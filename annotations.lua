---@module"iRadRing"


---[CLIENT]
---@alias iColorSchemes table<string, {HP: Color, Armor: Color}>
---[CLIENT]
---@alias iColorMode "default" | "deuteranopia" | "protanopia" | "tritanopia"

---@class iRadRing
---[CLIENT]
---@field private HpCache table<integer, number>
---[CLIENT]
---@field private ArmorCache table<integer, number>
---[CLIENT]
---@field private HpAnimated table<integer, number>
---[CLIENT]
---@field private ArmorAnimated table<integer, number>
---[CLIENT]
---@field private ColorMode iColorMode
---[SHARED]
---@field RecentlyDmgdNPCs table<integer, {ent: Player | NPC, delay: integer}>
---[CLIENT]
---@field private DrawOnEntity fun(self: self, ent: Player | NPC) -- INTERNAL. Do not use.
---[CLIENT]
---@field DrawRadialHPArmor fun(self: self, baseRadius: number, selfRender: boolean, colorMode: iColorMode)
---[SHARED]
---@field TrackDmgdEntity fun(self: self, ent: Player | NPC)
