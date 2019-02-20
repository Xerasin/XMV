if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_submarine"
ENT.PrintName = "Submarine"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
function ENT:Initialize()
    if(SERVER) then
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
	local t = Vector(-13752.9140625, 95.98560333252, 14304.03125)
	self.tracks = {}
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
	if(phys and phys:IsValid() and self:IsInWater()) then
		local forward = self:GetForward()
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
			local angle = self:GetAngles()
			local pos = self:GetPos()
			phys:AddVelocity(angle:Forward() * phys:GetMass() * forward_back * tick)
		end
		if up_down ~= 0 then
			local angle = self:GetAngles()
			local pos = self:GetPos()
			phys:AddVelocity(angle:Up() * phys:GetMass() * up_down * tick)
		end
		self:SetSpin(forward_back)
		if side ~= 0 then
			if math.abs(angle.p) < 45 then
				local angVel = phys:GetAngleVelocity()
				local yaw_sign =  angVel.z * -1 + side * 5--math.Clamp(roll, -2.5, 2.5)
				phys:AddAngleVelocity(Vector(0, 0, yaw_sign))
			end
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
if(CLIENT) then
	function ENT:CreateModels()
		local chair,cover,propeller,propeller2,propeller3,propeller4
		if not self.ModelsCreated then
			chair = ClientsideModel("models/props_combine/breenchair.mdl", RENDERGROUP_OPAQUE)
			cover = ClientsideModel("models/props_phx/construct/windows/window_dome360.mdl", RENDERGROUP_TRANSLUCENT)
			propeller = ClientsideModel("models/props_c17/TrapPropeller_Blade.mdl", RENDERGROUP_OPAQUE)
			propeller2 = ClientsideModel("models/props_c17/TrapPropeller_Blade.mdl", RENDERGROUP_OPAQUE)
			propeller3 = ClientsideModel("models/props_c17/TrapPropeller_Blade.mdl", RENDERGROUP_OPAQUE)
			propeller4 = ClientsideModel("models/props_c17/TrapPropeller_Blade.mdl", RENDERGROUP_OPAQUE)
			
		end
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
		self.chair = SetupModel(chair or self.chair, Vector(1, 1, 1) * 0.11)
		self.cover = SetupModel(cover or self.cover, Vector(1, 1, 1) * 0.11)
		self.propeller = SetupModel(propeller or self.propeller, Vector(1, 1, 1) * 0.15)
		self.propeller2 = SetupModel(propeller2 or self.propeller2, Vector(1, 1, 1) * 0.15)
		self.propeller3 = SetupModel(propeller3 or self.propeller3, Vector(1, 1, 1) * 0.15)
		self.propeller4 = SetupModel(propeller4 or self.propeller4, Vector(1, 1, 1) * 0.15)
		self.ModelsCreated = true
	end
	function ENT:Draw()
		--if not self.ModelsCreated then
			self:CreateModels()
		--end
		local pos,ang = LocalToWorld(Vector(2, 0, 10.5), Angle(-90, 0, 0), self:GetPos(), self:GetAngles())
		self.chair:SetRenderOrigin(pos)
		self.chair:SetRenderAngles(ang)
		self.chair:DrawModel()
		
		self.NewSpin = self.NewSpin or 0
		self.NewSpin = self.NewSpin + (self:GetSpin() - self.NewSpin) * 0.1
		self.SpinAng = self.SpinAng or 0
		self.SpinAng = self.SpinAng + self.NewSpin * 3
		
		local pos,ang = LocalToWorld(Vector(0, 0, -10), Angle(180, 90 + self.SpinAng % 360, 0), self:GetPos(), self:GetAngles())
		self.propeller:SetRenderOrigin(pos)
		self.propeller:SetRenderAngles(ang)
		self.propeller:DrawModel()
		
		local pos,ang = LocalToWorld(Vector(0, 0, -10), Angle(180, 0 + self.SpinAng % 360, 0), self:GetPos(), self:GetAngles())
		self.propeller2:SetRenderOrigin(pos)
		self.propeller2:SetRenderAngles(ang)
		self.propeller2:DrawModel()
		
		local pos,ang = LocalToWorld(Vector(0, 0, -10), Angle(180, 270 + self.SpinAng % 360, 0), self:GetPos(), self:GetAngles())
		self.propeller3:SetRenderOrigin(pos)
		self.propeller3:SetRenderAngles(ang)
		self.propeller3:DrawModel()
		
		local pos,ang = LocalToWorld(Vector(0, 0, -10), Angle(180, 180 + self.SpinAng % 360, 0), self:GetPos(), self:GetAngles())
		self.propeller4:SetRenderOrigin(pos)
		self.propeller4:SetRenderAngles(ang)
		self.propeller4:DrawModel()
		
		local mat = Matrix()
		mat:Scale(Vector(1, 1, 1) * 0.4)
		self:SetRenderAngles(self:LocalToWorldAngles(Angle(90, 0, 0)))
		self:EnableMatrix("RenderMultiply", mat)
		self:DrawModel()
		
		self:DrawPlayer(Vector(0, 0, 10), Angle(-90, 0, 0), 0.11, function(model)
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
		self:DrawPlayerName(Vector(-1, 6, 0), Angle(90, 90, 0), 0.1)
		local pos,ang = LocalToWorld(Vector(0, 0, 10), Angle(0, 90, 0), self:GetPos(), self:GetAngles())
		self.cover:SetRenderOrigin(pos)
		self.cover:SetRenderAngles(ang)
		self.cover:DrawModel()
	end
else
	function ENT:SpawnFunction(ply,tr)
		if ( !tr.Hit ) then return end
		local ent = ents.Create( self.ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 6 )
		ent:Spawn()
		ent:Activate()
		return ent
	end

end
scripted_ents.Register(ENT, ENT.ClassName, true)

list.Set('SpawnableEntities',ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
