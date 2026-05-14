# NosyKeys

## v1.0.0 (2026-05-13)

First stable release.

- **Alt-hold reveal**: hold the Alt key while the broker tooltip is open to temporarily bypass both the *Online guildmates only* filter and the *Show guild keys* toggle. Cap still applies. A tooltip hint surfaces the feature contextually.
- **Header annotation**: the Guild section now reads `Guild  (online only)` when the filter is active, so users understand why offline guildmates are missing.
- **Stored guild data — Wipe** button in Settings as a one-click escape hatch. New broadcasts repopulate the list within minutes; the standard weekly-reset wipe still runs.
- **Behavior**: guild broadcasts are now stored on receipt regardless of the *Show guild keys* toggle, so the Alt-hold reveal has data available even when the section is hidden by default. Storage is still wiped on weekly reset.
- **Fix**: outer `enableGuild` gate in the tooltip render was suppressing the Alt-hold reveal when the toggle was off; the visibility decision is now consolidated inside `GetGuildEntries`.
- **Fix**: `CreateSettingsButtonInitializer` now requires a non-nil `addSearchTags` argument in Midnight 12.x; passing `true` so the wipe row is findable via Blizzard's settings search.

## v0.9.3-beta (2026-05-13)

End-to-end publishing pipeline verification. No source changes from v0.9.2-beta — first tag with CurseForge and Wago.io API tokens wired into repo secrets, so the BigWigs packager uploads to all three platforms (GitHub Releases + CurseForge + Wago.io) in a single workflow run.

## v0.9.2-beta (2026-05-13)

Bug fixes and publishing wiring.

- Fix duplicate alt rows when `GetNormalizedRealmName()` briefly returned "" during early addon-load, producing a bare `Name` entry alongside the proper `Name-Realm` one. `CharLabel()` is now strict (returns nil if realm isn't ready) and `RecordSelf()` skips the write until a valid label is available. Read-side callers tolerate the nil.
- One-time SavedVariables migration scrubs any pre-existing bare-name entries from alts and guild keys on next load.
- Contain WoW 12.x keystone-API taint into a private `GameTooltipTemplate` frame instead of the shared `GameTooltip`, so reading from `C_MythicPlus` / `C_ChallengeMode` no longer leaks taint into Blizzard's own tooltip handling.
- Wire CurseForge and Wago project IDs into the TOC, enabling automatic packager uploads on tag push.

## v0.9.1-beta (2026-05-13)

Polish from first in-game test.

- Footer: show "dev" instead of literal "@project-version@" in raw source checkouts (packager substitutes the real tag on build)
- Guild section: deduplicate party members when Party is rendered, so a guildmate currently in your party doesn't appear in both lists
- Smart sort: add rating as deterministic tiebreaker when two guildmates are equidistant from the reference level and share the same key level
- Default "Show guild keys" flipped on; guild visibility is the whole point of the addon and opt-in was over-cautious. "Hide my key from guild" remains the actual privacy lever.

## v0.9.0-beta (2026-05-13)

Initial public beta.

- Broker bar: current keystone (`<Dungeon> +<Level>`) or `no key`
- Tooltip: *You*, *Party*, *Alts*, *Guild* sections with class-colored names, key-tier-colored levels, weekly vault progress (`vault +<N>`), and current-season rating
- LibKeystone-powered party and guild comm — interoperates with BigWigs and any other LibKeystone-aware addon
- Guild section is on by default (toggle to opt out), persists across `/reload`, wipes on weekly reset
- Party members are deduplicated from the Guild section so a guildmate currently in your party doesn't show twice
- Guild filtering: online-only by default — keep the section focused on guildmates you can actually whisper now
- Guild sorting: *Smart* (closeness to your own key level), *Highest first*, or *Alphabetic by name* — Smart by default so the cap surfaces realistic partners, not the top of an unfiltered list
- Per-channel guild hide (privacy: broadcast "no key" to guildmates only; party broadcasts unaffected)
- Per-character alt snapshots in SavedVariables, stale-faded after a week unseen
- Click handlers: open keystone holder, insert keystone hyperlink into chat, open settings
- Native WoW Settings panel
- Publishing pipeline: CurseForge and Wago.io automated via BigWigsMods packager on tag push
