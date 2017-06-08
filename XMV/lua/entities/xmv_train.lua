if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_train"
ENT.PrintName = "Train"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
local track_length = 3
local max_track_length = 20
local max_track_length_cl = 200
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
			phys:SetMaterial("gmod_ice")
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min,max)
		self:PhysWake()
		self:SetUseType(SIMPLE_USE)
		self.PhysShadowControl.angle = self:GetAngles()
		self.PhysShadowControl.pos = self:GetPos()
		self:SetMode(2)
		self:StartMotionController()
    end
	self.AngOffset = Angle(0, 0, 0)
	local t = Vector(-13752.9140625, 95.98560333252, 14304.03125)
	self.tracks = {}
end
function ENT:SetupDataTables2()
	self:NetworkVar( "Int", 0, "Mode")
end
function ENT:NetworkTrack()
	net.Start("TRAINTRACK_UPDATE")
		net.WriteEntity(self)
		net.WriteTable(self.tracks)
	net.Broadcast()
end
function ENT:NetworkAdd(tab)
	net.Start("TRAINTRACK_ADD")
		net.WriteEntity(self)
		net.WriteDouble(tab[1].x)
		net.WriteDouble(tab[1].y)
		net.WriteDouble(tab[1].z)
		net.WriteDouble(tab[2].p)
		net.WriteDouble(tab[2].y)
		net.WriteDouble(tab[2].r)
	net.Broadcast()
end
function ENT:OnMove(ply, data)
	if not self.LastMove or self.LastMove + 0.01 < CurTime() then
		if #self.tracks > max_track_length then
			table.remove(self.tracks, 1)
		end
		local ltrack = self.tracks[#self.tracks]
		if not ltrack then
			ltrack = {}
			ltrack[1] = self:GetPos() - self:GetAngles():Up() * 4
			ltrack[2] = self:GetAngles()
		end
		local ang = nil
		if self:GetMode() == 1 then
			if(ply:KeyDown(IN_FORWARD)) then
				ang = Angle()
				if ply:KeyDown(IN_JUMP) then
					ang = Angle(-10, 0, 0)
				elseif ply:KeyDown(IN_SPEED) then
					ang = Angle(10, 0, 0)
				end
				
			end
			
			if(ply:KeyDown(IN_BACK)) then
				--[[ang = Angle(0, 180, 0)
				if ply:KeyDown(IN_JUMP) then
					ang = Angle(10, 0, 0)
				elseif ply:KeyDown(IN_WALK) then
					ang = Angle(-10, 0, 0)
				end]]
				
			end
			if(ply:KeyDown(IN_MOVELEFT)) then
				ang = Angle(0, 10, 0)
			end
			if(ply:KeyDown(IN_MOVERIGHT)) then
				ang = Angle(0, -10, 0)
			end
		else
			if(ply:KeyDown(IN_FORWARD)) then
				ang = ltrack[2]
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
						return math.Clamp(resolved_dif, -10, 10)
					else
						return 0
					end
				end
				local eyeang = ply:EyeAngles()
				local ang_dif = Vector(ang.p,ang.y,ang.r) - Vector(eyeang.p,eyeang.y,0)
				local yaw = GetPreferredRoute(ang.y, eyeang.y)
				local pitch = GetPreferredRoute(ang.p, eyeang.p)
				ang_dif.z = ang_dif.z * -1
				--print(ang.p, eyeang.p, ang_dif.x, pitch)
				ang = Angle(pitch, yaw, math.Clamp(ang_dif.z, -10, 10))
			end
			if(ply:KeyDown(IN_BACK)) then
				--ang = Angle(0, 180, 0)
			end
		end
		if ply:KeyDown(IN_DUCK) and not ply:KeyDownLast(IN_DUCK) then
			if self:GetMode() == 2 then
				self:GetDriver():ChatPrint"Keyboard Steering"
				self:SetMode(1)
			elseif self:GetMode() == 1 then
				self:GetDriver():ChatPrint"Mouse Steering"
				self:SetMode(2)
			end
		end
		if ply:KeyDown(IN_ATTACK2) and not ply:KeyDownLast(IN_ATTACK2) and (not self.nexthonk or self.nexthonk < RealTime()) then
			sound.Play("ambient/alarms/train_horn2.wav",self:GetPos(),75,200)
			self.nexthonk = RealTime() + 5
		end
		if ang then
			
			local Tpos,Tang = LocalToWorld(Vector(track_length, 0, 0), ang, ltrack[1], ltrack[2])
			--print(Tang, (ang + ltrack[2]))
			Tang = ltrack[2] + ang
			local trace = util.QuickTrace(Tpos, Tang:Forward():GetNormal() * track_length * 15, self)
			local distance = trace.HitPos:Distance(trace.StartPos)
			if not trace.Hit or true then
				track = {}
				track[1] = Tpos
				track[2] = Tang
				table.insert(self.tracks, track)
				self:NetworkAdd(track)
			end
		end
		self.LastMove = CurTime()
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
		self.Rail:BuildFromTriangles(ReturnMesh(Vector(0, 0, 0), Vector(track_length, 0.3, 0.2)))
		
		self.WoodenPart = Mesh()
		self.WoodenPart:BuildFromTriangles(ReturnMesh(Vector(-3.25, 0, 0), Vector(3.25, track_length * 0.3, 0.1)))
	end
	
	function ENT:Draw()
		if not self.box or not self.box:IsValid() then self:CreateModels() end
		local ltrack = nil
		for k,v in pairs(self.tracks or {}) do
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
			local pos = v[1]
			local pos2 = v[1] + v[2]:Forward() * track_length
			local ang = v[2]
			
			--[[render.DrawLine( pos, pos + ang:Up(), Color(255, 0, 0), true )
			render.DrawLine( pos, pos + ang:Right(), Color(0, 255, 0), true )
			render.DrawLine( pos, pos + ang:Forward(), Color(0, 0, 255), true )]]
			
			local t = track_length * 0.25 - track_length * 0.15
			render.SetMaterial(self.Mat2)
			local tang = Angle(ang.p, ang.y, ang.r)
			tang:RotateAroundAxis(tang:Up(), -90)
			
			DrawMesh(self.WoodenPart, pos + ang:Forward() * t, tang)
			local t = track_length * 0.75 - track_length * 0.15
			DrawMesh(self.WoodenPart, pos + ang:Forward() * t, tang)
			
			render.SetMaterial(self.Mat)
			DrawMesh(self.Rail, pos + ang:Right() * 2 + ang:Up() * 0.05, ang)
			DrawMesh(self.Rail, pos + ang:Right() * -2 + ang:Up() * 0.05, ang)
		end
		
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
	net.Receive("TRAINTRACK_UPDATE", function(len)
		local ent = net.ReadEntity()
		if ent and ent:IsValid() then
			ent.tracks = net.ReadTable()
		end
	end)
	
	net.Receive("TRAINTRACK_ADD", function(len)
		local ent = net.ReadEntity()
		
		if ent and ent:IsValid() then
			ent.tracks = ent.tracks or {}
			local track = {}
			track[1] = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
			track[2] = Angle(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
			table.insert(ent.tracks, track)
			if #ent.tracks > max_track_length_cl then
				table.remove(ent.tracks, 1)
			end
		end
	end)
else
	util.AddNetworkString("TRAINTRACK_UPDATE")
	util.AddNetworkString("TRAINTRACK_ADD")
	function ENT:PhysicsSimulate(phys, deltatime)
		phys:Wake()
		if #self.tracks > 10 then
			
			local track1 = self.tracks[#self.tracks - 8][2]
			local track2 = self.tracks[#self.tracks - 8][2]
			local ang = Angle((track1.p + track2.p) * 0.5, (track1.y + track2.y) * 0.5, (track1.r + track2.r) * 0.5)
			local new_pos = self.tracks[#self.tracks - 8][1] + ang:Up() * 6
			self.PhysShadowControl.pos = new_pos
			self.PhysShadowControl.angle = ang
			if new_pos:Distance(self:GetPos()) > 100 then
				self.tracks = {}
				net.Start("TRAINTRACK_UPDATE")
					net.WriteEntity(self)
					net.WriteTable({})
				net.Broadcast()
			end
		else
			self.PhysShadowControl.angle = self:GetAngles()
			self.PhysShadowControl.pos = self:GetPos()
		end
		self.PhysShadowControl.deltatime = deltatime
		return phys:ComputeShadowControl(self.PhysShadowControl)
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
