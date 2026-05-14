# NosyKeys

**A lean Mythic+ keystone tracker. A single tooltip covers you, your party, your alts, and your guild — no separate window, no custom comm protocol.** Talks [LibKeystone](https://github.com/BigWigsMods/LibKeystone), so BigWigs guildmates appear automatically.

**Open the tooltip from your broker bar or from the built-in minimap button** — both are first-class entry points, and either can be toggled off if you only want one. No broker bar host? No problem. Have one already (Arcana, ElvUI, Bazooka, TitanPanel...)? Drop the minimap icon and use the bar entry instead.

Retail only. Requires Midnight (Interface 120005+); a broker bar host is optional.

## Is this for you?

**Yes, probably** — if you:

- Run Mythic+ on multiple characters and want to see all their keys in one place
- Want to know who in your party has what key without asking
- Already use BigWigs (LibKeystone interop is free; nothing to configure)
- Prefer a hover-tooltip over a dedicated window — whether you reach it via a broker bar or the minimap is up to you

**Probably not** — if you:

- Want a sortable spreadsheet-style window listing every guildmate (use [AstralKeys](https://www.curseforge.com/wow/addons/astral-keys))
- Want in-run tools like death tracking or enemy-forces precision (use [AngryKeystones](https://www.curseforge.com/wow/addons/angry-keystones))
- Run M+ exclusively in pre-formed Discord groups (you don't need keystone discovery)
- Need AstralKeys-protocol interop for non-LibKeystone guilds (NosyKeys is LibKeystone-native by design)

## Features

- **Broker bar text**: `<DungeonName>  +<Level>` for your current key, or `no key`
- **Tooltip sections**: *You*, *Party* (in a 5-man), *Alts* (other characters on your account), *Guild*
- **Vault progress**: each row appends `vault +<N>` when the character has weekly M+ progress, alongside current key and seasonal rating
- **LibKeystone-powered comm**: party and guild keys arrive automatically from any LibKeystone-aware addon (BigWigs, other NosyKeys installs)
- **Class-colored names**, **key-tier-colored levels** (green / blue / purple / orange / pink mirroring Blizzard's keystone item-quality), and **stale-fade** for alts not seen this week
- **Smart guild sort** *(default)*: prioritizes guildmates whose key level is closest to yours — so the people you could actually run with surface first, not the +20 pushers at the top of a fixed-cap list
- **Online-first filtering**: by default the Guild section lists only guildmates currently online; the header reads `Guild  (online only)` while the filter is active
- **Alt-hold reveal**: hold the **Alt** key while the tooltip is open to temporarily bypass the online-only filter and the *Show guild keys* toggle — see everyone whose key has been broadcast this week without flipping a setting. Cap still applies.
- **Privacy**: per-channel guild-hide (broadcast "no key" to guildmates while keeping party broadcasts intact)
- **Click handlers**: open the keystone holder · Shift-Click to insert your keystone hyperlink into chat · Shift-RightClick to open settings
- **Weekly reset aware**: guild data wipes on rollover; alts persist with stale-fade after a week unseen
- **Optional minimap button**: on by default, one-toggle off in settings for those keeping the minimap edge clear
- **Native Settings panel**: all options in WoW's built-in AddOns settings (Escape → Options → AddOns → NosyKeys)

## Installation

The recommended path is a package manager: **CurseForge app**, **WowUp**, or the **Wago app** — search for "NosyKeys" and one-click install.

For manual installation:

1. Download the latest release zip from [GitHub Releases](https://github.com/darktrine-addons/Broker_NosyKeys/releases), CurseForge, or Wago.io
2. Extract the `Broker_NosyKeys` folder into your addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or `/reload`

## Click Interactions

Interactions work identically on the broker bar entry and the minimap button — whichever you keep visible:

- **Left-click** — Open the keystone holder (lazy-loads `Blizzard_ChallengesUI` if needed)
- **Shift-Left-click** — Insert your keystone hyperlink into the active chat box (plain-text fallback if the bag scan can't find it)
- **Shift-Right-click** — Open the Settings panel
- **Hold Alt while tooltip is open** — Temporarily reveal all stored guild keys (bypasses the *Online guildmates only* filter and the *Show guild keys* toggle for the duration of the hold)

## Configuration

Open the settings panel via **Shift-Right-click** on the broker button, or via **Escape → Options → AddOns → NosyKeys**.

### Guild

- **Show guild keys** *(default: On)* — Subscribe to guildmates' keystone broadcasts and list them in the tooltip. Both sides need a LibKeystone-aware addon installed (BigWigs counts; another NosyKeys install counts). Toggle off if you only care about your own party.
- **Hide my key from guild** *(default: Off)* — Broadcast "no key" to guildmates even when you have one. Party broadcasts are unaffected. Toggling *Show guild keys* off stops displaying guild keys; it does **not** stop broadcasting your own — this setting is the one that does.
- **Max guild entries shown** *(default: Top 15)* — Cap on the number of guild rows in the tooltip, applied after the sort.
- **Online guildmates only** *(default: On)* — Filter the Guild section to guildmates currently online. With a large guild this is usually what you want. Off shows everyone whose key arrived this week.
- **Sort guild by** *(default: Smart)* — How to order before the cap is applied:
  - *Smart (near my key level)* — distance-from-your-key-level ascending; uses your weekly best as the reference when you have no current key. Degrades to *Highest first* when neither is known.
  - *Highest first* — by key level descending, then by rating.
  - *Alphabetic by name* — by `Name-Realm`.
- **Stored guild data — Wipe** — One-click escape hatch that drops every locally stored guildmate entry. New broadcasts repopulate the list within minutes, so this is safe to use any time. The standard weekly-reset wipe still runs automatically.

### Minimap

- **Show minimap button** *(default: On)* — Show the NosyKeys minimap button. Most users with a broker bar host (Arcana, ElvUI, Bazooka, etc.) prefer turning this off to keep the minimap edge clear.

### Tooltip

- **Show party** *(default: On)* — Include the Party section while you are in a 5-man.
- **Show alts** *(default: On)* — Include the Alts section listing other characters on your account who have engaged with Mythic+ this season.

## Technical Details

### File Structure

- `Broker_NosyKeys.toc` — Addon metadata and load order
- `Core.lua` — Broker object, key/vault info, party + guild stores, tooltip, click handlers
- `Settings.lua` — Saved-variable defaults and Settings panel registration
- `Locales/Locales.xml` — Locale file manifest (enUS baseline)
- `Libs/` — bundled libraries: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0, LibKeystone

### Events Handled

- `ADDON_LOADED` — Initialize saved variables, register LibDBIcon, build Settings panel
- `PLAYER_ENTERING_WORLD` — Request M+ map info, request party/guild keys
- `PLAYER_LOGOUT` — Capture final per-character snapshot
- `BAG_UPDATE_DELAYED` / `CHALLENGE_MODE_COMPLETED` / `CHALLENGE_MODE_MAPS_UPDATE` / `MYTHIC_PLUS_CURRENT_AFFIX_UPDATE` — Refresh own keystone state
- `WEEKLY_REWARDS_UPDATE` — Refresh vault info (weekly best level, run count)
- `GROUP_ROSTER_UPDATE` — Refresh party roster, request party keys
- `PLAYER_GUILD_UPDATE` / `GUILD_ROSTER_UPDATE` — Request guild roster, request guild keys (if enabled)
- `CHAT_MSG_ADDON` (via LibKeystone) — Receive party/guild keystone broadcasts

### Saved Variables

- `Broker_NosyKeysDB` — all settings, the LibDBIcon minimap position sub-table, per-character alt snapshots, and persisted guild key data (wiped on weekly reset)

## Compatibility

- **WoW Version**: Retail (Midnight, Interface 120005+)
- **Dependencies**: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0, LibKeystone (all bundled)
- **Broker display**: **optional** — any LDB-compatible host works (Arcana, ElvUI, Bazooka, Broker2FuBar, TitanPanel, etc.). If you don't run one, the built-in minimap button is a full-equivalent entry point on its own.

## Contributing

Issues and pull requests are welcome.

## License

Licensed under [GPL-2.0](https://www.gnu.org/licenses/gpl-2.0.html). The full license text is in the `LICENSE` file in the source distribution.

## Changelog

### v1.1.0

- Minimap button is now configurable via *Settings → Minimap*. On by default; toggle off to declutter your minimap edge.
- README clarifies that NosyKeys works without a broker bar — the minimap button is a full-equivalent entry point.

### v1.0.0

First stable release.

- **Alt-hold reveal**: hold Alt while the tooltip is open to temporarily show all stored guild keys, bypassing the *Online guildmates only* filter and the *Show guild keys* toggle. Cap still applies. A tooltip hint surfaces the feature when it would do something.
- **Header annotation**: the Guild section reads `Guild  (online only)` when the filter is active, so it's clear why offline guildmates are missing.
- **Wipe button**: one-click escape hatch in *Settings → Guild* to drop all stored guildmate keys. Safe to use any time — new broadcasts repopulate the list within minutes.

### v0.9.3-beta

Pipeline verification — first release published to CurseForge and Wago alongside GitHub. No source changes.

### v0.9.2-beta

- Fix duplicate alt rows when realm wasn't ready during early addon-load (one-time SavedVariables migration drops any legacy bare-name keys).
- Contain WoW 12.x keystone-API taint into a private tooltip frame so the shared `GameTooltip` stays clean.

### v0.9.1-beta

Polish from first in-game test.

- Dev-build footer (no more literal `@project-version@` showing in raw source checkouts).
- Guild rows deduplicate against the Party section.
- Deterministic smart-sort tiebreaker (rating).
- Guild visibility default flipped on.

### v0.9.0-beta

Initial public beta.

- Broker bar: current keystone (`<Dungeon> +<Level>`) or `no key`.
- Tooltip: *You*, *Party*, *Alts*, *Guild* sections with class-colored names, key-tier-colored levels, weekly vault progress (`vault +<N>`), and current-season rating.
- LibKeystone-powered party and guild comm — interoperates with BigWigs and any other LibKeystone-aware addon.
- Guild section persists across `/reload`, wipes on weekly reset.
- Party members are deduplicated from Guild so a guildmate currently in your party doesn't appear twice.
- Guild filter: online-only by default; configurable cap (Top 10 / 15 / 25 / 50 / All).
- Guild sort: *Smart* (near my key level), *Highest first*, or *Alphabetic*.
- Per-channel guild hide (privacy: broadcast "no key" to guildmates only).
- Per-character alt snapshots in SavedVariables, stale-faded after a week unseen.
- Click handlers: open keystone holder, insert keystone hyperlink into chat, open settings.
- Native WoW Settings panel.
