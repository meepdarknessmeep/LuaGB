local bit32 = require("bit")

local Io = {}

local band, bor = bit32.band, bit32.bor
local bnot = bit32.bnot

function Io.new(modules)
  local memory = modules.memory
  local io = memory:create_block(0x100)

  io.ports = {
    -- Port names pulled from Pan Docs, starting here:
    -- http://bgb.bircd.org/pandocs.htm#videodisplay

    -- LCD Control
    LCDC = 0x40,

    -- LCD Status
    STAT = 0x41,

    -- BG Scroll
    SCY = 0x42,
    SCX = 0x43,

    -- Current Scanline (LCDC Y-coordinate)
    LY = 0x44,
    -- LCD Compare, scanline on which a STAT interrupt is requested
    LYC = 0x45,

    -- B&W Palettes
    BGP = 0x47,
    OBP0 = 0x48,
    OBP1 = 0x49,

    -- Window Scroll
    WY = 0x4A,
    WX = 0x4B,

    -- Color-mode Palettes
    BGPI = 0x68,
    BGPD = 0x69,
    OBPI = 0x6A,
    OBPD = 0x6B,

    -- Color-mode VRAM Bank
    VBK = 0x4F,

    -- DMA Transfer Start (Write Only)
    DMA = 0x46,

    -- Joypad
    JOYP = 0x00,

    -- Timers
    DIV = 0x04,
    TIMA = 0x05,
    TMA = 0x06,
    TAC = 0x07,

    -- Interrupts
    IE = 0xFF,
    IF = 0x0F,

    -- Sound
    NR10 = 0x10,
    NR11 = 0x11,
    NR12 = 0x12,
    NR13 = 0x13,
    NR14 = 0x14,

    NR21 = 0x16,
    NR22 = 0x17,
    NR23 = 0x18,
    NR24 = 0x19,

    NR30 = 0x1A,
    NR31 = 0x1B,
    NR32 = 0x1C,
    NR33 = 0x1D,
    NR34 = 0x1E,

    NR41 = 0x20,
    NR42 = 0x21,
    NR43 = 0x22,
    NR44 = 0x23,

    NR50 = 0x24,
    NR51 = 0x25,
    NR52 = 0x26
  }
  local ports = io.ports

  io.write_logic = {}
  io.read_logic = {}
  io.write_mask = {
    [ports.JOYP] = 0x30,
    [ports.LY] = 0x00
  }

  io = io -- TODO: remove (DEPRECATED)

  io.base = 0xFF00

  function io:getter(addr)
    local offset = addr - 0xFF00
    if self.read_logic[offset] then
      return self.read_logic[offset]()
    else
      return self[offset]
    end
  end

  function io:setter(addr, value)
    local offset = addr - 0xFF00
    local mask = self.write_mask[offset]
    if mask then
      value = bor(band(value, mask), band(self[offset], bnot(mask)))
    end
    if io.write_logic[offset] then
      -- Some addresses (mostly IO ports) have fancy logic or do strange things on
      -- writes, so we handle those here.
      io.write_logic[offset](value)
      return
    end
    self[offset] = value
  end

  io.reset = function(gameboy)
    io.gameboy = gameboy

    for i = 0, #io do
      io[i] = 0
    end

    -- Set io registers to post power-on values
    -- Sound Enable must be set to F1
    io[0x26] = 0xF1

    io[ports.LCDC] = 0x91
    io[ports.BGP ] = 0xFC
    io[ports.OBP0] = 0xFF
    io[ports.OBP1] = 0xFF
  end

  io.save_state = function()
    local state = {}

    for i = 0, 0xFF do
      state[i] = io[i]
    end

    return state
  end

  io.load_state = function(state)
    for i = 0, 0xFF do
      io[i] = state[i]
    end
  end

  memory:install_hooks(0xFF00, 0x100, io)

  return io
end

return Io
