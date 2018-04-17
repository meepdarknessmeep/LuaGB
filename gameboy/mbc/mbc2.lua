local bit32 = require("bit")

local Mbc2 = {}

function Mbc2.new()
  local mbc2 = {}
  mbc2.raw_data = {}
  mbc2.external_ram = {}
  mbc2.rom_bank = 1
  mbc2.ram_enable = false
  function mbc2:getter(address)
    -- Lower 16k: return the first bank, always
    if address <= 0x3FFF then
      return self.raw_data[address]
    end
    -- Upper 16k: return the currently selected bank
    if address >= 0x4000 and address <= 0x7FFF then
      local rom_bank = self.rom_bank
      return self.raw_data[(rom_bank * 16 * 1024) + (address - 0x4000)]
    end

    if address >= 0xA000 and address <= 0xA1FF and self.ram_enable then
      -- For MBC2, only the lower 4 bits of each RAM byte are available for use
      return bit32.band(0x0F, self.external_ram[(address - 0xA000)])
    end

    return 0x00
  end
  function mbc2:setter(address, value)
    if address <= 0x1FFF and bit32.band(address, 0x0100) == 0 then
      if bit32.band(0x0A, value) == 0x0A then
        self.ram_enable = true
      else
        self.ram_enable = false
      end
      return
    end
    if address >= 0x2000 and address <= 0x3FFF and bit32.band(address, 0x0100) ~= 0 then
      -- Select the ROM bank (4 bits)
      value = bit32.band(value, 0x0F)
      if value == 0 then
        value = 1
      end
      self.rom_bank = value
      return
    end

    -- Handle actually writing to External RAM
    if address >= 0xA000 and address <= 0xBFFF and self.ram_enable then
      self.external_ram[(address - 0xA000)] = bit32.band(0x0F, value)
      self.cartridge.external_ram_dirty = true
      return
    end
  end

  mbc2.reset = function(self)
    self.rom_bank = 1
    self.ram_enable = false
  end

  mbc2.save_state = function(self)
    return {rom_bank = self.rom_bank, ram_enable = self.ram_enable}
  end

  mbc2.load_state = function(self, state_data)
    self:reset()

    self.rom_bank = state_data.rom_bank
    self.ram_enable = state_data.ram_enable
  end

  return mbc2
end

return Mbc2
