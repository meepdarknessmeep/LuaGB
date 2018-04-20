local bit32 = require("bit")
local ffi   = require "ffi"

local Cache = require("gameboy/graphics/cache")
local Palette = require("gameboy/graphics/palette")
local Registers = require("gameboy/graphics/registers")

local function setcolor(to, r, g, b)
  to[1] = r
  to[2] = g
  to[3] = b
end

local function new_graphics(modules)
  local graphics = {
    palette = {},
    registers = {},
    cache = {},
    -- Internal Variables
    vblank_count = 0,
    last_edge = 0,
    next_edge = 0,
    lcdstat = false,
    -- color[144][160]
    game_screen = {},
    lcd = {},
    vram = {
      mem = modules.memory:create_block(16 * 2 * 1024),
    },
    oam = {
      mem = modules.memory:create_block(0xA0), -- (0xA0, 0xFE00)
    },
    scanline_data = {
      x = 0,
      bg_tile_x = 0,
      bg_tile_y = 0,
      sub_x = 0,
      sub_y = 0,
      active_tile = nil,
      active_attr = nil,
      current_map = nil,
      current_map_attr = nil,
      window_active = false,
      bg_index = {},
      bg_priority = {},
      active_palette = nil
    }
  }

  for y = 0, 143 * 160, 160 do
    for x = 0, 159 do
      graphics.game_screen[y + x] = {0, 0, 0}
    end
  end

  graphics.cache = Cache.new(graphics.cache, graphics, modules)
  graphics.palette = Palette.new(graphics.palette, graphics, modules)
  graphics.registers = Registers.new(graphics.registers, graphics, modules, graphics.cache)

  return graphics
end

if (ffi) then
  function new_graphics(modules)
    local graphics = ffi.new "LuaGBGraphics"

    graphics = setmetatable({
      clear_screen = false,
      initialize = false,
      reset = false,
      refresh_lcdstat = false,
      update = false,
      initialize_frame = false,
      initialize_scanline = false,
      switch_to_window = false,
      draw_next_pixels = false,
      getIndexFromTilemap = false,
      draw_sprites_into_scanline = false
    }, {
      __index = graphics,
      __newindex = graphics
    })

    Cache.new(graphics.cache, graphics, modules)
    Palette.new(graphics.palette, graphics, modules)
    Registers.new(graphics.registers, graphics, modules, graphics.cache)

    return graphics
  end
end

local Graphics = {}

function Graphics.new(gameboy)
  local interrupts = gameboy.interrupts
  local io = gameboy.io
  local memory = gameboy.memory
  local timers = gameboy.timers

  local graphics = new_graphics(gameboy)

  --just for shortening access
  local ports = io.ports

  graphics.clear_screen = function()
    for y = 0, 143 * 160, 160 do
      for x = 0, 159 do
        setcolor(graphics.game_screen[y + x], 255, 255, 255)
      end
    end
  end

  local vram_hook = {
    mem = graphics.vram
  }
  function vram_hook:getter(address)
    return self.mem[address - 0x8000 + (16 * 1024 * graphics.vram_bank)]
  end
  function vram_hook:setter(address, value)
    local offset = address - 0x8000
    self.mem[offset + (0x4000 * graphics.vram_bank)] = value
    if (offset <= 0x17FF) then
      graphics.cache.refreshTile(offset, graphics.vram_bank)
    end
    if address >= 0x9800 and address <= 0x9BFF then
      local x = address % 32
      local y = math.floor((address - 0x9800) / 32)
      if graphics.vram_bank == 1 then
        graphics.cache.refreshAttributes(graphics.cache.map_0_attr, x, y, offset)
      end
      graphics.cache.refreshTileIndex(x, y, 0x1800, graphics.cache.map_0, graphics.cache.map_0_attr)
    end
    if address >= 0x9C00 and address <= 0x9FFF then
      local x = address % 32
      local y = math.floor((address - 0x9C00) / 32)
      if graphics.vram_bank == 1 then
        graphics.cache.refreshAttributes(graphics.cache.map_1_attr, x, y, offset)
      end
      graphics.cache.refreshTileIndex(x, y, 0x1C00, graphics.cache.map_1, graphics.cache.map_1_attr)
    end
  end
  memory:install_hooks(0x8000, 0x2000, vram_hook)

  local oam_hook = {
    mem = graphics.oam
  }
  function oam_hook:getter(address)
    return self.mem[address - 0xFE00]
  end
  function oam_hook:setter(address, byte)
    self.mem[address - 0xFE00] = byte
    graphics.cache.refreshOamEntry(math.floor((address - 0xFE00) / 4))
  end
  memory:install_hooks(0xFE00, 0xA0, oam_hook)

  io.write_logic[0x4F] = function(byte)
    if gameboy.type == gameboy.types.color then
      io[1][0x4F] = bit32.band(0x1, byte)
      graphics.vram_bank = bit32.band(0x1, byte)
    else
      -- Not sure if the write mask should apply in DMG / SGB mode
      io[1][0x4F] = byte
    end
  end

  graphics.initialize = function() -- TODO: add gameboy back after ffi barrier
    graphics.registers.status.SetMode(2)
    graphics.clear_screen()
    graphics.reset()
  end

  graphics.reset = function()
    graphics.cache.reset()
    graphics.palette.reset()

    -- zero out all of VRAM:
    for i = 0, (16 * 2 * 1024) - 1 do
      graphics.vram[i] = 0
    end

    -- zero out all of OAM
    for i = 0, 0x9F do
      graphics.oam[i] = 0
    end

    graphics.vblank_count = 0
    graphics.last_edge = 0
    graphics.vram_bank = 0
    graphics.lcdstat = false

    graphics.clear_screen()
    graphics.registers.status.SetMode(2)
  end

  --[[ TODO: readd after ffi barrier
  graphics.save_state = function()
    local state = {}

    state.vram = {}
    for i = 0, (16 * 2 * 1024) - 1 do
      state.vram[i] = graphics.vram[i]
    end

    state.vram_bank = graphics.vram_bank

    state.oam = {}
    for i = 0, 0x9F do
      state.oam[i] = graphics.oam[i]
    end

    state.vblank_count = graphics.vblank_count
    state.last_edge = graphics.last_edge
    state.lcdstat = graphics.lcdstat
    state.mode = graphics.registers.status.mode

    state.palette = {}
    state.palette.bg   = graphics.palette.bg
    state.palette.obj0 = graphics.palette.obj0
    state.palette.obj1 = graphics.palette.obj1

    state.color_bg = {}
    state.color_obj = {}
    state.color_bg_raw = {}
    state.color_obj_raw = {}

    for p = 0, 7 do
      state.color_bg[p] = graphics.palette.color_bg[p]
      state.color_obj[p] = graphics.palette.color_obj[p]
    end

    for i = 0, 63 do
      state.color_bg_raw[i] = graphics.palette.color_bg_raw[i]
      state.color_obj_raw[i] = graphics.palette.color_obj_raw[i]
    end

    return state
  end

  graphics.load_state = function(state)
    for i = 0, (16 * 2 * 1024) - 1 do
      graphics.vram[i] = state.vram[i]
    end

    graphics.vram_bank = state.vram_bank

    for i = 0, 0x9F do
      graphics.oam[i] = state.oam[i]
    end
    graphics.vblank_count = state.vblank_count
    graphics.last_edge = state.last_edge
    graphics.lcdstat = state.lcdstat
    graphics.registers.status.mode = state.mode

    graphics.palette.bg   = state.palette.bg
    graphics.palette.obj0 = state.palette.obj0
    graphics.palette.obj1 = state.palette.obj1

    for p = 0, 7 do
      graphics.palette.color_bg[p] = state.color_bg[p]
      graphics.palette.color_obj[p] = state.color_obj[p]
    end

    for i = 0, 63 do
      graphics.palette.color_bg_raw[i] = state.color_bg_raw[i]
      graphics.palette.color_obj_raw[i] = state.color_obj_raw[i]
    end

    graphics.cache.refreshAll()
    io.write_logic[ports.STAT](io[1][ports.STAT])
    io.write_logic[ports.LCDC](io[1][ports.LCDC])
  end
  ]]

  local time_at_this_mode = function()
    return timers.system_clock - graphics.last_edge
  end

  local scanline_data = graphics.scanline_data

  graphics.refresh_lcdstat = function()
    local lcdstat = false
    local status = graphics.registers.status

    lcdstat =
      (status.lyc_interrupt_enabled and io[1][ports.LY] == io[1][ports.LYC]) or
      (status.oam_interrupt_enabled and status.mode == 2) or
      (status.vblank_interrupt_enabled and status.mode == 1) or
      (status.hblank_interrupt_enabled and status.mode == 0)

    -- If this is a *rising* edge, raise the LCDStat interrupt
    if graphics.lcdstat == false and lcdstat == true then
      interrupts.raise(interrupts.LCDStat)
    end

    graphics.lcdstat = lcdstat
  end

  io.write_logic[ports.LY] = function(byte)
    -- LY, writes reset the counter
    io[1][ports.LY] = 0
    graphics.refresh_lcdstat()
  end

  io.write_logic[ports.LYC] = function(byte)
    -- LY, writes reset the counter
    io[1][ports.LYC] = byte
    graphics.refresh_lcdstat()
  end

  -- HBlank: Period between scanlines
  local handle_mode = {}
  handle_mode[0] = function()
    if timers.system_clock - graphics.last_edge > 204 then
      graphics.last_edge = graphics.last_edge + 204
      io[1][ports.LY] = io[1][ports.LY] + 1
      if io[1][ports.LY] == io[1][ports.LYC] then
        -- set the LY compare bit
        io[1][ports.STAT] = bit32.bor(io[1][ports.STAT], 0x4)
      else
        -- clear the LY compare bit
        io[1][ports.STAT] = bit32.band(io[1][ports.STAT], 0xFB)
      end

      if io[1][ports.LY] >= 144 then
        graphics.registers.status.SetMode(1)
        graphics.vblank_count = graphics.vblank_count + 1
        interrupts.raise(interrupts.VBlank)
      else
        graphics.registers.status.SetMode(2)
      end

      graphics.refresh_lcdstat()
    else
      graphics.next_edge = graphics.last_edge + 204
    end
  end

  --VBlank: nothing to do except wait for the next frame
  handle_mode[1] = function()
    if timers.system_clock - graphics.last_edge > 456 then
      graphics.last_edge = graphics.last_edge + 456
      io[1][ports.LY] = io[1][ports.LY] + 1
      graphics.refresh_lcdstat()
    else
      graphics.next_edge = graphics.last_edge + 456
    end

    if io[1][ports.LY] >= 154 then
      io[1][ports.LY] = 0
      graphics.initialize_frame()
      graphics.registers.status.SetMode(2)
      graphics.refresh_lcdstat()
    end

    if io[1][ports.LY] == io[1][ports.LYC] then
      -- set the LY compare bit
      io[1][ports.STAT] = bit32.bor(io[1][ports.STAT], 0x4)
    else
      -- clear the LY compare bit
      io[1][ports.STAT] = bit32.band(io[1][ports.STAT], 0xFB)
    end
  end

  -- OAM Read: OAM cannot be accessed
  handle_mode[2] = function()
    if timers.system_clock - graphics.last_edge > 80 then
      graphics.last_edge = graphics.last_edge + 80
      graphics.initialize_scanline()
      graphics.registers.status.SetMode(3)
      graphics.refresh_lcdstat()
    else
      graphics.next_edge = graphics.last_edge + 80
    end
  end
  -- VRAM Read: Neither VRAM, OAM, nor CGB palettes can be read
  handle_mode[3] = function()
    local duration = timers.system_clock - graphics.last_edge
    graphics.draw_next_pixels(duration)
    if timers.system_clock - graphics.last_edge > 172 then
      graphics.last_edge = graphics.last_edge + 172
      graphics.draw_sprites_into_scanline(io[1][ports.LY], scanline_data.bg_index, scanline_data.bg_priority)
      graphics.registers.status.SetMode(0)
      -- If enabled, fire an HBlank interrupt
      graphics.refresh_lcdstat()
    else
      graphics.next_edge = graphics.last_edge + 172
    end
  end

  graphics.update = function()
    if graphics.registers.display_enabled then
      handle_mode[graphics.registers.status.mode]()
    else
      -- erase our clock debt, so we don't do stupid timing things when the
      -- display is enabled again later
      graphics.last_edge = timers.system_clock
      graphics.next_edge = timers.system_clock
      graphics.registers.status.SetMode(0)
      io[1][ports.LY] = 0
      graphics.refresh_lcdstat()
    end
  end

  local frame_data = {}
  frame_data.window_pos_y = 0
  frame_data.window_draw_y = 0

  graphics.initialize_frame = function()
    -- latch WY at the beginning of the *frame*
    frame_data.window_pos_y = io[1][ports.WY]
    frame_data.window_draw_y = 0
  end

  graphics.initialize_scanline = function()
    scanline_data.x = 0

    scanline_data.bg_tile_x = math.floor(io[1][ports.SCX] / 8)
    scanline_data.bg_tile_y = math.floor((io[1][ports.LY] + io[1][ports.SCY]) / 8)
    if scanline_data.bg_tile_y >= 32 then
      scanline_data.bg_tile_y = scanline_data.bg_tile_y - 32
    end

    scanline_data.sub_x = io[1][ports.SCX] % 8
    scanline_data.sub_y = (io[1][ports.LY] + io[1][ports.SCY]) % 8

    scanline_data.current_map = graphics.registers.background_tilemap
    scanline_data.current_map_attr = graphics.registers.background_attr

    scanline_data.active_attr = scanline_data.current_map_attr[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
    scanline_data.active_tile = scanline_data.current_map[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
    scanline_data.window_active = false
  end

  local switch_to_window = function()
    local ly = io[1][ports.LY]
    local w_x = io[1][ports.WX] - 7
    if graphics.registers.window_enabled and scanline_data.x >= w_x and ly >= frame_data.window_pos_y then
      -- switch to window map
      scanline_data.current_map = graphics.registers.window_tilemap
      scanline_data.current_map_attr = graphics.registers.window_attr
      scanline_data.bg_tile_x = math.floor((scanline_data.x - w_x) / 8)
      scanline_data.bg_tile_y = math.floor(frame_data.window_draw_y / 8)
      scanline_data.sub_x = (scanline_data.x - w_x) % 8
      scanline_data.sub_y = frame_data.window_draw_y % 8
      frame_data.window_draw_y = frame_data.window_draw_y + 1
      frame_data.window_draw_y = math.min(frame_data.window_draw_y, 143)

      scanline_data.active_attr = scanline_data.current_map_attr[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
      scanline_data.active_tile = scanline_data.current_map[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
      scanline_data.window_active = true
    end
  end

  graphics.draw_next_pixels = function(duration)
    local ly = io[1][ports.LY]
    local game_screen = graphics.game_screen
    local scanline_data = scanline_data

    local min = math.min(duration, 160)
    while scanline_data.x < min do
      local dx = scanline_data.x
      if not scanline_data.window_active then
        switch_to_window()
      end

      local bg_index = 0 --default, in case no background is enabled
      if graphics.registers.background_enabled then
        -- DRAW BG PIXEL HERE
        local sub_x = scanline_data.sub_x
        local sub_y = scanline_data.sub_y
        bg_index = scanline_data.active_tile[sub_x][sub_y]
        local active_palette = scanline_data.active_attr.palette[bg_index]

        setcolor(game_screen[ly * 160 + dx], active_palette[1], active_palette[2], active_palette[3])
      end

      scanline_data.bg_index[scanline_data.x] = bg_index
      scanline_data.bg_priority[scanline_data.x] = scanline_data.active_attr.priority

      scanline_data.x = scanline_data.x  + 1
      
      scanline_data.sub_x = scanline_data.sub_x  + 1
      if scanline_data.sub_x > 7 then
        -- fetch next tile
        scanline_data.sub_x = 0
        scanline_data.bg_tile_x = scanline_data.bg_tile_x + 1
        if scanline_data.bg_tile_x >= 32 then
          scanline_data.bg_tile_x = scanline_data.bg_tile_x - 32
        end
        if not scanline_data.window_active then
          scanline_data.sub_y = (ly + io[1][ports.SCY]) % 8
          scanline_data.bg_tile_y = math.floor((ly + io[1][ports.SCY]) / 8)
          if scanline_data.bg_tile_y >= 32 then
            scanline_data.bg_tile_y = scanline_data.bg_tile_y - 32
          end
        end

        local tile_attr = scanline_data.current_map_attr[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
        if tile_attr.vertical_flip then
          scanline_data.sub_y = 7 - scanline_data.sub_y
        end

        scanline_data.active_attr = scanline_data.current_map_attr[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
        scanline_data.active_tile = scanline_data.current_map[scanline_data.bg_tile_x][scanline_data.bg_tile_y]
      end
    end
  end

  graphics.getIndexFromTilemap = function(map, tile_data, x, y)
    local tile_x = bit32.rshift(x, 3)
    local tile_y = bit32.rshift(y, 3)
    local tile_index = map[tile_x][tile_y]

    local subpixel_x = x - (tile_x * 8)
    local subpixel_y = y - (tile_y * 8)

    if tile_data == 0x9000 then
      if tile_index > 127 then
        tile_index = tile_index - 256
      end
      -- add offset to re-root at tile 256 (so effectively, we read from tile 192 - 384)
      tile_index = tile_index + 256
    end

    if gameboy.type == gameboy.types.color then
      local map_attr = graphics.cache.map_0_attr
      if map == graphics.cache.map_1 then
        map_attr = graphics.cache.map_1_attr
      end
      local tile_attributes = map_attr[tile_x][tile_y]
      tile_index = tile_index + tile_attributes.bank * 384

      if tile_attributes.horizontal_flip == true then
        subpixel_x = (7 - subpixel_x)
      end

      if tile_attributes.vertical_flip == true then
        subpixel_y = (7 - subpixel_y)
      end
    end

    return graphics.cache.tiles[tile_index][subpixel_x][subpixel_y]
  end

  graphics.draw_sprites_into_scanline = function(scanline, bg_index, bg_priority)
    if not graphics.registers.sprites_enabled then
      return
    end
    local active_sprites = {}
    local sprite_size = 8
    if graphics.registers.large_sprites then
      sprite_size = 16
    end

    -- Collect up to the 10 highest priority sprites in a list.
    -- Sprites have priority first by their X coordinate, then by their index
    -- in the list.
    local i = 0
    while i < 40 do
      -- is this sprite being displayed on this scanline? (respect to Y coordinate)
      local sprite_y = graphics.cache.oam[i].y
      local sprite_lower = sprite_y
      local sprite_upper = sprite_y + sprite_size
      if scanline >= sprite_lower and scanline < sprite_upper then
        if #active_sprites < 10 then
          table.insert(active_sprites, i)
        else
          -- There are more than 10 sprites in the table, so we need to pick
          -- a candidate to vote off the island (possibly this one)
          local lowest_priority = i
          for j = 1, #active_sprites do
            local lowest_x = graphics.cache.oam[lowest_priority].x
            local candidate_x = graphics.cache.oam[active_sprites[j]].x
            if candidate_x > lowest_x then
              lowest_priority = active_sprites[j]
              lowest_priority_index = j
            end
          end
          if lowest_priority_index then
            active_sprites[lowest_priority_index] = i
          end
        end
      end
      i = i + 1
    end

    -- now, for every sprite in the list, display it on the current scanline
    for i = #active_sprites, 1, -1 do
      local sprite = graphics.cache.oam[active_sprites[i]]

      local sub_y = 16 - ((sprite.y + 16) - scanline)
      if sprite.vertical_flip then
        sub_y = sprite_size - 1 - sub_y
      end

      local tile = sprite.tile
      if sprite_size == 16 then
        tile = sprite.upper_tile
        if sub_y >= 8 then
          tile = sprite.lower_tile
          sub_y = sub_y - 8
        end
      end

      local game_screen = graphics.game_screen

      for x = 0, 7 do
        local display_x = sprite.x + x
        if display_x >= 0 and display_x < 160 then
          local sub_x = x
          if x_flipped then
            sub_x = 7 - x
          end
          local subpixel_index = tile[sub_x][sub_y]
          if subpixel_index > 0 and ((bg_priority[display_x] == false and not sprite.bg_priority) or bg_index[display_x] == 0 or graphics.registers.oam_priority) then
            local subpixel_color = sprite.palette[subpixel_index]
            setcolor(game_screen[scanline * 160 + display_x], subpixel_color[1], subpixel_color[2], subpixel_color[3])
          end
        end
      end
    end
    if #active_sprites > 0 then
      -- TODO
    end
  end

  return graphics
end

return Graphics
