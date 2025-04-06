local DrawMeth = include("cl_draw_meth.lua")

local persistentBaseRadius = CreateClientConVar("cl_radialdisk_size", "20", true, true, "Base radial size, 0 is the target's collision box",0)
local toggleRadialDisk = CreateClientConVar("cl_radialdisk_toggle", "1", true, true, "Toggle the radial disk", 0, 1)

concommand.Add("cl_radialdisk_size", function (ply, cmd, args)
  if not args[1] then
    return print("Current radial radius: "..persistentBaseRadius:GetString())
  end
  local val = tonumber(args[1])
  if not val then return end
  persistentBaseRadius:SetInt(val)
end)


concommand.Add("cl_radialdisk_toggle",function (ply, cmd, args)
  toggleRadialDisk:SetBool(not toggleRadialDisk:GetBool())
end)




---[[
---   Unfortunately i have not been able to look for a workaround to get
---   the surface and draw libraries be ok the be accessed in the game without returning nil.
---   It was just a micro optimization in cl_draw_meth
---]]

-- This will be much likely be better coded in the future
-- As im making a gamemode about this
hook.Add("PostDrawTranslucentRenderables", "denz:RadialResources", function()
    if not toggleRadialDisk:GetBool() then return end

    local baseRadius = persistentBaseRadius:GetInt()
    DrawMeth:DrawRadialHPArmor(baseRadius)
end)
