

local opcode_names = require("gameboy/opcode_names")

local profiler = {}

profiler.width = 256 * 2

function profiler:onactivate(state)
  self.gameboy.profiling = state
  self.gameboy.processor.profiler = {}
end

profiler.init = function(gameboy)
  profiler.canvas = love.graphics.newCanvas(256, 400)
  profiler.gameboy = gameboy
  --profiler.background_image = love.graphics.newImage("images/debug_profiler_background.png")
end

profiler.draw = function(x, y)
  love.graphics.setCanvas(profiler.canvas)
  love.graphics.clear()
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("fill", x, y, 256, 400)
  --love.graphics.draw(profiler.background_image, 0, 0)
  profiler.print_opcodes(profiler.gameboy)
  love.graphics.setCanvas() -- reset to main FB
  love.graphics.setColor(1, 1, 1)
  love.graphics.push()
  love.graphics.scale(2, 2)
  love.graphics.draw(profiler.canvas, x / 2, y / 2)
  love.graphics.pop()
end

local opcode_string = function(opcode)
  local name = opcode_names[opcode]
  return name
end

profiler.print_opcodes = function(gameboy)
  local y = 15
  local darken_rows = 0
  love.graphics.setColor(0.5, 0.5, 0.5)
  love.graphics.rectangle("fill", 0, 14, 256, 7)
  local worst_offenders = {}

  local total = 0
  for opcode, profile in pairs(profiler.gameboy.processor.profiler) do
    table.insert(worst_offenders, {
      time = profile.time,
      calls = profile.calls,
      extrabits = profile.extrabits,
      opcode = opcode
    })
    total = total + profile.time
  end

  table.sort(worst_offenders, function(a, b) return a.time > b.time end)

  for i = 1, math.floor((400 - 15) / 10) do
    local offender = worst_offenders[i]
    if (not offender) then
      break
    end
    local name = opcode_string(bit.rshift(offender.opcode, offender.extrabits))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("[%04X] %s - %0.2fus (%.02f%%)", offender.opcode, name, offender.time / offender.calls * 1000000, offender.time / total * 100), 4, y)
    y = y + 10
  end
end

return profiler
