# NosyKeys

## v1.1.2 (2026-05-15)

- Sub-max-level characters are now hidden from the Party / Alts / Guild lists. Max level is sourced from `GetMaxPlayerLevel()` with a hardcoded fallback constant (currently 90 for Midnight) as the single touch-point for future expansions.
- The `vault +N` segment in the tooltip now renders in teal instead of inheriting the key-tier color. Stops vault and key from blurring into the same hue when their levels happen to fall in the same tier.

## v1.1.1 (2026-05-15)

- Shift-click on a character with no keystone now prints a brief chat message instead of silently doing nothing.
- Defensive editbox-show after `ChatEdit_ActivateChat` so shift-click-to-chat works when Prat-3.0 is loaded on Midnight 12.x. Filed upstream at [prat-3-0#315](https://github.com/Legacy-of-Sylvanaar/prat-3-0/issues/315).
- "You" row in the tooltip is now class-colored, matching the Party / Alts / Guild rows.
- Tooltip footer: removed a duplicate `v` in the version string.

## v1.1.0 (2026-05-14)

- Minimap button is now configurable via *Settings → Minimap*. On by default; toggle off to declutter your minimap edge.
- README clarifies that NosyKeys works without a broker bar — the minimap button is a full-equivalent entry point.

## v1.0.0 (2026-05-13)

First stable release.

- **Alt-hold reveal**: hold Alt while the tooltip is open to temporarily show all stored guild keys, bypassing the *Online guildmates only* filter and the *Show guild keys* toggle. Cap still applies. A tooltip hint surfaces the feature when it would do something.
- **Header annotation**: the Guild section reads `Guild  (online only)` when the filter is active, so it's clear why offline guildmates are missing.
- **Wipe button**: one-click escape hatch in *Settings → Guild* to drop all stored guildmate keys. Safe to use any time — new broadcasts repopulate the list within minutes.

## v0.9.3-beta (2026-05-13)

Pipeline verification — first release published to CurseForge and Wago alongside GitHub. No source changes.

## v0.9.2-beta (2026-05-13)

- Fix duplicate alt rows when realm wasn't ready during early addon-load (one-time SavedVariables migration drops any legacy bare-name keys).
- Contain WoW 12.x keystone-API taint into a private tooltip frame so the shared `GameTooltip` stays clean.

## v0.9.1-beta (2026-05-13)

Polish from first in-game test.

- Dev-build footer (no more literal `@project-version@` showing in raw source checkouts).
- Guild rows deduplicate against the Party section.
- Deterministic smart-sort tiebreaker (rating).
- Guild visibility default flipped on.

## v0.9.0-beta (2026-05-13)

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
