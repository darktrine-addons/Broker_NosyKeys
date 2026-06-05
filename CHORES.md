# Chores

Recurring maintenance tasks that don't belong in CHANGELOG and aren't tracked by issues.

## Bundled libraries — refresh check

Run a quarterly `git fetch` against each upstream lib and diff against the vendored copy. If anything moved, decide per-lib whether to roll it in.

**Priority:** LibKeystone. Its wire format is shared with BigWigs; falling behind BigWigs's bundled version silently degrades guild-broadcast interop with BigWigs users. Always align our bundled copy with whatever BigWigs ships in its current build.

| Lib | Vendored version | Upstream | Cadence |
|---|---|---|---|
| LibKeystone | 10 | https://github.com/BigWigsMods/LibKeystone | **Align with BigWigs's bundled copy.** Check on each major BigWigs release. |
| LibDBIcon-1.0 | 55 | https://github.com/Rainrider/LibDBIcon-1.0 | Quarterly. Cosmetic/internal changes, no urgency. |
| LibDataBroker-1.1 | 4 | https://github.com/tekkub/libdatabroker-1-1 | Annual. It's a spec; near-zero churn since ~2012. |
| CallbackHandler-1.0 | 8 | https://repos.curseforge.com/wow/ace3 (Ace3 bundle) | Annual. Dead-stable. |
| LibStub | 2 | https://repos.curseforge.com/wow/libstub | Never. Hasn't moved in over a decade. |

### Refresh procedure

For each lib worth refreshing:

1. `git clone --depth 1` the upstream repo into a temp dir.
2. Diff against `Libs/<LibName>/` — confirm the change set is innocuous (new fields, fixes) and not a breaking API revision.
3. If safe to take: copy the upstream files over the vendored ones, bump no version of our own (the lib carries its own MAJOR/MINOR), commit with `chore: bundle LibX vN`.
4. Tag a patch release if the bumped lib touches code we actually call; skip the release if the change is dead code for us.

### Why not the packager's `externals:` feature

Considered and rejected — see conversation thread 2026-06-04. Short version: the packager fetches externals into a release-staging dir, not into the working tree, so `git clone darktrine-addons/Broker_NosyKeys && /reload` would silently break for any contributor (and for us on a fresh machine). Vendoring keeps the source tree self-contained; the cost is this manual cadence, which is cheap for libs that move slowly.