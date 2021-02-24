ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_ufo"
ENT.Spawnable = true
ENT.PrintName = "UFO"
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Initialize()

	if SERVER then
		local min = Vector(-15, -5, -3)
		local max = Vector(10, 5, 2)

		self:PhysicsInitBox(min,max)

		self:SetCollisionBounds(min,max)
		self:PhysWake()
		self:DrawShadow(false)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
			phys:SetMaterial("gmod_ice")
			phys:SetDamping(155, 155)
			phys:SetMass(10)
			phys:EnableGravity(false)
		end
	end

	self.Models = {
		{
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			TickType = "Rotate",
			RotateAng = Angle(0, 128, 0),
			{
				Type = "Prop",
				Model = "models/props_vehicles/tire001b_truck.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.1, 0.2, 0.2),
				Color = Color(150, 150, 150, 255),
				Pos = Vector(0, 0, -2),
				Ang = Angle(90, 90, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_wasteland/prison_lamp001c.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(1.2, 1.2, 0.8),
				Color = Color(200, 200, 200, 255),
				Pos = Vector(),
				Ang = Angle(),
			},
		},
		{
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_junk/watermelon01.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 255, 0, 255),
				Pos = Vector(0, 8, -1.9),
				Ang = Angle(0, 0, -28),
				TickType = "Rotate",
				RotateAng = Angle(0, 36, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_junk/watermelon01.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(0, 0, 255, 255),
				Pos = Vector(0, -8, -1.9),
				Ang = Angle(0, 0, 28),
				TickType = "Rotate",
				RotateAng = Angle(0, 36, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_junk/watermelon01.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 0, 255, 255),
				Pos = Vector(8, 0, -1.9),
				Ang = Angle(28, 0, 0),
				TickType = "Rotate",
				RotateAng = Angle(0, 36, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_junk/watermelon01.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 0, 0, 255),
				Pos = Vector(-8, 0, -1.9),
				Ang = Angle(-28, 0, 0),
				TickType = "Rotate",
				RotateAng = Angle(0, 36, 0),
			},

			TickType = "Rotate",
			RotateAng = Angle(0, -32, 0),
		},
		{
			Pos = Vector(0, 0, 0),
			Ang = Angle(0, 45, 0),
			{
				Type = "Prop",
				Model = "models/props_combine/breenclock.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 255, 0, 255),
				Pos = Vector(0, 8, -1.9),
				Ang = Angle(28, 90, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_combine/breenclock.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(0, 0, 255, 255),
				Pos = Vector(0, -8, -1.9),
				Ang = Angle(-28, 90, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_combine/breenclock.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 0, 255, 255),
				Pos = Vector(8, 0, -1.9),
				Ang = Angle(28, 0, 0),
			},
			{
				Type = "Prop",
				Model = "models/props_combine/breenclock.mdl",
				Material = "models/debug/debugwhite",
				Scale = Vector(0.2, 0.2, 0.2),
				Color = Color(255, 0, 0, 255),
				Pos = Vector(-8, 0, -1.9),
				Ang = Angle(-28, 0, 0),
			},

			TickType = "Rotate",
			RotateAng = Angle(0, -32, 0),
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
		{},
		{
			Key = IN_FORWARD,
			Name = "Go Forward"
		},
		{
			Key = IN_BACK,
			Name = "Go Back"
		},
		{
			Key = IN_MOVELEFT,
			Name = "Go Left"
		},
		{
			Key = IN_MOVERIGHT,
			Name = "Go Right"
		},
		{
			Key = IN_SPEED,
			Name = "Speed Up!"
		}
	}

	self:CreateXMVModels()
end


function ENT:OnMove(ply, data)
	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then
		phys:Wake()
		local shiftspeed = ply:KeyDown(IN_SPEED) and 2 or 1
		local vel = Vector()

		if ply:KeyDown(IN_JUMP) then
			vel.z = phys:GetMass() * 25 * shiftspeed
		elseif ply:KeyDown(IN_DUCK) then
			vel.z = phys:GetMass() * -25 * shiftspeed
		else
			vel.z = 0
		end

		if ply:KeyDown(IN_FORWARD) then
			local newVel = ply:EyeAngles():Forward() * phys:GetMass() * shiftspeed * 25
			vel.x = vel.x + newVel.x
			vel.y = vel.y + newVel.y
		end

		if ply:KeyDown(IN_BACK) then
			local newVel = ply:EyeAngles():Forward() * phys:GetMass() * shiftspeed * -25
			vel.x = vel.x + newVel.x
			vel.y = vel.y + newVel.y
		end

		if ply:KeyDown(IN_MOVELEFT) then
			local newVel = ply:EyeAngles():Right() * phys:GetMass() * shiftspeed * -25
			vel.x = vel.x + newVel.x
			vel.y = vel.y + newVel.y
		end

		if ply:KeyDown(IN_MOVERIGHT) then
			local newVel = ply:EyeAngles():Right() * phys:GetMass() * shiftspeed * 25
			vel.x = vel.x + newVel.x
			vel.y = vel.y + newVel.y
		end

		phys:AddAngleVelocity(phys:GetAngleVelocity() * -1)
		phys:SetVelocity(vel)
	end
end

function ENT:Think()
	self:TickModels()
	if SERVER then
		self:SetAngles(Angle())
	end
end

function ENT:Draw()
	if not self.Models then return end
	if not self.Models[1].Created then return self:CreateXMVModels() end
	self:DrawModels()

	self:DrawPlayer(Vector(0, 3, 0.2), Angle(0, -90, 0), 0.125, function(model)
		local seq = model:SelectWeightedSequence(ACT_DRIVE_JEEP)
		if model:GetSequence() ~= seq then
			model:ResetSequence(seq)
		end
		model:SetPoseParameter( "vehicle_steer", 0 )
	end)

	self:DrawPlayerName(Vector(0, -1, 2.5), Angle(0, 0, 30), 0.2)
end

scripted_ents.Register(ENT, ENT.ClassName, true)
list.Set("SpawnableEntities", ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
