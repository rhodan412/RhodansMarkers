-- Core.lua


-- Initialize RM if it doesn't exist
RM = RM or {}


-- Initialize the enabled state from the saved variable or default to true
-- At the top of your Core.lua or equivalent file
if RhodansMarkersEnabled == nil then
    RhodansMarkersEnabled = true  -- Default state is enabled
end
RM.isEnabled = RhodansMarkersEnabled



local RMFrame = CreateFrame("Frame", "RhodansMarkersFrame", UIParent)


local function IsIn5ManDungeon()
    local isInstance, instanceType = IsInInstance()
    return isInstance and instanceType == "party"
end


local function SetMarkerOnUnit(unit, marker)
    SetRaidTarget(unit, marker)
end


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
    if not RM.isEnabled then return end
	
    if not IsIn5ManDungeon() or UnitAffectingCombat("player") then return end

    local healerMarked = false
    local tankMarked = false

    -- Iterate over party members only, excluding the player
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local role = UnitGroupRolesAssigned(unit)
        local currentMarker = GetRaidTargetIndex(unit)

        if role == "HEALER" and not healerMarked and not currentMarker then
            SetMarkerOnUnit(unit, 5)  -- Moon marker
            healerMarked = true
        elseif role == "TANK" and not tankMarked and not currentMarker then
            SetMarkerOnUnit(unit, 1)  -- Star marker
            tankMarked = true
        end
    end
    C_Timer.After(3, RM.CheckAndMarkPlayer)
end

function RM.DelayedCheckAndMarkPartyMembers()
    C_Timer.After(2, RM.CheckAndMarkPartyMembers)  -- Delay for 2 seconds
end


-- Ensure this function is part of the RM table
function RM.CheckAndMarkPartyMembersByRole()
    -- Check if the addon is enabled
    if not RM.isEnabled then return end
	
    if not IsIn5ManDungeon() or UnitAffectingCombat("player") then return end

    local healerMarked = false
    local tankMarked = false

    -- Iterate over party members only, excluding the player
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local role = UnitGroupRolesAssigned(unit)
        local currentMarker = GetRaidTargetIndex(unit)

        if role == "HEALER" and not healerMarked and not currentMarker then
            SetMarkerOnUnit(unit, 5)  -- Moon marker
            healerMarked = true
        elseif role == "TANK" and not tankMarked and not currentMarker then
            SetMarkerOnUnit(unit, 1)  -- Star marker
            tankMarked = true
        end
    end
end


-- Ensure this function is part of the RM table
function RM.CheckAndMarkPartyMembers()
    if not IsIn5ManDungeon() or not RM.isEnabled or RM.isUpdatingMarkers then return end

    -- Define healer and tank spec IDs
    local healerSpecIDs = {105, 270, 65, 256, 257, 264, 1468} -- Add all healer spec IDs here
    local tankSpecIDs = {250, 104, 581, 66, 268, 73} -- Add all tank spec IDs here

    -- Flags to check if healer or tank has been marked
    local healerMarked = false
    local tankMarked = false

    -- Iterate over party members only, excluding the player
    for i = 1, GetNumGroupMembers() - 1 do
        local unit = "party" .. i
        local specID = GetSpecializationID(unit)
        local currentMarker = GetRaidTargetIndex(unit)

        -- Check and update the party member's marker based on their specialization
        if specID and tContains(healerSpecIDs, specID) and not healerMarked and currentMarker ~= 5 then
            SetMarkerOnUnit(unit, 5) -- Moon marker
            healerMarked = true
        elseif specID and tContains(tankSpecIDs, specID) and not tankMarked and currentMarker ~= 1 then
            SetMarkerOnUnit(unit, 1) -- Star marker
            tankMarked = true
        end
    end
	RM.DelayedCheckAndMarkPlayer()
end


		
-- Ensure this function is part of the RM table
function RM.CheckAndMarkPlayer()
    -- Ensure we are in a dungeon, the addon is enabled, and we are not currently updating markers
    if not IsIn5ManDungeon() or not RM.isEnabled or RM.isUpdatingMarkers then return end
	
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
    if playerSpecID and tContains(healerSpecIDs, playerSpecID) and playerMarker ~= 5 then
        SetMarkerOnUnit("player", 5) -- Moon marker
    elseif playerSpecID and tContains(tankSpecIDs, playerSpecID) and playerMarker ~= 1 then
        SetMarkerOnUnit("player", 1) -- Star marker
    elseif playerMarker and not (tContains(healerSpecIDs, playerSpecID) or tContains(tankSpecIDs, playerSpecID)) then
        SetRaidTarget("player", 0) -- Clear the marker if it's not matching the spec anymore
    end

	if not healerMarked or not tankMarked then
		RM.CheckAndMarkPartyMembersByRole()
	end
	
    -- Reset the flag after a delay
    C_Timer.After(1, function() RM.isUpdatingMarkers = false end)
end



-- At the beginning of your script
RM.isEnabled = true  -- Addon is enabled by default


-- Slash command registration
SLASH_RM1 = "/rm"
SlashCmdList["RM"] = function(msg)
    msg = string.lower(msg)
    if msg == "on" then
        RM.isEnabled = true
        RhodansMarkersEnabled = true  -- Update the saved variable
        print("Rhodan's Markers enabled.")
        RM.DelayedCheckAndMarkPlayer()  -- Optionally check and mark players immediately
    elseif msg == "off" then
        RM.isEnabled = false
        RhodansMarkersEnabled = false  -- Update the saved variable
        print("Rhodan's Markers disabled.")
    else
        print("Usage: /rm on | /rm off")
    end
end




-- Register event for group roster update
RMFrame:RegisterEvent("ADDON_LOADED")
RMFrame:RegisterEvent("VARIABLES_LOADED")
RMFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
RMFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
RMFrame:RegisterEvent("PLAYER_LOGIN")
RMFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
RMFrame:RegisterEvent("RAID_TARGET_UPDATE")
RMFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")


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
RMFrame:SetScript("OnEvent", function(self, event, ...)
    if not RM.isEnabled then return end

    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ROLES_ASSIGNED" then
        local inInstance, instanceType = IsInInstance()
        if inInstance and instanceType == "party" then
            RM.addonIsUpdatingMarkers = true
            RM.ClearAndApplyMarkers()
            C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)  -- Set flag to false after markers have been re-applied
        end
    elseif event == "GROUP_ROSTER_UPDATE" and IsIn5ManDungeon() then
        -- Delayed re-marking if the group roster updates while in a dungeon
        RM.addonIsUpdatingMarkers = true
        RM.ClearAndApplyMarkers()
        C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)  -- Set flag to false after markers have been re-applied
    elseif event == "PLAYER_REGEN_ENABLED" then  -- MIGHT NEED TO REMOVE THIS IF MARKS TURN INTO BAD BEHAVIOR, ELSE CAN SAVE HEALER AND TANK TO TABLE FOR REFRESHING WHEN COMBAT ENDS
        -- Actions to take when exiting combat
        if IsIn5ManDungeon() then
            RM.addonIsUpdatingMarkers = true
            RM.ClearAndApplyMarkers()
            C_Timer.After(5.5, function() RM.addonIsUpdatingMarkers = false end)
        end
    end
end)