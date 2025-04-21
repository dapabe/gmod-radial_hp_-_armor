util.AddNetworkString("RadRing:Track")

---@type iRadRing
local RadRing = include("rad_ring.lua")


-- net.Receive("RadRing:Track", function()
--   local ent = net.ReadEntity()
--   if not IsValid(ent) and not ent:IsNPC() or not ent:IsPlayer() then return end

--   RadRing:TrackDmgdEntity(ent --[[@as Player | NPC]])
-- end)


hook.Add("EntityTakeDamage", "denz:TrackDamagedEntities", function(target)
  if not (IsValid(target) or target:IsNPC()) then return end
  if target.Health and target:Health() <= 0 then return end

  RadRing:TrackDmgdEntity(target)
end)



-- local visibilityCache = {}
-- local SCAN_INTERVAL = 0.25
-- local MAX_DIST_SQR = 4000 * 4000

-- hook.Add("Think", "UpdateVisibilityCache", function()
--   if not next(player.GetAll()) then return end
--   if not visibilityCache._nextScan or CurTime() >= visibilityCache._nextScan then
--     visibilityCache._nextScan = CurTime() + SCAN_INTERVAL

--     for _, ply in ipairs(player.GetAll()) do
--       visibilityCache[ply] = {}

--       for _, ent in ipairs(ents.GetAll()) do
--         if not IsValid(ent) or ent:IsWeapon() or ent:IsVehicle() or ent:IsWorld() then continue end
--         if ent == ply then continue end

--         if ply:TestPVS(ent) and ply:GetPos():DistToSqr(ent:GetPos()) <= MAX_DIST_SQR then
--           visibilityCache[ply][ent] = true
--         end
--       end
--     end
--   end
-- end)
