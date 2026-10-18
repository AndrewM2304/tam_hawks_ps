# Arcade response and six-area input audit

This pass addresses the owner's floaty jumps, halfpipe return behavior and rail-input forgiveness on the existing map. Automated input can reproduce movement defects and show the production camera; it cannot certify human fun, a physical DualSense, Apple Silicon frame times or exact Tony Hawk's behavior.

## Baseline observed on 18 October 2026

The first focused native-physics run returned **20 passed / 6 failed**, exit 1, with no script/runtime errors. Retained evidence is [baseline.log](arcade-response/diagnostics/baseline.log), [movement-component hashes](arcade-response/diagnostics/baseline-source.sha256) and [executed test hash](arcade-response/diagnostics/baseline-test.sha256). All three measured movement-component hashes remained unchanged throughout that run. This is a movement diagnostic, not a full-source release receipt.

| Mapped input | Actual result before repair |
| --- | --- |
| Space held two ticks, then released | Apex 1.84554 m above settled origin; 0.816667 s airborne; one Ollie and a physical landing. |
| Space held 24 ticks, then released | Apex 2.36722 m; 0.916667 s airborne; one Ollie and a physical landing. |
| W held for 660 ticks from halfpipe floor | Only east wall visited, then escaped east to X −3.4968; no bail or discontinuous movement. |
| Space held for 660 ticks from halfpipe floor | Only east wall visited, then escaped east to X −4.0298; no bail or discontinuous movement. |
| Held L, ±0.25 m / ±5° initial error | Both caught once, stayed latched on release and exited on a fresh second press without recapture. |
| Delayed released L taps | Both missed under the old flight/input timing. |
| Outside-lateral, expired tap and separating solid | All rejected without a phantom rail award. |

The old halfpipe regression stopped after the first wall rollback and first flat crossing. It could not establish an opposing-wall return or a repeatable cycle. The historical career circuit also assigns its desired heading on grounded ticks; its saved objective results remain fixture evidence, and are not described here as a steering-input-only playthrough.

## Independent checks

`tests/arcade_response_integration_tests.gd` declares each initial body placement once. Subsequent movement uses actual physical-key events mapped by the production InputMap. A separate recorder samples every native physics tick after the player, retaining actual tick IDs rather than assuming one process callback equals one physics step.

- Short release jump: actual apex 0.8–1.1 m and 0.40–0.53 s airborne. Charged release: 1.65–2.05 m and 0.60–0.73 s. Both must crouch before release, award one Ollie and physically land.
- Two actual steep-quarter approaches compare a single wall pop with an immediate second airborne tap. Incoming upward momentum cannot receive a second full impulse, stale street coyote time cannot award another Ollie, and the two actual arcs must agree within 0.10 m / 0.10 s and regain real support within 1.30 s.
- Held Push and held Crouch each require at least four alternating east/west halfpipe visits, without steering, heading assignments or forced velocity. A live face at least 65° steep must produce an upward departure over 1 m/s within 0.25 m of its authored lip height, then a descending airborne recapture of the same face and an opposite-wall visit. Touching a flat/deck first cancels that recapture claim. Finite movement, no bails, no discontinuous jumps and no invented Ollies remain mandatory.
- Perturbed rails vary initial lateral position, yaw and press timing. Released taps and held seeks are distinct; release must retain the latch, a fresh second press must exit, and each catch can award once. Outside-envelope, expired-input and real separating-wall negatives remain.

Later additions extend the real-body matrix to mirrored 20° approaches and a 70° rejection. The 70° case must physically cross a valid lateral/vertical/speed window so an unrelated miss cannot masquerade as angle coverage. Those angle cases pass in the expanded run below; they are not included in the earlier 34-check receipt.

`tests/player_forgiveness_tests.gd` now triggers its late-input fixtures at observed real descent or after landing, with a required event/tick receipt. It no longer assumes the old 28/34/48-frame jump schedule. `tests/grind_ride_tests.gd` retains strict outside-envelope cases, checks both sides of the revised angle boundary, measures horizontal retention without converting a fall to flat-rail speed, and preserves a swept case whose two endpoints both miss but whose actual sub-metre travel crosses a valid window.

The earlier repaired [candidate-03.log](arcade-response/diagnostics/candidate-03.log) returns **34 passed / 0 failed**, with clean import/runtime scans. The tap reaches **1.02028 m / 0.483333 s** and the charged pop **1.98287 m / 0.683333 s**. Both held-input halfpipe trials visit **east → west → east → west → east**, with zero bails, discontinuities or Ollie awards. Single and double-tap wall-pop trials have identical measured launch Y velocity **9.51618 m/s**, absolute apex **4.83970 m** and **0.50 s** flight; each awards one Ollie. Both released rail taps catch, while outside-lateral, expired-input and real solid-obstruction negatives reject. This earlier receipt proves alternating wall travel, not the stricter same-face airborne return below. Required-suite results are recorded separately below.

The expanded [candidate-04.log](arcade-response/diagnostics/candidate-04.log) returns **43 passed / 2 failed**. Both natural-recapture checks fail despite five alternating wall visits; four steep departures are observed in each trial, but zero direct airborne recaptures. The retained [660-tick trace](arcade-response/diagnostics/pipe-trace.json) and [state transitions](arcade-response/diagnostics/pipe-trace.log) confirm genuine deck landings at ticks **416** and **552**, zeroing velocity at Y5.2 before later face acquisition. This exposed a real handoff defect; the gate remains unchanged.

The corrected [candidate-05.log](arcade-response/diagnostics/candidate-05.log) passes **45/0**. Each held-input trial records **five real upward departures, four descending same-face airborne recaptures and six alternating wall visits**, with zero bails. The controller prepares a collision-clear body orientation immediately before the finite descending lip crossing, then lets the ordinary real move/admission determine position and velocity. The exact shared endpoint checks actual curve ownership just inside its last segment. It introduces no infinite support plane or forced launch-position shift.

The [handoff refusal run](arcade-response/diagnostics/handoff-focused-01.log) separately passes **20/0**. After a real mapped-input natural launch, removing/disabling the departed curve, carving beyond its width, a real deflector producing outward travel, or a blocker inside the intermediate body-orientation volume must refuse the handoff. Each scenario requires its actual adverse-condition witness, unchanged controller position/velocity during preparation, an upright refused air capsule and no invented trick award. The outward fixture also requires an initially clear capsule and an actual deflector collision; a roof that misses the player cannot pass as rejection coverage.

A separate physical seam repair removes the old 6 mm halfpipe floor step while retaining the visible floor at exactly its previous world transform. The [39/0 geometry check](arcade-response/diagnostics/geometry-focused.log) and [native toe trace](arcade-response/diagnostics/pipe-trace-seam.json) show tick **634** exiting at Y2.003, airborne false and vertical velocity zero, then tick **635** on real floor with no hop. The earlier [raised-seam trace](arcade-response/diagnostics/pipe-trace-fixed.json) records five toe exits at ticks 177/297/410/523/636 with upward speeds **1.19–2.08 m/s**, all still airborne on the next tick. The repaired trace has five exits at ticks 177/295/408/521/634, each at zero vertical speed, airborne false and real floor support on the following tick; no velocity/gravity adjustment was made for this seam repair. New combined checks require at least two such low toe exits in each repeated-input trial; ordinary vert flights are excluded from that predicate. The combined **67-check** arcade module passes within the rejected required-suite run below; this does not make that whole run acceptable.

The wall-pop trial also exposed a real intermediate failure: restoring an upright capsule while still embedded against a steep wall caused a bail/reset, after which another tap could jump from spawn. The corrected implementation must clear the actual curve before restoring the upright body, and must admit/award a wall pop only when that departure succeeds. The failed intermediate candidate is retained as diagnostic evidence; it is not a passing result.

`tests/edge_grind_integration_tests.gd` additionally uses actual Main and newly registered physical planter, market-counter, front bench and safe bridge-rail edges. The corrected [focused run](arcade-response/diagnostics/edge-focused-02.log) passes **24/0**: exact selected world IDs, one catch/award each, actual clear-capsule travel **0.4353 / 0.4949 / 0.4353 / 0.4885 m**, and fresh mapped exits with zero bails. This is actual movement on four selected edge families, not a claim that every registered edge is playable.

The first [edge diagnostic](arcade-response/diagnostics/edge-focused-01.log) returned 20/4: all movement checks passed, while four initial-standing query checks failed. The independent [idle probe](arcade-response/diagnostics/idle-probe.log) found eleven consecutive supported ticks at unchanged Y **0.000505708 m**, velocity zero, with only the floor in a query expanded by **0.001 m**. This was query-skin floor contact rather than idle instability. Only the standing diagnostic volume now lifts by the existing native **0.015 m safe margin**, while retaining an actual floor-ray/height check and ten consecutive stable ticks. The player is never moved by that measurement, and every active grind-clearance query remains strict and unshifted.

## Required-suite and contract follow-up

The first required `./tools/check.sh` run on **68781fc** is **rejected: 1,960 passed / 38 failed**, exit 1. Its [receipt](arcade-response/failed-check-01/receipt.json) records all **346 inputs unchanged during execution**, and retains the full failed log. Passing focused modules and rendered segments do not override this required-suite failure.

The subsequent [scoped physics run](arcade-response/diagnostics/regressions-physics-01.log) passes **151/0**, exit 0 with a clean log, covering the revised steering contract, complete classic trick integration and grind regression. Its three participating test files remained stable during that scoped run; other disjoint test repairs were still in progress, so this is not a new full-source release receipt. These physics follow-ups correct test expectations without reverting production tuning:

- Steering asserts the intended **0.055 s** response and independent **2.2 rad/s** exponential model, including exact elapsed-time agreement at 30/60/120 Hz, analogue shaping and mirrored signed-speed behavior. It replaces the old 0.1 s expectations rather than widening them.
- A charged real jump replaces the classic fixture's obsolete 34-frame tap-jump wait. The one-tick mapped Triangle press occurs during observed descent at **Y1.832473 / vertical speed −2.866666 m/s**, still above admission. Press tick **2520**, release **2521**, and actual catch **2525** establish **83.33 ms from request to catch, 66.67 ms after release**; the player cannot capture while the button is held, the captured ID is exact, one award is mandatory, release remains latched and a fresh second press drops.
- The natural vert check observes exactly **two actual physics ticks** and requires the intended **34 m/s²** decrement: vertical launch **7.079565** becomes **5.946231 m/s**, while horizontal momentum remains within the original 0.05 m/s gate. This replaces the stale less-than-1 m/s decrement assumption with a strict ballistic expectation.

A fresh required full-suite pass remains pending. Focused counts are not added together to manufacture an aggregate.

## Support and rendering scope

The refreshed [support audit 04](arcade-response/support/support-audit-04.json) classifies **20,620 queries**: 15,259 supported, 1,321 occupied by actual scenery, 2,606 unmapped and 1,434 intentional hazards. It reports zero finite-floor mismatches, route-offset holes or boundary/crossing faults. All **22 executed geometry input hashes** are stable before/after at that run, including the physical toe repair and rejected-art default policy. Two later visual changes remove the floating rear CENTRAL caption and replace the halfpipe floor's visible box with a top-only plane; those files no longer match the older audit byte for byte. Their collision construction is unchanged, and the refreshed geometry check below separately validates the current physical floor. Earlier audits remain retained for diagnosis.

The current [geometry run](arcade-response/diagnostics/geometry-focused-02.log) passes **40/0**, checking both the unchanged physical flat-to-toe support at 2.000 m and the two visible triangles' original four top corners at 2.006 m. The [floor visual experiment](arcade-response/floor-visual/README.md) separately retains its rendered before/after evidence and source binding; it does not replace physical collision checks.

The 4 m grid can miss smaller holes; route offsets and boundary joins supplement it. These queries do not establish a full gameplay tour or successful aerials. Candidate murals also remain **off in normal play** after a source-stable profile failed the strict frame-spike gate; saved preview frames are not live-art acceptance. No target-Mac performance gain is claimed.

## Six rendered traversal segments

Run locally when no competing engine/render jobs are active:

```sh
./tools/area_audit_play.sh --private-display
```

On the Mac, use its native desktop and omit `--private-display`:

```sh
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/area_audit_play.sh
```

The tool creates production Main with persistence disabled, starts Free Skate, and retains the production skater, chase camera, HUD, collisions and native render loop. The explicitly declared capture setting is 960×600 with the actual Performance preset; this is coverage evidence, not a performance comparison. It performs six independent traversals, each with a declared supported initial fixture and at most 26 simulated seconds:

| Area | Traversal |
| --- | --- |
| Royal Exchange | First two sides of the existing fountain circuit. |
| George Square | Existing civic workshop bypass. |
| Central Station | Existing low-level service walk and concourse return. |
| Barras | Existing inner market loop. |
| Clyde | Declared gentle weave inside the existing north-quay corridor. |
| Kelvingrove | First 65 m of the existing rolling loop. |

A separate **12 simulated second halfpipe stage** starts at the declared floor fixture (−22, 2.8, 60.5), holds mapped W only and requires at least four alternating real wall visits plus an upward departure → same-face descending airborne recapture → opposite-wall sequence, without bails or discontinuities. It retains a per-physics-tick trace and native production-chase images approximately every 0.75 simulated seconds. It is stored separately in the manifest and does not inflate the six-area count.

During movement a feedback driver submits binary mapped W/S/A/D events. It never assigns position, rotation, speed or velocity after the initial fixture. Each segment must reach its final waypoint, travel at least 20 m, physically enter its named district, remain within the declared 5.5 m corridor and avoid bails/discontinuous recoveries. Trace files retain actual positions, headings, controls, support, trick states, district and waypoint progress on every physics tick. Native post-draw captures record the ongoing production chase; PNG readbacks do not freeze or replace that camera.

The output directory retains the command, engine log, executed driver, before/after input hashes, per-area traces, PNGs and manifest. Changed source, runtime errors, incomplete routes or invalid camera framing reject the run. Six independent fixtures are **not** a continuous between-district tour, completion of all 48 routes or a human playtest.

The final actual native rendered run at checkpoint **68781fc** passes with a clean log, exit 0 and **346 unchanged executed inputs**, independently verified against its executed source inventory. Its [manifest](arcade-response/area-final/manifest.json), [source-bound receipt](arcade-response/area-final/receipt.json), seven traces and all 41 frames are retained. The archived executed driver also matches its bound source hash. Linux X11 used Godot 4.6.3 Compatibility with llvmpipe, native 60 Hz physics, time scale 1 and the declared Performance preset. All **41 generated PNGs** were independently decoded, verified as 960×600 and checked against the receipt's file hashes; the review covers 24 ordinary-area images and 17 separate halfpipe images. Later test-contract repairs differ from that captured inventory and require the fresh full-suite check above; no later production physics change is represented by this receipt. The earlier [3620363 diagnostic](arcade-response/area-diagnostic/receipt.json) remains retained separately.

| Actual segment | Distance | Simulated time | Native trace rows | Maximum corridor deviation |
| --- | --- | --- | --- | --- |
| Royal Exchange | 73.27 m | 13.47 s | 808 | 0.84 m |
| George Square | 77.61 m | 14.52 s | 871 | 0.74 m |
| Central Station | 81.81 m | 15.23 s | 914 | 0.92 m |
| Barras | 72.21 m | 13.77 s | 826 | 0.76 m |
| Clyde | 95.72 m | 17.17 s | 1,030 | 0.35 m |
| Kelvingrove | 65.30 m | 11.83 s | 710 | 0.10 m |

Every segment completes with **zero bails, discontinuities or stalled ticks**. All 5,886 recorded rows, including the separate pipe stage, have consecutive actual physics tick IDs and 1/60-second intervals. Kelvingrove has 26 airborne flags across 21 brief spans of one or two ticks while following its sloped path; this is not a sustained airborne phase or evidence of a fall through the map.

The separate W-only pipe stage records **122.46 m over 12.12 simulated seconds**, six alternating east/west wall visits, **five real upward departures and five descending same-face airborne recaptures**, followed by an opposite-wall visit. It records no bail or discontinuous recovery. Full-size supported-wall and apex frames show the actual board and body with the production chase camera; no custom capture orientation or pose was substituted.

Independent inspection of the 41 stills found the skater/board visible and HUD within the frame, without a new camera obstruction or obvious ground hole along these sampled routes. Current architecture and character art remain an alpha visual treatment. Sparse stills cannot establish absence of temporal shader flicker, target-Mac frame time, controller feel or human fun; those remain separate acceptance work. The required ordinary full-suite result remains pending.
