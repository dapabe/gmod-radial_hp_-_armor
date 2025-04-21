if SERVER then return end

---@type iColorSchemes
local COLOR_SCHEMES = include("cl_schemes.lua")

PersistentBaseRadius = CreateClientConVar("cl_radialdisk_size", "25", true, true, "Base radial size, 0 is the target's collision box", 0)
ToggleRadialDisk = CreateClientConVar("cl_radialdisk_toggle", "1", true, true, "Toggle the radial disk", 0, 1)
ToggleOnSelf = CreateClientConVar("cl_radialdisk_self", "0", true, true, "Toggle to be display on yourself", 0, 1)
RingSegments = CreateClientConVar("cl_radialdisk_segments", "20", true, true, "Lower the ring segments for better performance", 3)

local txtAvailableSchemes = table.concat(table.GetKeys(COLOR_SCHEMES), ", ")
ColorScheme = CreateClientConVar("cl_radialdisk_scheme", "default", true, true, "Color blind modes: "..txtAvailableSchemes)

concommand.Add("cl_radialdisk_size", function (ply, cmd, args)
  if not args[1] then
    return print("Current radial radius: "..PersistentBaseRadius:GetString())
  end
  local val = tonumber(args[1])
  if not val then return end
  PersistentBaseRadius:SetInt(val)
end)


concommand.Add("cl_radialdisk_toggle",function ()
  ToggleRadialDisk:SetBool(not ToggleRadialDisk:GetBool())
end)

concommand.Add("cl_radialdisk_self", function ()
  ToggleOnSelf:SetBool(not ToggleOnSelf:GetBool())
end)

concommand.Add("cl_radialdisk_scheme", function (ply, cmd, args)
  if not args[1] then
    print("Current color scheme: "..ColorScheme:GetString())
    return
  end
  local val = tostring(args[1]).lower()
  if not COLOR_SCHEMES[val] then
    print("Invalid color scheme. Available schemes: "..table.GetKeys(COLOR_SCHEMES))
    return
  end
  ColorScheme:SetString(val)
end)

concommand.Add("cl_radialdisk_segments", function (ply, cmd, args)
  if not args[1] then
    print("Current ring segments: "..RingSegments:GetString())
    return
  end
  local val = tonumber(args[1], 10)
  if not val then return end
  RingSegments:SetInt(val)
end)

