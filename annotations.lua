---@module"iRadRing"


---[CLIENT]
---@alias iColorMode "default" | "deuteranopia" | "protanopia" | "tritanopia"
---[CLIENT]
---@alias iColorSchemes table<iColorMode, {HP: Color, Armor: Color}>

---[SHARED]
---@alias iRingData {size: number, alpha: number}

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
---@field EntityCache table<Entity, iRingData>
---[CLIENT]
---@field RecentlyDmgdNPCs table<integer, {ent: NPC, delay: number}>
---[CLIENT]
---@field private DrawRings fun(self: self, ent: Player | NPC, ringData: iRingData) -- INTERNAL. Do not use.
---[CLIENT]
---Calculates line of sight, distance from player to target entity and caches for future use and draw
---of the target entity (NPC | Player).
---@field DrawRadialHPArmor fun(self: self, selfRender: boolean)
---[CLIENT]
---@field TrackDmgdNpc fun(self: self, npc: NPC)
