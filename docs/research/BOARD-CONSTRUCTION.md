# Native board construction review — 7 November 2026

FID-103 is assigned to the board artist, with independent BA/QE and root admission.
The first private derivative corrects UVs/material use while preserving every
actual drawn triangle position and normal. It does not fix the inherited28mm wood.

## Attributable construction references

Inspected7November2026. These sources inform proportions; no source photography,
branding, geometry or texture is copied or redistributed.

- [Roarockit street maple seven-layer sets](https://www.roarockit.com/skateboard-building/veneer/street-deck/street-deck-maple-7-layer-sets/)
  lists five face/core veneers at1/16inch and two crossbands at1/22inch. The sum is
  approximately10.25mm before allowing for glue, pressing and sanding; this is an
  arithmetic inference, not a promised final production thickness. It also locates
  the two crossgrain sheets near the middle, separated by one core sheet.
- [Point Distribution manufacturing overview](https://pointdistribution.com/deck-overview/)
  identifies seven plies of American/Canadian maple as its usual construction.
  A dyed ply is a design choice; the Tam finish uses restrained original maple
  tones and retains the project's original river graphic.
- Roarockit's [building overview](https://www.roarockit.com/skateboard-building-1/)
  separately offers1/16inch maple veneer. A manufacturer-search result advertising
  a10mm deck could not be opened successfully and is not the physical authority.
- [Independent's own truck specifications](https://independenttrucks.com/trucks)
  list its standard Stage 11 at 55 mm and forged variants at 53.5 mm; its mid
  models are lower. [Thunder's styles page](https://www.thundertrucks.com/truck-styles/)
  explicitly labels 49–50 mm axle heights for several styles. These measurements
  establish a credible reference range, not permission to copy either brand's
  geometry or marks. The current source's baseplate-top-to-axle distance is
  70 mm (−18 to −88 mm), materially taller than these street-truck references.

The initial visual seven-layer treatment is applied to unchanged28mm geometry;
its4mm-per-layer apparent thickness is explicitly provisional. A layer pattern
cannot certify credible physical construction by itself.

## Current measured source and protected interfaces

The original board is `tam_skateboard.glb`, SHA-256
`d5a68a8bd94fa8ad5c374ceddeb3804cc38d7ef780c5b87d3093ef8e15431f99`.
Its one mesh has four surfaces and5696triangles. The maple centre spans−14..+14mm,
while the centre grip is+17mm. The baseplate top is−18mm, leaving an existing4mm
mounting gap. Wheel bottoms are−120mm, so grip-to-wheel-bottom height is137mm.
The latter is a geometric fact, not a claim that the whole setup is realistic.

`GrindStyle.DECK_UNDERSIDE=−0.014` is a current boardslide datum. Keeping the grip
and all protected hardware exact while reducing the wood to10–12mm would leave
that old underside datum16mm or more below the wood, depending on top placement.
It also creates a roughly20–24mm truck-mounting separation. Credible risers require
explicit independent physical support evidence; adding arbitrary spacers or rails
to preserve a marker would conceal the migration rather than prove realism.

A future thickness candidate therefore needs a declared actual underside/contact
migration and explicit riser specification before changing shared runtime markers.
It must preserve grip/stance and protected hardware or separately justify their
migration, then recheck boardslides, Casper/Pogo, flips, grabs, manuals, native
obstacle/wall/rail and release poses. No such migration is installed or accepted.

The separate [indexed mounting audit](../testing/board-fidelity-2026-11-07/mounting-source-diagnosis.json)
also finds24source metal components, including eight bolt centres7.5mm outside
their associated baseplate width. Actual finite grip triangles at those bolt
centres lie1.845–2.715mm below the bolt tops; the retained record supplies face IDs
and barycentrics. These are construction measurements, not a demonstrated actual
shoe intersection. UV04 deliberately preserves the hardware. A later believable
mount must address these measurements explicitly rather than adding guessed risers.

## Private first-pass budget

Declared before authoring: zero added MeshInstance nodes, material surfaces,
materials, atlas dimensions/RGBA bytes, draw surfaces or collision objects;
at most512additional triangles and128KiB additional geometry buffers. Construction
is offline/startup only. Keep at least3GB disk free for exports; the first private
asset/diagnostic set occupies only a few megabytes and does not copy a Godot cache.

The initial UV01 observes zero added triangles, four unchanged surfaces/materials,
one unchanged1024² atlas and30,800additional geometry-buffer bytes for205wood seam
vertices plus explicit wood tangents. Protected grip/metal/urethane position,
normal, UV and index streams stay byte-exact; all maple triangle-corner positions,
normals and face winding stay exact. Native import/resource counts still need
verification. No CPU/GPU/M5 or ordinary moving acceptance follows from this budget.

The generator and same-author separate arithmetic checks are retained with the
[source packet](../testing/board-fidelity-2026-11-07/source-uv01/README.md).

The later [UV03 source packet](../testing/board-fidelity-2026-11-07/source-uv03/README.md)
replaces the first stretched strip with21whole192pixel repeats around the actual
perimeter. It retains the same protected geometry/resource scope with34,880added
geometry-buffer bytes and22same-author controls. UV02's failed wrap-seam control
is preserved separately. UV04 removes UV03's unused PNG alpha without altering
any primitive or decoded pixel. The [final native packet](../testing/board-fidelity-2026-11-07/native-uv04/README.md)
records exact imported geometry/contact caches, protected packed buffers and
eight matched native close views. The actual RGB8 mip allocation is unchanged;
the native geometry/shadow/LOD payload grows by 7,232 bytes. This is a scoped UV
admission proposal, with physical thickness and moving/target-device gates open.

## Separate construction migration proposal

The next physical change must be a declared migration, not a UV revision or an
unmeasured spacer. The following is an engineering proposal, not an installed or
validated board. Preserve the existing grip/stance centre at Y=+17 mm and the
original deck outline/kicks. A nominal 10.25 mm seven-ply design is informed by
the veneer arithmetic above; final pressed thickness remains a design choice
until a finished-deck primary specification is selected.

The current [private source study](../testing/board-fidelity-2026-11-07/construction-study/README.md)
puts the wood top at +16 mm (1 mm below grip) and its underside at +5.75 mm.
It retains the actual 64 mm wheels. The [maker's sizing guide](https://nhsskatedirect.com/products/genuine-parts-1-8-in-risers-pk-2-independent)
recommends 3/8–1/2 inch risers for 60–65 mm wheels, so the study uses a declared
9.525 mm riser and 55 mm truck height rather than guessing a spacer to fill the
old gap. The resulting baseplate top is −3.775 mm, axle centre −58.775 mm,
wheel bottom −90.775 mm and actual hanger bearing −73.775 mm. Grip-to-wheel-bottom
height becomes 107.775 mm instead of 137 mm. These are candidate dimensions,
not authority to change current runtime values.

[Empire Skateboard Manufacturing's drilling guide](https://www.empireskatemfg.com/store/index.php?article_id=25&route=blog/article)
identifies a 2.125 × 1.625 inch new-school bolt pattern. The study fits that
53.975 × 41.275 mm pattern inside the existing 75 × 94 mm baseplate footprint.
Moving plate centres from ±255 to ±215 mm while retaining axles at ±255 mm gives
376.025 mm / 14.804 inches between the inner bolts, consistent with Empire's
wide-deck guidance. Source bolt heads meet actual finite grip faces, with a
stated 0.1 mm crown. The former outboard/protruding bolt locations are preserved
in the baseline diagnosis, not silently retitled as proper hardware.

The first pad geometry failed: matching corners did not prevent 186 µm of
internal pad/wood discrepancy. Clipping the actual finite wood facets produces
a source-only 25/0 construction arithmetic result, with 300 added triangles and
30,600 geometry bytes, no extra mesh/material/atlas and exact original grip.
That is not physical-board acceptance. Real mating surfaces cause the current
coordinate-weld cache to combine the wood and mounts into a giant convex island;
a retained source witness finds a phantom collision volume under the clear deck
middle. The study proposes authenticated semantic triangle ownership for 32
logical parts, but actual indexed native/import binding, negative controls and
runtime contact gates must precede any use of that metadata. The existing
stylised hanger/single bushing also still needs professional moving art review.

Before any source promotion, inventory all users of deck underside, truck
bearing and wheel-bottom datums. Replace dependent magic numbers with values
derived from the actual admitted source geometry, with explicit baseline
negative fixtures. Rebuild and certify the new complete model/component cache;
keep the old 28 mm model as a rejection/migration witness. The scope includes
floor conformance, bank/transition entry, both manual bearings, all named grinds,
boardslides, Casper/Pogo, flips, grabs, walls, handplants and release interpolation.
Grip/sole contacts must retain their existing tolerances and physical actor
trajectories must stay unchanged where only visual support geometry changed.
Where a new bearing height legitimately changes grind admission, declare and
review that physical behavior explicitly instead of imposing false parity.

Required acceptance is finite native support and complete-model clearance,
actual mapped-input Main runs, close/moving rider+board review, independent QE
and the full suite. A thinner-looking source model, centre-only measurement or
new test fixture alone cannot close this construction work.
