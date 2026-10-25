# Lower-park material ownership and shoulder closure

25 October 2026. PT24-04/07 continuation on main after `6b18f30`.

The owner-camera view 11 showed grass wedges inside the station/park asphalt.
The repair now covers the complete affected junction and CentralApproach
perimeter, preserving the existing skating grades and native top data.

## Final construction

`OutdoorRoutes._separate_park_grass_finishes(world)` subtracts the union of the
central approach, cutback and both core park-port footprints from the three
resident grass display meshes. Core footprints use actual `top_polygon_local`
vertices transformed through world space into outdoors space. Adjacent ribbon
sections are united before subtraction to avoid unnecessary fragments. Original
UVs and smooth normals are interpolated from each source grass face.

The wider core station port contains native grassy support up to 0.214260 m above
its old flat Y2 asphalt. `_conform_station_port_finish` fits only that asphalt
TOP to the exact native support planes, retaining the original 310 m² retaining
walls, bottom faces, native shape, published route and continuous grade. The
existing approach owns their overlapping asphalt footprint; duplicate interior
top faces are removed without a height or material bias.

The remaining bright seam was a real open edge: the approach's original roughly
20 mm shoulder clearance let grazing camera rays see distant footings below its
uncapped side. Closing only the core-port portion removed the central seam but
left its continuation north of Z−8. `_close_park_approach_edges` therefore closes
**both complete lateral edges and both end caps**, following the authored path
from (−145,2,0) through (−151,3,−22) and (−147,4.5,−48) to (−155,6,−82).

Each original strip-edge interval receives a vertical closure. Its lower datum
is a conservative bound computed from exact native grass-plane intersections
along that interval; the original core slab supplies its Y2 datum where present.
The constant lower edge remains buried beneath the piecewise ground. The upper
edge is the unchanged riding surface. The existing approach mesh and concave
shape receive matching faces, with no extra material, draw, body or shape.

The final **166 vertical faces** replace the earlier seven core-port-only faces.
They do not change original native top triangles, height queries, strip metadata,
collision layers or physics parameters. The new independent mesh-factory check
compares exact packed top vertex bytes and triangle connectivity, allowing only
physics-backend triangle-order/winding differences.

## Cost

| Existing resource | Before → after / delta |
| --- | --- |
| Three grass display meshes | 8,808 → 8,780 triangles: **−28** |
| Core station-port mesh | 12 → 54 triangles: **+42** |
| CentralApproach resident mesh and native concave shape | **+166 vertical triangles**, within declared **192** ceiling |
| Additional bodies / shapes / draws / materials / textures | **0 / 0 / 0 / 0 / 0** |
| Combined default continuation | Grass −28 + port42 + road166 + quay−315 + gate12 = **−123 submitted triangles** |

The existing grass and world-coordinate asphalt materials remain. Construction
runs at startup; no per-frame reconstruction or new queries are introduced.
Triangle accounting is a resource bound, not a target-Mac timing result.

## Deterministic checks

`tests/pt24_park_finish_tests.gd` covers the following:

- Actual displayed/native overlap across both lower ribbons, independently
  bounded at X [−160,−135], Z [−58,1]: original native overlap 705.142043 m²;
  final displayed interior overlap **zero**.
- An independently declared **15 × 16 m** core-port footprint, X [−145,−130],
  Z [−8,8]: original native overlap 240 m²; final displayed overlap **zero**.
- A declared **0.25 mm** float/boolean edge envelope. Raw ribbon boundary
  roundoff is 0.00110668 m² across the whole witness, below its 0.002 m² ceiling;
  the fixed core-port witness has zero raw overlap. No physical tolerance changed.
- Thirty-six fixed entry-road support/display/query points and 26 fixed port
  points. Highest displayed port paving agrees with native support within
  **4 micrometres**; all original retaining faces remain present.
- **88 complete side/end intervals and 176 two-sided native rays**, with matching
  outward displayed closure. Both authored endpoints are fixed independently.
- The original three bright-line sites plus far-right pixels (1120,515),
  (1150,509), (1180,503), using the exact owner-camera projection at 1280×800.
  Exact centre and (+0.5,+0.5) subpixel rays hit native road and visible paving
  within 1 mm. The last pixel centre lands on the legitimate upper asphalt,
  while its subpixel ray hits the vertical closure; both are recorded explicitly.
- Four actual production-Push crossings: both directions at the port and beyond
  its old boundary at Z−10, with no ollie and **zero bails**.
- Resident resource and 192-triangle closure-budget checks, exact native-top
  connectivity/bytes, and an enclosed one-square-metre polygon subtraction case.

Existing `outdoor_repair_tests.gd` also retains 130 lateral native supports,
66 shelter-side rays, requested guard heights and summit face ownership.

Focused command:

```sh
./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_park_finish_focused.gd
```

Final focused result: **40 passed / 0 failed**, exit 0, clean engine log, in
`.local/pt24_park_complete_approach.log`. The ignored runner invokes both park
and existing outdoor-repair suites with counted assertions and nonzero failure
exit. Integration owns the final frozen-source full-suite receipt and capture.

## Rejected evidence and acceptance boundary

The earlier [grass-wedge capture](rejected-captures/grass-wedges/default-issue-0011.png)
and [core-port open-edge capture](rejected-captures/open-edge/default-issue-0011.png)
retain their manifests and rejection notes. The initial narrow approach test
missed the wider core port; the later seven-face closure missed the edge's
continuation outside Z−8. Neither subset certifies the complete approach.

Development logs preserve polygon fragmentation, native mesh-factory packing,
nonindexed/indexed SurfaceTool handling and pixel-centre versus subpixel findings.
The complete closure fixes the imported index-buffer omission by deindexing the
original resident mesh before appending new faces and indexing the final stream.
No support, closure or owner acceptance criterion was removed to hide a failure.
The previous [33/0 focused subset](validation/focused-extra/pt24_park_port_edge_caps.log)
remains historical; the complete-perimeter focused result above supersedes it.

The [current owner-camera frame](captures/default-issue-0011.png) and
[capture manifest](captures/manifest.json) now bind the complete-perimeter source.
The refreshed normal-loop capture completes twelve frames with zero failures and
unchanged sources. Root inspected view11: the original grass wedges, central slot
and remaining far-right white continuation are closed. The rejected
[uncapped-shoulder frame](rejected-captures/uncapped-shoulder/default-issue-0011.png)
retains that last failure. This is static placement/closure evidence; the paused
capture does not certify moving gameplay or temporal rendering.

PT24-09 temporal tiled-wall/shadow acceptance is not established by these static
geometric checks. Linux geometry or stills cannot certify Mac moving-shadow
stability, physical controller feel or target frame times.
