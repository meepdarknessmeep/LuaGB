local bit32 = require("bit")

local Mbc5 = {}

function Mbc5.new()
  local mbc5 = {}
  mbc5.raw_data = {}
  mbc5.external_ram = {}
  mbc5.rom_bank = 0
  mbc5.ram_bank = 0
  mbc5.ram_enable = false
  mbc5.rumble_pak = false
  mbc5.rumbling = false

  function mbc5:getter(address)
    -- Lower 16k: return the first bank, always
    if address <= 0x3FFF then
      return self.raw_data[address]
    end
    -- Upper 16k: return the currently selected bank
    if address >= 0x4000 and address <= 0x7FFF then
      local rom_bank = self.rom_bank
      return self.raw_data[(rom_bank * 16 * 1024) + (address - 0x4000)]
    end

    if address >= 0xA000 and address <= 0xBFFF and self.ram_enable then
      local ram_bank = self.ram_bank
      return self.external_ram[(address - 0xA000) + (ram_bank * 8 * 1024)]
    end
    return 0x00
  end
  function mbc5:setter(address, value)
    if address <= 0x1FFF then
      if bit32.band(0x0A, value) == 0x0A then
        self.ram_enable = true
      else
        self.ram_enable = false
      end
      return
    end
    if address >= 0x2000 and address <= 0x2FFF then
      -- Write the lower 8 bits of the ROM bank
      self.rom_bank = bit32.band(self.rom_bank, 0xFF00) + value
      return
    end
    if address >= 0x3000 and address <= 0x3FFF then
      -- Write the upper 1 bits of the ROM bank
      self.rom_bank = bit32.band(self.rom_bank, 0xFF) + bit32.lshift(bit32.band(value, 0x01), 8)
      print("Switched (high) to rom bank: ", self.rom_bank)
      return
    end
    if address >= 0x4000 and address <= 0x5FFF then
      local ram_mask = 0x0F
      if self.rumble_pak then
        ram_mask = 0x7
      end
      self.ram_bank = bit32.band(value, ram_mask)
      if bit32.band(value, 0x08) ~= 0 and self.rumbling == false then
        --print("Rumble on!")
        self.rumbling = true
      end
      if bit32.band(value, 0x08) ~= 0 and self.rumbling == true then
        --print("Rumble off!")
        self.rumbling = false
      end
      return
    end

    -- Handle actually writing to External RAM
    if address >= 0xA000 and address <= 0xBFFF and self.ram_enable then
      local ram_bank = self.ram_bank
      self.external_ram[(address - 0xA000) + (ram_bank * 8 * 1024)] = value
      self.cartridge.external_ram_dirty = true
      return
    end
  end

  mbc5.reset = function(self)
    self.rom_bank = 1
    self.ram_bank = 0
    self.ram_enable = false
  end

  mbc5.save_state = function(self)
    return {
      rom_bank = self.rom_bank,
      ram_bank = self.ram_bank,
      ram_enable = self.ram_enable,
      rumble_pak = self.rumble_pak}
  end

  mbc5.load_state = function(self, state_data)
    self:reset()

    self.rom_bank = state_data.rom_bank
    self.ram_bank = state_data.ram_bank
    self.ram_enable = state_data.ram_enable
    self.rumble_pak = state_data.rumble_pak
    self.rumbling = false
  end

  return mbc5
end

return Mbc5
