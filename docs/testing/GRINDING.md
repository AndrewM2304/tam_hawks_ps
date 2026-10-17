# M02-002 — first playable rail slice

Recorded 17 October 2026. The two orange rails in the prototype now support explicit acquisition, signed travel, balance, jump/release/end exits and air→rail→air→landing combos. M02-002 is in QE review until the human controller line trial. Manuals, reverts, hold-duration points, named gaps and complete M02 acceptance remain unfinished.

## Implementation and controls

- Hold **L** on keyboard, or the standard gamepad **R2** trigger candidate, while descending onto a rail. Triangle/R still restarts. Correct balance with **A/D** or the left stick; the meter shows lean and direction warnings. Ollie jumps off; releasing grind drops off.
- Capture selects the nearest eligible clear rail within 0.65 m, vertical reach 0.45 m (at most 0.10 m below the track), approach angle at most 55° and projected speed 2–18 m/s. Rising faster than 1 m/s rejects capture. A ground pass or unrelated ledge cannot generate a rail trick.
- The rail helper follows full 3D tangent geometry in either direction. Travel uses slope gravity 22 m/s² and linear friction 0.6 m/s², capped at 18 m/s. Below 1 m/s it releases. Open endpoints release without wrapping. Reacquisition has a global 0.35-second cooldown after release.
- Balance starts centred with deterministic drift and increasing instability; steering counteracts it. Reaching absolute lean 1 bails. This tuning needs the owner's physical controller feedback.
- The actual rider capsule sweeps against ordinary scenery during capture and every short travel segment. Blocked acquisition rejects; an obstacle during travel bails. Rails/posts use collision layer 2, mask 0; the rider checks layer 1 scenery. This deliberately keeps rail props nonblocking during ordinary passes in this prototype.
- One Rail Grind entry contributes 200 base points using ordinary repeat degradation. Holding does not award per-frame points. Successful capture resolves prior air spin without banking; only actual clean ground landing banks. Balance/obstruction bail drops only pending score and returns to spawn. No special grind-type animations or realistic rider model are claimed.
- Pause freezes travel/balance. Restart clears rail state, score and cooldown. At run expiry an existing air/rail combo gets at most three seconds to resolve, with fresh trick/spin/capture inputs disabled. Holding a rail cannot extend the deadline.

## Authored tracks and reproducible approach

| Track | Start | End | Length |
|---|---|---|---:|
| Exchange, right of the initial route | `(12, .92, 12.75)` | `(12, .92, 5.25)` | 7.5 m |
| Tenement, western edge | `(-26, .92, -18)` | `(-26, .92, -26)` | 8 m |

Coordinates are world metres. `get_grind_lines()` builds geometry from the visible rail nodes' local metadata and global transforms, so transformed/scaled authored levels can regenerate matching tracks. Increasing distance travels toward negative Z; both directions work. Curve Y equals the physical bar top.

`./tools/capture.sh` now creates four actual rendered images, including `.local/rail-grind.png`. Its reproducible rail route uses the real production scene and action input:

1. Restart, place the rider on the clear approach at `(12, .04, 18)`, yaw 0, and settle for 45 physics frames.
2. Initialise forward speed to 10 m/s for repeatability, then press push, ollie and grind. Release ollie after two frames; keep grind held.
3. Wait for actual descending rail acquisition, bounded to 90 frames. Capture after eight more frames of actual riding; fail capture if the state ends first.

This is a rendered scenario with a fixed approach speed, not a claim of a human playtest. The independent regression additionally accelerates from rest with ordinary push before ollie and captures the same visible rail. The actual screenshots use Godot 4.6.3 Compatibility / Mesa llvmpipe software OpenGL, 1280×800. They establish visible state, not Apple Silicon performance or final graphics quality. Camera uses the production chase behavior; the saved script defines repeatable state/timing.

## Verification and acceptance still needed

Run `./tools/check.sh` for the integrated assertions. Final counts and outcomes are recorded in [QE-REPORT.md](QE-REPORT.md) and [STATUS.md](../STATUS.md).

- `tests/grind_ride_tests.gd`: nearest eligible/clear candidate, angle/height/speed boundaries, invalid inputs, reverse/full-3D slope and transformed curved travel, endpoint momentum, slow release, speed cap, controlled balance and bail.
- `tests/grinding_tests.gd`: actual production rail/input/state/score integration; catch, forward/reverse, release, ollie, endpoint, cooldown, pause, repeat-score prevention, no-rail/perpendicular rejection, obstructed capture, balance bail, restart and bounded overtime.
- `tests/grind_regression_tests.gd`: independent ground-approach and obstruction/overtime regression cases.
- Existing rail geometry tests retain 42 checks. Momentum tests retain 21 actual-physics checks. The full suite also preserves previous skating/scoring/session coverage and verifies the new input binding.

The reviewed [rail screenshot](screenshots/rail-grind.png) shows Ollie + Rail Grind, 300 ×2, a 600-point pending combo and the balance gauge. Other captures have refreshed controls. The visible rider, facades and UI remain prototype assets; M06-007 still requires the final graphics/UI cleanup.

Before closing M02-002, play the Exchange line and reverse direction with keyboard and real wired/Bluetooth DualSense. Record capture forgiveness, R2 actuation, balance correction, release/ollie responsiveness, camera comfort and whether the line is repeatable. Real Mac performance, ramp-to-rail approaches, full-world placement, sophisticated bail animation and final art remain separate gates. Do not certify M01/M02 from synthetic tests.
