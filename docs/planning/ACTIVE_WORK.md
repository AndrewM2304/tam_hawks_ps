# Active work — nonlinear Glasgow routes and local encounters, 17 October 2026

The owner has renewed usage and explicitly authorizes continuing the terrain/rider work while adding a senior skate-game design review and Glasgow culture/fun review. Reference levels: San Francisco, London, Los Angeles from the THPS3/4 era and School from THPS1/2. The role is a design perspective, not a claim of actual franchise employment. Use original layout/art and compatible free components. No purchases, billing, paid APIs, hosted CI or infrastructure.

## Current checkpoint

The six-area foundation below is implemented. The ordinary `./tools/check.sh` run completed **871 passed, 0 failed**; it began before the final visual embankment/shader/riverside-facade and map wrapping edits, so final current-source verification is still required. Updated adult-rider motion preview is already present (222 frames, 7.4 seconds). Native packages/source convenience ZIP still point to the older committed build and must be regenerated after the extended work.

## New active ownership

- Root: main/HUD/player integration, shared tests, final checks, commits/export/artifact handoff and STATUS/interfaces.
- `lead_level_designer`: classic-level reference research and candid topology/flow audit; new LEAD-DESIGN-REVIEW and CLASSIC-LEVEL-DESIGN docs.
- `geometry`: world/core/outdoor/art sources and exact route docs. Agreed implementation: a genuine station undercroft with crossing high/low lines; an angled Merchant Close; a park downhill cutback returning to Central; a compact south-Clyde yard/return loop. Preserve the ten career/save IDs and useful tested paths.
- `glasgow_fun`: researched local culture plus original fictional encounters under game/characters. Complete optional busker challenge: deliberate interaction, three real trick families, clean bank >=1,000, limited time, replay, no career/save-ID changes. Additional ideas stay explicitly planned unless implemented/tested.
- `quality`: independent world/topography/career/encounter tests and evidence. Shared test runner remains root-owned.
- `planning`: BACKLOG, ADR-008, design brief and actual source-stable captures; new full-field task IDs M03-013/M03-014/M04-007/M05-007/M07-007.
- `physics_references`: stable rider action/motion evidence and preview refresh after final world freeze, no speculative model changes.

## Required next steps

Implement/review the agreed topology and encounter slice; adapt intentional coordinate fixtures without weakening coverage. Test supported high/low passage, nonlinear return routes, real trick/bank challenge success/failure/replay and unchanged career/save behavior. Run required current-source aggregate checks; inspect actual final city/river/park/map/NPC captures. Commit clean runtime, export/audit both native packages (including four CC0 anatomical meshes/notices), run normal Linux startup smoke, refresh source ZIP/video/checksums and exact STATUS handoff. Human fun/final-art, real Mac/DualSense and Apple Silicon performance remain evidence gates, not reasons to stop independent work.

Prior Google/StreetView access was blocked. New agents may inspect other accessible free sources, recording source/date/confidence and distinguishing user suggestions from verified observations. Do not copy panoramas, music, likeness/voices or proprietary layouts. Keep research-to-fiction adaptation explicit.

---

## Earlier foundation implementation record

# Glasgow level redesign — active work, 17 October 2026

The owner explicitly requests substantial level design, elevation and real-place skating features, plus a less cartoony adult rider. This supersedes the previous art-only collision freeze. Work remains autonomous, local and without purchases, paid APIs, billing, hosted CI or infrastructure. Baseline before this change: source a99f993 / handoff7d84fc6, 778 checks. Those packages are historical until rebuilt.

## Ownership and contracts

- Root: integration, `main.gd`, player recovery, HUD/map, shared test runner, export and final handoff.
- rail_world: core world, terrain helper, city art, `GLASGOW-ROUTES.md`. Lower Exchange0m, gallery2m, George4m/civic6m, Central2m/platform5m, Barras0/loading1.5m. Spawn(-22,.8,28), clear northward graded route; curved fountain at(0,0,10).
- art_direction: new outdoor module/helpers and `OUTDOOR-ROUTES.md`. Clyde south, waterY-2, quay2m,8m broken-footbridge opening and continuous alternate crossing; Kelvingrove-inspired rolling grass/path climb6→17m northwest. Outdoor IDs `clyde`,`kelvingrove`.
- physics_references: visual rider/garments and realism evidence. Adult proportions, anatomical CC0 head/hands, shoes/clothing; no physics rewrite.
- reuse_candidates: pinned MakeHuman data/licence verification, cropped head/hand derivatives and reproducible generator, asset manifest/licence register. Full nude body source is not committed or shipped.
- quality: world routes, career integration/circuit, presentation fixtures, new topography physics tests/evidence. Root owns `tests/run_tests.gd`; update obsolete flat-layout fixtures intentionally, retain behavior coverage.
- planning: eight fully specified backlog tickets, ADR-007, design brief and new level-design capture tools/evidence.

World APIs: `get_ground_height(Vector3)` returns authored support height or NAN; `get_route_definitions()` dictionaries contain id,label,ordered world-ground points,requires_jump; six named checkpoints; `get_recovery_position(Vector3)` returns safe local spawn or Vector3.INF outside hazards. Main calls `skater.recover_to` for water, preserving restart spawn and dropping only pending combo. Ten career/save IDs remain unchanged; outdoor regions do not count toward the four-core-district goal.

## Next integration steps

Finish authored terrain/collision and rider assets; update intentional coordinate fixtures; exercise actual production movement through core grades, fountain capture, river jump and park climb. Run `./tools/check.sh` and inspect actual rendered six-area, map and rider evidence. Fix visible/support/route defects before marking implementation complete. Update interfaces/player guide and retained third-party notices, extend isolated package asset validation, commit clean runtime and rebuild both native packages. Refresh STATUS and exact downloadable hashes only after verified exports; Mac/controller/realism/fun acceptance remains open.

Research limitations persist: prior Google/StreetView and official sources were proxy-blocked. No map survey/current-shop claim, copied panoramas or commercial game content. This is an original compressed Glasgow-inspired map.
