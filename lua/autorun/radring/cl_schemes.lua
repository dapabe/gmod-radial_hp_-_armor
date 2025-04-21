if SERVER then return end
--- Supposedly Color() is expensive, looking for a workaround to avoid it.

---@type iColorSchemes
local COLOR_SCHEMES = {
  default = {
    HP = Color(255, 0, 0),
    Armor = Color(0, 150, 255),
  },
  deuteranopia = {
    HP = Color(255, 255, 0),   -- Yellow
    Armor = Color(0, 200, 255),    -- Cyan
  },
  protanopia = {
    HP = Color(255, 128, 0),   -- Orange
    Armor = Color(0, 200, 255), -- Cyan
  },
  tritanopia = {
    HP = Color(255, 0, 0),     -- Red
    Armor = Color(255, 255, 0),    -- Yellow
  },
}

return COLOR_SCHEMES