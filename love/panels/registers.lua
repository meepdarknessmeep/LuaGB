local registers = {}

registers.width = 160 * 2

local vertical_spacing = 7

registers.init = function(gameboy)
  registers.canvas = love.graphics.newCanvas(160, 400)
  registers.gameboy = gameboy
end

registers.draw = function(x, y)
  love.graphics.setCanvas(registers.canvas)
  love.graphics.clear()
  love.graphics.setColor(0.75, 0.75, 0.75)
  love.graphics.rectangle("fill", 0, 0, 160, 400)
  registers.print_values(registers.gameboy)
  love.graphics.setCanvas() -- reset to main FB
  love.graphics.setColor(1, 1, 1)
  love.graphics.push()
  love.graphics.scale(2, 2)
  love.graphics.draw(registers.canvas, x / 2, y / 2)
  love.graphics.pop()
end

registers.print_registers = function(gameboy, x, y)
  local function get_register(name)
    return function() return gameboy.processor.registers[name] end
  end

  local registers = {
    {0, 0, 0, "A", get_register("a"), 0, 0},
    {0, 0, 0, "F", gameboy.processor.registers.f, 1, 0},
    {0, 0, 0, "B", get_register("b"), 0, 1},
    {0, 0, 0, "C", get_register("c"), 1, 1},
    {0, 0, 0, "D", get_register("d"), 0, 2},
    {0, 0, 0, "E", get_register("e"), 1, 2},
    {0, 0, 0, "H", get_register("h"), 0, 3},
    {0, 0, 0, "L", get_register("l"), 1, 3}
  }

  for _, register in ipairs(registers) do
    local r, g, b = register[1], register[2], register[3]
    local name, accessor = register[4], register[5]
    local rx, ry = register[6], register[7]

    love.graphics.setColor(r, g, b)
    love.graphics.print(string.format("%s: %02X", name, accessor()), x + rx * 30, y + ry * vertical_spacing)
  end
  love.graphics.setColor(1, 1, 1)
end

registers.print_wide_registers = function(gameboy, x, y)
  local wide_registers = {
    {0, 0, 0, "BC", "bc"},
    {0, 0, 0, "DE", "de"},
    {0, 0, 0, "HL", "hl"}
  }

  local ry = 0
  for _, register in ipairs(wide_registers) do
    local r, g, b = register[1], register[2], register[3]
    local name, accessor = register[4], register[5]
    local value = gameboy.processor.registers[accessor]()
    local indirect_value = gameboy.memory[value]

    love.graphics.setColor(r, g, b)
    love.graphics.print(string.format("%s: %04X (%s): %02X", name, value, name, indirect_value), x, y + ry)
    ry = ry + vertical_spacing
  end
  love.graphics.setColor(1, 1, 1)
end

registers.print_flags = function(gameboy, x, y)
  local function flag_string(flag) return gameboy.processor.registers.flags[flag] == true and flag or "" end
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(string.format("Flags: [%1s %1s %1s %1s]", flag_string("c"), flag_string("n"), flag_string("h"), flag_string("z")), x, y)
  love.graphics.setColor(1, 1, 1)
end

registers.print_pointer_registers = function(gameboy, x, y)
  local pointer_registers = {
    {0, 0, 0, "SP", 2},
    {0, 0, 0, "PC", 1}
  }

  local ry = 0
  for _, register in ipairs(pointer_registers) do
    local r, g, b = register[1], register[2], register[3]
    local name, accessor = register[4], register[5]
    local value = gameboy.processor.registers[accessor]

    love.graphics.setColor(r, g, b)
    love.graphics.print(string.format("%s: %04X (%s): %02X %02X %02X %02X", name, value, name,
                                      gameboy.memory[value],
                                      gameboy.memory[value + 1],
                                      gameboy.memory[value + 2],
                                      gameboy.memory[value + 3]), x, y + ry)
    ry = ry + vertical_spacing
  end
end

registers.print_status_block = function(gameboy, x, y)
  local status = {
    {"Frame", function() return gameboy.graphics.vblank_count end},
    {"Clock", function() return gameboy.timers.system_clock end}
  }
  love.graphics.setColor(0, 0, 0)
  local rx = 0
  for _, state in ipairs(status) do
    local name, accessor = state[1], state[2]

    love.graphics.print(string.format("%s: %d", name, accessor()), x + rx, y)
    rx = rx + 64
  end

  love.graphics.print(string.format("Halted: %d  IME: %d  IE: %02X  IF: %02X",
    gameboy.processor.halted,
    gameboy.interrupts.enabled,
    gameboy.memory[0xFFFF],
    gameboy.memory[0xFF0F]), x, y + vertical_spacing)
end

registers.print_values = function(gameboy)
  local grid = {
    x = {0, 80, 160, 380},
    y = {0, 24, 48, 72, 120, 144, 168}
  }

  registers.print_registers(gameboy, 4, 4)
  registers.print_wide_registers(gameboy, 64, 4)
  registers.print_flags(gameboy, 64, vertical_spacing * 3 + 4)
  registers.print_pointer_registers(gameboy, 4, vertical_spacing * 5 + 4)
  registers.print_status_block(gameboy, 4, vertical_spacing * 8 + 4)
end

return registers
