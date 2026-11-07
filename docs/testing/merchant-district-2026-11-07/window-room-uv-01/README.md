# One coherent room per Merchant window

The canonical1.4×2m glazing mesh supplies metre-based UVs to a shared shader
expecting a BoxMesh front atlas cell. Actual native arrays span4.2×4 shader rooms
per pane, making repeated dark grid fragments instead of a coherent interior.
The original control fails all three native size cases (0/3).

The correction assigns only the glazing's UVs to U1/3…2/3 and V0…1/2, matching
the existing shader's3×2 mapping. Candidate native3/0 reports1×1 room at each
tested size. Actual serialized native arrays are exact for stone, timber and
glazing positions, normals, tangents, indices and format; only glazing UV slot4
changes. No shared shader/material, geometry, collision, guide or controller
changes occur. Construction remains startup-only with no new resources/queries.

Both frozen four-view render cohorts pass26/0 with natural-frame camera, canvas
and world-marker pixel witnesses. Front, oblique, Market and High Street cameras
and projections match exactly; native draws, submitted primitives, buffer and
texture memory match in every view. Root inspects both close pairs and candidate
street views: the tiny repeated interior grid is removed while the facade and
skating composition remain. These are static resource/data comparisons, not a
whole-game frame-time, M5, normal-speed motion or final-art pass. Independent new
specialist review remains unavailable at the provider usage limit.

The actual one-file guarded install binds base main
`d5498ab47af76b6231c6cfaae92ccfa352d86e58`; the other940 frozen inputs remain
exact. Required07 is running when this packet is sealed; no completed full check
is claimed here. Its eventual receipt belongs in a separate packet. Current
packages/required06 precede this UV-only change and retain that source scope.

`source-closure.json` resolves all941 required07-before inputs using exact Git
blobs or gzip objects. Original baseline/candidate failures, readbacks, images,
launchers, source maps and install receipts are preserved. Run
`python3 verify_packet.py` here for57 payload and941 source identity checks.

