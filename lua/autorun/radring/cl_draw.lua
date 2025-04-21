if SERVER then return end
---[[
--- Store local references to global functions for micro-optimization.
--- Since this is render code, every little bit counts.
---]]
local sin,
cos,
rad,
floor,
lerp =
math.sin,
math.cos,
math.rad,
math.floor,
Lerp

---[[
---   Unfortunately i have not been able to look for a workaround to get
---   the surface and draw libraries be ok the be accessed in the game without returning nil.
---]]


---@param radius number
---@param thickness number
---@param startAngle number
---@param endAngle number
---@param segments number
local function generateRingPoints(radius, thickness, startAngle, endAngle, segments)
  ---@type table<integer,{inner: {x: number, y: number}, outer: {x: number, y: number}}>
  local points = {}

  for i = 0, segments do
    local t = i / segments
    local angle = rad(lerp(t, startAngle, endAngle))
    local ox, oy = cos(angle), sin(angle)

    --- Seems simple but i brainfart
    points[i + 1] = {
      inner = { x = ox * (radius - thickness), y = oy * (radius - thickness) },
      outer = { x = ox * radius, y = oy * radius }
    }
  end

  return points
end


include("cl_cmds.lua")

local drawColor, noTexture = surface.SetDrawColor, draw.NoTexture
---@param colorScheme Color
---@param outerRadius number
---@param thickness number
---@param startAngle number
---@param endAngle number
---@param currentPercent number
function DrawRingBar(colorScheme, outerRadius, thickness, startAngle, endAngle, currentPercent)
  drawColor(colorScheme)
  -- Interpolate segment count between 6 (low quality) and 100 (smooth) based on currentPercent
  -- Lower segments creates funny shapes and improve performance, hardcoded to 20
  -- I would lower the segments even more for lower end PCs
  local segments = math.min(floor(lerp(currentPercent, 6, 100)), RingSegments:GetInt())
  local points = generateRingPoints(outerRadius, thickness, startAngle, endAngle, segments)
  noTexture()

  for i = 1, #points - 1 do
    surface.DrawPoly({
      points[i].outer,
      points[i + 1].outer,
      points[i + 1].inner,
      points[i].inner,
    })
  end
end

