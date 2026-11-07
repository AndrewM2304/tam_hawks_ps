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
shoe intersection. UV03 deliberately preserves the hardware. A later believable
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
is preserved separately. UV03 is the current native-ready private proposal;
physical thickness and all native/rendered/contact gates remain open.
