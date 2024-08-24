local ACF = ACF
ACF.Permissions = ACF.Permissions or {}
local this = ACF.Permissions
local getPanelChecks = function() return {} end

local Permissions = {}

local PermissionModes = {}
local CurrentPermission = "default"
local DefaultPermission = "none"
local ModeDescTxt
local ModeDescDefault = "Can't find any info for this mode!"
local currentMode
local list
local firstMenuOpen = true


net.Receive("ACF_refreshfriends", function()
    local perms = net.ReadTable()
    local checks = getPanelChecks()

    for _, check in pairs(checks) do
        if perms[check.steamid] then
            check:SetChecked(true)
        else
            check:SetChecked(false)
        end
    end
end)

net.Receive("ACF_refreshfeedback", function()
    local success = net.ReadBit()
    local str, notify

    if success then
        str = "Successfully updated your ACF damage permissions!"
        notify = "NOTIFY_GENERIC"
    else
        str = "Failed to update your ACF damage permissions."
        notify = "NOTIFY_ERROR"
    end

    GAMEMODE:AddNotify(str, notify, 7)
end)

net.Receive("ACF_refreshpermissions", function()
    PermissionModes = net.ReadTable()
    CurrentPermission = net.ReadString()
    DefaultPermission = net.ReadString()

    Permissions:Update()
end)

function this.ApplyPermissions(checks)
    local perms = {}

    for _, check in pairs(checks) do
        if not check.steamid then
            Error("Encountered player checkbox without an attached SteamID!")
        end

        perms[check.steamid] = check:GetChecked()
    end

    net.Start("ACF_dmgfriends")
    net.WriteTable(perms)
    net.SendToServer()
end


local function CreateGivePerms(Menu)
    Menu:AddTitle("Give Damage Permissions")
    Menu:AddLabel("Allow or deny ACF damage to your props using this panel.\n\nThese preferences only work during the Build and Strict Build modes.")
    Menu.playerChecks = {}
    local checks = Menu.playerChecks
    getPanelChecks = function() return checks end
    local Players = player.GetAll()

    for _, tar in ipairs(Players) do
        if (IsValid(tar)) then
            local check = Menu:AddCheckBox(tar:Nick())
            check.steamid = tar:SteamID()
            --if tar == LocalPlayer() then check:SetChecked(true) end
            checks[#checks + 1] = check
        end
    end

    local button = Menu:AddButton("Give Damage Permission")

    button.DoClick = function()
        this.ApplyPermissions(Menu.playerChecks)
    end

    net.Start("ACF_refreshfriends")
    net.SendToServer(ply)
end

ACF.AddMenuItem(1, "Damage Permissions", "Give Permissions", "user_edit", CreateGivePerms)

local function CreateSetPerms(Menu)
    Permissions:RequestUpdate()

    Menu:AddTitle("Set Damage Mode")
    Menu:AddLabel("Damage Permission Modes change the way that ACF damage works.\n\nYou can change the DP mode if you are an admin.")
    currentMode = Menu:AddLabel("\nThe current damage permission mode is " .. CurrentPermission)

    if LocalPlayer():IsAdmin() then
        list = Menu:AddPanel("DListView")
        list:AddColumn("Mode")
        list:AddColumn("Active")
        list:AddColumn("Map Default")
        list:SetMultiSelect(false)
        list:SetSize(30, 100)

        for permission in pairs(PermissionModes) do
            list:AddLine(permission, "", "")
        end

        for id, line in pairs(list:GetLines()) do
            if line:GetValue(1) == CurrentPermission then
                list:GetLine(id):SetValue(2, "Yes")
            end
            if line:GetValue(1) == DefaultPermission then
                list:GetLine(id):SetValue(3, "Yes")
            end
        end

        list.OnRowSelected = function(panel, line)
            if ModeDescTxt then
                ModeDescTxt:SetText(PermissionModes[panel:GetLine(line):GetValue(1)] or ModeDescDefault)
                ModeDescTxt:SizeToContents()
            end
        end

        txt = Menu:AddLabel("What this mode does:")

        ModeDescTxt = Menu:AddLabel(PermissionModes[CurrentPermission] or ModeDescDefault)

        local button = Menu:AddButton("Set Permission Mode")
        button.DoClick = function()
            local line = list:GetLine(list:GetSelectedLine())
            if not line then
                Permissions:RequestUpdate()
                return
            end

            local mode = line and line:GetValue(1)
            RunConsoleCommand("ACF_setpermissionmode", mode)
        end


        local button2 = Menu:AddButton("Set Default Permission Mode")
        button2.DoClick = function()
            local line = list:GetLine(list:GetSelectedLine())
            if not line then
                Permissions:RequestUpdate()
                return
            end

            local mode = line and line:GetValue(1)
            RunConsoleCommand("ACF_setdefaultpermissionmode", mode)
        end
    end
end


function Permissions:Update()
    if list then
        for id, line in pairs(list:GetLines()) do
            if line:GetValue(1) == CurrentPermission then
                list:GetLine(id):SetValue(2, "Yes")
            else
                list:GetLine(id):SetValue(2, "")
            end
            if line:GetValue(1) == DefaultPermission then
                list:GetLine(id):SetValue(3, "Yes")
            else
                list:GetLine(id):SetValue(3, "")
            end
        end
    end

    if currentMode then
        currentMode:SetText(string.format("The current damage permission mode is %s.", CurrentPermission))
        currentMode:SizeToContents()
    end
end

function Permissions:RequestUpdate()
    net.Start("ACF_refreshpermissions")
    net.SendToServer()
end

ACF.AddMenuItem(2, "Damage Permissions", "Set Permission Mode", "server_edit", CreateSetPerms)

Permissions:RequestUpdate()