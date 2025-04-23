if SERVER then return end

include("sh_constants.lua")
include("cl_draw.lua")

---@class iRadRing
local RadRing = {
  EntityCache = {},
  HpCache = {},
  ArmorCache = {},
  HpAnimated = {},
  ArmorAnimated = {},
  RecentlyDmgdNPCs = {},
}

function RadRing:TrackDmgdNpc(npc)
  local id = npc:EntIndex()
  if not self.RecentlyDmgdNPCs[id] then
    self.RecentlyDmgdNPCs[id] = {
      ent = npc,
      delay = CurTime() + 8,
    }
  end
  -- Update
  self.RecentlyDmgdNPCs[id].delay = CurTime() + 8
end

local clamp, lerp = math.Clamp, Lerp

local defBgAlpha = 180
local thickness = 6
local extraBgDraw = 1


function RadRing:DrawRings(ent, ringData)
  local id = ent:EntIndex()
  local frame = RealFrameTime()

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
  local scheme = COLOR_SCHEMES[ColorScheme:GetString() or ColorScheme:GetDefault()]
  local pos = ent:GetPos()

  cam.Start3D2D(pos, angle_zero, 0.4) -- Scale on 1 its ugly
    -- Background disk
    DrawRingBar(pos, Color(60, 60, 60, ringData.alpha), bgFullRad, bgFullRad, 0, 360, extraBgDraw)
    if ent:Alive() then
      -- Armor ring
      DrawRingBar(pos, scheme.Armor, ringData.size + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)
      -- Health ring 
      DrawRingBar(pos, scheme.HP, ringData.size, thickness * 2, 0, 360 * animatedHp, animatedHp)
    end
  cam.End3D2D()
end

---@param pl Player
local function DrawOnPlayer(pl)
  local me = LocalPlayer()
  local hasLineOfSight = me:GetEyeTrace().Entity == pl
  local isCloser = me:GetPos():DistToSqr(pl:GetPos()) <= DistanceThreshold.Small[1]

  local ringData = RadRing.EntityCache[pl]
  if not ringData then return end
  local frame = RealFrameTime()

  local fadeIn = math.min(ringData.alpha + (frame * 100), defBgAlpha)
  local fadeOut = math.max(ringData.alpha - (frame * 100), 0)

  if not pl:Alive() then
    ringData.alpha = fadeOut
    if ringData.alpha <= 0 then
      -- Stop rendering but keep the cache
      return
    end
  end

  -- Handle normal visibility logic
  if me == pl then
    RadRing:DrawRings(pl, ringData)
    return
  end

  if hasLineOfSight or isCloser then
    ringData.alpha = fadeIn
  else
    ringData.alpha = fadeOut
    if ringData.alpha <= 0 then
      -- Stop rendering but keep the cache
      return
    end
  end
  

  -- Draw the ring
  RadRing:DrawRings(pl, ringData)
end
---@param npc NPC
local function DrawOnNPC(npc)
  local me = LocalPlayer()
  local hasLineOfSight = me:GetEyeTrace().Entity == npc
  local isCloser = me:GetPos():DistToSqr(npc:GetPos()) <= DistanceThreshold.Small[1]

  local ringData = RadRing.EntityCache[npc]
  if not ringData then return end
  local frame = RealFrameTime()
  local fadeIn = math.min(ringData.alpha + (frame * 100), defBgAlpha)
  local fadeOut = math.max(ringData.alpha - (frame * 100), 0)
  
  -- Npcs should be in distance to draw and have received damage or in LoS
  local dmgData = RadRing.RecentlyDmgdNPCs[npc:EntIndex()]

  -- Adjust visibility logic
  if hasLineOfSight or isCloser and dmgData and CurTime() < dmgData.delay then
    -- NPC has received damage and is either close or in line of sight
    ringData.alpha = fadeIn
  else
    -- Fade out if conditions are not met
    ringData.alpha = fadeOut
    if ringData.alpha <= 0 then return end
  end

  -- Draw the ring
  RadRing:DrawRings(npc, ringData)
end


--- Caches the entity position and size locally to avoid constant GetPos() calls.
---@param ent Entity
local function CacheEntLocally(ent)
  if RadRing.EntityCache[ent] then return end
  RadRing.EntityCache[ent] = {
    size = ent:OBBMaxs():Length2D() + PersistentBaseRadius:GetFloat(),
    alpha = defBgAlpha,
  }
  timer.Create("RadRing:Cache"..ent:EntIndex(), 5, 0, function()
    if not IsValid(ent) then
      timer.Remove("RadRing:Cache"..ent:EntIndex())
      RadRing.EntityCache[ent] = nil
      return
    end

    if not RadRing.EntityCache[ent] then
      timer.Remove("RadRing:Cache"..ent:EntIndex())
      return
    end
  end)
end

function RadRing:DrawRadialHPArmor(selfRender)
  local me = LocalPlayer()
  for _, ent in ents.Iterator() do
    if not IsValid(ent) then continue end
    if not (ent:IsNPC() or ent:IsPlayer()) then continue end
    
    CacheEntLocally(ent)
    if ent ~= me then
      if ent:GetNoDraw() or ent:IsDormant() then continue end
      if not ent:GetPos():ToScreen().visible then continue end
    end

    
      
    if ent:IsNPC() then
      if not ToggleNPCDisks:GetBool() then continue end
      DrawOnNPC(ent)
    else
      if ent == me then
        if not me:ShouldDrawLocalPlayer() or not selfRender then continue end
      end
      DrawOnPlayer(ent)
    end
  end
end

net.Receive(NetIds.Track, function()
  local index = net.ReadUInt(8)
  local ent = Entity(index)
  if not IsValid(ent) then return end
  RadRing:TrackDmgdNpc(ent --[[@as NPC]])
  
end)

net.Receive(NetIds.Dead, function ()
  local index = net.ReadUInt(8)
  local ent = Entity(index)
  if not IsValid(ent) then return end
  RadRing.RecentlyDmgdNPCs[index] = nil
end)

return RadRing