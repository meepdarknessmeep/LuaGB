local bit32 = require("bit")

local lshift = bit32.lshift
local band = bit32.band

function apply(opcodes, opcode_cycles)

  local function set_inc_flags (flags, value)
    flags[1] = value == 0
    flags[3] = value % 0x10 == 0x0
    flags[2] = false
  end

  local function set_dec_flags (flags, value)
    flags[1] = value == 0
    flags[3] = value % 0x10 == 0xF
    flags[2] = true
  end

  -- inc r
  opcodes[0x04] = function(self, reg, flags, mem)
    local v = band(reg[4] + 1, 0xFF)
    reg[4] = v
    set_inc_flags(flags, v)
  end
  opcodes[0x0C] = function(self, reg, flags, mem)
    local v = band(reg[5] + 1, 0xFF)
    reg[5] = v
    set_inc_flags(flags, v)
  end
  opcodes[0x14] = function(self, reg, flags, mem)
    local v = band(reg[6] + 1, 0xFF)
    reg[6] = v
    set_inc_flags(flags, v)
  end
  opcodes[0x1C] = function(self, reg, flags, mem)
    local v = band(reg[7] + 1, 0xFF)
    reg[7] = v
    set_inc_flags(flags, v)
  end
  opcodes[0x24] = function(self, reg, flags, mem)
    local v = band(reg[9] + 1, 0xFF)
    reg[9] = v
    set_inc_flags(flags, v)
  end
  opcodes[0x2C] = function(self, reg, flags, mem)
    local v = band(reg[10] + 1, 0xFF)
    reg[10] = v
    set_inc_flags(flags, v)
  end
  opcode_cycles[0x34] = 12
  opcodes[0x34] = function(self, reg, flags, mem)
    mem[reg.hl()] = band(mem[reg.hl()] + 1, 0xFF)
    set_inc_flags(flags, mem[reg.hl()])
  end
  opcodes[0x3C] = function(self, reg, flags, mem)
    local v = band(reg[3] + 1, 0xFF)
    reg[3] = v
    set_inc_flags(flags, v)
  end

  -- dec r
  opcodes[0x05] = function(self, reg, flags, mem)
    local v = band(reg[4] - 1, 0xFF)
    reg[4] = v
    set_dec_flags(flags, v)
  end
  opcodes[0x0D] = function(self, reg, flags, mem)
    local v = band(reg[5] - 1, 0xFF)
    reg[5] = v
    set_dec_flags(flags, v)
  end
  opcodes[0x15] = function(self, reg, flags, mem)
    local v = band(reg[6] - 1, 0xFF)
    reg[6] = v
    set_dec_flags(flags, v)
  end
  opcodes[0x1D] = function(self, reg, flags, mem)
    local v = band(reg[7] - 1, 0xFF)
    reg[7] = v
    set_dec_flags(flags, v)
  end
  opcodes[0x25] = function(self, reg, flags, mem)
    local v = band(reg[9] - 1, 0xFF)
    reg[9] = v
    set_dec_flags(flags, v)
  end
  opcodes[0x2D] = function(self, reg, flags, mem)
    local v = band(reg[10] - 1, 0xFF)
    reg[10] = v
    set_dec_flags(flags, v)
  end
  opcode_cycles[0x35] = 12
  opcodes[0x35] = function(self, reg, flags, mem)
    mem[reg.hl()] = band(mem[reg.hl()] - 1, 0xFF)
    set_dec_flags(flags, mem[reg.hl()])
  end
  opcodes[0x3D] = function(self, reg, flags, mem)
    local v = band(reg[3] - 1, 0xFF)
    reg[3] = v
    set_dec_flags(flags, v)
  end
end

return apply
