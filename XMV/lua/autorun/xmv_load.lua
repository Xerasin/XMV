module("xmv", package.seeall)

function BoxMesh(v1, v2)
    local col = Color(255, 255, 255)
    local x,y,z,x2,y2,z2 = v1.x,v1.y,v1.z,v2.x,v2.y,v2.z
    local tbl = {}
    local ou,ov = 0,0
    local u1, u2
    u1, v1 = ou, ov
    u2, v2 = ou + 1, ov + 1
    --
    table.insert(tbl, {color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z2),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z2),  u = u2, v = v2})

    table.insert(tbl, {color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z2),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z2),  u = u2, v = v1})
    --
    table.insert(tbl, {color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y, z),  u = u1, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})

    table.insert(tbl, {color = col, pos = Vector(x, y, z),  u = u1, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z),  u = u2, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
    --
    table.insert(tbl, {color = col, pos = Vector(x, y, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})

    table.insert(tbl, {color = col, pos = Vector(x, y, z2),  u = u2, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x, y, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
    --
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z2),  u = u1, v = v1})

    table.insert(tbl, {color = col, pos = Vector(x2, y2, z2),  u = u2, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z2),  u = u1, v = v1})
    --
    table.insert(tbl, {color = col, pos = Vector(x2, y, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y, z),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y, z2),  u = u1, v = v1})

    table.insert(tbl, {color = col, pos = Vector(x2, y, z2),  u = u2, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x2, y, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
    --
    table.insert(tbl, {color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})

    table.insert(tbl, {color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
    table.insert(tbl, {color = col, pos = Vector(x2, y2, z2),  u = u2, v = v1})
    table.insert(tbl, {color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
    return tbl
end

local function LoadVehicles()
    local BASE_DIR = "autorun/xmv/"
    for k,v in pairs(file.Find(BASE_DIR .. "*", "LUA")) do
        if SERVER then
            AddCSLuaFile(BASE_DIR .. v)
        end

        include(BASE_DIR .. v)
        MsgC(Color(100, 100, 100), "[XMV] ")
        MsgC(Color(255, 255, 255), string.format("loading %q \n", v))
    end
end

LoadVehicles()