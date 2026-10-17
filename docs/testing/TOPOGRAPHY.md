# Terrain, coping and outdoor route evidence

Independent QE for the terrain redesign, nonlinear routes and current court/workshop extension, Godot 4.6.3, 17 October 2026. The previous nonlinear/Mo runtime passed the final **955/0** aggregate. The new court/cat focused checks below have clean engine/script logs and exit 0; their final aggregate is **pending root's run**. The older 778/871 results describe earlier layouts. Career evidence and timing limits are in [CAREER-ROUTES](CAREER-ROUTES.md); earlier passes do not certify later geometry changes.

## Court and mechanical-cat extension: focused evidence

`cat_encounter_tests.gd` passes **38/0**: 21 explicitly separate callback-rule checks and 17 physical integration/presentation checks. The scene fixture disables persistence and uses a fresh in-memory career. After the initial spawn, the successful route never assigns position, velocity or speed, and never injects a capture, trick, score or bank. Direct grounded heading remains an explicit idealization.

The rider accepts Rae's offer through the mapped interaction key, physically travels to the west approach, then pushes/ollies onto `Grind_Cat_A`. Two actual rail ollies transfer to `Grind_Cat_B` and `Grind_Cat_C`; all three emit one capture each, with sequence states 1→2→3. The attempt remains active until the final real release/landing bank. The exact earned total is **1,050**, once: `(100 + 200 + 50 + 100 + 25 + 50) × 2`, for three ollies and three repeat-degraded Rail Grinds. No bail occurs and the 60-second attempt has **52.32 seconds** remaining at success. Although this fixture links all three rails, the stated challenge permits intermediate clean banks; the pure rule checks verify that permission separately.

The rule checks cover invalid duplicate rail definitions, offer distance, pending-combo rejection, unmarked/wrong-order captures, repeated last segment, restarting at A, intermediate banks, nonpositive final banks, replay, leaving, callback-before-poll area validation, the actual 60-second deadline, bail and run reset. Scene checks exercise pause, a real airborne combo during career expiry, results-screen interaction rejection, retained career identity, one actual manual-imbalance bail and free-skate progression isolation. Both side challenges now end when career time first reaches zero; ordinary scoring overtime may still finish an existing line. A last-positive-frame bank remains governed by main's existing update order.

Rendered review found that starting the payoff immediately at the C landing could spend its entire duration behind the player. The real bank now earns the win once and **queues** the payoff. Independent physical testing verifies the stage is outside the actual camera frustum at that bank. The rider then returns using ordinary push/brake and grounded heading toward the open gap near `(4,4,-93)`; after **51 physics ticks / 0.85s**, the rider is **9.87m** from Rae and the production camera's stage-frustum test is true. Only then does the one-shot start. The test never assigns a camera transform or audience-visible flag during this route.

Tests verify menu pause freezes playback, the visible payoff completes its full **3.2 seconds**, live reduced motion produces a stable raised-paw pose/steady indicator, and lingering or toggling motion cannot repeat the animation or reward. Separate callback fixtures check the 10m horizontal/2.5m vertical visibility gate and stopping an already playing animation when reduced motion is enabled. These checks do not replace rendered prop/readability review or human comic-timing acceptance.

The five changed continuous court routes pass **15/0**, with every intermediate waypoint traversed in both directions, no stalls/bails and correct supported endpoint heights:

| Court route | Forward / reverse fixed-60Hz time | Physical evidence |
| --- | --- | --- |
| Cat coping approach | 1.35s / 1.37s | Supported west-side entry to the marked course |
| Cat coping runout | 2.18s / 2.20s | Supported landing area and eastern return |
| Workshop permanent bypass | 5.80s / 5.80s | Existing X=±22 and Z=-74 civic corridor stays open |
| Civic workshop bank loop | 3.70s / 3.70s | 43 actual slope-contact ticks in each direction; 4m→4.65m terrace and descent |
| Market hall bank loop | 3.48s / 3.45s | 43/31 slope-contact ticks; 0m→0.65m raised skirt, angled aisle and descent |

Measured rider peaks include natural crest airtime; they are not new authored floor heights. The geometry owner's independent static route result is 173/0; root's aggregate must confirm it together with the preserved ten-goal career. `topography_tests.gd` now expects **75 checks** (the previous 60 plus these 15), and the new cat module adds 38. No earlier route assertion was removed or relaxed. A later retaining-side winding correction changes rendered triangle direction only; the geometry owner's control comparison reports identical 247 collision shapes/transforms and terrain registries, preserving the physical route fixture.

Clean current focused logs: `.local/cat-qe-visible-first.log` and `.local/courts-qe-first.log`. The earlier `.local/cat-qe-final.log` is the 33-check pre-visibility result, superseded for payoff behavior. Both current probes use `--fixed-fps 60`, not `Engine.time_scale`. The full ordinary-scheduler run, current rendered evidence and package identity remain separate gates. No human difficulty, real controller, Mac performance or final-art acceptance is inferred.

## Previous nonlinear extension: retained evidence

At the previous accepted checkpoint, `topography_tests.gd` contained **60 checks**, including all 33 earlier terrain checks, 24 new branch/clearance checks and three local combo checks. The focused final branch/outdoor runner passed **30/0**; the independent local-combo probe passed **3/0**. Root's subsequent ordinary aggregate passed 955/0. This retained evidence predates the court/workshop extension above.

| New physical connection | Forward / reverse fixed-60Hz time | Evidence |
| --- | --- | --- |
| Station low-level close | 6.07s / 6.07s | Real movement beneath both suspended 5m decks; independent rays prove the 2m floor, downward-facing 4.6m underside and upward-facing 5m deck |
| Merchant Close cut-through | 4.47s / 4.47s | Every angled bend traversed between 2m and 4m support |
| Kelvingrove cutback return | 9.25s / 9.28s | Branch/fork transit between approximately 4.5m and 11m |
| Clyde print-yard loop | 6.83s / 6.83s | All sides of the closed angled pocket traversed on 2m paving |
| Clyde curved bank and hip | 2.33s / 2.42s | Genuine curved ascent/descent, natural crest airtime and return to supported ground |
| Merchant service-court east escape | 2.25s / 2.25s | Physical slope contact and correct 1m↔2m endpoints |
| Merchant service-court west escape | 1.88s / 1.80s | Physical slope contact and correct 1m↔3.75m endpoints; natural uphill crest airtime |

Every route reaches each intermediate waypoint in both directions with **zero bails and stalled frames**. The final check includes the added lower service court, both real escape banks, trimmed park curb/grind rail, extended park embankment and cleared yard paving. The existing full Central→park circuit→Central route also passes after these corrections: **29.30s**, 868 non-flat contact ticks, no stalls/bails. Its observed rider peak of 18.11m includes natural airtime above the 17m path.

Independent collision rays on the curved bank find **five distinct 5-degree slope bins**, with a sampled maximum of **31.06°**, within the authored 35° limit. These are actual collision normals, not a pass inferred from shape metadata. Highest-support queries intentionally return the upper station deck; the low route uses physical floor/ceiling rays and actual movement to establish the separate lower passage.

The new local combo uses actual push and ollie inputs to acquire the print-yard ledge, rides it, rail-ollies into Kickflip + Melon Grab, enters a manual after real landing, then releases. Observed events are **Ollie, Rail Grind, Ollie, Kickflip, Melon Grab, Manual** with no bail. The line stays unbanked until release, then banks exactly **5,000** once: `(100 + 200 + 50 + 300 + 250 + 100) × 5`. A second waiting period cannot award it again. This establishes one genuine local rail/air/manual opportunity without claiming human comfort or replay appeal.

The unchanged all-ten career circuit passes **13/0** after the Merchant entrance repair: all goals by **75.20s**, return at **88.00s**, 1,199.52m, 20,000 banked/3,200 best, no bails/stalls. These are fixed-60Hz results; the final ordinary aggregate including the later service-court additions remains root's separate gate. The world owner reports **157/0** static support/clearance checks on final geometry; independent QE previously reproduced 148/0 before the hip/service-court additions, so root's final aggregate must confirm the complete current static set.

## Glasgow encounter integration

`glasgow_encounters_tests.gd` passes **30/0**. A real ground approach and mapped interaction start Mo's Big Finish; an actual Ollie + Kickflip + Melon Grab banks 1,950 and wins once. A replay using actual Frontside spin input also succeeds; repeated checks do not duplicate wins. Tests cover proximity, same-combo family diversity, short banks, leaving/re-entering the court, pending-combo replay rejection, pause, deadline, real manual-balance bail, restart, run expiry/results input and free-skate persistence. The ten original career/save goal IDs remain unchanged, and tests disable profile writes.

Audio checks decode the original PCM and establish nonempty bounded samples, a quiet loop seam, spatial range, master/ambience multiplication, both mute paths, and animation/process pause/resume. The Dummy driver deliberately skips playback; no audible quality, accent or hardware listening acceptance is implied. Actor appearance is covered by separate retained renders.

Clean focused logs are `.local/nonlinear-qe-service-final.log`, `.local/localcombo-qe.log`, `.local/encounters-qe-final.log` and `.local/career-nonlinear-final.log`. Earlier nonlinear runs are superseded where geometry changed. The existing temporary runner recipe below applies; the frozen production runner calls the new modules directly.

## Earlier terrain checkpoint: retained regression coverage

| Source suite | Result | What the checks establish |
| --- | --- | --- |
| `world_routes_tests.gd` | **136 passed, 0 failed** | Six classified/supported/clear checkpoints; actual collision and bidirectional capsule sweeps for continuous authored routes; retained objective support/clearance, Central gap break, NPC and cone checks |
| `topography_tests.gd` | **33 passed, 0 failed** | Exact district levels, real grade transit, curved coping capture/release, physical Clyde and park travel, successful bridge ollie and failed-jump recovery |
| `career_integration_tests.gd` | **23 passed, 0 failed** | Existing progression/special boundaries plus actual climb to the new 5m Central platform, ollie across its break, award/bank/reset |
| `presentation_integration_tests.gd` | **9 passed, 0 failed** | Real stone/asphalt/metal floor contact, new readable location name, marker/count feedback and protected-save warning |
| `career_route_tests.gd` | **13 passed, 0 failed** | All ten original goals in one 120-second career, four physical checkpoints and six linked graded boundary-combo directions |

These are earlier focused module counts, not current aggregate totals or a substitute for rerunning changed geometry. All four core checkpoint positions are passed by the career circuit; the topography driver's actual motion passes the Clyde and Kelvingrove checkpoint positions. Profile persistence is disabled except the existing protected-save test's unique ignored fixture path, whose bytes are preserved and file removed.

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
- The first new Merchant Close foundation created an unintended curb across the retained Central concourse route, stopping the rider at approximately `(-70.737,2.012,-37.726)`. The geometry owner kept the close mouth flat at 2m until it leaves the concourse and starts climbing beyond Z=-42. The original career test then passed unchanged; no detour, collision bypass or weakened assertion hid the defect.
- Mo's family classifier initially missed the production names `Frontside 180` and `Backside 360`. The feature owner corrected the parser. Public-callback family checks and a real spin-input winning line now pass.

## Local evidence and rerun

After the final colliding grass embankments were added below the Central and George park connectors, the complete static world-route suite was rerun: **136 passed, 0 failed**, exit 0, with no engine/script errors. Every sampled support and bidirectional capsule sweep still passes. This focused follow-up is `.local/world-routes-final-embankment.log`; root retains the final aggregate responsibility.

Clean focused logs: `.local/world-routes-redesign.log`, `.local/topography-final.log`, `.local/career-integration-redesign.log`, `.local/presentation-redesign.log`, `.local/career-redesign.log` and `.local/career-redesign-ordinary.log`. Assertions and engine-error scans pass. No downloaded testing dependency is used.

Use the temporary runner recipe in CAREER-ROUTES, replacing its preload with the desired test module. The topography, encounter, career integration and presentation modules accept `(tree, game, check)`; world routes accepts `(tree, game.world, check)`. For a fast focused run use `./tools/run.sh --headless --fixed-fps 60 --script .local/<runner>.gd > .local/<log>.log 2>&1`, then scan the complete log. The topography route timings above use this fixed-delta mode. The earlier all-goal career circuit passed ordinary scheduling at 75.33s to all goals and 88.13s to return before the nonlinear extension.

All affected source tests are wired into root's `tests/run_tests.gd`; `./tools/check.sh` is the aggregate import/test gate. New rendering/collision edits still require the appropriate rerun. Passing focused modules does not certify final visuals or replace the pending human/hardware gates.
