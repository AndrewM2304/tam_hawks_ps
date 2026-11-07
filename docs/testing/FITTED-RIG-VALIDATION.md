# Fitted rider deformation validation — 7 November 2026

Owner: rigging engineer. Production asset owner: rider artist. Independent
acceptance: technical QE/BA. Target: MacBook Air M5. This is a validation plan and
offline investigation; it does **not** accept the fitted asset or change the
current checkpoint's runtime/test source.

## Source and stage boundary

The ignored `.local/rider-fit-staging` candidate uses the official CC0
`male_casualsuit01` welded source and the existing retained adult anatomical head.
The rider artist owns that directory. Rigging prototypes live separately in
`.local/rider-rig-validation`. Existing attachment tests remain untouched until the
director releases phase two. The retained head has a moving local frame under
TorsoRig; source-authenticated crop edges, rather than a guessed ellipse, govern
the future neck connection.

## Required native adapter

- Select every shirt/trouser shared boundary from actual source edges recorded in
  `cloth-landmarks.json` (currently 100 edges). Map imported rest XYZ+UV and weights
  to source identity explicitly; reject missing/ambiguous endpoints.
- Resolve each native Mesh.ARRAY_BONES index through its actual Skin bind name or
  index. For every vertex use the sum of `global_bone_pose * inverse_bind * rest`
  weighted by its own native weights, then the actual skeleton frame. Use the
  equivalent interpolated root frame for render checks.
- Evaluate all boundary endpoints, not only average hem/waist centres. Preserve
  existing 80-mm settled seam, 60-mm settled joint, 120-mm active-grab and 50-mm
  neck/surface recovery limits. Add a much stricter numerical weld check for the
  genuinely shared source waist; this supplements those historical thresholds.
- Transform each native trouser triangle with all its own weights. The existing
  hips-only waist-surface shortcut and procedural `.955/1.01/1.435` selection
  planes are incompatible with a new blended source mesh.
- Keep the 800-mm corrupt torso inverse-bind control, unchanged node/bone-joint
  diagnostic, uniform jacket-translation negative, and all existing actual input
  sequences. Add missing-edge and deliberately wrong source identity controls.

## Neck connection investigation

Read the exact retained head crop and actual Head/Torso transforms. Record the
head seam in torso space at neutral, yaw ±1.10 rad, actual push, crouch, deepest
grabs and recovery. Test any proposed appended neck bone without renumbering the
existing ten bones or changing physical bodies, limb targets or score. Lower
source chest follows the torso; the upper skin boundary must follow the actual
retained head crop. A source-authenticated transition or stitched seam may bridge
the two. An arbitrary inset ellipse, floating patch or oversized dark shirt fill
is not acceptance.

## Verification sequence after release

1. Native import without resource/script errors; actual geometry, source-identity,
   normalized-weight, bind and normal checks; recount rider source triangles,
   surfaces and unique texture memory against the current provisional budget.
2. Unchanged real-input body-attachment/grab/bail/restart sequence, then fitted
   semantic seam negatives. Both physics and interpolated rendered samples.
3. Existing loaded shoe/tyre/board, rail/manual, wall and all-repertoire checks;
   actual markers remain on visible source triangles with unchanged tolerances.
4. Source-stable ordinary Main push/coast/brake/Ollie/flip/grab/manual/revert/
   special motion and close neck/waist/cuff frames. Independent QE inspects the
   original frames/video and all engine logs. Full `tools/check.sh` integration.
5. Report hardware/owner/AAA gates separately; offline agreement and a green
   regression suite cannot certify those outcomes.

## Bounded offline and standalone results

The ignored source-frozen `epoch-02` packet under `.local/rider-rig-validation`
contains ten input hashes and the independent Python observer. It authenticates
all 16,672 emitted clothing triangles and UVs against the actual official source
OBJ. All 100 actual shared waist edges and their 100 source endpoints have exactly
equal GLB rest positions, normals, joint indices, weights and independently
calculated posed positions across both draws. Missing-edge and wrong-source-ID
negative controls are detected. These are source/GLB/algebra results, not imported
native or rendered garment acceptance.

The unchanged 800-mm torso inverse-bind corruption moves the actual blended waist
by a maximum 182.431 mm, exceeding the existing 80-mm settled allowance. Its torso
weight is approximately 22.8%; imposing the procedural test's old `>500 mm` waist
sentinel would incorrectly require changing good weights. Preserve the corruption
and positive limits, check an actual upper-shirt region with full torso influence
for `>500 mm` drawn displacement, and verify that the waist fails its real limit.
The actual full-torso-influence upper-shirt displacement is 800.000 mm. A second
control translates every jacket Skin bind consistently in the posed frame; its
matched waist displacement is 250.000 mm. Independent QE agrees with this semantic adaptation; no source weights or
positive attachment tolerances are changed to accommodate the test.

The retained head's real lower boundary has 46 edges/vertices. Its source-body IDs
are recovered from the original head selection and authenticated against the
existing manifest's selected-vertex SHA. The exact local ring is at `Y=-.13`,
ellipse centre `XZ=(0,.036)`, radii `.043/.039`. Current pose delivery fixes its
centre in torso space at `(0,.51,.010)` while yaw/pitch rotates the rim. Across 299
analytic states (`yaw ±1.10`, `pitch -.04..+.56`), a torso-fixed corresponding ring
can differ by 46.759 mm. This is correspondence drift, not a measured visible hole.
An appended independent head-frame bone with rest origin `(0,1.58,-.026)` and
the matching inverse bind reproduces those ring points within `5e-16 m` offline.

A coordinated standalone Godot 4.6.3 headless API fixture then passed **6/0**,
clean engine log, in under one second. It uses the real 46 ring coordinates, a
nonidentity actor transform, eighteen two-phase head/torso pose cases, a
snapshot-style bone overwrite, an independent NPC Head and a disabled-driver
negative. End-of-tick maximum correspondence error is **1.168 µm**; after the
snapshot-style overwrite it is **1.093 µm**. The wrong-neck control differs by
601.835 mm. This proves only the native external BoneAttachment frame API under
the declared fixture; actual Main, interpolated rendering and complete garment
deformation remain untested.

The first standalone epoch failed **3/3** and remains retained: binding the bone
while override was false changed the attachment's local transform, and the
fixture later reparented Head without refreshing its relative skeleton path.
Correct setup restores local identity after configuration and refreshes the path
when reparenting. Its corrected log contains no such engine errors. Immediate
getters before transform notifications settle can still return an obsolete frame;
an explicit deterministic sync remedy is the next small fixture test. Do not
infer a measured Main animation lag from this deliberately extreme standalone
fixture.

A subsequent tiny native remedy fixture passed **7/0**, clean engine log, in
0.49 seconds. Setting the final independent neck global pose explicitly from
`Skeleton.global_transform.affine_inverse() * Head.global_transform` makes
immediate synchronous readers agree within **1.168 µm**, before queued transform
notifications. The external attachment still covers the existing NPC callers.
The proposed `Garments.pose_head` call belongs at the very end of Skater animate,
after handplant/snapshot blending. `Node3D.force_update_transform` alone is less
general because it acts only when a transform notification remains queued. This
remedy is still a standalone API diagnostic, not a production rig acceptance.

The rider artist implemented the safer source-topology neck repair privately:
continue actual source body faces directly below the retained head selection,
reuse the authenticated 46 boundary identities, match their geometry/UV/normal
seam, and feather the warp/neck weights through existing source adjacency. A plane
at game `Y=1.415` has a broad upper-chest cross-section (approximately 198 mm
wide); it is not automatically a narrow closed neck. Source topology avoids the
need for a fabricated zipper or large fill patch. Private implementation and its
future native review remain open; production checkpoint source is unchanged.

The later ignored frozen `epoch-03` independently authenticates **1,076** upper
chest triangles and their UVs to the original body, with **zero** overlap of the
original selected head faces. Its 651 GLB vertices include 47 UV-split seam
vertices representing all **46** actual shared source boundary edges/identities.
Every seam endpoint is fully neck weighted. Maximum rest seam difference is
5.21 nm; normal-component-vector difference is `3.78e-8`, UV difference
`1.48e-8`. Across the same 299 analytic head poses using the actual emitted GLB
weights/inverse binds, maximum seam difference is **0.214 µm**. Minimum source
triangle area is `3.37e-7 m²`; the original 100-edge waist remains exactly welded.
These are offline source/GLB checks. Other cropped chest/shoulder boundary reaches
`Y=1.4381 m`, which requires actual anterior/upper-back/side views during yaw,
loaded push/recovery and deepest crouch/grab; a numerical neck weld does not prove
the shirt hides those outer boundaries without penetration.

Next authorised native adapter pass must also record actual world-scale adult
standing height, head/torso/limb dimensions, board dimensions and exact source
ancestry/age morph identity. QE keeps adult proportions, visual deformation,
ordinary Main, temporal contact and target hardware acceptance open.

## Native V4 rejection and source-neck correction

The rider artist's clean nine-view private V4 capture was **rejected visually**.
Independent inspection of its original face, jacket and profile PNGs confirms
background holes beside the open collar and a stepped lower neck/chest. Original
V4 source/images/logs remain in `.local/rider-fit-staging/epochs/v4`. Its earlier
point-seam and standalone API passes retain their narrower scope.

There were two concrete geometry problems. The hard 115-mm source crop left 44
nonrim boundary vertices above `Y=1.34 m`; some came within 77.1 mm of the centre
and reached `Y=1.4381 m`, exposing background. The old retained-head generator had
also forced an irregular anatomical boundary onto a planar ellipse to hide under
the former opaque collar. At real shared source edges `(833,834)` and
`(7544,7545)`, the head and chest adjacent triangles were coplanar with opposite
normals. Across all 46 edges, geometric dihedral reached **180°**, p95 **87.37°**,
with two folds over 90°. Matching vertex positions and copying normals had not
detected that folded surface.

The suspected old torso-only/mixed-weight mismatch was **not reproduced** inside
V4's small patch: all its vertices had zero original arm influence and the two
prewarps were identical. The extended shoulder patch does require the same
original body/arm retarget and weights as the outfit. Private V5 extends authentic
source coverage to 230 mm, retains one connected surface without nonmanifold or
branched boundary edges, and moves high outer cuts to at least 156.5 mm from the
centre. Its 2,004 source triangles replace the previous 1,076. Native coverage and
shirt penetration remain visual gates.

Private V6 restores the 130 neck/under-jaw positions changed by that historical
collar fit into a new ignored head derivative; the production head is untouched.
UV arrays and native face triangles remain exactly identical. Independent actual
surface-region checks find **zero positional change** for 689 eye-surrounding
vertices per side within 35 mm of the recorded eye centres, 1,022 vertices in the
declared nose/front region, 878 in the lip/front region and all 3,802 head vertices
above local `Y=-.04 m`. The altered source neck/under-jaw positions originally
occupied local `Y=-.130..-.06458 m`; maximum restoration is 47.675 mm. This does not
claim every lower-jaw vertex is unchanged.

The independently frozen V6 `epoch-05` authenticates all 2,004 emitted body
triangles/UVs, zero overlap with original selected head faces, all 46 real seam
edges/identities and 47 UV-split vertices. Actual adjacent geometry now has maximum
dihedral **19.03°**, p95 **16.93°** and **zero folds over 90°**. Maximum seam error
over 299 actual GLB-weight/bind calculations is **0.247 µm**. All 100 waist edges
remain identical. An initial observer variable-name collision was corrected and
its rejected log retained; it was not a candidate geometry failure.

These source and algebra results still require native V6 inspection. The head and
upper chest also used different skin settings despite sharing an albedo: head
specular/roughness/normal channels differed from the plain chest material. The
artist will share the actual skin material and inspect anterior/side/back collar,
head turns, loaded push/recovery and deepest crouch/grab. Current production and
existing tests remain frozen; no AAA, Main or hardware acceptance follows from
this repair proposal.

## Authored wardrobe mask and coupled deformation

The next three-view V6 and V7 candidates remain visually rejected: restored neck
geometry and eyes improve, but bright skin penetrates the upper back/shoulder of
the shirt. A native object-ID diagnostic identifies that patch as **UpperChest**;
the alternate hypothesis that rigid AnatomicalHead caused it was disproven. No
head API redesign follows from that rejected hypothesis.

The official CC0 outfit `.mhclo` contains an authored `delete_verts` section with
8,430 body IDs. It overlaps none of the 46 retained head seam identities. Pinned
MakeHuman source was read only to establish semantics: a source polygon is hidden
only when **all** its corners are masked, including original quads before fan
triangulation. The incorrect ANY-corner variant yielded 418 triangles and was
retained as an unrendered rejection. Exact ALL-original-quad data plus the exposed
body component connected to the head produces **520 triangles / 310 source body
vertices / 315 UV-split vertices**, preserving all 46 seam identities. The asset
mask is data; no MakeHuman AGPL program code is copied into runtime or generators.

Using the source mask avoids a hand-painted or arbitrary spatial hole, but its
first actual view still shows penetration. Body-only neck influences and an
averaged displacement warp can depart from the outfit's original rest/skin field.
The next private proposal shares one authored source body/neck weight field and
the actual source-neck retarget across both body and the proxy garment. Source
waist influence remains zero; original source identities/triangles and the authored
520-face coverage policy remain stable.

A further source-interface issue was caught before rendering: outfit `.mhclo`
anchors predominantly reference fitting-cage helpers outside the rendered BODY
graph. A field propagated only along BODY adjacency transferred zero neck influence
to every outfit vertex. The artist is adding an original offline exact projection
from the used helper positions onto real body triangles, recording source triangle,
barycentric coordinates and projection distance before the existing proxy transfer.
This proposal still needs independent source checks and actual native review;
no field or runtime acceptance is inferred from an implementation description.

The source-frozen V8 field audit independently checks all **321** positive helper
records against every actual body triangle using a separate exhaustive Voronoi
closest-point reference; no author KD candidate list is trusted. Maximum nearest
distance difference is `2.02e-16 m`, reconstructed barycentric point difference
`1.14e-16 m`, and scalar field difference zero. **191** records are used by this
wardrobe. All 520 original quad/triangle parent identities satisfy the authored
ALL-corner policy and retain the 46 head seam IDs. The resulting neck influence
affects 821 unique proxy source vertices / 929 emitted UV vertices, with zero
waist neck influence. These offline results verify the transfer, not the art.

Actual V8 views remain rejected because two small UpperChest triangles cross the
lower collar. Native pixel rays identify actual body source triangles 2318 and
2413; the artist confirms real intersections with steep lapel side triangles at
rest or idle. A garment-only smooth clearance solve across declared poses is
being investigated with an explicit 8-mm maximum fit offset, unchanged waist and
reported exact intersections. No further body crop or hidden filler is accepted.

Official API source inspected:
[Godot 4.6.3 BoneAttachment3D](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/3d/bone_attachment_3d.cpp).
The native fixture command was `godot --headless --path
.local/rider-rig-validation/native --script res://probe.gd`, with isolated private
XDG paths. Exact source, logs and receipts are retained in ignored local epochs;
they are development diagnostics, not a shipped game acceptance packet.


## Fitted attachment adapter handoff — 7 November 2026

The actual main exact contact helper is now `ff779d03537f86a879fde2aab49c5b342970ab80c432b8c2f22e79af099de3ca`. Its exact clean current-source complete WallManual and ObstacleArm gate passes 139/0; [the packet](deformed-contact-2026-11-07/current-02/) binds the helper, both modules, executable observer, raw output and 797 stable source hashes. This uses the procedural main rider. It does not admit the private fitted wardrobe.

`tests/skater_body_attachment_tests.gd` is deliberately unchanged. Its old rest-Y selectors (`.955`, `1.01`, `1.435 m`), pure-torso/pure-hips requirements and hips-only trouser surface transform are valid only for the legacy procedural asset. Preserve those selectors as the legacy branch. Its actual 800-mm torso inverse-bind corruption and all original positive limits remain required evidence through the transition.

The ignored `.local/rider-rig-validation/fitted_adapter.gd` is only a preparation prototype: it has **not been parsed, executed, independently accepted or promoted**. Do not copy it directly into main. The next author must:

1. Authenticate the immutable actual admitted asset and semantic JSON. Map native import vertex reordering/UV splits to actual source identities using native rest coordinates, UV, normal, resolved bone names and decoded native weights. Compare imported attributes using the actual format-derived quantization bounds; the prototype's arbitrary `MATCH_WEIGHT=2e-6` is incompatible with the observed native UNORM16 quantization and must not be treated as an accepted tolerance. Keep decoded weights unchanged for deformation. Ambiguous source identity, wrong source mapping, missing edge and malformed topology fail closed.
2. Verify every one of the **100 actual shared source waist edges**, both endpoints and all UV-split occurrences, rather than only an average ring or a count. Authenticate actual indexed triangle/source-corner correspondence. All 46 authentic head rim identities and 47 upper-chest UV-split rim vertices must be covered. The prototype's silent `continue` on missing IDs and endpoint-only report are insufficient acceptance.
3. Use each actual native vertex's current Skin bind and Skeleton global bone pose, form the weighted local skin matrix, then apply that mesh's actual current/interpolated `global_transform` once. The prototype currently shares a skeleton frame across meshes and sums transformed points; replace this with the independently GPU-proven matrix order, actual model identity and unequal-mesh/skeleton-frame witness. No weight normalization or native bake-only oracle. Rigid head geometry uses its real head model and source-authenticated natural-rest rim, not an unverified fallback offset.
4. Deform the actual selected indexed trouser triangles with their own blended weights for surface distances; remove hips-only assumptions only in the fitted branch. Preserve 80-mm settled waist, 60-mm settled joint, 50-mm neck/surface and existing active-grab/limb/sole/contact limits, plus rendered/interpolated sampling and every original action/bail/restart input. Verify adult world dimensions and source morph identity during that authorized native pass.
5. Preserve the **same 800-mm wrong torso bind**. Authentic blended waist response is about **182.431 mm**, above the original 80-mm positive bound but below the procedural-only 500-mm sentinel. Record this sensitivity honestly and retain a source-authenticated pure-upper-shirt response over 500 mm; do not alter weights or the corruption magnitude to satisfy obsolete arithmetic. Add uniform all-bind jacket translation, missing/wrong edge IDs and native bind/name corruption controls. Node/bone joint metrics must remain unchanged by the skin-only negatives.
6. Run the entire original attachment repertoire, actual fresh fitted native contact modules and normal Main admission after the director releases that source stage. Independent QE must review the executable adapter and negatives, actual native/rendered seam and moving actions. Actual M5 cost, subjective finish and 26 explicitly open internal folded-lapel cross-pairs remain separate gates.

The source-only V9 offset audit is retained at `.local/rider-rig-validation/v9-delta-audit.json`; independent raw-GLB evidence is in [the V9 fourteen-view review](rider-fit-2026-11-07/independent-v9-fourteen/). Exactly 33 shirt source positions move, at most 6.532029 mm; trousers, UpperChest, source head, indices/UV/joints/weights, authored 520-triangle mask, 46 neck identities and 100 waist edges remain exact. Fresh actual imported geometry must still be consumed by the contact cache; these offline claims are not native admission.


## V11 source-bound native admission work — 7 November 2026

The private selected GLB remains `03944d9a01a030ee39a5cab2211cc8827c85e81cd60f6fd3e8783a8d360f7a46`: 11 bones, source-authored 520 body triangles, 100 waist edges and 46 head seam identities. Native imported data has 4,567 shirt / 4,495 trouser / 315 chest vertices and 8,244 / 8,428 / 520 triangles. The old unparsed adapter has been replaced privately under `.local/fitted-rig-admission`; no actual fitted assets or body-attachment tests have been promoted.

Epoch01 was rejected for raw class-cache errors and observer JSON float/integer topology key mismatch. Epoch02/03 mapped actual cloth vertices, weights, original inverse binds and indexed topology, but exposed the OBJ import quantization omitted by the prototype. Official 4.6.3 `servers/rendering/rendering_server.cpp` packs compressed positions against AABB extent into UNORM16 and source UVs into UNORM16. The actual compressed head therefore needs a source identity bound of **6.1205 µm** in position and **2.17795e-5** in UV norm; these derive from its native AABB and format, not a contact tolerance change. Raw decoded skin weights remain unchanged.

Epoch04 passed **24/0**, exit 0, clean raw log and stable source: all native cloth vertices/triangles, 100 waist edges and 46 seam identities authenticate. Maximum waist gap is zero; neck maximum is **5.359 µm** over nine declared direct visual poses. The same **800-mm** torso bind corruption produces **182.425-mm** waist separation and **799.9997-mm** pure upper-shirt displacement without changing node joint distances. Actual fitted arm caches contain 1,202/1,116 vertices, occupy **66,100 packed bytes** and have zero endpoint escapes. This is static/direct-pose and cache evidence, not controller/Main, whole rendering, motion or Mac acceptance.

Epoch04's bind-origin translation negative was caught as incorrectly described: equal local bind-origin offsets do not cause uniform garment translation under distinct bone frames. Epoch05 fixes that by composing each bind with `pose.inverse * Translation(250mm) * pose`, giving **249.997 mm** actual separation with unchanged decoded native mass. Its full result is **29/9**, clean engine log/source but rejected for the new shoe-cache contracts: `Mesh.get_faces()`/debug hull points disagree with native indexed extrema, exceed the declared compact payload, and omit small measured hull planes. The motion engineer owns that correction.

Epoch06 exercises the privately adapted **entire original BodyAttachment** repertoire, retaining original inputs, positive limits, procedural selector branch and 800-mm corruption. Its **53/4 is rejected wholesale** because the new exact shoe math helper returns an untyped Array where Array[float] is required. The raw log, executable snapshot, PID 63172 and source receipt are retained; no partial green admission inherits from that run. Separate CPU/model-interpolated traces estimate up to **83.277 mm** neck separation after grab/recovery, while direct poses remain microns. That remains an estimate until a clean native rendered/palette proof attributes interpolation.

Independent QE additionally found required adapter improvements now being prepared in epoch07: native Head matches must be actually indexed and form all 46 boundary edges / 47 UV occurrences; unused orphan vertices cannot count. UV/normal finiteness is checked before distance matching. Actual triangle winding uses cyclic directed identity, including the official GLTF importer CCW-to-CW swap, rather than sorting corners. For rendered readbacks, use `get_global_transform_interpolated()` even on an OFF child: official Node3D documents inherited ancestor interpolation. Changing the observer to current transforms would hide the question.

Official Skeleton3D source also gives every nonempty Skin bind name precedence over its index. The inherited production helper was index-first. A held private name-first helper `77f2a6a09a40055b644b91eed901afb1111b10b15684d9293f28689998cfaab2` has independent **18/0 native palette/GPU** support, including conflicting valid bindings and missing-name failure. Promotion and rerunning the original 139 contact limits remain director-controlled.

Independent source-only audits are retained under `.local/rider-rig-validation`: shoe audit **57/0** reconstructs all eight original UV components, verifies sock islands 6/7 each have 154 UV vertices / 252 triangles, and proves exported non-sock coverage plus unchanged Cupsole/toe provenance. Per foot the actual V9→V10 delta is **171 real upper triangles restored, 61 old sock triangles removed, net +110**, with no non-sock triangle lost. Hand atlas audit **30/0** verifies original 1,817/84 UV islands, positive uniform material transform/repeat tiles, padding, and 6,300 independently inverted albedo samples against the licensed 2K source within half an 8-bit quantum. Wrong offset and disabled-repeat controls fail. An early native array diagnostic maps all 1,901 vertices on each hand to original U and `1−OBJ V`; because its enclosing epoch06 is rejected, this observation will be reconfirmed in a clean cohort. These audits do not certify final materials, mipmaps or moving presentation.

## Coherent clock and final composite admission — 7 November 2026

The private epoch07 is a clean **54/4** baseline. Its four original attachment
failures concern the independently interpolated rigid head versus the current
Skin palette. The matched epoch08 changes only the Player's local Rider and Board
subtrees to interpolation OFF, preserving the interpolated actor/Visual ancestors,
and passes the entire original attachment repertoire plus native source controls
**58/0**. Real indexed Head missing-edge/orphan and reversed cloth winding controls
separately pass **6/0**. [Independent review](rider-fit-2026-11-07/fitted-admission-epoch08/)
binds the matched sources and preserves the rejected baseline and first invalid
control fixture. This is private source admission, not a production policy change.

Actual rendered clock02 captures independently reconstruct a worst retained
**36.671-mm** head/chest separation under the original local clocks versus micron
separation with the coherent policy. All current component poses, native Skin
palettes, cameras and outer rendered frames match. The [independent 300/0 review](rider-fit-2026-11-07/independent-clock-02/)
verifies native endpoint projections and selected original images. The earlier
83/224-mm figures remain headless CPU/model-interpolated estimates; they are not
GPU measurements. [A separate native MODEL witness](fidelity-2026-11-06/rendered-model-clock-01/README.md)
proves that an OFF descendant still inherits interpolation from its ON ancestor.
Smooth high-refresh animation and target-Mac cost remain unmeasured.

The public reference generator v2 reproduces the exact native reference using
only four pinned public assets and Python's standard library. It authenticates
all 100 source waist edges, three unique meshes and complete attribute lengths,
and rejects honestly repinned malformed metadata. [Independent 18/0 reproduction](rider-fit-2026-11-07/fitted-reference-reproduction/v2/)
supports its integration; the original truncated-metadata loophole and v1 source
are retained separately.

The artist's transported03 leg-frame change retains the original 11 bones,
endpoints, source positions and weights. Actual final Skeleton frame history,
upper-segment transport and a conditioned common bend plane remove independent
segment sign flips. The private native temporal observer passes **16/0** across
near-straight extension, full bend-plane rotation, antiparallel folds, final
snapshot overrides and reset. [Independent 29/0 review](rider-fit-2026-11-07/independent-leg-temporal03/)
finds no blocker in that bounded change; it does not certify moving gameplay.

The first final composite combines exact V13 assets, transported03, coherent
Player clocks, current forecast45/name-first helper77 and the motion engineer's
candidate05 per-leg sole/full-shoe support cache. Its import and 12-control math
smoke are clean. The full source-bound core is **198/1**, exit 1 with no raw engine
errors and 875 unchanged source inputs. All original attachment and arm checks
pass, but strict non-arm bone parity in WallManual fails. A read-only repeat is
**90/1**, source-stable: its first difference is only neck bone 10, at the first
3.274-mm visual root correction, with identical head/torso local transforms and
basis but a **14.9-nm** local origin difference. The automatic external
BoneAttachment and final Player-local `pose_head` are competing drivers. Keep the
failure; do not relax exact parity. A caller-selective automatic-driver API is
prepared privately for controlled testing, retaining the NPC default driver.

The fresh native shoe certificate independently passes with exact Python integer
determinants over full-precision binary32 coordinates: 1,645 source points per
foot, 288/294 support vertices, closed oriented 572/584-face hulls, zero outside
points and 6,984 raw support-coordinate bytes. The unsupported exponent-span
negative retains every source endpoint. Fresh hand arrays again match all
1,901 source corner pairs per side with original U and `1−OBJ V`; no unflipped-V
match exists. These bounded positives do not turn the rejected combined run green.

Exact final private source, prebound wrapper, manifests, failed logs and native
outputs are under `.local/fitted-rig-admission/final-composite-01`. No fitted asset,
new attachment adapter or local clock policy has been promoted by this specialist.
Ordinary Main/motion, the corrected strict contact cohort, caller-specific live NPC
clocks, selected final native views, the 26 folded-lapel pairs and MacBook Air M5
performance remain explicit admission work.

The final private composite subsequently passes the original full core
**199/0**, ordinary Main/standalone Motion **67/0**, and the public fitted/NPC
constructor and encounter cohort **249/0**, all with clean raw logs and unchanged
source pins. The Player-only automatic-neck-driver exclusion restores strict
bone parity; NPC one-argument defaults and shared skin materials remain intact.
The real Main constructor also required removal of its obsolete separate-collar
material lookup. The registered public fitted module contributes **60** checks,
including math, source edges/winding, corruption and actual indexed shoe-cache
controls. The independent exact-integer certificate is part of the proposed
ordinary `tools/check.sh` gate, not an inference from matching native predicates.

The fresh fitted contact cache contains 3,488 nonzero native influences and
1,202/1,116 endpoint vertices: worst eight envelopes require **13,952 weighted
contributions**, plus **9,272 model transforms** recorded separately, in **66,100
packed bytes**. The original 16,000-contribution/512-KiB limits are retained;
target-M5 CPU p95/p99 remains unmeasured. The final explicit joint/native support,
12-query, 20-cm wrist, 8-mm skin and 220-mm continuity limits all remain unchanged.

[The durable final packet](rider-fit-2026-11-07/final-composite-admission-01/README.md)
preserves executable observers, candidate sources, prebound wrappers/manifests,
losslessly compressed raw logs and the rejected preceding stages. The director
has now performed the [guarded actual source install](rider-fit-2026-11-07/actual-install-01/receipt.json):
115 exact files installed and 16 obsolete asset/import/generator files retired,
with other source bytes preserved. Actual editor import, focused current-main
verification and full regression are the director's next gates. Live NPC clocks,
selected final moving Main captures, internal folded-lapel pairs and target-Mac
performance remain separate from this source installation.

The private native inputs bind 113 of the 115 integration entries. The public
60-check module and certificate verifier execute directly in those observers;
the two final runner/check hook files are source-reviewed there and await their
actual execution in the director's full check. Actual-focused01 is separately
rejected immediately for a typed-variable inference error in the later NPC clock
policy; no private green result is relabelled as that failed actual integration.

[Actual-focused02](rider-fit-2026-11-07/actual-focused-02/README.md) now passes
**93/0** on installed source: public Fitted60, default Main Motion/support32 and
Music/profile isolation1, followed by the installed independent exact-integer
shoe verifier. Exit0, no raw errors and all 875 executable/source hashes remain
unchanged before native execution, after exit and after the certificate. Its
only actual-runtime changes from rejected actual-focused01 are the two explicit
Node3D declarations. The actor clock, bead tips, sun policy, level integration and
capture tools are included in that source scope. All 11 actual imported Skin
indices are -1 with valid names; no current name/index conflict is observed.
This completes the focused actual integration gate, while full registered
runner/check execution, moving graphical acceptance and M5 verification remain
separate.

The promoted, unchanged `tools/rider_asset_inspect.sh` also completes its existing
**nine** native close views, zero failures, with **79/0** outer source/capture
checks and 874 unchanged actual inputs. [The packet](rider-fit-2026-11-07/promoted-inspector-01/README.md)
retains nine clean plus nine proof originals, exact PNG/native-RGBA identities,
current camera/pose/counter brackets and the original marker limits. All nine
clean images were opened. Face/eyes, continuous cloth/cuffs and restored shoe
vamps are visible; resting hand splay/highlights, close collar/sleeve stiffness
and an angular raised knee remain qualitative follow-ups. The thick/orange legacy
board edge belongs to separate board work. This validates the existing inspector
on installed source, not AAA finish, continuous movement, ordinary Main rendering
or M5 performance. No rendering pipeline, source fixture or thresholds changed.
