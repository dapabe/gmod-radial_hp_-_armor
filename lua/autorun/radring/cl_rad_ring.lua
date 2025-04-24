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
local secondsToDisappear = 20
function RadRing:TrackDmgdNpc(npc)
  local id = npc:EntIndex()
  if not self.RecentlyDmgdNPCs[id] then
    self.RecentlyDmgdNPCs[id] = {
      ent = npc,
      delay = CurTime() + secondsToDisappear,
    }
  end
  -- Update
  self.RecentlyDmgdNPCs[id].delay = CurTime() + secondsToDisappear
end

local clamp, lerp = math.Clamp, Lerp

local defBgAlpha = 180
local thickness = 6
local extraBgDraw = 1



---@param ent Entity
---@return Angle
local function GetRadialRingAngle(ent)
  local entHeight = ent:GetPos().z + ent:OBBCenter().z
  local eyeHeight = LocalPlayer():EyePos().z
  local shouldBillboard = eyeHeight < entHeight - 20 -- allow a little buffer

  local angleToUse = angle_zero
  if shouldBillboard then
    local toEye = (LocalPlayer():EyePos() - ent:GetPos()):Angle()
    toEye:RotateAroundAxis(toEye:Right(), 90)
    angleToUse = toEye
  end
  return angleToUse
end

---@param ent Entity
---@return number
local function GetEntitySize(ent)
  local minRingSize = 20
  -- Calculate the size of the ring based on the average of the x and y dimensions
  local bounds = ent:OBBMaxs() - ent:OBBMins()
  local size = math.max((bounds.x + bounds.y) / 2, minRingSize) -- Use the average of x and y, but enforce a minimum size
  return size
end

---Interpolate from the previous animated value to the current resource percent.
---@param ent NPC | Player
---@return number, number
local function GetResourceInterpolation(ent)
  local id = ent:EntIndex()
  local frame = RealFrameTime()

  local animatedHp = 0
  if ent.Health and ent:Health() > 0 then
    local maxHealth = ent:GetMaxHealth()
    local hpPercent = clamp(ent:Health(), 0, maxHealth) / maxHealth
    local currentHp = RadRing.HpAnimated[id] or hpPercent
    animatedHp = lerp(frame * 10, currentHp, hpPercent)
    RadRing.HpAnimated[id] = animatedHp
  end

  local animatedArmor = 0
  -- Some addons make npcs have armor? idk
  if ent.Armor and ent:Armor() > 0 then
    local maxArmor = ent.GetMaxArmor and ent:GetMaxArmor() or 100 -- Ternary
    local armorPercent = clamp(ent:Armor(), 0, maxArmor) / maxArmor
    local currentArmor = RadRing.ArmorAnimated[id] or armorPercent
    animatedArmor = lerp(frame * 10, currentArmor, armorPercent)
    RadRing.ArmorAnimated[id] = animatedArmor
  end
  
  return animatedHp, animatedArmor
end

function RadRing:DrawRings(ent, ringData)
  local animatedHp, animatedArmor = GetResourceInterpolation(ent)

  local size = GetEntitySize(ent)
  local bgFullRad = size + (ent.Armor and thickness or 0) + extraBgDraw
  local scheme = COLOR_SCHEMES[ColorScheme:GetString() or ColorScheme:GetDefault()]
  local pos = ent:GetPos()

  local hpPos = ent.Armor and thickness * 1.5 or thickness

  cam.Start3D2D(pos, GetRadialRingAngle(ent), 1)
    -- Background disk
    DrawRingBar(pos, Color(60, 60, 60, ringData.alpha), bgFullRad, bgFullRad, 0, 360, extraBgDraw)
    if ent:Alive() then
      -- Armor ring
      DrawRingBar(pos, scheme.Armor, size + thickness, thickness, 0, 360 * animatedArmor, animatedArmor)
      -- Health ring 
      DrawRingBar(pos, scheme.HP, size, hpPos, 0, 360 * animatedHp, animatedHp)
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
    if ringData.alpha <= 0 then return end
  end

  -- Handle normal visibility logic
  if me == pl then
    -- ringData.alpha = defBgAlpha
    RadRing:DrawRings(pl, ringData)
    return
  end

  if hasLineOfSight or isCloser then
    ringData.alpha = fadeIn
  else
    ringData.alpha = fadeOut
    if ringData.alpha <= 0 then return end
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
    -- size = ent:OBBMaxs():Length2D() + PersistentBaseRadius:GetFloat(),
    alpha = defBgAlpha,
  }
  timer.Create("RadRing:Cache"..ent:EntIndex(), 1, 0, function()
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
    if ent:Alive() and ent.Health and ent:Health() <= 0 then continue end -- Rollermine, etc

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