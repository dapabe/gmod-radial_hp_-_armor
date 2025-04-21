AddCSLuaFile()

if SERVER then
  AddCSLuaFile("autorun/radring/cl_schemes.lua")
  AddCSLuaFile("autorun/radring/cl_draw.lua")
  AddCSLuaFile("autorun/radring/rad_ring.lua")
  AddCSLuaFile("autorun/radring/cl_init.lua")

  include("autorun/radring/sv_init.lua")
end

if CLIENT then
  include("autorun/radring/cl_init.lua")
end