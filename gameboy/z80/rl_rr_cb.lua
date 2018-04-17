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
  opcodes[0x07] = function(self, reg, flags, mem) reg.a = reg_rlc(flags, reg.a); flags[1] = false end

  -- rl a
  opcodes[0x17] = function(self, reg, flags, mem) reg.a = reg_rl(flags, reg.a); flags[1] = false end

  -- rrc a
  opcodes[0x0F] = function(self, reg, flags, mem) reg.a = reg_rrc(flags, reg.a); flags[1] = false end

  -- rr a
  opcodes[0x1F] = function(self, reg, flags, mem) reg.a = reg_rr(flags, reg.a); flags[1] = false end

  -- ====== CB: Extended Rotate and Shift ======

  cb = {}

  -- rlc r
  cb[0x00] = function(self, reg, flags, mem) reg.b = reg_rlc(flags, reg.b); self:add_cycles(4) end
  cb[0x01] = function(self, reg, flags, mem) reg.c = reg_rlc(flags, reg.c); self:add_cycles(4) end
  cb[0x02] = function(self, reg, flags, mem) reg.d = reg_rlc(flags, reg.d); self:add_cycles(4) end
  cb[0x03] = function(self, reg, flags, mem) reg.e = reg_rlc(flags, reg.e); self:add_cycles(4) end
  cb[0x04] = function(self, reg, flags, mem) reg.h = reg_rlc(flags, reg.h); self:add_cycles(4) end
  cb[0x05] = function(self, reg, flags, mem) reg.l = reg_rlc(flags, reg.l); self:add_cycles(4) end
  cb[0x06] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_rlc(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x07] = function(self, reg, flags, mem) reg.a = reg_rlc(flags, reg.a); self:add_cycles(4) end

  -- rl r
  cb[0x10] = function(self, reg, flags, mem) reg.b = reg_rl(flags, reg.b); self:add_cycles(4) end
  cb[0x11] = function(self, reg, flags, mem) reg.c = reg_rl(flags, reg.c); self:add_cycles(4) end
  cb[0x12] = function(self, reg, flags, mem) reg.d = reg_rl(flags, reg.d); self:add_cycles(4) end
  cb[0x13] = function(self, reg, flags, mem) reg.e = reg_rl(flags, reg.e); self:add_cycles(4) end
  cb[0x14] = function(self, reg, flags, mem) reg.h = reg_rl(flags, reg.h); self:add_cycles(4) end
  cb[0x15] = function(self, reg, flags, mem) reg.l = reg_rl(flags, reg.l); self:add_cycles(4) end
  cb[0x16] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_rl(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x17] = function(self, reg, flags, mem) reg.a = reg_rl(flags, reg.a); self:add_cycles(4) end

  -- rrc r
  cb[0x08] = function(self, reg, flags, mem) reg.b = reg_rrc(flags, reg.b); self:add_cycles(4) end
  cb[0x09] = function(self, reg, flags, mem) reg.c = reg_rrc(flags, reg.c); self:add_cycles(4) end
  cb[0x0A] = function(self, reg, flags, mem) reg.d = reg_rrc(flags, reg.d); self:add_cycles(4) end
  cb[0x0B] = function(self, reg, flags, mem) reg.e = reg_rrc(flags, reg.e); self:add_cycles(4) end
  cb[0x0C] = function(self, reg, flags, mem) reg.h = reg_rrc(flags, reg.h); self:add_cycles(4) end
  cb[0x0D] = function(self, reg, flags, mem) reg.l = reg_rrc(flags, reg.l); self:add_cycles(4) end
  cb[0x0E] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_rrc(flags, mem[reg.hl()])
    self:add_cycles(12)
  end
  cb[0x0F] = function(self, reg, flags, mem) reg.a = reg_rrc(flags, reg.a); self:add_cycles(4) end

  -- rl r
  cb[0x18] = function(self, reg, flags, mem) reg.b = reg_rr(flags, reg.b); self:add_cycles(4) end
  cb[0x19] = function(self, reg, flags, mem) reg.c = reg_rr(flags, reg.c); self:add_cycles(4) end
  cb[0x1A] = function(self, reg, flags, mem) reg.d = reg_rr(flags, reg.d); self:add_cycles(4) end
  cb[0x1B] = function(self, reg, flags, mem) reg.e = reg_rr(flags, reg.e); self:add_cycles(4) end
  cb[0x1C] = function(self, reg, flags, mem) reg.h = reg_rr(flags, reg.h); self:add_cycles(4) end
  cb[0x1D] = function(self, reg, flags, mem) reg.l = reg_rr(flags, reg.l); self:add_cycles(4) end
  cb[0x1E] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_rr(flags, mem[reg.hl()])
    self:add_cycles(12) 
  end
  cb[0x1F] = function(self, reg, flags, mem) reg.a = reg_rr(flags, reg.a); self:add_cycles(4) end

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
  cb[0x20] = function(self, reg, flags, mem) reg.b = reg_sla(self, flags, reg.b) end
  cb[0x21] = function(self, reg, flags, mem) reg.c = reg_sla(self, flags, reg.c) end
  cb[0x22] = function(self, reg, flags, mem) reg.d = reg_sla(self, flags, reg.d) end
  cb[0x23] = function(self, reg, flags, mem) reg.e = reg_sla(self, flags, reg.e) end
  cb[0x24] = function(self, reg, flags, mem) reg.h = reg_sla(self, flags, reg.h) end
  cb[0x25] = function(self, reg, flags, mem) reg.l = reg_sla(self, flags, reg.l) end
  cb[0x26] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_sla(self, flags, mem[reg.hl()]) 
    self:add_cycles(8) 
  end
  cb[0x27] = function(self, reg, flags, mem) reg.a = reg_sla(self, flags, reg.a) end

  -- swap r (high and low nybbles)
  cb[0x30] = function(self, reg, flags, mem) reg.b = reg_swap(self, flags, reg.b) end
  cb[0x31] = function(self, reg, flags, mem) reg.c = reg_swap(self, flags, reg.c) end
  cb[0x32] = function(self, reg, flags, mem) reg.d = reg_swap(self, flags, reg.d) end
  cb[0x33] = function(self, reg, flags, mem) reg.e = reg_swap(self, flags, reg.e) end
  cb[0x34] = function(self, reg, flags, mem) reg.h = reg_swap(self, flags, reg.h) end
  cb[0x35] = function(self, reg, flags, mem) reg.l = reg_swap(self, flags, reg.l) end
  cb[0x36] = function(self, reg, flags, mem) 
    mem[reg.hl()] = reg_swap(self, flags, mem[reg.hl()])
    self:add_cycles(8) 
  end
  cb[0x37] = function(self, reg, flags, mem) reg.a = reg_swap(self, flags, reg.a) end

  -- sra r
  cb[0x28] = function(self, reg, flags, mem) reg.b = reg_sra(self, flags, reg.b); self:add_cycles(-4) end
  cb[0x29] = function(self, reg, flags, mem) reg.c = reg_sra(self, flags, reg.c); self:add_cycles(-4) end
  cb[0x2A] = function(self, reg, flags, mem) reg.d = reg_sra(self, flags, reg.d); self:add_cycles(-4) end
  cb[0x2B] = function(self, reg, flags, mem) reg.e = reg_sra(self, flags, reg.e); self:add_cycles(-4) end
  cb[0x2C] = function(self, reg, flags, mem) reg.h = reg_sra(self, flags, reg.h); self:add_cycles(-4) end
  cb[0x2D] = function(self, reg, flags, mem) reg.l = reg_sra(self, flags, reg.l); self:add_cycles(-4) end
  cb[0x2E] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_sra(self, flags, mem[reg.hl()])
    self:add_cycles(4) 
  end
  cb[0x2F] = function(self, reg, flags, mem) reg.a = reg_sra(self, flags, reg.a); self:add_cycles(-4) end

  -- srl r
  cb[0x38] = function(self, reg, flags, mem) reg.b = reg_srl(self, flags, reg.b) end
  cb[0x39] = function(self, reg, flags, mem) reg.c = reg_srl(self, flags, reg.c) end
  cb[0x3A] = function(self, reg, flags, mem) reg.d = reg_srl(self, flags, reg.d) end
  cb[0x3B] = function(self, reg, flags, mem) reg.e = reg_srl(self, flags, reg.e) end
  cb[0x3C] = function(self, reg, flags, mem) reg.h = reg_srl(self, flags, reg.h) end
  cb[0x3D] = function(self, reg, flags, mem) reg.l = reg_srl(self, flags, reg.l) end
  cb[0x3E] = function(self, reg, flags, mem)
    mem[reg.hl()] = reg_srl(self, flags, mem[reg.hl()])
    self:add_cycles(8) 
  end
  cb[0x3F] = function(self, reg, flags, mem) reg.a = reg_srl(self, flags, reg.a) end

  -- ====== GMB Singlebit Operation Commands ======
  local function reg_bit (flags, value, bit)
    flags[1] = band(value, lshift(0x1, bit)) == 0
    flags[2] = false
    flags[3] = true
    return
  end

  opcodes[0xCB] = function(self, reg, flags, mem)
    local cb_op = self.read_nn()
    self:add_cycles(4)
    if cb[cb_op] ~= nil then
      --revert the timing; this is handled automatically by the various functions
      self:add_cycles(-4)
      cb[cb_op](self, reg, flags, mem)
      return
    end
    local high_half_nybble = rshift(band(cb_op, 0xC0), 6)
    local reg_index = band(cb_op, 0x7)
    local bit = rshift(band(cb_op, 0x38), 3)
    if high_half_nybble == 0x1 then
      -- bit n,r
      if reg_index == 0 then reg_bit(flags, reg.b, bit) end
      if reg_index == 1 then reg_bit(flags, reg.c, bit) end
      if reg_index == 2 then reg_bit(flags, reg.d, bit) end
      if reg_index == 3 then reg_bit(flags, reg.e, bit) end
      if reg_index == 4 then reg_bit(flags, reg.h, bit) end
      if reg_index == 5 then reg_bit(flags, reg.l, bit) end
      if reg_index == 6 then reg_bit(flags, mem[reg.hl()], bit); self:add_cycles(4) end
      if reg_index == 7 then reg_bit(flags, reg.a, bit) end
    end
    if high_half_nybble == 0x2 then
      -- res n, r
      -- note: this is REALLY stupid, but it works around some floating point
      -- limitations in Lua.
      if reg_index == 0 then reg.b = band(reg.b, bxor(reg.b, lshift(0x1, bit))) end
      if reg_index == 1 then reg.c = band(reg.c, bxor(reg.c, lshift(0x1, bit))) end
      if reg_index == 2 then reg.d = band(reg.d, bxor(reg.d, lshift(0x1, bit))) end
      if reg_index == 3 then reg.e = band(reg.e, bxor(reg.e, lshift(0x1, bit))) end
      if reg_index == 4 then reg.h = band(reg.h, bxor(reg.h, lshift(0x1, bit))) end
      if reg_index == 5 then reg.l = band(reg.l, bxor(reg.l, lshift(0x1, bit))) end
      if reg_index == 6 then mem[reg.hl()] = band(mem[reg.hl()], bxor(mem[reg.hl()], lshift(0x1, bit))); self:add_cycles(8) end
      if reg_index == 7 then reg.a = band(reg.a, bxor(reg.a, lshift(0x1, bit))) end
    end

    if high_half_nybble == 0x3 then
      -- set n, r
      if reg_index == 0 then reg.b = bor(lshift(0x1, bit), reg.b) end
      if reg_index == 1 then reg.c = bor(lshift(0x1, bit), reg.c) end
      if reg_index == 2 then reg.d = bor(lshift(0x1, bit), reg.d) end
      if reg_index == 3 then reg.e = bor(lshift(0x1, bit), reg.e) end
      if reg_index == 4 then reg.h = bor(lshift(0x1, bit), reg.h) end
      if reg_index == 5 then reg.l = bor(lshift(0x1, bit), reg.l) end
      if reg_index == 6 then mem[reg.hl()] = bor(lshift(0x1, bit), mem[reg.hl()]); self:add_cycles(8) end
      if reg_index == 7 then reg.a = bor(lshift(0x1, bit), reg.a) end
    end
  end
end

return apply
