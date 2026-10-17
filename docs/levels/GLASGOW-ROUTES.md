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

`core_terrain.gd` constructs rectangular terrain meshes and convex collision from the same four top corners. Angled Merchant Close patches triangulate the top polygon and give each displayed triangle an identical convex retaining prism, preserving graded turns without a filled rectangular annex. Bodies extend downward to form retaining foundations. Terrain tiles share the existing materials; the height registry describes the authored top surface. Stairs use individual horizontal patches with explicit rises. Decorative facade returns, cornices, rail supports, furniture and foliage remain separate from those skating surfaces.

The station upper walk and both platform decks are suspended slabs with tops at Y5 and undersides at Y4.6. Their lower concourse remains at Y2, so the low service close passes underneath with 2.6m clearance. The western canopy column was moved from Z−10 to Z−17 to frame that entrance. The station platform has a **real four-metre opening**, Z−5…−1, between two Y5 decks. A safe Y2 concourse lies below. The mandatory career gap remains `central_gap`; a flat concourse route bypasses the jump. Curved fountain coping, gallery stair rails, civic stair rails, planter edges and the market loading rail provide optional combo links.

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
- `get_support_height(world_position, max_step_up=1.0) -> float`: highest authored support no more than `max_step_up` above the supplied Y. This deliberately distinguishes the Y2 station undercroft from its Y5 overhead deck. `get_ground_height` retains its highest-surface behavior for existing art consumers. Both are terrain queries, not proof of collision or headroom.
- `get_encounter_definitions() -> Array[Dictionary]`: authored social challenge anchors. `busker_big_finish` is at `(28,0,31)`, heading0.93 radians; the encounter owns the visible actor while the world retains the existing NPC audio position.
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
| `station_low_level_close` | A diagonal concourse entry into the low passage beneath two raised station routes | No |
| `merchant_close_cutthrough` | An angled, framed close through the station/civic space | No |
| `merchant_service_east_return`, `merchant_service_west_return` | Two exits from the lower service court to the station concourse / climbing lane | No |

The live route API also includes the outdoor route definitions, including the park cutback and print-yard loop/curved-bank branch. These routes are navigation/test metadata, not scripts that move the player or grant tricks automatically.

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


## Nonlinear place-design slice

Following the senior level-design review, four local loops add distinct route choices without changing the original ten career/save IDs. These are original spatial arrangements inspired by the broad design principles of classic skating games; no commercial level layout is reproduced.

- **Station undercroft:** `station_low_level_close` follows `(-126,2,0) → (-126,2,-8) → (-114,2,-8) → (-103,2,-8) → (-82,2,-8) → (-82,2,22)`. This passes beneath the suspended service walk and north platform, reconnecting the park-side entrance with the open concourse. It is a genuine overlapping high/low choice, rather than a painted shortcut across a solid block. The top platform transfer and safe lower route remain available.
- **Merchant Close:** `merchant_close_cutthrough` follows `(-64,2,-30) → (-68,2,-44) → (-69,2.5,-50) → (-61,3.2,-60) → (-55,3.5,-65) → (-59,4,-74) → (-59,4,-80)`. Its eight-metre angled retained street, small triangular side pocket, optional angled ledge and two solid building islands connect the station north street to the civic backstreet. The approach doglegs around architecture; it occupies previously empty negative space. The mouth stays at Y2 until it clears the original station floor, preserving the east/west concourse crossing without a new curb. The broad existing career paths stay accessible.
- **Kelvingrove cutback:** a second western hillside branch rejoins the Central approach, allowing a hill climb, different downhill route and return to the city without retracing the ascent. A shared level fork apron prevents the two graded strips from producing an overlapping curb. See OUTDOOR-ROUTES.
- **Clyde print yard:** the broken bridge landing now connects to an angled pocket loop around a small planted/seating island, returning to the south quay. An optional radius 4m, 35° curved masonry bank and rounded corner hip climb only 0.723m onto that island; the continuous outer route remains available. This is a low curved bank supported by the present controller, not a near-vertical quarter-pipe or a new lip/wallride mechanic.

The first independent static route pass after all additions was **151 passed, 0 failed** (`.local/geometry-routes.log`): actual floor heights and capsule sweeps in both directions, not metadata inspection alone. That local probe is ignored/reproducible through the main world-route suite. Independent focused follow-up passed **24/0 nonlinear/outdoor checks** and **13/0 unchanged career-route checks**. Both directions of the new branches had no stalls or bails; downward/upward rays independently proved station floorY2, undersideY4.6 and deckY5. All ten original goals completed at 75.20 s and returned at 88.00 s with no bails/stalls. The driver directly aims supported heading, so this is feasibility evidence rather than human timing/fun. Final aggregate, rendered review and remaining human acceptance are recorded by QE/STATUS; these checks do not certify camera comfort or final art.


The close now sits above a bounded **Y1 lower service court**, X−94…−34,Z−86…−30, with masonry retaining foundations. Existing Y2–4 road/terrace surfaces remain above it. It fills the formerly exposed backdrop beneath the street islands and is playable ground, rather than a decorative false floor. Two independently published exits avoid trapping a rider who drops into either side: `merchant_service_east_return` follows `(-56,1,-56) → (-59,1,-54) → (-59,2,-42) → (-59,2,-34)`; `merchant_service_west_return` follows `(-72,1,-70) → (-74,1,-70) → (-82,3.75,-70) → (-88,3.75,-70)`. Both are continuous banks with no required jump. Local HUD names distinguish Merchant Close/service court and the station low close/concourse/high line while canonical career district IDs remain unchanged.

After the lower-court/rendered integration corrections, the focused static world-route result is **157 passed, 0 failed**. The refreshed 21-frame source-stable capture set replaces the earlier void/fork-edge/paving views; Fresh independent physical checks passed **30/0** after these corrections: both return banks escape/descend with real non-flat floor contact, no stalls or bails (east 1↔2m, 2.25s each direction; west 1↔3.75m, 1.88/1.80s). Existing nonlinear branches still pass in both directions; final aggregate verification is owned by root. Final published evidence in STATUS takes precedence over these intermediate checks.


The refreshed 21-view set has `valid_capture_set=true`, `source_changed_during_run=false` and `source_stable_capture_set=true`. Geometry review inspected both Merchant mouths, the lower station passage, the park fork/join and both yard-bank views. It confirms the lower service ground, clear branch opening and blended join foundation. The independent lead reviewer accepts this as a substantial topology development iteration. Four broad core courts, repeated/sparse facades, detailed landscaping, human camera/fun and final realistic-art acceptance remain open. The small grass wedge inside the print-yard loop should receive a defined planting edge or paved apron during that art pass; it does not block traversal or reopen the frozen slice.


## Civic workshop and market-hall edge pass

This bounded M06-007/M05-001 iteration reshapes two existing courts, preserving the established career and nonlinear routes. It adds no detached district, changes no career/save IDs and requires no new movement engine. The signs/buildings are original Glasgow-inspired composites, not verified current occupants.

**George Square** replaces the rectangular garden pair with chamfered planted wings around X±13/Z−84, topY4.55, a shallow irregular paving apron atY4.01 and a raised workshop backdrop atY4.65, Z−94…−99. Diagonal side banks match the existing civic bank's toe heights beyond Z−96, so the terrace connects to the existing square rather than floating above it. The protected X±22 civic lines and Z−74 cross-court route remain open. `civic_workshop_bank_loop` runs from `(-22,4,-95.5)` through `(-19.625,4,-95.5)`, `(-15.625,4.65,-95.5)`, `(-10,4.65,-94.5)`, `(10,4.65,-94.5)`, `(15.625,4.65,-95.5)`, `(19.625,4,-95.5)` and `(22,4,-95.5)`. The original `Grind_Ledge_Civic` ID now follows the west garden's actual angled edge.

The workshop encounter anchor is **`(0,4.65,-98)`**, heading PI, on real raised ground. Its three separately authored coping segments are:

| ID / steady marker | World board-contact endpoints | Physical context |
|---|---|---|
| `Grind_Cat_A` / A | `(-16,4.60,-91) → (-10,4.60,-91)` | Independent 6m low plinth, quiet teal start accent |
| `Grind_Cat_B` / B | `(-4,4.60,-91) → (2,4.60,-91)` | Independent 6m low plinth, copper start accent |
| `Grind_Cat_C` / C | `(8,4.60,-91) → (14,4.60,-91)` | Independent 6m low plinth, cream start accent |

The ordinary support beneath the course stays atY4/4.01. Plinth tops areY4.45; coping board tracks areY4.60. Billboard A/B/C labels face the eastbound chase camera without flashing or relying on colour alone. Each 6m space between plinths permits grounded landing and a separate re-approach; it is not a promise of an automatic transfer at every speed. Ordinary push caps at 15m/s, whereas the existing grind state permits 18m/s and has a 0.35s recapture cooldown. The encounter allows separate combos and requires actual distinct ordered captures plus a final clean bank; geometry does not grant any challenge progress.

`cat_coping_approach` follows `(-28,4,-91) → (-22,4,-91) → (-18,4,-91)`; `cat_coping_runout` follows `(16,4,-91) → (22,4,-91) → (22,4,-74)`. `cat_ordered_coping_line` publishes the approach, actual elevated track points, intermediate landing spaces and runout with `requires_jump=true`. `cat_workshop_bypass` follows the permanent ordinary-floor route along X−22→Z−74→X22, so neither the encounter nor missed captures block district travel. Cat actors/stage props stay behind Z−96 and do not add riding collision.

**The Barras** gains a brick Market Repair Hall attached to a chamfered masonry loading/seating skirt inside X50…76/Z−2…17. The skirt rises 0.65m with an east bank and an angled corner return to the market floor. `Grind_Ledge_MarketHall` follows the actual outer skirt edge atY0.77. The aisle X80…88, career Z18…28, central stair runout X86…101 and outer X126 route remain clear. The former stall at `(67,0,10)` moves to `(105,0,-2)`; all four stall objects and market goal positions remain intact. `market_hall_bank_loop` follows `(82,0,8) → (80,0,8) → (76,0.65,8) → (68,0.65,8) → (67,0.65,13) → (69,0.65,17) → (73,0,17) → (78,0,17) → (82,0,8)`.

The focused static production-route pass is **173/0**, with a clean Godot 4.6.3 import. Independent changed-court physical checks pass **15/0**: cat approach/runout/bypass travel works in both directions; the civic workshop loop takes 3.70s each direction and the market hall loop 3.48/3.45s, with real slope contact, >0.6m height change and zero stalls/bails. The actual ordered A→B→C rail/ollie route also produces one real 1,050-point bank. This driver directly aims supported heading, so these are feasibility results, not human timing/fun. Fresh complete career/aggregate verification and real rendered court/actor review are required before replacing the prior source-bound package. Final counts and accepted capture identity belong in STATUS/QE; earlier 955/0 and older imagery do not certify this pass.


The first court render revealed inward-facing retaining side triangles on some chamfered/mirrored polygons. `core_terrain.add_polygon` now chooses outward side winding from the footprint direction while retaining its original top triangulation and collision prisms. An actual representative side-normal probe changes outward-dot from −0.961 to +0.961; a control-world comparison verifies identical 247 collision shapes/transforms, 74 rectangular patches and 18 polygon registries before/after this visual correction. Static routes remain 173/0. Final rendered review must inspect these restored foundations, rather than infer appearance from collision checks.


The corrected court/cat capture completed **34/34**, with 34 authored routes and 102 unchanged source inputs at 16:18:46 UTC on 17 October 2026. Manifest SHA-256: `9ba441c01c7dd24e2e5dd52505eb8314346720327bc7224ff81c6f3906c377e9`. Actual garden/terrace retaining walls are visibly closed/lit in frames 22/25/26, and the supported Barras return in 24 shows the rider clear of the old stall. Geometry review finds no further concrete blocker in this bounded slice. The initial stall-intersecting fixture was corrected without altering gameplay geometry. Broader court shaping, sparse/repeated facades, horizon/landscape materials, human route choice/camera comfort and final realistic-art acceptance remain open under the existing tasks. Source is frozen for the root-owned aggregate/export checks.
