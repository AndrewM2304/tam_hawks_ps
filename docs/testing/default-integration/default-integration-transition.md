# Default transition integration

Merge roles: stage 2 is latest default; stage 3 is feature work.

- `game/player/transition_ride.gd` and UID are byte-identical to stage 2.
  Default finite cylindrical dictionaries retain `try_start`, `step`, `reconcile`,
  `position()`, `normal()`, `travel_velocity()` and `stop()`. Caller owns native
  collision movement/reconciliation. No default control or return gate was changed.
- NEW `game/player/feature_transition_ride.gd` and UID are byte-identical to stage 3.
  It handles actual Node3D quarter/bowl/halfpipe/spine/Sunken open-port features in
  `skate_transitions`. `try_enter(body, velocity)` confirms the exact native face.
  `step(body, delta, push, brake, steer, jump=false, lip_held=false,
  jump_impulse=8.8)` owns native movement and returns active/state/event/velocity/
  normal/forward/surface_pitch/lip/lip_balance. Public feature/air_feature remain
  Node3D. `reset(body=null)`, `refresh_frame(body)`, `lip_frame()` and
  `grind_path_clear(from,to,body)` retain their work contracts.
- Both match latest default's actual BodyCollision capsule (height 1.7, radius .28,
  rest centre Y .85). Distinct script UIDs each occur exactly once in game/.
- Root dispatches `_transition` for dictionaries and `_feature_transition` for
  Node3D features; never call both movements or ordinary MoveAndSlide in one tick.
  Feature motion must invalidate native ordinary floor/platform caches; heading
  changes need refresh_frame; reset/grind handoff restores the capsule. Event
  launch begins air, landed finishes landing, exit is grounded, exit_air forces
  ordinary air, bail begins bail. Existing native floor-only upright recovery and
  once-only real-port departure guard remain intact.
- QE retains both test architectures; only work helper preloads change to the new
  feature path. Default tests remain on transition_ride.gd. World keeps dictionary
  metadata distinct from Node3D group membership.

Validation: Godot 4.6.3 --headless --script PATH --check-only exits 0 for BOTH
helpers. No Skater/world/test/doc/tool edits or git stage/commit by this agent.
Full integration/native gameplay checks are pending Root/QE's merged Skater/world.

SHA256 default helper: 56d0ca80f088ba5500e6e5a0946d8f6c27683c108d0efa4cc4004c50222f5a26

SHA256 feature helper: 5216948d7733fa2ce7588bae8236b09ffedac121b44a6ede4a96bcc52bb8498a
