local Classes 	= ACF.Classes
local Flight 	= Classes.Flight
local Entries 	= {}


function Flight.Register(ID, Data)
	local Group = Classes.AddGroup(ID, Entries, Data)

	if not Group.LimitConVar then
		print("Added LimitConVar for ", ID)
		Group.LimitConVar = {
			Name   = "_acf_flight",
			Amount = 32,
			Text   = "Maximum amount of ACF flight components a player can create."
		}
	end

	Classes.AddSboxLimit(Group.LimitConVar)

	return Group
end

function Flight.RegisterItem(ID, ClassID, Data)
	return Classes.AddGroupItem(ID, ClassID, Entries, Data)
end

Classes.AddGroupedFunctions(Flight, Entries)
