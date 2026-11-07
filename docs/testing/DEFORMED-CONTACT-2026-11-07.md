# Native deformed contact investigation — 7 November 2026

Owner: contact rigging engineer. Independent verifier: QE. Target: MacBook Air M5.
Work is private during the current production freeze. No runtime helper or existing
test has been changed in the shared game by this track.

## Defect and retained authority

`SkaterObstacleArmFit.prepare` groups vertices by exactly equal weights and refuses
more than 32 groups. The authentic fitted shirt has 508/385 distinct groups after
including all endpoints of arm-incident triangles. A procedural cylinder-row
enclosure cannot admit that source reliably. The current ordinary procedural game
also has a separate actual arm-clearance trajectory defect; geometry replacement
alone must not be mistaken for its repair.

All proposals retain 12 native queries, 200-mm maximum wrist shift, 8-mm native
skin, fixed .30/.29-m limb lengths, unchanged shoulder/root/nonarm poses and the
220-mm body-relative continuity check. Existing native finite-face/RID agreement,
mode/reset exclusions and three proposal attempts remain authoritative. There is
no tolerance or movement-cap increase.

## Private geometry algorithm and budget

At preparation, cache actual native vertex positions, nonzero bind indices/weights
and offsets for every indexed triangle incident to any strictly positive arm
influence, including native UNORM values below the former `.001` cutoff.
Include its zero-arm-weight corner too. Per candidate pose, reuse a native-pose
palette containing `bone pose * current Skin inverse bind`, construct the weighted
local skin matrix with the retained native weights, apply it to each real endpoint,
then apply the actual MeshInstance model transform **once** and take its AABB.
A triangle lies inside its endpoint convex hull, so the bound
contains the actual rendered triangle. Merge the retained native hand base/curl
bound, which encloses every normalized curl mixture.

Actual mesh changes, Skin identity changes, bind-pose changes and bone mapping
changes refresh the appropriate cache. Bind corruption remains observable; no
stale inverse-bind geometry is trusted. Routine envelope evaluation constructs no
PackedArrays, mesh resources or GPU readbacks. Cache/resource refreshes are explicit
events rather than a per-frame bake.

Admission budget declared before implementation: at most 16,000 transformed
contributions per physics tick for the current worst-case eight bounds, at most
512 KiB extra retained cache, and no new Mesh/Skin resources or explicit PackedArray
construction per ordinary bound. Incremental M5 bounds CPU p95 <=1 ms / p99 <=2 ms
is a provisional **unmeasured** target. Local wall times under overlapping untimed
diagnostics do not establish that budget or game frame rate.

The frozen fitted GLB diagnostic finds 1,193/1,108 selected real vertices and
1,743/1,530 nonzero influences: **13,092** contributions across eight bounds and
**64,108 bytes** of packed geometry/palette. Sixty-four affine cases per arm have
zero reference points outside the envelope under the existing 10-µm native
containment allowance. Wrong-bind stale bounds reject 624/558 actual points, while
the current bind palette contains them. An added native arm triangle contributes
all three real endpoints. This is offline math, not native performance acceptance.

## Source-bound native findings

Private procedural snapshot `proc-project-01` copied 673 production inputs without
change, then overlaid only the helper and one private observer. No editor/import
ran; it has its own copied import cache and XDG directories. Original obstacle-arm
and Manual-arm controls ran unchanged, followed by extra cache tests. The result
was **106 passes / 2 failures**. An initial observer type-inference parse error is
retained separately; the actual run's raw engine log is clean.

All new native cache checks pass: complete actual endpoint containment through 48
override palettes; 63,376-byte procedural cache; actual 800-mm inverse-bind
corruption escapes stale bounds for 676 points and is contained after reading the
new Skin; an actual opposite-arm bridge triangle invalidates topology selection;
all native query fields remain unchanged. Existing Manual controls and negative
guards pass. These results do **not** accept the remaining two trajectory failures.

Private diagnostic epoch `proc-project-02` retains that same **106/2** outcome on
674 unchanged inputs, measured engine exit 1, no raw engine errors and a 6.95-s
elapsed diagnostic under the declared untimed shared load. The trajectory accepts
only three fits and refuses 35. All 108 traced failed proposals hit the unchanged
200-mm wrist cap before a candidate query: a global 133-mm source arm radius sets
a 149-mm wrist target even when the actual wrist lies 60–90 mm inside the wall.
That requests 209–240 mm of translation. Ten absent-face traces are separately
retained, including the declared guard fixtures; no remembered plane is accepted.

## Next bounded proposal

The next private candidate uses the actual native hand/curl directional bearing
to seed the wrist target, then advances it only from the proposed full AABB's
deficit against the same fresh finite face. It retains the original elbow minimum
clearance and fixed-shoulder guard; the elbow band's maximum cannot be below its
minimum when a smaller wrist target is valid. Every committed pose still needs
the complete native query to pass within the original three attempts, 200 mm and
12 calls. This is a proposal for the observed bad target, not radius tuning.

Actual positive/negative native regression, fitted-mesh verification, ordinary
Main motion, source-stable rendering, independent QE and M5 CPU acceptance remain
open. The failed source/logs are preserved in ignored private epochs; no green
whole-game or AAA claim follows from the cached geometry proof.

## Corrected native candidate and shader authority

The first strengthened private epoch03 was rejected completely: an invented
`1e-5` unit-weight test refused valid native data, leaving no prepared arm records
and producing test script errors. Its **58/4** count is not an accepted run. A
separate native layout probe measured valid triangle/index/bind data with decoded
weight sums `0.9999847114..1.0`. Godot stores native weights as UNORM16; the corrected
data-validity bound is `stride/65535 + 1e-6`, preserving the exact decoded values.
This is an import-format validity bound, not a change to any contact tolerance.

Private epoch04 then passed **118/0**, clean log, engine exit 0 and unchanged
source in 8.22 s. Actual ordinary approach/Flip/landing accepts **92** fits with
zero refusals, maximum **6** native calls, **187.215 mm** wrist shift and
**74.54 mm** body-relative marker step. The exact physical/root/nonarm/far-arm
twins and the original 800-point bank remain unchanged. All original Manual
controls and new tiny-weight, Skin mutation, actual topology, native body/shape,
invalid binding, unsupported primitive and UNORM controls pass.

That epoch still used an inherited CPU oracle which incorrectly weighted world
translations per influence. Independent [official-source and actual GPU evidence](fidelity-2026-11-06/skinning-operation-order-01/README.md)
shows that GLES and RD first form a local weighted skin matrix, output `.xyz`,
then apply the actual geometry model with homogeneous `1`. No weight normalization
occurs. The native mesh bake API has a different residual-rest expression and is
not sufficient authority for this nonunit-weight case.

Corrected private epoch05 passed **120/0**, clean raw log, measured exit 0 and
**674 unchanged inputs**, in **8.90 s** under the declared shared untimed load.
It retains the same 92/0 actual trajectory and all prior controls, and adds a
far-origin native decoded-weight witness at model origin `(137,.008,-106)` plus
unequal MeshInstance/Skeleton transforms. The inherited oracle differs by
**2.660 mm** there; the corrected envelope uses the actual MeshInstance model
once. Mesh.skeleton must resolve the actual selected Skeleton. Missing/out-of-range
bindings and malformed primitive/index/weight data fail before bone-pose/query work.

The active native Manual case uses maximum **6,344 weighted contributions** and
**4,624 separate model transforms**, with **63,376 bytes** of retained packed cache.
Fresh authentic V8 source geometry under strict positive-weight incidence needs
at most **13,956 weighted contributions** plus **9,272 model transforms** across
the worst eight bounds and **66,108 packed bytes**. The additional model transforms
are recorded separately; target-M5 CPU and total resident allocation remain
unmeasured. No per-vertex Matrix/Transform resource or PackedArray is constructed
by the runtime loop; it accumulates scalar/vector matrix terms and reuses its palette.

Executable helper/observer, all native outputs, exact before/after source lists
and failed epochs remain in `.local/deformed-contact/proc-project-01..05`.
Independent QE accepted that bounded epoch05 source and receipt. The director
released its exact promotion; helper SHA `45390fb4…f784` is now on main, with the
[before/after receipt](deformed-contact-2026-11-07/promotion-receipt.json).

## Complete current modules exposed two remaining cases

The actual current-source **entire** WallManual module plus ObstacleArm module
produced **137/2**, engine exit 1, clean log and stable inputs in 16.06 s.
[Original trace and executable observer](deformed-contact-2026-11-07/current-01/)
remain preserved. ObstacleArm passes 48/0. WallManual passes 89 and fails the
dedicated positive-skin acquisition sample and two initial ordinary Manual arm
fits. Its loaded tyre/board/sole support assertion passes; this result must not
be relabelled as an integrated pass.

The dedicated test's old starting phase samples control gaps `+12.760 mm` and
then `-21.308 mm` on consecutive ticks, skipping the `0..7.99 mm` witness band.
Rendered fitted clearance remains at least 8 mm throughout. The director approved
a private initial-position change of **+8 mm for all three twins**, preserving
every input, threshold and endpoint. The resulting complete WallManual run is
90/1: the genuine positive-skin witness now passes, while the ordinary Manual
failure remains separate. The public fixture is held for review.

Read-only traces identify both ordinary Manual refusals precisely. Current hand
bearing suggests 209.07/209.35-mm wrist translations, so all three proposals stop
at the unchanged 200-mm limit without querying a candidate. Shoulders remain
outside at approximately 191.7 mm. Since IK changes hand orientation, that old
orientation is only a seed, not proof that a smaller legal pose cannot clear.

The next private boundary candidate clips only the **initial proposal** to
`wrist_gap + MAX_WRIST_SHIFT - 1 µm`, then still requires full native envelope
clearance with the original 8-mm skin. Increasing retries stop once they exceed
the same limit. It passes **139/0** across entire WallManual 91/0 then ObstacleArm
48/0, clean engine exit 0 and unchanged source, in a 21.29-s shared-load diagnostic.
Ordinary Manual has 62 accepted fits, zero refusals and zero skin hits versus
2,451 in its control. Maximum wrist shift is **199.999 mm**, at most six native
queries; actual world/common-visual-root changed-arm peaks are **197.765/199.895 mm**,
inside the preserved 220-mm criterion. The raw actor-relative 258.837-mm value
includes identical shared-root backoff and is retained explicitly; no criterion
or physical twin was changed to hide it. Original real enclosing/corner negative
geometry also passes.

[Independent clean-candidate review](deformed-contact-2026-11-07/independent-wrist-cap-review/)
records 14 bounded checks with no source blocker. Clean helper SHA
`ff779d03…e3ca` and fixture `3c3c917a…34d2c` differ from that private executable only
by removal of read-only traces/comments. The director then approved those exact
clean files and the dedicated initial phase for actual main. The
[clean actual-source combined gate](deformed-contact-2026-11-07/current-02/)
passes **139/0**: complete WallManual **91/0**, then ObstacleArm **48/0**, engine
exit 0, clean raw log and all **797 scoped inputs unchanged**, starting at
03:41:47 UTC. This separately establishes execution of the clean files, rather
than relabelling the earlier traced private proof. Before/after promotion hashes
are retained in the [boundary receipt](deformed-contact-2026-11-07/boundary-promotion-receipt.json).

**Moving review of the nearly 20-cm correction, fitted-avatar contacts and semantic
attachment adapter, full regression and M5 performance remain open.** This focused
gate uses current procedural clothing. Its 18.464-s shared Linux wall duration
is a regression diagnostic, not a frame-time or target-device measurement.
