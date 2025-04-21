---@class iRadRing
RadRing = RadRing or {
  RecentlyDmgdNPCs = {},
  EntityCache = {}
}

function RadRing:TrackDmgdNpc(npc)
  local id = npc:EntIndex()
  if not self.RecentlyDmgdNPCs[id] then
    self.RecentlyDmgdNPCs[id] = {
      ent = npc,
      delay = CurTime() + 4,
    }
  end
  -- Update
  self.RecentlyDmgdNPCs[id].delay = CurTime() + 4
end


if CLIENT then
  include("cl_draw.lua")
  RadRing.HpCache = {}
  RadRing.ArmorCache = {}
  RadRing.HpAnimated = {}
  RadRing.ArmorAnimated = {}
  RadRing.ColorMode = "default"
  RadRing.DesiredRingSize = 20

  ---@type iColorSchemes
  local COLOR_SCHEMES = include("cl_schemes.lua")
  local clamp, lerp = math.Clamp, Lerp
 
  local pixelVisibleHandle = util.GetPixelVisibleHandle()
  local diskLocation = Vector(0, 0, 0.2)
  local defBgAlpha = 180
  local thickness = 6
  local extraBgDraw = 1
  local maxDistSqr = 2250000 -- 1500^2


  function RadRing:DrawOnEntity(ent)
    local id = ent:EntIndex()
    local frame = FrameTime()

    local ringData = self.EntityCache[ent]
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
    local isFarAway = ringData.pos:DistToSqr(LocalPlayer():GetPos()) > maxDistSqr

    cam.Start3D2D(ringData.pos, angle_zero, 0.4) -- Scale on 1 its ugly
      -- Background disk
      DrawRingBar(isFarAway, Color(60, 60, 60, ringData.alpha), bgFullRad, bgFullRad, 0, 360, extraBgDraw)
      if ent:Alive() then
        -- Armor ring
        DrawRingBar(isFarAway, scheme.Armor, ringData.size + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)
        -- Health ring 
        DrawRingBar(isFarAway, scheme.HP, ringData.size, thickness * 2, 0, 360 * animatedHp, animatedHp)
      end
    cam.End3D2D()
  end


  --- Caches the entity position and size locally to avoid constant GetPos() calls.
  ---@param ent Entity
  local function CacheEntLocally(ent)
    if RadRing.EntityCache[ent] then return end
    RadRing.EntityCache[ent] = {
      pos = ent:GetPos() + diskLocation,
      size = ent:OBBMaxs():Length2D() + baseRadius,
      alpha = defBgAlpha,
    }
    timer.Create("RadRing:Cache"..ent:EntIndex(), 0, 0, function()
      if not IsValid(ent) then
        timer.Remove("RadRing:Cache"..ent:EntIndex())
        RadRing.EntityCache[ent] = nil
        return
      end

      if not RadRing.EntityCache[ent] then
        timer.Remove("RadRing:Cache"..ent:EntIndex())
        return
      end

      RadRing.EntityCache[ent].pos = ent:GetPos() + diskLocation
    end)
  end

  function RadRing:DrawRadialHPArmor(baseRadius, selfRender, colorMode)
    local me = LocalPlayer()
    local eye = me:GetEyeTrace()
    if COLOR_SCHEMES[colorMode] then
      self.ColorMode = colorMode
    end
    self.DesiredRingSize = baseRadius
    
    -- Insane amount of checks before drawing
    for _, ent in ents.Iterator() do
      if not IsValid(ent) then continue end
      if not (ent:IsNPC() or ent:IsPlayer()) then continue end
      
      local hasLineOfSight = eye.Entity == ent
      local distSqr = me:GetPos():DistToSqr(ent:GetPos())

      -- Always draw on LoS
      if hasLineOfSight then
        CacheEntLocally(ent)
        self:DrawOnEntity(ent)
        continue
      end

      -- Always render rings for players
      if ent:IsPlayer() then
        if ent == me then
          if not me:ShouldDrawLocalPlayer() then continue end
          if not selfRender then continue end
        end
        if distSqr > maxDistSqr then continue end
        local visibility = util.PixelVisible(ent:GetPos(), 1, pixelVisibleHandle)
        if not visibility or visibility <= 0 then continue end

        CacheEntLocally(ent)
        self:DrawOnEntity(ent)
        continue
      end

      -- Render rings for NPCs only if they were recently damaged
      -- or they lose line of sight, else fade out the rings
      local dmgData = self.RecentlyDmgdNPCs[ent:EntIndex()]

      -- Regardless of distance or LoS, this has to be up to date.
      if dmgData then
        -- Remove NPC if delay expired
        if CurTime() > dmgData.delay  then
          self.RecentlyDmgdNPCs[ent:EntIndex()] = nil
          continue
        else CacheEntLocally(ent) end
      end

      if hasLineOfSight then
        -- Reset the delay if the NPC is in line of sight
        if dmgData then
          dmgData.delay = CurTime() + 4
        end
        CacheEntLocally(ent)
        self:DrawOnEntity(ent)
        continue
      end


      if not self.EntityCache[ent] then continue end


      local ringData = self.EntityCache[ent]
        -- Fade out the ring if the NPC is not recently damaged or not in line of sight
      if not dmgData and (not hasLineOfSight or distSqr > maxDistSqr) then
        ringData.alpha = math.max(ringData.alpha - (FrameTime() * 100), 0)
        if ringData.alpha <= 0 then
            self.EntityCache[ent] = nil
            continue
        end
      else
          -- Reset alpha if NPC is in line of sight or within distance
          -- ringData.alpha = defBgAlpha
      end
      
      if distSqr > maxDistSqr then continue end

      self:DrawOnEntity(ent)
    end
  end

end

return RadRing