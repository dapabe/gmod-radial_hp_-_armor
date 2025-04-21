
---@type iRadRing
local RadRing = include("rad_ring.lua")
include("cl_cmds.lua")

--- Only hook i know that works with NPCs & Players
hook.Add("PostDrawTranslucentRenderables", "denz:RadialResources", function()
    if not ToggleRadialDisk:GetBool() then return end
    local baseRadius = PersistentBaseRadius:GetFloat()
    local selfRender = ToggleOnSelf:GetBool()
    local colorMode = ColorScheme:GetString()

    RadRing:DrawRadialHPArmor(baseRadius, selfRender, colorMode)
  end)
  

-- ---@type table<Entity>
-- local visible = {}


-- hook.Add("Think", "denz:BroadcastTrackedNPCs",function ()
--   for id, d in ipairs(RadRing.RecentlyDmgdNPCs) do
--     if not IsValid(d.ent) or CurTime() > d.delay then
--       RadRing.RecentlyDmgdNPCs[id] = nil
--     else
--       table.insert(visible, d.ent)
--     end
--   end

--   net.Start()
--   net.WriteUInt(#visible, 8)
--   for _, ent in ipairs(visible) do
--     net.WriteEntity(ent)
--   end
--   net.Broadcast()
-- end)

