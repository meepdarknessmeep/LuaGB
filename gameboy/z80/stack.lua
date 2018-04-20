local bit32 = require("bit")

local band = bit32.band

function apply(opcodes, opcode_cycles, z80, memory)
  -- push BC
  opcode_cycles[0xC5] = 16
  opcodes[0xC5] = function(self, reg, flags, mem)
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[4]
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[5]
  end

  -- push DE
  opcode_cycles[0xD5] = 16
  opcodes[0xD5] = function(self, reg, flags, mem)
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[6]
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[7]
  end

  -- push HL
  opcode_cycles[0xE5] = 16
  opcodes[0xE5] = function(self, reg, flags, mem)
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[9]
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[10]
  end

  -- push AF
  opcode_cycles[0xF5] = 16
  opcodes[0xF5] = function(self, reg, flags, mem)
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg[3]
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = reg.f()
  end

  -- pop BC
  opcode_cycles[0xC1] = 12
  opcodes[0xC1] = function(self, reg, flags, mem)
    reg[5] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
    reg[4] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
  end

  -- pop DE
  opcode_cycles[0xD1] = 12
  opcodes[0xD1] = function(self, reg, flags, mem)
    reg[7] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
    reg[6] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
  end

  -- pop HL
  opcode_cycles[0xE1] = 12
  opcodes[0xE1] = function(self, reg, flags, mem)
    reg[10] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
    reg[9] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
  end

  -- pop AF
  opcode_cycles[0xF1] = 12
  opcodes[0xF1] = function(self, reg, flags, mem)
    reg.set_f(mem[reg[2]])
    reg[2] = band(0xFFFF, reg[2] + 1)
    reg[3] = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
  end
end

return apply
