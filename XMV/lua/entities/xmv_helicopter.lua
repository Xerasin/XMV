if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_helicopter"
ENT.PrintName = "Helicopter"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
-- Credits to LPine for code on how to use a shadow controller
ENT.PhysShadowControl = {}
ENT.PhysShadowControl.secondstoarrive  = 0.1 //SMALL NUMBERS
ENT.PhysShadowControl.pos              = Vector(0, 0, 0)
ENT.PhysShadowControl.angle            = Angle(0, 0, 0)
ENT.PhysShadowControl.maxspeed         = 1000000000000
ENT.PhysShadowControl.maxangular       = 1000000
ENT.PhysShadowControl.maxspeeddamp     = 10000
ENT.PhysShadowControl.maxangulardamp   = 1000000
ENT.PhysShadowControl.dampfactor       = 1
ENT.PhysShadowControl.teleportdistance = 0
ENT.PhysShadowControl.deltatime        = deltatime

function ENT:Initialize()
    if(SERVER) then
		self:SetModel("models/props_trainstation/train001.mdl")
		
 
		local min=Vector(-17, -4, -5)
		local max=Vector(17, 4, 5)
		
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
	self.AngOffset = Angle(0, 0, 0)
	local t = Vector(-13752.9140625, 95.98560333252, 14304.03125)
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
local speed = 10
function ENT:OnMove(ply, data)
	local tick = 66 / ( 1 / FrameTime())
	local phys = self:GetPhysicsObject()
	if(phys and phys:IsValid()) then
		local eyeang = ply:EyeAngles()
		local ang = Angle(0, eyeang.y, 0)
		local trace, hit = self:AreWheelsTouching()
		if hit then
			if not ply:KeyDown(IN_JUMP) then
				--self:SetSpin(math.max(self:GetSpin() - 0.25, 0))
			else
				self:SetSpin(math.min(self:GetSpin() + 0.25, 10))
			end
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
		else
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

if(CLIENT) then
	function ENT:CreateModels()
		local box = ClientsideModel("models/props_trainstation/train001.mdl", RENDERGROUP_OPAQUE)
		box:SetNoDraw(true)
		local mat = Matrix()
		mat:Scale(Vector(0.05,0.05,0.05))
		box:EnableMatrix("RenderMultiply", mat)
		self.box = box
		self.box:SetRenderOrigin(self:GetPos())
		self.box:SetRenderAngles(self:GetAngles())
		self.box:SetParent(self)
		
		local params = {}
		params[ "$basetexture" ] = "phoenix_storms/iron_rails"
		params[ "$vertexcolor" ] = 1
		--params[ "$vertexalpha" ] = 1
				
		self.Mat = CreateMaterial( "Track_Material" .. os.time(), "UnlitGeneric", params )
		
		local params = {}
		params[ "$basetexture" ] = "phoenix_storms/wood"
		params[ "$vertexcolor" ] = 1
		--params[ "$vertexalpha" ] = 1
				
		self.Mat2 = CreateMaterial( "Track_Material2" .. os.time(), "UnlitGeneric", params )
		
		local function ReturnMesh(v1, v2)
			local col = Color(255, 255, 255)
			local x,y,z,x2,y2,z2 = v1.x,v1.y,v1.z,v2.x,v2.y,v2.z
			local tbl = {}
			local ou,ov = 0,0
			local u1,v1 = ou,ov
			local u2,v2 = ou + 1, ov + 1
			--
			table.insert(tbl,{color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z2),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z2),  u = u2, v = v2})
					
			table.insert(tbl,{color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z2),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z2),  u = u2, v = v1})
			--
			table.insert(tbl,{color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y, z),  u = u1, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
				
			table.insert(tbl,{color = col, pos = Vector(x, y, z),  u = u1, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z),  u = u2, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
			--
			table.insert(tbl,{color = col, pos = Vector(x, y, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
			
			table.insert(tbl,{color = col, pos = Vector(x, y, z2),  u = u2, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x, y, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
			--
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z2),  u = u1, v = v1})
			
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z2),  u = u2, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z2),  u = u1, v = v1})
			--
			table.insert(tbl,{color = col, pos = Vector(x2, y, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y, z),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
			
			table.insert(tbl,{color = col, pos = Vector(x2, y, z2),  u = u2, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x2, y, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y, z2),  u = u1, v = v1})
			--
			table.insert(tbl,{color = col, pos = Vector(x, y2, z),  u = u1, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
			
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z),  u = u2, v = v2})
			table.insert(tbl,{color = col, pos = Vector(x2, y2, z2),  u = u2, v = v1})
			table.insert(tbl,{color = col, pos = Vector(x, y2, z2),  u = u1, v = v1})
			--
			
			
			return tbl
		end
		self.Rail = Mesh()
		self.Rail:BuildFromTriangles(ReturnMesh(Vector(-0.25, -10, -0.25), Vector(0.25, 10, 0.25)))
	end
	
	function ENT:Draw()
		if not self.box or not self.box:IsValid() then self:CreateModels() end
		local ltrack = nil
		--for k,v in pairs(self.tracks or {}) do
			local function DrawMesh(mesh, vec, ang)
				render.OverrideDepthEnable( true, true )
					local mat = Matrix()
					mat:Translate(vec)
					mat:Rotate(ang)
					cam.PushModelMatrix( mat )
						mesh:Draw()
					cam.PopModelMatrix()
				render.OverrideDepthEnable( false, false )
			end
			--[[render.DrawLine( pos, pos + ang:Up(), Color(255, 0, 0), true )
			render.DrawLine( pos, pos + ang:Right(), Color(0, 255, 0), true )
			render.DrawLine( pos, pos + ang:Forward(), Color(0, 0, 255), true )]]
			render.SetMaterial(self.Mat2)
			self.SpinAng = self.SpinAng or 0
			self.SpinAng = self.SpinAng + self:GetSpin()
			local ang = self:GetAngles()
			local tang = Angle(ang.p,ang.y,ang.r)
			tang:RotateAroundAxis(tang:Up(), self.SpinAng)
			DrawMesh(self.Rail, self:GetPos() + self:GetAngles():Up() * 5, tang)
			tang:RotateAroundAxis(tang:Up(), 90)
			DrawMesh(self.Rail, self:GetPos() + self:GetAngles():Up() * 5, tang)
		--end
		
		self.box:SetRenderOrigin(self:GetPos())
		local ang = self:GetAngles()
		ang:RotateAroundAxis(ang:Up(), -90)
		self.box:SetRenderAngles(ang)
		self.box:DrawModel()
		self.ang_off = self.ang_off or 0
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
else
	function ENT:Think()
		if not IsValid(self:GetDriver()) then
			self:SetSpin(0)
		end
	end
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