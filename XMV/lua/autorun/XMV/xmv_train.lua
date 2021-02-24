if SERVER then AddCSLuaFile() end
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
ENT.PhysShadowControl.secondstoarrive  = 0.1
ENT.PhysShadowControl.pos			  = Vector(0, 0, 0)
ENT.PhysShadowControl.angle			= Angle(0, 0, 0)
ENT.PhysShadowControl.maxspeed		 = 1000000000000
ENT.PhysShadowControl.maxangular	   = 1000000
ENT.PhysShadowControl.maxspeeddamp	 = 10000
ENT.PhysShadowControl.maxangulardamp   = 1000000
ENT.PhysShadowControl.dampfactor	   = 1
ENT.PhysShadowControl.teleportdistance = 0

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
			phys:SetMaterial("gmod_ice")
			phys:SetMass(10)
		end
		self:SetCollisionBounds(min,max)

		self:SetUseType(SIMPLE_USE)
		self.PhysShadowControl.angle = self:GetAngles()
		self.PhysShadowControl.pos = self:GetPos()
		self:SetMode(2)
		self:StartMotionController()
	end
	self.AngOffset = Angle(0, 0, 0)
	self.tracks = {}


	local mat1, mat2
	if CLIENT then

		local params = {}
		params[ "$basetexture" ] = "phoenix_storms/iron_rails"
		params[ "$vertexcolor" ] = 1

		mat1 = CreateMaterial( "Track_Material" .. os.time(), "UnlitGeneric", params )

		params = {}
		params[ "$basetexture" ] = "phoenix_storms/wood"
		params[ "$vertexcolor" ] = 1
		mat2 = CreateMaterial( "Track_Material2" .. os.time(), "UnlitGeneric", params )
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
			ManualDraw = true,
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			{
				Type = "Mesh",
				Mesh = xmv.BoxMesh(Vector(0, 0, 0), Vector(track_length, 0.3, 0.2)),
				Material = mat1,
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0),
			},
		},
		{
			ManualDraw = true,
			Pos = Vector(0, 0, 0),
			Ang = Angle(),
			{
				Type = "Mesh",
				Mesh = xmv.BoxMesh(Vector(-3.25, 0, 0), Vector(3.25, track_length * 0.3, 0.1)),
				Material = mat2,
				Pos = Vector(0, 0, 0),
				Ang = Angle(0, 0, 0),
			},
		},
	}

	self.Controls = {
		{
			Key = IN_FORWARD,
			Name = "Go Forward"
		},
		{
			Key = IN_DUCK,
			Name = "Change control method"
		},
		{},
		"  Keyboard Mode Controls  ",
		{},
		{
			Key = IN_FORWARD,
			Name = "Go Forward"
		},
		{
			Key = IN_JUMP,
			Name = "Move Up"
		},
		{
			Key = IN_SPEED,
			Name = "Move Down"
		},
		{
			Key = IN_MOVELEFT,
			Name = "Go Left"
		},
		{
			Key = IN_MOVERIGHT,
			Name = "Go Riight"
		},

	}
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
			if ply:KeyDown(IN_FORWARD) then
				ang = Angle()
				if ply:KeyDown(IN_JUMP) then
					ang = Angle(-10, 0, 0)
				elseif ply:KeyDown(IN_SPEED) then
					ang = Angle(10, 0, 0)
				end

			end
			if ply:KeyDown(IN_MOVELEFT) then
				ang = Angle(0, 10, 0)
			end
			if ply:KeyDown(IN_MOVERIGHT) then
				ang = Angle(0, -10, 0)
			end
		else
			if ply:KeyDown(IN_FORWARD) then
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

if CLIENT then
	function ENT:Draw()
		if not self.Models then return end
		if not self.Models[1].Created then return self:CreateXMVModels() end

		self.Rail, self.WoodenPart = self.Models[2][1].MeshObject, self.Models[3][1].MeshObject
		local railMat, woodMat = self.Models[2][1].Material, self.Models[3][1].Material
		if not self.Rail or not self.WoodenPart then return end

		for k,v in pairs(self.tracks or {}) do
			local function DrawMesh(mesh, vec, ang)
				print(mesh)
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
			local ang = v[2]

			--[[render.DrawLine( pos, pos + ang:Up(), Color(255, 0, 0), true )
			render.DrawLine( pos, pos + ang:Right(), Color(0, 255, 0), true )
			render.DrawLine( pos, pos + ang:Forward(), Color(0, 0, 255), true )]]

			local t = track_length * 0.25 - track_length * 0.15
			render.SetMaterial(woodMat)
			local tang = Angle(ang.p, ang.y, ang.r)
			tang:RotateAroundAxis(tang:Up(), -90)

			DrawMesh(self.WoodenPart, pos + ang:Forward() * t, tang)
			t = track_length * 0.75 - track_length * 0.15
			DrawMesh(self.WoodenPart, pos + ang:Forward() * t, tang)

			render.SetMaterial(railMat)
			DrawMesh(self.Rail, pos + ang:Right() * 2 + ang:Up() * 0.05, ang)
			DrawMesh(self.Rail, pos + ang:Right() * -2 + ang:Up() * 0.05, ang)
		end

		self.ang_off = self.ang_off or 0
		self:DrawModels()

		self:DrawPlayer(Vector(10.0, 0, 3.25), Angle(0, 0, 0), 0.125, function(model)
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
			local newTrack = {}
			newTrack[1] = Vector(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
			newTrack[2] = Angle(net.ReadDouble(), net.ReadDouble(), net.ReadDouble())
			table.insert(ent.tracks, newTrack)
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
		if not tr.Hit then return end
		local ent = ents.Create( self.ClassName )
		ent:SetPos( tr.HitPos + tr.HitNormal * 6 )
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

function ENT:Think()
	self:TickModels()
end
scripted_ents.Register(ENT, ENT.ClassName, true)

list.Set("SpawnableEntities",ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
