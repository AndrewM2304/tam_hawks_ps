# Glasgow terrain and route contract

The redesign replaces the original flat four-court test layout with connected civic terraces, graded streets, a fountain loop, station platforms, warehouse loading streets, Clyde quays and a rolling Kelvingrove route. This is an original compressed skating map with Glasgow architectural cues. It is not a current map survey or a copy of a commercial skating-game level. Existing career IDs and saved progression remain compatible.

## Core terrain

Coordinates are world metres in the default level transform. The skater starts at **`(-22, 0.8, 28)`**, facing north. Holding push follows the clear western gallery bank and the western George Square approach; the fountain and stairs are visible to the right of that line. All core banks use masonry/paving or asphalt materials, with no former teal test wedges or painted runway arrows.

| Area | Authored support and architecture | Continuous approach |
|---|---|---|
| Royal Exchange | Lower court Y0; gallery terrace Y2 at Z−42…−18; central eight-step set; fountain at `(0,0,10)` | Side banks X−35…−11 and X11…35 climb from Z−4/Y0 to Z−18/Y2 |
| George Square | Main square Y4; civic forecourt Y6 at Z−128…−108; formal gardens and broad central stair set | X±22 streets climb Y2→4 between Z−42 and−56; outer civic banks climb Y4→6 between Z−96 and−108 |
| Central Station | Concourse Y2; platform and station walk Y5 under an enlarged arched canopy | X−94 approach climbs from Z32/Y2 to Z14/Y5; exit returns from Z−20/Y5 to Z−38/Y2; low concourse bypass at X−82 |
| Barras | Market floor Y0; warehouse loading terrace Y1.5 at Z−42…−18; loading stairs and sheltered recording court | Banks X54…76 and X108…130 climb from Z−6/Y0 to Z−18/Y1.5 |

`core_terrain.gd` constructs each terrain mesh and convex collision from the same four top corners. Bodies extend downward to form retaining foundations. Terrain tiles share the existing materials; the height registry describes the authored top surface. Stairs use individual horizontal patches with explicit rises. Decorative facade returns, cornices, rail supports, furniture and foliage remain separate from those skating surfaces.

The station platform has a **real four-metre opening**, Z−5…−1, between two Y5 decks. A safe Y2 concourse lies below. The mandatory career gap remains `central_gap`; a flat concourse route bypasses the jump. Curved fountain coping, gallery stair rails, civic stair rails, planter edges and the market loading rail provide optional combo links.

## Fountain contract

`Grind_Coping_ExchangeFountain` is a 64-segment closed sampled circle around `(0,0,10)`, radius **6.2 m**, with the board track at **Y0.92**. Its kind is `coping`. The reused MIT GrindLine helper receives those sampled points, so its existing tangent/travel logic follows the curve without a new movement engine. Reaching the curve's endpoint releases normally; it is not an unlimited auto-loop.

The stone basin is a solid cylinder, radius6.2 and topY0.55. The central pedestal has its own radius0.7, height2.7 collision cylinder. The rounded rim sits on the basin edge; the grind clearance is above the solid basin. The fountain is a safe civic feature, not a water-recovery trigger. The teaching rail `Grind_Rail_Exchange` retains its original `(12,0,9)` authoring position, length7.5 and Y0.92 board track for both novice use and stable controller regression fixtures.

## Street connections and outdoor ports

| Connection | Ground points / geometry |
|---|---|
| Exchange ↔ George | Two 14m streets at X±22, `(±22,2,−42)` ↔ `(±22,4,−56)` |
| Exchange ↔ Central south | `(−35,0,22)` ↔ `(−50,2,22)`, width14 |
| Exchange ↔ Central north | `(−35,2,−22)` ↔ `(−50,2,−22)`, width14 |
| Exchange ↔ Barras south | `(35,0,22)` ↔ `(50,0,22)`, width14 |
| Exchange ↔ Barras north | `(35,2,−22)` ↔ `(50,1.5,−22)`, width14 |
| Central/Barras ↔ civic back streets | X±88 climbs from Z−42 at Y2/Y1.5 to **Z−74/Y4**, then a flat corner turns through Z−80 toward X±35 |
| Central ↔ Clyde | `(−94,2,45)`, 16m clear approach |
| Barras ↔ Clyde | `(94,0,45)`, 16m clear approach; outdoor road reaches quayY2 at Z55 |
| Station ↔ Kelvingrove | `(−145,2,0)`, 16m core approach through the split station facade |
| Civic ↔ Kelvingrove | `(−42,6,−122)` joins the outdoor promenade toward `(−145,6,−125)` |

The north climbing roads end at the south edge of their Y4 corner pads. An earlier overlapping flat pad created a small upward lip; physical route checks found it and the join was corrected. Civic side facades are split around Z−80, and the station west facade is split around Z0, so architecture frames these streets rather than blocking them.

The outdoor module owns river water/recovery, a continuous bridge and the deliberate bridge jump, quay geometry, park landscape and its climbing loop. The old broad background paving plane was removed so it cannot cover the river. See [DESIGN-BRIEF](DESIGN-BRIEF.md) and the outdoor module for that separately authored geometry. Current route/collision test results take precedence over intermediate coordinate notes.

## Public interfaces

- `get_spawn_position() -> Vector3`: safe default spawn, including the initial0.8m settling allowance.
- `get_district_checkpoints() -> Dictionary`: six world positions at ground+0.8, keyed `royal_exchange`, `george_square`, `central_station`, `barras`, `clyde`, `kelvingrove`. The four career district IDs remain unchanged; outdoor exploration does not expand the saved four-district career requirement.
- `get_ground_height(world_position) -> float`: highest authored terrain support; returns `NAN` where no terrain support is authored. It excludes props, handrails and facade roofs. Tests independently raycast collision rather than trusting this registry as proof.
- `get_route_definitions() -> Array[Dictionary]`: each record has `id`, `label`, `points: PackedVector3Array` and `requires_jump`. Points are **world ground-contact positions**, with every grade seam/corner included. Jump routes deliberately include unsupported stretches; callers must not flatten them into continuous-floor assertions.
- `get_grind_lines() -> Array`: fresh world-space snapshots of core and outdoor rails/coping. Paths carry their authored rail/ledge/coping kind.
- `get_gap_definitions() -> Array[Dictionary]`: preserves `{id,name,start,end,radius,points,airborne_required}` and includes outdoor gaps. Gameplay remains owned by GapTracker/Main.
- `get_recovery_position(world_position) -> Vector3`: delegates outdoor hazards and returns a safe bank position or `Vector3.INF` when no recovery is needed. Main owns the actual bail/reposition operation.

The world adds `OutdoorRoutes` as a child, then calls `build(world, materials)`. Outdoor classification is checked before broad core X/Z district thresholds. Core height lookup delegates unsupported positions to the outdoor height query. Surface metadata continues to identify `stone` or `asphalt` for rolling audio.

## Authored core routes

| Route ID | Purpose | Jump required |
|---|---|---|
| `gallery_civic_ascent` | Default spawn → gallery bank → George approach → civic forecourt, total rise6m | No |
| `exchange_fountain_loop` | Broad lower-court circuit around fountain/optional ledges | No |
| `central_south_link`, `central_north_link` | Paired station streets | No |
| `barras_south_link`, `barras_north_link` | Paired market streets | No |
| `central_back_lane`, `barras_back_lane` | Climbing outer loop into civic back streets | No |
| `central_high_line` | Station bank → raised platform gap → descending bank | Yes |
| `central_high_line_bypass` | Open concourse beside the raised route | No |
| `market_loading_ascent` | East market bank → loading street → recording court | No |
| `gallery_step_drop`, `market_step_drop` | Optional architectural stair transfers | Yes |
| `station_park_port`, `civic_park_port` | Core sections of the two park links | No |

The live route API also includes six outdoor route definitions. These routes are navigation/test metadata, not scripts that move the player or grant tricks automatically.

## Career positions and gaps

| Preserved goal ID | New position |
|---|---|
| `H` | `(-22,2.9,-26)` |
| `A` | `(20,6.9,-116)` |
| `W` | `(-94,5.9,-12)` |
| `K` | `(94,.9,20)` |
| `S` | `(-60,4.9,-80)` |
| `market_1`, `market_2`, `market_3` | `(70,.9,22)`, `(106,.9,26)`, `(106,2.4,-26)` |
| `cone` | `(18,2.8,-22)` beside the original interactive statue, now on the gallery terrace |
| `secret_recording` | `(120,2.4,-33)` in the warehouse court |

Core gap triggers are Gallery Steps (`exchange_launch`), `(0,2.4,-13)`→`(0,.8,-5)`; Mind The Gap (`central_gap`), `(-94,5.4,0)`→`(-94,5.4,-6)`; and Market Loading Steps (`market_hop`), `(93,1.9,-15)`→`(93,.8,-7)`. They still require physical airborne travel and the existing ordered/swept crossing checks. Trigger locations alone do not award a gap.

## Evidence and remaining acceptance

Independent focused checks verified actual regional support heights, curved fountain capture/travel/release, physical uphill/downhill motion and all authored core route support/sweeps. The revised career circuit has completed all ten preserved goals with no bails/stalls; the exact final integrated counts and run metrics belong in [STATUS](../STATUS.md), [CAREER-ROUTES](../testing/CAREER-ROUTES.md) and the new topography report. Earlier flat-level route times and captures remain historical evidence, not acceptance of this layout.

Five intermediate rendered core views were inspected during implementation: default chase, gallery/fountain, civic terraces, station platforms and market loading street. They confirmed visible elevation, a connected fountain lip, stone banks and lifted station architecture. The final source-stable integrated capture set is produced by the separate level-capture runner after the outdoor and rider changes settle; its record belongs in the test report.

This is a substantive level redesign, not final realistic-art acceptance. Large procedural surfaces, repeated building bays and original composite frontage identities remain visible. The user still needs to judge route fun, landmark recognition, difficulty, rider/camera comfort and final presentation. Keep those gates open while independent implementation and regressions continue. No paid services, map-image textures, purchases or hosted jobs were used.
