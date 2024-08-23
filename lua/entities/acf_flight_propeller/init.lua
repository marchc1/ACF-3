AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
local ACF = ACF

local Contraption	= ACF.Contraption
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local HookRun		= hook.Run
local Entities	    = Classes.Entities
local Flight	    = Classes.Flight

do
	local function VerifyData(Data)
		hook.Run("ACF_VerifyData", "acf_flight_propeller", Data)
	end

	local function UpdatePropeller(Entity, Data)
		Entity.ACF = Entity.ACF or {}

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		ACF.Activate(Entity, true)
	end

	function MakeACF_Propeller(Player, Pos, Angle, Data)
		if not Player:CheckLimit("_acf_flight_propeller") then return end

		VerifyData(Data)

		local Source = Classes.Flight
		local Class = Classes.GetGroup(Source, "1-Propeller")
		local Propeller = Class.Lookup[Data.Propeller]

		local CanSpawn = hook.Run("ACF_PreEntitySpawn", "acf_flight_propeller", Player, Data, Class, Propeller)
		if CanSpawn == false then return false end

		local Prop = ents.Create("acf_flight_propeller")

		if not IsValid(Prop) then return end
		Prop:SetAngles(Angle)
		Prop:SetPos(Pos)

		Prop:SetScaledModel(Propeller.Model)
		Prop:SetMaterial("sprops/sprops_grid_12x12")
		Prop:SetPlayer(Player)
		Prop:Spawn()

		Player:AddCount("_acf_flight_propeller", Prop)
		Player:AddCleanup("_acf_flight_propeller", Prop)

		Prop.Owner = Player -- MUST be stored on ent for PP
		Prop.DataStore = Entities.GetArguments("acf_flight_propeller")

		UpdatePropeller(Prop, Data)
		hook.Run("ACF_OnEntitySpawn", "acf_flight_propeller", Prop, Data)

		do
			local EntMods = Data.EntityMods
			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Prop
	end

	Entities.Register("acf_flight_propeller", MakeACF_Propeller)

	------------------- Updating ---------------------
	function ENT:Update(Data)
		VerifyData(Data)
		hook.Run("ACF_OnEntityLast", "acf_flight_propeller", self)
		ACF.SaveEntity(self)
		UpdatePropeller(self, Data)
		ACF.RestoreEntity(self)
		hook.Run("ACF_OnEntityUpdate", "acf_flight_propeller", self, Data)
		net.Start("ACF_UpdateEntity")
		net.WriteEntity(self)
		net.Broadcast()
		return true, "Propeller updated successfully!"
	end
end

function ENT:OnRemove()
	WireLib.Remove(self)
end