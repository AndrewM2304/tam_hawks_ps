---
name: deformed-contact
description: Bound actual native skinned rider surfaces for obstacle contact without procedural shape assumptions, changed physical authority or unmeasured rendering cost.
---

Read AGENTS.md, STATUS, AAA_BENCHMARK, FIDELITY_TICKETS, runtime interfaces and
FITTED-RIG-VALIDATION. Apply rigging-validation and skating-motion as appropriate.
Coordinate helper ownership with the motion engineer, source mesh/weights with
the rider artist and acceptance with independent QE. The director owns Git and
stage release. During a source freeze, use only ignored private prototypes and
durable plans; do not edit runtime, existing tests or imported resources.

The exact use case is `game/player/skater_obstacle_arm_fit.gd`: an authentic fitted
shirt has hundreds of distinct skin-weight combinations, so grouping by exact
weights and rejecting more than 32 groups cannot support it. Do not retune old
procedural cylinder rows or weaken contact tolerances to fit a replacement mesh.

1. Cache real indexed native geometry and resolve every nonzero influence through
   its actual Skin binding and Skeleton bone. Include every endpoint of each arm
   incident triangle, not synthetic radius witnesses. The convex hull of the
   deformed triangle endpoints encloses the rendered triangle.
2. Bound the actual per-vertex linear blend using current native inverse binds and
   current/candidate bone poses. Preserve all nonarm transforms and fixed shoulder
   authority. Resource identity/bind changes must invalidate cached contributions;
   deliberate bind corruption must remain observable.
   Follow the official shader order: weighted **local** skin matrices first,
   discard homogeneous W, then apply the actual MeshInstance model once. Native
   UNORM16 weights may sum below one; keep their decoded values. An inherited CPU
   world-per-influence oracle and the native bake API are insufficient authority.
   Include a far-origin, nonunit-weight and unequal mesh/skeleton-frame witness.
3. Declare CPU work, cache memory and allocation budgets before implementation.
   Reuse native Skin/ArrayMesh resources, packed caches and one palette. No per-frame
   mesh construction, GPU readback or hidden geometry baking. Cache rebuilds occur
   only at preparation or authenticated mesh/Skin changes and must be explicit.
4. Preserve the current 12 native-query ceiling, 20-cm wrist shift, 8-mm skin,
   220-mm whole-body continuity checks, finite freshly authenticated native wall
   body/RID/shape, shoulder, nonarm/root parity and mode/reset exclusions. Do not
   enlarge a movement/tolerance limit or accept a remembered infinite plane.
5. Retain existing actual native arm intrusions, wrong-body/foreign-plane and bind
   corruption negatives. Verify every actual indexed endpoint against its envelope
   under ordinary, pushed, crouched, manual and bounded candidate arm transforms.
   Prove containment numerically and inspect original native rendered frames.
6. Run focused helper/affected contact checks and the director's current-source
   integration gate after release. Compare source-frozen actual Main cases; static
   algebra cannot establish movement or MacBook Air M5 frame time. Measure M5 cost
   only on that device; clearly label local CPU diagnostics and unmeasured gates.

Initial private fitted candidate admission budget: at most 16,000 transformed
nonzero contributions for both arms across the current worst-case eight envelope
evaluations per physics tick; at most 512 KiB extra retained packed cache; no new
Mesh/Skin resources or explicit PackedArray construction per routine envelope.
Provisional target-M5 incremental envelope CPU p95 <=1 ms, p99 <=2 ms remains
unmeasured. A failed budget requires optimization/evidence, not silently disabling
normal trial content or inventing a platform pass.

Default ownership when explicitly assigned: the contact helper and its focused
test adapter. The rider artist owns source geometry/weights and the motion engineer
owns shared control/IK integration. Another agent independently verifies the result.
