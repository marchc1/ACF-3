local ACF        = ACF

local gridMaterial = CreateMaterial("acf_bp_vis_spropgrid1", "VertexLitGeneric", {
	["$basetexture"] = "sprops/sprops_grid_12x12",
	["$model"] = 1,
	["$translucent"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1
})

local color_thick = Color(255, 255, 255, 0)
local color_thin = Color(255, 255, 0, 0)
local color_superthin = Color(255, 127, 0, 0)

local function LerpColor(a, b, t)
	return Color(
		Lerp(t, a.r, b.r),
		Lerp(t, a.g, b.g),
		Lerp(t, a.b, b.b),
		Lerp(t, a.a, b.a)
	)
end

local function CreateMenu(Menu)
	ACF.SetToolMode("acf_menu", "Spawner", "Component")
	ACF.SetClientData("PrimaryClass", "acf_baseplate")
	ACF.SetClientData("SecondaryClass", "N/A")

	Menu:AddTitle("Baseplate Settings")

	Menu:AddLabel("The root entity of all ACF contraptions.")
	local SizeX     = Menu:AddSlider("Plate Width (gmu)", 36, 96, 2)
	local SizeY     = Menu:AddSlider("Plate Length (gmu)", 36, 420, 2)
	local SizeZ     = Menu:AddSlider("Plate Thickness (gmu)", 1, 3, 2)

	Menu:AddLabel("Comparing the current dimensions with a 105mm Howitzer:")
	local Vis       = Menu:AddModelPreview("models/howitzer/howitzer_105mm.mdl", true)
	Vis:SetSize(30, 300)
	function Vis:PreDrawModel(_)
		local w, h, t = SizeX:GetValue(), SizeY:GetValue(), SizeZ:GetValue()
		self.CamDistance = math.max(w, h, 60) * 1
		local c
		if t > 2 then
			c = LerpColor(color_thin, color_thick, t - 2)
		else
			c = LerpColor(color_superthin, color_thin, t - 1)
		end

		render.SetMaterial(gridMaterial)
		render.DrawBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(-h / 2, -w / 2, -t / 2), Vector(h / 2, w / 2, t / 2), c)

	end

	SizeX:SetClientData("Width", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value, 2)

		Panel:SetValue(X)

		return X
	end)

	SizeY:SetClientData("Length", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value, 2)

		Panel:SetValue(Y)

		return Y
	end)

	SizeZ:SetClientData("Thickness", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value, 2)

		Panel:SetValue(Z)

		return Z
	end)

	Menu:AddLabel("You can hold SHIFT while left-clicking to replace an existing entity with an ACF Baseplate. " ..
		"This will, to the best of its abilities (given you're using a cubical prop, with the long side facing forwards), replace the targetted entity with " ..
		"a new ACF baseplate.\n\nIt works by taking an Advanced Duplicator 2 copy of the entire contraption from the target entity, replacing the target entity " ..
		"in the dupe's class to acf_baseplate, setting the size based off the physical size of the target entity, then removing all entities and re-pasting the dupe. " ..
		"\n\nYou will need to manually re-copy the contraption with the Adv. Dupe 2 tool before using it again, but after that, everything should be converted. This is " ..
		"an experimental tool, so if something breaks with an ordinary setup, report it at https://github.com/ACF-Team/ACF-3/issues."
	)
end

ACF.AddMenuItem(0, "Entities", "Baseplates", "shape_square", CreateMenu)
