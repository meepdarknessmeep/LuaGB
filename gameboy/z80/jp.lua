local bit32 = require("bit")

local lshift = bit32.lshift

function apply(opcodes, opcode_cycles)

  -- ====== GMB Jumpcommands ======
  local function jump_to_nnnn (self, reg)
    local lower = self.read_nn()
    local upper = lshift(self.read_nn(), 8)
    reg.pc = upper + lower
  end

  -- jp nnnn
  opcode_cycles[0xC3] = 16
  opcodes[0xC3] = function(self, reg, flags)
    jump_to_nnnn(self, reg)
  end

  -- jp HL
  opcodes[0xE9] = function(self, reg, flags)
    reg.pc = reg.hl()
  end

  -- jp nz, nnnn
  opcode_cycles[0xC2] = 16
  opcodes[0xC2] = function(self, reg, flags)
    if not flags.z then
      jump_to_nnnn(self, reg)
    else
      reg.pc = reg.pc + 2
      self:add_cycles(-4)
    end
  end

  -- jp nc, nnnn
  opcode_cycles[0xD2] = 16
  opcodes[0xD2] = function(self, reg, flags)
    if not flags.c then
      jump_to_nnnn(self, reg)
    else
      reg.pc = reg.pc + 2
      self:add_cycles(-4)
    end
  end

  -- jp z, nnnn
  opcode_cycles[0xCA] = 16
  opcodes[0xCA] = function(self, reg, flags)
    if flags.z then
      jump_to_nnnn(self, reg)
    else
      reg.pc = reg.pc + 2
      self:add_cycles(-4)
    end
  end

  -- jp c, nnnn
  opcode_cycles[0xDA] = 16
  opcodes[0xDA] = function(self, reg, flags)
    if flags.c then
      jump_to_nnnn(self, reg)
    else
      reg.pc = reg.pc + 2
      self:add_cycles(-4)
    end
  end

  local function jump_relative_to_nn (self, reg)
    local offset = self.read_nn()
    if offset > 127 then
      offset = offset - 256
    end
    reg.pc = (reg.pc + offset) % 0x10000
  end

  -- jr nn
  opcode_cycles[0x18] = 12
  opcodes[0x18] = function(self, reg, flags)
    jump_relative_to_nn(self, reg)
  end

  -- jr nz, nn
  opcode_cycles[0x20] = 12
  opcodes[0x20] = function(self, reg, flags)
    if not flags.z then
      jump_relative_to_nn(self, reg)
    else
      reg.pc = reg.pc + 1
      self:add_cycles(-4)
    end
  end

  -- jr nc, nn
  opcode_cycles[0x30] = 12
  opcodes[0x30] = function(self, reg, flags)
    if not flags.c then
      jump_relative_to_nn(self, reg)
    else
      reg.pc = reg.pc + 1
      self:add_cycles(-4)
    end
  end

  -- jr z, nn
  opcode_cycles[0x28] = 12
  opcodes[0x28] = function(self, reg, flags)
    if flags.z then
      jump_relative_to_nn(self, reg)
    else
      reg.pc = reg.pc + 1
      self:add_cycles(-4)
    end
  end

  -- jr c, nn
  opcode_cycles[0x38] = 12
  opcodes[0x38] = function(self, reg, flags)
    if flags.c then
      jump_relative_to_nn(self, reg)
    else
      reg.pc = reg.pc + 1
      self:add_cycles(-4)
    end
  end
end

return apply
