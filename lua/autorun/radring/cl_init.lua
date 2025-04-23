if SERVER then return end
include("cl_cmds.lua")
---@type iRadRing
local RadRing = include("cl_rad_ring.lua")

--- Only hook i know that works with NPCs & Players
hook.Add("PostDrawTranslucentRenderables", "denz:RadialResources", function()
    if not ToggleRadialDisk:GetBool() then return end
    local selfRender = ToggleOnSelf:GetBool()

    RadRing:DrawRadialHPArmor(selfRender)
end)