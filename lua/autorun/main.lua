AddCSLuaFile()

if SERVER then
  AddCSLuaFile("autorun/radring/cl_schemes.lua")
  AddCSLuaFile("autorun/radring/cl_cmds.lua")
  AddCSLuaFile("autorun/radring/cl_draw.lua")
  AddCSLuaFile("autorun/radring/sh_caches.lua")
  AddCSLuaFile("autorun/radring/cl_rad_ring.lua")
  AddCSLuaFile("autorun/radring/cl_init.lua")
  AddCSLuaFile("autorun/radring/sh_net.lua")

  include("autorun/radring/sh_caches.lua") -- ?
  include("autorun/radring/sh_net.lua")
end

if CLIENT then
  include("autorun/radring/sh_caches.lua")
  include("autorun/radring/sh_net.lua")
  include("autorun/radring/cl_cmds.lua")
  include("autorun/radring/cl_init.lua")
end