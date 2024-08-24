AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local ACF = ACF

-- ONLY for baseplates specifically
local RecursiveEntityRemove
function RecursiveEntityRemove(ent, track)
	track = track or {}
	if track[ent] == true then return end
	local constrained = constraint.GetAllConstrainedEntities(ent)
	ent:Remove()
	track[ent] = true
	for k, _ in pairs(constrained) do
		if k ~= ent then RecursiveEntityRemove(k, track) end
	end
end

-- Spawning and Updating
local Classes = ACF.Classes
local Entities = Classes.Entities

function ENT.ACF_VerifyPlayerData(Data)
	Data.Size = Vector(Data.Length, Data.Width, Data.Thickness)
end

function ENT:ACF_Update(Data)
	local Size = Data.Size
	self:SetSize(Size)
end

function ENT.ACF_Spawn(Player, Pos, PAngle, Data)
	if Player:KeyDown(IN_SPEED) and not AdvDupe2.SpawningEntity then
		local lookEnt = Player:GetEyeTrace().Entity -- What entity are they looking at
		if not IsValid(lookEnt) then return end

		local Owner = lookEnt:CPPIGetOwner()
		if not IsValid(Owner) or Owner ~= Player then return end

		local physObj = lookEnt:GetPhysicsObject()
		if not IsValid(physObj) then return end

		local aMi, aMa = physObj:GetAABB()
		local boxSize = aMa - aMi
		-- Duplicate the entire thing
		local entities, constraints = AdvDupe2.duplicator.Copy(Player, lookEnt, {}, {}, Vector(0, 0, 0))
		-- Find the baseplate
		local bp = entities[lookEnt:EntIndex()]
		-- Setup the dupe table to convert it to a baseplate
		local w, l, t = boxSize.y, boxSize.x, boxSize.z
		bp.Class = "acf_baseplate"
		bp.Width = w
		bp.Length = l
		bp.Thickness = t

		-- Delete everything now
		for k, _ in pairs(entities) do
			local e = Entity(k)
			if IsValid(e) then e:Remove() end
		end

		-- Paste the stuff back to the dupe
		local ents = AdvDupe2.duplicator.Paste(Player, entities, constraints, Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), true)
		-- Try to find the baseplate
		local realBP
		for _, v in pairs(ents) do
			if v:GetClass() == "acf_baseplate" and v:GetPos() == bp.Pos then
				realBP = v
				break
			end
		end

		undo.Create("acf_baseplate")
		undo.AddEntity(realBP)
		undo.SetPlayer(Player)
		undo.Finish()
		ACF.DoNotDropEntity(realBP)
		return realBP
	end

	local Plate = ents.Create("acf_baseplate")
	if not IsValid(Plate) then return end

	Plate.ACF_VerifyPlayerData(Data)

	Plate:SetPos(Pos)
	Plate:SetAngles(PAngle)
	Plate:SetScaledModel("models/holograms/cube.mdl")
	Plate:SetMaterial("sprops/sprops_grid_12x12")

	Plate:ACF_SpawnAndAssignTo(Player)
	do
		local EntMods = Data.EntityMods
		if EntMods and EntMods.mass then Plate:GetPhysicsObject():SetMass(EntMods.mass.Mass) end
	end
	Plate:ACF_Update(Data)
	return Plate
end

ENT.ACF_DataKeys = {
	["Width"]     = {Type = "Float", Min = 36, Max = 96,  Default = 36, Decimals = 2},
	["Length"]    = {Type = "Float", Min = 36, Max = 480, Default = 36, Decimals = 2},
	["Thickness"] = {Type = "Float", Min = 1,  Max = 3,   Default = 3,  Decimals = 2}
}

function ENT:OnRemove()
	WireLib.Remove(self)
end

Entities.Register()