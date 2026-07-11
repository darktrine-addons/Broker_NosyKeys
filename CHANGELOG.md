# NosyKeys — Changelog

User-facing changes, newest first. Internal and dev-tooling work lives in the
git history, not here.

## [v1.1.6](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.6) — 2026-07-11

- chore: updated for WoW patch **12.0.7** (Interface 120007). No functional changes — every API the addon uses is unchanged in 12.0.7.

## [v1.1.5](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.5) — 2026-06-03

- chore: release notes are now posted per-version to CurseForge and Wago; the full history lives in this file.

## [v1.1.4](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.4) — 2026-05-24

- fix: guild keystone broadcasts no longer throw an error (regression from v1.1.3).

## [v1.1.3](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.3) — 2026-05-17

- fix: on connected realms a guildmate is no longer listed twice (once per realm spelling); existing duplicates self-heal on the next roster update — no `/reload` needed.

## [v1.1.2](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.2) — 2026-05-15

- fix: characters below max level are hidden from the Party / Alts / Guild lists.
- fix: the `vault +N` segment renders in teal so it no longer blends into the key-tier colour.

## [v1.1.1](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.1) — 2026-05-15

- fix: shift-click on a character with no keystone now prints a brief chat message instead of silently doing nothing.
- fix: shift-click-to-chat works again when Prat-3.0 is loaded on Midnight 12.x.
- fix: your own *You* row is now class-coloured, matching the Party / Alts / Guild rows.
- fix: removed a duplicate `v` in the tooltip footer version string.

## [v1.1.0](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.1.0) — 2026-05-14

- feat: the minimap button is now toggleable in *Settings → Minimap* (on by default) — turn it off if you run a broker bar.

## [v1.0.0](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v1.0.0) — 2026-05-13

First stable release.

- feat: **Alt-hold reveal** — hold Alt while the tooltip is open to temporarily show all stored guild keys, bypassing the *Online guildmates only* filter and the *Show guild keys* toggle (cap still applies).
- feat: the Guild header reads `Guild  (online only)` when the filter is active, so it's clear why offline guildmates are missing.
- feat: **Wipe** button in *Settings → Guild* drops all stored guildmate keys; broadcasts repopulate within minutes.

## [v0.9.3-beta](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v0.9.3-beta) — 2026-05-13

- chore: pipeline verification — first release published to CurseForge and Wago alongside GitHub (no source changes).

## [v0.9.2-beta](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v0.9.2-beta) — 2026-05-13

- fix: duplicate alt rows when the realm wasn't ready at addon load.
- fix: the keystone tooltip no longer taints Blizzard's shared tooltip.

## [v0.9.1-beta](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v0.9.1-beta) — 2026-05-13

- fix: source checkouts no longer show a literal `@project-version@` in the tooltip footer.
- fix: guild rows deduplicate against the Party section.
- feat: guild keys shown by default.

## [v0.9.0-beta](https://github.com/darktrine-addons/Broker_NosyKeys/releases/tag/v0.9.0-beta) — 2026-05-13

Initial public beta.

- feat: broker bar shows your current keystone (`<Dungeon> +<Level>`) or `no key`.
- feat: tooltip with *You*, *Party*, *Alts*, and *Guild* sections — class-coloured names, key-tier-coloured levels, weekly vault progress (`vault +N`), and current-season rating.
- feat: LibKeystone-powered party and guild comm — interoperates with BigWigs and any other LibKeystone-aware addon.
- feat: guild filtering (online-only by default, configurable cap), sorting (*Smart* / *Highest first* / *Alphabetic*), and a per-channel privacy hide.
- feat: per-character alt snapshots that stale-fade after a week unseen; guild data wipes on weekly reset.
- feat: click handlers (open keystone holder, insert keystone link into chat, open settings) and a native WoW Settings panel.
