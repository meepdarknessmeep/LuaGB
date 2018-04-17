local bit32 = require("bit")

local band = bit32.band
local bxor = bit32.bxor
local bor = bit32.bor

function apply(opcodes, opcode_cycles, z80, memory)
  local function and_a_with (reg, flags, value)
    reg.a = band(reg.a, value)
    flags[1] = reg.a == 0
    flags[2] = false
    flags[3] = true
    flags[4] = false
  end

  -- and A, r
  opcodes[0xA0] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.b) end
  opcodes[0xA1] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.c) end
  opcodes[0xA2] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.d) end
  opcodes[0xA3] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.e) end
  opcodes[0xA4] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.h) end
  opcodes[0xA5] = function(self, reg, flags, mem) and_a_with(reg, flags, reg.l) end
  opcode_cycles[0xA6] = 8
  opcodes[0xA6] = function(self, reg, flags, mem) and_a_with(reg, flags, self.read_at_hl()) end
  opcodes[0xA7] = function(self, reg, flags, mem)
    --reg.a = band(reg.a, value)
    flags[1] = reg.a == 0
    flags[2] = false
    flags[3] = true
    flags[4] = false
  end

  -- and A, nn
  opcode_cycles[0xE6] = 8
  opcodes[0xE6] = function(self, reg, flags, mem) and_a_with(reg, flags, self.read_nn()) end

  local function xor_a_with (reg, flags, value)
    reg.a = bxor(reg.a, value)
    flags[1] = reg.a == 0
    flags[2] = false
    flags[3] = false
    flags[4] = false
  end

  -- xor A, r
  opcodes[0xA8] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.b) end
  opcodes[0xA9] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.c) end
  opcodes[0xAA] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.d) end
  opcodes[0xAB] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.e) end
  opcodes[0xAC] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.h) end
  opcodes[0xAD] = function(self, reg, flags, mem) xor_a_with(reg, flags, reg.l) end
  opcode_cycles[0xAE] = 8
  opcodes[0xAE] = function(self, reg, flags, mem) xor_a_with(reg, flags, self.read_at_hl()) end
  opcodes[0xAF] = function(self, reg, flags, mem)
    reg.a = 0
    flags[1] = true
    flags[2] = false
    flags[3] = false
    flags[4] = false
  end

  -- xor A, nn
  opcode_cycles[0xEE] = 8
  opcodes[0xEE] = function(self, reg, flags, mem) xor_a_with(reg, flags, self.read_nn()) end

  local function or_a_with (reg, flags, value)
    reg.a = bor(reg.a, value)
    flags[1] = reg.a == 0
    flags[2] = false
    flags[3] = false
    flags[4] = false
  end

  -- or A, r
  opcodes[0xB0] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.b) end
  opcodes[0xB1] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.c) end
  opcodes[0xB2] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.d) end
  opcodes[0xB3] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.e) end
  opcodes[0xB4] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.h) end
  opcodes[0xB5] = function(self, reg, flags, mem) or_a_with(reg, flags, reg.l) end
  opcode_cycles[0xB6] = 8
  opcodes[0xB6] = function(self, reg, flags, mem) or_a_with(reg, flags, self.read_at_hl()) end
  opcodes[0xB7] = function(self, reg, flags, mem)
    flags[1] = reg.a == 0
    flags[2] = false
    flags[3] = false
    flags[4] = false
  end

  -- or A, nn
  opcode_cycles[0xF6] = 8
  opcodes[0xF6] = function(self, reg, flags, mem) or_a_with(reg, flags, self.read_nn()) end

  -- cpl
  opcodes[0x2F] = function(self, reg, flags, mem)
    reg.a = bxor(reg.a, 0xFF)
    flags[2] = true
    flags[3] = true
  end
end

return apply
