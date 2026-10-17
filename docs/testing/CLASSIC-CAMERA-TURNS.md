# Classic handling: turns and chase framing — 17 October 2026

Owner: A04 controller/camera implementation; A09/root owns final aggregate, normal-scene capture and Mac/DualSense acceptance. Scope: existing controller and camera only; no new area, paid tool, dependency or commercial-game source/asset.

Read [CLASSIC-TRICK-CONTROLS](../research/CLASSIC-TRICK-CONTROLS.md) for the inspected THPS3/4 manual pages and pinned MIT examples, and [ARCADE-HANDLING-REVIEW](../research/ARCADE-HANDLING-REVIEW.md) for the previous wide-turn diagnosis. The instruction manuals establish control grammar, not physical constants or the commercial camera algorithm. This is original bounded tuning informed by that review, not a claim to reproduce proprietary code or certify equivalent feel.

## Delivered behavior

`game/player/skate_response.gd` now targets **2.8rad/s at rest → 2.2rad/s at 15m/s**, retaining the exact 0.10s exponential response and angle integral. Previously the full-speed rate was 1.1rad/s. An ideal steady 15m/s full-input circle therefore changes from **13.64m radius / 27.27m diameter** to **6.82m radius / 13.64m diameter**. Those are source-derived steady values, not measured city trajectories.

Analogue input is `0.75×input + 0.25×input³`: symmetric, continuous, full strength unchanged, with useful fine corrections and no additional deadzone. Quarter input produces 19.14% of full-rate steering; half input gives 40.625%. The existing mapped device deadzone remains authoritative. Camera sensitivity never changes physical steering. Coast, speed cap, braking and signed slope gravity are unchanged by this helper change. Its bounded air-correction API remains available; root's new player air-spin contract owns whether it is called during flight.

`game/player/chase_camera.gd` uses a moderately lower rear view: normal nominal height **2.7m** (previously 3.4m), low obstruction candidate **1.95m**, rear distance **5.8m + 0.035×horizontal speed**, and **66° + 0.25×speed** FOV. At 15m/s those are 6.325m and 69.75°. Modest lookahead grows from 0.35m to at most 1.175m, scaled down when collision shortens the arm. Reduced motion fixes distance, lookahead and FOV at 5.8m / 0.35m / 66°; ordinary collision repair still operates.

The camera follows body-facing travel during regular skating and switches behind sustained reverse travel only after **0.28s** above 1.2m/s with a clear backwards alignment. Returning forward requires **0.22s**. Near rest or sideways motion holds the selected direction and clears a pending reversal. This prevents a zero-speed ramp apex or brief collision impulse flipping the chase repeatedly. Camera orbit interpolation travels around the rider rather than through the torso. Cosmetic board flips and rider spins do not feed this heading.

All existing collision mechanisms remain: a 0.25m camera sphere, chest-to-camera arm sweep, moving camera-volume sweep, alternate side/height candidates, stable blocked-side selection and delayed return, minimum useful arm, and independent board/chest/head visibility rays. When the controller exposes `transition_active` and `transition_normal`, the anchor and all three body visibility points follow that contact normal. `look_at` retains world-up so riding a quarter wall does not roll the horizon. No camera code writes rider movement, speed, heading or transition state.

## Focused measured checkpoint

`tests/skate_response_tests.gd::run(check)` plus `tests/camera_turn_review_tests.gd::run(tree,check)` completed **61 passed / 0 failed**, exit 0, with a clean script/engine/error scan. The new asynchronous module contains 24 checks; the pure response module contains 37. They are intended to run inside the ordinary aggregate; do not add this count to the aggregate result. Root records final integrated evidence in STATUS.

The actual-input tests create a large isolated supported floor, settle an ordinary production skater, push to the requested initial speed, release push, and turn for one second using mapped quarter/half/full action strengths. They do not assign per-frame position, speed, camera or heading. These are **coasting** turns, so initial speeds below are not held constant. Angle accumulates each actual frame's yaw difference to avoid wrapping a legitimate turn beyond 180°.

| Initial speed | Final speed | Input | Actual turn | Distance | Effective radius, distance/angle |
|---|---|---|---|---|---|
| 8.000m/s | 5.644m/s | 0.25 | 24.926° | 6.763m | 15.546m |
| 8.000m/s | 5.643m/s | 0.50 | 52.904° | 6.763m | 7.324m |
| 8.000m/s | 5.644m/s | 1.00 | 130.226° | 6.763m | 2.976m |
| 12.000m/s | 8.918m/s | 0.25 | 23.485° | 10.382m | 25.329m |
| 12.000m/s | 8.918m/s | 0.50 | 49.845° | 10.382m | 11.934m |
| 12.000m/s | 8.918m/s | 1.00 | 122.696° | 10.382m | 4.848m |
| 15.000m/s | 11.375m/s | 0.25 | 22.404° | 13.097m | 33.494m |
| 15.000m/s | 11.375m/s | 0.50 | 47.551° | 13.097m | 15.781m |
| 15.000m/s | 11.375m/s | 1.00 | 117.048° | 13.097m | 6.411m |

All **540 turn samples** retained a finite camera, visible board/chest/head and clear sight lines. An actual supported 20° bank rollback, starting with a held brake and then releasing it, ended at **−2.489m/s** after three seconds. The camera's horizontal rear direction dotted with actual travel was **−1.000**: behind the backwards travel. All **180 rollback samples** retained the same visibility checks and support. Pure timing checks also reject a brief reverse impulse and clear pending reversal at noisy near-rest speed.

The first attempt was rejected as evidence because another agent's in-progress visual script had a temporary type-inference parse error. The clean rerun above followed its repair. The focused test does not render pixels, exercise city walls, prove transition contact, estimate frame times or establish physical controller comfort. Root's existing full city camera/support tests and actual normal-scene/transition captures remain necessary; no existing occlusion assertion was weakened.

## Integration and remaining acceptance

- `camera_turn_review_tests.gd` must be awaited from the ordinary test runner after the response checks. Its input cleanup releases all mapped actions and frees only its own fixtures.
- Existing route tests which compare only the start/end wrapped angle of a two-second full turn need to accumulate actual frame deltas: the tighter valid turn can exceed 180°. Keep distance, support, occlusion and natural-input requirements intact.
- Root owns the transition-body visual/contact contract and actual half/quarter-pipe camera captures. A tilted ray fixture alone cannot certify that integration.
- Capture the existing natural spawn, fountain, shopfront wall, station low ceiling, gallery columns, quarter-wall apex and sustained reverse ramp motion. Review board visibility, horizon, landing-space view, camera orbit direction and comfort on the owner's Mac with a physical DualSense.
- Right-stick inspection and selectable locked camera positions described by the manual remain follow-up work; this bounded chase change does not claim they are implemented. No manual-camera takeover is needed for tricks.

Human subjective feel, camera comfort, Mac rendering and Apple Silicon performance remain open gates. The final ordinary result and evidence package belong in [STATUS](../STATUS.md); this document does not independently close them.
