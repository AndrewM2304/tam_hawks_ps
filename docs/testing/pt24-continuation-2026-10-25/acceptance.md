# PT24 skating, pose, recorder and camera-query acceptance

25 October 2026. Independent QE notes for the current continuation on main.
The existing 4,657/0 receipt belongs to the preceding repair source; it is not
a result for this continuation. No engine run has been performed by this QE
agent while source/physics ownership remains with the coordinated repair work.

## Camera optimization review

`chase_camera.gd` calls `_usable` and `_clear_volume` repeatedly while evaluating
the same endpoint, smoothing a view and selecting a supported fallback. Its
native sphere/ray checks include actual foot and wheel landmarks. Removing those
checks or coarsening their endpoints could change what the camera hides.

Memoizing their exact Vector3 endpoint is semantically safe only within one
synchronous `update`, after board/anchor, `_body_up`, `_minimum_arm`, foot/wheel
targets, space state and exclusions are final. There is no await or physics
step in that region. The shared query's transform/motion changes are not semantic
outputs: each subsequent `_sweep` writes both before its native cast. Direct
helper calls must remain uncached, and reset, early return and update completion
must leave no cached answers. No approximate key, cross-frame reuse, sweep cache,
landmark removal or changed contact tolerance is admitted by this optimization.

The production diagnostic contract is:

- `debug_query_cache_enabled`: defaults true; false is the uncached control.
- `last_update_queries`: shape/ray/cast counts plus clear/usable cache hits.
- Counters measure native camera overlap/visibility/cast work. Candidate ground
  rays are unchanged and outside these diagnostic counters; do not call these
  complete engine-query totals or frame-time measurements.

[`tests/pt24_acceptance_tests.gd`](../../../tests/pt24_acceptance_tests.gd)
independently compares cached and uncached cameras in a private native World3D.
Its real rider is settled once and then frozen. Open ground, rear obstruction,
corner and low roof are exercised with ordinary/reduced motion, sensitivity
limits, zero delta and a delayed update. Each pair shares identical frozen
geometry, rider physics, camera initial conditions and update arguments.

Required evidence is exact complete transform/FOV and semantic-state parity,
unchanged rider/capsule/velocity/state, no extra native shape/ray calls, identical
sweep counts and a strict measured query reduction in a blocked-view workload.
Moving a native solid onto the exact old endpoint must be observed by direct
helpers and the next update; removing it must likewise preserve uncached parity.
Reset/invalid-rider paths and cleared scope are checked. This is camera-query
equivalence evidence, not an actual-input skating route or a render/stutter pass.

## Existing focused source witnesses to reuse

Do not copy the existing behavior assertions into another broad test module.
The following current modules already exercise the actual production contracts:

| Ticket | Appropriate existing focused evidence | What remains distinct |
| --- | --- | --- |
| PT24-23 bowl escape/camera | `owner_playtest_repairs_tests.gd` `_bowl_air` compares held approach versus fresh in-air Push; `_natural_bowl_air` checks opposite-wall natural launches, coping departure and a single downward apex handoff. `camera_turn_review_tests.gd` `_apex_launch_identity` and `_support_interpolation` cover launch identity and restored body axis. | Repeated ordinary-camera/native-input source proof does not certify target-Mac comfort or every user trajectory. Preserve the declared curved fixture setup and avoid later transform correction. |
| PT24-24 print-yard wallride/wallie | `owner_playtest_repairs_tests.gd` `_print_yard_wall` checks the actual backed wall and head-on rejection. `overnight_integration_tests.gd` `_world_wall_and_transition` and `authentic_fidelity_integration_tests.gd` `_wall_line` check real architectural Wallride→Wallie, wheel/head contact and once-only awards. | The broader boundary exclusions must remain; do not turn all safety walls/fences into eligible walls. Controller line feel is separate. |
| PT24-28 startup/contracted rider | `authentic_pose_tests.gd` `_startup_pose`, `_recovery`, `_interrupted_recovery`, `_recorded_drag_reach` and `_ordinary_foot_support`; `limb_pose_tests.gd` samples actual push/brake/manual/flip/grab/ramp actions; `bail_recovery_tests.gd` checks actual fall/slide/get-up/ready. | Startup neutral/reset can be proven independently; the older contracted-body photograph's cause remains unproven without a matching reproduction. Passing limb lengths alone cannot establish a believable full silhouette. |
| PT24-29 recorder | `playtest_recorder_tests.gd` already checks active versus configured flags, input edges, bail semantics, physics/presentation frame IDs, note typing, capture pause/restore, safe HUD scales, retry after write failure and readable ZIP. | Source frame/timestamp assertions need a normal displayed capture witness; synthetic input is not physical DualSense editing evidence. |

Root can invoke the existing methods in a bounded observer after the relevant
source owners release physics/rendering. Preserve spawn/profile state and the
full suite's normal registration; do not run two Main/capture workloads together.

## Admission and outstanding results

Root's intermediate frozen-source required check passed **4,843/0**, exit zero,
clean log and 572 unchanged inputs; see
[the pre-cap receipt](validation/intermediate-precap/receipt.json). This includes
the recorder/startup/bowl/wallride regressions and the camera parity fixture.
It predates the independently discovered civic-preview gutter closure; the
[root continuation record](README.md) owns the final source admission rather
than treating this intermediate pass as sufficient.

The parity fixture compares 96 exact update pairs: shape overlaps 564→168,
visibility rays 44,100→29,400 and all 336 casts retained, with exact camera
transform/FOV/state and unchanged rider state. Actual market and cable sequences
earn one bank each; migrated print-yard Wallride→Wallie retains real contact and
the authentic five-entry line banks 6,000 once with zero bails. Ramp framing is
checked after camera node processing; a no-framing control still fails with that
correct timing. Raw controls and rejected observations remain under validation.
The [normal startup PNG](captures/default-normal-startup.png) is a completed
render-loop witness; paused placement captures do not certify skating motion.

No older contraction cause, blanket PT24 ticket closure, frame-time improvement
or stutter resolution is claimed by these results.

The native-query reduction is a bounded CPU-work reduction. Target performance
still requires matched frozen-source existing-map moving workloads, exact
settings and p50/p95/p99/long-frame/resource evidence on the actual Mac. Linux
llvmpipe or a lower counter cannot close that gate. Human Mac/DualSense, listening,
fun, final art and export admission remain separate.
