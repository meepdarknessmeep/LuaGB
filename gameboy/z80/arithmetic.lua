local bit32 = require("bit")

local band = bit32.band

function apply(opcodes, opcode_cycles)

  local function add_to_a (reg, flags, value)
    local a = reg.a
    -- half-carry
    flags[3] = band(a, 0xF) + band(value, 0xF) > 0xF

    local sum = a + value

    -- carry (and overflow correction)
    flags[4] = sum > 0xFF

    reg.a = band(sum, 0xFF)

    flags[1] = reg.a == 0
    flags[2] = false
  end

  local function adc_to_a (reg, flags, value)
    local a = reg.a
    -- half-carry
    local carry = 0
    if flags[4] then
      carry = 1
    end
    flags[3] = band(a, 0xF) + band(value, 0xF) + carry > 0xF
    local sum = a + value + carry

    -- carry (and overflow correction)
    flags[4] = sum > 0xFF
    reg.a = band(sum, 0xFF)

    flags[1] = reg.a == 0
    flags[2] = false
  end

  -- add A, r
  opcodes[0x80] = function(self, reg, flags) add_to_a(reg, flags, reg.b) end
  opcodes[0x81] = function(self, reg, flags) add_to_a(reg, flags, reg.c) end
  opcodes[0x82] = function(self, reg, flags) add_to_a(reg, flags, reg.d) end
  opcodes[0x83] = function(self, reg, flags) add_to_a(reg, flags, reg.e) end
  opcodes[0x84] = function(self, reg, flags) add_to_a(reg, flags, reg.h) end
  opcodes[0x85] = function(self, reg, flags) add_to_a(reg, flags, reg.l) end
  opcode_cycles[0x86] = 8
  opcodes[0x86] = function(self, reg, flags) add_to_a(reg, flags, self.read_at_hl()) end
  opcodes[0x87] = function(self, reg, flags) add_to_a(reg, flags, reg.a) end

  -- add A, nn
  opcode_cycles[0xC6] = 8
  opcodes[0xC6] = function(self, reg, flags) add_to_a(reg, flags, self.read_nn()) end

  -- adc A, r
  opcodes[0x88] = function(self, reg, flags) adc_to_a(reg, flags, reg.b) end
  opcodes[0x89] = function(self, reg, flags) adc_to_a(reg, flags, reg.c) end
  opcodes[0x8A] = function(self, reg, flags) adc_to_a(reg, flags, reg.d) end
  opcodes[0x8B] = function(self, reg, flags) adc_to_a(reg, flags, reg.e) end
  opcodes[0x8C] = function(self, reg, flags) adc_to_a(reg, flags, reg.h) end
  opcodes[0x8D] = function(self, reg, flags) adc_to_a(reg, flags, reg.l) end
  opcode_cycles[0x8E] = 8
  opcodes[0x8E] = function(self, reg, flags) adc_to_a(reg, flags, self.read_at_hl()) end
  opcodes[0x8F] = function(self, reg, flags) adc_to_a(reg, flags, reg.a) end

  -- adc A, nn
  opcode_cycles[0xCE] = 8
  opcodes[0xCE] = function(self, reg, flags) adc_to_a(reg, flags, self.read_nn()) end

  local function sub_from_a (reg, flags, value)
    local a = reg.a
    -- half-carry
    flags[3] = band(a, 0xF) - band(value, 0xF) < 0
    a = a - value

    -- carry (and overflow correction)
    flags[4] = a < 0 or a > 0xFF
    a = band(a, 0xFF)

    reg.a = a
    flags[1] = a == 0
    flags[2] = true
  end

  local function sbc_from_a (reg, flags, value)
    local a = reg.a
    local carry = 0
    if flags[4] then
      carry = 1
    end
    -- half-carry
    flags[3] = band(a, 0xF) - band(value, 0xF) - carry < 0

    local difference = a - value - carry

    -- carry (and overflow correction)
    flags[4] = difference < 0 or difference > 0xFF
    a = band(difference, 0xFF)

    reg.a = a
    flags[1] = a == 0
    flags[2] = true
  end

  -- sub A, r
  opcodes[0x90] = function(self, reg, flags) sub_from_a(reg, flags, reg.b) end
  opcodes[0x91] = function(self, reg, flags) sub_from_a(reg, flags, reg.c) end
  opcodes[0x92] = function(self, reg, flags) sub_from_a(reg, flags, reg.d) end
  opcodes[0x93] = function(self, reg, flags) sub_from_a(reg, flags, reg.e) end
  opcodes[0x94] = function(self, reg, flags) sub_from_a(reg, flags, reg.h) end
  opcodes[0x95] = function(self, reg, flags) sub_from_a(reg, flags, reg.l) end
  opcode_cycles[0x96] = 8
  opcodes[0x96] = function(self, reg, flags) sub_from_a(reg, flags, self.read_at_hl()) end
  opcodes[0x97] = function(self, reg, flags) sub_from_a(reg, flags, reg.a) end

  -- sub A, nn
  opcode_cycles[0xD6] = 8
  opcodes[0xD6] = function(self, reg, flags) sub_from_a(reg, flags, self.read_nn()) end

  -- sbc A, r
  opcodes[0x98] = function(self, reg, flags) sbc_from_a(reg, flags, reg.b) end
  opcodes[0x99] = function(self, reg, flags) sbc_from_a(reg, flags, reg.c) end
  opcodes[0x9A] = function(self, reg, flags) sbc_from_a(reg, flags, reg.d) end
  opcodes[0x9B] = function(self, reg, flags) sbc_from_a(reg, flags, reg.e) end
  opcodes[0x9C] = function(self, reg, flags) sbc_from_a(reg, flags, reg.h) end
  opcodes[0x9D] = function(self, reg, flags) sbc_from_a(reg, flags, reg.l) end
  opcode_cycles[0x9E] = 8
  opcodes[0x9E] = function(self, reg, flags) sbc_from_a(reg, flags, self.read_at_hl()) end
  opcodes[0x9F] = function(self, reg, flags) sbc_from_a(reg, flags, reg.a) end

  -- sbc A, nn
  opcode_cycles[0xDE] = 8
  opcodes[0xDE] = function(self, reg, flags) sbc_from_a(reg, flags, self.read_nn()) end

  -- daa
  -- BCD adjustment, correct implementation details located here:
  -- http://www.z80.info/z80syntx.htm#DAA
  opcodes[0x27] = function(self, reg, flags)
    local a = reg.a
    if not flags[2] then
      -- Addition Mode, adjust BCD for previous addition-like instruction
      if band(0xF, a) > 0x9 or flags[3] then
        a = a + 0x6
      end
      if a > 0x9F or flags[4] then
        a = a + 0x60
      end
    else
      -- Subtraction mode! Adjust BCD for previous subtraction-like instruction
      if flags[3] then
        a = band(a - 0x6, 0xFF)
      end
      if flags[4] then
        a = a - 0x60
      end
    end
    -- Always reset H and Z
    flags[3] = false
    flags[1] = false

    -- If a is greater than 0xFF, set the carry flag
    if band(0x100, a) == 0x100 then
      flags[4] = true
    end
    -- Note: Do NOT clear the carry flag otherwise. This is how hardware
    -- behaves, yes it's weird.

    a = band(a, 0xFF)
    reg.a = a
    -- Update zero flag based on A's contents
    flags[1] = a == 0
  end

  local function add_to_hl (reg, flags, value)
    -- half carry
    flags[3] = band(reg.hl(), 0xFFF) + band(value, 0xFFF) > 0xFFF
    local sum = reg.hl() + value

    -- carry
    flags[4] = sum > 0xFFFF or sum < 0x0000
    reg.set_hl(band(sum, 0xFFFF))
    flags[2] = false
  end

  -- add HL, rr
  opcode_cycles[0x09] = 8
  opcode_cycles[0x19] = 8
  opcode_cycles[0x29] = 8
  opcode_cycles[0x39] = 8
  opcodes[0x09] = function(self, reg, flags) add_to_hl(reg, flags, reg.bc()) end
  opcodes[0x19] = function(self, reg, flags) add_to_hl(reg, flags, reg.de()) end
  opcodes[0x29] = function(self, reg, flags) add_to_hl(reg, flags, reg.hl()) end
  opcodes[0x39] = function(self, reg, flags) add_to_hl(reg, flags, reg.sp) end

  -- inc rr
  opcode_cycles[0x03] = 8
  opcodes[0x03] = function(self, reg, flags)
    reg.set_bc(band(reg.bc() + 1, 0xFFFF))
  end

  opcode_cycles[0x13] = 8
  opcodes[0x13] = function(self, reg, flags)
    reg.set_de(band(reg.de() + 1, 0xFFFF))
  end

  opcode_cycles[0x23] = 8
  opcodes[0x23] = function(self, reg, flags)
    reg.set_hl(band(reg.hl() + 1, 0xFFFF))
  end

  opcode_cycles[0x33] = 8
  opcodes[0x33] = function(self, reg, flags)
    reg.sp = band(reg.sp + 1, 0xFFFF)
  end

  -- dec rr
  opcode_cycles[0x0B] = 8
  opcodes[0x0B] = function(self, reg, flags)
    reg.set_bc(band(reg.bc() - 1, 0xFFFF))
  end

  opcode_cycles[0x1B] = 8
  opcodes[0x1B] = function(self, reg, flags)
    reg.set_de(band(reg.de() - 1, 0xFFFF))
  end

  opcode_cycles[0x2B] = 8
  opcodes[0x2B] = function(self, reg, flags)
    reg.set_hl(band(reg.hl() - 1, 0xFFFF))
  end

  opcode_cycles[0x3B] = 8
  opcodes[0x3B] = function(self, reg, flags)
    reg.sp = band(reg.sp - 1, 0xFFFF)
  end

  -- add SP, dd
  opcode_cycles[0xE8] = 16
  opcodes[0xE8] = function(self, reg, flags)
    local offset = self.read_nn()
    -- offset comes in as unsigned 0-255, so convert it to signed -128 - 127
    if band(offset, 0x80) ~= 0 then
      offset = offset + 0xFF00
    end

    -- half carry
    --if band(reg.sp, 0xFFF) + offset > 0xFFF or band(reg.sp, 0xFFF) + offset < 0 then
    flags[3] = band(reg.sp, 0xF) + band(offset, 0xF) > 0xF
    -- carry
    flags[4] = band(reg.sp, 0xFF) + band(offset, 0xFF) > 0xFF

    reg.sp = reg.sp + offset
    reg.sp = band(reg.sp, 0xFFFF)

    flags[1] = false
    flags[2] = false
  end
end

return apply
