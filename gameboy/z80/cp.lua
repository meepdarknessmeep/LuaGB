function apply(opcodes, opcode_cycles)

  local function cp_with_a (reg, flags, value)
    -- half-carry
    flags.h = (reg.a % 0x10) - (value % 0x10) < 0

    local temp = reg.a - value

    -- carry (and overflow correction)
    flags.c = temp < 0 or temp > 0xFF
    temp  = (temp + 0x100) % 0x100

    flags.z = temp == 0
    flags.n = true
  end

  -- cp A, r
  opcodes[0xB8] = function(self, reg, flags) cp_with_a(reg, flags, reg.b) end
  opcodes[0xB9] = function(self, reg, flags) cp_with_a(reg, flags, reg.c) end
  opcodes[0xBA] = function(self, reg, flags) cp_with_a(reg, flags, reg.d) end
  opcodes[0xBB] = function(self, reg, flags) cp_with_a(reg, flags, reg.e) end
  opcodes[0xBC] = function(self, reg, flags) cp_with_a(reg, flags, reg.h) end
  opcodes[0xBD] = function(self, reg, flags) cp_with_a(reg, flags, reg.l) end
  opcode_cycles[0xBE] = 8
  opcodes[0xBE] = function(self, reg, flags) cp_with_a(reg, flags, self.read_at_hl()) end
  opcodes[0xBF] = function(self, reg, flags) cp_with_a(reg, flags, reg.a) end

  -- cp A, nn
  opcode_cycles[0xFE] = 8
  opcodes[0xFE] = function(self, reg, flags) cp_with_a(reg, flags, self.read_nn()) end
end

return apply
