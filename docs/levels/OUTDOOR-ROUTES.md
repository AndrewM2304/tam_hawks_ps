# Clyde Quays and Kelvingrove Park

Original, compressed Glasgow-inspired skating spaces, authored 17 October 2026. These are not surveyed street or bridge layouts. No map imagery, third-party models, paid APIs or downloaded outdoor assets are bundled. The existing reviewed material palette is reused; terrain, paths, water, bridges, pavilion and planting are authored locally.

The core city remains responsible for its four career districts. `clyde` and `kelvingrove` are exploration/map areas and add two supported checkpoints. They do not alter the ten canonical career goals or saved district identities.

## Connected terrain

Coordinates are metres, +Y up. Published route points are board-contact ground positions. Checkpoints add 0.8 m for settling onto the floor.

| Connection / feature | Authored geometry |
|---|---|
| Central → Clyde | Core port `(-94,2,45)`; 16 m approach to the Y2 north quay. |
| Barras → Clyde | Core port `(94,0,45)`; 16 m approach rises to Y2 at Z55, then joins the north quay. |
| North / south quays | X−150…150; north Z55…78, south Z116…130, both Y2. Textured masonry retains the banks down to the water. |
| Clyde water | Main hazard X−150…150, Z78…116; water surface Y−2. The noncolliding water visual extends beyond the skating frontage. |
| Continuous bridge | Centre X−98; 8 m wide. Ground centreline `(−98,2,72) → (−98,3.4,89) → (−98,3.4,105) → (−98,2,122)`. Colliding handrails flank the route. |
| Broken footbridge | Centre X35; 5 m wide. North deck Z74/Y2 → Z86/Y2.6 → Z94/Y3.2. South deck starts Z102/Y2.8 and descends to Z116/Y2. The unsupported opening is exactly 8 m. |
| Central → park | Core port `(−145,2,0)`; 10 m path via `(−151,3,−22)`, `(−147,4.5,−48)` to `(−155,6,−82)`. |
| George → park | Core port `(−42,6,−122)`; 10 m promenade to `(−145,6,−125)`, meeting the flat lower return branch of the park loop. |
| Park rolling loop | Main riding bounds X−220…−140, Z−185…−75. An 8 m S-bend path climbs from Y6 to Y17 and returns to the lower promenade. Grass shoulders and granite edge ribbons follow the curve. |
| Park context | Rolling woodland extends to X−255…−140, Z−225…−60, with graded western/northern skirts. The south riverbank continues as low rolling ground beyond the paved quay. |

The loop knots are `(-155,6,-82)`, `(-173,7,-96)`, `(-195,9,-106)`, `(-208,11,-126)`, `(-200,13,-147)`, `(-181,15,-164)`, `(-161,17,-178)`, `(-146,15,-165)`, `(-145,11,-146)`, `(-145,6,-125)`, `(-145,6,-104)`, then the start. Curves are sampled about every 2 m. Flat-height knots suppress vertical spline overshoot; exact first/last positions preserve portal joins. Terrain is conformed beneath all three path systems to avoid invisible grass bumps through the asphalt.

The summit has a granite terrace, original small viewing shelter and accessible coping. Planting is kept clear of the route centres and their approach capsules. The landscape is still an authored first pass requiring visual review; detailed current Glasgow frontage verification is a separate recorded task.

Five south-bank facades reuse the core city's existing material-batched authoring helper, with widths 26–38 m and heights 13–19 m. Their centres sit at Z145, behind the south promenade; the nearest frontage details are around Z138, clear of all tested approaches/landings. Their workshop/record-shop names are original composites, not claims about current Glasgow businesses. This restores an urban riverside backdrop without adding a second building system.

## Runtime contract

`game/levels/outdoor_routes.gd` extends `Node3D`. The core adds it beneath the world and calls `build(world, materials)` once. The module owns its nodes and uses the supplied material palette without changing core geometry.

- `get_route_definitions() -> Array[Dictionary]`: `{id,label,points:PackedVector3Array,requires_jump:bool}` in world space. IDs are `clyde_north_quay`, `clyde_safe_crossing`, `clyde_bridge_transfer`, `kelvingrove_central_climb`, `kelvingrove_george_promenade`, `kelvingrove_rolling_loop`.
- `get_checkpoints() -> Dictionary`: `clyde:(15,2.8,67)` and `kelvingrove:(-155,6.8,-82)`, transformed into world space.
- `get_ground_height(world_x,world_z) -> float`: supported authored surface height, `NAN` outside this module. Paths take precedence over underlying shaped grass; water without a deck has no floor. The core delegates after checking its own surfaces.
- `get_district_id(world_position) -> String`: outdoor exploration ID or empty string. Connector classification uses narrow path footprints, preserving the nearby Central/George regions. `get_location_name` supplies their readable labels.
- `get_grind_lines() -> Array`: `clyde_quay_coping`, `clyde_bridge_rail`, `kelvingrove_terrace_coping`, `kelvingrove_s_bend_*` segments, cutback ledge and print-yard ledge, using the existing attributed GrindLine authoring interface.
- `get_gap_definitions() -> Array[Dictionary]`: `clyde_bridge_transfer`, readable name “Clyde Broken Bridge”, start `(35,3.05,92)`, end `(35,2.69,104)`, radius2.4, 900 points, airborne required. Trigger separation is12 m; actual missing deck length is8 m.
- `get_recovery_position(world_position) -> Vector3`: `Vector3.INF` when safe. Below Y−1.75 inside the river hazard, returns a supported point on the nearer bank at Y2.8. Return X avoids both bridge rail approaches. Root integration performs one bail, clears pending combo/gap state and preserves the original restart spawn.

The actual bridge collision bodies are named `ClydeBridgeNorthDeck`, `ClydeBridgeSouthDeck` and `ClydeSafeBridge`; all carry `surface_audio="metal"`. Quays/terrain carry stone, paths asphalt. The water has no collider. Path and terrain meshes use real concave floor collision, not scripted movement or hidden teleport links.

## Construction and verification

`outdoors/surface_builder.gd` produces indexed terrain and road meshes, matching collision and smooth normals. The park landscape uses approximately 6,100 triangles at 2.5 m spacing, the two connector embankments another 1,724, and the southbank approximately 1,000 at 10 m spacing; individual path ribbons add modest geometry. The connector embankments remain below the tested pavement and give the raised roads visible foundations. Repeated trunks and crowns use two MultiMeshes; the shared original leaf/twig crown has 3,080 triangles per tree. No per-tree processing runs, and the water uses a small original shader. These counts are a geometry budget, not a measured frame-rate claim.

Godot 4.6.3 headless startup/import is clean. Static route checks exposed overlapping quay/grass surfaces and flat-height spline overshoot; those causes were corrected. Independent QE then reports **136 static world-route checks and 33 topography checks passed**, with clean engine logs. `tests/topography_tests.gd` uses the actual production skater/collision: north quay traversal 16.08 seconds, continuous safe crossing 4.57 seconds, and Central → complete park circuit → same Central port 29.45 seconds, without bails/stalls or relocation within a route. The park run records 924 slope-supported frames and board-origin height about 2–17.8 m, including motion over the summit. The automated driver aims the grounded heading; these timings are feasibility evidence, not human difficulty targets.

The bridge fixture pushes from `(35,2,65)` toward +Z and ollies around Z91.8. It clears the actual 8 m opening, awards the named gap once, and banks 2,000 points with the ollie/combo multiplier. A separate no-ollie miss reaches the water, bails once, discards an actual pending flip and preserves an already banked 100 points, recovering on the Y2 quay. Static metadata alone is not used as proof of traversal. Aggregate integration and final rendered inspection are recorded separately by the parent task.

The final connector embankments were rechecked independently: 136 static route checks passed again, including actual floor support and capsule clearance in both directions; `.local/world-routes-final-embankment.log` is the local diagnostic log. Initial combined renders exposed checkerboard grass noise and broad metallic water stripes. The original shaders were revised to interpolate grass noise smoothly and use smaller, intersecting low-specular water ripples. This changes presentation only; the route geometry remains the tested version.

Rendered evidence is produced by the redesign capture tool using the actual six checkpoints and route/gap metadata. Useful park viewpoints: chase from the first `kelvingrove_rolling_loop` point facing its next point; scenic camera `(-181,29,-190)` looking at `(-180,10,-121)`. Inspect both core portal joins, grass/path contact, bridge opening/water, complete safe crossing and summit coping. Human difficulty, final realistic appearance, Mac launch, physical DualSense and Apple Silicon 60 fps remain open evidence gates.


## Additional return routes and low curved bank

The park gains `kelvingrove_cutback_return`, an eight-metre sampled path through these authored knots: `(-208,11,-126) → (-226,10,-111) → (-210,8,-86) → (-185,6.5,-70) → (-162,5,-54) → (-147,4.5,-48)`. The last point rejoins the existing Central approach. The western branch is a downhill alternative and uphill bypass; neither direction requires a jump. Both branches flatten/blend around a common Y11 fork apron (6m flat radius, 14m blend radius), preventing overlapping graded strips from creating a lip. Actual sampled heights from the runtime API take precedence over the unblended knot values. Terrain shoulders follow the nearer branch, and trees are excluded from its riding clearance. A separate small bank/ledge beside the lower cutback is optional.

The bridge's south landing connects to `clyde_print_yard_loop`: `(35,2,124) → (56,2,137) → (78,2,124) → (45,2,122) → (35,2,124)`. Two openings through the existing rear retaining strip and the angled paving make a compact triangular return pocket, framed by the original quay frontages. Its island sits at `(58,2,127)` with a low planted portion and optional coping. Surrounding rolling ground is lowered beneath the new paving so the route does not intersect the grass surface.

`clyde_print_yard_hip` is an optional physical curved-bank branch through the east and south sides of that island. The profile uses radius 4m, angle 0→35°, run `4*sin(35°)=2.294m` and rise `4*(1-cos(35°))=0.723m`. A 0.25m terrain mesh and its matching triangle collision form the curved climb, raised deck and rounded ninety-degree hip corner. East toe is X64.794 at Y2, reaching X62.5/Y2.723; south toe is Z131.794 at Y2, reaching Z129.5/Y2.723. The published route approaches from `(69,2,127.5)`, climbs west, crosses the deck at X60, then descends south to `(60,2,135.5)`. The low bank supports the existing 56° floor controller; it does not imply vert, wallride or dedicated lip mechanics. The outer print-yard loop bypasses it.

All three new outdoor route definitions are ordinary navigation/test metadata. None move the rider, award a trick, force a landing or grant career goals. The canonical four-district career visit/save model remains unchanged. Final route/career/render acceptance belongs in the corresponding QE reports and STATUS.

Independent focused verification passed 24/0 nonlinear/outdoor checks after these additions. The curved bank/hip route completed in 2.33 s forward and 2.42 s reverse with no bails or stalls, including elevated movement and real slope contacts; static ascending collision normals produced five distinct 5° bins, steepest sampled 31.06° within the 35° design maximum. Natural crest airtime is allowed by the current controller. The main loop and the complete original career circuit also remain supported; final aggregate/render/human acceptance is recorded separately.


Final junction cleanup removes both the granite curb and the S-bend grind track within 6m of the cutback branch, splitting the latter into separate authored lines so no invisible track bridges the opening. The Central/park embankment now extends over X−215…−130,Z−92…20 and blends down below the tested roads, replacing the exposed drop beside the lower junction. The print-yard landscape uses 5m samples and a wider below-paving cut so grass triangles cannot rise through its walkway/hip apron. These corrections leave the tested high route waypoints unchanged; final source-stable imagery and focused/aggregate results are recorded by QE/STATUS.

Fresh physical follow-up after these rendered corrections passed **30/0** checks, including both service-court escapes and all five previous nonlinear branches in both directions. The complete park climb/loop/return takes 29.30s in the idealized driver and remains free of bails/stalls. The final integrated aggregate and refreshed capture set remain separate evidence.

The final refreshed 21-view source-stable capture set was inspected for the park fork/join and both yard-bank directions: the crossing curb/grind segment is absent, the lower join has a blended embankment, and the hip/continuous return are visible. A small green inner yard wedge remains a defined-planting-edge/paved-apron art task; no additional traversal defect was found. Human route choice, controller/camera comfort and final realistic-art acceptance remain open.
