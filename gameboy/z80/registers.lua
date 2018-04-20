local bit32 = require("bit")

local lshift = bit32.lshift
local band = bit32.band
local rshift = bit32.rshift

local Registers = {}

function Registers.new()
  -- [1] = pc, [2] = sp
  local registers = {
    0, -- pc
    0, -- sp
    0, -- a
    0, -- b
    0, -- c
    0, -- d
    0, -- e
    {
      false, -- z
      false, -- n
      false, -- h
      false, -- c z=false,n=false,h=false,c=false}
    }, -- flags
    0, -- h
    0, -- l
  }
  local reg = registers

  reg.f = function()
    local value = 0
    if reg[8][1] then
      value = value + 0x80
    end
    if reg[8][2] then
      value = value + 0x40
    end
    if reg[8][3] then
      value = value + 0x20
    end
    if reg[8][4] then
      value = value + 0x10
    end
    return value
  end

  reg.set_f = function(value)
    reg[8][1] = band(value, 0x80) ~= 0
    reg[8][2] = band(value, 0x40) ~= 0
    reg[8][3] = band(value, 0x20) ~= 0
    reg[8][4] = band(value, 0x10) ~= 0
  end

  reg.af = function()
    return lshift(reg[3], 8) + reg.f()
  end

  reg.bc = function()
    return lshift(reg[4], 8) + reg[5]
  end

  reg.de = function()
    return lshift(reg[6], 8) + reg[7]
  end

  reg.hl = function()
    return lshift(reg[9], 8) + reg[10]
  end

  reg.set_bc = function(value)
    reg[4] = rshift(band(value, 0xFF00), 8)
    reg[5] = band(value, 0xFF)
  end

  reg.set_de = function(value)
    reg[6] = rshift(band(value, 0xFF00), 8)
    reg[7] = band(value, 0xFF)
  end

  reg.set_hl = function(value)
    reg[9] = rshift(band(value, 0xFF00), 8)
    reg[10] = band(value, 0xFF)
  end

  return registers
end

return Registers
