# NosyKeys

**A lean Mythic+ keystone broker. One tooltip shows you, your party, your alts, and your guild — no separate window, no custom comm protocol.** Talks [LibKeystone](https://github.com/BigWigsMods/LibKeystone), so BigWigs guildmates appear automatically.

Retail only. Requires Midnight (Interface 120005+) and a broker host such as Arcana (recommended), ElvUI, Bazooka, Broker2FuBar, or TitanPanel.

## Is this for you?

**Yes, probably** — if you:

- Run Mythic+ on multiple characters and want to see all their keys in one place
- Want to know who in your party has what key without asking
- Already use BigWigs (LibKeystone interop is free; nothing to configure)
- Prefer broker bars and hover-tooltips over dedicated windows

**Probably not** — if you:

- Want a sortable spreadsheet-style window listing every guildmate (use [AstralKeys](https://www.curseforge.com/wow/addons/astral-keys))
- Want in-run tools like death tracking or enemy-forces precision (use [AngryKeystones](https://www.curseforge.com/wow/addons/angry-keystones))
- Run M+ exclusively in pre-formed Discord groups (you don't need keystone discovery)
- Need AstralKeys-protocol interop for non-LibKeystone guilds (NosyKeys is LibKeystone-native by design)

## Features

- **Broker bar text**: `<DungeonName>  +<Level>` for your current key, or `no key`
- **Tooltip sections**: *You*, *Party* (in a 5-man), *Alts* (other characters on your account), *Guild* (opt-in)
- **Vault progress**: each row appends `vault +<N>` when the character has weekly M+ progress, alongside current key and seasonal rating
- **LibKeystone-powered comm**: party and guild keys arrive automatically from any LibKeystone-aware addon (BigWigs, other NosyKeys installs)
- **Class-colored names**, **key-tier-colored levels** (green / blue / purple / orange / pink mirroring Blizzard's keystone item-quality), and **stale-fade** for alts not seen this week
- **Smart guild sort** *(default)*: prioritizes guildmates whose key level is closest to yours — so the people you could actually run with surface first, not the +20 pushers at the top of a fixed-cap list
- **Online-first filtering**: by default the Guild section lists only guildmates currently online; toggle off to see everyone whose key arrived this week
- **Privacy**: per-channel guild-hide (broadcast "no key" to guildmates while keeping party broadcasts intact)
- **Click handlers**: open the keystone holder · Shift-Click to insert your keystone hyperlink into chat · Shift-RightClick to open settings
- **Weekly reset aware**: guild data wipes on rollover; alts persist with stale-fade after a week unseen

## Installation

The recommended path is a package manager: **CurseForge app**, **WowUp**, or the **Wago app** — search for "NosyKeys" and one-click install.

For manual installation:

1. Download the latest release zip from [GitHub Releases](https://github.com/darktrine-addons/Broker_NosyKeys/releases), CurseForge, or Wago.io
2. Extract the `Broker_NosyKeys` folder into your addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or `/reload`

## Click Interactions

- **Left-click** — Open the keystone holder (lazy-loads `Blizzard_ChallengesUI` if needed)
- **Shift-Left-click** — Insert your keystone hyperlink into the active chat box (plain-text fallback if the bag scan can't find it)
- **Shift-Right-click** — Open the Settings panel

## Configuration

Open the settings panel via **Shift-Right-click** on the broker button, or via **Escape → Options → AddOns → NosyKeys**.

### Guild

- **Show guild keys** *(default: Off)* — Subscribe to guildmates' keystone broadcasts and list them in the tooltip. Both sides need a LibKeystone-aware addon installed (BigWigs counts; another NosyKeys install counts).
- **Hide my key from guild** *(default: Off)* — Broadcast "no key" to guildmates even when you have one. Party broadcasts are unaffected. Toggling *Show guild keys* off stops displaying guild keys; it does **not** stop broadcasting your own — this setting is the one that does.
- **Max guild entries shown** *(default: Top 15)* — Cap on the number of guild rows in the tooltip, applied after the sort.
- **Online guildmates only** *(default: On)* — Filter the Guild section to guildmates currently online. With a large guild this is usually what you want. Off shows everyone whose key arrived this week.
- **Sort guild by** *(default: Smart)* — How to order before the cap is applied:
  - *Smart (near my key level)* — distance-from-your-key-level ascending; uses your weekly best as the reference when you have no current key. Degrades to *Highest first* when neither is known.
  - *Highest first* — by key level descending, then by rating.
  - *Alphabetic by name* — by `Name-Realm`.

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
- **Broker display**: any LDB-compatible display (ElvUI, Bazooka, Broker2FuBar, TitanPanel, etc.)

## Contributing

Issues and pull requests are welcome.

## License

Licensed under [GPL-2.0](https://www.gnu.org/licenses/gpl-2.0.html). The full license text is in the `LICENSE` file in the source distribution.

## Changelog

### v0.9.0-beta

Initial public beta.

- Broker bar: current keystone (`<Dungeon> +<Level>`) or `no key`
- Tooltip: *You*, *Party*, *Alts*, *Guild* sections with class-colored names, key-tier-colored levels, weekly vault progress (`vault +<N>`), and current-season rating
- LibKeystone-powered party and guild comm — interoperates with BigWigs and any other LibKeystone-aware addon
- Guild section is opt-in, persists across `/reload`, wipes on weekly reset
- Guild filtering: online-only by default to surface guildmates you can actually whisper now
- Guild sorting: Smart (near my key level), Highest first, or Alphabetic — Smart by default so a +10 player isn't drowned in +20 pushers
- Per-channel guild hide (privacy: broadcast "no key" to guildmates only)
- Per-character alt snapshots in SavedVariables, stale-faded after a week unseen
- Click handlers: open keystone holder, insert keystone hyperlink into chat, open settings
- Native WoW Settings panel
- Publishing pipeline: CurseForge and Wago.io automated via BigWigsMods packager on tag push
