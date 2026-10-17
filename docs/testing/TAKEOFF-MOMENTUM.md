# M01-008 — takeoff momentum investigation

**17 October 2026.** Actual Godot 4.6.3 physics reproduced the suspected takeoff boost and two related bookkeeping defects. The controller now carries its collision-adjusted horizontal velocity into air, rotates that vector by bounded steering input, and applies gravity to Y. Ground speed uses capped actual travel velocity so descending a slope does not repeatedly lose its vertical component.

## Reproduction and measurement

The diagnostic used the production `CharacterBody3D` and real static collision at 60 physics steps per second. A finite box platform is centred at `(0, 5, 0)`, size `(8, 0.3, 12)`, and pitched by `atan(0.4)` (21.8 degrees). The skater settles for 60 frames, starts with surface speed 12 m/s, and coasts without push. Uphill and flat trials start at `(0, 6, 0)` facing -Z; downhill starts at `(0, 6, 4)` facing +Z so the original excessive damping does not prevent departure. The collided trial adds a wall at `(0, 5, -8)`, size `(8, 8, 0.5)`. The probe samples immediately after each actual `move_and_slide` call.

“Velocity” below means the post-collision `CharacterBody3D.velocity`, not the raw request before collision. “Real velocity” means `get_real_velocity()`, derived from actual travel. The outgoing row is the first frame with `is_on_floor()==false`; the next sample is one physics step later. Values are horizontal magnitudes in metres per second.

| Route | Before: outgoing → next velocity | After: outgoing → next velocity | After: outgoing → next real velocity |
|---|---:|---:|---:|
| Uphill | 10.79354 → 11.62500 | 10.79345 → 10.79345 | 10.79344 → 10.83738 |
| Downhill | 1.95911 → 2.89394 | 7.73204 → 7.73204 | 7.72857 → 7.73206 |
| Flat platform edge | 10.88085 → 11.60000 | 10.88098 → 10.88098 | 10.87895 → 10.88098 |

The uphill requested horizontal boost was **7.7%**. The flat trial also exposed a boost after capsule contact with the platform edge redirected velocity. Collision recovery at the uphill edge contributes about 0.044 m/s to the first real-velocity sample; the following free-air step matches carried velocity to rounding precision. These measurements establish continuity rather than requiring collision recovery to be numerically zero.

The downhill values differ substantially between runs because the investigation also confirmed unintended ground damping. Before the fix, a 12 m/s coast from the centre of the same slope fell to 11.13012 m/s in the first frame, 2.39753 after 21 frames and zero by frame 61. Godot's post-slide requested Y became zero while real motion continued down the incline. Taking `velocity.length()` as full ground speed discarded a slope component every frame. After the fix, the first frame records **11.98750 m/s**, exactly 12 minus the configured 0.75 m/s² rolling drag for 1/60 second. The clamp against previous speed prevents snap/recovery displacement from adding speed.

The wall trial stopped horizontal velocity at zero in both versions. Before the fix the public speed remained 11.6 m/s and every later air tick reapplied it; collision hid that until the wall was removed. Afterward both remaining horizontal velocity and public speed stay zero. Independent QE explicitly removes the contacted wall to verify that lost momentum cannot return.

## Independent durable regression

`tests/takeoff_tests.gd` uses separately authored elevated platforms at +30°, -30° and 0°, ordinary push input and automatic physics processing. It checks actual departure, outgoing/next velocity and real displacement, six frames of bounded air steering without acceleration, and momentum after removing an air-collision wall. It does not duplicate the movement calculation.

Before the production fix, that suite observed **11 passing and 7 failing assertions**: uphill 12.99038 → 15.0 m/s, flat 13.40031 → 15.0 m/s, downhill unable to reach the lip within 180 push frames, and wall removal restoring 10 m/s. Its slope differs intentionally from the diagnostic above.

After the fix the same independent suite reports **21 passed, 0 failed**, exit 0. Both 30° slope departures preserve 12.99038 m/s; the flat edge preserves 13.37894 m/s; removing the wall leaves zero horizontal motion and zero public speed. The bounded-steering checks pass. More assertions run after the fix because downhill now reaches its lip and executes the previously unreachable velocity comparisons.

For an isolated rerun, create this ignored runner and execute it from the repository root:

```sh
mkdir -p .local
cat > .local/takeoff_qe_probe.gd <<'GDSCRIPT'
extends SceneTree
const TakeoffTests = preload("res://tests/takeoff_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    await TakeoffTests.run(self, _check)
    print("TAKEOFF RESULT: %d passed, %d failed" % [passed, failed])
    quit(1 if failed > 0 else 0)
func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("PASS: " + label)
    else:
        failed += 1
        push_error("FAIL: " + label)
GDSCRIPT
./tools/run.sh --headless --script .local/takeoff_qe_probe.gd
```

The temporary diagnostic, baseline controller and raw before/after logs live under ignored `.local/`; the independent regression above and this record are the durable handoff. The root integrator owns the complete `tools/check.sh` run after concurrent trick-system integration. Its final result is recorded in STATUS and the QE report, not inferred from the focused probe.

## Scope and remaining limits

Ground push/brake values, ollie impulse, gravity, steering rate and cosmetic aerial trick rules are unchanged. Intentional ollies still add the documented upward impulse; they do not restore a discarded horizontal component. Airborne `speed` now reports remaining horizontal motion; grounded `speed` reports capped surface travel. The heading and carried velocity rotate together by the same input angle, without rebuilding speed from heading.

This fixes measured momentum discontinuities, not quarter-pipe/vert support or human skating feel. Physical Mac/DualSense validation and M01-007 remain open. Parent integration must preserve these regressions when adding grind release or other sources of takeoff velocity.
