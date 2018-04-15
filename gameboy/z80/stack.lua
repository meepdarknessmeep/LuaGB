local bit32 = require("bit")

local band = bit32.band
local lshift = bit32.lshift
local rshift = bit32.rshift

function apply(opcodes, opcode_cycles, z80, memory)
  -- push BC
  opcode_cycles[0xC5] = 16
  opcodes[0xC5] = function(self, reg, flags)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.b)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.c)
  end

  -- push DE
  opcode_cycles[0xD5] = 16
  opcodes[0xD5] = function(self, reg, flags)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.d)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.e)
  end

  -- push HL
  opcode_cycles[0xE5] = 16
  opcodes[0xE5] = function(self, reg, flags)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.h)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.l)
  end

  -- push AF
  opcode_cycles[0xF5] = 16
  opcodes[0xF5] = function(self, reg, flags)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.a)
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, reg.f())
  end

  -- pop BC
  opcode_cycles[0xC1] = 12
  opcodes[0xC1] = function(self, reg, flags)
    reg.c = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.b = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  end

  -- pop DE
  opcode_cycles[0xD1] = 12
  opcodes[0xD1] = function(self, reg, flags)
    reg.e = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.d = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  end

  -- pop HL
  opcode_cycles[0xE1] = 12
  opcodes[0xE1] = function(self, reg, flags)
    reg.l = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.h = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  end

  -- pop AF
  opcode_cycles[0xF1] = 12
  opcodes[0xF1] = function(self, reg, flags)
    reg.set_f(self.read_byte(reg.sp))
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.a = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
  end
end

return apply
