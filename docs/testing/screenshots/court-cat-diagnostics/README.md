# First court/cat capture diagnostics

These actual frames and manifest preserve the first 32-image review candidate, completed 17 October 2026 at 16:11:10 UTC from dirty source based on `64000fd`. Manifest SHA-256: `28126c99411a29242fa7459b3f10d71c99b8e00d9e40b97c948c960a8f9d9257`. Source stayed stable across the run; these bytes precede the corrections below and must not be presented as final acceptance.

- `24-barras-aisle-return.png`: the authored fixture at (82,0,−2) settled atop an existing stall counter at Y1.207 while the route support is Y0. The awning hid the rider. Correct the viewpoint to the clear supported southeast return and require floor-height/capsule clearance before accepting an image.
- `32-cat-success.png`: the real A→B→C transfers banked 1,050 once, but the initial 3.2-second dance ran behind the east-facing chase camera. Score completion is real; the frame does not show the payoff. The bounded correction queues the dance for an actual nearby return with the stage visible, without changing bank/reward semantics.
- `22-george-workshop-approach.png`: missing/dark retaining sides prompted a mesh-normal check. Geometry confirmed inward-facing polygon sides and corrected side-triangle winding without changing top/collision/route geometry.

The complete first candidate remains in ignored `.local/level-design-20261017T161036Z-Bj42Lx/`. The successor set is published separately under `../court-cat/` after its source guard and actual review. Historical `../level-redesign/` evidence remains untouched.
