local DrawMeth = include("draw_meth.lua")

local persistentBaseRadius = CreateClientConVar("cl_radialdisk_size", "20", true, true, "Base radial size, 0 is the target's collision box", 0)
local toggleRadialDisk = CreateClientConVar("cl_radialdisk_toggle", "1", true, true, "Toggle the radial disk", 0, 1)
local toggleOnSelf = CreateClientConVar("cl_radialdisk_self", "0", true, true, "Toggle to be display on yourself", 0, 1)

concommand.Add("cl_radialdisk_size", function (ply, cmd, args)
  if not args[1] then
    return print("Current radial radius: "..persistentBaseRadius:GetString())
  end
  local val = tonumber(args[1])
  if not val then return end
  persistentBaseRadius:SetInt(val)
end)


concommand.Add("cl_radialdisk_toggle",function ()
  toggleRadialDisk:SetBool(not toggleRadialDisk:GetBool())
end)

concommand.Add("cl_radialdisk_self", function ()
  toggleOnSelf:SetBool(not toggleOnSelf:GetBool())
end)


-- This will be much likely be better coded in the future
-- As im making a gamemode about this
hook.Add("PostDrawTranslucentRenderables", "denz:RadialResources", function()
    if not toggleRadialDisk:GetBool() then return end

    local baseRadius = persistentBaseRadius:GetInt()
    local selfRender = toggleOnSelf:GetBool()
    DrawMeth:DrawRadialHPArmor(baseRadius, selfRender)
end)
