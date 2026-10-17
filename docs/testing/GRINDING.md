# Rail and continuous-combo verification

Updated 17 October 2026. Six authored rails now support acquisition, signed travel, balance, release/ollie/end exits and connected air→rail→ground/manual combos. Manuals, reverts, special charge and named gaps are enabled. Human controller line trials and M02 acceptance remain open; holding a ride still awards no duration points.

## Implementation and controls

- Hold **L / R2** for an eligible air capture and to sustain the ride. **A/D / left-stick left-right** correct balance. **Space / Cross** ollies off; releasing grind drops off. These are remappable defaults; Triangle/R remains restart.
- Capture chooses the nearest eligible clear rail within 0.65 m, vertical reach 0.45 m and at most 0.10 m below the track. Horizontal approach is within 55° of either travel direction and tangent-projected entry speed is 2–18 m/s. Rising faster than 1 m/s rejects capture. Ground passes and unrelated ledges cannot award Rail Grind.
- Travel follows full 3D tangent geometry in either direction, with slope gravity 22 m/s² and friction 0.6 m/s², capped at 18 m/s. Speed below 1 m/s releases. Open endpoints release without wrapping, and global recapture cooldown is 0.35 seconds.
- Balance starts centred; deterministic drift and elapsed instability are corrected by steering. Absolute lean 1 bails. Current tuning needs actual wired/Bluetooth controller feedback.
- The rider capsule sweeps against layer-1 scenery during capture and short travel segments. Obstructed acquisition rejects; obstruction during travel bails. Rail bars/posts use layer 2/mask 0, so ordinary unacquired passes remain nonblocking.
- Successful attachment awards 200 base points once, uses normal repetition degradation and resolves prior air spin. It emits no ground landing. Release carries tangent momentum; balance/obstruction bail drops pending score and resets safely.

## Landing, manual and revert links

Clean ground landing calls the score model's `begin_landing()`; it **does not bank immediately**. The authoritative pending deadline is 0.35 seconds. A valid manual, ollie or rail transition continues the combo; actual physical airtime/rail/manual also holds it. Repeated landing events and mere trick awards never refresh the deadline. Ground expiry banks once; bail drops the active combo.

Manual (**M / L2**) needs fresh supported input, speed at least 2 m/s and an elapsed 0.35-second exit cooldown. Holding sustains balance; push/brake correct fore/aft lean while steering still changes heading. The visible board raises its nose. Release/insufficient speed ends the link once. Holding through airtime, a failed entry or cooldown cannot automatically score another entry. Ollie continues the manual's combo; support loss preserves physical airtime without a false ground-end.

Revert (**C / R3**) is once per actual landing within its original 0.35-second eligibility window, unavailable during an active manual/rail. It awards 150, costs 15% speed and turns the visible stance 180° over 0.18 seconds. Travel heading stays consistent. Revert alone does not refresh or suspend banking: link to a valid manual/ollie before the original score deadline, or the combo banks.

Pause freezes movement, balance and deadlines. Restart clears transient ride/score state. At run expiry, an existing air/rail/manual/pending-ground combo has at most three seconds to resolve, with fresh entries disabled. A hold cannot extend overtime. Main's pre-movement score tick means a deadline already expired in that tick banks before a later input can start a new combo. See [ADR-006](../architecture/decisions/ADR-006-trick-state-and-input.md).

## Current authored tracks

| Track | Start | End | Length |
|---|---|---|---:|
| Exchange | `(12, .92, 12.75)` | `(12, .92, 5.25)` | 7.5 m |
| Tenement | `(-26, .92, -18)` | `(-26, .92, -26)` | 8 m |
| George Square | `(22, .92, -100)` | `(22, .92, -112)` | 12 m |
| Central elevated platform | `(-98, 2.92, 10.5)` | `(-98, 2.92, 1.5)` | 9 m |
| Central ground route | `(-69, .92, 3.5)` | `(-69, .92, -13.5)` | 17 m |
| Barras | `(114, .92, 24)` | `(114, .92, 12)` | 12 m |

Coordinates describe the current untransformed authored world in metres. Increasing curve distance travels toward negative Z; reverse direction also works. `get_grind_lines()` snapshots the visible authors' local vertices through global transforms, so rebuild after moving/scaling authoring nodes. Current levels use straight rails, while the helper/ride suites also exercise curved and sloped geometry.

The original Exchange capture remains a repeatable entry route:

1. Restart, place the rider at `(12, .04, 18)`, yaw 0, and settle for 45 physics frames.
2. Set forward speed 10 m/s for reproducibility; press push, ollie and grind, releasing ollie after two frames.
3. Wait for actual eligible capture, bounded to 90 frames. Save the ride frame after eight more frames, failing if the ride has ended.

`tools/capture.sh` includes this rendered scenario. It is a deterministic setup with a prescribed starting speed, not a human playtest. Independent regression also accelerates from rest using ordinary push. Capture scripts and STATUS/QE-REPORT identify the latest images; do not infer current screenshot scores or frame counts from an older revision. Linux Mesa software rendering establishes visible state, not Apple Silicon performance.

## Special/gap extensions

Banked combos fill the special meter (points/25, maximum 50 per bank, capacity 100). U/D-pad up requests Clyde Carousel; I/D-pad right requests Tenement Tumble. Career unlocks and full charge are checked before eligible airtime accepts one special per air segment. Free skate skips career unlock gating but still needs charge. Rejected ground/rail/manual/paused/overtime requests spend nothing. Special animation does not alter physical trajectory.

Three world-authored swept routes award named combo points: Exchange Air (300), Mind The Gap (600) and Barras Basket Hop (350). Ordered crossings, 4-second timeout, required airborne evidence and rearm/teleport guards are covered independently. Central gap also feeds its career goal. These mechanics are enabled, not merely catalog definitions.

## Verification and remaining acceptance

Run `./tools/check.sh`. Exact final counts are maintained in [QE-REPORT](QE-REPORT.md) and [STATUS](../STATUS.md).

| Suite | Scope |
|---|---|
| `rail_geometry_tests.gd`, `grind_ride_tests.gd` | Valid/invalid geometry, transformed and sloped/curved tangents, both directions, nearest clear candidate, eligibility boundaries, endpoints, speed/balance limits |
| `grinding_tests.gd`, `grind_regression_tests.gd` | Actual production acquisition/release/ollie, visible authored rail, obstruction, cooldown, pause/reset and bounded overtime |
| `takeoff_tests.gd` | Actual uphill/downhill/flat departure momentum, wall loss and bounded air steering |
| `manual_revert_tests.gd`, `combo_integration_tests.gd` | Fresh versus held manual entry, balance/bail, cooldown, real air/manual linking, revert cost/once/early/late behavior and no deadline extension |
| `combo_resolution_tests.gd` | Authoritative timer, duplicate events, exact-once bank/drop/reset, invalid deltas and score bounds |
| `special_gap_tests.gd`, `career_integration_tests.gd` | Charge/unlock separation, eligible specials, swept gap order/air evidence and progression boundaries |

The rider now has rounded original procedural geometry and articulated push/landing/grab poses. That presentation pass does not certify final character animation or specialized grind poses. Ordinary banks remain supported; near-vertical quarter-pipe riding is still outside the current controller.

Before accepting M02, play forward/reverse Exchange and the district rails with keyboard and a physical DualSense. Record trigger actuation, capture forgiveness, balance correction, release/ollie/manual/revert continuity, camera comfort and repeatability. Target-Mac launch/performance, final visuals and owner feel acceptance remain explicit gates while further authorized implementation continues.
