if SERVER then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_submarine"
ENT.PrintName = "Submarine"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Forward = 0
function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_borealis/bluebarrel001.mdl")

		local min = Vector(-10.373940467834, -5.7561001777649, -5.7430200576782)
		local max = Vector(10.398138999939, 5.7622199058533, 5.7752599716187)
		self:PhysicsInitBox(min, max)
		--self:SetMoveType(MOVETYPE_NONE)

		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMaterial("gmod_ice")
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min, max)
		self:PhysWake()
		self:SetSpin(0)
		self:SetUseType(SIMPLE_USE)
	end
	self.AngOffset = Angle(-90, -180, -180)

	self.Models = {
		{
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_borealis/bluebarrel001.mdl",
				Scale = Vector(0.4, 0.4, 0.4),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(0, 0, 0),
				Ang = Angle(90, 0, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_combine/breenchair.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(12, 0, -2),
				Ang = Angle(0, 0, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_phx/construct/windows/window_dome360.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(10, 0, 0),
				Ang = Angle(90, 0, 0),
			}
		},
		{
			Pos = Vector(-11, 0, 0),
			Ang = Angle(-90, 0, 0),
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Blade.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Blade.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 90, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Blade.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 180, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_c17/TrapPropeller_Blade.mdl",
				Scale = Vector(0.11, 0.11, 0.11),
				Color = Color(255, 255, 150, 255),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 270, 0),
			},
			Tick = function(curProp, vehicle)
				if vehicle and vehicle.SpinAng and curProp.Ang then
					curProp.Ang:RotateAroundAxis(Vector(1, 0, 0), vehicle.SpinAng)
				end
			end
		}
	}
	self.Controls = {
		{
			Key = IN_JUMP,
			Name = "Move Up"
		},
		{
			Key = IN_DUCK,
			Name = "Move Down"
		},
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
	local pos = self:GetPos()
	local contents = util.PointContents(pos)
	local contents2 = util.PointContents(pos - Vector(0, 0, 1))
	return bit.band(contents, CONTENTS_WATER) == CONTENTS_WATER or bit.band(contents, CONTENTS_TRANSLUCENT) == CONTENTS_TRANSLUCENT
		or bit.band(contents2, CONTENTS_WATER) == CONTENTS_WATER or bit.band(contents2, CONTENTS_TRANSLUCENT) == CONTENTS_TRANSLUCENT
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
		local up_down = 0
		local side = 0
		if ply:KeyDown(IN_FORWARD) then
			forward_back = forward_back + 1
		end
		if ply:KeyDown(IN_BACK) then
			forward_back = forward_back - 1
		end
		if ply:KeyDown(IN_DUCK) then
			up_down = up_down - 1
		end
		if ply:KeyDown(IN_JUMP) then
			up_down = up_down + 1
		end
		if ply:KeyDown(IN_SPEED) then
			forward_back = forward_back * 1.5
			up_down = up_down * 1.5
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
			local newAngle = self:GetAngles()
			phys:AddVelocity(newAngle:Forward() * phys:GetMass() * forward_back * tick)
		end
		if up_down ~= 0 then
			local newAngle = self:GetAngles()
			phys:AddVelocity(newAngle:Up() * phys:GetMass() * up_down * tick)
		end
		self:SetSpin(forward_back)
		if side ~= 0 and math.abs(angle.p) < 45 then
			local angVel = phys:GetAngleVelocity()
			local yaw_sign =  angVel.z * -1 + side * 5--math.Clamp(roll, -2.5, 2.5)
			phys:AddAngleVelocity(Vector(0, 0, yaw_sign))
		end
		local pitch = GetPreferredRoute(angle.p, 0)
		local roll = GetPreferredRoute(angle.r, 0)
		local angVel = phys:GetAngleVelocity()
		local pitch_sign =  angVel.y * -1 + pitch * 5--math.Clamp(roll, -2.5, 2.5)
		local roll_sign =  angVel.x * -1 + roll * 5--math.Clamp(roll, -2.5, 2.5)
		phys:AddAngleVelocity(Vector(roll_sign, pitch_sign, yaw_sign))
	end
end

function ENT:Think()
	self:TickModels()

	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then
		if self:IsInWater() then
			phys:EnableGravity(false)
			if self.WasNotInWater then
				phys:SetVelocity(phys:GetVelocity() * Vector(1, 1, 0.1))
				if phys:GetVelocity().Z < 3 then
					self.WasNotInWater = false
				end
			end
		else
			phys:EnableGravity(true)
			self.WasNotInWater = true
		end
		phys:SetBuoyancyRatio(0)
		phys:Wake()
	end
end

if CLIENT then
	function ENT:Draw()
		if not self.Models then return end
		if not self.Models[1].Created then return self:CreateXMVModels() end
		self:DrawModels()

		self.SpinAng = self:GetSpin()
		self:DrawPlayer(Vector(11, 0, 0), Angle(0, 0, 0), 0.11, function(model)
			local seq = model:SelectWeightedSequence(ACT_DRIVE_JEEP)
			if model:GetSequence() ~= seq then
				model:ResetSequence(seq)
			end
			local newAng
			if not self.LastAng then self.LastAng = self:GetAngles() end
			if self.LastAng then
				local tang = math.floor((self.LastAng.Y - self:GetAngles().Y) * 100) / 100
				if tang == 0 then
					newAng = 0
				else
					newAng = math.Clamp(tang, -5, 5) * 3
				end
				self.LastAng = self:GetAngles()
			end
			if newAng then
				if not self.Steer then
					self.Steer = newAng
				end
				self.Steer = self.Steer + (newAng - self.Steer) * 0.05
				model:SetPoseParameter( "vehicle_steer", self.Steer)
			end
		end)

		self:DrawPlayerName(Vector(-2, 5.9, 2), Angle(0, 180, 90), 0.1)
	end
else
	function ENT:SpawnFunction(ply,tr)
		if not tr.Hit then return end
		local ent = ents.Create( self.ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 6 )
		ent:Spawn()
		ent:Activate()
		return ent
	end

end
scripted_ents.Register(ENT, ENT.ClassName, true)

list.Set("SpawnableEntities", ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
