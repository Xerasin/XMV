if SERVER then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_boat"
ENT.PrintName = "Boat"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Forward = -90
local scale = 0.4
local propeller_pos = Vector(-20, 0, -6)
local propeller_ang = 12.5
function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_canal/boat002b.mdl")
		local min,max = Vector(-64.63606262207, -34.816837310791, -17.238922119141) * scale, Vector(66.601356506348, 34.816837310791, 17.983730316162) * scale
		self:PhysicsInitBox(min,max)
		self:DrawShadow(false)
		--[[self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)]]
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min,max)
		self:PhysWake()
		self:SetUseType(SIMPLE_USE)
	end
	self.AngOffset = Angle(0, 0, 0)
	self.Models = {
		{
			Pos = Vector(),
			Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_canal/boat002b.mdl",
				Scale = Vector(0.4, 0.4, 0.4),
				Pos = Vector(),
				Ang = Angle(),
			},
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Engine.mdl",
				Scale = Vector(0.32, 0.32, 0.32),
				Pos = Vector(-16, 0, -3),
				Ang = Angle(-90, 0, 0),
			},
		},
		{
			Pos = Vector(-24, -0.75, -4.75),
			Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_docks/dock01_pole01a_256.mdl",
				Scale = Vector(0.025, 0.025, 0.025),
				Pos = Vector(),
				Ang = Angle(-90, 0, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Blade.mdl",
				Scale = Vector(0.1, 0.1, 0.1),
				Pos = Vector(-2.5, 0, 0),
				Ang = Angle(-90, 0, 0),
			},
			Tick = function(curProp, vehicle)
				if vehicle and vehicle.SpinAng and curProp.Ang then
					curProp.Ang:RotateAroundAxis(Vector(1, 0, 0), vehicle.SpinAng)
				end
			end
		},
		{
			Pos = Vector(),
			Ang = Angle(),
			{
				Type = "PlayerName",
				Scale = 0.2,
				Pos = Vector(0, 3, 2),
				Ang = Angle(),
			},
			{
				Type = "Player",
				Scale = Vector(0.25, 0.25, 0.25),
				Pos = Vector(-8, 5, -1.0),
				Ang = Angle()
			},
		}
		
	}

	self.Controls = {
		{
			Key = IN_FORWARD,
			Name = "Go Forward"
		},
		{
			Key = IN_BACK,
			Name = "Go Back"
		},
		{
			Key = IN_SPEED,
			Name = "Speed Up!"
		}
	}
end

function ENT:SetupDataTables2()
	self:NetworkVar( "Float", 0, "Spin")
end

function ENT:IsInWater()
	local pos = self:LocalToWorld(propeller_pos)
	local contents = util.PointContents(pos)
	return bit.band(contents, CONTENTS_WATER) == CONTENTS_WATER or bit.band(contents, CONTENTS_TRANSLUCENT) == CONTENTS_TRANSLUCENT
end

function ENT:OnMove(ply, data)
	local tick = 33 / ( 1 / FrameTime())
	local phys = self:GetPhysicsObject()
	if ply:KeyDown(IN_WALK) then
		local ang = self:GetAngles()
		self:SetAngles(Angle(ang.p,ang.y, 0))
	end
	if phys and phys:IsValid() and self:IsInWater() then
		--local forward = self:GetForward()
		local forward_back = 0
		local side = 0
		if ply:KeyDown(IN_FORWARD) then
			forward_back = forward_back + 13
		end
		if ply:KeyDown(IN_BACK) then
			forward_back = forward_back - 13
		end
		if ply:KeyDown(IN_SPEED) then
			forward_back = forward_back * 1.5
		end
		--[[if ply:KeyDown(IN_MOVELEFT) then
			side = side + 8
		end
		if ply:KeyDown(IN_MOVERIGHT) then
			side = side - 8
		end]]
		local function GetPreferredRoute(ang1, ang2)
			local tang1 = ang1 % 360
			local tang2 = ang2 % 360

			local dif = tang2 - tang1
			local abs_dif = math.abs(dif)
			local resolved_dif = nil
			--359, 0 == 359
			--0, 359 = -359
			--print(tang1, " - ", tang2, " = ", dif)
			if tang1 > tang2 then
				--359, 0
				local dif1 = (tang2 + 360) - tang1
				local dist1 = math.abs(dif1)

				if abs_dif < dist1 then
					resolved_dif = dif
				else
					resolved_dif = dif1
				end
			else
				--0, 359
				--0, 90
				local dif1 = tang2 - (tang1 + 360)
				local dist1 = math.abs(dif1)
				if abs_dif < dist1 then
					resolved_dif = dif
				else
					resolved_dif = dif1
				end
				--print(tang1, tang2, abs_dif, dist1, dif, dif1, resolved_dif)
			end
			if resolved_dif then
				--print(resolved_dif)
				return resolved_dif
			else
				return 0
			end
		end
		local angle = self:GetAngles()
		local eyeang = ply:EyeAngles()
		side = GetPreferredRoute(angle.y, eyeang.y)
		if forward_back ~= 0 then
			local newAng = self:GetAngles()
			newAng:RotateAroundAxis(newAng:Forward(), propeller_ang)
			local pos = self:LocalToWorld(propeller_pos)
			phys:ApplyForceOffset(newAng:Forward() * phys:GetMass() * forward_back * tick, pos)
		end
		self:SetSpin(forward_back)
		if side ~= 0 and math.abs(angle.p) < 45 then
			local angVel = phys:GetAngleVelocity()
			local yaw_sign =  angVel.z * -1 + side * 5--math.Clamp(roll, -2.5, 2.5)
			phys:AddAngleVelocity(Vector(0, 0, yaw_sign))
		end
	end
end


if CLIENT then
	function ENT:Draw()
		if not self.Models then return end
		if not self.Models[1].Created then return self:CreateXMVModels() end
		self:DrawModels()
		self.SpinAng = self:GetSpin()
	end
else
	function ENT:SpawnFunction(ply,tr)
		if not tr.Hit then return end
		local ent = ents.Create( self.ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 2 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
	function ENT:CThink()
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:SetBuoyancyRatio(0.065)
			phys:Wake()
		end
	end
end
scripted_ents.Register(ENT, ENT.ClassName, true)

list.Set("SpawnableEntities", ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
