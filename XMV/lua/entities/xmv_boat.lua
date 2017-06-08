if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_boat"
ENT.PrintName = "Boat"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
local scale = 0.4
local propeller_pos = Vector(-20, 0, -6)
local propeller_ang = 12.5
function ENT:Initialize()
    if(SERVER) then
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
	if(phys and phys:IsValid() and self:IsInWater()) then
		local forward = self:GetForward()
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
			local angle = self:GetAngles()
			angle:RotateAroundAxis(angle:Forward(), propeller_ang)
			local pos = self:LocalToWorld(propeller_pos)
			phys:ApplyForceOffset(angle:Forward() * phys:GetMass() * forward_back * tick, pos)
		end
		self:SetSpin(forward_back)
		if side ~= 0 then
			if math.abs(angle.p) < 45 then
				local angVel = phys:GetAngleVelocity()
				local yaw_sign =  angVel.z * -1 + side * 5--math.Clamp(roll, -2.5, 2.5)
				phys:AddAngleVelocity(Vector(0, 0, yaw_sign))
			end
		end
	end
end

if(CLIENT) then
	function ENT:CreateModels()
		local box = ClientsideModel("models/props_canal/boat002b.mdl", RENDERGROUP_OPAQUE)
		local engine = ClientsideModel("models/props_c17/TrapPropeller_Engine.mdl", RENDERGROUP_OPAQUE)
		local rod = ClientsideModel("models/props_docks/dock01_pole01a_256.mdl", RENDERGROUP_OPAQUE)
		local propeller = ClientsideModel("models/props_c17/TrapPropeller_Blade.mdl", RENDERGROUP_OPAQUE)
		local function SetupModel(box, scale)
			box:SetNoDraw(true)
			local mat = Matrix()
			mat:Scale(scale)
			box:EnableMatrix("RenderMultiply", mat)
			box:SetRenderOrigin(self:GetPos())
			box:SetRenderAngles(self:GetAngles())
			box:SetParent(self)
			return box
		end
		self.box = SetupModel(box, Vector(1, 1, 1) * scale)
		self.engine = SetupModel(engine, Vector(1, 1, 1) * scale / 1.25)
		self.rod = SetupModel(rod, Vector(1, 1, 1.25) * scale / 16)
		self.propeller = SetupModel(propeller, Vector(1, 1, 1) * scale / 2)
	end
	function ENT:Draw()
		if not self.box then
			self:CreateModels()
		end
		local function SetupModel(box, pos, ang)
			box:SetRenderOrigin(pos)
			box:SetRenderAngles(ang)
		end
		
		SetupModel(self.box, self:GetPos(), self:GetAngles())
		self.box:DrawModel()
		
		self.SpinAng = self.SpinAng or 0
		self.SpinAng = self.SpinAng + self:GetSpin()
		local propeller_angle = self:GetAngles()
		propeller_angle:RotateAroundAxis(propeller_angle:Forward(), propeller_ang)
		propeller_angle:RotateAroundAxis(propeller_angle:Right(), 90)
		propeller_angle:RotateAroundAxis(propeller_angle:Up(), self.SpinAng)
		local pos = LocalToWorld(propeller_pos, Angle(), self:GetPos(), self:GetAngles())
		SetupModel(self.propeller, pos, propeller_angle)
		self.propeller:DrawModel()
		local propeller_angle = self:GetAngles()
		propeller_angle:RotateAroundAxis(propeller_angle:Forward(), propeller_ang)
		propeller_angle:RotateAroundAxis(propeller_angle:Right(), 90)
		local rodpos = pos + propeller_angle:Up() * -10.25 * scale
		SetupModel(self.rod, rodpos, propeller_angle)
		self.rod:DrawModel()
		
		local enginepos = (rodpos + pos) / 2 + self:GetUp() * 13 * scale + propeller_angle:Up() * -6.25 * scale
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Right(), -90)
		ang:RotateAroundAxis(ang:Up(), 180)
		SetupModel(self.engine, enginepos, ang)
		self.engine:DrawModel()
		self:DrawPlayer(Vector(-8, 5, -1.0), Angle(0, 0, 0), 0.25, function(model)
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
		--[[local pos = self:LocalToWorld(propeller_pos)
		render.DrawBox(pos, Angle(), Vector(-1, -1, -1) * 0.1, Vector(1, 1, 1) * 0.1, Color(255, 255, 255), false)
		local propeller_angle = self:GetAngles()
		propeller_angle.p = propeller_angle.p - propeller_ang
		render.DrawLine(pos, pos + propeller_angle:Forward() * 5, Color(255, 0, 0), false)
		]]
		self:DrawPlayerName(Vector(0, 3, 2), Angle(0, 0, 0), 0.2)
	end
else
	function ENT:SpawnFunction(ply,tr)
		if ( !tr.Hit ) then return end
		local ent = ents.Create( self.ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 2 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
	function ENT:Think()
		local phys = self:GetPhysicsObject()
		if phys and phys:IsValid() then
			phys:SetBuoyancyRatio(0.065)
			phys:Wake()
		end
	end
end
scripted_ents.Register(ENT, ENT.ClassName, true)
	
list.Set('SpawnableEntities',ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
