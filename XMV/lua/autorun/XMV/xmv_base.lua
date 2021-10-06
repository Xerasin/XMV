if SERVER then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.ClassName = "xmv_base"
ENT.PrintName = "Base XMV"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Controls = {}
function ENT:Initialize()
	if SERVER then
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
	self.AngOffset = Angle(0,90,0)
end

-- todo: whitelist/blacklist
function ENT:CanProperty()
	return false
end

function ENT:StartTouch(ent)
	if IsValid(ent) and ent:GetClass() == "trigger_teleport" then
		SafeRemoveEntity(self)
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Driver")
	self:NetworkVar( "Int", 14, "ViewMode")
	self:SetupDataTables2()
end

function ENT:SetupDataTables2()
end

function ENT:OnMove(ply, data)
end

function ENT:OnKeyPress(ply, key)
end

function ENT:AssignPlayer(ply, driver)
	local rider = driver or self:GetDriver()
	if self:GetDriver() and self:GetDriver():IsValid() then
		local out_pos = self:GetPos() + Vector(0,0,20)
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

			rider:SetParent(NULL)

			for I = 0, 2 do
				rider:DrawViewModel(true, I)
			end
			local zone = nil
			if rider.GetZone then
				zone = rider:GetZone()
			end

			--rider:Spawn()
			rider:SetPos(self:GetPos() + Vector(0,0,20))
			if zone then
				rider:SetZone(zone)
			end

			timer.Simple(0, function()
				xmv.UnstuckPlayer(rider)
			end)
			--rider:GetViewModel():SetNoDraw(false)
			self:SetDriver(NULL)

			hook.Remove("Move", self)
			hook.Remove("KeyPress", self)
		else
			return
		end
	end
	if ply and ply:IsValid() and (not ply:XMVGetVehicle() or not ply:XMVGetVehicle():IsValid()) then
		if ply:HasWeapon("popcorn_bucket") then
			ply:SelectWeapon("popcorn_bucket")
		end
		self:SetDriver(ply)
		ply.prepos = ply:GetPos()
		--ply:Spectate( OBS_MODE_CHASE )
		ply:SpectateEntity(self)
		ply:SetNWEntity("XMV_Vehicle", self)
		ply:SetMoveType(MOVETYPE_NOCLIP)

		for I = 0,2 do
			ply:DrawViewModel(false, I)
		end

		self.BeforeActiveWeapon = ply:GetActiveWeapon()
		ply:SetActiveWeapon(nil)

		hook.Add("Move",self,function(_, oPly, data)
			if not self:GetDriver() or not self:GetDriver():IsValid() then
				self:Remove()
			end

			if oPly == self:GetDriver() then
				oPly:SetActiveWeapon(nil)
				self:OnMove(oPly, data)
			end
		end)

		local honkable = {
			["func_door_rotating"] = true,
			["prop_door_rotating"] = true,
			["func_door"] = true,
			["prop_testchamber_door"] = true,
		}
		hook.Add("KeyPress", self, function(_, oPly, key)
			if not self:GetDriver() or not self:GetDriver():IsValid() then
				self:Remove()
			elseif oPly == self:GetDriver() and key == IN_USE then
				self:AssignPlayer()
			end
			if oPly == self:GetDriver() then
				if key == IN_RELOAD then
					if self:GetViewMode() == 1 then
						self:GetDriver():ChatPrint"Third Person"
						self:SetViewMode(0)
					elseif self:GetViewMode() == 0 then
						self:GetDriver():ChatPrint"First Person"
						self:SetViewMode(1)
					end
				end

				if key == IN_ATTACK2 and (not self.nexthonk or self.nexthonk < RealTime()) then
					sound.Play(self.HonkSound or "ambient/alarms/klaxon1.wav", self:GetPos(), 75, 200)
					self.nexthonk = RealTime() + 5

					local dir = Angle(0, self:GetAngles().y, 0)
					if self.Forward then dir.y = dir.y + self.Forward end

					local trace = util.QuickTrace(self:GetPos() + Vector(0, 0, 10), dir:Forward() * 50, {self, self:GetDriver()})
					if trace.Hit and not trace.HitWorld and IsValid(trace.Entity) and honkable[trace.Entity:GetClass()] then
						local ent = trace.Entity
						ent:Use(self:GetDriver(), self, USE_ON, 1)
					end
				end
				self:OnKeyPress(oPly, key)
			end
		end)
	end
	self.LastEnter = CurTime()
end







local createTypes = {
	["Prop"] = function(prop)
		prop.Entity = ClientsideModel(prop.Model, RENDERGROUP_OPAQUE)
		prop.Entity:SetNoDraw(true)

		local mat = Matrix()
		mat:Scale(prop.Scale)
		prop.Entity:EnableMatrix("RenderMultiply", mat)

		if prop.Color then prop.Entity:SetColor(prop.Color) end
	end,
	["Mesh"] = function(prop)
		if not prop.Mesh then return end
		prop.MeshObject = Mesh()
		prop.MeshObject:BuildFromTriangles(prop.Mesh)
	end,
	["Player"] = function(prop)
		prop.Entity = ClientsideModel("models/player/skeleton.mdl", RENDERGROUP_OPAQUE)
		prop.Entity:SetNoDraw(true)
	end,
	["PlayerName"] = function() end,
}

local tickTypes = {
	["Rotate"] = function(curProp)
		curProp.Ang = curProp.SpawnAng + curProp.RotateAng * CurTime()
	end
}



local function _BaseSteer(prop, vehicle)
	local newAng
	if not prop.LastAng then prop.LastAng = vehicle:GetAngles() end
	if prop.LastAng then
		local tang = math.floor((prop.LastAng.Y - vehicle:GetAngles().Y) * 100) / 100
		if tang == 0 then
			newAng = 0
		else
			newAng = math.Clamp(tang, -5, 5) * 3
		end
		prop.LastAng = vehicle:GetAngles()
	end

	if newAng then
		if not vehicle.Steer then
			prop.SteerAng = newAng
		end

		prop.SteerAng = prop.SteerAng + (newAng - prop.SteerAng) * 0.05
		return prop.SteerAng
	end

	return 1
end
local drawTypes = {
	["Prop"] = function(prop, modelPos, modelAng)
		if not prop.Entity or not IsValid(prop.Entity) then return end
		local mat = Matrix()
		mat:Scale(prop.Scale)
		prop.Entity:EnableMatrix("RenderMultiply", mat)

		local propPos, propAng = LocalToWorld(prop.Pos, prop.Ang, modelPos, modelAng)

		if prop.Material then
			prop.Entity:SetMaterial(prop.Material)
		end

		if prop.Color then
			render.SetColorModulation(prop.Color.r / 255, prop.Color.g / 255, prop.Color.b / 255)
			prop.Entity:SetColor(prop.Color)
		end

		prop.Entity:SetNoDraw(true)
		prop.Entity:SetPos(propPos)
		prop.Entity:SetAngles(propAng)
		prop.Entity:SetRenderOrigin(propPos)
		prop.Entity:SetRenderAngles(propAng)

		prop.Entity:DrawModel()
	end,
	["Mesh"] = function(prop, modelPos, modelAng)
		if not prop.MeshObject then return end

		local propPos, propAng = LocalToWorld(prop.Pos, prop.Ang, modelPos, modelAng)

		if prop.Color then
			render.SetColorModulation(prop.Color.r / 255, prop.Color.g / 255, prop.Color.b / 255)
			render.SetBlend(prop.Color.a / 255)
		end
		if prop.Material then
			render.SetMaterial(prop.Material)
		end
		render.OverrideDepthEnable( true, true )
			local mat = Matrix()
			mat:Translate(propPos)
			mat:Rotate(propAng)
			cam.PushModelMatrix( mat )
				prop.MeshObject:Draw()
			cam.PopModelMatrix()
		render.OverrideDepthEnable( false, false )
	end,
	["Player"] = function(prop, modelPos, modelAng, vehicle)
		if not prop.Entity or not IsValid(prop.Entity) then return end
		if not IsValid(vehicle:GetDriver()) then return end

		local mat = Matrix()
		mat:Scale(prop.Scale)
		prop.Entity:EnableMatrix("RenderMultiply", mat)

		local propPos, propAng = LocalToWorld(prop.Pos, prop.Ang, modelPos, modelAng)

		if prop.Material then
			prop.Entity:SetMaterial(prop.Material)
		end

		if prop.Color then
			render.SetColorModulation(prop.Color.r / 255, prop.Color.g / 255, prop.Color.b / 255)
			prop.Entity:SetColor(prop.Color)
		end

		propPos, propAng = LocalToWorld(prop.Pos, prop.Ang, modelPos, modelAng)
		prop.Entity:SetModel(vehicle:GetDriver():GetModel())
		prop.Entity:EnableMatrix("RenderMultiply", mat)
		prop.Entity:SetRenderOrigin(propPos)
		prop.Entity:SetRenderAngles(propAng)
		prop.Entity:SetupBones()

		local seq = prop.Entity:SelectWeightedSequence(ACT_DRIVE_JEEP)
		if prop.Entity:GetSequence() ~= seq then
			prop.Entity:ResetSequence(seq)
		end

		prop.Entity:SetPoseParameter( "vehicle_steer", prop.Steer and prop:Steer(vehicle) or _BaseSteer(prop, vehicle))


		prop.Entity:DrawModel()
	end,
	["PlayerName"] = function(prop, modelPos, modelAng, vehicle)
		local rider = vehicle:GetDriver()
		local color = Color(255, 0, 0)
		local text = "No Driver"
		if rider and rider:IsValid() then
			color = team.GetColor(rider:Team())
			text = rider:Name()
		end

		local propPos, propAng = LocalToWorld(prop.Pos, prop.Ang, modelPos, modelAng)
		cam.Start3D2D(propPos, propAng, prop.Scale)
			draw.DrawText(text, "XMV_Player_Font", 0, 0, color, TEXT_ALIGN_CENTER )
		cam.End3D2D()
	end,
}

local removeType = {
	["Prop"] = function(prop)
		if not IsValid(prop.Entity) then return end
		SafeRemoveEntity(prop.Entity)
	end,
	["Mesh"] = function(prop)
		if not prop.MeshObject then return end
		prop.MeshObject:Destroy()
		prop.MeshObject = nil
	end,
	["Player"] = function(prop)
		if not IsValid(prop.Entity) then return end
		SafeRemoveEntity(prop.Entity)
	end,
	["PlayerName"] = function() end,
}

function ENT:CreateXMVModels()
	if SERVER then return end
	if self.Models then
		for _, model in pairs(self.Models) do
			for _, prop in pairs(model) do
				if type(prop) == "table" then
					if createTypes[prop.Type] then
						createTypes[prop.Type](prop)
					end

					prop.SpawnPos = prop.Pos
					prop.SpawnAng = prop.Ang

					if prop.TickType and tickTypes[prop.TickType] then
						prop.Tick = tickTypes[prop.TickType]
					end
				end
			end

			model.SpawnPos = model.Pos
			model.SpawnAng = model.Ang

			if model.TickType and tickTypes[model.TickType] then
				model.Tick = tickTypes[model.TickType]
			end

			model.Created = true
		end
	end
end

function ENT:TickModels()
	if SERVER then return end
	if self.Models then
		for _, model in pairs(self.Models) do
			if model.Tick then model:Tick(self) end
			for _, prop in ipairs(model) do
				if prop.Tick then prop:Tick(self) end
			end
		end
	end
end

function ENT:DrawModels()
	if SERVER then return end
	if self.Models then
		for _, model in pairs(self.Models) do
			local modelPos, modelAng = LocalToWorld(model.Pos, model.Ang, self:GetPos(), self:GetAngles())
			if not model.ManualDraw then
				for _, prop in ipairs(model) do
					if not prop.ManualDraw and type(prop) == "table" and drawTypes[prop.Type] then
						drawTypes[prop.Type](prop, modelPos, modelAng, self)
					end
				end
			end
		end
	end

	render.SetColorModulation(1, 1, 1)
	render.SetBlend(1)
end


function ENT:OnRemove()
	if CLIENT then
		if self.Models then
			for _, model in pairs(self.Models) do
				for _, prop in pairs(model) do
					if type(prop) == "table" and removeType[prop.Type] then
						removeType[prop.Type](prop)
					end
				end
			end
		end
		return
	end
	self:AssignPlayer(nil, self:GetDriver())
end

if CLIENT then
	surface.CreateFont( "XMV_Player_Font", {
		font 		= "Default",
		size 		= 30,
		weight 		= 450,
		antialias 	= true,
		additive 	= false,
		shadow 		= false,
		outline 	= false
	} )

	function ENT:Draw()
		self:DrawModel()
	end

	hook.Add("Think","XMV_CAR_Think",function()
		for k,v in pairs(player.GetAll()) do
			local car = v:XMVGetVehicle()
			if car and car:IsValid()  then -- Assume they are in a car
				v:SetNoDraw(true)
				v.washidden = true
			elseif (not car or not car:IsValid()) and v.washidden then
				v:SetNoDraw(false)
				v.washidden = false
			elseif (not car or not car:IsValid()) then
				v.washidden = false
			end
		end
	end)
	local CalcView_ThirdPerson = function( ply, view, dist, hullsize, entityfilter )
		local neworigin = view.origin - ply:EyeAngles():Forward() * dist
		if hullsize and hullsize > 0 then
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
			local xmvVeh = LocalPlayer():XMVGetVehicle()
			if xmvVeh and xmvVeh:IsValid()  then -- Assume they are in a car
				if not xmvVeh.CameraDistVel then
					xmvVeh.CameraDist 	= 4
					xmvVeh.CameraDistVel 	= 0.1
				end
				xmvVeh.CameraDistVel = xmvVeh.CameraDistVel + cmd:GetMouseWheel() * -0.5

				xmvVeh.CameraDist = xmvVeh.CameraDist + xmvVeh.CameraDistVel * FrameTime()
				xmvVeh.CameraDist = math.Clamp( xmvVeh.CameraDist, 2, 6 )
				xmvVeh.CameraDistVel = math.Approach( xmvVeh.CameraDistVel, 0, xmvVeh.CameraDistVel * FrameTime() * 2 )

				--[[cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
				cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK2)))]]

				cmd:ClearMovement()
			end
		end
	end)

	hook.Add("CalcView", "XMV_CalcView", function(ply, pos, angles, fov)
		if ply.XMVGetVehicle then
			local car = ply:XMVGetVehicle()
			local view = {}
			if car and car:IsValid() and car.GetViewMode then -- Assume they are in a car
				if car:GetViewMode() == 1 then
					local newPos, ang = LocalToWorld(Vector(0, 0, 2), (car.AngOffset or Angle(0,90,0)) * -1, car:GetPos(), car:GetAngles())
					view.origin = newPos
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
			local xmvVeh = LocalPlayer():XMVGetVehicle()
			if xmvVeh and xmvVeh:IsValid() then -- Assume they are in a car
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

		self:TickModels()
		if self.CThink then self:CThink() end
	end
	local binds = {
		[IN_ATTACK] = "+attack",
		[IN_ATTACK2] = "+attack2",
		[IN_USE] = "+use",
		[IN_WALK] = "+walk",
		[IN_SPEED] = "+speed",
		[IN_DUCK] = "+duck",
		[IN_RELOAD] = "+reload",
		[IN_JUMP] = "+jump",
		[IN_FORWARD] = "+forward",
		[IN_BACK] = "+back",
		[IN_LEFT] = "+left",
		[IN_RIGHT] = "+right",
		[IN_MOVELEFT] = "+moveleft",
		[IN_MOVERIGHT] = "+moveright"
	}

	local function getControlText(control)
		local bindName = binds[control]
		if bindName then
			local key = input.LookupBinding(bindName, false)
			local keyName = ""


			if key then
				keyName = language.GetPhrase(key)
			else
				keyName = ("<%s is not bound!>"):format(bindName)
			end

			return string.sub(keyName, 1, 1):upper() .. string.sub(keyName, 2):lower()
		end
		return "???"
	end

	function ENT:DrawControls()
		if not self.Controls then return end
		local y = 0
		for _, control in pairs(self.Controls) do
			if type(control) == "string" then
				draw.DrawText(control, "TargetID", 0, ScrH() * 0.25 + y, Color(255,255,255,255), TEXT_ALIGN_LEFT)
			end

			if type(control) == "table" and control.Key then
				local inputKey = control.Key
				draw.DrawText(("%s - %s"):format(getControlText(inputKey), control.Name), "TargetID", 0, ScrH() * 0.25 + y, Color(255,255,255,255), TEXT_ALIGN_LEFT)
			end

			y = y + 15
		end

		render.SetColorModulation(1, 1, 1)
		render.SetBlend(1)
	end

	hook.Add("HUDPaint", "XMVDrawHUD", function()
		local car = LocalPlayer():XMVGetVehicle()
		if car and car:IsValid() and car.DrawControls then
			car:DrawControls()
		end
	end)
else
	function ENT:Think()
		if self:GetDriver() and self:GetDriver():IsValid() and not self:GetDriver():Alive() then
			self:AssignPlayer()
		end

		if IsValid(self:GetDriver()) then
			local ply = self:GetDriver()
			if ply:GetPos():Distance(self:GetPos()) > 150 then
				ply:SetPos(self:GetPos())
			end
			ply:SetNetworkOrigin(self:GetPos() - ply:GetViewOffset() + Vector(0, 0, 5) )
		end
		if self.CThink then self:CThink() end
	end

	function ENT:Use(ply, call)
		if ply:IsPlayer() and not IsValid(self:GetDriver()) and (not self.LastEnter or CurTime() - self.LastEnter > 1) then
			self:AssignPlayer(ply)
		end
	end

	hook.Add("PlayerSpawn","XMV_CAR_REMOVE",function(ply)
		local car = ply:XMVGetVehicle()
		if car and car:IsValid() then -- Assume they are in a car
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


local function Deny(ply, ent)
	if IsValid(ent) and ply:XMVGetVehicle() == ent then
		return false
	end
end

hook.Add("AllowPlayerPickup", "XMVAllowPlayerPickup", Deny)
hook.Add("GravGunPickupAllowed", "XMVOnPhysgunPickup", Deny)
hook.Add("PhysgunPickup", "XMVPhysgunPickup", function(ply, ent)
	if IsValid(ent) and ent:IsPlayer() and IsValid(ent:XMVGetVehicle()) then
		return false
	end
end)


