# Terrain, coping and outdoor route evidence

Independent QE for the terrain redesign, Godot 4.6.3, 17 October 2026. The redesigned production geometry passes the focused checks below with clean engine/script logs and exit 0. The final aggregate gate is **pending root’s run**; these focused passes are not a full-project result. The former 778-check result and 69.52-second career circuit describe the previous flat layout; current career evidence is in [CAREER-ROUTES](CAREER-ROUTES.md).

## Focused results

| Source suite | Result | What the checks establish |
| --- | --- | --- |
| `world_routes_tests.gd` | **136 passed, 0 failed** | Six classified/supported/clear checkpoints; actual collision and bidirectional capsule sweeps for continuous authored routes; retained objective support/clearance, Central gap break, NPC and cone checks |
| `topography_tests.gd` | **33 passed, 0 failed** | Exact district levels, real grade transit, curved coping capture/release, physical Clyde and park travel, successful bridge ollie and failed-jump recovery |
| `career_integration_tests.gd` | **23 passed, 0 failed** | Existing progression/special boundaries plus actual climb to the new 5m Central platform, ollie across its break, award/bank/reset |
| `presentation_integration_tests.gd` | **9 passed, 0 failed** | Real stone/asphalt/metal floor contact, new readable location name, marker/count feedback and protected-save warning |
| `career_route_tests.gd` | **13 passed, 0 failed** | All ten original goals in one 120-second career, four physical checkpoints and six linked graded boundary-combo directions |

These are focused module counts, not an aggregate suite total. All four core checkpoint positions are passed by the career circuit; the topography driver's actual motion passes the Clyde and Kelvingrove checkpoint positions. Profile persistence is disabled except the existing protected-save test's unique ignored fixture path, whose bytes are preserved and file removed.

| Actual physical route | Fixed-60Hz elapsed | Measured result |
| --- | --- | --- |
| Gallery→civic ascent and reverse | 10.47s each | Ground levels 0→2→4→6m and back, 162 non-flat floor-contact ticks in each direction, no stalls/bails |
| Central south grade and reverse | 3.90s each | 0↔2m, 60/61 slope-contact ticks, no stalls/bails |
| Market loading approach and reverse | 5.05s each | 0↔1.5m, 49/48 slope-contact ticks, no stalls/bails |
| Central port→Clyde north quay→Barras port | 16.08s | Actual route and Clyde checkpoint passed with no stall/bail |
| Continuous Clyde bridge | 4.57s | Physical graded crossing reaches the opposite quay without jumping or recovery |
| Central→Kelvingrove loop→same Central port | 29.45s | Continuous climb/circuit/descent, 924 slope-contact ticks, no stalls/bails; rider height 2.00→17.80→2.00m, including natural crest airtime above the 17m path |

The fountain test accelerates from real ground, ollies and captures the descending tangent. Over 36 subsequent ticks the heading changes by more than 0.5 radians while the rider remains within 5cm of the coping curve and travels more than 4m. Release lands and banks the Ollie + Rail Grind combo once without a bail. The final solid 6.2m basin and central pedestal are included.

The broken Clyde bridge test pushes from the north quay to its launch grade, ollies near Z=91.8, crosses the actual **8m unsupported interval Z=94–102**, lands on the southern deck and banks **2,000 points**, including one named gap award. A separate fixture earns a real 100-point ollie bank, then rides off without jumping and performs a real Flip while falling. The water hazard emits exactly one bail, drops that pending combo, preserves the 100-point bank and returns to supported quay `(25,2,124)` without changing the run's original restart spawn.

## Physical coverage

`tests/topography_tests.gd` uses the production main scene, player movement, collision bodies and scoring. `tests/world_routes_tests.gd` independently samples actual collision at authored navigation points, checks upright rider clearance in both directions, and preserves objective/NPC/cone checks. Authoring metadata alone is not a traversal pass.

The terrain gate covers:

- Independently expected support elevations: Exchange lower square 0m/gallery 2m; George 4m/civic terrace 6m; Central concourse 2m/platform 5m; Barras 0m/loading terrace 1.5m. Real rays must return upward walkable surfaces at those levels.
- Real push-driven ascent and descent over grade transitions, with non-flat floor normals, measured height change, no recovery and no stalled section.
- Fountain: ground approach, actual ollie, descending capture of the curved coping, changing travel tangent while remaining on the curve, then release, landing and a single bank.
- Clyde: actual run-up and ollie across the unsupported bridge interval; separately an unsuccessful crossing that falls into water, emits one bail, drops pending points, preserves banked points and returns to supported ground without changing the run's restart spawn.
- Kelvingrove: continuous uphill/downhill park circuit through the authored seams, using production push/steer/collision.
- The original ten goals remain covered separately by `tests/career_route_tests.gd` and `tests/career_integration_tests.gd`, with physical collections and the real Central platform jump. Outdoor navigation checkpoints do not enlarge the original four-district career requirement.

## Driver and acceptance limits

Each independent fixture may set its spawn **before** restart. Once that route starts, the test never assigns rider position, velocity or speed, bypasses collision, injects a gap award, or changes gravity. It issues ordinary input actions. On supported ground it may directly aim the rider's heading, permitting instantaneous idealized turns; in air it uses bounded steering actions. Consequently this proves a physical route exists, not its discoverability, human timing, turning comfort or difficulty.

The focused runner may use `--fixed-fps 60` for fast fixed-delta simulation; it never changes `Engine.time_scale`, the 120-second career timer or tuning. Ordinary-scheduler timing must be labelled separately. Scanned engine/script errors block acceptance even if assertion counts pass. Fixtures disable player-profile writes.

No headless result certifies final art, real Mac/DualSense behavior, Apple Silicon performance, subjective fun or human balance tuning.

## Reproduce

The runner contract is `await TopographyTests.run(tree, game, check_callable)`. Construct `game/main.gd`, set `persistence_enabled = false` before adding it to the scene tree, and report failures with a nonzero exit code. Root owns integration in `tests/run_tests.gd` and the final `./tools/check.sh` result.

A clean result requires both successful assertions and a scan of the complete import/test logs for `ERROR:`, `SCRIPT ERROR:` and `FAIL:`. Coordinate newly created assets with their owner before running editor import. Focused logs and temporary probes belong under ignored `.local/`; source tests and this document are the durable handoff.


## Defects found and resolved

- A civic frontage sealed the backstreet to the S letter. Physical travel stopped at `(-35.706,4.012,-77.431)`. The world owner split the frontage; the career circuit and collision sweeps now pass the opening.
- Flat backstreet corners overlapped unfinished slopes, creating approximately 0.3–0.4m lips near Z=-74. Both climbing lanes now reach 4m at the corner edge and publish the matching waypoint.
- The Clyde eastern quay approach originally ended its rise beyond the start of the higher quay. It now reaches 2m where the quay begins at Z=55.
- Park terrain/terrace overlaps and interpolated undershoot produced mismatched support and blocked capsule sweeps. The outdoor owner conformed nearby terrain beneath paths, moved the summit apron, removed height tangents at flat/sign-change knots, and preserved exact sampled endpoints. The final complete static route and real player circuit pass; tolerances were not widened to hide these failures.
- Natural uphill crest airtime legitimately ends a manual. The career driver now uses fresh post-landing manual inputs within the unchanged cooldown/deadline. This is documented input adaptation, not a controller or scoring workaround.

## Local evidence and rerun

After the final colliding grass embankments were added below the Central and George park connectors, the complete static world-route suite was rerun: **136 passed, 0 failed**, exit 0, with no engine/script errors. Every sampled support and bidirectional capsule sweep still passes. This focused follow-up is `.local/world-routes-final-embankment.log`; root retains the final aggregate responsibility.

Clean focused logs: `.local/world-routes-redesign.log`, `.local/topography-final.log`, `.local/career-integration-redesign.log`, `.local/presentation-redesign.log`, `.local/career-redesign.log` and `.local/career-redesign-ordinary.log`. Assertions and engine-error scans pass. No downloaded testing dependency is used.

Use the temporary runner recipe in CAREER-ROUTES, replacing its preload with the desired test module. The topography, career integration and presentation modules accept `(tree, game, check)`; world routes accepts `(tree, game.world, check)`. For a fast focused run use `./tools/run.sh --headless --fixed-fps 60 --script .local/<runner>.gd > .local/<log>.log 2>&1`, then scan the complete log. The topography route timings above use this fixed-delta mode. The separate all-goal career circuit also passed ordinary scheduling at 75.33s to all goals and 88.13s to return.

All affected source tests are wired into root's `tests/run_tests.gd`; `./tools/check.sh` is the aggregate import/test gate. New rendering/collision edits still require the appropriate rerun. Passing focused modules does not certify final visuals or replace the pending human/hardware gates.
