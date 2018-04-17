local bit32 = require("bit")

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band

function apply(opcodes, opcode_cycles)

  local function call_nnnn (self, reg, flags, mem)
    local pc = reg[1]
    local lower = mem[pc]
    local upper = mem[pc + 1] * 256

    -- store the current PC to the stack

    local sp = reg[2]

    mem[(sp + 0xFFFF) % 0x10000] = rshift(pc + 2, 8)
    sp = (sp + 0xFFFE) % 0x10000
    reg[2] = sp
    mem[sp] = (pc + 2) % 0x100

    reg[1] = upper + lower
  end

  -- call nn
  opcode_cycles[0xCD] = 24
  opcodes[0xCD] = call_nnnn

  -- call nz, nnnn
  opcode_cycles[0xC4] = 12
  opcodes[0xC4] = function(self, reg, flags, mem)
    if not flags[1] then
      call_nnnn(self, reg, nil, mem)
      self:add_cycles(12)
    else
      reg[1] = reg[1] + 2
    end
  end

  -- call nc, nnnn
  opcode_cycles[0xD4] = 12
  opcodes[0xD4] = function(self, reg, flags, mem)
    if not flags[4] then
      call_nnnn(self, reg, nil, mem)
      self:add_cycles(12)
    else
      reg[1] = reg[1] + 2
    end
  end

  -- call z, nnnn
  opcode_cycles[0xCC] = 12
  opcodes[0xCC] = function(self, reg, flags, mem)
    if flags[1] then
      call_nnnn(self, reg, nil, mem)
      self:add_cycles(12)
    else
      reg[1] = reg[1] + 2
    end
  end

  -- call c, nnnn
  opcode_cycles[0xDC] = 12
  opcodes[0xDC] = function(self, reg, flags, mem)
    if flags[4] then
      call_nnnn(self, reg, nil, mem)
      self:add_cycles(12)
    else
      reg[1] = reg[1] + 2
    end
  end

  local function ret (self, reg, flags, mem)
    local lower = mem[reg[2]]
    reg[2] = band(0xFFFF, reg[2] + 1)
    local upper = lshift(mem[reg[2]], 8)
    reg[2] = band(0xFFFF, reg[2] + 1)
    reg[1] = upper + lower
    self:add_cycles(12)
  end

  -- ret
  opcodes[0xC9] = ret

  -- ret nz
  opcode_cycles[0xC0] = 8
  opcodes[0xC0] = function(self, reg, flags, mem)
    if not flags[1] then
      ret(self, reg, nil, mem)
    end
  end

  -- ret nc
  opcode_cycles[0xD0] = 8
  opcodes[0xD0] = function(self, reg, flags, mem)
    if not flags[4] then
      ret(self, reg, nil, mem)
    end
  end

  -- ret z
  opcode_cycles[0xC8] = 8
  opcodes[0xC8] = function(self, reg, flags, mem)
    if flags[1] then
      ret(self, reg, nil, mem)
    end
  end

  -- ret c
  opcode_cycles[0xD8] = 8
  opcodes[0xD8] = function(self, reg, flags, mem)
    if flags[4] then
      ret(self, reg, nil, mem)
    end
  end

  -- reti
  opcodes[0xD9] = function(self, reg, flags, mem)
    ret(self, reg, nil, mem)
    self.modules.interrupts.enable()
    self.service_interrupt()
  end

  -- note: used only for the RST instructions below
  local function call_address (self, reg, mem, address)
    -- reg[1] points at the next instruction after the call,
    -- so store the current PC to the stack
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = rshift(band(reg[1], 0xFF00), 8)
    reg[2] = band(0xFFFF, reg[2] - 1)
    mem[reg[2]] = band(reg[1], 0xFF)

    reg[1] = address
  end

  -- rst N
  opcode_cycles[0xC7] = 16
  opcodes[0xC7] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x00) end

  opcode_cycles[0xCF] = 16
  opcodes[0xCF] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x08) end

  opcode_cycles[0xD7] = 16
  opcodes[0xD7] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x10) end

  opcode_cycles[0xDF] = 16
  opcodes[0xDF] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x18) end

  opcode_cycles[0xE7] = 16
  opcodes[0xE7] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x20) end

  opcode_cycles[0xEF] = 16
  opcodes[0xEF] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x28) end

  opcode_cycles[0xF7] = 16
  opcodes[0xF7] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x30) end

  opcode_cycles[0xFF] = 16
  opcodes[0xFF] = function(self, reg, flags, mem) call_address(self, reg, mem, 0x38) end
end

return apply
