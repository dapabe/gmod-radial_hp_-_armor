
--- Declared client events first, separated server events at the bottom
--- Server variables declared at the top
---@type iRadRing
local RadRing = include("cl_rad_ring.lua")

local NetIdTrack = "RadRing:Track"
local NetIdDead = "RadRing:Dead"


net.Receive(NetIdTrack, function()
  local index = net.ReadUInt(8)
  local ent = Entity(index)
  if not IsValid(ent) then return end
  RadRing:TrackDmgdNpc(ent --[[@as NPC]])
  
end)

net.Receive(NetIdDead, function ()
  local index = net.ReadUInt(8)
  local ent = Entity(index)
  if not IsValid(ent) then return end
  RadRing.RecentlyDmgdNPCs[index] = nil
end)

if CLIENT then return end

util.AddNetworkString(NetIdTrack)
util.AddNetworkString(NetIdDead)


hook.Add("PostEntityTakeDamage", "denz:TrackDamagedEntities", function(target)
  if not (IsValid(target) or target:IsNPC()) then return end

  net.Start(NetIdTrack)
  net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
  net.Broadcast()
end)

hook.Add("OnNPCKilled", "denz:NPCKilled", function (target)
  net.Start(NetIdDead)
  net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
  net.Broadcast()
end)


