include("sh_constants.lua")

if SERVER then
  util.AddNetworkString(NetIds.Track)
  util.AddNetworkString(NetIds.Dead)

  hook.Add("PostEntityTakeDamage", "denz:TrackDamagedEntities", function(target)
    if not target:IsNPC() then return end
    net.Start(NetIds.Track)
    net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
    net.Broadcast()
  end)

  hook.Add("OnNPCKilled", "denz:NPCKilled", function (target)
    net.Start(NetIds.Dead)
    net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
    net.Broadcast()
  end)

end


