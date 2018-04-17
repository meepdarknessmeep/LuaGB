local bit32 = require("bit")

local lshift = bit32.lshift
local rshift = bit32.rshift
local band = bit32.band
local bxor = bit32.bxor
local bor = bit32.bor
local bnot = bit32.bnot

local apply_arithmetic = require("gameboy/z80/arithmetic")
local apply_bitwise = require("gameboy/z80/bitwise")
local apply_call = require("gameboy/z80/call")
local apply_cp = require("gameboy/z80/cp")
local apply_inc_dec = require("gameboy/z80/inc_dec")
local apply_jp = require("gameboy/z80/jp")
local apply_ld = require("gameboy/z80/ld")
local apply_rl_rr_cb = require("gameboy/z80/rl_rr_cb")
local apply_stack = require("gameboy/z80/stack")

local opcodes = {}
local opcode_cycles = {}

local ffi, clock = require "ffi", os.clock
if (ffi and ffi.os == "Windows") then
  ffi.cdef [[
    extern int (__stdcall QueryPerformanceCounter)(uint64_t *lpPerformanceCount);
    extern int (__stdcall QueryPerformanceFrequency)(uint64_t *lpFrequency);
  ]]
  local time = ffi.new "uint64_t[1]"
  local freq = ffi.new "uint64_t[1]"

  ffi.C.QueryPerformanceFrequency(freq)
  clock = function()
    ffi.C.QueryPerformanceCounter(time)
    time[0] = time[0] * 1000000
    time[0] = time[0] / freq[0]
    return tonumber(time[0]) / 1000000
  end
  
end


-- Initialize the opcode_cycles table with 4 as a base cycle, so we only
-- need to care about variations going forward
for i = 0x00, 0xFF do
  opcode_cycles[i] = 4
end

local add_cycles_normal = function(self, cycles)
  self.timers.system_clock = self.timers.system_clock + cycles
end

local add_cycles_double = function(self, cycles)
  self.timers.system_clock = self.timers.system_clock + cycles / 2
end

apply_arithmetic(opcodes, opcode_cycles)
apply_bitwise(opcodes, opcode_cycles)
apply_call(opcodes, opcode_cycles)
apply_cp(opcodes, opcode_cycles)
apply_inc_dec(opcodes, opcode_cycles)
apply_jp(opcodes, opcode_cycles)
apply_ld(opcodes, opcode_cycles)
apply_rl_rr_cb(opcodes, opcode_cycles, z80, memory)
apply_stack(opcodes, opcode_cycles, z80, memory)

-- ====== GMB CPU-Controlcommands ======
-- ccf
opcodes[0x3F] = function(self, reg, flags)
  flags[4] = not flags[4]
  flags[2] = false
  flags[3] = false
end

-- scf
opcodes[0x37] = function(self, reg, flags)
  flags[4] = true
  flags[2] = false
  flags[3] = false
end

-- nop
opcodes[0x00] = function(self, reg, flags) end

-- halt
opcodes[0x76] = function(self, reg, flags)
  --if interrupts_enabled == 1 then
    --print("Halting!")
    self.halted = 1
  --else
    --print("Interrupts not enabled! Not actually halting...")
  --end
end

-- stop
opcodes[0x10] = function(self, reg, flags)
  -- The stop opcode should always, for unknown reasons, be followed
  -- by an 0x00 data byte. If it isn't, this may be a sign that the
  -- emulator has run off the deep end, and this isn't a real STOP
  -- instruction.
  -- TODO: Research real hardware's behavior in these cases
  local stop_value = read_nn()
  if stop_value == 0x00 then
    print("STOP instruction not followed by NOP!")
    --halted = 1
  else
    print("Unimplemented WEIRDNESS after 0x10")
  end

  if band(io[0x4D], 0x01) ~= 0 then
    --speed switch!
    print("Switching speeds!")
    if z80.double_speed then
      self.add_cycles = add_cycles_normal
      self.double_speed = false
      io[0x4D] = band(io[0x4D], 0x7E) + 0x00
      timers:set_normal_speed()
      print("Switched to Normal Speed")
    else
      self.add_cycles = add_cycles_double
      self.double_speed = true
      io[0x4D] = band(io[0x4D], 0x7E) + 0x80
      timers:set_double_speed()
      print("Switched to Double Speed")
    end
  end
end

-- di
opcodes[0xF3] = function(self, reg, flags)
  self.interrupts.disable()
  --print("Disabled interrupts with DI")
end
-- ei
opcodes[0xFB] = function(self, reg, flags)
  self.interrupts.enable()
  --print("Enabled interrupts with EI")
  self.service_interrupt()
end

-- For any opcodes that at this point are undefined,
-- go ahead and "define" them with the following panic
-- function
  local function undefined_opcode()
    local opcode = read_byte(band(reg[1] - 1, 0xFFFF))
    print(string.format("Unhandled opcode!: %x", opcode))
  end

for i = 0, 0xFF do
  if not opcodes[i] then
    opcodes[i] = undefined_opcode
  end
end

local Registers = require("gameboy/z80/registers")

local Z80 = {}

function Z80.new(modules)
  local z80 = {
    modules = modules,
    profiler = {}
  }
  for k, v in pairs(modules) do
    z80[k] = v
  end

  local interrupts = modules.interrupts
  local io = modules.io
  local memory = modules.memory
  local timers = modules.timers

  -- local references, for shorter code
  local read_byte = memory.read_byte
  local write_byte = memory.write_byte

  z80.write_byte = memory.write_byte
  z80.read_byte = memory.read_byte

  z80.registers = Registers.new()
  local reg = z80.registers
  local flags = reg.flags

  -- Intentionally bad naming convention: I am NOT typing "registers"
  -- a bazillion times. The exported symbol uses the full name as a
  -- reasonable compromise.
  z80.halted = 0

  z80.add_cycles = add_cycles_normal

  z80.double_speed = false

  z80.reset = function(gameboy)

    z80.gameboy = gameboy

    -- Initialize registers to what the GB's
    -- iternal state would be after executing
    -- BIOS code

    flags[1] = true
    flags[2] = false
    flags[3] = true
    flags[4] = true

    if gameboy.type == gameboy.types.color then
      reg.a = 0x11
    else
      reg.a = 0x01
    end

    reg.b = 0x00
    reg.c = 0x13
    reg.d = 0x00
    reg.e = 0xD8
    reg.h = 0x01
    reg.l = 0x4D
    reg[1] = 0x100 --entrypoint for GB games
    reg[2] = 0xFFFE

    z80.halted = 0

    z80.double_speed = false
    z80.add_cycles = add_cycles_normal
    timers:set_normal_speed()
  end

  z80.save_state = function()
    local state = {}
    state.double_speed = z80.double_speed
    state.registers = z80.registers
    state.halted = z80.halted
    return state
  end

  z80.load_state = function(state)
    -- Note: doing this explicitly for safety, so as
    -- not to replace the table with external, possibly old / wrong structure
    flags[1] = state.registers.flags[1]
    flags[2] = state.registers.flags[2]
    flags[3] = state.registers.flags[3]
    flags[4] = state.registers.flags[4]

    z80.registers.a = state.registers.a
    z80.registers.b = state.registers.b
    z80.registers.c = state.registers.c
    z80.registers.d = state.registers.d
    z80.registers.e = state.registers.e
    z80.registers.h = state.registers.h
    z80.registers.l = state.registers.l
    z80.registers[1] = state.registers[1]
    z80.registers[2] = state.registers.sp

    z80.double_speed = state.double_speed
    if z80.double_speed then
      timers:set_double_speed()
    else
      timers:set_normal_speed()
    end
    z80.halted = state.halted
  end

  io.write_mask[0x4D] = 0x01


  function z80.read_at_hl()
    return memory.read_byte(reg.h * 0x100 + reg.l)
  end

  function z80.set_at_hl(value)
    memory.write_byte(reg.h * 0x100 + reg.l, value)
  end

  function z80.read_nn()
    local nn = read_byte(reg[1])
    reg[1] = reg[1] + 1
    return nn
  end

  z80.service_interrupt = function()
    local fired = band(io[0xFF], io[0x0F])
    if fired ~= 0 then
      z80.halted = 0
      if interrupts.enabled ~= 0 then
        -- First, disable interrupts to prevent nesting routines (unless the program explicitly re-enables them later)
        interrupts.disable()

        -- Now, figure out which interrupt this is, and call the corresponding
        -- interrupt vector
        local vector = 0x40
        local count = 0
        while band(fired, 0x1) == 0 and count < 5 do
          vector = vector + 0x08
          fired = rshift(fired, 1)
          count = count + 1
        end
        -- we need to clear the corresponding bit first, to avoid infinite loops
        io[0x0F] = bxor(lshift(0x1, count), io[0x0F])

        reg[2] = band(0xFFFF, reg[2] - 1)
        write_byte(reg[2], rshift(band(reg[1], 0xFF00), 8))
        reg[2] = band(0xFFFF, reg[2] - 1)
        write_byte(reg[2], band(reg[1], 0xFF))

        reg[1] = vector

        z80:add_cycles(12)
        return true
      end
    end
    return false
  end

  -- register this as a callback with the interrupts module
  interrupts.service_handler = z80.service_interrupt

  z80.process_instruction = function()
    local profiling, start_time, fake_opcode, extrabits = z80.gameboy and z80.gameboy.profiling
    --  If the processor is currently halted, then do nothing.d
    if z80.halted == 0 then
      local opcode = read_byte(reg[1])
      -- Advance to one byte beyond the opcode
      reg[1] = band(reg[1] + 1, 0xFFFF)
      -- Run the instruction
      if (profiling) then
        fake_opcode = opcode
        extrabits = 0
        if (opcode == 0xE0 or opcode == 0xF0) then -- io write
          fake_opcode = bit.lshift(opcode, 8) + read_byte(reg[1])
          extrabits = 8
        end
        start_time = clock()
      end

      opcodes[opcode](z80, reg, flags)

      if (profiling) then
        local time_elapsed = clock() - start_time
        local profile = z80.profiler[fake_opcode]
        if (not profile) then
          profile = {
            time = 0,
            calls = 0,
            extrabits = extrabits
          }
          z80.profiler[fake_opcode] = profile
        end

        profile.time = profile.time + time_elapsed
        profile.calls = profile.calls + 1
      end

      -- add a base clock of 4 to every instruction
      -- NOPE, working on removing add_cycles, pull from the opcode_cycles
      -- table instead
      z80:add_cycles(opcode_cycles[opcode])
    else
      -- Base cycles of 4 when halted, for sanity
      z80:add_cycles(4)
    end

    return true
  end

  return z80
end

return Z80
