local bit32 = require("bit")

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band
local bxor = bit32.bxor
local bor = bit32.bor
local bnor = bit32.bnor

function apply(opcodes, opcode_cycles)
  -- ====== GMB Rotate and Shift Commands ======
  local function reg_rlc (flags, value)
    value = lshift(value, 1)
    -- move what would be bit 8 into the carry
    flags[4] = band(value, 0x100) ~= 0
    value = band(value, 0xFF)
    -- also copy the carry into bit 0
    if flags[4] then
      value = value + 1
    end
    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    return value
  end

  local function reg_rl (flags, value)
    value = lshift(value, 1)
    -- move the carry into bit 0
    if flags[4] then
      value = value + 1
    end
    -- now move what would be bit 8 into the carry
    flags[4] = band(value, 0x100) ~= 0
    value = band(value, 0xFF)

    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    return value
  end

  local function reg_rrc (flags, value)
    -- move bit 0 into the carry
    flags[4] = band(value, 0x1) ~= 0
    value = rshift(value, 1)
    -- also copy the carry into bit 7
    if flags[4] then
      value = value + 0x80
    end
    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    return value
  end

  local function reg_rr (flags, value)
    -- first, copy the carry into bit 8 (!!)
    if flags[4] then
      value = value + 0x100
    end
    -- move bit 0 into the carry
    flags[4] = band(value, 0x1) ~= 0
    value = rshift(value, 1)
    -- for safety, this should be a nop?
    -- value = band(value, 0xFF)
    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    return value
  end

  -- rlc a
  opcodes[0x07] = function(self, reg, flags, mem) reg[3] = reg_rlc(flags, reg[3]); flags[1] = false end

  -- rl a
  opcodes[0x17] = function(self, reg, flags, mem) reg[3] = reg_rl(flags, reg[3]); flags[1] = false end

  -- rrc a
  opcodes[0x0F] = function(self, reg, flags, mem) reg[3] = reg_rrc(flags, reg[3]); flags[1] = false end

  -- rr a
  opcodes[0x1F] = function(self, reg, flags, mem) reg[3] = reg_rr(flags, reg[3]); flags[1] = false end

  -- ====== CB: Extended Rotate and Shift ======

  cb = {}

  -- rlc r
  cb[0x00] = function(self, reg, flags, mem) reg[4] = reg_rlc(flags, reg[4]); self:add_cycles(4) end
  cb[0x01] = function(self, reg, flags, mem) reg[5] = reg_rlc(flags, reg[5]); self:add_cycles(4) end
  cb[0x02] = function(self, reg, flags, mem) reg[6] = reg_rlc(flags, reg[6]); self:add_cycles(4) end
  cb[0x03] = function(self, reg, flags, mem) reg[7] = reg_rlc(flags, reg[7]); self:add_cycles(4) end
  cb[0x04] = function(self, reg, flags, mem) reg[9] = reg_rlc(flags, reg[9]); self:add_cycles(4) end
  cb[0x05] = function(self, reg, flags, mem) reg[10] = reg_rlc(flags, reg[10]); self:add_cycles(4) end
  cb[0x06] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_rlc(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x07] = function(self, reg, flags, mem) reg[3] = reg_rlc(flags, reg[3]); self:add_cycles(4) end

  -- rl r
  cb[0x10] = function(self, reg, flags, mem) reg[4] = reg_rl(flags, reg[4]); self:add_cycles(4) end
  cb[0x11] = function(self, reg, flags, mem) reg[5] = reg_rl(flags, reg[5]); self:add_cycles(4) end
  cb[0x12] = function(self, reg, flags, mem) reg[6] = reg_rl(flags, reg[6]); self:add_cycles(4) end
  cb[0x13] = function(self, reg, flags, mem) reg[7] = reg_rl(flags, reg[7]); self:add_cycles(4) end
  cb[0x14] = function(self, reg, flags, mem) reg[9] = reg_rl(flags, reg[9]); self:add_cycles(4) end
  cb[0x15] = function(self, reg, flags, mem) reg[10] = reg_rl(flags, reg[10]); self:add_cycles(4) end
  cb[0x16] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_rl(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x17] = function(self, reg, flags, mem) reg[3] = reg_rl(flags, reg[3]); self:add_cycles(4) end

  -- rrc r
  cb[0x08] = function(self, reg, flags, mem) reg[4] = reg_rrc(flags, reg[4]); self:add_cycles(4) end
  cb[0x09] = function(self, reg, flags, mem) reg[5] = reg_rrc(flags, reg[5]); self:add_cycles(4) end
  cb[0x0A] = function(self, reg, flags, mem) reg[6] = reg_rrc(flags, reg[6]); self:add_cycles(4) end
  cb[0x0B] = function(self, reg, flags, mem) reg[7] = reg_rrc(flags, reg[7]); self:add_cycles(4) end
  cb[0x0C] = function(self, reg, flags, mem) reg[9] = reg_rrc(flags, reg[9]); self:add_cycles(4) end
  cb[0x0D] = function(self, reg, flags, mem) reg[10] = reg_rrc(flags, reg[10]); self:add_cycles(4) end
  cb[0x0E] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_rrc(flags, mem[reg.hl()])
    self:add_cycles(12)
  end
  cb[0x0F] = function(self, reg, flags, mem) reg[3] = reg_rrc(flags, reg[3]); self:add_cycles(4) end

  -- rl r
  cb[0x18] = function(self, reg, flags, mem) reg[4] = reg_rr(flags, reg[4]); self:add_cycles(4) end
  cb[0x19] = function(self, reg, flags, mem) reg[5] = reg_rr(flags, reg[5]); self:add_cycles(4) end
  cb[0x1A] = function(self, reg, flags, mem) reg[6] = reg_rr(flags, reg[6]); self:add_cycles(4) end
  cb[0x1B] = function(self, reg, flags, mem) reg[7] = reg_rr(flags, reg[7]); self:add_cycles(4) end
  cb[0x1C] = function(self, reg, flags, mem) reg[9] = reg_rr(flags, reg[9]); self:add_cycles(4) end
  cb[0x1D] = function(self, reg, flags, mem) reg[10] = reg_rr(flags, reg[10]); self:add_cycles(4) end
  cb[0x1E] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_rr(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x1F] = function(self, reg, flags, mem) reg[3] = reg_rr(flags, reg[3]); self:add_cycles(4) end

  local function reg_sla (self, flags, value)
    -- copy bit 7 into carry
    flags[4] = band(value, 0x80) == 0x80
    value = band(lshift(value, 1), 0xFF)
    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    self:add_cycles(4)
    return value
  end

  local function reg_srl (self, flags, value)
    -- copy bit 0 into carry
    flags[4] = band(value, 0x1) == 1
    value = rshift(value, 1)
    flags[1] = value == 0
    flags[3] = false
    flags[2] = false
    self:add_cycles(4)
    return value
  end

  local function reg_sra (self, flags, value)
    local arith_value = reg_srl(self, flags, value)
    -- if bit 6 is set, copy it to bit 7
    if band(arith_value, 0x40) ~= 0 then
      arith_value = arith_value + 0x80
    end
    self:add_cycles(4)
    return arith_value
  end

  local function reg_swap (self, flags, value)
    value = rshift(band(value, 0xF0), 4) + lshift(band(value, 0xF), 4)
    flags[1] = value == 0
    flags[2] = false
    flags[3] = false
    flags[4] = false
    self:add_cycles(4)
    return value
  end

  -- sla r
  cb[0x20] = function(self, reg, flags, mem) reg[4] = reg_sla(self, flags, reg[4]) end
  cb[0x21] = function(self, reg, flags, mem) reg[5] = reg_sla(self, flags, reg[5]) end
  cb[0x22] = function(self, reg, flags, mem) reg[6] = reg_sla(self, flags, reg[6]) end
  cb[0x23] = function(self, reg, flags, mem) reg[7] = reg_sla(self, flags, reg[7]) end
  cb[0x24] = function(self, reg, flags, mem) reg[9] = reg_sla(self, flags, reg[9]) end
  cb[0x25] = function(self, reg, flags, mem) reg[10] = reg_sla(self, flags, reg[10]) end
  cb[0x26] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_sla(self, flags, mem[reg.hl()]) 
    self:add_cycles(8) 
  end
  cb[0x27] = function(self, reg, flags, mem) reg[3] = reg_sla(self, flags, reg[3]) end

  -- swap r (high and low nybbles)
  cb[0x30] = function(self, reg, flags, mem) reg[4] = reg_swap(self, flags, reg[4]) end
  cb[0x31] = function(self, reg, flags, mem) reg[5] = reg_swap(self, flags, reg[5]) end
  cb[0x32] = function(self, reg, flags, mem) reg[6] = reg_swap(self, flags, reg[6]) end
  cb[0x33] = function(self, reg, flags, mem) reg[7] = reg_swap(self, flags, reg[7]) end
  cb[0x34] = function(self, reg, flags, mem) reg[9] = reg_swap(self, flags, reg[9]) end
  cb[0x35] = function(self, reg, flags, mem) reg[10] = reg_swap(self, flags, reg[10]) end
  cb[0x36] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_swap(self, flags, mem[reg.hl()])
    self:add_cycles(8) 
  end
  cb[0x37] = function(self, reg, flags, mem) reg[3] = reg_swap(self, flags, reg[3]) end

  -- sra r
  cb[0x28] = function(self, reg, flags, mem) reg[4] = reg_sra(self, flags, reg[4]); self:add_cycles(-4) end
  cb[0x29] = function(self, reg, flags, mem) reg[5] = reg_sra(self, flags, reg[5]); self:add_cycles(-4) end
  cb[0x2A] = function(self, reg, flags, mem) reg[6] = reg_sra(self, flags, reg[6]); self:add_cycles(-4) end
  cb[0x2B] = function(self, reg, flags, mem) reg[7] = reg_sra(self, flags, reg[7]); self:add_cycles(-4) end
  cb[0x2C] = function(self, reg, flags, mem) reg[9] = reg_sra(self, flags, reg[9]); self:add_cycles(-4) end
  cb[0x2D] = function(self, reg, flags, mem) reg[10] = reg_sra(self, flags, reg[10]); self:add_cycles(-4) end
  cb[0x2E] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_sra(self, flags, mem[reg.hl()])
    self:add_cycles(4) 
  end
  cb[0x2F] = function(self, reg, flags, mem) reg[3] = reg_sra(self, flags, reg[3]); self:add_cycles(-4) end

  -- srl r
  cb[0x38] = function(self, reg, flags, mem) reg[4] = reg_srl(self, flags, reg[4]) end
  cb[0x39] = function(self, reg, flags, mem) reg[5] = reg_srl(self, flags, reg[5]) end
  cb[0x3A] = function(self, reg, flags, mem) reg[6] = reg_srl(self, flags, reg[6]) end
  cb[0x3B] = function(self, reg, flags, mem) reg[7] = reg_srl(self, flags, reg[7]) end
  cb[0x3C] = function(self, reg, flags, mem) reg[9] = reg_srl(self, flags, reg[9]) end
  cb[0x3D] = function(self, reg, flags, mem) reg[10] = reg_srl(self, flags, reg[10]) end
  cb[0x3E] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_srl(self, flags, mem[reg.hl()])
    self:add_cycles(8) 
  end
  cb[0x3F] = function(self, reg, flags, mem) reg[3] = reg_srl(self, flags, reg[3]) end

  -- ====== GMB Singlebit Operation Commands ======
  local function reg_bit (flags, value, bit)
    flags[1] = band(value, lshift(0x1, bit)) == 0
    flags[2] = false
    flags[3] = true
    return
  end

  local indices = {
    [0] = 4,
    5,
    6,
    7,
    8,
    9,
    nil,
    3
  }
  opcodes[0xCB] = function(self, reg, flags, mem)
    local cb_op = self.read_nn()
    if cb[cb_op] ~= nil then
      cb[cb_op](self, reg, flags, mem)
      return
    end
    self:add_cycles(4)
    local high_half_nybble = rshift(band(cb_op, 0xC0), 6)
    local reg_index = band(cb_op, 0x7)
    local bit = rshift(band(cb_op, 0x38), 3)
    if high_half_nybble == 0x1 then
      -- bit n,r
      local val = indices[reg_index]
      if (not val) then
        reg_bit(flags, mem[reg.hl()], bit)
        self:add_cycles(4)
        return
      end

      reg_bit(flags, reg[val], bit)
    elseif high_half_nybble == 0x2 then
      -- res n, r
      -- note: this is REALLY stupid, but it works around some floating point
      -- limitations in Lua.
      local val = indices[reg_index]
      if (not val) then
        mem[reg.hl()] = band(mem[reg.hl()], bxor(mem[reg.hl()], lshift(0x1, bit)))
        self:add_cycles(8)
        return
      end

      local n = reg[val]
      reg[val] = band(n, bxor(n, lshift(0x1, bit)))
    elseif high_half_nybble == 0x3 then
      -- set n, r
      local val = indices[reg_index]
      if (not val) then
        mem[reg.hl()] = bor(lshift(0x1, bit), mem[reg.hl()])
        self:add_cycles(8)
        return
      end

      reg[val] = bor(lshift(0x1, bit), reg[val])
    end
  end
end

return apply
