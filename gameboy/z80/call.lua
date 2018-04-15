local bit32 = require("bit")

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band

function apply(opcodes, opcode_cycles)

  local function call_nnnn (self, reg)
    local lower = self.read_nn()
    local upper = self.read_nn() * 256
    -- at this point, reg.pc points at the next instruction after the call,
    -- so store the current PC to the stack

    reg.sp = (reg.sp + 0xFFFF) % 0x10000
    self.write_byte(reg.sp, rshift(reg.pc, 8))
    reg.sp = (reg.sp + 0xFFFF) % 0x10000
    self.write_byte(reg.sp, reg.pc % 0x100)

    reg.pc = upper + lower
  end

  -- call nn
  opcode_cycles[0xCD] = 24
  opcodes[0xCD] = call_nnnn

  -- call nz, nnnn
  opcode_cycles[0xC4] = 12
  opcodes[0xC4] = function(self, reg, flags)
    if not flags.z then
      call_nnnn(self, reg)
      self:add_cycles(12)
    else
      reg.pc = reg.pc + 2
    end
  end

  -- call nc, nnnn
  opcode_cycles[0xD4] = 12
  opcodes[0xD4] = function(self, reg, flags)
    if not flags.c then
      call_nnnn(self, reg)
      self:add_cycles(12)
    else
      reg.pc = reg.pc + 2
    end
  end

  -- call z, nnnn
  opcode_cycles[0xCC] = 12
  opcodes[0xCC] = function(self, reg, flags)
    if flags.z then
      call_nnnn(self, reg)
      self:add_cycles(12)
    else
      reg.pc = reg.pc + 2
    end
  end

  -- call c, nnnn
  opcode_cycles[0xDC] = 12
  opcodes[0xDC] = function(self, reg, flags)
    if flags.c then
      call_nnnn(self, reg)
      self:add_cycles(12)
    else
      reg.pc = reg.pc + 2
    end
  end

  local function ret (self, reg)
    local lower = self.read_byte(reg.sp)
    reg.sp = band(0xFFFF, reg.sp + 1)
    local upper = lshift(self.read_byte(reg.sp), 8)
    reg.sp = band(0xFFFF, reg.sp + 1)
    reg.pc = upper + lower
    self:add_cycles(12)
  end

  -- ret
  opcodes[0xC9] = ret

  -- ret nz
  opcode_cycles[0xC0] = 8
  opcodes[0xC0] = function(self, reg, flags)
    if not flags.z then
      ret(self, reg)
    end
  end

  -- ret nc
  opcode_cycles[0xD0] = 8
  opcodes[0xD0] = function(self, reg, flags)
    if not flags.c then
      ret(self, reg)
    end
  end

  -- ret z
  opcode_cycles[0xC8] = 8
  opcodes[0xC8] = function(self, reg, flags)
    if flags.z then
      ret(self, reg)
    end
  end

  -- ret c
  opcode_cycles[0xD8] = 8
  opcodes[0xD8] = function(self, reg, flags)
    if flags.c then
      ret(self, reg)
    end
  end

  -- reti
  opcodes[0xD9] = function(self, reg, flags)
    ret(self, reg)
    self.modules.interrupts.enable()
    self.service_interrupt()
  end

  -- note: used only for the RST instructions below
  local function call_address (self, reg, address)
    -- reg.pc points at the next instruction after the call,
    -- so store the current PC to the stack
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, rshift(band(reg.pc, 0xFF00), 8))
    reg.sp = band(0xFFFF, reg.sp - 1)
    self.write_byte(reg.sp, band(reg.pc, 0xFF))

    reg.pc = address
  end

  -- rst N
  opcode_cycles[0xC7] = 16
  opcodes[0xC7] = function(self, reg, flags) call_address(self, reg, 0x00) end

  opcode_cycles[0xCF] = 16
  opcodes[0xCF] = function(self, reg, flags) call_address(self, reg, 0x08) end

  opcode_cycles[0xD7] = 16
  opcodes[0xD7] = function(self, reg, flags) call_address(self, reg, 0x10) end

  opcode_cycles[0xDF] = 16
  opcodes[0xDF] = function(self, reg, flags) call_address(self, reg, 0x18) end

  opcode_cycles[0xE7] = 16
  opcodes[0xE7] = function(self, reg, flags) call_address(self, reg, 0x20) end

  opcode_cycles[0xEF] = 16
  opcodes[0xEF] = function(self, reg, flags) call_address(self, reg, 0x28) end

  opcode_cycles[0xF7] = 16
  opcodes[0xF7] = function(self, reg, flags) call_address(self, reg, 0x30) end

  opcode_cycles[0xFF] = 16
  opcodes[0xFF] = function(self, reg, flags) call_address(self, reg, 0x38) end
end

return apply
