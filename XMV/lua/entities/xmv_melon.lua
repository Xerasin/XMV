if(SERVER) then AddCSLuaFile() end
ENT = {}
ENT.Type = "anim"
ENT.Base = "xmv_base"
ENT.ClassName = "xmv_melon"
ENT.PrintName = "Melon"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
function ENT:Initialize()
    if(SERVER) then
		self:SetModel("models/props_junk/watermelon01.mdl")
		
		self:DrawShadow(false)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(10)
		end
		self:PhysWake()
		self:SetUseType(SIMPLE_USE)
    end
	self.AngOffset = Angle(0, 0, 0)
end
function ENT:AreWheelsTouching()
	local normal = Vector(0, 0, -1)
	local trace = util.QuickTrace(self:GetPos(),normal * 200,{self})
	return trace, trace.StartPos:Distance(trace.HitPos) <= 10
end
function ENT:SetupDataTables2()

end
function ENT:OnMove(ply, data)
	local phys = self:GetPhysicsObject()
	if(phys and phys:IsValid()) then
		local eye = ply:GetAimVector()
		local eye_r = (ply:EyeAngles() + Angle(0, 90, 0)):Forward()
		local up = self:GetUp()
		local forward = self:GetForward()
		local forward_sign = 0
		local side_sign = 0
		if ply:KeyDown(IN_FORWARD) then
			forward_sign = forward_sign + 2
		end
		if ply:KeyDown(IN_BACK) then
			forward_sign = forward_sign - 2
		end
		if ply:KeyDown(IN_MOVELEFT) then
			side_sign = side_sign + 2
		end
		if ply:KeyDown(IN_MOVERIGHT) then
			side_sign = side_sign - 2
		end
		if ply:KeyDown(IN_SPEED) then
			forward_sign = forward_sign * 2
			side_sign = side_sign * 2
		end
		if(ply:KeyDown(IN_JUMP) and (not self.lastjump or RealTime() - self.lastjump > 1) ) then
			local trace, hit = self:AreWheelsTouching()
			if hit then
				phys:AddVelocity(Vector(0, 0, 1) * phys:GetMass() * 20)
				self.lastjump = RealTime()
			end
		end
		if forward_sign ~= 0 then
			phys:ApplyForceOffset(eye * phys:GetMass() * forward_sign, self:GetPos() + Vector(0, 0, 10))
		end
		if side_sign ~= 0 then
			phys:ApplyForceOffset(eye_r * phys:GetMass() * side_sign, self:GetPos() + Vector(0, 0, 10))
		end
	end
end

if(CLIENT) then
	function ENT:Draw()
		self:DrawModel()
		self:DrawPlayerName(Vector(0, 0, 8), Angle(0, 90, 0), 0.2)
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
end
scripted_ents.Register(ENT, ENT.ClassName, true)
	
list.Set('SpawnableEntities',ENT.ClassName,{["PrintName"] = ENT.PrintName, ["ClassName"] = ENT.ClassName, ["Spawnable"] = ENT.Spawnable, ["Category"] = "Xerasin's Micro Vehicles"})
