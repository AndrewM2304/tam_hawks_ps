# Glasgow terrain and route redesign

**Direction:** owner-requested substantial redesign, 17 October 2026. **State:** authored contracts agreed; implementation/physical verification in progress. [ADR-007](../architecture/decisions/ADR-007-authored-glasgow-terrain-redesign.md) records authority and compatibility limits. These coordinates are game-authoring decisions, not surveyed Glasgow measurements. Latest runtime/evidence status belongs in STATUS and the eight redesign tickets in BACKLOG.

## The experience to build

The city should offer recognisable places and readable skating choices: push up a street, gain a view over a square, grind a fountain edge, carry a combo down a bank, choose a risky river transfer or a safe crossing, then climb a grassy park path and descend into another line. Elevation must change actual traversal and camera composition. A flat floor with decorative hills or randomly placed ramps does not meet this brief.

Each named area needs an identifiable landmark/silhouette, a coherent ground material and topography, at least one repeatable accessible loop and an optional technical line. Approaches should reveal takeoff, landing and a return route at normal chase-camera height. Streets, ledges, stairs/terraces, quay edges and park paths should create lines that belong to the place. Purpose-built skate elements can support those lines without replacing the place's architectural identity.

This is an original compressed composite. Preserve broad civic/gallery/station/market/river/park character; do not imply that the fountain, fictional bridge opening, terrace heights or northwest park route occupy these exact real locations. Real current shop identities, street relationships and detailed landmark proportions require inspected dated references under M03-006. Composite signs and design estimates must remain distinguishable from verified facts.

## Authored areas and elevation contract

Coordinates use +Y up and -Z north/forward. Heights below are intended skating surfaces; checkpoints use ground plus the player's 0.8 m reset clearance. Values are provisional until independent physical checks pass and may be corrected with the associated route tests and map data.

| Area / stable ID | Terrain and landmark identity | Intended line and return | Agreed authoring anchors |
|---|---|---|---|
| Royal Exchange / `royal_exchange` | Stone court and gallery setting; circular fountain creates a central route feature | Accessible outside loop, curved coping grind, gallery-bank ascent/descent; spawn faces a clear northbound approach with fountain to the right | Spawn **(-22, 0.8, 28)**; court Y=0; gallery terrace Y=2 for Z≤-18; side banks at X±23, Z -4→-18; fountain centre (0,0,10), coping radius 6.2 m, track Y=0.92 |
| George Square / `george_square` | Broad civic square and higher civic frontage, with skyline visible above lower streets | Climb from lower courts, choose civic bank/ledge line, descend through a second connection | Main floor Y=4; civic terrace Y=6 for Z≤-108; side banks X±26, Z -96→-108 |
| Central Station / `central_station` | Concourse, canopy, platform-height skating and street approaches | Ground route remains available; optional platform approach/ollie/landing retains the original career gap | Concourse Y=2; platforms Y=5; 4 m platform break Z -1…-5 near X=-94; preserve `central_gap` |
| Barras / `barras` | Market aisles, warehouse/venue edge and a loading street | Broad return around market clutter plus tighter stall/ledge line up to the loading edge | Market Y=0; loading street Y=1.5 for Z≤-18; banks near X=65/118, Z -6→-18 |
| Clyde Quays / `clyde` | Recognisable waterside space, quays and bridges; visible water below traversable edges | Optional bridge jump with a clear run-up/landing; uninterrupted alternate bridge and quay return; water miss recovers safely | Core ports **(-94,2,45)** and **(94,0,45)**; quays Y=2; water Y=-2, X[-150,150], Z[78,116]; jump bridge near X=35, 8 m opening Z94…102, north lip Y=3.2/south lip Y=2.8; continuous 8 m-wide alternate bridge near X=-98 |
| Kelvingrove-inspired park / `kelvingrove` | Hilly grass, trees and a deliberately visible winding paved path; distinct from a flat civic court | Supported uphill/downhill S-loop, terrace coping and two connections; grass changes silhouette/topography, not merely ground colour | Main riding area X[-220,-140], Z[-185,-75]; path climbs Y=6→17; surrounding woodland extends to X[-255,-140], Z[-225,-60]; Central-side port **(-145,2,0)**; civic port **(-42,6,-122)** toward **(-145,6,-125)** |

All six regions are visible in navigation. The original four remain the career district collection. The two new areas are optional exploration space; neither changes the ten-goal count, required district total or existing save completion. No loading transition may interrupt a running combo between areas.

## Route criteria

1. **Connected ground:** authored collision and visible surfaces agree at terrace/bank/bridge/path joins. `get_ground_height(world_position)` returns the supported surface height, or NaN when there is no supported ground. Do not bridge unsupported space with a convenient flat fallback. Check upward and downward traversal with the real player body, not only ray hits.
2. **Readable elevation:** every mandatory rise has a rideable approach and a safe return. Place optional technical drops/jumps beside a continuous ground route. Stair decoration does not substitute for a ramp that the controller can climb; small surface seams must not snag the capsule.
3. **Useful line length:** a beginner can repeat a local push/ollie/landing loop. A more practiced player can link at least three transitions using air, manual or grind without an artificial forced stop. Verify the actual score continuation and landing window; a drawn route line is not evidence of a valid combo.
4. **Fountain:** a 64-segment closed authored coping path `Grind_Coping_ExchangeFountain` follows the visible 6.2 m rim at Y=0.92. A physical push→ollie→descending tangent approach acquires it; travel follows changing tangents, exits cleanly and resolves the combo once. Verify obstruction, balance failure, both intended travel directions and the closure seam. Fountain water/decoration must not hide an invisible obstruction.
5. **Clyde transfer:** `clyde_bridge_transfer` describes the optional ordered airborne crossing. Prove actual takeoff, all 8 m of the opening, supported landing and one gap award. The trigger centres are 12 m apart, bracketing the 8 m missing deck; those are different measurements. A missed jump/water entry drops only the active combo, emits one bail and returns the rider to supported ground while preserving banked score. A continuous alternate bridge makes exploration possible without the advanced jump.
6. **Park:** uphill speed and downhill exit remain controllable on the paved S-loop. Test actual travel over every seam and back to both connection ports with no unintended stall/bail. Grass slopes need believable terrain silhouettes and contact if skateable; where scenery is inaccessible, its boundary must read clearly. Foliage must not conceal the path or camera.
7. **Return and recovery:** a player who misses a line can recover without an invisible trap or forced full-run reset. World hazard data distinguishes water/out-of-bounds recovery from ordinary unsupported airtime. A valid safe position is a Vector3; infinity means no special recovery. Main owns the one-time bail/score handling.
8. **Camera and frame cost:** inspect at the production chase camera's normal FOV/distance, approaching uphill and downhill, under the station canopy, beside the fountain and at both bridge lips. Capture ordinary and shaded views. Measure after the geometry settles; the prior four-view benchmark cannot establish cost for six redesigned areas.

## Runtime data and ownership

| Owner | Authoritative responsibilities | Consumers / checks |
|---|---|---|
| A05 core world (`rail_world`) | Four career districts, terraces, graded streets, spawn/markers, fountain, integration of the outdoor module; world ground/route/checkpoint/recovery queries | Controller/main, route map, A09 physical tests, captured views |
| A05 outdoors (`art_direction`) | `build(world, materials)` for Clyde/park; region classification, supported-height/recovery queries, grind/gap definitions, six-area integration ports | Core world's merged public query results; independent crossing/climb tests |
| A05/A04 rider (`physics_references`) | Adult anatomical assets, clothing/rig/pose presentation; preserve board/collision/movement contracts | Action tests, close/chase/motion captures and provenance review |
| A01/A08 integration | Hazard bail/recovery, stable career/save wiring, map page and final shared interfaces | Real input/menu tests, migration/goal regressions and map fixtures |
| A09 quality | Independent collision/real-motion/routes/career verification and explicit limitations | Recorded pass/fail evidence tied to final source |

Route records are `{id, label, points: PackedVector3Array, requires_jump}` with **ordered world-space ground points**. Core and outdoor sources both return that point type; the final shared interface document remains authoritative. Checkpoints retain the four original keys and add `clyde` and `kelvingrove`. Outdoor display labels are **CLYDE QUAYS** and **KELVINGROVE PARK**. Outdoor grind IDs are `clyde_quay_coping`, `clyde_bridge_rail`, `kelvingrove_terrace_coping` and `kelvingrove_s_bend`; final source must agree with the recorded tests. More detailed implementation coordinates and caveats are in [GLASGOW-ROUTES](GLASGOW-ROUTES.md) and [OUTDOOR-ROUTES](OUTDOOR-ROUTES.md).

**CITY MAP & ROUTES** is reached from pause and goals using existing menu controls. It draws actual route/checkpoint data, current rider position and heading, elevation distinctions and readable jump links. Region labels must fit; colour alone must not distinguish a jump from a safe path. Opening/closing the page preserves pause state, focus and navigation history. Capture the real production page using its readiness check; a successful PNG write alone does not establish a visible map.

## Career and save invariants

The goal IDs remain `first_shift`, `good_shift`, `some_shift`, `one_long_line`, `letters`, `cone`, `platform_change`, `market_sweep`, `across_toon` and `lost_recording`. Preserve score thresholds 1,000/5,000/15,000 and 3,000 combo pending actual balance evidence. Preserve H/A/W/K/S, `market_1`–`market_3`, interaction `cone`, gap `central_gap`, collectible `secret_recording`, the four original career district IDs and all earned cosmetic/special unlock IDs. Save schema remains version 1; future/corrupt-save protection remains intact.

Marker positions can move onto the authored terrain. A09 must complete all ten original goals through a real physical career circuit within 120 seconds, with profile writes disabled. Check the six-area exploration circuit separately; the extra areas must not silently turn the career into a six-checkpoint requirement. Free skate remains unable to complete career goals or records. New gap scoring follows the existing once-per-valid-traversal/rearm/bail rules.

## Adult skater direction

The rider should read as an adult through anatomy and movement, not just a taller version of the previous cartoon head. Current targets are approximately **1.75 m standing height, 0.25 m head height and 0.44 m shoulder width**, tapered wrists and ordinary skate footwear. Use restrained slate/denim/leather colour and natural clothing volume, an anatomical face and fingers, and avoid an oversized hat or mitten hands. These are modeling targets pending inspection at real gameplay scale.

The current direction is a source/licence-verified CC0 anatomical mesh adapted to original clothing and the existing ten-bone native clothing rig; exact source/revision/attribution belongs in the asset register before distribution. Preserve board origin, gameplay collision, timing, grounded foot/deck contact and deliberate trick separation. Check front/profile/full-body/head views and actual input-driven coast/push/brake/ollie/flip/grab/grind/manual/revert/special/landing/bail transitions at normal and slow speed. Keep final adult realism, motion weight and owner visual acceptance open until reviewed.

## Evidence and resumption

M03-008–M03-012, M05-006, M06-008 and M07-006 carry owners, priorities, dependencies, acceptance and verification in BACKLOG. Before claiming this redesign integrated, record clean import/aggregate counts, independent new physical routes and ten-goal completion, real chase/overview/map images, adult action evidence, resource/licence checks and a source-bound performance comparison.

After the ordinary setup/import succeeds and source changes settle, reproduce the terrain/map images on this Linux image with:

```bash
./tools/level_design_capture.sh --private-display
```

On a normal Mac desktop with the pinned free engine installed:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/level_design_capture.sh
```

The runner requests Compatibility rendering at an explicitly verified 1280×800 window/content canvas. It samples the real six checkpoint/route/gap definitions and settles positioned riders with production physics. Seven chase views, two clearly identified authored overview cameras and the actual ready map page are rendered with `force_draw`; automatic rendering is disabled between fixture steps to avoid wasting software-render time. These are static inspection fixtures, not route completion or FPS evidence. Profile writes are disabled before main enters the tree; the map is opened through `show_map()` and checked before/after `frame_post_draw`.

Images first go to a unique ignored `.local/level-design-*` directory. A bounded wrapper rejects engine errors, incomplete captures or any game/asset source changes during the run before publishing ten PNGs and a manifest under `docs/testing/screenshots/level-redesign/`. The manifest records exact engine/renderer, settings, source fingerprints, camera/player transforms, route data, image hashes and fixture limits. The wrapper owns/stops its game process and private display; it installs nothing and has no network or paid-service dependency. At this writing the new script parses and rejects headless correctly; combined rendering awaits all source owners' release.

The 778-check suite and earlier career/performance/capture artifacts belong to the previous cleanup and remain historical. New code is in progress. Current-reference access, physical DualSense/target-Mac tests, human route enjoyment/listening and final visual acceptance remain unresolved evidence gates. Continue independent authorized implementation; if credits/session time end, preserve the current source, exact failing route/action, reproduction command and next edit in STATUS/ACTIVE_WORK rather than marking work complete.
