local ACF = ACF
local Flight = ACF.Classes.Flight
local function CreateMenu(Menu)
    local Entries = Flight.GetEntries()

    ACF.SetToolMode("acf_menu", "Spawner", "Component")
    ACF.SetClientData("PrimaryClass", "N/A")
    ACF.SetClientData("SecondaryClass", "N/A")

    Menu:AddTitle("Flight Entities")
    Menu:AddLabel("Warning: Experimental!\nFlight entities are a work in progress, and may lead to some strange events!\nReport any crashes or other issues if you come across them!")
    local ClassList = Menu:AddComboBox()
    local ClassDesc = Menu:AddLabel()
    local ComponentClass = Menu:AddComboBox()
    local Base = Menu:AddCollapsible("Flight Components")
    local ComponentName = Base:AddTitle()
    local ComponentDesc = Base:AddLabel()
    function ClassList:OnSelect(Index, _, Data)
        if self.Selected == Data then return end
        self.ListData.Index = Index
        self.Selected = Data
        ClassDesc:SetText(Data.Description or "No description provided.")
        ACF.LoadSortedList(ComponentClass, Data.Items, "Name")
    end

    function ComponentClass:OnSelect(Index, _, Data)
        if self.Selected == Data then return end
        self.ListData.Index = Index
        self.Selected = Data
        local ClassData = ClassList.Selected
        ACF.SetClientData("Propeller", Data.ID)
        ComponentName:SetText(Data.Name)
        ComponentDesc:SetText(Data.Description or "No description provided.")
        Menu:ClearTemporal(Base)
        Menu:StartTemporal(Base)
        local CustomMenu = Data.CreateMenu or ClassData.CreateMenu
        if CustomMenu then CustomMenu(Data, Base) end
        Menu:EndTemporal(Base)
    end

    ACF.LoadSortedList(ClassList, Entries, "ID")
end

ACF.AddMenuItem(210, "Entities", "Flight", "weather_clouds", CreateMenu)