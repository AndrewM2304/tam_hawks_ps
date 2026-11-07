# Physical board construction — private source study

The installed UV04 board is unchanged. No engine, runtime code, contact datum or
game asset was changed by these source-only studies. This packet is a reviewable
next construction proposal, not a completed FID-103 board.

The declared budget precedes authoring in `specification.json`: one mesh, four
surfaces/materials, the same atlas, no runtime construction or extra collision
objects, at most 512 added triangles and 128 KiB geometry buffers. The proposed
profile uses 10.25 mm wood, 55 mm trucks, retained 64 mm wheels and 3/8 in risers.
Actual maker references and inference limits are recorded in the specification
and [construction review](../../../research/BOARD-CONSTRUCTION.md).

The original grip arrays and axle Z positions stay exact. Moving the baseplates
40 mm inward and using a documented 41.275 × 53.975 mm mounting pattern gives a
376.025 mm / 14.804 in inner-bolt wheelbase. Bolt heads follow actual finite grip
faces with a declared 0.1 mm crown. This avoids the old unsupported outer bolts.
The tubular hanger and single bushing remain artistic/mechanical limitations;
source dimensions alone cannot establish that the truck looks or moves credibly.

Study01 adds 32 triangles but fails its separate 24/1 arithmetic audit: corner
matches hide a 186.015 µm internal pad/wood discrepancy. That version remains
rejected. Study02 clips actual finite wood-bottom facets to the pad footprint.
Its 25/0 author arithmetic check measures 3,010 overlapping triangle-pair vertices
and finds a maximum absolute pad/wood separation of 0.131 nm. It adds 300
triangles and 30,600 geometry bytes, giving 5,996 triangles. Encoded atlas bytes,
grip attributes/indices and all original triangle index topology remain exact.
Each wheel receives one rigid translation; its radius is not reduced.

Study02 GLB SHA-256 is
`c7737ca758b1f8aa39b259ae88c28a98b817f5417b1433d137d39e69075215f5`.
Its source-only arithmetic shares a binary accessor reader and is not independent
QE. The 10 nm pad-conformance design check does not replace or alter any gameplay
contact tolerance. The thin-only negative retains old hardware and demonstrates
a 23.75 mm mounting gap and 19.75 mm boardslide-datum error.

## Contact-cache obstacle — admission remains blocked

A physically assembled pad shares actual vertices with the wood and baseplate.
The existing all-mesh coordinate-weld constructor merges the wood and both mounts:
30 convex islands replace 32. Source reproduction finds point `(0, -0.010, 0)`
7.775 mm inside that merged convex hull, although its distance from every actual
triangle is at least 15.75 mm. This is a phantom obstacle beneath the deck middle.
The retained diagnostic is source-only; it does not assert a new defect in the
unchanged installed UV04 model or an executed Godot collision query.

`semantic-parts-proposal.json.gz` declares 32 logical volumes, assigns every one
of 5,996 source triangles once and stores 37,188 bytes of actual float32 support
points. It is an **unadmitted data proposal**, not an instruction to trust those
points at runtime. A future editor/cache migration must authenticate the actual
imported indexed face membership, source and policy hashes, finite transforms and
complete coverage. Missing/duplicate/foreign faces, altered vertices, wrong
part ownership and stale/reset caches must fail closed. Sixteen separate source-only structural controls pass, including missing, duplicate,
foreign/fractional face IDs, wrong winding/ownership, a 100 µm point displacement,
NaN and malformed/oversized point buffers. This tests the proposal producer and
raw source consistency; it does not authenticate native or runtime metadata.
No per-frame parsing or mesh construction is proposed. The old fused-hull witness must remain a negative.

The future runtime datum migration is explicit: wood underside −14 → +5.75 mm;
truck bearing −103 → −73.775 mm; wheel centre −88 → −58.775 mm; wheel bottom /
board rest height 120 → 90.775 mm. Retaining the existing grip does not justify
leaving dependent wheel, manual, Casper/Pogo, grind, release or wall constants
behind. Actual native contacts, ordinary mapped-input Main motion, all named
styles, close/moving artwork, independent QE and full regression are mandatory
before any physical-board promotion.

## Reproduce the source study

Reconstruct the private folder `.local/board-fidelity/construction-study/` using
the retained scripts (remove their `.txt` suffix) and `specification.json`. Place
the installed exact UV04 GLB in sibling `candidate-uv04/tam_skateboard.glb` and
copy `tools/art/finish_board_uv.py` to sibling `board_uv_finish04.py` (the binary
reader only). Use the pinned board-art Python requirements. Run `build_study.py`
and `verify_study.py` to reproduce the rejected first pad, then `build_study02.py`,
`verify_study02.py`, `part_provenance.py` and `verify_part_proposal.py`. Do not install their generated GLBs.
