---
name: skating-motion
description: Diagnose and refine Tam Hawks skating contact, movement, visual transitions and chase-camera continuity using Godot physics evidence.
---

# Skating motion specialist

Use for grounded riding, takeoff/landing, board contact, trick transitions, frame continuity and chase-camera motion. Own `game/player/skater.gd`, `skate_response.gd` and `chase_camera.gd`; agree changes with the rider specialist before changing the pose snapshot.

1. Read `AGENTS.md`, current STATUS/BACKLOG, runtime interfaces, ART_DIRECTION, SKATING_REUSE, `docs/product/AAA_BENCHMARK.md`, `docs/planning/FIDELITY_TICKETS.md` and current PT24/C03 evidence. Work on current main; the October alpha is historical. Preserve native support/capsule orientation authority (including finite wall/transition orientation), signed slope/coast, authenticated rail transfer, actual steering landing/stance rules, takeoff momentum and once-only scoring.
2. Inspect existing `tests/physics_interpolation_tests.gd`, `tests/authentic_fidelity_integration_tests.gd`, `tests/curved_visual_contact_tests.gd`, `tests/grind_surface_contact_tests.gd`, `tests/platform_contact_tests.gd` and the full-repertoire/native wall fixtures before designing replacement measurements. Reproduce an observable defect before editing. Use actual `CharacterBody3D` motion with mapped `Input` actions. Fixture placement is allowed once; per-frame heading/velocity corrections cannot prove ordinary play.
3. Preserve the existing detailed native GLB wheel/rim/board/shoe/palm checks, real finite surface proofs and 78-trick catalogue. Measure additional defects using actual rendered vertices and native support. Nominal primitive footprints and a passing chest ray cannot replace those existing contact/visibility gates. A capsule can stand beyond a thin prop's centre ray; compare fresh native slide-contact RID/shape/plane with the ray before accepting a lower ground plane. Godot `get_collider_shape_index()` supplies the integer ray-hit shape identity; `get_collider_shape()` supplies an object. Revalidate finite tyre/model clearance and reset invalidation after such changes.
4. Prefer Godot floor normals, collision sweeps, native interpolation and bounded analytic pose response. Camera response must not alter travel heading or physical steering. Reset interpolation after teleports, resets and recoveries.
5. Keep ground/air/grind/manual transitions explicit. Verify single landing/link events, no energy gain at lips, no resurrected wall velocity and no ground-clipping board during carve. A named grind's exact supported rigid board frame must seed flight; sample the release pose before the next physical body movement, not just the subsequent airborne frames. For a grounded grade/wall correction, preserve the real floor tangent and revalidate fresh finite wall ownership, all four tyre supports and complete connected board/shoe clearance. Never clear a capsule by moving only its board or donating an old infinite plane. Pass optional visual state fields without changing eligibility or delaying inputs.
6. Add focused regressions for reproduced defects; run the ordinary suite after integration. Extend `tools/full_fidelity_capture.sh` and its native observer/render/pixel synchronization proofs for motion evidence; do not replace its 78-trick/contact coverage with a weaker reel. Inspect landings, push return, flips, banks and camera obstructions. Record exact command, engine/render mode, counts, source identity and limitations in `docs/testing/MOTION-FIDELITY.md`.
7. Send independent QA the defect fixture and acceptance target. Fix verified regressions before marking a ticket accepted. Linux software rendering does not certify Apple Silicon performance, DualSense ergonomics, fun or AAA animation quality.

For finite airborne wall contacts, preserve the separate loaded-floor, unloaded
capsule and actual rendered-model contracts. New presentation authority requires
both an actual native capsule wall contact and an actual connected model hit on
the same fresh finite RID/shape face. An earned owner hint may survive within one
air epoch while the model clears a crown, but it supplies no plane or translation.
Reacquisition needs a new real component hit and finite face proof. Clear active
and hint state on landing/restart/ineligible mode; test foreign native owners and
same-body floor/wall distinctions. Copy Dictionary hints independently: clearing
an aliased active Dictionary must not silently erase the hint.

Native clearance alone cannot certify smooth movement. Retain per-physics
presentation-offset, rider-root and board deltas around contact transitions and
review normal-speed side/chase clips with native pixel/camera/Canvas proofs. A
large one-tick correction can remain visibly wrong despite a clear endpoint.
Diagnose actual indexed mesh triangles versus convex-envelope conservatism before
changing a pose. Anticipation must prove a finite native swept contact; do not
attract a rider toward an unrelated nearby wall or relax a failed margin.
Treat observer phases as part of the contract: `SceneTree.process_frame` is
emitted before nodes run `_process`, so awaiting it alone cannot establish that
the chase camera has processed the newest physical pose. A late process-priority
observer must authenticate the same physics/process index, unchanged rider/model
pose and the player's current `last_presentation_process_frame`; actual rendered
visibility still needs the existing native draw/readback/pixel proof. Preserve
pre-camera failures as such rather than silently renaming them rendered defects.
Declare the finite prediction horizon and native-query hard cap before testing.
Record actual invocation-frame stamps and separate controller costs from observer
queries; counts cannot establish target-Mac CPU time. Duplicate receipt dictionaries
before synchronous fault probes that clear live state, restore all borrowed query
parameters/counters, and keep invalid attribution epochs rejected rather than
recalculating them under a later source version.

Coordinate manual request/buffer/physical-balance/HUD edits with the specialist
using `../combo-usability/SKILL.md`. When asymmetric authored footwear is adopted,
cache actual sole vertices/bounds per leg rather than reusing one mirrored side;
preserve the public SOLE/TOE/contact API and rerun the detailed native matrix.
Do not assume the sole's horizontal outline encloses an authored upper. Measure
actual indexed faces: OBJ vertex tables can retain unused vertices. Keep sole
support separate from complete-shoe3D wall extrema, cache compact native convex
support once during loading, and declare point/resource budgets. Revalidate mesh
transforms, side assignment, invalidation and final whole-shoe native guards;
never resize an authentic shoe to preserve an obsolete envelope assumption.
`Mesh.get_faces()` and native debug hulls can weld/simplify imported source; read
actual rendered position/index buffers for an exact support cache. A debug-hull
vertex subset does not prove enclosure. For a compact source-indexed replacement,
verify closed oriented manifold, exact source provenance and all-source plane
signs independently using exact binary-rational arithmetic on the native export.
Keep numerical ambiguity separate from contact tolerances and declare both cached
support and source-invalidation memory, not only the compact XYZ payload.

Completion benchmark: satisfy current AAA_BENCHMARK V1/V3 and all existing detailed native finite-contact tolerances without relaxing them. New planted push-slip checks target under 5 mm per 60 Hz tick on real stationary support in both travel directions against the actual native sole-support plane, a visibly lifted return, a supporting sole within 5 mm of actual griptape triangles, and no connected head step above 220 mm relative to body travel. Preserve physical input/trajectory/scoring checks and native interpolation. Full action/camera coverage, performance and owner acceptance remain separate gates; a focused push check cannot close them.
