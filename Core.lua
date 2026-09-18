-- Rhodan's Markers: target-driven tank and healer marking in five-player dungeons.
RM = RM or {}
RMS = RMS or {}

local ADDON_NAME = "RhodansMarkers"
local healerSpecs = { [65] = true, [105] = true, [256] = true, [257] = true, [264] = true, [270] = true, [1468] = true }
local tankSpecs = { [66] = true, [73] = true, [104] = true, [250] = true, [268] = true, [581] = true }
local version = GetBuildInfo()
local major, minor = tostring(version):match("^(%d+)%.(%d+)")
major, minor = tonumber(major) or 0, tonumber(minor) or 0
-- Forever reports 1.60 but uses the newer protected raid-target action.
local secureMarking = major >= 12 or (major == 1 and minor >= 60)
local frame = CreateFrame("Frame")
local button
local bindingOwner = CreateFrame("Frame")
local lastInspectGUID, lastInspectTime

function RM:InitializeSettings()
    RhodansMarkersSettings = RhodansMarkersSettings or {}
    RMS = RhodansMarkersSettings
    if RMS.enabled == nil then RMS.enabled = true end
    if RMS.tankEnabled == nil then RMS.tankEnabled = true end
    if RMS.healerEnabled == nil then RMS.healerEnabled = true end
    RMS.tankMarker = tonumber(RMS.tankMarker) or 1
    RMS.healerMarker = tonumber(RMS.healerMarker) or 5
    if type(RMS.keybind) ~= "string" or RMS.keybind == "" then RMS.keybind = nil end
end

local function InFivePlayerDungeon()
    local inside, kind = IsInInstance()
    local members = GetNumGroupMembers() or 0
    return inside and kind == "party" and not IsInRaid() and members >= 2 and members <= 5
end

local function TargetSpec(unit)
    if not UnitIsPlayer(unit) then return nil end
    local specAPI = C_SpecializationInfo
    if unit == "player" then
        local index = specAPI and specAPI.GetSpecialization and specAPI.GetSpecialization()
            or (GetSpecialization and GetSpecialization())
        if not index then return nil end
        if specAPI and specAPI.GetSpecializationInfo then
            return specAPI.GetSpecializationInfo(index)
        end
        return GetSpecializationInfo and GetSpecializationInfo(index)
    end
    local spec = specAPI and specAPI.GetInspectSpecialization and specAPI.GetInspectSpecialization(unit)
        or (GetInspectSpecialization and GetInspectSpecialization(unit))
    if issecretvalue and issecretvalue(spec) then return nil end
    if spec and spec > 0 then return spec end
    -- Classic and Retail may need an inspect response before the spec is known.
    if NotifyInspect and CanInspect and CanInspect(unit) then
        local guid = UnitGUID(unit)
        if guid and (not issecretvalue or not issecretvalue(guid))
            and (guid ~= lastInspectGUID or GetTime() - (lastInspectTime or 0) > 5) then
            lastInspectGUID, lastInspectTime = guid, GetTime()
            NotifyInspect(unit)
        end
    end
end

local function TargetPartyUnit()
    if UnitIsUnit("target", "player") then return "player" end
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitIsUnit("target", unit) then return unit end
    end
end

local function PartyRoleUnits()
    local tank, healer
    for i = 0, 4 do
        local unit = i == 0 and "player" or "party" .. i
        if UnitExists(unit) then
            local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
            if not (issecretvalue and issecretvalue(role)) then
                -- Match the self-role fallback used when marking the player.
                if role ~= "TANK" and role ~= "HEALER" and unit == "player" then
                    local spec = TargetSpec(unit)
                    if tankSpecs[spec] then role = "TANK" end
                    if healerSpecs[spec] then role = "HEALER" end
                end
                if role == "TANK" and not tank then tank = unit end
                if role == "HEALER" and not healer then healer = unit end
            end
        end
    end
    return tank, healer
end

local function TargetMarker()
    if not RMS.enabled or not InFivePlayerDungeon() or InCombatLockdown() then return nil end
    if not UnitExists("target") then return nil end
    local unit = TargetPartyUnit()
    if not unit then return nil end

    -- Assigned party role wins; specialization is only a fallback for players.
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
    if issecretvalue and issecretvalue(role) then return nil end
    if role == "TANK" then return RMS.tankEnabled and RMS.tankMarker or nil, "Tank" end
    if role == "HEALER" then return RMS.healerEnabled and RMS.healerMarker or nil, "Healer" end
    -- A player's assigned dungeon role can lag behind a spec change; use the
    -- player's current spec as a fallback while retaining the DPS veto for others.
    if role == "DAMAGER" and unit ~= "player" then return nil end
    local spec = TargetSpec(unit)
    if issecretvalue and issecretvalue(spec) then return nil end
    if tankSpecs[spec] then return RMS.tankEnabled and RMS.tankMarker or nil, "Tank" end
    if healerSpecs[spec] then return RMS.healerEnabled and RMS.healerMarker or nil, "Healer" end
end

local function CreateMarkButton()
    -- Retail and Forever require a genuinely secure action for raid-target marking.
    button = CreateFrame("Button", "RhodansMarkersMarkButton", UIParent,
        secureMarking and "SecureActionButtonTemplate,SecureHandlerStateTemplate" or nil)
    button:SetSize(110, 30)
    if TargetFrame then
        button:SetPoint("LEFT", TargetFrame, "RIGHT", 12, 0)
    else
        button:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    button:SetFrameStrata("DIALOG")
    -- Secure override bindings need both phases so the button receives key release.
    if secureMarking then
        button:RegisterForClicks("AnyDown", "AnyUp")
    else
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.04, 0.06, 0.09, 0.94)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.30, 0.42, 0.56, 0.45)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText("Mark")
    button.label = label

    if secureMarking then
        -- Force the up-click path even when the ActionButtonUseKeyDown CVar is enabled.
        button:SetAttribute("useOnKeyDown", false)
        button:SetAttribute("action", "set")
        button:SetAttribute("_onstate-combat", [[
            if newstate == "combat" then
                self:SetAttribute("type1", nil)
                self:SetAttribute("type2", nil)
                self:Hide()
            end
        ]])
        RegisterStateDriver(button, "combat", "[combat] combat; nocombat")
    else
        button:SetScript("OnClick", function(_, mouseButton)
            local marker = TargetMarker()
            if marker then
                SetRaidTarget("target", marker)
            elseif RMS.enabled and InFivePlayerDungeon() and not InCombatLockdown() then
                local tank, healer = PartyRoleUnits()
                local unit = mouseButton == "LeftButton" and tank
                    or mouseButton == "RightButton" and healer
                if unit then TargetUnit(unit) end
            end
        end)
    end
    button:Hide()
end

function RM.UpdateButton()
    if not button then return end
    -- The secure state driver disables and hides the protected button in combat.
    if InCombatLockdown() then
        if not secureMarking then button:Hide() end
        return
    end
    ClearOverrideBindings(bindingOwner)
    local marker, role = TargetMarker()
    local marking = marker and marker >= 1 and marker <= 8
    local tank, healer
    if not marking and RMS.enabled and InFivePlayerDungeon() then
        tank, healer = PartyRoleUnits()
        if not RMS.tankEnabled then tank = nil end
        if not RMS.healerEnabled then healer = nil end
    end
    if secureMarking then
        button:SetAttribute("type1", marking and "raidtarget" or tank and "target" or nil)
        button:SetAttribute("type2", marking and "raidtarget" or healer and "target" or nil)
        button:SetAttribute("unit1", marking and "target" or tank)
        button:SetAttribute("unit2", marking and "target" or healer)
        button:SetAttribute("marker", marking and marker or nil)
    end
    if marking then
        button.label:SetText(role .. " |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. marker .. ":16:16|t")
    elseif tank or healer then
        button.label:SetText((tank and "L: Tank" or "")
            .. (tank and healer and "  " or "") .. (healer and "R: Healer" or ""))
    else
        button:Hide()
        return
    end
    button:Show()
    if RMS.keybind then
        SetOverrideBindingClick(bindingOwner, true, RMS.keybind, button:GetName(), "LeftButton")
    end
end

-- Follower parties can briefly have an incomplete roster while roles are reassigned.
-- Refresh after the role event and again when that reorganization has settled.
local roleRefreshToken = 0
local function ScheduleRoleRefresh()
    roleRefreshToken = roleRefreshToken + 1
    local token = roleRefreshToken
    C_Timer.After(0.5, function()
        if token == roleRefreshToken then RM.UpdateButton() end
    end)
    C_Timer.After(3, function()
        if token == roleRefreshToken then RM.UpdateButton() end
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("RAID_TARGET_UPDATE")
frame:RegisterEvent("INSPECT_READY")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("ROLE_CHANGED_INFORM")
if major >= 5 or secureMarking then frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") end
if major >= 5 then frame:RegisterEvent("LFG_ROLE_UPDATE") end
frame:SetScript("OnEvent", function(_, event, addon)
    if event == "ADDON_LOADED" then
        if addon ~= ADDON_NAME then return end
        RM:InitializeSettings()
        CreateMarkButton()
        RM:RegisterOptions()
        RM.UpdateButton()
        frame:UnregisterEvent("ADDON_LOADED")
        return
    end
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" or event == "ROLE_CHANGED_INFORM"
        or event == "PLAYER_ROLES_ASSIGNED" or event == "PLAYER_SPECIALIZATION_CHANGED"
        or event == "LFG_ROLE_UPDATE" then
        RM.UpdateButton()
        ScheduleRoleRefresh()
    else
        RM.UpdateButton()
    end
end)

function RM:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "RhodansMarkersOptionsPanel", UIParent)
    panel.name = "Rhodan's Markers"
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Rhodan's Markers Options")

    local enabled = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -24)
    enabled.Text:SetText("Enable target marking in 5-player dungeons")
    enabled:SetChecked(RMS.enabled)
    enabled:SetScript("OnClick", function(self)
        RMS.enabled = self:GetChecked()
        RM.UpdateButton()
    end)
    RM.enabledCheckbox = enabled

    local function RoleRow(label, role, anchor, offset)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offset)
        check.Text:SetText("Enable " .. label .. " marker")
        check:SetChecked(RMS[role .. "Enabled"])
        check:SetScript("OnClick", function(self)
            RMS[role .. "Enabled"] = self:GetChecked()
            RM.UpdateButton()
        end)
        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 0, -5)
        UIDropDownMenu_SetWidth(dropdown, 150)
        UIDropDownMenu_Initialize(dropdown, function()
            for icon = 1, 8 do
                local info = UIDropDownMenu_CreateInfo()
                info.text = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. icon .. ":16|t " .. icon
                info.value = icon
                info.func = function()
                    if icon == RMS[(role == "tank" and "healer" or "tank") .. "Marker"] then
                        print("Tank and healer markers must differ.")
                        return
                    end
                    RMS[role .. "Marker"] = icon
                    UIDropDownMenu_SetSelectedValue(dropdown, icon)
                    RM.UpdateButton()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetSelectedValue(dropdown, RMS[role .. "Marker"])
        return dropdown
    end
    local tank = RoleRow("Tank", "tank", enabled, -28)
    local healer = RoleRow("Healer", "healer", tank, -38)

    local keyLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    keyLabel:SetPoint("TOPLEFT", healer, "BOTTOMLEFT", 20, -12)
    keyLabel:SetText("Marking keybind:")
    local keyButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    keyButton:SetSize(180, 25)
    keyButton:SetPoint("LEFT", keyLabel, "RIGHT", 12, 0)
    keyButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local listening = false
    local function StopCapture()
        listening = false
        keyButton:EnableKeyboard(false)
        if keyButton.SetPropagateKeyboardInput and not InCombatLockdown() then
            keyButton:SetPropagateKeyboardInput(true)
        end
        keyButton:SetText(RMS.keybind and RMS.keybind:gsub("-", "+") or "Unbound")
    end
    keyButton:SetScript("OnClick", function(self, mouseButton)
        if InCombatLockdown() then return end
        if mouseButton == "RightButton" then
            RMS.keybind = nil
            StopCapture()
            RM.UpdateButton()
            return
        end
        listening = true
        self:SetText("Press a key...")
        if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
        self:EnableKeyboard(true)
    end)
    keyButton:SetScript("OnKeyDown", function(_, key)
        if not listening then return end
        if key == "ESCAPE" then StopCapture(); return end
        if key == "BACKSPACE" or key == "DELETE" then
            RMS.keybind = nil
        elseif key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL"
            or key == "LALT" or key == "RALT" or key == "LMETA" or key == "RMETA" then
            return
        else
            local chord = ""
            if IsAltKeyDown() then chord = chord .. "ALT-" end
            if IsControlKeyDown() then chord = chord .. "CTRL-" end
            if IsShiftKeyDown() then chord = chord .. "SHIFT-" end
            if IsMetaKeyDown and IsMetaKeyDown() then chord = chord .. "META-" end
            RMS.keybind = chord .. key
        end
        StopCapture()
        RM.UpdateButton()
    end)
    keyButton:SetScript("OnHide", StopCapture)
    StopCapture()

    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -16)
    hint:SetWidth(400)
    hint:SetJustifyH("LEFT")
    hint:SetText("With no tank or healer targeted, left-click the button to target the tank or right-click to target the healer. Click again to mark. Left-click the key picker to set a binding; right-click it to clear. Disabled in combat.")
    return panel
end

function RM:RegisterOptions()
    local panel = self:CreateOptionsPanel()
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        RM.optionsID = category:GetID()
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

SLASH_RM1 = "/rm"
SlashCmdList.RM = function(msg)
    msg = (msg or ""):lower()
    if msg == "on" or msg == "off" then
        RMS.enabled = msg == "on"
        RM.enabledCheckbox:SetChecked(RMS.enabled)
        RM.UpdateButton()
    elseif Settings and Settings.OpenToCategory and RM.optionsID then
        Settings.OpenToCategory(RM.optionsID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("Rhodan's Markers")
    end
end
