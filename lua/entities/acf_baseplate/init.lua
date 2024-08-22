AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local ACF = ACF
local baseplate_minWidth = 36
local baseplate_maxWidth = 96
local baseplate_minLength = 36
local baseplate_maxLength = 480
local baseplate_minThickness = 1
local baseplate_maxThickness = 3
do
	-- Spawning and Updating
	local Classes = ACF.Classes
	local Entities = Classes.Entities
	local function VerifyData(Data)
		do
			-- Verifying dimension values
			if not isnumber(Data.Width) then Data.Width = ACF.CheckNumber(Data.PlateSizeX, 36) end
			if not isnumber(Data.Length) then Data.Length = ACF.CheckNumber(Data.PlateSizeY, 36) end
			if not isnumber(Data.Thickness) then Data.Thickness = ACF.CheckNumber(Data.PlateSizeZ, 3) end
			Data.Width = math.Clamp(Data.Width, baseplate_minWidth, baseplate_maxWidth)
			Data.Length = math.Clamp(Data.Length, baseplate_minLength, baseplate_maxLength)
			Data.Thickness = math.Clamp(Data.Thickness, baseplate_minThickness, baseplate_maxThickness)
			Data.Size = Vector(Data.Length, Data.Width, Data.Thickness)
		end

		do
			-- External verifications
			hook.Run("ACF_VerifyData", "acf_baseplate", Data, Baseplate)
		end
	end

	local function UpdatePlate(Entity, Data)
		Entity.ACF = Entity.ACF or {}
		local Size = Data.Size
		Entity:SetSize(Size)
		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		ACF.Activate(Entity, true)
	end

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

	function MakeACF_Baseplate(Player, Pos, PAngle, Data)
		if not Player:CheckLimit("_acf_baseplate") then return end

		local CanSpawn = hook.Run("ACF_PreEntitySpawn", "acf_baseplate", Player, Data)
		if CanSpawn == false then return false end
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

			-- This makes me want to blow my head off
			local _dtf = realBP.DropToFloor
			timer.Simple(0.0001, function() realBP:SetPos(bp.Pos) end)

			return realBP
		end

		local Plate = ents.Create("acf_baseplate")
		VerifyData(Data)

		if not IsValid(Plate) then return end
		Plate:SetAngles(PAngle)
		Plate:SetPos(Pos)

		Plate:SetScaledModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/sprops_grid_12x12")
		Plate:SetPlayer(Player)
		Plate:Spawn()

		Player:AddCount("_acf_baseplate", Plate)
		Player:AddCleanup("_acf_baseplate", Plate)

		Plate.Owner = Player -- MUST be stored on ent for PP
		Plate.DataStore = Entities.GetArguments("acf_baseplate")
		do
			local EntMods = Data.EntityMods
			if EntMods and EntMods.mass then
				Plate:GetPhysicsObject():SetMass(EntMods.mass.Mass)
			end
		end
		UpdatePlate(Plate, Data)
		hook.Run("ACF_OnEntitySpawn", "acf_baseplate", Plate, Data)

		return Plate
	end

	Entities.Register("acf_baseplate", MakeACF_Baseplate, "Width", "Length", "Thickness")
	------------------- Updating ---------------------
	function ENT:Update(Data)
		VerifyData(Data)
		hook.Run("ACF_OnEntityLast", "acf_baseplate", self)
		ACF.SaveEntity(self)
		UpdatePlate(self, Data)
		ACF.RestoreEntity(self)
		hook.Run("ACF_OnEntityUpdate", "acf_baseplate", self, Data)
		net.Start("ACF_UpdateEntity")
		net.WriteEntity(self)
		net.Broadcast()
		return true, "Baseplate updated successfully!"
	end
end

function ENT:OnRemove()
	WireLib.Remove(self)
end