# C02 civic cameras 2/3 — environment review

27 October 2026, source checkpoint cd661ca. No production edit or engine run
by the environment reviewer. Native capture belongs to QE's source-stable
55/0 witness receipt at `.local/civic-shadow-native/receipt.json`.

The read-only comparator ran against the completed native manifest and verified
every stationary PNG SHA256, identical camera dictionaries and increasing
completed process-frame IDs. Both cameras' six stationary frames are pixel
identical: all ten consecutive pairs have zero changed pixels, channel max/mean
absolute differences zero, and null change bounds. Results remain verbatim in
`.local/civic-shadow-stationary.json`. First moving images also match the first
stationary image byte-for-byte at each exact initial camera.

The reviewer opened stationary00 and moving05/06/11 for each camera. Asphalt/tile
joins remain continuous; no missing face, open gap, duplicated dark stripe or
obvious isolated seam pop is evident in those current images. The moving views
contain ordinary parallax. No moving-pixel comparison or causal claim is made.
Native sun stays enabled: Balanced45m, bias0.1, normal bias2, MSAA2x, 3Dscale1,
occlusion off. No process-local shadow toggle was requested or run.

The relevant current authored join is at Z=-56: the two GeorgeGradedStreet
approaches meet GeorgeSquareFloor. GalleryRearFoundationJoin already subtracts
the two14x2m duplicate display-top bands while preserving native support. Existing
terrain_top_ownership_tests independently check the translated graded plane,
56m2 ownership subtraction and unchanged collision. Do not re-remove that repair
or change shadow settings without new evidence of a current defect.

No new bounded production repair is supported by this witness. Keep C02 target
Mac moving-shadow and human temporal acceptance open; paused Linux same-camera
stability and a one-metre authored camera movement do not certify those gates.
The next independent accepted implementation can continue without disguising
this limitation or hiding trial content.

Analysis SHA256: `09f7f62179a7eae64a17d014bb5eeb11a9b470088300bfb9c31e1ba040928289`.
Comparator SHA256: `42cfc0e6e70dbe3b21545e0aa41fbf34fe3177005cd0a13886924b72ce0604b5`.
