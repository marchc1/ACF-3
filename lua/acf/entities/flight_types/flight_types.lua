local ACF     = ACF
local Flight = ACF.Classes.Flight

do
	Flight.Register("1-Propeller", {
		Name		= "Propeller-based Thrust Producers",
		Description	= "Thrust-producing entities that use propellers to move air in a particular direction, which moves you in the opposite direction.",
		Entity		= "acf_flight_propeller",
		CreateMenu	= ACF.CreateFlightPropellerMenu,
		LimitConVar	= {
			Name	= "_acf_flight_propeller",
			Amount	= 16,
			Text	= "Maximum number of ACF propellers a player can create."
		}
	})

	do
		Flight.RegisterItem("Airscrew", "1-Propeller", {
			Name			= "Airscrew Propeller",
			Description		= "A traditional airscrew propeller.\nWhen connected to an engine, the blade rotates around an axis and produces thrust in one direction.\nBad at generating vertical thrust.",
			Model			= "models/props_c17/TrapPropeller_Blade.mdl"
		})
	end

	do
		Flight.RegisterItem("HelicopterMainRotor", "1-Propeller", {
			Name			= "Helicopter Main Rotor",
			Description		= "The primary rotor for a helicopter. Designed to generate large amounts of vertical thrust, but is too heavy to generate horizontal thrust.\nThese rotors produce so much rotational torque that a tail rotor is required to counteract the torque; otherwise, the helicopter will spin in the opposite direction and be unusable. Another option is to use a second main rotor, configured to rotate in the opposite direction.",
			Model			= "models/props_c17/TrapPropeller_Blade.mdl"
		})
	end
	do
		Flight.RegisterItem("HelicopterTailRotor", "1-Propeller", {
			Name			= "Helicopter Tail Rotor",
			Description		= "The secondary rotor for a helicopter. Mounted at the tail, it produces thrust to counteract the rotational torque produced by the main rotor.",
			Model			= "models/props_c17/TrapPropeller_Blade.mdl"
		})
	end
end