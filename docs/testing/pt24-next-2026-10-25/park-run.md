# C04-L06: existing park seats form a downhill handoff

25 October 2026. Work starts from main `258fec4`, after the Apple Music merge.
The bounded east-descent implementation passes **21 checks / 0 failures** in
`.local/pt24_park_run_admitted.log`, exit zero, with no engine warnings/errors.
Root owns matched rendered evidence and the required combined check after source
freeze. This focused result does not certify those later admission steps.

Two existing eight-metre graded seats move from disconnected lawn positions to
the west shoulder of `KelvingroveRollingLoop`. Their catches/releases follow the
actual local tangent and native support grade. The downhill seat leads through
a real inboard Ollie and manual into a visible choice between the lower seat and
the clear through lane. No park-lap challenge is created or enabled.

| Existing identity | Refit north centre, metres | Refit south centre, metres |
| --- | --- | --- |
| `park_east_lower` | (−147.9186, 9.777272, −140.0145) | (−147.9583, 7.441023, −132.0146) |
| `park_east_gateway` | (−147.4165, 6.46, −115.9338) | (−147.1921, 6.46, −107.9369) |

Each centre is three metres west of the local road centre; width remains 1.2m.
The existing top is refitted between native endpoint supports plus 0.46m. Only
these two seats change. The other six path-side seats, promenade apron, sunken
facility openings, path/grass ownership and the complete existing **166-face
approach closure** are unchanged. Summit/cutback→city and promenade→facility
flagship acceptance remain outside this local line's evidence.

## Cost and native construction

The measured component ceiling remains **zero additional submitted triangles,
resident draw surfaces, bodies, shapes, cylinder instances, materials, textures
or lights**. Each original 12-triangle seat keeps its single stone surface and
its original four-instance bearing MultiMesh, four native cylinder shapes and
one convex body shape. Material keys and batching eligibility remain unchanged.
These bearing MultiMeshes were never registered for static batching, so there
are no stale authored batch-transform records. No per-frame placement work is
added. Moving existing geometry does not certify unchanged frame times or
per-view submissions on target hardware.

Startup refitting updates the existing visible mesh, convex points, bearing
instances/shapes and grind-guide points together. Author frames remain unit and
world-up. The old rectangular support records, and any same-ID polygon records,
are removed before registering the exact same two top triangles as support
polygons. No support remains at the old lawn positions. The composition is
idempotent and runs before edge snapshots/audit and static batching.

The graded closed perimeter retains its existing generic grind-contact status;
its changing radial normals are not falsely certified as one named contact.
The flat lower seat retains verified contact. All eight actual native bearing
facet rays pass the original 4mm guide/radial-envelope comparison. Top, vertex
and end-plane comparisons retain the existing **1mm** geometric tolerance.

## Actual input and deterministic evidence

The production fixture starts at X−147.34/Z−148 on native support, heading
south. Push reaches a real Ollie catch; held Grind and ordinary balance inputs
ride the upper seat. An inboard Ollie at Z−135.3 clears the seat before a fresh
manual carries the landing across the flattening. Release and Brake bank before
the next seat. Only initial spawn/heading is supplied: no subsequent actor pose,
heading, velocity, speed, trick or score is corrected or seeded.

The admitted run records:

- Exactly `Grind_Ledge_park_east_lower`, **38 grind frames**, then a real inboard Ollie.
- **52 manual frames / 9.208m**, from (−145.9319, 6.398921, −129.1122) to (−145.9776, 6.012517, −119.9043).
- Exactly **one 2,000-point bank**, equal to the production pending value; the banked total remains unchanged afterwards. The second Ollie's real repeat degradation is included.
- Zero bails; strict full-rider/board framing, native camera occlusion and camera-volume checks pass after normal camera callbacks. The catch and lower-seat/through-lane choices are visible before commitment.
- Separate Push-only uphill and downhill traversals pass both seats without jumping or bailing.

Geometry checks cover 54 regular interior top contacts, eight actual bearing
rays, 12 transverse endcap rays, eight hull/display/query vertices and 36 fixed
centre/east bypass support/capsule sites. Endcaps are tested independently of
ambiguous exact XZ top-edge classification; their native/display requirements
are retained in full.

| Measured maximum error | Upper seat | Lower seat |
| --- | ---: | ---: |
| Native hull vertex versus authored top | 0 | 0 |
| Height query at authored vertices | 0 | 0 |
| Baked display vertex versus authored top | 0.054207mm | 0.070746mm |
| Actual native end plane versus displayed end | 0.396729mm | 0.549528mm |

Literal mesh/native local-byte equality was an invalid extra assumption after
mesh float packing. The final test retains the existing 1mm geometric contract;
no grading, collision, camera policy or tolerance was enlarged to admit it.

## Receipts and remaining acceptance

Command, with the root-serialized engine slot:

```sh
timeout 40s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_park_run_focused.gd
```

The ignored runner sets `Main.persistence_enabled=false` before adding Main;
scripted games cannot read/control the owner's Music configuration. Production
and test source were frozen after 21/0:

- `outdoor_routes.gd`: `11a2fd02dedd1dc257e2236ab3f5a79e43189b47d0d9c0473fa6039fce5880dd`
- `pt24_park_run_tests.gd`: `e72314c13a1813333de6b268893ea00baa32186ae46524ef80fdd4e093f05978`

Rejected development receipts remain separate:

| Raw `.local/` receipt | Result and reason |
| --- | --- |
| `pt24_park_run_rejected-first.log` | 11/6: initial grind missed; endpoint aggregates ambiguous; bypasses passed |
| `pt24_park_run_diagnostic.log` | Test-only bool inference error before input; no gameplay result |
| `pt24_park_run_diagnostic-corrected.log` | 14/3: real 1,425-point straight-release combo, but seat hid a low board/foot marker; exact endpoint rays failed |
| `pt24_park_run_inboard-exit.log` | 18/1: intended 2,000-point line and strict camera passed; one near-end convex ray remained ambiguous |
| `pt24_park_run_final.log` | 19/2: all prior strict checks passed; two newly added literal local-byte vertex comparisons rejected mesh packing differences |

Matched visual integration and the combined required regression remain root-owned
admission work. Human readability/fun, Mac/DualSense behavior, target-hardware
moving frame times and temporal acceptance remain open. No headless result
certifies those limits or an uninterrupted whole summit-to-city combo.

## Combined-suite fixture corrections

The first combined check reported 5,021/2. Its park material witness compared
the highest native seat top against only the five underlying road/stone skin
BVHs. The relocated gateway correctly occupies 60 reviewed floor coordinates;
its 0.46m height was falsely reported as buried paving. The corrected test first
compares that seat's actual mesh BVH and native top, then casts through only the
two named seat RIDs to review **all 3,135 original floor sites**. No coordinates
are dropped and the original **0.5–9mm** skin band is unchanged.

A second failure was an equal-depth corner identity ambiguity: at X−38.7 and
X75.7, the original solid side wall and rear wall meet at the same Z142.98 face.
Depending on native traversal order, the full-world ray can return the adjoining
`SouthPocketEndBoundary`. The corrected test verifies that exact adjacent solid's
bounds, hit plane and non-wallride policy, then excludes only its RID and
independently requires the actual rear wall. All 18 fixed full-world witnesses
remain. Separate controls hit the rear at both corners with the adjacent end
excluded, and correctly find no support when both rear and end are excluded.
No production wall, collision, material or wallride policy changes were needed.

Focused `surface_coverage_tests.gd` verification is **79/0**, exit zero, clean,
at `.local/pt24_surface_regression_admitted.log`. The 60 seat comparisons have
maximum native/display error **0.043869mm**; all original floor separations lie
between **1.962662mm and 6.044388mm**. Both positive and both negative corner
controls pass. Earlier focused 78/0 and the failing exact-prefix diagnosis are
retained at `.local/pt24_surface_regression_focused.log` and
`.local/pt24_surface_prefix.log`; the latter also reports a separate strict
Clyde bowl-return camera witness for the contact owner. Final combined admission
remains root-owned.
