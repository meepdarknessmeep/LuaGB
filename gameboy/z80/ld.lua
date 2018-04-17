local bit32 = require("bit")

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band

function apply(opcodes, opcode_cycles, z80, memory)
  -- ld r, r
  opcodes[0x40] = function(self, reg, flags, mem) reg.b = reg.b end
  opcodes[0x41] = function(self, reg, flags, mem) reg.b = reg.c end
  opcodes[0x42] = function(self, reg, flags, mem) reg.b = reg.d end
  opcodes[0x43] = function(self, reg, flags, mem) reg.b = reg.e end
  opcodes[0x44] = function(self, reg, flags, mem) reg.b = reg.h end
  opcodes[0x45] = function(self, reg, flags, mem) reg.b = reg.l end
  opcode_cycles[0x46] = 8
  opcodes[0x46] = function(self, reg, flags, mem) reg.b = self.read_at_hl() end
  opcodes[0x47] = function(self, reg, flags, mem) reg.b = reg.a end

  opcodes[0x48] = function(self, reg, flags, mem) reg.c = reg.b end
  opcodes[0x49] = function(self, reg, flags, mem) reg.c = reg.c end
  opcodes[0x4A] = function(self, reg, flags, mem) reg.c = reg.d end
  opcodes[0x4B] = function(self, reg, flags, mem) reg.c = reg.e end
  opcodes[0x4C] = function(self, reg, flags, mem) reg.c = reg.h end
  opcodes[0x4D] = function(self, reg, flags, mem) reg.c = reg.l end
  opcode_cycles[0x4E] = 8
  opcodes[0x4E] = function(self, reg, flags, mem) reg.c = self.read_at_hl() end
  opcodes[0x4F] = function(self, reg, flags, mem) reg.c = reg.a end

  opcodes[0x50] = function(self, reg, flags, mem) reg.d = reg.b end
  opcodes[0x51] = function(self, reg, flags, mem) reg.d = reg.c end
  opcodes[0x52] = function(self, reg, flags, mem) reg.d = reg.d end
  opcodes[0x53] = function(self, reg, flags, mem) reg.d = reg.e end
  opcodes[0x54] = function(self, reg, flags, mem) reg.d = reg.h end
  opcodes[0x55] = function(self, reg, flags, mem) reg.d = reg.l end
  opcode_cycles[0x56] = 8
  opcodes[0x56] = function(self, reg, flags, mem) reg.d = self.read_at_hl() end
  opcodes[0x57] = function(self, reg, flags, mem) reg.d = reg.a end

  opcodes[0x58] = function(self, reg, flags, mem) reg.e = reg.b end
  opcodes[0x59] = function(self, reg, flags, mem) reg.e = reg.c end
  opcodes[0x5A] = function(self, reg, flags, mem) reg.e = reg.d end
  opcodes[0x5B] = function(self, reg, flags, mem) reg.e = reg.e end
  opcodes[0x5C] = function(self, reg, flags, mem) reg.e = reg.h end
  opcodes[0x5D] = function(self, reg, flags, mem) reg.e = reg.l end
  opcode_cycles[0x5E] = 8
  opcodes[0x5E] = function(self, reg, flags, mem) reg.e = self.read_at_hl() end
  opcodes[0x5F] = function(self, reg, flags, mem) reg.e = reg.a end

  opcodes[0x60] = function(self, reg, flags, mem) reg.h = reg.b end
  opcodes[0x61] = function(self, reg, flags, mem) reg.h = reg.c end
  opcodes[0x62] = function(self, reg, flags, mem) reg.h = reg.d end
  opcodes[0x63] = function(self, reg, flags, mem) reg.h = reg.e end
  opcodes[0x64] = function(self, reg, flags, mem) reg.h = reg.h end
  opcodes[0x65] = function(self, reg, flags, mem) reg.h = reg.l end
  opcode_cycles[0x66] = 8
  opcodes[0x66] = function(self, reg, flags, mem) reg.h = self.read_at_hl() end
  opcodes[0x67] = function(self, reg, flags, mem) reg.h = reg.a end

  opcodes[0x68] = function(self, reg, flags, mem) reg.l = reg.b end
  opcodes[0x69] = function(self, reg, flags, mem) reg.l = reg.c end
  opcodes[0x6A] = function(self, reg, flags, mem) reg.l = reg.d end
  opcodes[0x6B] = function(self, reg, flags, mem) reg.l = reg.e end
  opcodes[0x6C] = function(self, reg, flags, mem) reg.l = reg.h end
  opcodes[0x6D] = function(self, reg, flags, mem) reg.l = reg.l end
  opcode_cycles[0x6E] = 8
  opcodes[0x6E] = function(self, reg, flags, mem) reg.l = self.read_at_hl() end
  opcodes[0x6F] = function(self, reg, flags, mem) reg.l = reg.a end

opcode_cycles[0x70] = 8
  opcodes[0x70] = function(self, reg, flags, mem) self.set_at_hl(reg.b) end

  opcode_cycles[0x71] = 8
  opcodes[0x71] = function(self, reg, flags, mem) self.set_at_hl(reg.c) end

  opcode_cycles[0x72] = 8
  opcodes[0x72] = function(self, reg, flags, mem) self.set_at_hl(reg.d) end

  opcode_cycles[0x73] = 8
  opcodes[0x73] = function(self, reg, flags, mem) self.set_at_hl(reg.e) end

  opcode_cycles[0x74] = 8
  opcodes[0x74] = function(self, reg, flags, mem) self.set_at_hl(reg.h) end

  opcode_cycles[0x75] = 8
  opcodes[0x75] = function(self, reg, flags, mem) self.set_at_hl(reg.l) end

  -- 0x76 is HALT, we implement that elsewhere

  opcode_cycles[0x77] = 8
  opcodes[0x77] = function(self, reg, flags, mem) self.set_at_hl(reg.a) end

  opcodes[0x78] = function(self, reg, flags, mem) reg.a = reg.b end
  opcodes[0x79] = function(self, reg, flags, mem) reg.a = reg.c end
  opcodes[0x7A] = function(self, reg, flags, mem) reg.a = reg.d end
  opcodes[0x7B] = function(self, reg, flags, mem) reg.a = reg.e end
  opcodes[0x7C] = function(self, reg, flags, mem) reg.a = reg.h end
  opcodes[0x7D] = function(self, reg, flags, mem) reg.a = reg.l end
  opcode_cycles[0x7E] = 8
  opcodes[0x7E] = function(self, reg, flags, mem) reg.a = self.read_at_hl() end
  opcodes[0x7F] = function(self, reg, flags, mem) reg.a = reg.a end

  -- ld r, n
  opcode_cycles[0x06] = 8
  opcodes[0x06] = function(self, reg, flags, mem) reg.b = self.read_nn() end

  opcode_cycles[0x0E] = 8
  opcodes[0x0E] = function(self, reg, flags, mem) reg.c = self.read_nn() end

  opcode_cycles[0x16] = 8
  opcodes[0x16] = function(self, reg, flags, mem) reg.d = self.read_nn() end

  opcode_cycles[0x1E] = 8
  opcodes[0x1E] = function(self, reg, flags, mem) reg.e = self.read_nn() end

  opcode_cycles[0x26] = 8
  opcodes[0x26] = function(self, reg, flags, mem) reg.h = self.read_nn() end

  opcode_cycles[0x2E] = 8
  opcodes[0x2E] = function(self, reg, flags, mem) reg.l = self.read_nn() end

  opcode_cycles[0x36] = 12
  opcodes[0x36] = function(self, reg, flags, mem) self.set_at_hl(self.read_nn()) end

  opcode_cycles[0x3E] = 8
  opcodes[0x3E] = function(self, reg, flags, mem) reg.a = self.read_nn() end

  -- ld A, (xx)
  opcode_cycles[0x0A] = 8
  opcodes[0x0A] = function(self, reg, flags, mem)
    reg.a = mem[reg.bc()]
  end

  opcode_cycles[0x1A] = 8
  opcodes[0x1A] = function(self, reg, flags, mem)
    reg.a = mem[reg.de()]
  end

  opcode_cycles[0xFA] = 16
  opcodes[0xFA] = function(self, reg, flags, mem)
    local lower = self.read_nn()
    local upper = lshift(self.read_nn(), 8)
    reg.a = mem[upper + lower]
  end

  -- ld (xx), A
  opcode_cycles[0x02] = 8
  opcodes[0x02] = function(self, reg, flags, mem)
    mem[reg.bc()] = reg.a
  end

  opcode_cycles[0x12] = 8
  opcodes[0x12] = function(self, reg, flags, mem)
    mem[reg.de()] = reg.a
  end

  opcode_cycles[0xEA] = 16
  opcodes[0xEA] = function(self, reg, flags, mem)
    local lower = self.read_nn()
    local upper = lshift(self.read_nn(), 8)
    mem[upper + lower] = reg.a
  end

  -- ld a, (FF00 + nn)
  opcode_cycles[0xF0] = 12
  opcodes[0xF0] = function(self, reg, flags, mem)
    reg.a = mem[0xFF00 + self.read_nn()]
  end

  -- ld (FF00 + nn), a
  opcode_cycles[0xE0] = 12
  opcodes[0xE0] = function(self, reg, flags, mem)
    mem[0xFF00 + self.read_nn()] = reg.a
  end

  -- ld a, (FF00 + C)
  opcode_cycles[0xF2] = 8
  opcodes[0xF2] = function(self, reg, flags, mem)
    reg.a = mem[0xFF00 + reg.c]
  end

  -- ld (FF00 + C), a
  opcode_cycles[0xE2] = 8
  opcodes[0xE2] = function(self, reg, flags, mem)
    mem[0xFF00 + reg.c] = reg.a
  end

  -- ldi (HL), a
  opcode_cycles[0x22] = 8
  opcodes[0x22] = function(self, reg, flags, mem)
    self.set_at_hl(reg.a)
    reg.set_hl(band(reg.hl() + 1, 0xFFFF))
  end

  -- ldi a, (HL)
  opcode_cycles[0x2A] = 8
  opcodes[0x2A] = function(self, reg, flags, mem)
    reg.a = self.read_at_hl()
    reg.set_hl(band(reg.hl() + 1, 0xFFFF))
  end

  -- ldd (HL), a
  opcode_cycles[0x32] = 8
  opcodes[0x32] = function(self, reg, flags, mem)
    self.set_at_hl(reg.a)
    reg.set_hl(band(reg.hl() - 1, 0xFFFF))
  end

  -- ldd a, (HL)
  opcode_cycles[0x3A] = 8
  opcodes[0x3A] = function(self, reg, flags, mem)
    reg.a = self.read_at_hl()
    reg.set_hl(band(reg.hl() - 1, 0xFFFF))
  end

  -- ====== GMB 16-bit load commands ======
  -- ld BC, nnnn
  opcode_cycles[0x01] = 12
  opcodes[0x01] = function(self, reg, flags, mem)
    reg.c = self.read_nn()
    reg.b = self.read_nn()
  end

  -- ld DE, nnnn
  opcode_cycles[0x11] = 12
  opcodes[0x11] = function(self, reg, flags, mem)
    reg.e = self.read_nn()
    reg.d = self.read_nn()
  end

  -- ld HL, nnnn
  opcode_cycles[0x21] = 12
  opcodes[0x21] = function(self, reg, flags, mem)
    reg.l = self.read_nn()
    reg.h = self.read_nn()
  end

  -- ld SP, nnnn
  opcode_cycles[0x31] = 12
  opcodes[0x31] = function(self, reg, flags, mem)
    local lower = self.read_nn()
    local upper = lshift(self.read_nn(), 8)
    reg[2] = band(0xFFFF, upper + lower)
  end

  -- ld SP, HL
  opcode_cycles[0xF9] = 8
  opcodes[0xF9] = function(self, reg, flags, mem)
    reg[2] = reg.hl()
  end

  -- ld HL, SP + dd
  opcode_cycles[0xF8] = 12
  opcodes[0xF8] = function(self, reg, flags, mem)
    -- cheat
    local old_sp = reg.sp
    opcodes[0xE8]()
    reg.set_hl(reg[2])
    reg[2] = old_sp
  end

  -- ====== GMB Special Purpose / Relocated Commands ======
  -- ld (nnnn), SP
  opcode_cycles[0x08] = 20
  opcodes[0x08] = function(self, reg, flags, mem)
    local lower = self.read_nn()
    local upper = lshift(self.read_nn(), 8)
    local address = upper + lower
    mem[address] = band(reg[2], 0xFF)
    mem[band(address + 1, 0xFFFF)] = rshift(band(reg[2], 0xFF00), 8)
  end
end

return apply
