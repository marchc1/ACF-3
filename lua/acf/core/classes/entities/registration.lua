--[[
The purpose of this class is to define a class that represents an entity, storing its spawn function as well as registering the arguments attached to the entity with duplicators.
--]]

local duplicator = duplicator
local isfunction = isfunction
local isstring   = isstring
local istable    = istable
local unpack     = unpack
local Classes    = ACF.Classes
local Entities   = Classes.Entities
local Entries    = {}

--- Gets the entity table of a certain class
--- If an entity table doesn't exist for the class, it will register one.
--- @param Class table The class to get the entity table from
--- @return {Lookup:table, Count:number, List:table} # The entity table of this class
local function GetEntityTable(Class)
	local Data = Entries[Class]

	if not Data then
		Data = {
			Lookup = {},
			Count  = 0,
			List   = {},
		}

		Entries[Class] = Data
	end

	return Data
end

--- Adds arguments to an entity for storage in duplicators
--- The Entity.Lookup, Entity.Count and Entity.List variables allow us to iterate over this information in different ways. 
--- @param Entity entity The entity to add arguments to
--- @param Arguments any[] # An array of arguments to attach to the entity (usually {...})
--- @return any[] # An array of arguments attached to the entity
local function AddArguments(Entity, Arguments)
	local Lookup = Entity.Lookup
	local Count  = Entity.Count
	local List   = Entity.List

	for _, V in ipairs(Arguments) do
		if Lookup[V] then continue end

		Count = Count + 1

		Lookup[V]   = true
		List[Count] = V
	end

	Entity.Count = Count

	return List
end

local TypeVerifiers = {
	Float = function(Value, Specs)
		if not isnumber(Value) then Value = ACF.CheckNumber(Value, Specs.Default or 0) end

		Value = math.Round(Value, Specs.Decimals or 3)
		Value = math.max(Value, Specs.Min)
		Value = math.min(Value, Specs.Max)
		return Value
	end
}

--- Registers a class as a spawnable entity class. 
--- When no arguments are provided, and as long as this is being called from a scripted entity init.lua file, the arguments will be auto-filled in.
--- @param Class string The class to register
--- @param Function fun(Player:entity, Pos:vector, Ang:angle, Data:table):Entity A function defining how to spawn your class (This should be your MakeACF_<something> function)
--- @param ... any #A vararg of arguments to attach to the entity
function Entities.Register(Class, Function, ...)
	local Arguments
	if Class == nil and Function == nil then
		-- Because this is called in an entity init.lua, ENT should be available
		if ENT == nil then ErrorNoHaltWithStack("Entities.Register was passed with no arguments and no active ENT table.") return end
		if ENT.ACF_Spawn == nil then ErrorNoHaltWithStack("Entities.Register was passed before ENT.ACF_Spawn was defined.") return end
		-- We autofill from the ENT table
		Class = string.Replace(ENT.Folder, "entities/")

		-- The boilerplate code for spawning entities (hooks, limit checks) get ran; then call ACF_Spawn
		local ACF_Spawn = ENT.ACF_Spawn
		Function = function(Player, Pos, Angle, Data)
			if not Player:CheckLimit("_" .. Class) then return false end

			local CanSpawn = hook.Run("ACF_PreEntitySpawn", Class, Player, Data)
			if CanSpawn == false then return false end

			local Ent = ACF_Spawn(Player, Pos, Angle, Data)
			if not IsValid(Ent) then return end
			hook.Run("ACF_OnEntitySpawn", Class, Ent, Data)

			return Ent
		end

		-- Boilerplate code for spawning and assigning the entity to a player
		function ENT:ACF_SpawnAndAssignTo(Player)
			self:SetPlayer(Player)
			self:Spawn(self)
			Player:AddCount("_" .. Class, self)
			Player:AddCleanup("_" .. Class, self)

			self.Owner = Player -- MUST be stored on ent for PP
			self.DataStore = Entities.GetArguments(Class)
		end

		if ENT.ACF_DataKeys then
			local ACF_DataKeys = ENT.ACF_DataKeys
			Arguments = table.GetKeys(ACF_DataKeys)
			local update_func = ENT.ACF_Update
			local verify_func = ENT.ACF_VerifyPlayerData

			-- Define functions
			function ENT.ACF_VerifyPlayerData(Data)
				for k, v in pairs(ACF_DataKeys) do
					local verifier = TypeVerifiers[v.Type]
					if verifier then
						Data[k] = verifier(Data[k], v)
					end
				end

				if verify_func then verify_func(Data) end
				hook.Run("ACF_VerifyData", Class, Data, Baseplate)
			end
			function ENT:ACF_Update(Data)
				self.ACF = self.ACF or {}

				-- Storing all the relevant information on the entity for duping
				for _, V in ipairs(Arguments) do
					self[V] = Data[V]
				end

				update_func(self, Data)

				ACF.Activate(self, true)
			end
			function ENT:Update(Data)
				self.ACF_VerifyPlayerData(Data)
				hook.Run("ACF_OnEntityLast", Class, self)

				ACF.SaveEntity(self)
				self:ACF_Update(Data)
				ACF.RestoreEntity(self)

				hook.Run("ACF_OnEntityUpdate", Class, self, Data)

				net.Start("ACF_UpdateEntity")
				net.WriteEntity(self)
				net.Broadcast()

				return true, self.PrintName .. " updated successfully!"
			end
		end
	end
	if not isstring(Class) then return end
	if not isfunction(Function) then return end

	local Entity    = GetEntityTable(Class)
	Arguments       = Arguments or (istable(...) and ... or { ... })
	local List      = AddArguments(Entity, Arguments)

	Entity.Spawn = Function

	duplicator.RegisterEntityClass(Class, Function, "Pos", "Angle", "Data", unpack(List))
end

--- Adds extra arguments to a class which has already been called in Entities.Register  
--- Should be called after Entities.Register if you want to specify any additional arguments
--- @param Class string A class previously registered as an entity class
--- @param ... any #A vararg of arguments
function Entities.AddArguments(Class, ...)
	if not isstring(Class) then return end

	local Entity    = GetEntityTable(Class)
	local Arguments = istable(...) and ... or { ... }
	local List      = AddArguments(Entity, Arguments)

	if Entity.Spawn then
		duplicator.RegisterEntityClass(Class, Entity.Spawn, "Pos", "Angle", "Data", unpack(List))
	end
end

--- Returns an array of the entity's arguments
--- @param Class string The entity class to get arguments from
--- @return any[] # An array of arguments attached to the entity
function Entities.GetArguments(Class)
	if not isstring(Class) then return end

	local Entity = GetEntityTable(Class)
	local List   = {}

	for K, V in ipairs(Entity.List) do
		List[K] = V
	end

	return List
end

Classes.AddSimpleFunctions(Entities, Entries)

if CLIENT then return end

do -- Spawning and updating
	local hook = hook
	local undo = undo

	--- Spawns an entity with the given parameters
	--- Internally calls the class' Spawn method
	--- @param Class string The class of entity to spawn
	--- @param Player entity The player creating the entity
	--- @param Position vector The position to create the entity at
	--- @param Angles angle The angles to create the entity at
	--- @param Data table The data to pass into the entity's spawn function
	--- @param NoUndo boolean Whether the entity is added to the undo list (can be z keyed)
	--- @return boolean, table? # Whether the spawning was successful and the reason why
	function Entities.Spawn(Class, Player, Position, Angles, Data, NoUndo)
		if not isstring(Class) then return false end

		local ClassData = Entities.Get(Class)

		if not ClassData then return false, Class .. " is not a registered ACF entity class." end
		if not ClassData.Spawn then return false, Class .. " doesn't have a spawn function assigned to it." end

		local HookResult, HookMessage = hook.Run("ACF_CanCreateEntity", Class, Player, Position, Angles, Data)

		if HookResult == false then return false, HookMessage end

		local Entity = ClassData.Spawn(Player, Position, Angles, Data)
		if not IsValid(Entity) then return false, "The spawn function for " .. Class .. " didn't return an entity." end

		Entity:Activate()
		Entity:CPPISetOwner(Player)

		if not NoUndo then
			undo.Create(Entity.Name or Class)
				undo.AddEntity(Entity)
				undo.SetPlayer(Player)
			undo.Finish()
		end

		return true, Entity
	end

	--- Triggers the update function of an entity  
	--- Internally calls the ENT:Update(Data) metamethod that's implemented on all entities
	--- @param Entity table The entity to update
	--- @param Data table The data to pass into the entity on update
	--- @return boolean, string # Whether the update was successful and the reason why
	function Entities.Update(Entity, Data)
		if not IsValid(Entity) then return false, "Can't update invalid entities." end
		if not isfunction(Entity.Update) then return false, "This entity does not support updating." end

		Data = istable(Data) and Data or {}

		local HookResult, HookMessage = hook.Run("ACF_CanUpdateEntity", Entity, Data)

		if HookResult == false then
			return false, "Couldn't update entity: " .. (HookMessage or "No reason provided.")
		end

		local Result, Message = Entity:Update(Data)

		if not Result then
			Message = "Couldn't update entity: " .. (Message or "No reason provided.")
		end

		return Result, Message
	end
end
