# Existing-level surface and skating audit

23 October 2026. Original compressed Glasgow map, Godot 4.6.3. This records the overnight implementation and native collision evidence; it does not certify human feel, final art, Mac performance or every possible approach.

The six existing places remain connected. All ten career goal identities, side encounter identities, published navigation routes, bridge gap and route mouths are retained. The level changes concentrate skating opportunities in two underused spaces and make existing raised architecture usable without filling landing lanes with decoration.

## Inventory and runtime contract

`world.get_surface_audit()` returns a defensive dictionary built after level geometry and dressing finish. The frozen level contains **357 static collision bodies, 55 eligible wall bodies, 45 bodies associated with grind tracks and 111 total grind tracks**. Of the tracks, 47 are authored paths and 64 are top edges derived from selected real box colliders. A body count is not a count of independently verified approaches.

Every physical body receives a stable semantic audit ID, `wallrideable`, `no_wallride`, an exclusion reason and its associated `grind_surface_ids`. The snapshot includes body path, shape type/count, box dimensions, collision layer, position, wall reason, track IDs and explicit visual-only exclusions. Art labels keep duplicate benches, terrain pieces and boundaries identifiable across scene construction. `world.get_grind_lines()` returns the existing authored tracks first, then derived edges; original goal/encounter rail IDs remain unchanged.

Opaque box architecture qualifies at 1.6 m height and 2 m face length. Convex terrain masonry qualifies only when a contiguous exposed face at least 2 m long rises at least 1.6 m above supported lower terrain. Its actual retaining thickness must also reach 1.6 m: suspended 0.4 m platform slabs are not counted as walls merely because their decks sit 3 m above the concourse. Live wallride side probes still require the actual bounded vertical face at two rider heights. Top/bank normals cannot become imaginary wall planes through metadata. The solid river retaining masonry can be ridden where native contact exists; the water recovery hazard remains.

| Surface family | Result |
|---|---|
| Opaque city facades, venue, retaining masonry, market backing, recording alcove | Explicit rideable wall semantics, subject to actual contact and native movement clearance |
| Court seating and both planter sides; four city planters | Exposed top edges derive from the real body dimensions; the visible court cap overhang is respected |
| Merchant Close pocket planter, workshop seats, Clyde benches and print-yard planter | Real ledge tracks; existing authored coverage is reused instead of duplicated |
| Civic garden polygons | Both gardens have perimeter coverage; the original left garden track ID remains |
| Gallery stair cheeks | Only the visible upper edges south of the buried landing portion receive finite ledge tracks |
| Both Central raised platforms and suspended service walk | Continuous top-edge tracks; the lower concourse, platform transfer gap and underpass stay clear |
| Civic workshop terrace and Barras loading lips | Raised terrace perimeter and the exposed lip sections between bank/stair openings are grindable |
| Clyde safe and broken bridge handrails | Both sides of each intact piece have finite grind tracks; no track crosses the eight-metre water gap |
| Monument foot and crown | Real perimeter edges are grindable; high-cap approach/reachability is an advanced traversal case, not certified by a positioned capture test |
| New manual pads, low ledges and quarter-pipe coping | Collision-backed pad/ledge edges and finite coping tracks on both practice features |

## Useful density within the current map

**West Clyde quay practice pocket:** X −145…−105, Z 56…75, floor Y 2. A radius-2 m, width-8 m quarter-pipe at toe `(−124,2,65)` faces west, with a 16 m clear approach/return. A broad 0.48 m manual pad, 0.55 m ledge and 0.68 m flatbar support short linked practice lines. The Station–Barras route starts east of this pocket; the bridge approach, quay recovery and river landing lanes remain open. Existing benches now contribute usable low ledges.

**Kelvingrove promenade practice apron:** X −118…−76, Z −139.5…−126, floor Y 6. The existing George-to-park promenade widens into a concrete apron with a radius-2.4 m, width-8 m quarter-pipe at toe `(−96,6,−130)`, an 18 m approach, manual pad and low ledge. Grass shoulders blend beneath the apron into the existing embankment; the concrete does not conceal a floating unsupported slab. The rear shoulder stays supported up to its visible perimeter; this fence is raised to 5 m to contain the new deck and an ordinary deck ollie. Slab joints and restrained approach inlays make the layout legible. The original promenade remains on the north side.

Both features have a real curved collision face, a rear deck, side roll-in and top landing. Their transition state and motion are supplied by `transition_feature.gd` / `transition_ride.gd`, not this audit. `world.get_skate_feature_definitions()` publishes both pocket IDs, bounds, feature families and approach/landing points for capture and clearance checks.

Final rendered review replaced the ramps' plain overbright material with original muted concrete grain, generated locally with FastNoiseLite and a seamless 256 px noise texture. World-space projection keeps a consistent two-metre scale across the curved face, deck and sides; steel coping retains its contrast. Three visible feet now support the Clyde flatbar. Retained map edges have double-sided stone foundation faces extending eight metres below their actual fence baseline. These vertical scenic faces close exposed undersides without adding collision, a horizontal catch floor or playable terrain behind a boundary.

The Exchange fountain court keeps its broad circuit, George keeps the ordered coping challenge and bank bypass, Central keeps platform runouts, and the Barras keeps its sheltered delivery aisles. These clear areas provide approaches, recovery and sightlines; they were reviewed as playable space rather than filled with arbitrary obstacles. The woodland and distant south-bank landscape retain scenic value rather than becoming new districts.

## Explicit exclusions and practical limits

- Retained perimeter iron fences remain safety boundaries. Their open bars and collision envelope are not opaque wallride architecture or hidden grind routes.
- Glass panes, water, foliage, canvas, thin posts, lamps and high shelter roofs are not supporting walls. Decorative facade details do not create a separate collision plane.
- Stocked market counters retain their merchandise and hanging canopy valances. Standing grinds along those tops would clip the dressing/headroom; they are recorded as excluded working counters.
- Decorative benches and bins behind retained city boundaries remain scenery. They do not manufacture playable collision or invisible tracks.
- Behind-boundary stone foundations are vertical visual scenery below the existing baseline, with no collision, wallride eligibility or grind coverage.
- The park's 25 mm path edging is flush roll-over terrain trim. Buried foundations and top edges under another landing are not presented as usable ledges.
- Native capsule sweeps and trick-state gates can reject a blocked, misaligned, ascending or otherwise ineligible capture even when a track exists. Positioned acquisition proves collision feasibility at sampled points, not discovery, an ordinary-ollie approach, or acceptance of every corner at every speed.

## Verification

The focused harness ran `SurfaceCoverageTests.run(tree,world,check)` and the existing `WorldRoutesTests.run(tree,world,check)` with fixed 60 Hz simulation: **240 passed, zero failed**. It verified all generated box-edge tracks and the new raised-terrain tracks at three interior samples using `GrindRide` acquisition plus the production-sized capsule, native overlap and motion queries. It also verified unique track IDs, all selected ledge references, defensive snapshots, bridge-piece bounds, both clear supported 10 m-plus transition approaches, wall-helper eligibility agreement, actual vertical side hits on box and convex retaining masonry, and perimeter containment from the new apron/deck-ollie heights. Existing district routes, checkpoints, goal/secret markers, gap floors and NPC support checks pass unchanged.

Root owns the final aggregate, actual Main trick integration, rendered six-district/practice-pocket captures and source-bound final evidence. Human controller, target-Mac performance and final visual acceptance remain separate gates.
