if SERVER then return end


--- Sqr2 | Vertices
DistanceThreshold = {
  Small = {2250000, 10}, -- 1500^2 
  Medium = {4000000, 8}, -- 2000^2
  Large = {6250000, 6}, -- 2500^2
}

---@type iColorSchemes
COLOR_SCHEMES = {
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
