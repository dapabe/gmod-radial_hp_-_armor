---@class DrawMeth
---@field private HpCache table<integer, number>
---@field private ArmorCache table<integer, number>
---@field private HpAnimated table<integer, number>
---@field private ArmorAnimated table<integer, number>
---@field private DrawOnPlayers fun(self, baseRadius: number, selfRender: boolean)
---@field DrawRadialHPArmor fun(self, baseRadius: number,selfRender: boolean)

---@class DrawMeth
DrawMeth = DrawMeth or {
  HpAnimated = {},
  ArmorAnimated = {},
}

---[[
--- Store local references to global functions for micro-optimization.
--- Since this is render code, every little bit counts.
---]]
local sin, cos, rad, floor, clamp, lerp = math.sin, math.cos, math.rad, math.floor, math.Clamp, Lerp
---[[
---   Unfortunately i have not been able to look for a workaround to get
---   the surface and draw libraries be ok the be accessed in the game without returning nil.
---   It was just a micro optimization in cl_draw_meth
---]]


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
---@param currentPercent number
local function drawRadialBar(x, y, outerRadius, thickness, startAngle, endAngle, currentPercent)
  -- Interpolate segment count between 6 (low quality) and 100 (smooth) based on currentPercent
  local segments = floor(lerp(currentPercent, 6, 100))
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

function DrawMeth:DrawOnPlayers(baseRadius, selfRender)
    local me = LocalPlayer()
    for _, pl in ipairs(player.GetAll() --[[@as table<integer, Player>]]) do
      if not IsValid(pl) or not pl:Alive() then continue end
      if pl == me and not selfRender then continue end

      if me:GetPos():DistToSqr(pl:GetPos()) > (3000 * 3000) then continue end

      local id = pl:EntIndex()
      local maxHealth = pl:GetMaxHealth()
      local hp = clamp(pl:Health(), 0, maxHealth)
      local hpPercent = hp / maxHealth
      local armorPercent = clamp(pl:Armor(), 0, 100) / 100
      local frame = FrameTime()

      -- Animate HP: Interpolate from the previous animated value to the current hpPercent.
      local currentHp = self.HpAnimated[id] or hpPercent
      local animatedHp = lerp(frame * 10, currentHp, hpPercent)
      self.HpAnimated[id] = animatedHp

      -- Animate Armor: Interpolate from the previous animated value to the current armorPercent.
      local currentArmor = self.ArmorAnimated[id] or armorPercent
      local animatedArmor = lerp(frame * 10, currentArmor, armorPercent)
      self.ArmorAnimated[id] = animatedArmor

      local entSize = pl:OBBMaxs():Length2D() + baseRadius
      local thickness = 6
      local extraBgDraw = 1
      local pos = pl:GetPos() + diskLocation

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

function DrawMeth:DrawRadialHPArmor(baseRadius, selfRender)
  self:DrawOnPlayers(baseRadius,selfRender)
end

return DrawMeth