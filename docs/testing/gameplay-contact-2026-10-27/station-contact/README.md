# Station return: loaded tyres at the grade-to-flat join

The exact Gallery→Station prefix reproduces a **real tyre/terrain intersection**
after the capsule reaches flat ground while the loaded Manual axle still trails
on the graded street. The visibility failure is not an invented hull extremity
or a stale camera update. The scoped native presentation repair now passes the
exact prefix, standalone Station and all120 existing Manual guards.

| Native record | Result | Stable inputs | Time |
| --- | --- | ---: | ---: |
| [Station alone](first-native/receipt.json) | 2/0; narrower fixture, no first failure | 678 | 13.986s |
| [Original Gallery→Station prefix](prefix-native-rejected/receipt.json) | 3/1; original receipt rejects hidden rider | 678 | 16.194s |

The rejected prefix binds manifest
`0d6cc938fe7db420dc509fb4faec225ecddb4f307f31010224a539c5988c7fc1`.
The driver adapter changes only the Density preload. Its wrapper returns the
original strict visibility result, observing only the first Station failure.
The prefix runner preserves the existing focus runner's setup, controls and
ordinary observer; Gallery executes immediately before Station on the same
Main/Skater. Personal persistence is disabled before tree entry. No extra frames,
mid-route placement, camera assignment or altered assertion are introduced.

## Exact first-failure witness

At physics frame1637/process frame1636, the camera's recorded process frame is
also1636. This is the normal post-camera-update observation, not an earlier
`process_frame` callback.

- Physical root: `(-34.86673,0.010547,22.16784)`.
- First strict target: raw native hull vertex38 of
  `SkaterVisual/Board/DetailedSkateboard/TamSkateboard`, at
  `(-35.09699,0.010996,22.05503)`.
- Target board-local position: `(0.128981,-0.115590,-0.264)`.
- Closest actual rendered vertex is **45.07µm** away. That actual vertex's ray
  also hits the same street, so substituting it does not remove the defect.
- Camera's cached native board landmark differs from that actual vertex by
  about4.12µm. The complete current camera `usable` query also returns false.

The hit is the actual `CentralSouthStreet` ConvexPolygonShape. Its top plane
normal is `(0.132183,0.991225,0)`. Direct shape-local convex-plane calculation
places the raw target **1.624107mm inside** its native hull. Both short endpoint
support rays confirm the same graded face; the ordinary view ray is blocked by
that face.

Independent native zero-margin overlap queries find **two actual tyre hulls**
overlapping the same street RID: model tyre indices0 and1. Connected native model
components27 and28, each with160 vertices, independently overlap it. Tyres2 and3
remain clear above `ExchangeLowerCourt`. The capsule-centre floor ray already
finds that flat court atY0.

The current visible support frame is flat, with its origin atY0.008, while the
previous displayed frame still retains grade. The loaded axle therefore needs
finite native support through the join even after the capsule-centre support
changes. Restoring an already intersecting original pose is not a valid clearance
fallback. Any repair must preserve the Manual pivot and use the actual tyre/model
pose with the existing bounded native fit; neither a wider camera contact band
nor removal of the Density assertion follows from this evidence.

The standalone2/0 result is retained honestly and does not supersede the rejected
same-actor prefix. These headless observations establish no rendering-time,
Mac/controller or human-feel acceptance.


## Implemented repair and final focused validation

The Manual lowering check now queries the cached actual connected skateboard
pieces at their **exact displayed affine transform**. A long run's inherited
physical basis has tiny scale drift: the failing frame's printed board basis has
approximately0.9999837 determinant. The rigid-only grind/sweep API correctly
refuses that frame, but cannot validate a static Manual presentation. The new
private static query leaves that API and its rotation/interpolation contract
unchanged. It uses zero query margin, all native world/steel/platform layers and
only the rider's own exclusion, refuses every native hit, and restores each
changed query field. No query-only normalization substitutes different geometry.

A rejected Manual plane fit also stops assuming its original pose was clear.
The restored actual tyre hulls must prove upward native support, a clear raised
endpoint and a downward cast within the existing25mm rim cap. All four final
native tyre hulls and all connected board pieces must be clear before moving the
whole visual hierarchy together. The physical root, movement and local Manual
pivot remain untouched; the existing camera checks and tolerances remain intact.

The print-only rejected prefix identifies the old final lowering guard at
physics tick1637. Both native tyre rest normals are the actual graded street
normal, raised endpoints are clear, and bounded downward casts produce a4.785mm
candidate. Its retained `invalid_frame_or_model` result and actual basis explain
why restoring the original unsafe flat presentation did not solve contact. The
subsequent repair uses the actual static geometry rather than weakening rigid
validation. The print-only source adapters and all rejected logs remain archived.

| Final native record | Result | Stable inputs | Time |
| --- | --- | ---: | ---: |
| [Full test graph parser](manual-grade-twin-parser/receipt.json) | clean | 673 | 2.711s |
| [Exact Gallery→Station prefix](manual-affine-prefix-native/receipt.json) | **4/0** | 678 | 16.242s |
| [Standalone Station](manual-affine-standalone-native/receipt.json) | **2/0** | 678 | 14.088s |
| [Original Grade and earned Wall Manual guards](manual-grade-twin-guards-native/receipt.json) | **120/0** | 674 | 9.223s |

The exact prefix retains the same independently calculated **11,116-point single
Station bank**,668 Manual ticks,68 bank-Manual ticks, both native spine faces,
the actual transfer and zero bails. Its original strict camera/visibility result
now passes. Standalone Station is supplementary evidence, not a replacement for
that prefix.

The first guard run was112/8 and is retained at
[manual-affine-guards-rejected](manual-affine-guards-rejected/receipt.json).
The Grade fixture superimposes a negative-control Skater on the tested rider in
the same native world. The new all-solids model query therefore correctly saw
that extra layer2 capsule as an obstacle. Only that diagnostic control's public
collision layer is now0; the actual rider remains on layer2, and both actors keep
their original world collision mask9, native capsule, initial state and motion.
Every original support/penetration, exact physical/local-pivot parity, planted
shoe, attachment, score, unsafe-corner and query-restoration assertion remains.
All120 now pass. No live product collider or world/rail layer was removed.

The earlier [bounded-rim-only prefix](manual-rim-prefix-rejected/receipt.json),
[print-only prefix](manual-rim-print-prefix-rejected/receipt.json) and initial
rejections remain evidence of the intermediate failures. These are focused
headless results; the required whole-project verification and platform trial
are reported by the parent integration work.
