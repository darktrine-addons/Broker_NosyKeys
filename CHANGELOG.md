# NosyKeys

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
