
--- Declared client events first, separated server events at the bottom
--- Server variables declared at the top
---@type iRadRing
local RadRing = include("cl_rad_ring.lua")

local NetIdTrack = "RadRing:Track"


net.Receive(NetIdTrack, function()
  local ent = Entity(net.ReadUInt(8))
  if not IsValid(ent) then return end
  RadRing:TrackDmgdNpc(ent --[[@as NPC]])
end)

if CLIENT then return end

util.AddNetworkString(NetIdTrack)


hook.Add("EntityTakeDamage", "denz:TrackDamagedEntities", function(target)
  if not (IsValid(target) or target:IsNPC()) then return end
  if target.Health and target:Health() <= 0 then return end

  net.Start(NetIdTrack)
  net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
  net.Broadcast()
end)