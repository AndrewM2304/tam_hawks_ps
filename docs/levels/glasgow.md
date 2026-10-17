# The Glasgow level

This is a fictional arrangement of Glasgow-inspired districts, not a geographical reconstruction. Models/textures are authored or reused with appropriate permissions; real street/shopfront references guide recognisable perimeter architecture, while playable routes are deliberately adapted. No scraped map, photograph, logo or commercial game layout is bundled.

## District plan

| District | Visual identity | Skating opportunities | Objective / secret hooks |
|---|---|---|---|
| George Square | Civic stone silhouettes, broad square, planters, statue and cone | Open learning loop, low ledges, approachable ramps, intersecting lines | Intro score runs, tokens, cone event |
| Royal Exchange Square | Gallery-inspired central form, columns, dense paving court | Circular ledge route, precision gaps, arcade passage | Combo route and discreet side-area entrance |
| Central Station surroundings | Original arched canopy and railway architecture silhouettes | Longer approaches, bank-to-rail links, elevated line with safe exits | Platform route gap and checkpoint |
| Barras / Barrowlands | Market stalls, warehouse fronts, original bright venue sign | Tight technical turns, stall gaps, roof-adjacent transfer | Market collectibles and lost recording |

Connections use fictional compressed streets. Provide at least two ways into each district and avoid a single corridor that prevents combo flow. Loading transitions cannot interrupt a running combo.

## Recognisable perimeter edges

The owner specifically wants researched Glasgow shops/venues and street layouts instead of generic shop rows. Use the [reference register](../research/GLASGOW_REFERENCES.md) to verify real street relationships, entrances, bay rhythms, corners and skyline cues. Non-playable border facades can establish place without adding interior gameplay scope. Keep reference imagery separate from shipped assets, verify changing tenancies and date every source. M03-006 verifies references; M03-007 implements authentic boundaries. The current fictional shop signs are temporary.

After core gameplay is accepted, replace blockout visuals under [art direction](../product/ART_DIRECTION.md) and the required M06-007 cleanup gate. Generic cuboids are not the final aesthetic.

## Route acceptance

Author a traversal route from spawn through all four district checkpoints back to spawn, at least one beginner repeatable loop per district, and at least three combo links across district boundaries. A09 records route time, stalls, unintended collisions, camera occlusion and recovery. Check both travel directions where the route is intended to be bidirectional.

Use explicit collision geometry for skateable ramps, ground and rails. Decoration must not create tiny snagging surfaces. Hazard boundaries recover the player; optional hidden areas must have a reliable way out. Root transforms and scale changes cannot silently alter trick physics.

## Secrets and interactions

M03 reserves a hidden interior/court, a route shortcut, a reachable secret recording location and the cone event geometry. M04 connects mission events and persistence. An object looking like a collectible does not count as a functioning objective.

## Current playable layout

The original Exchange controller test square now connects to three geometrically distinct skating spaces. The functional geometry has received an initial architectural/material pass, while the street arrangement, buildings and current shop identities remain original compositions. Real shop placement and final visual acceptance remain separate work.

| District ID | Collision floor extent (X, Z) | Checkpoint | Distinct route |
| --- | --- | --- | --- |
| `royal_exchange` | X −35…35, Z −42…42 | `(0, 0.8, 12)` | Original four banks, two rails and monument court |
| `george_square` | X −35…35, Z −125…−55 | `(0, 0.8, −70)` | Broad civic learning loop, two low banks, long rail and ledges |
| `central_station` | X −128…−48, Z −42…42 | `(−65, 0.8, 22)` | Canopy, 2m elevated platforms, a real 4m platform break, ground and elevated rails |
| `barras` | X 48…128, Z −42…42 | `(65, 0.8, 22)` | Market counters/awnings, basket hop, technical rail and recording alcove |

Exchange has paired 12m openings toward George at X±20 through the north boundary, and toward Central/Barras at Z±22 through the side boundaries. Segmented walls retain the original collision boundary on all four center-axis rays. Facades have actual openings at these connections; there is no invisible passage through a shop mesh.

The northern back lanes connect Central → George → Barras without crossing Exchange. Central's north route runs at X−88 to Z−78, then east into George; Barras mirrors it at X88. These routes give every district multiple entrances and form a continuous outer loop. The letter S occupies the western back lane. The recording alcove at `(120, 0, −33)` has a ground-level south entrance at Z−22 and the same clear exit.

Suggested all-district survey: Exchange → west connector at Z22 → Central checkpoint → north lane at X−85 → back lane at Z−75 → George checkpoint → east back lane at Z−78 → Barras north lane at X88 → Barras checkpoint → east Exchange connector at Z22 → spawn. Use intermediate turns around the actual obstacles; checkpoint-to-checkpoint straight lines are not promised to be clear. Paired lower connectors provide shorter alternative returns. Human skating/comfort acceptance remains open.

## Reference workflow

A05 may consult public architectural facts and owned/licensed references for proportions and atmosphere. Record each actual imported asset and its licence in `docs/licences/REGISTER.md`. External images are reference-only unless explicit redistribution permission is established. Do not download asset packs just because they are labelled free.

## Implemented square geometry

`game/levels/glasgow_square.gd` generates an original civic skating court: sandstone tenements, slate rooftops, teal shop fronts, a clock tower silhouette and a cone-topped statue named **The Provost of Push**. The statue is an original standing skater, not a reproduction of a real monument. Procedural meshes, colours and signs require no downloaded assets.

Coordinates are metres, +Y up; spawn remains `(0, 0.8, 12)` facing -Z. All ground floors are Y=0. The original 70 × 84m court and four ramps retain their coordinates; perimeter walls now have connector openings. Mesh overlays and paving joints are visual only. All nine ramps use convex wedge collision and inclines below 15°. The six grind rails publish world-space metadata matching their visible tops. Rail bars/posts occupy layer 2, mask 0, allowing explicit grind acquisition without thin supports snagging the player; ordinary world collision is layer 1.

| Route | Start / direction | Obstacle | Landing space |
| --- | --- | --- | --- |
| Central launch | Spawn, straight toward -Z | Width 7 m, Z=-4 to -12, rise 1.6 m; 11.2° | Clear center lane through Z=-28 |
| Tenement return | X=-17, Z=-23, toward +Z | Width 6 m, Z=-14.5 to -7.5, rise 1.35 m | Clear return toward Z=18 |
| North bank | X=-5, Z=-23, toward -Z | Width 9 m, Z=-29.5 to -36.5, rise 1.8 m | Short 4.5 m apron before boundary; turn or brake after landing |
| Warm-up bank | X=7, Z=24, toward +X | Width 6 m, X=12.5 to 19.5, rise 1.1 m | 14.5 m to east boundary |

Low Exchange ledges are 0.48–0.56m tall. Original monument collision remains at X=11.5–16.5, Z=−17.5…−12.5, clear of the main skating line. The statue and distant skyline are visual ornaments above solid plinth/building collision. `get_location_name(position)` exposes district names plus the original Exchange subareas. `skateable_ramps` identifies all wedge bodies, with rise/run/width metadata for inspection.

Central's approach bank runs north at X−94 from Z24 to Z12, rising 2m onto the south platform (Z0…12). The second platform spans Z−16…−4. Ollie across the 4m break; a failed transfer lands on the ordinary ground floor rather than a lethal void. The northern bank descends from Z−16 to Z−28. Canopy posts are outside the 12m elevated lane; the roof is above 8m.

## Goal and gap metadata

World metadata exposes fresh collections; gameplay owns rendering, collection, scoring and persistence. Positions are transformed into world space on access. Re-query rail snapshots after moving the world.

| API | Contract |
| --- | --- |
| `get_district_id(position)` | Canonical `royal_exchange`, `george_square`, `central_station`, or `barras` |
| `get_district_checkpoints()` | Dictionary from canonical ID to clear supported spawn position |
| `get_goal_markers()` | 14 dictionaries containing `id`, `kind`, `position`, `radius` |
| `get_gap_definitions()` | Three dictionaries containing `id`, `name`, `start`, `end`, `radius`, `points`, `airborne_required` |
| `get_grind_lines()` | Six MIT-helper geometry snapshots, including the two unchanged original rails |
| `get_npc_positions()` | Four off-route bystander positions for optional proximity ambience |
| `activate_cone()` / `reset_interactions()` | Pop/tip the original statue cone once; restore it and clear `cone_activated` on restart |

Letters H/A/W/K/S occupy Exchange `(0,.9,−20)`, George `(15,.9,−106)`, the north station platform `(−94,2.9,−10)`, Barras `(88,.9,0)`, and the west back lane `(−60,.9,−78)`. Market item IDs `market_1`…`market_3` sit in clear market aisles. `interaction/cone` is reachable beside the monument at `(14,.8,−10)` and animates the actual cone above it without moving collision. The world is explicitly pausable, so the cone tween stops during pause and reset kills it. `collectible/secret_recording` is in the recording court. Four `district` markers match checkpoints.

| Gap ID / label | Start → end | Rule |
| --- | --- | --- |
| `exchange_launch` / Exchange Air | `(0,1.5,−12.5)` → `(0,.8,−18)` | Original central ramp launch; 2.2m trigger radius, 300 points |
| `central_gap` / Mind The Gap | `(−94,2.4,1)` → `(−94,2.4,−5)` | Elevated platform break; 2m trigger radius, 600 points |
| `market_hop` / Barras Basket Hop | `(88,.8,8)` → `(88,.8,2)` | Bank-to-basket hop; 2m trigger radius, 350 points |

All three gaps require airborne traversal. Gap event verification belongs in the gameplay integration suite; metadata alone does not establish a scored jump.

## Architecture and material pass

`game/levels/city_art.gd` owns original visual detail and never creates gameplay collision. It generates three repeatable 256px masonry/paving/slate textures in memory, including mipmaps, and shares material resources between level instances. World triplanar mapping keeps material scale consistent. The textures are entirely authored code output, without photographs, external datasets or asset downloads.

Facade modules have dark window backplanes, raised stone surrounds, individual sash/divider detail, cornice courses, lintels/pediments, pitched slate roofs, chimney pots and drainpipes. Repeated facade pieces use `MultiMesh` batches per material and size. The architecture is inspired by broad Glasgow characteristics; it is not a surveyed replica of a real storefront. The gallery portico, civic clock/cupola, transparent arched station canopy and striped market awnings give the districts different silhouettes. Market counters hold original book-like merchandise. Rounded tree crowns and four original static clothed bystanders replace some primitive silhouettes.

The Compatibility renderer uses shared rough materials, linear tonemapping, restrained distance fog, cool ambient light and one warmer directional sun with shadows limited to 75m. There are no local light shadows, screen-space effects, imported textures or external services. Far surroundings are noncolliding scenery beyond the skating boundaries.

This is an initial visual improvement, not completion of the owner's realistic/fun final-art requirement. Materials still repeat visibly; facade geometry and trees are stylized; no verified individual shopfronts, articulated ambient NPC animation or target-Mac performance result exists. Final cleanup, authored variation, visual-density/lighting review, hardware performance and owner acceptance remain M05/M06 work.

## Rendering and collision evidence

The original independent QE covers the preserved four ramp routes and center-axis boundaries. `tests/world_routes_tests.gd` adds 89 checks against actual production collision: district classification, four clear supported checkpoints, bidirectional capsule sweeps through six paired connectors, outer alleys and secret access, sampled continuous floor, unique supported/reachable markers, the real raised platform break, bystander support, and cone animation/pause/reset. A focused Godot 4.6.3 run passed all 89 checks after the art pass. These geometric checks do not replace input-driven route trials or human acceptance.

Rendered district views use real software OpenGL at 1280×800; `.local/district-george.png`, `.local/district-central.png`, `.local/district-barras.png` and `.local/district-overview.png` are development evidence, not target-Mac performance measurements. Root's aggregate validation and checked-in evidence are recorded in `docs/STATUS.md` and the QE report. No final-art claim follows from this functional district expansion.
