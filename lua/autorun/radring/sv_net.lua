include("sh_constants.lua")

if SERVER then
  util.AddNetworkString(NetIds.Track)

  hook.Add("PostEntityTakeDamage", "denz:TrackDamagedEntities", function(target)
    if not target:IsNPC() then return end
    net.Start(NetIds.Track)
    net.WriteUInt((target --[[@as NPC]]):EntIndex(), 8)
    net.Broadcast()
  end)

end


