---@class DrawMeth
---@field private HpCache table<integer, number>
---@field private ArmorCache table<integer, number>
---@field private HpAnimated table<integer, number>
---@field private ArmorAnimated table<integer, number>
---@field DrawRadialHPArmor fun(self, baseRadius: number)

---@class DrawMeth
local DrawMeth = {
  HpCache = {},
  ArmorCache = {},
  HpAnimated = {},
  ArmorAnimated = {},
}

---[[
--- Store local references to global functions for micro-optimization.
--- Since this is render code, every little bit counts.
---]]
local sin, cos, rad, floor, clamp, lerp = math.sin, math.cos, math.rad, math.floor, math.Clamp, Lerp

---@param x number
---@param y number
---@param radius number
---@param thickness number
---@param startAngle number
---@param endAngle number
---@param segments number
local function generateRingPoints(x, y, radius, thickness, startAngle, endAngle, segments)
  local points = {}

  for i = 0, segments do
    local t = i / segments
    local angle = rad(lerp(t, startAngle, endAngle))
    local ox, oy = cos(angle), sin(angle)

    points[i + 1] = {
      inner = { x = x + ox * (radius - thickness), y = y + oy * (radius - thickness) },
      outer = { x = x + ox * radius, y = y + oy * radius }
    }
  end

  return points
end

---@param x number
---@param y number
---@param outerRadius number
---@param thickness number
---@param startAngle number
---@param endAngle number
---@param hpPercent number
local function drawRadialBar(x, y, outerRadius, thickness, startAngle, endAngle, hpPercent)
  -- Interpolate segment count between 6 (low quality) and 100 (smooth) based on hpPercent
  local segments = floor(lerp(hpPercent, 6, 100))
  local points = generateRingPoints(x, y, outerRadius, thickness, startAngle, endAngle, segments)
  draw.NoTexture()

  for i = 1, #points - 1 do
    surface.DrawPoly({
      points[i].outer,
      points[i + 1].outer,
      points[i + 1].inner,
      points[i].inner,
    })
  end
end

local diskLocation = Vector(0, 0, 0.2)

-- local function isVisible(pos)
--   local ply = LocalPlayer()
--   local trace = util.TraceLine({
--       start = ply:EyePos(),
--       endpos = pos,
--       filter = ply
--   })
--   return trace.Fraction == 1
-- end

function DrawMeth:DrawRadialHPArmor(baseRadius)
  local me = LocalPlayer()

  for _, pl in ipairs(player.GetAll()) do
    if not IsValid(pl) or not pl:Alive() or me == pl then continue end
    if me:GetPos():DistToSqr(pl:GetPos()) > (3000 * 3000) then continue end

    local id = pl:EntIndex()
    local maxHealth = pl:GetMaxHealth()
    local hp = clamp(pl:Health(), 0, maxHealth)
    local hpPercent = hp / maxHealth
    local armorPercent = clamp(pl:Armor(), 0, 100) / 100

    -- Store the raw values in HpCache / ArmorCache if needed.
    self.HpCache[id] = hpPercent
    self.ArmorCache[id] = armorPercent

    -- Animate HP: Interpolate from the previous animated value to the current hpPercent.
    local currentHp = self.HpAnimated[id] or hpPercent
    local animatedHp = lerp(FrameTime() * 10, currentHp, hpPercent)
    self.HpAnimated[id] = animatedHp

    -- Animate Armor: Interpolate from the previous animated value to the current armorPercent.
    local currentArmor = self.ArmorAnimated[id] or armorPercent
    local animatedArmor = lerp(FrameTime() * 10, currentArmor, armorPercent)
    self.ArmorAnimated[id] = animatedArmor

    local entSize = pl:OBBMaxs():Length2D() + baseRadius
    local thickness = 6
    local extraBgDraw = 1
    local pos = pl:GetPos() + diskLocation


    ---[[
    ---   Players clipped through walls can see the disk
    ---   no current fix.
    ---]]
    -- Optionally check if the disk is visible:
    -- if not isVisible(pos) then continue end

    cam.Start3D2D(pos, angle_zero, 0.4)
      -- Background disk
      surface.SetDrawColor(60, 60, 60, 180)
      drawRadialBar(0, 0, entSize + thickness + extraBgDraw, entSize + thickness + extraBgDraw, 0, 360, 1)

      -- Armor ring 
      surface.SetDrawColor(0, 153, 255, 200)
      drawRadialBar(0, 0, entSize + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)

      -- Health ring 
      surface.SetDrawColor(255, 0, 0, 255)
      drawRadialBar(0, 0, entSize, thickness * 2, 0, 360 * animatedHp, animatedHp)
    cam.End3D2D()
  end
end

return DrawMeth