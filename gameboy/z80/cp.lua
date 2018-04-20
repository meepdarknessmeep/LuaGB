function apply(opcodes, opcode_cycles)

  local function cp_with_a (reg, flags, value)
    -- half-carry
    flags[3] = (reg[3] % 0x10) - (value % 0x10) < 0

    local temp = reg[3] - value

    -- carry (and overflow correction)
    flags[4] = temp < 0 or temp > 0xFF
    temp  = (temp + 0x100) % 0x100

    flags[1] = temp == 0
    flags[2] = true
  end

  -- cp A, r
  opcodes[0xB8] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[4]) end
  opcodes[0xB9] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[5]) end
  opcodes[0xBA] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[6]) end
  opcodes[0xBB] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[7]) end
  opcodes[0xBC] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[9]) end
  opcodes[0xBD] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[10]) end
  opcode_cycles[0xBE] = 8
  opcodes[0xBE] = function(self, reg, flags, mem) cp_with_a(reg, flags, self.read_at_hl()) end
  opcodes[0xBF] = function(self, reg, flags, mem) cp_with_a(reg, flags, reg[3]) end

  -- cp A, nn
  opcode_cycles[0xFE] = 8
  opcodes[0xFE] = function(self, reg, flags, mem) cp_with_a(reg, flags, self.read_nn()) end
end

return apply
