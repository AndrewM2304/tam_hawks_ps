# Current handoff — 17 October 2026

**Project:** Tam Hawks Pro Skater. **Branch:** `bootstrap/m00-m01`. **State:** M01 prototype plus first playable M02 rail grinding; ready for human keyboard/Mac/DualSense playtests. This is an initial gameplay slice, not the complete game or final art. `git log -1` identifies the latest checkpoint; preserve this feature-branch history.

The source, tests, captures and 54 full task records are saved on [the GitHub feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01). The original remote had no commits or `main`, so there is no PR base yet. No GitHub issues, hosted workflows or release publication were created. Check actual Git state before assuming a remote result.

## Start or resume

1. Read `AGENTS.md`, this file, `docs/planning/BACKLOG.md`, `docs/architecture/interfaces.md` and ADR-006. Check `git status --short` and preserve later work. Use the existing isolated checkout.
2. Run `./tools/setup.sh`. It verifies the installed Godot 4.6.3 and runs import/tests. No package download, server, paid service or secret is required.
3. Play using `./tools/run.sh` on a graphical desktop. On macOS, install the free official Godot 4.6.3 editor, import `project.godot` and press F5. For terminal scripts set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot` if that is its path. There is no verified native Mac export yet.
4. Reproduce captures using `./tools/capture.sh`. On this Linux image it starts an installed temporary Xorg dummy display, uses software OpenGL, captures four frames and stops the display. Outputs: `.local/prototype.png`, `.local/air-tricks.png`, `.local/pause-menu.png`, `.local/rail-grind.png`.
5. Read `docs/product/ART_DIRECTION.md` before visual work, `docs/research/SKATING_REUSE.md` before generic skating infrastructure, and `docs/research/GLASGOW_REFERENCES.md` before authentic frontage work.

## Implemented and latest changes

- Original procedural Glasgow-inspired square, four skateable ramps, ledges, boundaries, fictional placeholder shops and cone-topped statue. Two existing orange rail props now have matching authored grind geometry.
- Arcade push/brake/steering, buffered/coyote ollies, flip/grab/spin, forgiving landings and smoothed obstacle-aware camera. Primitive rider/board and presentation remain temporary.
- **M01-008 Done:** measured and fixed uphill/flat takeoff boosts, unintended downhill damping and horizontal momentum returning after airborne wall contact. Preserve actual collision-adjusted velocity in air and capped real surface velocity on ground. Independent 21-case regression and exact before/after evidence: `docs/testing/TAKEOFF-MOMENTUM.md`.
- **M02-001 Done:** ADR-006 defines state/input/score contracts; validated trick catalog adds IDs, structural guards and point rules. Future manual/revert/special records and the 0.35-second landing window are specifications, not enabled features.
- **M02-002 in QE review:** hold L/R2 to catch an aligned rail while descending; steer to balance; release, reach an end or ollie to exit. Full 3D signed travel, bounded capture, capsule clearance sweeps, cooldown, balance/obstruction bail and reset work. One Rail Grind award per attachment; no per-frame farming. Air→rail→air→ground combos bank on landing. Exact tuning and replay: `docs/testing/GRINDING.md`.
- Two-minute runs/free skate, pause/results/restart, score/history/repeat degradation and best combo. Active air/rail combos have bounded three-second overtime; fresh tricks/spins/captures are disabled at expiry while earned combo resolution remains possible. Manuals/reverts will later change immediate landing-bank behavior.
- Original MIT `GrindLine` adaptation retains its complete upstream notice. New ride/catalog/controller orchestration is original project code informed by inspected references. No third-party game assets were imported.

## Verified evidence at this checkpoint

| Check | Observed result |
|---|---|
| Engine | Installed `4.6.3.stable.official.7d41c59c4`; no engine artifact downloaded |
| `./tools/check.sh` | Clean import, **260 assertions passed, 0 failed**, exit 0; no scanned engine/script errors |
| Coverage totals | Previous 136 + 21 momentum + 27 catalog + 41 ride-helper + 19 production grinding + 15 independent grind regressions + 1 new input-action check |
| Independent physics evidence | Actual uphill/downhill/flat departures, air steering and wall-removal behavior; unchanged regressions fail before the fix and pass afterward |
| Production rail evidence | Real from-rest push→ollie→descending capture, both directions, release/ollie/end, pause/reset, one-entry scoring, ground banking, capture/travel obstruction and balance bail |
| Overtime review | Independent review found fresh-entry admission gap; fixed and verified rejection of new flip/grab/spin/rail/rail-ollie while earned spin and release/landing still resolve |
| `./tools/capture.sh` | Four real 1280×800 Compatibility/llvmpipe frames saved, all return 0; script exit 0. Orchestrator reviewed all four; A09 independently reviewed the new rail frame |
| Rail screenshot | Balance gauge and Ollie + Rail Grind, 300 ×2 = 600 pending points, readable controls and visible rail alignment |
| Local services/cost | No hosted CI, purchases, paid API calls, credentials, runtime network, unattended jobs or new downloaded dependencies |

Full report: `docs/testing/QE-REPORT.md`. Reproducible logs are ignored under `.local/`; reviewed captures are committed in `docs/testing/screenshots/`. The suite verifies the local slice, not physical controller behavior, target-Mac performance or finished game quality. Previous title-corrected captures remain in Git at `ad31a56c3cf6c324c10bb13520a3b8890dd54afb`.

## Owner visual direction and Glasgow access

The corrected title is **Tam Hawks Pro Skater**. The owner requires believable detailed Glasgow graphics, convincing animation and polished UI after core gameplay acceptance. `ART_DIRECTION.md`, `VISUAL_ACCEPTANCE.md`, ADR-005 and **mandatory M06-007** define the finish and owner review. Do not drop that cleanup if credits/session time end. The visible blockout does not satisfy it.

The Glasgow dossier preserves 12 dated address candidates (including Di Maggio's, Banca Di Roma, FOPP, Tantrum Doughnuts, BAaD and Saint Luke's), inspected source commit/hash, confidence limits and district survey questions. These historical community-data leads do not establish current occupants or actual street/corner/frontage geometry. No dataset or reference imagery was imported.

**M03-006 still Blocked:** a new 17 October 2026 12:11 UTC check of Google Maps, Glasgow Life, Network Rail and Barras again returned proxy tunnel HTTP 403. Local Chrome/incognito is not connected to this cloud task. A later configuration read shows the reference domains in the saved base version with no pending draft, but a fresh request from this running machine still returns 403. Startup in a fresh environment using those settings has not been verified; retry there before asking the owner to change the same settings again. Do not repeatedly retry unchanged blocked access or claim Street View was inspected. M03-007 will build verified facade borders. No paid Maps API is needed.

## Next concrete work

1. **M02-003 — manuals as combo links.** Read ADR-006 and the existing score ownership first. Implement eligible deliberate entry, balance/travel, release/bail and air/ground transitions with actual input/physics tests. Do not activate catalog entries or bind manual controls without mechanics. Keep current rail/air behavior and 260-check baseline.
2. **M02-004 / M02-005 — reverts and combo resolution.** After manuals, implement the original 0.35-second landing window, one revert per landing, authoritative pending-bank ownership and exploit bounds. Preserve timeout admission and existing earned-score tests; add exact boundary cases before replacing immediate landing banking.
3. **M01-007 and M02-002 hardware line trial remain open.** On a target Mac, play central/return ramp routes and the right-hand Exchange rail with keyboard, then real wired/Bluetooth DualSense. Record hardware/build, feel, R2 threshold, capture forgiveness, balance/ollie/release, camera comfort and replay appeal. Fix measured issues; synthetic tests cannot close these gates.
4. Resume **M03-006** once actual runtime access changes. Inspect maps, current official sources and imagery dates, record real corner/entrance/frontage relationships, then implement M03-007 through its dependencies. Do not infer geometry from dated address points.
5. Follow the backlog for specials/gaps, full four-district traversal, career/saves, art/audio/NPCs, accessibility/performance and packaging. M04–M07 remain explicitly proposed continuation because the supplied document ends at M03. Start representative production art after M02-008 acceptance and keep M06-007 as a release gate.

## Limits and checkpoint discipline

- No physical DualSense, macOS export/launch or Apple Silicon 1080p/60 fps test has run. Software-rendered Linux captures establish visibility only.
- No manuals, reverts, specials, named gaps, career missions, persistent saves/records, unlocks, cone interaction, secrets, NPCs, sound/music or full four-district level yet. Generic shop signs are placeholders.
- Flat landings remain forgiving at all headings. Spin is cosmetic to travel heading; grab is a crouch pose. Rail bail returns directly to spawn. Detailed contact/animation and full comfort review remain work.
- No standalone distributable or paid signing/notarization exists; free source/editor play is the current route. Do not buy Apple enrollment, assets or voice services.
- No unattended future work is scheduled. Normal in-session assistant credits are still consumed. Local ticket records are not published GitHub issues.
- Before ending each session, update this file and affected tickets with exact tests, defects, paths and next edits; commit source, tests and handoff together. Keep `.godot/`, `.local/`, builds and credentials out of Git. Environment draft saving does not apply/publish it, and fresh-task restoration requires separate evidence.
