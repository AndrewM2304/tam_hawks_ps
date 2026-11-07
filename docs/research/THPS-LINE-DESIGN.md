# Compact skating lines: reference study and November candidate

Research date: 6 November 2026. Owner: level-design specialist. Active baseline: main `0b62035`; October 17 alpha measurements and earlier unmerged court experiments are historical and are **not** measurements of this baseline. Read current [density requirements](../planning/LEVEL-DENSITY-NEXT.md), [PT24 remaining work](../planning/PT24-REMAINING-2026-10-27.md), [benchmark](../product/AAA_BENCHMARK.md) and [tickets FID-401–404](../planning/FIDELITY_TICKETS.md) together. Existing default-on station/train, compact Clyde, pond/cable, green/civic and authenticated native movement remain the starting implementation.

## What was actually researched

The separate [primary construction review of coping proportions](COPING-PROPORTIONS.md)
compares the inherited 70 mm exposed crown with real design guidance. Its private
60 mm OD / 12 mm up / 10 mm out prototype changes native/display/guide datums
together and requires fresh contact, route and visual evidence before promotion.

This is a source-based study of published developer testimony and player guides, not a claim to have played the commercial games or measured their original geometry. No franchise layouts, art, names, signs or music are copied into the game. Observations below are attributable descriptions; recommendations are our own inferences.

| Reference | Observed source facts | Original design inference |
| --- | --- | --- |
| [Mick West developer interview, CoRecursive, 2 April 2024](https://corecursive.com/game-programming-with-mick-west/) | West describes changing from downhill progression to discrete levels; skate videos informed meaningful skating spots. The school was planned around stairs, rails, a pool, walls and objectives. Testing and immediate player feedback informed iteration. | Begin with recognizable skating situations and player actions. Iterate actual input runs through a few useful arrangements before filling the world with decorative objects. |
| [Warehouse, Stephen Tailby, Push Square, 4 March 2025](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-warehouse-all-park-goals-gaps-and-challenges) | The guide identifies a central rail, paired kickers, rear quarter pipe, upper deck and halfpipe. Named gaps connect deck to rail and opposite sides of the channel. | A bounded room makes the central obstacle, perimeter return and elevated option legible together. One landing can prepare a different next action; repeated straight acceleration is unnecessary. |
| [School II, Stephen Tailby, Push Square, 4 March 2025](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-school-ii-all-park-goals-gaps-and-challenges) | The guide describes the starting stair/rail, library approach, lower court buildings and roof gap. A quarter pipe and planter participate in access to the library roof; several rails are individually recognizable objectives. | Larger environments can work as linked local courts. Grade changes, stairs and elevated alternatives should concentrate decisions around landmarks while leaving ordinary ground access understandable. |
| [Marseille, Stephen Tailby, Push Square, 4 March 2025](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-marseille-all-gaps-and-collectibles) | The guide lists bowl, spine, box and curved-rail transfers. “Ledge 2 Rail” and “Rail 2 Ledge” describe reciprocal transfers around the same curved yellow rail; “2 the Box” connects that rail to a funbox. | An obstacle with useful approaches and exits in both directions earns its footprint. Put turnarounds near the end of a sequence so players can repeat, reverse or branch without a long transport leg. |

The supported principles are compact visibility, distinct action sequences, vertical/ground alternatives, reciprocal connections and immediate replay. None of these sources establishes a universal metre spacing, a copied optimal map, or guaranteed fun. Each source's paraphrase above is brief; no commercial diagram or screenshot is reproduced. Foundry was considered during discovery but a sufficiently inspectable source was unavailable, so no Foundry layout claim is used.

## Current map diagnosis

The latest main already implements far more than the stale alpha: transition bowls/halfpipe/spine, graded park returns, fountain/stair/entrance chain, recording-yard loading kerb, civic back-street seat, station bank handoff, compact bridge/yard returns and native contact-aware semantic ledges. Recreating those would add repetition and resource cost. Existing historical source-bound receipts remain valid only for their recorded source.

A fresh ordinary-Main inventory (`.local/level_inventory.gd`, personal Music disabled before tree entry) measured authored navigation polylines, not time between tricks:

| Existing route | Polyline length | Interpretation |
| --- | ---: | --- |
| `exchange_fountain_loop` | 148.000m | Enclosing beginner/navigation loop, not one demonstrated combo. |
| `exchange_south_line` | 22.075m | Two banks and raised deck; originally E/W at `(0,0,34)`, separate from the fountain's west exit. |
| `clyde_north_quay` | 220.258m | Includes approaches; its central straight is 156m. Coping/transition choices exist on its western portion. |
| `clyde_safe_crossing` | 58.115m | Deliberate bridge transport with retained supported recovery. |
| `clyde_print_yard_loop` | 190.513m | Enclosing navigation loop; length alone does not establish repeated trick decisions. |
| `clyde_south_east_west` | 73.132m | Existing useful curved-seat/rail relay and safe through route; preserve rather than duplicate. |
| `station_transition_handoff` | 30.059m | Existing spine/bank/halfpipe relation. |
| `kelvingrove_rolling_loop` | 252.488m | Scenic traversal; blanket claims that this is one dense combo circuit would be misleading. |

Independent QA's clean-main ordinary captures show the strongest local deficit on the **east north quay**, between transfer bridge X20 and Barras arrival X78: approximately 58m of visually repetitive paving. Two short seats were offset from travel at X8 and X70/Z59. Existing embankment edges mean this is not literally an absence of every possible grind; the defect is the lack of a visible, purposeful middle sequence and re-entry. Baseline Exchange overview also shows the existing south bank as an isolated cross-court object instead of a continuation from fountain exits.

Baseline images are durably preserved in [the independent baseline packet](../testing/fidelity-2026-11-06/baseline/README.md) (`clyde-east-quay.png`, `overview_exchange.png`, plus all six overviews). These are actual captures reviewed by LD and QA, not diagrams. Root/QA own durable manifests and current-source publication.

## Candidate experiments

1. **Exchange west fountain exit.** Reorient the existing bank/manual deck 90 degrees around new centre `(-10,0,20)`. Native footprint becomes X[-12,-8], Z[13,27]; approaches lie on Z9 and31. This puts a bank/manual/ledge choice beside the fountain's west release and points toward the west quay close. The exact Z28 beginner crossing remains outside its native toe; the original teaching rail, gallery/stair east-side chain and career markers stay fixed. Transform physical mesh/collision, guide author, support probes, terrain corner heights and published feature/route points together. No new geometry/resources.
2. **Clyde east seating relay.** Recompose the two existing seats/support pairs into elongated public seating at `(42,2,64)` and `(64,2,64)`, second seat yaw15 degrees. Each reuses its original body, shape, mesh and finishes; length5.6m makes an actual finite bearing visible from entry. Original semantic guide identities are explicitly retained while endpoints follow native shapes. Only these inspected BoxShape tops opt into exact native crown/rotated outward-face/owner-RID contact; unknown legacy semantic guides are not globally certified. The intended input run must prove named two-truck50-50 poses and actual board/capsule clearance, not count a generic short end-cap catch as the long bearing. The cross-quay Z69 route and four-metre Z68–72 bypass remain open. This creates a staggered grind/manual/turnback option inside existing retaining walls rather than adding a district or repeating bank modules.

3. **Terminal bank and enclosed return.** Rebuild the existing eastern end wall's native shape slots and single masonry display as a closed bank/wall profile: toeX80.8, kneeX84.7,2m rise over3.9m, then visible/native vertical backing toY7. The exact existing end-wall span defines its width. This provides a visible graded end to the seating sequence and a native uphill/coast/fakie return. The earlierY5backing failed actual maximum-speed uphill pops; the Y7candidate contained those bodies but exposed airborne board/sole clipping. Motion's subsequent finite-wall repair now passes all four original adverse native cases; inspected same-source visual movement remains open. Physics uses0.28slope-gravity scale, so entry-speed range must be measured rather than assuming a quarter-pipe response. Terrain queries use the same plane. Body/shape/mesh/material/texture counts remain constant; the closed six-corner profile adds8triangles per existing panel and needs explicit performance admission. The diagonal Barras mouth and its shoulders must remain open. No extra district or repeated bank module is added.

These are experiments until native input, misses, clear chase, approach/exit support and matched after images establish their actual behavior. Bench-to-bench centre spacing22m is **not** evidence of a single unbroken combo; actual event intervals and banking must be measured. Existing two-distinct-returnable-lines-per-core-arena and three-cross-arena-circuit acceptance remains stricter than this local intervention and remains open until independently demonstrated.

## Verification and limitations

Required: preserve all legacy route/feature IDs, all six checkpoint mouths and career/encounter access; verify native terrain/query parity after rotation; input-drive bank/manual crossing and the old gallery/Exchange chain; catch and release real seating bearings; exercise misses and both bypass directions; inspect same-view after frames. Record failures before changing drivers or geometry, and retain positive/negative evidence. Budget-neutral means counts must be measured, including edge snapshots; it does not imply unchanged GPU time.

The [7November focused native checkpoint](../testing/line-design-2026-11-06/focused-native-2026-11-07/README.md) records326/0 in its declared scope. Actual first catch→manual landing→second catch occur at physics578→648→807, with continuous ordinary input and exact long-bearing identities; actual second-bearing pop→native paving landing are880→910. Both contact-bearing board release frames remain continuous before capsule travel, then actual GLB components clear on subsequent initial airborne physics steps. The independent articulated Rider root is not frozen to satisfy that contact oracle. Resource addition is measured32triangles,0added bodies/shapes/meshes/materials/textures/lights. Those counts do not establish unchanged frame time.

The real bank return works after the relay, but its long safe-bypass leg remains39m/570physics frames=9.50s with no trick. It is **transport**, not evidence of a meaningful repeatable trick circuit. An opposite-bearing/reversal route and a stronger coherent enclosure remain independently actionable design work after this checkpoint. Two small benches in broad paving do not meet the intended whole-map visual/density benchmark.

The [later maximum-speed uphill-pop probe, FID-D012/P1](../testing/line-design-2026-11-06/rejected-top-escape/README.md), found a more demanding failure: two naturally15m/s charged Ollies cleared theY5backing into unsupported ground; a third input exposed chase occlusion. Passing no-jump8/12m/s rollback did not establish jump containment. A coherent visible/native Y7upper-wall profile using the same slots/resources contained all four exact inputs, but [actual airborne board/sole markers still clipped its face](../testing/line-design-2026-11-06/rejected-top-escape/y7-native-contained/README.md). The [current-order native checkpoint](../testing/line-design-2026-11-06/current-order-native-2026-11-07/README.md) now passes158/0, including all42LineDesign assertions after32MotionMain and84independent manual cases. All four original adverse jumps have native landings, strict every-air1mm capsule/GLB/shoe/chase clearance and rejected foreign-owner/loaded-floor faults;261script/scene inputs remain stable. Maximum observed loaded floor-normal capsule depth0.610303mm is distinct from existing15mm native solver safe_margin and is not an air/visual allowance. Corrections reaching105–120mm still need actual visual inspection. Whole integration, affected routes, final movement, performance and AAA acceptance remain open. No invisible support or velocity clamp is used.

The [rejected wrong end-cap captures](../testing/line-design-2026-11-06/rejected-short-edge/README.md) demonstrate that simply retiming a generic catch did not establish the intended line. The [rejected development trial](../testing/line-design-2026-11-06/rejected-early-exit/README.md) preserved a genuine two-seat catch/manual sequence and an early seat-landing visual defect, but contains rider import errors and is not acceptance. Its observer counts71/141/305 are not elapsed physics time; current receipts use `Engine.get_physics_frames()`. Final owner fun/visual review, complete per-arena line coverage, cross-arena acceptance, actual M5 Air performance and AAA finish remain open unless specifically measured. This study does not certify them.

## Next existing-geometry experiments after the checkpoint

The priority is replacing the measured9.50s trickless transport leg, not adding more audit metadata or counting the same bearings backwards as a second distinct arena line. Derive all physical endpoints from actual `boundary_points`/native shapes and guide points, then investigate these ordinary-input choices:

- **Long landward masonry return.** The real opaque east `QuayLandwardBoundary` begins atX15 and ends at the computed east approach join, alongZ55.2. Its existing native face is wallrideable. The second-seat landing near`(68,2,62.7)` could lead via Manual and a glancing pop onto that wall travelling west, then a Wallie south into the supported quay, Manual and the first bearing back toward entry. Contact intervalX50–66 lies inside the existing face. This would earn a different support/action sequence within one repeatable relay; it is not yet a demonstrated line. Prove actual wall identity, finite contact/connected-model clearance, release landing and every meaningful-opportunity interval before retaining it. No new objects/resources are proposed for this experiment.
- **Terminal oblique cross-area exit.** The new bank's upper wall is only6.18m wide. Current native wallride admission requires a glancing trajectory with `abs(closing)/planar_speed <= 0.8` and at least3m/s tangent speed; a head-on bank pop cannot become a useful wallride merely by holding Grind. An oblique north-going ride could release toward the supported Barras mouth, but short face length, its finite crown and diagonal shoulders are real constraints. Reject a fleeting edge touch that only increases score counts or exits into unsupported ground. It needs an actual useful ride/release, supported next action and negative approaches before contributing to cross-area acceptance.
- **Existing wider network.** Audit the already implemented western transition/coping, safe bridge, print-yard return/loading kerb, park/station handoff and market loading-hall chain before adding geometry. Preserve their source-bound historical proofs, then demonstrate genuinely different current-source sequences and three complete cross-area circuits with actual inputs and physics intervals. A navigation loop, reverse duplication or a successful through journey is not a dense trick circuit.

These remain an actionable investigation queue, not acceptance or a claim that the original games prescribe these arrangements. Current native contact progress does not remove the need for stronger original composition, current inspected after views or the owner's high visual benchmark.


## 7 November — full-regression reconciliation remains open

The first complete required run (`required-01`) was rejected: 6,311 checks passed,
25 failed, 1,620.781 seconds; all 800 recorded source inputs remained byte-identical.
A focused local positive packet does not supersede that result. Three route-driver
failures were traced to old speed inputs overriding the current W/S Manual balance
controls, plus an impossible final park coast: 6.82683 m/s with unchanged drag
0.75 m/s² and minimum Manual speed 2 m/s permits 28.40374 m; the target required
29.82367 m. The revised driver requests a genuine additional Push/Ollie/Manual
link on the existing supported promenade near X−62. Physics and acceptance
thresholds stay unchanged; this still needs the combined rerun.

The moved Exchange bank also blocks the career circuit's previous straight Z22
leg at X−12.359. That was missed in the initial protection review. The proposed
career input route uses the existing Z28 bypass and retains all original collection
waypoints, six scoring-leg targets, the 120-second run and ten-goal thresholds.
A separate actual Clyde coping contact/presentation failure is owned by the motion
specialist; it is not explained by a driver input migration.

Legacy audit expectations also require explicit, narrow adaptation: the same
55 protected convex boundary prisms remain, while the four native six-corner bank
prisms now have 20 triangles each (740 total versus 708 before), and the shared
stone now has a real normal map. The two inspected seat providers alone publish
six authenticated Box top/face records; the two rotated short endcaps correctly fail the existing 1e−6 perpendicular guard and retain generic metadata. Other semantic sources remain generic.
The new bank genuinely obstructs the far end of the existing long river-curb guide
at (80.98643, 2.055, 77.98). Its stable ID can retain more than 57 m of useful length
by cropping only that end against the real transformed bank vertices and existing
capsule envelope. The old blocked point must remain a native negative; it must
never become an eighteenth “inherited” exception. Native reruns and matched
current-epoch images are pending for these changes.


The subsequent regression-repair packet is
[recorded separately](../testing/line-design-2026-11-06/c04-regression-development-2026-11-07/README.md):
Clyde/Gallery/Park fixes passed in a bounded partial C04 sequence; the default
career/facility/local-line tail completed 212/2 and retains rejection for its fixture
and test-expectation failures; the corrected historical native audit passed 149/0.
The career returns in 90.97 seconds with all 10 goals and zero bails. Actual native
records confirm six authenticated seat faces and two rejected rotated short ends,
with no contact-tolerance change. All 55 protected convex prisms, four closed bank
prisms/740 triangles, malformed native controls, shortened river-curb positive and
original blocked-tail negative pass. Neither partial packet supersedes required-01
or closes D014/current visual/M5/human acceptance. The distinct return route is
still an untested proposal and the 9.50-second trickless transport remains open.


The first [existing-wall feasibility probe](../testing/line-design-2026-11-06/wall-return-feasibility-rejected-2026-11-07/README.md)
is now preserved as a rejected 1/3 result. The east landward masonry actually
extends to X81.00891, not the earlier guessed approach join. A 0.8/0.6 glancing
heading earned 30 native wallride steps/3.087m and a real mapped Wallie, but its
1.777m/s board-forward release could not enter the unchanged 2m/s-minimum Manual.
The more glancing 0.94/0.342 approach reached the wall later in its flight and
landed after 14 ride observations. Both had no bails/recoveries and clear existing
chase checks. The wrapper captured actual process/command/deadline/exit and all
1,010 private source/import-cache inputs remained stable. These are useful
ordinary-input design failures, with no production geometry/physics tuning or
completed return claim. A closer player-controlled pop on the more glancing
heading is a testable next experiment; D014 integration confirmation remains
higher priority than another map run.
