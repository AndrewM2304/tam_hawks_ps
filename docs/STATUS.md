# Current handoff — 17 October 2026

**Project:** Tam Hawks Pro Skater (owner-corrected title). **Branch:** `bootstrap/m00-m01`. **State:** a working M01 prototype, ready for its first human skating playtest. This is an initial slice, not the full Release 1 game. `git log -1` identifies the latest checkpoint; all work stays on the feature branch.

The source, tests, screenshots and full task records have been pushed to [the GitHub feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01). The first implementation checkpoint is `de11b1f`. The original remote had no commits or `main` branch, so there is no base branch for a pull request yet. No GitHub issues, hosted workflows or release publication were created. Continue from the feature branch and preserve this history.

## Start or resume

1. Read `AGENTS.md`, this file, `docs/planning/BACKLOG.md`, and `docs/architecture/interfaces.md`.
2. Run `git status --short` and preserve any later work. Use the existing checkout; no extra worktree is needed.
3. Run `./tools/setup.sh` in the repository root. It verifies the already installed Godot 4.6.3 and executes the import/test checks. No package download, paid service, secret or server is required.
4. Play with `./tools/run.sh` on a graphical desktop. On macOS, install the free official Godot 4.6.3 editor, import `project.godot`, and press F5 to run the project. For terminal scripts, set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot` if that is the installed path. The cloud machine is Linux; there is no native Mac build yet.
5. Reproduce screenshots with `./tools/capture.sh`. On this Linux image it starts an installed Xorg dummy display, uses software OpenGL, captures three frames and stops its display process. On a graphical desktop it uses the existing display. Outputs are `.local/prototype.png`, `.local/air-tricks.png`, and `.local/pause-menu.png`.

## Implemented

- Original procedural Glasgow-inspired Exchange Square, sandstone facades, fictional shop names, four skateable ramps, ledges, rail props, boundaries and an original cone-topped statue. Rail props do not support grinds yet.
- Arcade acceleration/braking/steering, buffered/coyote ollies, kickflip, melon-grab pose, scored spins and forgiving landings. Original primitive rider/board and a smoothed obstacle-aware chase camera.
- Aerial combo preview, unique-trick multiplier, repeat degradation, bank-on-landing, out-of-world recovery, session score and best combo.
- Two-minute runs with bounded landing grace, free skate, pause/results, fast restart, HUD, and standard gamepad plus keyboard bindings. Training prompts are temporary session hints, not persistent career goals.
- Dependency-free automated tests, a screenshot runner, local issue/PR templates, product requirements, architecture decisions, provenance register and 54 detailed release tickets.

## Verified evidence

| Check | Observed result |
|---|---|
| Engine | Preinstalled `4.6.3.stable.official.7d41c59c4`; no engine artifact downloaded or upstream checksum comparison claimed |
| `./tools/check.sh` | Clean Godot import; **136 assertions passed, 0 failed** (original 94 plus 42 rail-helper checks), exit 0 |
| `./tools/setup.sh` | Verified pinned-toolchain/import/test path in initial session (94-check baseline); delegates to the same check script |
| Physics/integration | Movement, jump/held-button behavior, flip/grab/spin scoring, bank/drop/reset, four ramp surface normals, two actual ramp traversal routes, boundaries, pause, restart, mode switches and timer overtime |
| Failure detection | Temporary runner invoked the actual assertion helper with a deliberate failure; explicit FAIL and exit 1 observed; probe removed |
| Rendered evidence | Real 1280×800 software OpenGL captures; reviewed by orchestrator, gameplay/world specialists and independent QE |
| Reused component | Isolated MIT helper verified on 4.6.3; duplicate-bake and endpoint-tangent defects fixed under unchanged QE assertions; full notice retained |
| Local dependencies/services | One vendored MIT source component; no plug-ins, third-party game assets, network runtime, credentials, asset purchases or paid API calls |

See `docs/testing/QE-REPORT.md` for exact coverage and limitations. Logs in `.local/` are reproducible and ignored. Reviewed screenshots are checked into `docs/testing/screenshots/`. Early overexposed lighting and a clipped speed gauge were fixed during visual review.

## Reuse follow-up completed

The owner encouraged research/reuse instead of building all skating infrastructure ourselves. M02-009/M02-010 are complete: four public projects and official engine APIs were inspected, one self-contained licensed component was adapted, and tests verified it on the pinned engine. `docs/research/SKATING_REUSE.md` has exact source commits, algorithms, limitations and file hashes. ADR-004 and AGENTS establish the reuse preference. The full upstream games were not imported or runtime-certified; no upstream assets or paid tools were used. Candidate Mick West articles were inaccessible and are explicitly recorded as unread leads.

`game/tricks/grind_line.gd` now supplies world-space curve geometry, closest points, full 3D tangents, authoring transforms and malformed-data guards. It is a foundation for M02; playable grinding is not enabled yet. Research also identified a possible ramp takeoff momentum discontinuity in our existing controller. It is not a reproduced failure: M01-008 records the measurement/regression task before any air-control change. The helper addition does not alter active movement. The later title correction was separately verified with a clean 136-check run and three regenerated, reviewed captures.

## Owner direction and Glasgow research

The owner corrected the title to **Tam Hawks Pro Skater**. Project settings, scene, HUD/world labels, test output and documentation now use it. `./tools/check.sh` passed all 136 assertions after the rename; `./tools/capture.sh` regenerated three actual 1280×800 OpenGL captures, reviewed and copied to `docs/testing/screenshots/`. The previous-title captures remain in Git history at `9322aebdba224d215d6a3660703419fecf6fb74f`.

The current cuboid environment, primitive rider and prototype UI are temporary. `docs/product/ART_DIRECTION.md` specifies believable detailed Glasgow art, convincing animation and polished UI. `docs/testing/VISUAL_ACCEPTANCE.md` defines matched captures, placeholder inventory, accessibility, gameplay regressions, target-Mac performance and owner review. **M06-007 is a mandatory cleanup gate after core gameplay**, required before release; do not drop it if credits/session time end. ADR-005 records the decision.

`docs/research/GLASGOW_REFERENCES.md` preserves 12 dated address candidates, inspected source commit/hash, confidence limits and a district-by-district survey itinerary. Examples include Di Maggio's, Banca Di Roma, FOPP, Tantrum Doughnuts, BAaD and Saint Luke's. These are historical community-data leads, not verified current frontages or map geometry. No dataset, photographs or map assets were imported.

**M03-006 remains blocked:** official sites, Google Maps/Street View, OpenStreetMap and the primary food-rating source returned proxy CONNECT 403. Domain additions are saved in the cloud draft, but are not active runtime access. The owner must review and save the changes in environment settings, then publish the environment; a subsequent environment using that configuration can retry the exact links. M03-007 will turn verified references into recognisable nonplayable facade edges. No paid Maps API is required.

## Next concrete work

1. **M01-007 — owner playtest on Mac + DualSense.** Play the central launch ramp and tenement return loop for several runs. Record keyboard vs wired/Bluetooth controller, turn sensitivity, jump timing, landing forgiveness, camera comfort and whether another run is appealing. Use `docs/testing/STRATEGY.md`; record actual results instead of treating synthetic input as hardware proof.
2. Fix any concrete feel/input/camera defects from that playtest under M01-001–006. The current automated baseline is 136 assertions; add focused regressions where meaningful.
3. **M01-008 — takeoff momentum measurement** can proceed independently. Measure uphill/downhill departures and distinguish intended arcade tuning from a velocity discontinuity before fixing a demonstrated issue.
4. **M02-001 — trick-state/input specification.** Independent specification work can start while hardware feedback is pending. Read the inspected 3deric/Not Pro Skater examples in `docs/research/SKATING_REUSE.md`; agree grind acquisition, manual balance, revert window, combo continuation and bail rules. M02-002 should integrate the adopted helper rather than recreate rail geometry. Do not mark M01 or M02 accepted without their human gates.
5. Resume **M03-006** when reference sites are accessible. Inspect actual street/corner/frontage relationships and imagery dates; then implement M03-007 after its level dependencies. Do not infer layouts from the dated address leads.
6. Follow the dependency graph in the backlog. Full four-district level is M03; career goals/saves/unlocks M04; art/audio/NPCs M05; accessibility/hardware/performance M06; packaging/release M07. M04–M07 are explicitly proposed continuation because the supplied paste stops at M03.

## Known limits and outstanding gates

- The current blockout does not meet final art/UI requirements. Real storefront verification, detailed art and mandatory M06-007 cleanup remain open.

- No physical DualSense, macOS export/launch or Apple Silicon 60-fps/1080p test has run. The Linux software-rendered frames establish visibility, not target performance.
- Landings deliberately succeed at all headings. Spins are cosmetic and score on landing without changing travel heading; grab is a crouch pose. Advanced bail rules and animations remain work.
- No grinds, manuals, reverts, special tricks, named gaps, career missions, persistent records/saves, unlocks, interactive cone, secrets, ambient NPCs, sound or music yet. No full four-district level yet.
- No standalone distributable or paid signing/notarization setup exists. Free source-project play is the current route; do not buy Apple enrollment or voice services.
- No hosted CI or unattended agents are enabled. Existing in-session assistant credits are still consumed normally; no system here schedules future paid work.
- Ticket files and templates are local records, not published GitHub issues. Never infer a PR or remote branch exists without checking Git.

## Checkpoint discipline

Before ending the next session, update this file and the affected tickets with exact results, defects, files, dependencies and next steps. Commit source, tests, decisions and handoff together on the feature branch. Keep `.godot/`, `.local/`, builds and credential files out of commits. Preserve original plan and no-spend constraints. Environment draft publication and fresh-task restoration are separate from current-instance validation.
