
--- Shutdown runs in the client and the server
--- Does it need to in this case ? Probab change file to "cl_"

local ID = {
  Size = "cl:rd:size",
}

hook.Add("ShutDown","RadRing:ShutDown", function()
  cvars.RemoveChangeCallback("cl_radialdisk_size", ID.Size)
end)


if SERVER then return end

---@type iRadRing
local RadRing = include("cl_rad_ring.lua")

-- Dynamic cache update
cvars.AddChangeCallback("cl_radialdisk_size", function (convar, oldValue, newValue)
  local baseRadius = tonumber(newValue) or 0
  for ent, data in pairs(RadRing.EntityCache) do
    if not IsValid(ent) then continue end
    data.size = ent:OBBMaxs():Length2D() + baseRadius
  end
end, ID.Size)
