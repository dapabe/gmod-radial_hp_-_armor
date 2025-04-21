---@class iRadRing
RadRing = RadRing or {
  RecentlyDmgdNPCs = {},
}

function RadRing:TrackDmgdEntity(ent)
  self.RecentlyDmgdNPCs[ent:EntIndex()] = {
    ent = ent,
    delay = CurTime() + 6,
  }
end


if CLIENT then
  include("cl_draw.lua")
  RadRing.HpCache = {}
  RadRing.ArmorCache = {}
  RadRing.HpAnimated = {}
  RadRing.ArmorAnimated = {}
  RadRing.ColorMode = "default"

  ---@type iColorSchemes
  local COLOR_SCHEMES = include("cl_schemes.lua")
  local clamp, lerp = math.Clamp, Lerp
 
  local diskLocation = Vector(0, 0, 0.2)
  local defBgAlpha = 180
  local thickness = 6
  local extraBgDraw = 1

    ---Attempt at optimization
  ---@type table<Entity, {pos: Vector, size: number, alpha: number}>
  local ringCache = {}

  function RadRing:DrawOnEntity(ent)
    local id = ent:EntIndex()
    local frame = FrameTime()

    local ringData = ringCache[ent]
    if not ringData then return end

    -- Animate HP: Interpolate from the previous animated value to the current hpPercent.
    local currentHp = 0
    local animatedHp = 0
    if ent.Health and ent:Health() > 0 then
      local maxHealth = ent:GetMaxHealth()
      local hpPercent = clamp(ent:Health(), 0, maxHealth) / maxHealth
      currentHp = self.HpAnimated[id] or hpPercent
      animatedHp = lerp(frame * 10, currentHp, hpPercent)
      self.HpAnimated[id] = animatedHp
    end

    -- Animate Armor: Interpolate from the previous animated value to the current armorPercent.
    local currentArmor = 0
    local animatedArmor = 0
    -- Some addons make npcs have armor? idk
    if ent.Armor and ent:Armor() > 0 then
      local armorPercent = clamp(ent:Armor(), 0, 100) / 100
      currentArmor = self.ArmorAnimated[id] or armorPercent
      animatedArmor = lerp(frame * 10, currentArmor, armorPercent)
      self.ArmorAnimated[id] = animatedArmor
    end

    -- Fade-out death animation
    if not ent:Alive() then
      ringData.alpha = ringData.alpha or defBgAlpha -- Slightly transparent
      ringData.alpha = math.max(ringData.alpha - (frame * 100), 0) -- Reduce alpha over time
      if ringData.alpha <= 0 then
        return -- Stops rendering but keep the cache until the entity is alive again
      end
    else
      ringData.alpha = defBgAlpha -- Reset alpha when alive
    end

    local bgFullRad = ringData.size + thickness + extraBgDraw
    local scheme = COLOR_SCHEMES[self.ColorMode]

    cam.Start3D2D(ringData.pos, angle_zero, 0.4) -- Scale on 1 its ugly
      -- Background disk
      DrawRingBar(Color(60, 60, 60, ringData.alpha), bgFullRad, bgFullRad, 0, 360, extraBgDraw)
      if ent:Alive() then
        -- Armor ring
        DrawRingBar(scheme.Armor, ringData.size + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)
        -- Health ring 
        DrawRingBar(scheme.HP, ringData.size, thickness * 2, 0, 360 * animatedHp, animatedHp)
      end
    cam.End3D2D()
  end


  ---@param ent Entity
  ---@param baseRadius number
  local function CacheEntLocally(ent, baseRadius)
    local dmgData = RadRing.RecentlyDmgdNPCs[ent:EntIndex()]
    -- Remove NPC if cache expired
    if dmgData and dmgData.delay > CurTime() then
      RadRing.RecentlyDmgdNPCs[ent:EntIndex()] = nil
      return
    end
    if not ringCache[ent] then
      ringCache[ent] = {
        pos = ent:GetPos() + diskLocation,
        size = ent:OBBMaxs():Length2D() + baseRadius,
        alpha = defBgAlpha,
      }
      timer.Create("RadRing:Cache"..ent:EntIndex(), 0, 0, function()
        if not IsValid(ent) then
          timer.Remove("RadRing:Cache"..ent:EntIndex())
          ringCache[ent] = nil
          return
        end

        if not ringCache[ent] then
          timer.Remove("RadRing:Cache"..ent:EntIndex())
          return
        end

        ringCache[ent].pos = ent:GetPos() + diskLocation
      end)
    end
  end

  function RadRing:DrawRadialHPArmor(baseRadius, selfRender, colorMode)
    local me = LocalPlayer()
    if COLOR_SCHEMES[colorMode] then
      self.ColorMode = colorMode
    end
    
    -- Insane amount of checks before drawing
    for _, ent in ents.Iterator() do
      if not IsValid(ent) then continue end
      if not (ent:IsNPC() or ent:IsPlayer() )then continue end

      if ent == me then
        if not me:ShouldDrawLocalPlayer() then continue end
        if not selfRender then continue end
      end
      -- This is good for entity culling, not used.
      -- if not trace.Entity or trace.Entity ~= ent then continue end
      
      local distSqr = me:GetPos():DistToSqr(ent:GetPos())
      if distSqr > (1500 * 1500) then continue end

      CacheEntLocally(ent, baseRadius)

      self:DrawOnEntity(ent)
    end
  end

  -- Dynamic cache update
  cvars.AddChangeCallback("cl_radialdisk_size", function (convar, oldValue, newValue)
    local baseRadius = tonumber(newValue) or 0
    for ent, data in pairs(ringCache) do
      if not IsValid(ent) then continue end
      data.size = ent:OBBMaxs():Length2D() + baseRadius
    end
  end)

  hook.Add("ShutDown","RadRing:ShutDown", function()
    cvars.RemoveChangeCallback("cl_radialdisk_size", "RadRing:OneTimeOnly")
  end)
end

return RadRing