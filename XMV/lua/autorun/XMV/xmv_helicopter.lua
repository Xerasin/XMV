if SERVER then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_helicopter"
ENT.PrintName = "Helicopter"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Forward = 0
-- Credits to LPine for code on how to use a shadow controller
ENT.PhysShadowControl = {}
ENT.PhysShadowControl.secondstoarrive  = 0.1 --SMALL NUMBERS
ENT.PhysShadowControl.pos			  = Vector(0, 0, 0)
ENT.PhysShadowControl.angle			= Angle(0, 0, 0)
ENT.PhysShadowControl.maxspeed		 = 1000000000000
ENT.PhysShadowControl.maxangular	   = 1000000
ENT.PhysShadowControl.maxspeeddamp	 = 10000
ENT.PhysShadowControl.maxangulardamp   = 1000000
ENT.PhysShadowControl.dampfactor	   = 1
ENT.PhysShadowControl.teleportdistance = 0
ENT.PhysShadowControl.deltatime		= deltatime

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_trainstation/train001.mdl")


		local min = Vector(-17, -4, -5)
		local max = Vector(17, 4, 5)

		self:PhysicsInitBox(min,max)
		--self:SetMoveType(MOVETYPE_NONE)

		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			--phys:SetMaterial("gmod_ice")
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min,max)
		self:PhysWake()
		self:SetUseType(SIMPLE_USE)
		self.PhysShadowControl.angle = self:GetAngles()
		self.PhysShadowControl.pos = self:GetPos()
		self:SetMode(2)
		self:SetSpin(5)
		constraint.Keepupright( self, Angle(0,0,0), 0, 99999 )

	end
	local woodMat
	if CLIENT then
		local params = {}
		params[ "$basetexture" ] = "phoenix_storms/wood"
		params[ "$vertexcolor" ] = 1

		woodMat = CreateMaterial( "WoodMaterialXMV" .. os.time(), "UnlitGeneric", params )
	end

	self.Models = {
		{
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_trainstation/train001.mdl",
				Scale = Vector(0.05, 0.05, 0.05),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, -90, 0),
			},
		},
		{
			Pos = Vector(0, 0, 5.5),
			Ang = Angle(),
			{
				Type = "Mesh",
				Mesh = xmv.BoxMesh(Vector(-0.25, -10, -0.15), Vector(0.25, 10, 0.15)),
				Material = woodMat,
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0),
			},
			{
				Type = "Mesh",
				Mesh = xmv.BoxMesh(Vector(-0.25, -10, -0.15), Vector(0.25, 10, 0.15)),
				Material = woodMat,
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 90, 0),
			},
			Tick = function(curProp, vehicle)
				if vehicle and vehicle.SpinAng and curProp.Ang then
					curProp.Ang:RotateAroundAxis(Vector(0, 0, 1), vehicle.SpinAng)
				end
			end
		},
	}

	self.Controls = {
		{
			Key = IN_JUMP,
			Name = "Move Up"
		},
		{
			Key = IN_WALK,
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
	self.AngOffset = Angle(0, 0, 0)
end

function ENT:AreWheelsTouching()
	local normal = self:GetAngles():Up() * -1
	local trace = util.QuickTrace(self:GetPos(),normal * 200,{self})
	return trace, trace.StartPos:Distance(trace.HitPos) <= 20
end

function ENT:SetupDataTables2()
	self:NetworkVar( "Int", 0, "Mode")
	self:NetworkVar( "Float", 0, "Spin")
end

function ENT:OnMove(ply, data)
	local tick = 66 / ( 1 / FrameTime())
	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then
		local eyeang = ply:EyeAngles()
		local ang = Angle(0, eyeang.y, 0)
		local _, hit = self:AreWheelsTouching()
		if hit and ply:KeyDown(IN_JUMP) then
			self:SetSpin(math.min(self:GetSpin() + 0.25, 10))
		end
		if self:GetSpin() == 10 then
			local ratio = self:GetSpin() / 10
			local UpDown = 0
			if ply:KeyDown(IN_JUMP) then
				UpDown = UpDown + 20
			end
			if ply:KeyDown(IN_WALK) then
				UpDown = UpDown - 20
			end
			local Forward = 0
			if ply:KeyDown(IN_FORWARD) then
				Forward = Forward + 30
			end
			if ply:KeyDown(IN_BACK) then
				Forward = Forward - 30
			end
			if Forward ~= 0 then
				UpDown = UpDown + 5
				ang.p = Forward
			end
			local Left = 0
			if ply:KeyDown(IN_MOVELEFT) then
				Left = Left - 30
			end
			if ply:KeyDown(IN_MOVERIGHT) then
				Left = Left + 30
			end
			if Left ~= 0 then
				--UpDown = UpDown + 5
				ang.r = Left
			end
			phys:ApplyForceCenter(self:GetUp() * ((UpDown * ratio) + (self:GetSpin() * 9.02  ) ) * tick )
		end
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
		local angVel = phys:GetAngleVelocity()
		local pitch = GetPreferredRoute(angle.p, ang.p)
		local yaw = GetPreferredRoute(angle.y, ang.y)
		local roll = GetPreferredRoute(angle.r, ang.r)
		local roll_sign = angVel.x * -1 + roll * 5--math.Clamp(roll, -2.5, 2.5)
		local pitch_sign = angVel.y * -1 + pitch * 5--math.Clamp(pitch, -2.5, 2.5)
		local yaw_sign =  angVel.z * -1 + yaw * 5--math.Clamp(roll, -2.5, 2.5)
		--if math.abs(pitch) > 2 then
		phys:AddAngleVelocity(Vector(roll_sign, pitch_sign,  yaw_sign))
		--end
		--if math.abs(roll) > 2 then
			--phys:AddAngleVelocity(Vector(, 0, 0))
		--end
		--print(pitch_sign, roll_sign)
	end
end


function ENT:Think()
	self:TickModels()
	if SERVER and not IsValid(self:GetDriver())  then
		self:SetSpin(0)
	end
end

function ENT:Draw()
	if not self.Models then return end
	if not self.Models[1].Created then return self:CreateXMVModels() end
	self:DrawModels()

	self.SpinAng = self:GetSpin() / 3

	self:DrawPlayer(Vector(10.0, 0, 3.25), Angle(0, 0, 0), 0.125, function(model)
		local seq = model:SelectWeightedSequence(ACT_DRIVE_JEEP)
		if model:GetSequence() ~= seq then
			model:ResetSequence(seq)
		end
		local ang
		if not self.LastAng then self.LastAng = self:GetAngles() end
		if self.LastAng then
			local tang = math.floor((self.LastAng.Y - self:GetAngles().Y) * 100) / 100
			if tang == 0 then
				ang = 0
			else
				ang = math.Clamp(tang, -5, 5) * 3
			end
			self.LastAng = self:GetAngles()
		end
		if ang then
			if not self.Steer then
				self.Steer = ang
			end
			self.Steer = self.Steer + (ang - self.Steer) * 0.05
			model:SetPoseParameter( "vehicle_steer", self.Steer)
		end
	end)
	self:DrawPlayerName(Vector(0, 3, 6), Angle(), 0.2)
end

if SERVER then
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

list.Set("SpawnableEntities", ENT.ClassName, {["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})