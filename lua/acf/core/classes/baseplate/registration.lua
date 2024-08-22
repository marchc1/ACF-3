local Classes    = ACF.Classes
local Baseplate = Classes.Baseplate
local Entries    = {}

function Baseplate.Register(ID, Base)
	return Classes.AddObject(ID, Base, Entries)
end

Classes.AddSimpleFunctions(Baseplate, Entries)
Classes.AddSboxLimit({
	Name   = "_acf_baseplate",
	Amount = 32,
	Text   = "Maximum amount of ACF baseplates a player can create"
})
