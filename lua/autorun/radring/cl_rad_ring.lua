if SERVER then return end

---@type iColorSchemes
local COLOR_SCHEMES = include("cl_schemes.lua")
include("cl_draw.lua")

---@class iRadRing
local RadRing = {
  RecentlyDmgdNPCs = {},
  EntityCache = {},
  HpCache = {},
  ArmorCache = {},
  HpAnimated = {},
  ArmorAnimated = {},
  DesiredRingSize = PersistentBaseRadius:GetFloat()
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

local clamp, lerp = math.Clamp, Lerp

local pixelVisibleHandle = util.GetPixelVisibleHandle()
local diskLocation = vector_up
local defBgAlpha = 180
local thickness = 6
local extraBgDraw = 1
local maxDistSqr = 2250000 -- 1500^2 for npcs


function RadRing:DrawRings(ent, ringData, isNPC)
  local id = ent:EntIndex()
  local frame = FrameTime()

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

  local bgFullRad = ringData.size + thickness + extraBgDraw
  local scheme = COLOR_SCHEMES[ColorScheme:GetString()]

  cam.Start3D2D(ringData.pos, angle_zero, 0.4) -- Scale on 1 its ugly
    -- Background disk
    DrawRingBar(isNPC, Color(60, 60, 60, ringData.alpha), bgFullRad, bgFullRad, 0, 360, extraBgDraw)
    if ent:Alive() then
      -- Armor ring
      DrawRingBar(isNPC, scheme.Armor, ringData.size + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)
      -- Health ring 
      DrawRingBar(isNPC, scheme.HP, ringData.size, thickness * 2, 0, 360 * animatedHp, animatedHp)
    end
  cam.End3D2D()
end

---@param pl Player
local function DrawOnPlayer(pl)
  local frame = FrameTime()

  local ringData = RadRing.EntityCache[pl]
  if not ringData then return end

  -- If the player is dead, fade out the ring
  if not pl:Alive() then
    ringData.alpha = math.max(ringData.alpha - (frame * 100), 0)
    if ringData.alpha <= 0 then
      RadRing.EntityCache[pl] = nil
      return
    end
  else
    -- Reset alpha if the player is alive
    ringData.alpha = defBgAlpha
  end

  -- Check distance and line of sight
  local me = LocalPlayer()
  local distSqr = me:GetPos():DistToSqr(pl:GetPos())
  local hasLineOfSight = me:GetEyeTrace().Entity == pl
  local isFarAway = distSqr > maxDistSqr

  -- Fade out if out of line of sight or too far away
  if not hasLineOfSight or isFarAway then
    ringData.alpha = math.max(ringData.alpha - (frame * 100), 0)
    if ringData.alpha <= 0 then
      RadRing.EntityCache[pl] = nil
      return
    end
  end

  RadRing:DrawRings(pl, ringData)
end
---@param npc NPC
local function DrawOnNPC(npc)
  local id = npc:EntIndex()
  local frame = FrameTime()

  local ringData = RadRing.EntityCache[npc]
  if not ringData then return end


  -- Check if the NPC is recently damaged
  local dmgData = RadRing.RecentlyDmgdNPCs[id]
  if dmgData then
    -- Remove NPC from RecentlyDmgdNPCs if the delay expired
    if CurTime() > dmgData.delay then
      RadRing.RecentlyDmgdNPCs[id] = nil
    else
      -- Reset alpha if recently damaged
      ringData.alpha = defBgAlpha
    end
  end

  -- Check distance and line of sight
  local me = LocalPlayer()
  local distSqr = me:GetPos():DistToSqr(npc:GetPos())
  local hasLineOfSight = me:GetEyeTrace().Entity == npc
  local isFarAway = distSqr > maxDistSqr

  -- Fade out if not recently damaged, out of line of sight, or too far away
  if not dmgData or not hasLineOfSight or isFarAway then
    ringData.alpha = math.max(ringData.alpha - (frame * 100), 0)
    if ringData.alpha <= 0 then
      RadRing.EntityCache[npc] = nil
      return
    end
  end

  RadRing:DrawRings(npc, ringData, true)
end


--- Caches the entity position and size locally to avoid constant GetPos() calls.
---@param ent Entity
local function CacheEntLocally(ent)
  if RadRing.EntityCache[ent] then return end
  RadRing.EntityCache[ent] = {
    pos = ent:GetPos() + diskLocation,
    size = ent:OBBMaxs():Length2D() + RadRing.DesiredRingSize,
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

function RadRing:DrawRadialHPArmor(selfRender)
  for _, ent in ents.Iterator() do
    if not IsValid(ent) then continue end
    if not (ent:IsNPC() or ent:IsPlayer()) then continue end
    
    ---@type number
    local visibility

    CacheEntLocally(ent)
    if ent:IsNPC() then
      if ent:GetNoDraw() or ent:IsDormant() then continue end
      visibility = util.PixelVisible(ent:GetPos(), 1, pixelVisibleHandle)
      if not visibility or visibility <= 0 then continue end
      DrawOnNPC(ent)
    else
      if ent == LocalPlayer() then
        if not LocalPlayer():ShouldDrawLocalPlayer() or not selfRender then continue end
        DrawOnPlayer(ent)
      else
        if ent:GetNoDraw() or ent:IsDormant() then continue end
        visibility = util.PixelVisible(ent:GetPos(), 1, pixelVisibleHandle)
        if not visibility or visibility <= 0 then continue end
        DrawOnPlayer(ent)
      end
    end
  end
end

return RadRing