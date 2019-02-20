module("xmv", package.seeall)
local BASE_DIR = "autorun/XMV/"
for k,v in pairs(file.Find(BASE_DIR .. "*", "LUA")) do
    if SERVER then
        AddCSLuaFile(BASE_DIR .. v)
    end
    include(BASE_DIR .. v)
    MsgC(Color(100, 100, 100), "[XMV] ")
    MsgC(Color(255, 255, 255), string.format("loading %q \n", v))
end