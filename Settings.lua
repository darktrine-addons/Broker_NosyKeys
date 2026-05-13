-- Broker_NosyKeys - Settings
-- WoW Settings panel registration and saved-variables defaults.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local defaults = {
    -- Guild
    enableGuild         = false,    -- opt-in: subscribe to guild keystone broadcasts
    hideMyselfFromGuild = false,    -- privacy: broadcast "no key" to guild even if I have one
    maxGuildEntries     = 15,       -- cap rows in the Guild tooltip section
    guildOnlineOnly     = true,     -- filter to online guildies (most actionable for finding partners)
    guildSortMode       = "smart",  -- "smart" | "highest" | "alphabetic"
    -- Tooltip sections
    showParty           = true,
    showAlts            = true,
}

local sf = CreateFrame("Frame")
sf:RegisterEvent("ADDON_LOADED")
sf:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    Broker_NosyKeysDB = Broker_NosyKeysDB or {}
    local db = Broker_NosyKeysDB
    db.minimapIcon = db.minimapIcon or { hide = false }  -- sub-table; managed by LibDBIcon
    db.alts        = db.alts        or {}                -- Name-NormalizedRealm → snapshot
    db.guildKeys   = db.guildKeys   or {}                -- Name-NormalizedRealm → snapshot
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    ns.db = db

    -- Register minimap button (LibDBIcon manages show/hide via its own right-click menu).
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and ns.broker then
        LibDBIcon:Register("Broker_NosyKeys", ns.broker, db.minimapIcon)
    end

    -- Apply the persisted guild-hide preference now that db is available.
    if ns.ApplyGuildHidden then ns.ApplyGuildHidden() end
    -- Kick off an initial guild request if the user has guild visibility on.
    if ns.RefreshGuild then ns.RefreshGuild() end

    -- ── Settings panel ────────────────────────────────────────────────────────

    local category = Settings.RegisterVerticalLayoutCategory("NosyKeys")

    -- ── Section: Guild ───────────────────────────────────────────────────────
    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Guild", nil))

    local enableGuildSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_enableGuild", "enableGuild", db,
        Settings.VarType.Boolean, "Show guild keys", defaults.enableGuild)
    enableGuildSetting:SetValueChangedCallback(function()
        if ns.RefreshGuild then ns.RefreshGuild() end
    end)
    Settings.CreateCheckbox(category, enableGuildSetting,
        "List guildmates' keys in the tooltip. Requires a LibKeystone-aware addon on both ends (e.g. BigWigs or another NosyKeys install).")

    local hideMineSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_hideMyselfFromGuild", "hideMyselfFromGuild", db,
        Settings.VarType.Boolean, "Hide my key from guild", defaults.hideMyselfFromGuild)
    hideMineSetting:SetValueChangedCallback(function()
        if ns.ApplyGuildHidden then ns.ApplyGuildHidden() end
    end)
    Settings.CreateCheckbox(category, hideMineSetting,
        "Broadcast \"no key\" to guildmates even when you have one. Party broadcasts are unaffected.")

    local maxGuildSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_maxGuildEntries", "maxGuildEntries", db,
        Settings.VarType.Number, "Max guild entries shown", defaults.maxGuildEntries)
    Settings.CreateDropdown(category, maxGuildSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add(10,   "Top 10")
        c:Add(15,   "Top 15")
        c:Add(25,   "Top 25")
        c:Add(50,   "Top 50")
        c:Add(9999, "All")
        return c:GetData()
    end, "Cap on the number of guild rows in the tooltip, applied after the sort.")

    local onlineOnlySetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_guildOnlineOnly", "guildOnlineOnly", db,
        Settings.VarType.Boolean, "Online guildmates only", defaults.guildOnlineOnly)
    Settings.CreateCheckbox(category, onlineOnlySetting,
        "Filter the Guild section to guildmates currently online. Off shows everyone whose key we've received this week, online or not.")

    local sortModeSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_guildSortMode", "guildSortMode", db,
        Settings.VarType.String, "Sort guild by", defaults.guildSortMode)
    Settings.CreateDropdown(category, sortModeSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add("smart",      "Smart (near my key level)")
        c:Add("highest",    "Highest first")
        c:Add("alphabetic", "Alphabetic by name")
        return c:GetData()
    end, "How to order the Guild list before the cap is applied. \"Smart\" sorts by closeness to your own key level (or weekly best when you have no key), so the people you could actually run with surface first.")

    -- ── Section: Tooltip ─────────────────────────────────────────────────────
    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Tooltip", nil))

    local showPartySetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showParty", "showParty", db,
        Settings.VarType.Boolean, "Show party", defaults.showParty)
    Settings.CreateCheckbox(category, showPartySetting,
        "Include the Party section while you are in a 5-man.")

    local showAltsSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showAlts", "showAlts", db,
        Settings.VarType.Boolean, "Show alts", defaults.showAlts)
    Settings.CreateCheckbox(category, showAltsSetting,
        "Include the Alts section listing other characters on your account who have engaged with Mythic+ this season.")

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategoryID = category:GetID()
end)
