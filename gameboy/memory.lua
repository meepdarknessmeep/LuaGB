local bit32 = require("bit")

local brshift = bit32.rshift

local Memory = {}

function Memory.new(modules)
  local memory = {}

  local invalid_map_mt = {
    __index = function(self, offset)
      error(string.format("failure to read data from %04X", offset + self.base))
    end,
    __newindex = function(self, offset, value)
      error(string.format("failure to write data from %04X", offset + self.base))
    end,
    __eq = function() return true end
  }
  setmetatable(invalid_map_mt, invalid_map_mt)

  -- high byte index
  local high_byte_base_address = {[0] = 0}
  local high_byte_map = {[0] = setmetatable({base = 0}, invalid_map_mt)}
  for i = 1, 0xff do
    local base = bit.lshift(i, 8)
    table.insert(high_byte_base_address, base)
    table.insert(high_byte_map, setmetatable({
      base = base
    }, invalid_map_mt))
  end


  memory.print_block_map = function()
    --debug
    print("Block Map: ")
    for b = 0, 0xFF do
      local map = high_byte_map[b]
      if (map ~= invalid_map_mt) then
        print(string.format("Block at: %02X starts at %04X", b, map.base))
      end
    end
  end

  memory.map_block = function(starting_high_byte, ending_high_byte, mapped_block, starting_address)
    if starting_high_byte > 0xFF or ending_high_byte > 0xFF then
      print("Bad block, bailing", starting_high_byte, ending_high_byte)
      return
    end

    rawset(mapped_block, "base", bit.lshift(starting_high_byte, 8))

    for i = starting_high_byte, ending_high_byte do
      high_byte_base_address[i] = mapped_block.base
      high_byte_map[i] = mapped_block
    end

    memory.print_block_map()
  end

  memory.generate_block = function(size, starting_address)
    starting_address = starting_address or 0
    local block = {}
    for i = starting_address, starting_address + size - 1 do
      block[i] = 0
    end
    return block
  end

  local echo_mt = {
    __index = function(self, offset)
      return self.echo[offset - self.base + self.echo.base]
    end,
    __newindex = function(self, offset, value)
      self.echo[offset - self.base + self.echo.base] = value
    end
  }

  -- Main Memory
  memory.work_ram_0 = memory.generate_block(4 * 1024, 0xC000)
  memory.work_ram_1_raw = memory.generate_block(4 * 7 * 1024, 0xD000)
  memory.work_ram_1 = {}
  memory.work_ram_1.bank = 1
  memory.work_ram_1.mt = {}
  memory.work_ram_1.mt.__index = function(table, address)
    return memory.work_ram_1_raw[address + ((memory.work_ram_1.bank - 1) * 4 * 1024)]
  end
  memory.work_ram_1.mt.__newindex = function(table, address, value)
    memory.work_ram_1_raw[address + ((memory.work_ram_1.bank - 1) * 4 * 1024)] = value
  end
  setmetatable(memory.work_ram_1, memory.work_ram_1.mt)
  memory.map_block(0xC0, 0xCF, memory.work_ram_0, 0)
  memory.map_block(0xE0, 0xEF, setmetatable({
    echo = memory.work_ram_0
  }, echo_mt))
  memory.map_block(0xD0, 0xDF, memory.work_ram_1, 0)
  memory.map_block(0xF0, 0xFD, setmetatable({
    echo = memory.work_ram_1
  }, echo_mt))

  memory.read_byte = function(address)
    local high_byte = brshift(address, 8)
    return high_byte_map[high_byte][address]
  end

  memory.write_byte = function(address, byte)
    local high_byte = brshift(address, 8)
    high_byte_map[high_byte][address] = byte
  end

  memory.get_map = function(high_byte)
    return high_byte_map[high_byte]
  end

  memory.reset = function()
    -- It's tempting to want to zero out all 0x0000-0xFFFF, but
    -- instead here we'll reset only that memory which this module
    -- DIRECTLY controls, so initialization logic can be performed
    -- elsewhere as appropriate.

    for i = 0xC000, 0xCFFF do
      memory.work_ram_0[i] = 0
    end

    for i = 0xD000, 0xDFFF do
      memory.work_ram_1[i] = 0
    end

    memory.work_ram_1.bank = 1
  end

  memory.save_state = function()
    local state = {}

    state.work_ram_0 = {}
    for i = 0xC000, 0xCFFF do
      state.work_ram_0[i] = memory.work_ram_0[i]
    end

    state.work_ram_1_raw = {}
    for i = 0xD000, (0xD000 + (4 * 7 * 1024) - 1) do
      state.work_ram_1_raw[i] = memory.work_ram_1_raw[i]
    end

    state.work_ram_1_bank = 1

    return state
  end

  memory.load_state = function(state)
    for i = 0xC000, 0xCFFF do
      memory.work_ram_0[i] = state.work_ram_0[i]
    end
    for i = 0xD000, (0xD000 + (4 * 7 * 1024) - 1) do
      memory.work_ram_1_raw[i] = state.work_ram_1_raw[i]
    end

    memory.work_ram_1.bank = state.work_ram_1_bank
  end

  -- Fancy: make access to ourselves act as an array, reading / writing memory using the above
  -- logic. This should cause memory[address] to behave just as it would on hardware.
  memory.mt = {}
  memory.mt.__index = function(table, key)
    return memory.read_byte(key)
  end
  memory.mt.__newindex = function(table, key, value)
    memory.write_byte(key, value)
  end
  setmetatable(memory, memory.mt)

  return memory
end

return Memory
