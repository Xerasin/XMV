if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.ClassName = "xmv_base"
ENT.PrintName = "Base XMV"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
function ENT:Initialize()
	if(SERVER) then
		self:SetModel("models/props_junk/cardboard_box001a.mdl")
		
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end
		self:PhysWake()
		self:SetUseType(SIMPLE_USE)
		self:SetViewMode(0)
	end
	if CLIENT then
		self.CameraDist 	= 4
		self.CameraDistVel 	= 0.1
	end
	self.TurretPositions = 
	{
	}
	self.AngOffset = Angle(0,90,0)
end

-- todo: whitelist/blacklist
function ENT:CanProperty()
	return false
end

function ENT:Touch(ent)
	if IsValid(ent) then
		if ent:GetClass() == "trigger_teleport" then
			SafeRemoveEntity(self)
		end
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Driver")
	self:NetworkVar( "Int", 14, "ViewMode")
	self:NetworkVar( "Int", 0, "TurretCount")
	self:NetworkVar( "Int", 0, "MaxHealth")
	self:NetworkVar( "Int", 0, "Health")
	self:SetupDataTables2()
end

function ENT:SetupDataTables2()
	--Filler
end
function ENT:OnMove(ply, data)


end
function ENT:OnKeyPress(ply, key)
	
end

local t = {start=nil,endpos=nil,mask=MASK_PLAYERSOLID,filter=nil}
local function PlayerNotStuck(ply, pos)

	t.start = pos or ply:GetPos()
	t.endpos = t.start
	t.filter = ply
	return util.TraceEntity(t,ply).StartSolid == false
	
	
end

local function FindPassableSpace( ply, direction, step )
	local OldPos = ply:GetPos()
	local i = 0
	local origin = ply:GetPos()
	while ( i < 14 ) do
		

		origin = origin + step * direction
		if ( PlayerNotStuck( ply , origin) ) then
			return true, origin
		end
		i = i + 1
	end
	--ply:SetPos(OldPos)
	return false, OldPos
end

local function UnstuckPlayer( pl , ang)
	ply = pl

	NewPos = ply:GetPos()
	local OldPos = NewPos
	
	if ( !PlayerNotStuck( ply ) ) then
	
		local angle = ang or ply:GetAngles()
		
		local forward = angle:Forward()
		local right = angle:Right()
		local up = angle:Up()
		
		local SearchScale = 1
		local found
		found, NewPos = FindPassableSpace(  pl, forward, -SearchScale )
		if ( not found ) then
			found, NewPos = FindPassableSpace(  pl, right, SearchScale )
			if ( not found ) then
				found, NewPos = FindPassableSpace(  pl, right, -SearchScale )
				if ( not found ) then
					found, NewPos = FindPassableSpace(  pl, up, SearchScale )
					if ( not found ) then
						found, NewPos = FindPassableSpace(  pl, up, -SearchScale )
						if ( not found ) then
							found, NewPos = FindPassableSpace(  pl, forward, SearchScale )
							if ( not found ) then
								return false
							end
						end
					end
				end
			end
		end
		
		if OldPos == NewPos then
			return true -- ???
		else
			ply:SetPos( NewPos )
			if SERVER and ply and ply:IsValid() and ply:GetPhysicsObject():IsValid() then
				if ply:IsPlayer() then
					ply:SetVelocity(vector_origin)
				end
				ply:GetPhysicsObject():SetVelocity(vector_origin) -- For some reason setting origin MAY apply some velocity so we're resetting it here.
			end
			return true
		end
		
	end
end
function ENT:AssignPlayer(ply, driver)
	local rider = driver or self:GetDriver()
	if(self:GetDriver() and self:GetDriver():IsValid()) then
		local out_pos = self:GetPos()+Vector(0,0,20)
		local trace = util.TraceEntity({
			start = out_pos,
			endpos = out_pos,
			mask = MASK_PLAYERSOLID,
			filter = {self, rider},
		}, rider)
		if not trace.Hit then
			rider:SetNWEntity("XMV_Vehicle", NULL)
			--drive.PlayerStopDriving(rider)
			--rider:SetObserverMode(OBS_MODE_NONE)
			--rider:UnSpectate()
			--self:GetDriver():SetParent()
			rider:SetMoveType(MOVETYPE_WALK)
			rider:SetActiveWeapon(self.BeforeActiveWeapon)
			
			
			for I=0,2 do
				rider:DrawViewModel(true, I)
			end
			local zone = nil
			if rider.GetZone then
				zone = rider:GetZone()
			end
			--rider:Spawn()
			rider:SetPos(self:GetPos()+Vector(0,0,20))
			if zone then
				rider:SetZone(zone)
			end
			timer.Simple(0, function()
				if IsValid(self) then
					UnstuckPlayer(rider, self:GetAngles())
				end
			end)
			--rider:GetViewModel():SetNoDraw(false)
			self:SetDriver(NULL)
			
			hook.Remove("Move", self)
			
			hook.Remove("KeyPress", self)
		else
			return
		end
	end
	if(ply and ply:IsValid() and (not ply:XMVGetVehicle() or not ply:XMVGetVehicle():IsValid())) then
		if ply:HasWeapon("popcorn_bucket") then
			ply:SelectWeapon("popcorn_bucket")
		end
		self:SetDriver(ply)
		ply.prepos = ply:GetPos()
		--ply:Spectate( OBS_MODE_CHASE )
		ply:SpectateEntity(self)
		ply:SetNWEntity("XMV_Vehicle", self)
		ply:SetMoveType(MOVETYPE_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		for I=0,2 do
			ply:DrawViewModel(false, I)
		end
		self.BeforeActiveWeapon = ply:GetActiveWeapon()
		ply:SetActiveWeapon(nil)
		--drive.PlayerStartDriving(ply, self, "drive_xmv")
		--ply:SetViewEntity(nil)
		--ply:SetParent(self)
		hook.Add("Move",self,function(self, ply, data)
			if(not self:GetDriver() or not self:GetDriver():IsValid()) then
				self:Remove()
			end
			if(ply == self:GetDriver()) then
				ply:SetActiveWeapon(nil)
				self:OnMove(ply, data)
				--[=[if ply:KeyDown(IN_ATTACK) then
					self:FireTurrets()
				end]=]
			end
		end)
		
		hook.Add("KeyPress",self,function(self,ply,key)
			if(not self:GetDriver() or not self:GetDriver():IsValid()) then
				self:Remove()
			elseif(ply == self:GetDriver() and key == IN_USE) then
				self:AssignPlayer()
			end
			if ply == self:GetDriver() then
				if key == IN_RELOAD then
					if self:GetViewMode() == 1 then
						self:GetDriver():ChatPrint"Third Person"
						self:SetViewMode(0)
					elseif self:GetViewMode() == 0 then
						self:GetDriver():ChatPrint"First Person"
						self:SetViewMode(1)
					end
				end
				self:OnKeyPress(ply, key)
			end
		end)
	end
	self.LastEnter = CurTime()
end
function ENT:OnRemove()
	if CLIENT then
		if self.TurretModels then
			for k,v in pairs(self.TurretModels) do v:Remove() end
		end
		return
	end
	self:AssignPlayer(nil, self:GetDriver())
end

if(CLIENT) then
	surface.CreateFont( "XMV_Player_Font", {
		font 		= "Default",
		size 		= 30,
		weight 		= 450,
		antialias 	= true,
		additive 	= false,
		shadow 		= false,
		outline 	= false
	} )
	function ENT:CreateModels()
		
	end
	
	function ENT:DrawPlayerName(vector, angle, scale)
		local pos,ang = LocalToWorld(vector, angle, self:GetPos(), self:GetAngles())
		
		self:DrawPlayerName2(pos, ang, scale)
	end
	function ENT:DrawPlayer(vector, angle, scale, ...)
		local pos,ang = LocalToWorld(vector, angle, self:GetPos(), self:GetAngles())
		self:DrawPlayer2(pos, ang, scale, ...)
	end
	
	function ENT:DrawTurret(num, vector, angle, scale)
		if not num then return end
		if not self.TurretModels then self.TurretModels = {} end
		if not self.TurretModels[num] then
			local turret = ClientsideModel("models/weapons/w_smg1.mdl", RENDERGROUP_OPAQUE)
			turret:SetNoDraw(true)
			self.TurretModels[num] = turret

			if type(scale) == "number" then
				scale = Vector(1, 1, 1) * scale
			end
			local mat = Matrix()
			mat:Scale(scale)
			self.TurretModels[num]:EnableMatrix("RenderMultiply", mat)
			self.TurretModels[num]:SetRenderOrigin(self:GetPos())
			self.TurretModels[num]:SetRenderAngles(self:GetAngles())
			self.TurretModels[num]:SetParent(self)
		end
		
		local function SetupModel(box, pos, ang)
			box:SetRenderOrigin(pos)
			box:SetRenderAngles(ang)
		end
		
		local pos, ang = LocalToWorld(vector, angle, self:GetPos(), self:GetAngles())
		SetupModel(self.TurretModels[num], pos, ang)
		self.TurretModels[num]:DrawModel()
	end
	
	function ENT:DrawPlayer2(vector, angle, scale, func)
		if not IsValid(self:GetDriver()) then return end
		local driver = self:GetDriver()
		if not self.PlayerModel then
			self.PlayerModel = ClientsideModel(driver:GetModel(), RENDERGROUP_OPAQUE)
			self.PlayerModel:SetNoDraw(true)
		end
		local mat = Matrix()
		mat:Scale(Vector(1, 1, 1) * scale)
		self.PlayerModel:SetModel(driver:GetModel())
		self.PlayerModel:EnableMatrix("RenderMultiply", mat)
		self.PlayerModel:SetRenderOrigin(vector)
		self.PlayerModel:SetRenderAngles(angle)
		self.PlayerModel:SetupBones()
		
		if func then
			func(self.PlayerModel)
		end
		
		self.PlayerModel:DrawModel()
	end
	
	function ENT:DrawPlayerName2(vector, angle, scale)
		local rider = self:GetDriver()
		local color = Color(255,0,0)
		local text = "No Driver"
		if(rider and rider:IsValid()) then
			color = team.GetColor(rider:Team())
			text = rider:Name() .. self:GetTurretCount()
		end
		cam.Start3D2D(vector, angle, scale)
			draw.DrawText(text, "XMV_Player_Font", 0, 0, color, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end
	function ENT:DrawTurrets()
		local turretCount = self:GetTurretCount()
		if turretCount > 0 then
			if self.TurretPositions then
				local maxn = table.maxn(self.TurretPositions)
				turretCount = math.Clamp(turretCount, 0, maxn)
				for I=1, turretCount do	
					local v = self.TurretPositions[I]
					self:DrawTurret(I, v[1], v[2], v[3])	
				end
			end
		end
	end	
	function ENT:Draw()
		self:DrawModel()
		self:DrawPlayer(Vector(0, 5, 9.0), Angle(0, 90, 0), 0.2, function(model)
			local seq = model:SelectWeightedSequence(ACT_DRIVE_JEEP)
			if model:GetSequence() ~= seq then
						model:ResetSequence(seq)
				end
		end)
		self:DrawPlayerName(Vector(0, 0, 12.5), Angle(), 0.2)
		self:DrawTurrets()
	end
	
	hook.Add("Think","XMV_CAR_Think",function()
		for k,v in pairs(player.GetAll()) do
			local car = v:XMVGetVehicle()
			if(car and car:IsValid()) then -- Assume they are in a car
				v:SetNoDraw(true)
				v.washidden = true
			elseif((not car or not car:IsValid()) and v.washidden) then
				v:SetNoDraw(false)
				v.washidden = false
			elseif((not car or not car:IsValid())) then
				v.washidden = false
			end
		end
	end)
	local CalcView_ThirdPerson = function( ply, view, dist, hullsize, entityfilter )
		local neworigin = view.origin - ply:EyeAngles():Forward() * dist
		if ( hullsize && hullsize > 0 ) then
			local tr = util.TraceHull( {
				start	= view.origin,
				endpos	= neworigin,
				mins	= Vector( hullsize, hullsize, hullsize ) * -1,
				maxs	= Vector( hullsize, hullsize, hullsize ),
				filter	= entityfilter
			})
			if ( tr.Hit ) then
				neworigin = tr.HitPos
			end

		end
		view.origin		= neworigin
		view.angles		= ply:EyeAngles()
	end
	
	hook.Add("CreateMove", "XMV_CreateMove", function(cmd)
		if LocalPlayer().XMVGetVehicle then
			local self = LocalPlayer():XMVGetVehicle()
			if(self and self:IsValid()) then -- Assume they are in a car
				
				if not self.CameraDistVel then
					self.CameraDist 	= 4
					self.CameraDistVel 	= 0.1
				end
				self.CameraDistVel = self.CameraDistVel + cmd:GetMouseWheel() * -0.5

				self.CameraDist = self.CameraDist + self.CameraDistVel * FrameTime()
				self.CameraDist = math.Clamp( self.CameraDist, 2, 6 )
				self.CameraDistVel = math.Approach( self.CameraDistVel, 0, self.CameraDistVel * FrameTime() * 2 )

				cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
				cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK2)))
				
				
				cmd:ClearMovement()
			end
		end
	end)
	
	hook.Add("CalcView", "XMV_CalcView", function(ply, pos, angles, fov)
		if ply.XMVGetVehicle then
			local car = ply:XMVGetVehicle()
			local view = {}
			if(car and car:IsValid() and car.GetViewMode) then -- Assume they are in a car
				if car:GetViewMode() == 1 then
					local pos, ang = LocalToWorld(Vector(0, 0, 2), (car.AngOffset or Angle(0,90,0)) * -1, car:GetPos(), car:GetAngles())
					view.origin = pos
					view.angles = ang
					view.fov = fov
					return view
				else
					view.origin = car:GetPos() + Vector(0, 0, 2)
					local idealdist = math.max( 10, car:BoundingRadius() ) * (car.CameraDist or 4)
					CalcView_ThirdPerson(ply, view, idealdist, 2, { car, car:GetDriver()} )

					view.angles.roll = 0
					return view
				end
			end
		end
	end)
	
	hook.Add("HUDShouldDraw", "XMV_HUDShouldDraw", function(name)
		if name ~= "CHudWeaponSelection" then return end
		if LocalPlayer().XMVGetVehicle then
			local self = LocalPlayer():XMVGetVehicle()
			if(self and self:IsValid()) then -- Assume they are in a car
				return false
			end
		end
	end)
	--[[hook.Add("ShouldDrawLocalPlayer","XMV_ShouldDrawLocalPlayer", function(ply)
		if LocalPlayer().XMVGetVehicle then
			local self = LocalPlayer():XMVGetVehicle()
			if(self and self:IsValid()) then -- Assume they are in a car
				return true
			end
		end
	end)]]
	function ENT:Think()
		if IsValid(self:GetDriver()) then
			local ply = self:GetDriver()
			ply:SetNetworkOrigin(self:GetPos() - ply:GetViewOffset() + Vector(0, 0, 5) )
		end
		self:NextThink(CurTime() + 0.01)
	end
else
	function ENT:FireTurrets() 
		local turrets = self:GetTurretCount()
		if turrets == 0 then return end
		if not self.NextShot then self.NextShot = CurTime() + 0.1 end

		if self.NextShot > CurTime() then return end

		self.NextShot = CurTime() + 0.5
		
		for I=1, turrets do
			if not self.TurretPositions[I] then return end
			-- Get the shot angles and stuff.
			local shootOrigin = self.TurretPositions[I][1] + self:GetVelocity() * engine.TickInterval()
			--debugoverlay.Sphere(shootOrigin, )
			local shootAngles = self.TurretPositions[I][2]
			local pos, ang = LocalToWorld(shootOrigin, shootAngles, self:GetPos(), self:GetAngles())
			-- Shoot a bullet
			local bullet = {}
			bullet.Num 			= 20
			bullet.Src 			= self:GetPos() + Vector(0, 0, 20)
			bullet.Dir 			= self:GetAngles():Forward()
			bullet.Force		= 10
			bullet.Damage		= 1
			bullet.Attacker 	= self:GetDriver()
			bullet.IgnoreEntity = {self, self:GetDriver()}
			self:FireBullets( bullet )
			
		end
	end
	
	function ENT:Think()
		if self:GetHealth() <= 0 and self:GetMaxHealth() ~= 0 and self:GetTurretCount() > 0 then
			--Temp Replace
			
			SafeRemoveEntity(self)
		end
	
		if (self:GetDriver() and self:GetDriver():IsValid() and not self:GetDriver():Alive()) then
			self:AssignPlayer()
		end
		if IsValid(self:GetDriver()) then
			local ply = self:GetDriver()
			ply:SetNetworkOrigin(self:GetPos() - ply:GetViewOffset() + Vector(0, 0, 5) )
		end
		self:NextThink(CurTime() + 0.01)
	end
	
	function ENT:StartTouch(entity)
		--[=[if entity:GetClass() == "gmod_turret" then
			SafeRemoveEntity(entity)
			if self:GetTurretCount() == 0 then
				self:SetHealth(self:GetMaxHealth())
			end
			self:SetTurretCount(self:GetTurretCount() + 1)
		end]=]
	end

	function ENT:Use(ply, call)
		if ply:IsPlayer()  and (not self:GetDriver() or not self:GetDriver():IsValid()) then
			if not self.LastEnter or CurTime() - self.LastEnter > 1 then
				self:AssignPlayer(ply)
			end
		end
	end
	hook.Add("PlayerSpawn","XMV_CAR_REMOVE",function(ply)
		local car = ply:XMVGetVehicle()
		if(car and car:IsValid()) then -- Assume they are in a car
			car:AssignPlayer()
		end
	end)
end
scripted_ents.Register(ENT, ENT.ClassName, true)

local PMETA = FindMetaTable"Player"

function PMETA:XMVGetVehicle()
	return self:GetNWEntity("XMV_Vehicle")
end

function PMETA:XMVInVehicle()
	return self:XMVGetVehicle() and self:XMVGetVehicle():IsValid()
end

function PMETA:XMVExitVehicle()
	if IsValid(self:XMVGetVehicle()) then self:XMVGetVehicle():AssignPlayer() end
end

hook.Add("PlayerSpawn", "XMVRespawnKick", function(ply)
	if ply:XMVInVehicle() then
		ply:XMVExitVehicle()
	end
end)
