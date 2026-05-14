-- Broker_NosyKeys - Settings
-- WoW Settings panel registration and saved-variables defaults.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local defaults = {
    -- Guild
    enableGuild         = true,     -- on by default; visibility is the whole point of the addon
    hideMyselfFromGuild = false,    -- privacy: broadcast "no key" to guild even if I have one
    maxGuildEntries     = 15,       -- cap rows in the Guild tooltip section
    guildOnlineOnly     = true,     -- filter to online guildies (most actionable for finding partners)
    guildSortMode       = "smart",  -- "smart" | "highest" | "alphabetic"
    -- Minimap
    showMinimapButton   = true,     -- on by default; users who want a clean minimap can opt out
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

    -- One-time DB migration: drop entries whose key isn't a proper Name-Realm string.
    -- Older sessions could store a bare "Artherio" when GetNormalizedRealmName briefly
    -- returned "" during early addon-load, leaving a ghost row alongside "Artherio-Elune".
    -- Cheap to run on every load; "All keys valid → zero deletions."
    for _, tbl in pairs({ db.alts, db.guildKeys }) do
        for charKey in pairs(tbl) do
            if type(charKey) ~= "string" or not charKey:match("^[^-]+-.+$") then
                tbl[charKey] = nil
            end
        end
    end

    ns.db = db

    -- The Settings checkbox is authoritative over the icon's visibility — sync it
    -- into LibDBIcon's persistent hide flag before registering. (LibDBIcon owns the
    -- db.minimapIcon table for icon position too; we only drive the hide field.)
    db.minimapIcon.hide = not db.showMinimapButton

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

    -- Escape hatch: wipe the locally stored guild data. New broadcasts repopulate
    -- the list automatically, so this is safe to use any time. Bypasses the
    -- weekly-reset rhythm for users who want a clean slate sooner.
    Settings.RegisterInitializer(category, CreateSettingsButtonInitializer(
        "Stored guild data",
        "Wipe",
        function()
            local guildKeys = Broker_NosyKeysDB and Broker_NosyKeysDB.guildKeys
            if not guildKeys then return end
            local n = 0
            for _ in pairs(guildKeys) do n = n + 1 end
            wipe(guildKeys)
            DEFAULT_CHAT_FRAME:AddMessage(
                ("|cffaaaaff[NosyKeys]|r cleared %d stored guild keystone entr%s.")
                :format(n, n == 1 and "y" or "ies"))
        end,
        "Drop all locally stored guildmate keystone data. New broadcasts from LibKeystone-aware addons (BigWigs, NosyKeys) will repopulate the list within minutes. Safe to use any time.",
        true))  -- addSearchTags: required non-nil in Midnight; true so the row matches "wipe" / "guild" in the settings search

    -- ── Section: Minimap ─────────────────────────────────────────────────────
    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Minimap", nil))

    local showMinimapSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showMinimapButton", "showMinimapButton", db,
        Settings.VarType.Boolean, "Show minimap button", defaults.showMinimapButton)
    showMinimapSetting:SetValueChangedCallback(function()
        db.minimapIcon.hide = not db.showMinimapButton
        local LDBIcon = LibStub("LibDBIcon-1.0", true)
        if LDBIcon then
            if db.showMinimapButton then
                LDBIcon:Show("Broker_NosyKeys")
            else
                LDBIcon:Hide("Broker_NosyKeys")
            end
        end
    end)
    Settings.CreateCheckbox(category, showMinimapSetting,
        "Show the NosyKeys minimap button. On by default. Most users with a broker bar host (Arcana, ElvUI, Bazooka, etc.) prefer turning this off to keep the minimap edge clear.")

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
