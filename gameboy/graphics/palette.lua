local bit32 = require("bit")
local ffi   = require "ffi"

local function setcolor(to, r, g, b)
  to[1] = r
  to[2] = g
  to[3] = b
end

local function new_palette(palette)
  palette = palette or {}
  for k,v in pairs {
    bg = {},
    obj0 = {},
    obj1 = {},
    color_bg = {},
    color_obj = {},
    color_bg_raw = {},
    color_obj_raw = {},
    color_bg_index = 0,
    color_bg_auto_increment = false,
    color_obj_index = 0,
    color_obj_auto_increment = false,
    reset = function()
      local dmg_colors = {}
      setcolor(dmg_colors[0], 255, 255, 255)
      setcolor(dmg_colors[1], 192, 192, 192)
      setcolor(dmg_colors[2], 128, 128, 128)
      setcolor(dmg_colors[3], 0, 0, 0)

      palette.dmg_colors = dmg_colors

      for i = 0, 3 do
        palette.bg[i] = dmg_colors[i]
        palette.obj0[i] = dmg_colors[i]
        palette.obj1[i] = dmg_colors[i]
      end

      for p = 0, 7 do
        palette.color_bg[p] = {}
        palette.color_obj[p] = {}
        for i = 0, 3 do
          setcolor(palette.color_bg[p][i], 255, 255, 255)
          setcolor(palette.color_obj[p][i], 255, 255, 255)
        end
      end

      for i = 0, 63 do
        palette.color_bg_raw[i] = 0
        palette.color_obj_raw[i] = 0
      end
    end
  } do
    palette[k] = v
  end
  palette.reset()

  return palette
end


if (ffi) then
  function new_palette(palette)
    palette = palette or ffi.new "LuaGBPalette"
    function palette.reset()
      local dmg_colors = ffi.new "LuaGBPaletteColor[4]"
      setcolor(dmg_colors[0], 255, 255, 255)
      setcolor(dmg_colors[1], 192, 192, 192)
      setcolor(dmg_colors[2], 128, 128, 128)
      setcolor(dmg_colors[3], 0, 0, 0)

      for i = 0, 3 do
        palette.bg[i] = dmg_colors[i]
        palette.obj0[i] = dmg_colors[i]
        palette.obj1[i] = dmg_colors[i]
      end

      for p = 0, 7 do
        for i = 0, 3 do
          setcolor(palette.color_bg[p][i], 255, 255, 255)
          setcolor(palette.color_obj[p][i], 255, 255, 255)
        end
      end

      for i = 0, 63 do
        palette.color_bg_raw[i] = 0
        palette.color_obj_raw[i] = 0
      end
    end
    palette.reset()
    return palette
  end
end

local Palette = {}

function Palette.new(palette, graphics, modules)
  local io = modules.io
  local ports = io.ports

  local palette = new_palette(palette)




  palette.set_dmg_colors = function(pal_0, pal_1, pal_2, pal_3)
    palette.dmg_colors[0] = pal_0
    palette.dmg_colors[1] = pal_1
    palette.dmg_colors[2] = pal_2
    palette.dmg_colors[3] = pal_3
  end

  local getColorFromIndex = function(index, p)
    p = p or 0xE4
    while index > 0 do
      p = bit32.rshift(p, 2)
      index = index - 1
    end
    return palette.dmg_colors[bit32.band(p, 0x3)]
  end

  -- DMG palettes
  io.write_logic[ports.BGP] = function(byte)
    io[1][ports.BGP] = byte
    for i = 0, 3 do
      palette.bg[i] = getColorFromIndex(i, byte)
    end
    graphics.update()
  end

  io.write_logic[ports.OBP0] = function(byte)
    io[1][ports.OBP0] = byte
    for i = 0, 3 do
      palette.obj0[i] = getColorFromIndex(i, byte)
    end
    graphics.update()
  end

  io.write_logic[ports.OBP1] = function(byte)
    io[1][ports.OBP1] = byte
    for i = 0, 3 do
      palette.obj1[i] = getColorFromIndex(i, byte)
    end
    graphics.update()
  end

  -- Color Palettes
  io.write_logic[0x68] = function(byte)
    io[1][0x68] = byte
    palette.color_bg_index = bit32.band(byte, 0x3F)
    palette.color_bg_auto_increment = bit32.band(byte, 0x80) ~= 0
  end

  io.write_logic[0x69] = function(byte)
    palette.color_bg_raw[palette.color_bg_index] = byte

    -- Update the palette cache for this byte pair
    local low_byte = palette.color_bg_raw[bit32.band(palette.color_bg_index, 0xFE)]
    local high_byte = palette.color_bg_raw[bit32.band(palette.color_bg_index, 0xFE) + 1]
    local rgb5_color = bit32.lshift(high_byte, 8) + low_byte
    local r = bit32.band(rgb5_color, 0x001F) * 8
    local g = bit32.rshift(bit32.band(rgb5_color, 0x03E0), 5) * 8
    local b = bit32.rshift(bit32.band(rgb5_color, 0x7C00), 10) * 8
    local palette_index = math.floor(palette.color_bg_index / 8)
    local color_index = math.floor((palette.color_bg_index % 8) / 2)
    setcolor(palette.color_bg[palette_index][color_index], r, g, b)

    if palette.color_bg_auto_increment then
      palette.color_bg_index = palette.color_bg_index + 1
      if palette.color_bg_index > 63 then
        palette.color_bg_index = 0
      end
    end
  end

  io.read_logic[0x69] = function()
    return palette.color_bg_raw[palette.color_bg_index]
  end

  io.write_logic[0x6A] = function(byte)
    io[1][0x6A] = byte
    palette.color_obj_index = bit32.band(byte, 0x3F)
    palette.color_obj_auto_increment = bit32.band(byte, 0x80) ~= 0
  end

  io.write_logic[0x6B] = function(byte)
    palette.color_obj_raw[palette.color_obj_index] = byte

    -- Update the palette cache for this byte pair
    local low_byte = palette.color_obj_raw[bit32.band(palette.color_obj_index, 0xFE)]
    local high_byte = palette.color_obj_raw[bit32.band(palette.color_obj_index, 0xFE) + 1]
    local rgb5_color = bit32.lshift(high_byte, 8) + low_byte
    local r = bit32.band(rgb5_color, 0x001F) * 8
    local g = bit32.rshift(bit32.band(rgb5_color, 0x03E0), 5) * 8
    local b = bit32.rshift(bit32.band(rgb5_color, 0x7C00), 10) * 8
    local palette_index = math.floor(palette.color_obj_index / 8)
    local color_index = math.floor((palette.color_obj_index % 8) / 2)
    setcolor(palette.color_obj[palette_index][color_index], r, g, b)

    if palette.color_obj_auto_increment then
      palette.color_obj_index = palette.color_obj_index + 1
      if palette.color_obj_index > 63 then
        palette.color_obj_index = 0
      end
    end
  end

  io.read_logic[0x6B] = function()
    return palette.color_obj_raw[palette.color_obj_index]
  end

  return palette
end

return Palette
