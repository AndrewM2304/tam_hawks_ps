# Bounded physical approach to a grind — proposal only

Source and evidence: held Main `bd32911d…`, controller `1ef6cdb7…`; original
open-link15/0 and capture-timing12/0 packets. This document changes no source,
input timing, scoring contract, radius, deadline or clearance tolerance. Root and
ME must review ownership and scope before implementation.

The diagnostic separates three effects. The original entry adds0.798m of forward
endpoint correction; interior catches remove that longitudinal correction but
still pull the actor0.300m laterally and0.497–0.568m vertically in one tick. The
head changes another0.277–0.397m relative to the actor. A genuine entry Ollie is
present in every positive; grounded no-Ollie correctly refuses. A pose-only blend
would leave the native teleport and could cross the finite support. Narrowing the
request radius alone would make a forgiving skating input brittle.

Keep the existing generous request and separate it from actual capture. Introduce
a short **physical approach phase**, while the rider remains ordinary air or
already-supported ordinary movement. Selecting a potential line does not set
`grinding`, consume the final capture, emit a trick/capture event, grant native
gap authority or create a combo link. Existing real airborne/manual/wall states
continue to control Main's combo lifetime; no score/landing deadline is extended.
An already-real native bearing may transition directly with negligible correction.

1. **Request/reserve.** Reuse existing held Grind/fresh buffer semantics and the
   current finite candidate index/envelope, native owner and configured line
   identity. Produce a proposal without mutating active GrindRide. Snapshot
   canonical finite geometry, RID/integer shape and ownership epoch. A held
   request can wait through an ascending Ollie; a released/expired tap cannot
   gain a new hidden buffer. Do not snap toward a finite endpoint ahead of the
   rider. A prospective contact follows real forward travel along the finite
   face and refuses its outgoing end.
2. **Approach through ordinary physics.** Continue the actual gravity/launch
   impulse and `move_and_slide`; never move the actor to a guide point. On an
   ascending Ollie, wait for its real arc rather than imposing a downward catch
   impulse. Optional modest lateral/yaw assistance can rotate existing air
   momentum toward the reserved bearing, with bounded acceleration, no speed or
   vertical-energy boost, and cancellation on deliberate opposing input. It must
   pass the existing native capsule/full-model path checks for each real step.
   If safe arrival is no longer possible, release the reservation and preserve
   ordinary air/collision/recovery instead of forcing a catch.
3. **Prepare the visible contact posture in air.** Anticipate only the intended
   style/facing/feet pose while still unweighted, from the actual current drawn
   pose. Keep board/body transforms on the current physical flight and validate
   their whole finite native paths. Bound angular and joint/head-relative rates;
   retain planted/bearing constraints only after real contact. Do not report
   `native_grind_contact` or skip a solid during this preparation. The final
   contact frame should already agree with the displayed frame, so it does not
   erase a large smoothing offset at commitment.
4. **Commit on real bearing.** After the ordinary native move, require the actual
   board's selected truck/support anchors to meet the exact intended current
   native finite primitive/shape, with its current authenticated frame and the
   existing contact tolerances. Recheck full-model clearance against all solids,
   including the intended support. Then start GrindRide at the current finite
   travel coordinate, consume the request and emit one capture/one trick. No
   speculative approach earns score or a gap. Capture must not add a substantial
   translation or instantaneous posture change to that completed physics step.

Suggested implementation ownership: ME owns the controller/physics state and a
pure `GrindApproach` planner; GrindRide gains nonmutating proposal selection while
retaining legacy public `start` geometry tests; existing GrindStyle owns the
contact pose and current GrindClearance owns every native/full-model admission.
Rider specialist owns the anticipated pose channel after ME defines the physical
contract. Topology/QA independently replay the unchanged ordinary input drivers.
Do not duplicate native owner registries or infer bearing from `grinding=true`,
generic metadata, a guide point or a broad overlap box.

Initial numerical *review candidates*, not accepted constants: plan at most one
nearby reserved candidate per tick over a0.75s horizon; reuse the current index
and cached model. The early held request needs about0.6s of ordinary Ollie flight
in this observed case, so an arbitrary0.1s catch timer would regress it. The
horizon cannot extend the actual input buffer, combo deadline or native proof
freshness. Lateral assistance should use existing air steering/energy bounds,
not a per-frame position lerp. A final numerical placement tolerance should be
millimetres (provisionally≤5mm), alongside the existing tighter bearing tolerances;
it must not authorize a5mm tyre or shoe penetration. Head/joint continuity must
be assessed against the actual prior/current physical and visual states, not an
absolute world-distance test that would reject ordinary fast forward travel.
Native query cost must be instrumented separately: at most one existing bounded
capture/path admission plus two intended-contact probes when near real bearing;
no render allocation, broad scene scan or per-candidate full-model loop. These
are helper-call ceilings, not total native-query or CPU counts: instrument each
ray/cast/overlap class, model component/sample count, hit-limit saturation and the
worst supported candidate before setting a real per-tick native budget. They
require measured verification and are not an M5 performance claim.

Invalidate on release/expired tap, bail, reset, pause, level/epoch change, freed,
moved or disabled owner, finite-end departure, identity/shape/frame mismatch,
unsupported style, opposing input or a blocked native/model path. Resuming a
reservation cannot reuse a stale proof. Cancellation must neither bank/drop an
otherwise live combo nor stop normal gravity/movement. Retain current protected
support/contact tolerances and never exclude a complete owner RID.

Acceptance needs the unchanged baseline and all three original offsets, rising
and descending interior variants, held and tap timing, both travel directions,
near/over finite ends, high/low speed and different real launch heights; actual
grounded no-Ollie refusal; blocked wall/post/cap and unrelated owner/shape controls;
release, stale identity, moved/disabled owner, pause/bail/reset/level cancellation;
and the existing old34/strict gap controls plus natural all-four cable IDs. Record
native actor motion, expected ordinary velocity integration, complete board/rig
contacts and relative marker rates through request→approach→bearing→departure.
Score ledgers independently derive the final result and assert no award before
bearing, exactly one eventual capture, no duplicate holds/gap awards or artificial
extra bank. Scores may legitimately change with actual hold time and must be
derived, not forced to the old2000.

The new native-bearing approach should first cover verified canonical primitives.
Generic legacy guides without authenticated bearing are an explicit migration
decision for Root/ME: preserve their existing public pure APIs and test scope,
inventory affected natural routes, then add real native authoring contracts or a
separately reviewed compatibility boundary. Do not silently claim every legacy
guide has acquired physical proof or discard ordinary combo connectivity to make
one new fixture pass. A final interpolated rendered review and actual MacBook
Air M5 check remain required after native/score gates pass.
