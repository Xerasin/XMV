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
		--[=[MsgC(Color(100, 100, 100), "[XMV] ")
		MsgC(Color(255, 255, 255), string.format("loading %q \n", v))]=]
	end
end

if SERVER then
	local function returnFilter(pl)
		return function(e)
			if e == pl then return false end
			local cg = e:GetCollisionGroup()

			return
				cg ~= 15 -- COLLISION_GROUP_PASSABLE_DOOR
			and cg ~= 11 -- COLLISION_GROUP_WEAPON
			and cg ~= 1 -- COLLISION_GROUP_DEBRIS
			and cg ~= 2 -- COLLISION_GROUP_DEBRIS_TRIGGER
			and cg ~= 20 -- COLLISION_GROUP_WORLD

		end
	end

	local function IsStuck(pl, fast, pos)
		local t = {mask = MASK_PLAYERSOLID}

		t.start = pos or pl:GetPos()
		t.endpos = t.start

		if fast then
			t.filter = {pl}
		else
			t.filter = returnFilter(pl)
		end

		local output = util.TraceEntity(t, pl)
		return output.StartSolid, output.Entity, output
	end

	local function FindPassableSpace(ply, dirs, n, direction, step)
		local origin = dirs[n]
		if not origin then
			origin = ply:GetPos()
			dirs[n] = origin
		end

		--for i=0,100 do
			--origin = VectorMA( origin, step, direction )
			origin:Add(step * direction)

			if not IsStuck(ply, false, origin) then
				ply:SetPos(origin)
				if not IsStuck(ply, false) then
					ply.NewPos = ply:GetPos()
					return true
				end
			end

		--end

		return false
	end

	--[[
		Purpose: Unstucks player ,
		Note: Very expensive to call, you have been warned!
	]]

	--local forward = Vector(1,0,0)
	local right = Vector(0, 1, 0)
	local up = Vector(0, 0, 1)
	function UnstuckPlayer(ply)
		ply.NewPos = ply:GetPos()
		local OldPos = NewPos

		local dirs = {}
		if IsStuck(ply) then
			local SearchScale = 1 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12
			local ok
			local forward = ply:GetAimVector()
			forward.z = 0
			forward:Normalize()
			right = forward:Angle():Right()
			for i = 1, 20 do
				ok = true
				if	  not FindPassableSpace(ply, dirs, 1, forward, SearchScale * i)
					and not FindPassableSpace(ply, dirs, 2, right, SearchScale * i)
					and not FindPassableSpace(ply, dirs, 3, right, -SearchScale * i)
					and not FindPassableSpace(ply, dirs, 4, up, SearchScale * i)
					and not FindPassableSpace(ply, dirs, 5, up, -SearchScale * i)
					and not FindPassableSpace(ply, dirs, 6, forward, -SearchScale * i) then
						ok = false
				end
				if ok then break end
			end

			if not ok then return false end

			if OldPos == ply.NewPos then
				ply:SetPos(ply.NewPos)
				ply.NewPos = nil

				return true
			else
				ply:SetPos(ply.NewPos)
				ply.NewPos = nil

				if SERVER and ply and ply:IsValid() and ply:GetPhysicsObject():IsValid() then
					ply:SetVelocity(-ply:GetVelocity())
				end

				return true
			end
		end
	end
end

LoadVehicles()