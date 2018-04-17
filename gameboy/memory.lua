local ffi = require "ffi"

local Memory = {}

local function loadtable(narr)
  local tbl = {}
  for i = 0, narr - 1 do
    tbl[i] = 0
  end
  return tbl
end

if (jit) then -- enable jit optimizations
  local initializer = {}
  for i = 1, 0x7ff do
    initializer[i] = 0
  end
  function loadtable(narr)
      local t = {[0] = 0, unpack(initializer, 1, math.min(0x7ff, narr))}
      for i = 0x800, narr do
        t[i] = 0
      end
      return t
  end
end

local loadbytes = loadtable

if (ffi) then
  function loadbytes(narr)
    return ffi.new("uint8_t[?]", narr + 1)
  end
end

function Memory.new(modules)

  local memory_mt = {}

  local memory = setmetatable(loadtable(0xFFFF), memory_mt)

  memory.hooks = {}

  function memory:create_block(size)
    return loadtable(size)
  end
  function memory:create_raw_memory(size)
    return loadbytes(size)
  end

  function memory:install_hooks(address_start, size, hooks)
    local hook = {
      hooks.getter,
      hooks.setter,
      hooks
    }
    for address = address_start, address_start + size - 1 do
      -- hooks.setter(hooks, address, self[address])
      rawset(self, address, nil)
      self.hooks[address] = hook
    end
  end

  local wram1 = {
    memory:create_raw_memory(4 * 7 * 1024)
  }

  memory.reset = function()
    -- It's tempting to want to zero out all 0x0000-0xFFFF, but
    -- instead here we'll reset only that memory which this module
    -- DIRECTLY controls, so initialization logic can be performed
    -- elsewhere as appropriate.

    for i = 0xC000, 0xCFFF do
      memory[i] = 0
    end

    for i = 0xD000, 0xDFFF do
      memory[i] = 0
    end

    wram1.bank = 1
  end

  memory.save_state = function()
    local state = {}

    state.work_ram_0 = {}
    for i = 0xC000, 0xCFFF do
      state.work_ram_0[i] = memory[i]
    end

    state.work_ram_1_raw = {}
    for i = 0xD000, (0xD000 + (4 * 7 * 1024) - 1) do
      state.work_ram_1_raw[i] = memory[i]
    end

    state.work_ram_1_bank = wram1.bank

    return state
  end

  memory.load_state = function(state)
    for i = 0xC000, 0xCFFF do
      memory[i] = state.work_ram_0[i]
    end
    for i = 0xD000, (0xD000 + (4 * 7 * 1024) - 1) do
      memory[i] = state.work_ram_1_raw[i]
    end

    wram1.bank = state.work_ram_1_bank
  end

  function memory:initialize()
    function memory_mt:__tostring()
      return "Gameboy MMU"
    end

    function memory_mt:__index(n)
      local hook = self.hooks[n]
      if (hook) then
        return hook[1](hook[3], n)
      end
      return self[n % 0x10000]
    end

    function memory_mt:__newindex(n, v)
      local hook = self.hooks[n]
      if (hook) then
        return hook[2](hook[3], n, v)
      end
      self[n % 0x10000] = n
    end
  end

  -- echo wram0
  function memory:getter(addr)
    return self[addr - 0xE000 + 0xC000]
  end
  function memory:setter(addr, value)
    self[addr - 0xE000 + 0xC000] = value
  end
  memory:install_hooks(0xE000, 4 * 1024, memory)


  wram1.bank = 0

  function wram1:getter(addr)
    return self[1][addr - 0xD000 + self.bank * 4096]
  end
  function wram1:setter(addr, value)
    self[1][addr - 0xD000 + self.bank * 4096] = value
  end
  memory:install_hooks(0xD000, 0x1000, wram1)

  function wram1:getter(addr)
    return self[1][addr - 0xF000 + self.bank * 4096]
  end
  function wram1:setter(addr, value)
    self[1][addr - 0xF000 + self.bank * 4096] = value
  end
  memory:install_hooks(0xF000, 0xE00, wram1)

  return memory
end

return Memory
