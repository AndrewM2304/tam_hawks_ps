# Fixed-tick rider and displayed-frame chase

17 October 2026 · A04 implementation and focused verification. This addresses a
specific source of motion judder; it does not establish a frame-rate improvement,
Apple Silicon performance, display comfort or freedom from every source of stutter.

The production skater moves and animates in 60 Hz `_physics_process`, while its
chase camera updates every `_process`. Previously the camera read the newest raw
`global_position` and `global_basis`. Between physics ticks those targets did not
move, even if the display produced more frames and the camera eased its own orbit.
This matches the fixed-tick/display mismatch described by Godot's official guide.
An unrelated long shader compilation or slow rendering frame needs separate timing
evidence; interpolation does not solve those costs.

## Implementation and boundaries

- Project physics interpolation is enabled. Main opts its branch out because
  existing NPC transforms are animated every render frame; the Skater explicitly
  opts itself and its physics-driven descendant poses in.
- The world-space top-level chase camera explicitly opts out. Its per-render
  follow transform uses `get_global_transform_interpolated()` for the displayed
  rider position and heading. The displayed `BodyCollision` up axis supplies the
  curved-surface chest/head/board frame, including a blended transition exit.
- Direct physics queries still test the real scenery, including camera sphere
  sweeps, endpoint volumes and board/chest/head visibility. Physics-frame callers
  use current physical transforms. Interpolated transforms never drive skating,
  collisions, rail attachment, surface contact, scoring or airborne spin.
- `reset_skater()` resets native interpolation after placing the rider, support
  shape, descendant poses and camera. Restart, bail and `recover_to()` use that
  same path. Native displayed-transform sampling is initialized before resetting
  its history. Ordinary swept skating/grind/pipe movement remains interpolated;
  resetting every rail step would reintroduce judder.
- The first chase update after a reset uses the new current transform once.
  Godot 4.6.3 can retain an interpolated-transform cache for the remainder of the
  current callback/frame even after the reset notification. The next displayed
  frame resumes native interpolation. This prevents a reset camera from briefly
  chasing the pre-teleport cached target.

Interpolation displays the interval between physics samples; it adds no physics
ticks or smoothing forces. At normal 60 Hz its temporal window is one physics
tick (about 16.7 ms). The deliberate 10 Hz test exaggerates that interval to make
missing interpolation easy to detect; production physics remains 60 Hz.

## Actual focused evidence

`tests/physics_interpolation_tests.gd` reports **6 passed / 0 failed** both with a
fixed 240 Hz process cadence and with the ordinary clock capped at 120 process
frames per second. These are **headless displayed-transform/process samples**,
not rasterized images, monitor captures or measured GPU throughput.

| Headless trial | Samples over ten 10 Hz physics intervals | Movement changes within a physics interval | Largest raw physics-origin jump | Largest displayed-transform step | Chase anchor error |
|---|---:|---:|---:|---:|---:|
| `--fixed-fps 240` | 240 | 230 | 1.50000 m | 0.06250 m | 0.0000000 m |
| Ordinary clock, 120 cap | 120 | 110 | 1.50000 m | 0.13059 m | 0.0000000 m |

The fixture uses actual mapped push input on a real supported CharacterBody, not
per-frame position assignments. It checks that intermediate displayed motion
exists, that camera anchors match that displayed contact frame, and that
restart/recovery clear rider/descendant/support/camera history by the next
displayed frame. A second pair of real-input 42-tick push/crouch/pop/stick-spin
trials compares interpolation on and off: every physical position, velocity,
airborne flag and scored spin value matches within 0.00001.

Combined with the existing camera-turn suite, the focused result is **30 passed /
0 failed**. Nine natural-input turn trials and the supported 20° downhill rollback
report **zero unsafe camera samples**. These checks preserve physical frustum and
obstruction assertions; they do not certify all map routes or pipe camera comfort.
The required full `tools/check.sh` and source-bound graphical checks belong to the
integrated checkpoint recorded in STATUS, rather than being inferred here.

Retained focused logs:

- [240 Hz process trial](logs/physics-interpolation-240.log), SHA-256
  `75c59d54f0a50b36439fe079f5cbe9b5043b25075d966b2619bf88aacbc8b433`.
- [Ordinary-clock trial](logs/physics-interpolation-realtime.log), SHA-256
  `17fd16f84bd0c2d28d07ae80a8fc3f34b89357fde9e9a6b6aee468fcdcdb3a6d`.
- [Combined camera trial](logs/physics-interpolation-camera.log), SHA-256
  `a733a1e7406b454e0f919190860c2a69095e72ae7657371beeeab6dad706a957`.

The focused ignored runner calls
`await load("res://tests/physics_interpolation_tests.gd").run(self, check)` and
exits nonzero on a failed assertion. The combined runner subsequently calls
`camera_turn_review_tests.gd` with the same callback. Commands were
`./tools/run.sh --headless --fixed-fps 240 --script .local/interpolation-review-check.gd`,
the same command without `--fixed-fps 240`, and the fixed-rate command with
`.local/interpolation-camera-check.gd`. The aggregate runner provides the durable
entry point. Each fixture restores the prior physics rate, global interpolation
state and frame cap, and writes no career profile.

## Inspected official sources

Read the actual official 4.6 documentation repository at pinned revision
`b10b7ed373c2d15555186914b82e167169b5b87b`, with free public raw requests:

- [Introduction](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/physics/interpolation/physics_interpolation_introduction.rst):
  fixed physics/display cadence and interpolation fraction. SHA-256
  `e46398c070dc660067515a9a544aaa1ce18c79b36de3af65a2151a23931a93a9`.
- [Using interpolation](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/physics/interpolation/using_physics_interpolation.rst):
  physics-owned transforms and resetting after teleport placement. SHA-256
  `a0e1a9578e8831442a69f2b84741d6c99570513b10c31c8366a0eec13fe729cc`.
- [Advanced interpolation](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/physics/interpolation/advanced_physics_interpolation.rst):
  world-space per-render camera, explicit camera opt-out, displayed target rather
  than raw physics position. SHA-256
  `39672cdf561a8cea5ea1cf2e536d1cd997535121f023f5a8b2c6019bfcce03a0`.

Also read Godot's `4.6.3-stable` tag, resolved to
`35e80b3a8822a9df9be390814b62f44c0a9c69e8`: `Node.xml` interpolation modes/reset,
`SceneTree.xml` global enablement, `Node3D.xml` displayed transforms, and
[`node_3d.cpp`](https://github.com/godotengine/godot/blob/35e80b3a8822a9df9be390814b62f44c0a9c69e8/scene/3d/node_3d.cpp)
for the 4.6.3 cached-frame/reset behavior (`NOTIFICATION_RESET_PHYSICS_INTERPOLATION`
and `get_global_transform_interpolated`). Source SHA-256
`df1809e637b2a6d01b7df96fa878bdd61ce2a6cfbc5a31c0c0ac0eb8802a1497`.
These are API/behavior references; no documentation or engine implementation was
copied into game code. Focused execution used the installed free Godot
`4.6.3.stable.official.7d41c59c4` binary reported in the logs.

Next acceptance: inspect normal 60 Hz physics at the owner's real display rate,
including fast turns, quarter/half-pipe crest/return, grind capture, restart and
hazard recovery. Record monitor refresh, frame-time distribution and whether
remaining stutter corresponds to long frames; do not infer Mac acceptance from
the Linux headless cadence demonstration.
