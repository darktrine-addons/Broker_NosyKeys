-- Broker_NosyKeys - Core
-- LDB data broker plugin: mythic+ keystones for you, alts, party, and (opt-in) guild.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
-- The BigWigs packager substitutes @project-version@ at build time. In a raw
-- source checkout the literal placeholder reaches us instead; show "dev" so
-- the footer reads cleanly when running directly from the working tree.
if addonVersion:sub(1, 1) == "@" then addonVersion = "dev" end

local LDB = LibStub("LibDataBroker-1.1")
local broker = LDB:NewDataObject("Broker_NosyKeys", {
    type  = "data source",
    label = "NosyKeys",
    icon  = "Interface\\Icons\\inv_relics_hourglass",
    text  = "...",
})
ns.broker = broker  -- exposed for LibDBIcon registration in Settings.lua

-- ── tooltip colors ────────────────────────────────────────────────────────────
-- teal for static labels, white for dynamic values, orange for interaction hints,
-- grey for section headers and "no key" placeholders.
local CL_r, CL_g, CL_b = 0.40, 0.80, 0.80   -- teal   (label)
local CV_r, CV_g, CV_b = 1.00, 1.00, 1.00   -- white  (value)
local CH_r, CH_g, CH_b = 1.00, 0.60, 0.10   -- orange (hint keyword)
local CS_r, CS_g, CS_b = 0.70, 0.70, 0.70   -- grey   (section header / muted)

-- M+ key-level color tiers; mirrors Blizzard's keystone item-quality tinting.
local function KeyLevelColor(level)
    if not level or level <  2 then return CV_r, CV_g, CV_b end
    if level >= 20 then return 1.00, 0.25, 0.78   -- artifact pink
    elseif level >= 15 then return 1.00, 0.50, 0.00 -- legendary orange
    elseif level >= 10 then return 0.64, 0.21, 0.93 -- epic purple
    elseif level >=  5 then return 0.00, 0.44, 0.87 -- rare blue
    else                  return 0.12, 1.00, 0.00 -- uncommon green
    end
end

-- ── key info ──────────────────────────────────────────────────────────────────

-- Returns (mapID, level, dungeonName) for the player's owned keystone, or nil.
local function GetOwnedKey()
    local mapID = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneChallengeMapID
                  and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel
                  and C_MythicPlus.GetOwnedKeystoneLevel()
    if not mapID or mapID == 0 or not level or level == 0 then return nil end
    local name = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo
                 and C_ChallengeMode.GetMapUIInfo(mapID)
    return mapID, level, name or ("map " .. mapID)
end

-- Returns the player's current-season M+ rating, or 0 when unavailable.
local function GetMyRating()
    if not C_PlayerInfo or not C_PlayerInfo.GetPlayerMythicPlusRatingSummary then return 0 end
    local s = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    return (s and s.currentSeasonScore) or 0
end

-- Returns (weeklyRuns, weeklyBest) from the Great Vault's M+ activities.
-- weeklyRuns is your run count this week (drives vault slot unlocks at 1/4/8 runs);
-- weeklyBest is the highest key level that's currently driving a vault reward slot.
-- Both are 0 when no qualifying runs have been completed this week.
local function GetVaultInfo()
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return 0, 0 end
    local activities = C_WeeklyRewards.GetActivities(
        Enum and Enum.WeeklyRewardChestThresholdType
        and Enum.WeeklyRewardChestThresholdType.Activities)
    if type(activities) ~= "table" then return 0, 0 end
    local runs, bestLevel = 0, 0
    for _, a in ipairs(activities) do
        if (a.progress or 0) > runs      then runs      = a.progress end
        if (a.level    or 0) > bestLevel then bestLevel = a.level    end
    end
    return runs, bestLevel
end

-- Returns the live |Hkeystone:...|h hyperlink for the player's owned keystone item.
-- Scans bags 0-4 (backpack + standard bags); returns nil if no keystone is held.
-- Falls back gracefully when item APIs are missing (PTR/beta).
local function GetOwnedKeystoneLink()
    if not C_Container or not C_Item or not C_Item.IsItemKeystoneByID then return nil end
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and C_Item.IsItemKeystoneByID(itemID) then
                return C_Container.GetContainerItemLink(bag, slot)
            end
        end
    end
    return nil
end

-- ── character identity ───────────────────────────────────────────────────────
-- Always "Name-NormalizedRealm" so connected-realm collisions are impossible and
-- the format matches what LibKeystone hands us for party/guild members.

local function CharLabel()
    local name  = UnitName("player") or "?"
    local realm = GetNormalizedRealmName() or ""
    return realm ~= "" and (name .. "-" .. realm) or name
end

-- Normalizes the name LibKeystone hands us (Ambiguate(sender, "none")) into our
-- canonical Name-NormalizedRealm form. Cross-realm senders arrive as "Name-Realm Name"
-- with spaces in the realm; same-realm senders arrive as bare "Name".
local function NormalizeRecvName(rawName)
    if not rawName or rawName == "" then return nil end
    local name, realm = rawName:match("^([^-]+)-(.+)$")
    if name and realm then
        return name .. "-" .. (realm:gsub("%s+", ""))
    end
    return rawName .. "-" .. (GetNormalizedRealmName() or "")
end

-- Returns Name-NormalizedRealm for a party/raid unit token; nil if the unit isn't present.
local function UnitLabel(unit)
    local name, realm = UnitFullName(unit)
    if not name then return nil end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName() or ""
    else
        realm = realm:gsub("%s+", "")
    end
    return name .. "-" .. realm
end

-- ── alt store ─────────────────────────────────────────────────────────────────

-- Persists the current character's keystone snapshot, but only if there's anything
-- worth showing (a key, or a non-zero seasonal rating). This keeps bank/level-1
-- alts out of the tooltip.
local function RecordSelf()
    if not ns.db then return end
    local mapID, level, mapName = GetOwnedKey()
    local rating                = GetMyRating()
    local weeklyRuns, weeklyBest = GetVaultInfo()
    -- Skip pure non-M+ characters; vault progress alone also qualifies.
    if not level and rating == 0 and weeklyBest == 0 then return end

    local _, classFile = UnitClass("player")
    ns.db.alts = ns.db.alts or {}
    ns.db.alts[CharLabel()] = {
        mapID      = mapID,
        level      = level,
        mapName    = mapName,
        rating     = rating,
        weeklyRuns = weeklyRuns,
        weeklyBest = weeklyBest,
        classFile  = classFile,
        lastSeen   = time(),
    }
end
ns.RecordSelf = RecordSelf

-- Returns a sorted list of {charKey, entry} tuples excluding the current character.
-- Sort: highest key level first, then highest rating; "no key" alts fall to the bottom.
-- Uses a transient wrapper so we never mutate the stored alt records.
local function GetAltEntries()
    if not ns.db or not ns.db.alts then return {} end
    local me, list = CharLabel(), {}
    for charKey, entry in pairs(ns.db.alts) do
        if charKey ~= me then
            list[#list + 1] = { charKey = charKey, entry = entry }
        end
    end
    table.sort(list, function(a, b)
        local al, bl = a.entry.level or 0, b.entry.level or 0
        if al ~= bl then return al > bl end
        return (a.entry.rating or 0) > (b.entry.rating or 0)
    end)
    return list
end
ns.GetAltEntries = GetAltEntries

-- ── party store ───────────────────────────────────────────────────────────────
-- Transient (not SavedVariables): party data only meaningful while the party exists.
-- partyKeys is populated by LibKeystone callbacks; partyRoster is rebuilt from unit
-- tokens on roster updates and supplies class colors plus the "still in party" filter.

local partyKeys   = {}  -- Name-Realm → { level, mapID, mapName, rating }
local partyRoster = {}  -- Name-Realm → { classFile }

local function RefreshPartyRoster()
    wipe(partyRoster)
    -- Mythic+ runs through party only, not raid. Outside a party, drop everything.
    if not IsInGroup() or IsInRaid() then
        wipe(partyKeys)
        return
    end
    local n = GetNumGroupMembers()
    for i = 0, n - 1 do
        local unit = (i == 0) and "player" or ("party" .. i)
        if UnitExists(unit) then
            local label = UnitLabel(unit)
            local _, classFile = UnitClass(unit)
            if label then
                partyRoster[label] = { classFile = classFile }
            end
        end
    end
    -- Drop key entries for members who have left the party.
    for label in pairs(partyKeys) do
        if not partyRoster[label] then partyKeys[label] = nil end
    end
end
ns.RefreshPartyRoster = RefreshPartyRoster

-- LibKeystone delivers (level, mapID, rating, name, channel). Self callbacks
-- arrive too (channel="PARTY" or "GUILD" when we call Request) — filtered out
-- here so sections only list other people.
local function OnKeystoneRecv(level, mapID, rating, playerName, channel)
    local label = NormalizeRecvName(playerName)
    if not label or label == CharLabel() then return end

    local hasKey = level and level > 0 and mapID and mapID > 0
    local mapName
    if hasKey and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        mapName = C_ChallengeMode.GetMapUIInfo(mapID)
    end
    local snapshot = {
        level   = hasKey and level   or nil,
        mapID   = hasKey and mapID   or nil,
        mapName = mapName,
        rating  = rating or 0,
    }

    if channel == "PARTY" then
        partyKeys[label] = snapshot
    elseif channel == "GUILD" then
        -- Persist guild data in SavedVariables so it survives /reload (keys are valid
        -- across the whole week). The weekly-reset hook wipes the table.
        if ns.db and ns.db.enableGuild then
            snapshot.lastSeen     = time()
            ns.db.guildKeys       = ns.db.guildKeys or {}
            ns.db.guildKeys[label] = snapshot
        end
    end
end

local LKS = LibStub and LibStub("LibKeystone", true)
if LKS then LKS.Register(ns, OnKeystoneRecv) end

local function GetPartyEntries()
    local list = {}
    for label, classInfo in pairs(partyRoster) do
        if label ~= CharLabel() then
            list[#list + 1] = {
                charKey   = label,
                classFile = classInfo.classFile,
                entry     = partyKeys[label],  -- may be nil if they haven't responded
            }
        end
    end
    table.sort(list, function(a, b)
        local ae, be = a.entry, b.entry
        local al = (ae and ae.level) or 0
        local bl = (be and be.level) or 0
        if al ~= bl then return al > bl end
        return ((ae and ae.rating) or 0) > ((be and be.rating) or 0)
    end)
    return list
end
ns.GetPartyEntries = GetPartyEntries

-- ── guild store ───────────────────────────────────────────────────────────────
-- ns.db.guildKeys is the persisted store (keyed by Name-NormalizedRealm). guildClass
-- is a transient name→class lookup built from the guild roster, used to color
-- entries at render time. Regular guilds are realm-bound, so the bare first-name
-- segment is a sufficient lookup key.

local guildClass  = {}  -- baseName (pre-dash) → classFile
local guildOnline = {}  -- baseName → true when currently online

-- Asks the server for a guild roster refresh. Results arrive asynchronously and
-- trigger GUILD_ROSTER_UPDATE, which is where we rebuild the local lookups.
local function RequestGuildRoster()
    if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    end
end

-- Rebuilds name → class and name → online lookups from whatever roster data is
-- currently loaded. Kept separate from the request so GUILD_ROSTER_UPDATE doesn't
-- trigger another request in a feedback loop. Online flag comes from position 9
-- of GetGuildRosterInfo.
local function RebuildGuildLookups()
    wipe(guildClass)
    wipe(guildOnline)
    if not IsInGuild() then return end
    local n = GetNumGuildMembers() or 0
    for i = 1, n do
        local fullName, _, _, _, _, _, _, _, online, _, classFile = GetGuildRosterInfo(i)
        if fullName then
            local baseName = fullName:match("^([^-]+)") or fullName
            guildClass[baseName]  = classFile
            guildOnline[baseName] = online and true or false
        end
    end
end
ns.RequestGuildRoster  = RequestGuildRoster
ns.RebuildGuildLookups = RebuildGuildLookups

-- Apply the user's "hide my key from guild" preference to LibKeystone. Affects only
-- the GUILD channel; PARTY broadcasts always carry the real key.
local function ApplyGuildHidden()
    if LKS and LKS.SetGuildHidden and ns.db then
        LKS.SetGuildHidden(ns.db.hideMyselfFromGuild and true or false)
    end
end
ns.ApplyGuildHidden = ApplyGuildHidden

-- Called when the user toggles "Show guild keys" or on guild join. When the setting
-- is on and we're in a guild, request a fresh broadcast. When the setting is off,
-- drop the stored data so nothing lingers.
local function RefreshGuild()
    if not ns.db then return end
    if ns.db.enableGuild and IsInGuild() then
        RequestGuildRoster()
        RebuildGuildLookups()  -- use whatever roster data we already have
        if LKS then LKS.Request("GUILD") end
    elseif not ns.db.enableGuild and ns.db.guildKeys then
        wipe(ns.db.guildKeys)
    end
end
ns.RefreshGuild = RefreshGuild

-- "no key" entries (level=nil/0) always sink to the bottom regardless of sort mode —
-- they aren't actionable for finding a partner, but we keep them as a presence signal.
local function NoKeyBottom(al, bl)
    return (al == 0) ~= (bl == 0), al ~= 0
end

local function SortByHighest(a, b)
    local al, bl = a.entry.level or 0, b.entry.level or 0
    if al ~= bl then return al > bl end
    return (a.entry.rating or 0) > (b.entry.rating or 0)
end

-- Reference key level for the "smart" sort: prefer current key, fall back to
-- weekly best (you can run what you ran last week). Returns 0 when neither is known,
-- which causes smart sort to degrade gracefully to "highest first" rather than guess.
local function GetReferenceLevel()
    local _, level         = GetOwnedKey()
    local _, weeklyBest    = GetVaultInfo()
    return math.max(level or 0, weeklyBest or 0)
end

-- Returns a filtered, sorted, capped list of {charKey, classFile, entry} tuples.
-- Filter: ns.db.guildOnlineOnly drops entries whose owners are offline per roster;
--         party members are also dropped to avoid duplicating their row from the
--         Party section (skipped when Party is hidden, so no data is lost).
-- Sort:   ns.db.guildSortMode is "smart" | "highest" | "alphabetic".
local function GetGuildEntries()
    if not ns.db or not ns.db.enableGuild or not ns.db.guildKeys then return {} end
    local me, list      = CharLabel(), {}
    local onlineOnly    = ns.db.guildOnlineOnly
    local partyShown    = (ns.db.showParty ~= false) and (not IsInRaid()) and IsInGroup()
    for charKey, entry in pairs(ns.db.guildKeys) do
        if charKey ~= me and not (partyShown and partyRoster[charKey]) then
            local baseName = charKey:match("^([^-]+)") or charKey
            if not onlineOnly or guildOnline[baseName] then
                list[#list + 1] = {
                    charKey   = charKey,
                    classFile = guildClass[baseName],
                    entry     = entry,
                }
            end
        end
    end

    local mode = ns.db.guildSortMode or "smart"
    if mode == "alphabetic" then
        table.sort(list, function(a, b)
            local al, bl = a.entry.level or 0, b.entry.level or 0
            local split, prefer = NoKeyBottom(al, bl)
            if split then return prefer end
            return a.charKey < b.charKey
        end)
    elseif mode == "smart" then
        local ref = GetReferenceLevel()
        if ref == 0 then
            table.sort(list, SortByHighest)  -- no reference → degrade gracefully
        else
            table.sort(list, function(a, b)
                local al, bl = a.entry.level or 0, b.entry.level or 0
                local split, prefer = NoKeyBottom(al, bl)
                if split then return prefer end
                local ad, bd = math.abs(al - ref), math.abs(bl - ref)
                if ad ~= bd then return ad < bd end
                if al ~= bl then return al > bl end  -- equidistant: prefer the harder key
                return (a.entry.rating or 0) > (b.entry.rating or 0)  -- stable tiebreak
            end)
        end
    else  -- "highest"
        table.sort(list, SortByHighest)
    end

    local cap = ns.db.maxGuildEntries or 15
    if cap > 0 and #list > cap then
        for i = #list, cap + 1, -1 do list[i] = nil end
    end
    return list
end
ns.GetGuildEntries = GetGuildEntries

-- ── weekly reset ──────────────────────────────────────────────────────────────
-- Tuesday/Wednesday rollover varies by region; let Blizzard tell us instead of
-- hand-rolling a day-of-week check. nextResetTimestamp is lazily initialized.

local function NextWeeklyResetTime()
    local secs = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset
                 and C_DateAndTime.GetSecondsUntilWeeklyReset() or 0
    return time() + secs
end

-- Bumps the saved reset timestamp when the week has rolled over. Returns true on
-- an actual rollover (first-ever load returns false). On rollover, guild keys
-- are wiped — guildmates' broadcasts from last week are stale once everyone has
-- had a fresh weekly key issued.
local function CheckWeeklyReset()
    if not ns.db then return false end
    local now = time()
    local nextReset = ns.db.nextResetTimestamp or 0
    if now >= nextReset then
        local hadPrevious = nextReset ~= 0
        ns.db.nextResetTimestamp = NextWeeklyResetTime()
        if hadPrevious and ns.db.guildKeys then
            wipe(ns.db.guildKeys)
        end
        return hadPrevious
    end
    return false
end
ns.CheckWeeklyReset = CheckWeeklyReset

-- ── broker text ───────────────────────────────────────────────────────────────

local function UpdateText()
    local _, level, name = GetOwnedKey()
    if level and name then
        broker.text = name .. "  +" .. level
    else
        broker.text = "no key"
    end
end
ns.UpdateText = UpdateText

-- ── event frame ───────────────────────────────────────────────────────────────

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
f:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
f:RegisterEvent("MYTHIC_PLUS_CURRENT_AFFIX_UPDATE")
f:RegisterEvent("WEEKLY_REWARDS_UPDATE")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_GUILD_UPDATE")
f:RegisterEvent("GUILD_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            self:UnregisterEvent("ADDON_LOADED")
        end
        return
    end
    if event == "PLAYER_ENTERING_WORLD" and C_MythicPlus and C_MythicPlus.RequestMapInfo then
        -- C_ChallengeMode.GetMapUIInfo returns nil until the client has fetched map data.
        C_MythicPlus.RequestMapInfo()
    end
    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        RefreshPartyRoster()
        -- LibKeystone throttles internally; safe to call eagerly.
        if LKS then LKS.Request("PARTY") end
    end
    if event == "GUILD_ROSTER_UPDATE" then
        -- Roster data has arrived from the server; refresh our class-color lookup.
        -- Do NOT call GuildRoster() here or we loop on our own request.
        RebuildGuildLookups()
    elseif event == "PLAYER_GUILD_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        if ns.db and ns.db.enableGuild then
            RequestGuildRoster()                   -- async; class map rebuilds on the response
            if LKS and IsInGuild() then
                LKS.Request("GUILD")               -- LibKeystone throttles internally
            end
        end
    end
    CheckWeeklyReset()
    RecordSelf()
    UpdateText()
end)

-- ── tooltip ───────────────────────────────────────────────────────────────────

-- Look up the class color for an alt entry; returns (r, g, b) or white if unknown.
local function ClassColor(classFile)
    if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return c.r, c.g, c.b
    end
    return CV_r, CV_g, CV_b
end

-- Desaturate a color toward grey; used to mark alts that haven't logged in this week.
local function Fade(r, g, b)
    return r * 0.45 + 0.30, g * 0.45 + 0.30, b * 0.45 + 0.30
end

local STALE_SECONDS = 7 * 24 * 60 * 60  -- one week without seeing the alt

-- Builds the right-column text + color for a character row. Optional vault and
-- rating segments are appended with whitespace separators. weeklyBest=nil omits
-- the vault segment entirely (used for Party/Guild, since LibKeystone doesn't
-- transmit it). dim=true desaturates the color for stale entries.
local function FormatRow(level, mapName, rating, weeklyBest, dim)
    local s, rr, rg, rb
    if level and mapName then
        s            = mapName .. "  +" .. level
        rr, rg, rb = KeyLevelColor(level)
    else
        s            = "no key"
        rr, rg, rb = CS_r, CS_g, CS_b
    end
    if weeklyBest and weeklyBest > 0 then
        s = s .. "    vault +" .. weeklyBest
    end
    if rating and rating > 0 then
        s = s .. "    " .. rating
    end
    if dim then rr, rg, rb = Fade(rr, rg, rb) end
    return s, rr, rg, rb
end

broker.OnEnter = function(self)
    -- Anchor below the bar when in the top half, above when in the bottom half.
    local _, frameY = self:GetCenter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    if frameY and frameY > (GetScreenHeight() / 2) then
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    else
        GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
    end

    GameTooltip:SetText("NosyKeys", CV_r, CV_g, CV_b)

    -- ── You ───────────────────────────────────────────────────────────────────
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("You", CS_r, CS_g, CS_b)

    local _, level, name        = GetOwnedKey()
    local rating                = GetMyRating()
    local _, weeklyBest         = GetVaultInfo()
    local right, rr, rg, rb     = FormatRow(level, name, rating, weeklyBest, false)
    GameTooltip:AddDoubleLine(CharLabel(), right, CV_r, CV_g, CV_b, rr, rg, rb)

    local db = ns.db or {}

    -- ── Party ────────────────────────────────────────────────────────────────
    -- Only render when actually in a party AND at least one party member is known.
    if db.showParty ~= false then
        local party = GetPartyEntries()
        if #party > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Party", CS_r, CS_g, CS_b)
            for _, item in ipairs(party) do
                local nr, ng, nb = ClassColor(item.classFile)
                local e = item.entry
                local right, rr, rg, rb
                if e then
                    right, rr, rg, rb = FormatRow(e.level, e.mapName, e.rating, nil, false)
                else
                    -- Roster member who hasn't responded — likely no LibKeystone-aware addon.
                    right, rr, rg, rb = "—", CS_r, CS_g, CS_b
                end
                GameTooltip:AddDoubleLine(item.charKey, right, nr, ng, nb, rr, rg, rb)
            end
        end
    end

    -- ── Alts ─────────────────────────────────────────────────────────────────
    if db.showAlts ~= false then
        local alts = GetAltEntries()
        if #alts > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Alts", CS_r, CS_g, CS_b)
            local now = time()
            for _, item in ipairs(alts) do
                local e = item.entry
                local stale = (now - (e.lastSeen or 0)) > STALE_SECONDS
                local nr, ng, nb = ClassColor(e.classFile)
                if stale then nr, ng, nb = Fade(nr, ng, nb) end
                local right, rr, rg, rb = FormatRow(e.level, e.mapName, e.rating, e.weeklyBest, stale)
                GameTooltip:AddDoubleLine(item.charKey, right, nr, ng, nb, rr, rg, rb)
            end
        end
    end

    -- ── Guild ────────────────────────────────────────────────────────────────
    if db.enableGuild then
        local guild = GetGuildEntries()
        if #guild > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Guild", CS_r, CS_g, CS_b)
            for _, item in ipairs(guild) do
                local nr, ng, nb = ClassColor(item.classFile)
                local e = item.entry
                local right, rr, rg, rb = FormatRow(e.level, e.mapName, e.rating, nil, false)
                GameTooltip:AddDoubleLine(item.charKey, right, nr, ng, nb, rr, rg, rb)
            end
        end
    end

    -- ── Interaction hints ────────────────────────────────────────────────────
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Click",            "open the keystone holder", CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Shift-Click",      "link your key to chat",    CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Shift-RightClick", "open settings",            CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)

    -- ── Footer: addon name + version, right-aligned, faint grey ──────────────
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("", "NosyKeys  v" .. addonVersion, 0, 0, 0, 0.45, 0.45, 0.45)

    GameTooltip:Show()
end

broker.OnLeave = function(self)
    GameTooltip:Hide()
end

-- ── click handlers ────────────────────────────────────────────────────────────

local function LinkKeyToChat()
    local _, level, name = GetOwnedKey()
    if not level then return end
    local link = GetOwnedKeystoneLink()
    local editBox = ChatEdit_ChooseBoxForSend()
    ChatEdit_ActivateChat(editBox)
    -- Hyperlink renders as a clickable keystone item in chat; plain-text fallback
    -- keeps the feature working even if the bag scan fails (PTR/beta or Timerunning oddities).
    editBox:Insert(link or (name .. " +" .. level))
end

local function OpenKeystoneHolder()
    -- Blizzard_ChallengesUI is load-on-demand; pull it in before toggling.
    if not ToggleChallengesUI and C_AddOns and C_AddOns.LoadAddOn then
        C_AddOns.LoadAddOn("Blizzard_ChallengesUI")
    end
    if ToggleChallengesUI then ToggleChallengesUI() end
end

broker.OnClick = function(self, button)
    if button == "RightButton" then
        if IsShiftKeyDown() and ns.settingsCategoryID then
            Settings.OpenToCategory(ns.settingsCategoryID)
        end
        return
    end
    if button ~= "LeftButton" then return end

    if IsShiftKeyDown() then
        LinkKeyToChat()
    else
        OpenKeystoneHolder()
    end
end
