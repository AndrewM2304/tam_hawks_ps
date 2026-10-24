# ADR-030: flush Clyde bowl

24October2026; owner-authorized candidate. BOWL-01 in the local task overlay.

The owner rejects the raised standalone bowl and small external ramp. Retain its
shape, identity and steel coping, lower its bottom2.4m toY−0.4 and put the deck at
the existingY2 quay. Honor the existing `build_access` switch in Bowl; other
callers retain their default raised access. Reuse quay paving on the deck.

Both overlapping outdoor terrain bodies need real excavation: remove native
faces inside the128-sided bowl mouth and visible faces inside its outer deck.
Keep earlier unrelated visual trims and retain all exterior collision. Use
built-in Geometry2D subtraction at startup on these small terrain triangles;
the clip must cross triangle edges rather than enclose a hole inside one face.

Inside this pit, support height follows the actual128×90 faceted wall: project
onto the angular sector bisector and interpolate between its two sampled rings.
This is constant-time and introduces no per-frame geometry or physics query.
Independent engine rays must verify it, including between angular/ring samples.

This decision changes level placement and treatment only. Bowl pop/transfer,
body pose, camera and the separate Kelvingrove facility remain other tickets.
Performance budgets and acceptance evidence belong in the linked task/status.
