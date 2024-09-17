-- Core.lua


-------------------------------------
-- 1. Declarations
-------------------------------------

-- Initialize RM and RMS
RM = RM or {}
RMS = RMS or {}

-- Keep a reference to the settings category
RM.optionsID = nil

-- Initialize settings
function RM:InitializeSettings()
    if RhodansMarkersSettings == nil then
        RhodansMarkersSettings = {
            enabled = true,
            tankEnabled = true,
            healerEnabled = true,
            tankMarker = 1,  -- Default marker is Star
            healerMarker = 5 -- Default marker is Moon
        }
    end
    RMS = RhodansMarkersSettings
end

local RMFrame = CreateFrame("Frame", "RhodansMarkersFrame", UIParent)


-------------------------------------
-- 2. Utility Functions
-------------------------------------

-- Function to check if player is within a 5 player dungeon group
local function IsIn5ManDungeon()
    local isInstance, instanceType = IsInInstance()
    return isInstance and instanceType == "party"
end


-- Enhanced check to determine if the player is no longer in a 5-man dungeon group
local function ShouldClearMarkers()
    local isInstance, instanceType = IsInInstance()
    -- Checking if not in an instance or not in a 'party' instance type
    return not isInstance or instanceType ~= "party"
end


-- Function for applying the raid marker to specific players
local function SetMarkerOnUnit(unit, marker)
    SetRaidTarget(unit, marker)
end


-------------------------------------
-- 3. Core Functionality
-------------------------------------

-- Delayed marker check
function RM.DelayedCheckAndMarkPlayer()
    C_Timer.After(2, RM.CheckAndMarkPlayer)  -- Delay for 2 seconds
end


-- This function is now responsible for both clearing and then re-applying the markers
function RM.ClearAndApplyMarkers()
    RM.ClearAllMarkers()
    -- Apply markers after a delay to ensure they are not immediately cleared by the system
    C_Timer.After(5, function()  -- Increase the delay to 5 seconds to allow for role changes to process
        --RM.CheckAndMarkPlayer()
		RM.CheckAndMarkPartyMembers()
    end)
end


-- Clear markers
function RM.ClearAllMarkers()
    if not IsIn5ManDungeon() then return end
    for i = 0, GetNumGroupMembers() do
        local unit = (i == 0) and "player" or "party" .. i
        SetRaidTarget(unit, 0)
    end
end


-- Ensure this function is part of the RM table and properly called
function RM.ClearPlayerMarkers()
    -- Clear markers from the player
    SetRaidTarget("player", 0)
end


-- Helper function to get a player's specialization ID
local function GetSpecializationID(unit)
    -- For the player, we can use the direct function
    if unit == "player" then
        return GetSpecializationInfo(GetSpecialization())
    else
        local specID = nil
        -- For party members, we need to fetch the specialization from the server
        -- If this returns nil, you may need to wait for the server to send the information
        if UnitIsPlayer(unit) then
            specID = GetInspectSpecialization(unit)
        end
        -- Convert specID to a number if it's not nil
        return specID and tonumber(specID) or nil
    end
end


-- Ensure this function is part of the RM table
function RM.CheckAndMarkPartyMembersByRole()
    -- Check if the addon is enabled
    if not RMS.enabled or (not RMS.tankEnabled and not RMS.healerEnabled) then return end

    if not IsIn5ManDungeon() or UnitAffectingCombat("player") then return end

    RMS.healerMarked = false
    RMS.tankMarked = false

    -- Iterate over party members only, excluding the player
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local role = UnitGroupRolesAssigned(unit)
        local currentMarker = GetRaidTargetIndex(unit)

        if role == "HEALER" and RMS.healerEnabled and not RMS.healerMarked and not currentMarker then
            SetMarkerOnUnit(unit, RMS.healerMarker)  -- Healer marker
            RMS.healerMarked = true
        elseif role == "TANK" and RMS.tankEnabled and not RMS.tankMarked and not currentMarker then
            SetMarkerOnUnit(unit, RMS.tankMarker)  -- Tank marker
            RMS.tankMarked = true
        end
    end
    C_Timer.After(3, RM.CheckAndMarkPlayer)
end

function RM.DelayedCheckAndMarkPartyMembers()
    C_Timer.After(2, RM.CheckAndMarkPartyMembers)  -- Delay for 2 seconds
end


-- Ensure this function is part of the RM table
function RM.CheckAndMarkPartyMembers()
    if not IsIn5ManDungeon() or not RMS.enabled or (not RMS.tankEnabled and not RMS.healerEnabled) or RM.isUpdatingMarkers then return end

    -- Define healer and tank spec IDs
    local healerSpecIDs = {105, 270, 65, 256, 257, 264, 1468} -- Add all healer spec IDs here
    local tankSpecIDs = {250, 104, 581, 66, 268, 73} -- Add all tank spec IDs here

    -- Flags to check if healer or tank has been marked
    RMS.healerMarked = false
    RMS.tankMarked = false

    -- Iterate over party members only, excluding the player
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local specID = GetSpecializationID(unit)
        local currentMarker = GetRaidTargetIndex(unit)

        -- Check and update the party member's marker based on their specialization
        if specID and tContains(healerSpecIDs, specID) and not RMS.healerMarked and currentMarker ~= 5 then
            SetMarkerOnUnit(unit, RMS.healerMarker) -- Healer marker
            RMS.healerMarked = true
        elseif specID and tContains(tankSpecIDs, specID) and not RMS.tankMarked and currentMarker ~= 1 then
            SetMarkerOnUnit(unit, RMS.tankMarker) -- Tank marker
            RMS.tankMarked = true
        end
    end
	RM.DelayedCheckAndMarkPlayer()
end


-- Ensure this function is part of the RM table
function RM.CheckAndMarkPlayer()
    -- Ensure we are in a dungeon, the addon is enabled, and we are not currently updating markers
    if not IsIn5ManDungeon() or not RMS.enabled or (not RMS.tankEnabled and not RMS.healerEnabled) or RM.isUpdatingMarkers then return end

    -- Throttle updates to prevent loops
    if RM.lastUpdate and (GetTime() - RM.lastUpdate) < 1 then return end
    RM.lastUpdate = GetTime()

    RM.isUpdatingMarkers = true
    local playerSpecID = GetSpecializationID("player")
    local playerMarker = GetRaidTargetIndex("player")

    -- Define healer and tank spec IDs
    local healerSpecIDs = {105, 270, 65, 256, 257, 264, 1468} -- Add all healer spec IDs here
    local tankSpecIDs = {250, 104, 581, 66, 268, 73} -- Add all tank spec IDs here

    -- Check and update the player's marker based on their specialization
    if playerSpecID and tContains(healerSpecIDs, playerSpecID) and RMS.healerEnabled and playerMarker ~= 5 then
        SetMarkerOnUnit("player", RMS.healerMarker) -- Healer marker
    elseif playerSpecID and tContains(tankSpecIDs, playerSpecID) and RMS.tankEnabled and playerMarker ~= 1 then
        SetMarkerOnUnit("player", RMS.tankMarker) -- Tank marker
    elseif playerMarker and not (tContains(healerSpecIDs, playerSpecID) or tContains(tankSpecIDs, playerSpecID)) then
        SetRaidTarget("player", 0) -- Clear the marker if it's not matching the spec anymore
    end

	if not RMS.healerMarked or not RMS.tankMarked then
		RM.CheckAndMarkPartyMembersByRole()
	end

    -- Reset the flag after a delay
    C_Timer.After(1, function() RM.isUpdatingMarkers = false end)
end


-------------------------------------
-- 4. Event Registration
-------------------------------------

-- Register event for group roster update
RMFrame:RegisterEvent("ADDON_LOADED")
RMFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
RMFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
RMFrame:RegisterEvent("ENCOUNTER_START")
RMFrame:RegisterEvent("ENCOUNTER_END")
RMFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
RMFrame:RegisterEvent("PLAYER_REGEN_ENABLED")


-------------------------------------
-- 5. Event Handlers and Throttling
-------------------------------------

-- Flag to indicate whether an update is from the addon
RM.addonIsUpdatingMarkers = false

-- Throttle system to prevent rapid updates
local lastUpdate = 0
local function ShouldThrottle()
    local now = GetTime()
    if now - lastUpdate < 0.5 then -- half a second throttle
        return true
    end
    lastUpdate = now
    return false
end


-- Event handling function
RMFrame:SetScript("OnEvent", function(self, event, addonName)

    if event == "ADDON_LOADED" and addonName == "RhodansMarkers" then
        RM:InitializeSettings()
        RM:RegisterOptions()
        RMFrame:UnregisterEvent("ADDON_LOADED")
    end

    if not RMS.enabled or (not RMS.tankEnabled and not RMS.healerEnabled) then return end

    if event == "PLAYER_ENTERING_WORLD" then --or event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1, function()  -- Increased delay to ensure state accuracy
            if ShouldClearMarkers() then
                RM.ClearPlayerMarkers()
            end
        end)

    elseif event == "GROUP_ROSTER_UPDATE" and IsIn5ManDungeon() then
        -- Delayed re-marking if the group roster updates while in a dungeon
        RM.addonIsUpdatingMarkers = true
        RM.ClearAndApplyMarkers()
        C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)  -- Set flag to false after markers have been re-applied

	-- Triggers when Boss fight is over (win/lose) or during a PORTRAITS_UPDATED event (such as clicking the books in Azure Vault
    elseif event == "ENCOUNTER_END" then  -- TRIGGERS WHEN A BOSS FIGHT IS OVER (WIN OR LOSE)
	--elseif event == "ENCOUNTER_END" then 
        -- Actions to take when exiting combat
        if IsIn5ManDungeon() then
            RM.addonIsUpdatingMarkers = true
            RM.ClearAndApplyMarkers()
            C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)
        end

	-- Triggers when Boss fight is over (win/lose) or during a PORTRAITS_UPDATED event (such as clicking the books in Azure Vault
    elseif event == "UNIT_PORTRAIT_UPDATE" then  -- TRIGGERS WHEN A BOSS FIGHT IS OVER (WIN OR LOSE)
        -- Actions to take when exiting combat
        if IsIn5ManDungeon() then
            RM.addonIsUpdatingMarkers = true
            RM.CheckAndMarkPartyMembers()
            C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)
        end

	-- Triggers when Boss fight is over (win/lose) or during a PORTRAITS_UPDATED event (such as clicking the books in Azure Vault
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Actions to take when exiting combat
        if IsIn5ManDungeon() then
            RM.addonIsUpdatingMarkers = true
            RM.CheckAndMarkPartyMembers()
            C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)
        end
    end
end)


-------------------------------------
-- 6. Options
-------------------------------------

-- Create options panel
-- Create options panel
-- Create options panel
function RM:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "RhodansMarkersOptionsPanel", UIParent)
    panel.name = "Rhodan's Markers"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Rhodan's Markers Options")

    -- Enable/Disable Party Markers Checkbox
    RM.enabledCheckbox = CreateFrame("CheckButton", "EnablePartyMarkersCheckbox", panel, "UICheckButtonTemplate")
    RM.enabledCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
    RM.enabledCheckbox.text = RM.enabledCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    RM.enabledCheckbox.text:SetPoint("LEFT", RM.enabledCheckbox, "RIGHT", 0, 0)
    RM.enabledCheckbox.text:SetText("Enable/Disable Party Markers")
    RM.enabledCheckbox:SetChecked(RMS.enabled)

    -- Helper label under Enable/Disable Party Markers
    local helperLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    helperLabel:SetPoint("TOPLEFT", RM.enabledCheckbox, "BOTTOMLEFT", 0, 0)
    helperLabel:SetText("Toggle party markers on or off, regardless of individual role marker settings below.")
    helperLabel:SetTextColor(1, 1, 1)  -- Set text color to white (RGB: 1, 1, 1)

    -- Horizontal line
    local horizontalLine = panel:CreateTexture(nil, "ARTWORK")
    horizontalLine:SetColorTexture(1, 1, 1, 0.5)
    horizontalLine:SetHeight(1)
    horizontalLine:SetPoint("TOPLEFT", helperLabel, "BOTTOMLEFT", 0, -20)
    horizontalLine:SetPoint("RIGHT", -16, 0)

    -- Tank Marker Label
    local tankLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tankLabel:SetPoint("TOPLEFT", horizontalLine, "BOTTOMLEFT", 0, -20)
    tankLabel:SetText("Select the Tank marker:")

    -- Tank Marker Dropdown
    local tankDropdown = CreateFrame("Frame", "TankMarkerDropdown", panel, "UIDropDownMenuTemplate")
    tankDropdown:SetPoint("TOPLEFT", tankLabel, "BOTTOMLEFT", -16, -10)
    UIDropDownMenu_SetWidth(tankDropdown, 150)
    UIDropDownMenu_SetText(tankDropdown, "Select Tank Marker")

    -- Tank Marker Checkbox
    RM.tankCheckbox = CreateFrame("CheckButton", "TankMarkerCheckbox", panel, "UICheckButtonTemplate")
    RM.tankCheckbox:SetPoint("LEFT", tankDropdown, "RIGHT", 10, 0)
    RM.tankCheckbox.text = RM.tankCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    RM.tankCheckbox.text:SetPoint("LEFT", RM.tankCheckbox, "RIGHT", 0, 0)
    RM.tankCheckbox.text:SetText("Enable Tank Marker")
    RM.tankCheckbox:SetChecked(RMS.tankEnabled)

    -- Healer Marker Label
    local healerLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    healerLabel:SetPoint("TOPLEFT", tankDropdown, "BOTTOMLEFT", 16, -40)
    healerLabel:SetText("Select the Healer marker:")

    -- Healer Marker Dropdown
    local healerDropdown = CreateFrame("Frame", "HealerMarkerDropdown", panel, "UIDropDownMenuTemplate")
    healerDropdown:SetPoint("TOPLEFT", healerLabel, "BOTTOMLEFT", -16, -10)
    UIDropDownMenu_SetWidth(healerDropdown, 150)
    UIDropDownMenu_SetText(healerDropdown, "Select Healer Marker")

    -- Healer Marker Checkbox
    RM.healerCheckbox = CreateFrame("CheckButton", "HealerMarkerCheckbox", panel, "UICheckButtonTemplate")
    RM.healerCheckbox:SetPoint("LEFT", healerDropdown, "RIGHT", 10, 0)
    RM.healerCheckbox.text = RM.healerCheckbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    RM.healerCheckbox.text:SetPoint("LEFT", RM.healerCheckbox, "RIGHT", 0, 0)
    RM.healerCheckbox.text:SetText("Enable Healer Marker")
    RM.healerCheckbox:SetChecked(RMS.healerEnabled)

    -- Helper function to populate dropdown with marker options
    local function PopulateMarkerDropdown(dropdown, role)
        local markers = {
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:12|t Star", value = 1 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:12|t Circle", value = 2 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:12|t Diamond", value = 3 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:12|t Triangle", value = 4 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:12|t Moon", value = 5 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:12|t Square", value = 6 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:12|t Cross", value = 7 },
            { text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12|t Skull", value = 8 }
        }

        local function OnClick(self)
            UIDropDownMenu_SetSelectedID(dropdown, self:GetID())
            if role == "healer" then
                if self.value == RMS.tankMarker then
                    print("Healer marker cannot be the same as Tank marker.")
                    UIDropDownMenu_SetSelectedValue(healerDropdown, RMS.healerMarker)
                else
                    RMS.healerMarker = self.value
                end
            elseif role == "tank" then
                if self.value == RMS.healerMarker then
                    print("Tank marker cannot be the same as Healer marker.")
                    UIDropDownMenu_SetSelectedValue(tankDropdown, RMS.tankMarker)
                else
                    RMS.tankMarker = self.value
                end
            end
            RM.ClearAndApplyMarkers()
        end

        local function Initialize(self, level)
            for i, marker in ipairs(markers) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = marker.text
                info.value = marker.value
                info.func = OnClick
                UIDropDownMenu_AddButton(info, level)
            end
        end

        UIDropDownMenu_Initialize(dropdown, Initialize)
    end

    -- Populate dropdowns
    PopulateMarkerDropdown(tankDropdown, "tank")
    PopulateMarkerDropdown(healerDropdown, "healer")

    -- Load saved values
    UIDropDownMenu_SetSelectedValue(tankDropdown, RMS.tankMarker)
    UIDropDownMenu_SetSelectedValue(healerDropdown, RMS.healerMarker)

    -- Apply markers when checkbox states change
    RM.tankCheckbox:SetScript("OnClick", function(self)
        RMS.tankEnabled = self:GetChecked()
        RM.ClearAndApplyMarkers()
    end)

    RM.healerCheckbox:SetScript("OnClick", function(self)
        RMS.healerEnabled = self:GetChecked()
        RM.ClearAndApplyMarkers()
    end)

    -- Apply party markers toggle when checkbox changes
    RM.enabledCheckbox:SetScript("OnClick", function(self)
        RMS.enabled = self:GetChecked()
        if not RMS.enabled then
            RM.ClearAllMarkers()
        else
            RM.ClearAndApplyMarkers()
        end
    end)

    return panel
end

-- Register options panel
function RM:RegisterOptions()
    local panel = RM:CreateOptionsPanel()
    local Category = Settings.RegisterCanvasLayoutCategory(panel, "Rhodan's Markers")
    Settings.RegisterAddOnCategory(Category)
    RM.optionsID = Category:GetID()
end


-------------------------------------
-- 7. Slash Command Registration
-------------------------------------

-- Slash command registration
SLASH_RM1 = "/rm"
SlashCmdList["RM"] = function(msg)
    msg = string.lower(msg)

    if msg == "" then
        -- Open the options panel
        if Settings and Settings.OpenToCategory and RM.optionsID then
            Settings.OpenToCategory(RM.optionsID)
        else
            print("Rhodan's Markers options panel not found.")
        end
    elseif msg == "on" then
        RMS.enabled = true
        RM.enabledCheckbox:SetChecked(RMS.enabled)
        print("Rhodan's Markers enabled.")
        RM.CheckAndMarkPlayer()
    elseif msg == "off" then
        RMS.enabled = false
        RM.enabledCheckbox:SetChecked(RMS.enabled)
        print("Rhodan's Markers disabled.")
        RM.ClearAllMarkers()
    else
        print("Usage: /rm to open options panel. /rm [on | off] to toggle all markers on or off.")
    end
end