
include("rad_ring.lua")

if CLIENT then
  -- Dynamic cache update
  cvars.AddChangeCallback("cl_radialdisk_size", function (convar, oldValue, newValue)
    local baseRadius = tonumber(newValue) or 0
    for ent, data in pairs(RadRing.EntityCache) do
      if not IsValid(ent) then continue end
      data.size = ent:OBBMaxs():Length2D() + baseRadius
    end
  end)
end

hook.Add("ShutDown","RadRing:ShutDown", function()
  cvars.RemoveChangeCallback("cl_radialdisk_size", "RadRing:OneTimeOnly")
end)