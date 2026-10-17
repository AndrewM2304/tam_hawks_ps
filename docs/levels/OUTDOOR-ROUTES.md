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
- `get_grind_lines() -> Array`: `clyde_quay_coping`, `clyde_bridge_rail`, `kelvingrove_terrace_coping`, `kelvingrove_s_bend`, using the existing attributed GrindLine authoring interface.
- `get_gap_definitions() -> Array[Dictionary]`: `clyde_bridge_transfer`, readable name “Clyde Broken Bridge”, start `(35,3.05,92)`, end `(35,2.69,104)`, radius2.4, 900 points, airborne required. Trigger separation is12 m; actual missing deck length is8 m.
- `get_recovery_position(world_position) -> Vector3`: `Vector3.INF` when safe. Below Y−1.75 inside the river hazard, returns a supported point on the nearer bank at Y2.8. Return X avoids both bridge rail approaches. Root integration performs one bail, clears pending combo/gap state and preserves the original restart spawn.

The actual bridge collision bodies are named `ClydeBridgeNorthDeck`, `ClydeBridgeSouthDeck` and `ClydeSafeBridge`; all carry `surface_audio="metal"`. Quays/terrain carry stone, paths asphalt. The water has no collider. Path and terrain meshes use real concave floor collision, not scripted movement or hidden teleport links.

## Construction and verification

`outdoors/surface_builder.gd` produces indexed terrain and road meshes, matching collision and smooth normals. The park landscape uses approximately 6,100 triangles at 2.5 m spacing, the two connector embankments another 1,724, and the southbank approximately 1,000 at 10 m spacing; individual path ribbons add modest geometry. The connector embankments remain below the tested pavement and give the raised roads visible foundations. Repeated trunks and crowns use two MultiMeshes; the shared original leaf/twig crown has 3,080 triangles per tree. No per-tree processing runs, and the water uses a small original shader. These counts are a geometry budget, not a measured frame-rate claim.

Godot 4.6.3 headless startup/import is clean. Static route checks exposed overlapping quay/grass surfaces and flat-height spline overshoot; those causes were corrected. Independent QE then reports **136 static world-route checks and 33 topography checks passed**, with clean engine logs. `tests/topography_tests.gd` uses the actual production skater/collision: north quay traversal 16.08 seconds, continuous safe crossing 4.57 seconds, and Central → complete park circuit → same Central port 29.45 seconds, without bails/stalls or relocation within a route. The park run records 924 slope-supported frames and board-origin height about 2–17.8 m, including motion over the summit. The automated driver aims the grounded heading; these timings are feasibility evidence, not human difficulty targets.

The bridge fixture pushes from `(35,2,65)` toward +Z and ollies around Z91.8. It clears the actual 8 m opening, awards the named gap once, and banks 2,000 points with the ollie/combo multiplier. A separate no-ollie miss reaches the water, bails once, discards an actual pending flip and preserves an already banked 100 points, recovering on the Y2 quay. Static metadata alone is not used as proof of traversal. Aggregate integration and final rendered inspection are recorded separately by the parent task.

The final connector embankments were rechecked independently: 136 static route checks passed again, including actual floor support and capsule clearance in both directions; `.local/world-routes-final-embankment.log` is the local diagnostic log. Initial combined renders exposed checkerboard grass noise and broad metallic water stripes. The original shaders were revised to interpolate grass noise smoothly and use smaller, intersecting low-specular water ripples. This changes presentation only; the route geometry remains the tested version.

Rendered evidence is produced by the redesign capture tool using the actual six checkpoints and route/gap metadata. Useful park viewpoints: chase from the first `kelvingrove_rolling_loop` point facing its next point; scenic camera `(-181,29,-190)` looking at `(-180,10,-121)`. Inspect both core portal joins, grass/path contact, bridge opening/water, complete safe crossing and summit coping. Human difficulty, final realistic appearance, Mac launch, physical DualSense and Apple Silicon 60 fps remain open evidence gates.
