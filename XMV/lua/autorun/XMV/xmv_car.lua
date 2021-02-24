if SERVER then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_car"
ENT.Spawnable = true
ENT.PrintName = "Car"
ENT.RenderGroup = RENDERGROUP_OPAQUE
local w = 8  --Width
local l = 8  --Length
--local h = 5  --Height
function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_junk/cardboard_box001a.mdl")


		local min = Vector(-w / 2, -l / 2,-3)
		local max = Vector(w / 2, l / 2, 2)

		self:PhysicsInitBox(min,max)


		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMaterial("gmod_ice")
			phys:SetDamping(3,4)
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min,max)
		self:PhysWake()
		self:SetMode(2)
		self:SetUseType(SIMPLE_USE)

		self:SetTurretCount(3)
		self.TurretPositions = {
			{Vector(1.5, -3.5, 0), Angle(0, -90, 0), 0.2},
			{Vector(-1.5, -3.5, 0), Angle(0, -90, 0), 0.2},
			{Vector(0, -3.5, 1.5), Angle(0, -90, 0), 0.2}
		}
	end

	self.Models = {
		{
			Pos = Vector(), Ang = Angle(),
			{
				Type = "Prop",
				Model = "models/props_junk/cardboard_box001a.mdl",
				Scale = Vector(0.2, 0.2, 0.2),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0),
			}
		},
		{
			Pos = Vector(), Ang = Angle(), DrawManual = true,
			{
				Type = "Prop",
				Model = "models/props_vehicles/carparts_wheel01a.mdl",
				Scale = Vector(0.15, 0.15, 0.15),
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, -90, 0),
			}
		},
	}

	self.Controls = {
		{
			Key = IN_JUMP,
			Name = "Jump!"
		},
		{
			Key = IN_WALK,
			Name = "Reset"
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
			Name = "Go Left (while in keyboard mode)"
		},
		{
			Key = IN_MOVERIGHT,
			Name = "Go Right (while in keyboard mode)"
		},
		{
			Key = IN_SPEED,
			Name = "Speed Up!"
		},
		{},
		{
			Key = IN_DUCK,
			Name = "Change control method"
		},
	}
end

function ENT:AreWheelsTouching()
	local normal = self:GetAngles():Up() * -1
	local trace = util.QuickTrace(self:GetPos(),normal * 200,{self})
	return trace, trace.StartPos:Distance(trace.HitPos) <= 5
end

function ENT:SetupDataTables2()
	self:NetworkVar( "Float", 0, "WheelDir")
	self:NetworkVar( "Int", 1, "Mode")
end
function ENT:OnMove(ply, data)
	local phys = self:GetPhysicsObject()
	if phys and phys:IsValid() then
		phys:Wake()
		local ang = self:GetAngles()
		local forward = ang:Right()
		local up = ang:Up()
		local right = ang:Forward()
		local _, hit = self:AreWheelsTouching()
		if hit then
			local shiftspeed = ply:KeyDown(IN_SPEED) and 2 or 1

			if ply:KeyDown(IN_FORWARD) then
				phys:AddVelocity(forward * phys:GetMass() * 1.2 * shiftspeed)
			end
			if ply:KeyDown(IN_BACK) then
				phys:AddVelocity(forward * phys:GetMass() * -1.2 * shiftspeed)
			end
			if ply:KeyDown(IN_JUMP) and (not self.lastjump or RealTime() - self.lastjump > 1) then
				phys:AddVelocity(up * phys:GetMass() * 30)
				self.lastjump = RealTime()
			end
			if self:GetMode() == 1 then
				if ply:KeyDown(IN_MOVELEFT) then
					phys:ApplyForceOffset(right, self:GetPos() + forward * 20)
				elseif ply:KeyDown(IN_MOVERIGHT) then
					phys:ApplyForceOffset(right * -1, self:GetPos() + forward * 20)
				end
			elseif self:GetMode() == 2 then
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
				local yaw = GetPreferredRoute(angle.y, ply:EyeAngles().Y + 90)
				--print(angle.Y, ply:EyeAngles().Y)
				local yaw_sign =  angVel.z * -1 + yaw * 5--math.Clamp(roll, -2.5, 2.5)
				--if math.abs(pitch) > 2 then
				--print(angVel, angle)
				--print(angVel, Vector(0, 0,  yaw_sign))
				phys:AddAngleVelocity(Vector(0, 0,  yaw_sign))

				angle = self:GetAngles()
				local yaw2 = GetPreferredRoute(angle.y, ply:EyeAngles().Y + 90)
				local near_zero = math.abs(math.floor(yaw2 * 10) / 10) < 2
				--print(ply:Nick(), math.abs(math.floor(yaw_sign * 10) / 10))
				if near_zero then
					self:SetWheelDir(0)
				else
					self:SetWheelDir(yaw_sign > 0 and 1 or -1)
				end
			end
			phys:SetDamping(3, 4)
		else
			if self:GetMode() == 2 then
				self:SetWheelDir(0)
			end
			phys:SetDamping(0, 0)
		end
	end

	if self:GetMode() == 1 then
		if ply:KeyDown(IN_MOVELEFT) then
			self:SetWheelDir(1)
		elseif ply:KeyDown(IN_MOVERIGHT) then
			self:SetWheelDir(-1)
		else
			self:SetWheelDir(0)
		end
	end
end

function ENT:OnKeyPress(ply, key)
	if key == IN_WALK then
		local ang = self:GetAngles()
		local ang_clean = Angle(0, ang.yaw, 0)
		self:SetAngles(ang_clean)
	end

	if key == IN_ATTACK2 and (not self.nexthonk or self.nexthonk < RealTime()) then
		sound.Play("ambient/alarms/klaxon1.wav",self:GetPos(),75,200)
		self.nexthonk = RealTime() + 5
	end
	if key == IN_DUCK then
		if self:GetMode() == 2 then
			self:GetDriver():ChatPrint"Keyboard Steering"
			self:SetMode(1)
		elseif self:GetMode() == 1 then
			self:GetDriver():ChatPrint"Mouse Steering"
			self:SetMode(2)
		end
	end
end

if CLIENT then

	function ENT:Draw()
		if not self.Models then return end
		if not self.Models[1].Created then return self:CreateXMVModels() end
		self:DrawModels()

		if not self.Steer then
			self.Steer = self:GetWheelDir()
		end

		self.Steer = self.Steer + (self:GetWheelDir() - self.Steer) * 0.025

		self.ang_off = self.ang_off or 0

		local wheelEntity = self.Models[2][1].Entity
		if not wheelEntity or not IsValid(wheelEntity) then return end

		for X = -1,1,2 do
			for Y = -1,1,2 do
				local pos_local = Vector(w / 2,l / 2,-1) * Vector(X,Y,1)
				local ang_local = Angle(self.ang_off, 90, 0)
				self.ang_off = self.ang_off - self:GetVelocity():Dot(self:GetAngles():Right()) / 50
				if Y == -1  then
					ang_local = ang_local + Angle(0, 20, 0) * self.Steer
				end
				local pos,ang = LocalToWorld(pos_local,ang_local,self:GetPos(),self:GetAngles())
				wheelEntity:SetRenderOrigin(pos)
				wheelEntity:SetRenderAngles(ang)
				wheelEntity:SetupBones()
				wheelEntity:DrawModel()
			end
		end

		self:DrawPlayer(Vector(0, 2, 1.0), Angle(0, -90, 0), 0.125, function(model)
			local seq = model:SelectWeightedSequence(ACT_DRIVE_JEEP)
			if model:GetSequence() ~= seq then
		        model:ResetSequence(seq)
		    end
		    model:SetPoseParameter( "vehicle_steer", self.Steer * -1 )
		end)
		self:DrawPlayerName(Vector(0, 0, 2.5), Angle(), 0.2)
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
end
scripted_ents.Register(ENT, ENT.ClassName, true)

list.Set("SpawnableEntities", ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
