# The Glasgow level

This is a fictional arrangement of Glasgow-inspired districts, not a geographical reconstruction. Every asset and traversable layout is original. No scraped map, photograph, logo or commercial game layout is bundled.

## District plan

| District | Visual identity | Skating opportunities | Objective / secret hooks |
|---|---|---|---|
| George Square | Civic stone silhouettes, broad square, planters, statue and cone | Open learning loop, low ledges, approachable ramps, intersecting lines | Intro score runs, tokens, cone event |
| Royal Exchange Square | Gallery-inspired central form, columns, dense paving court | Circular ledge route, precision gaps, arcade passage | Combo route and discreet side-area entrance |
| Central Station surroundings | Original arched canopy and railway architecture silhouettes | Longer approaches, bank-to-rail links, elevated line with safe exits | Platform route gap and checkpoint |
| Barras / Barrowlands | Market stalls, warehouse fronts, original bright venue sign | Tight technical turns, stall gaps, roof-adjacent transfer | Market collectibles and lost recording |

Connections use fictional compressed streets. Provide at least two ways into each district and avoid a single corridor that prevents combo flow. Loading transitions cannot interrupt a running combo.

## Route acceptance

Author a traversal route from spawn through all four district checkpoints back to spawn, at least one beginner repeatable loop per district, and at least three combo links across district boundaries. A09 records route time, stalls, unintended collisions, camera occlusion and recovery. Check both travel directions where the route is intended to be bidirectional.

Use explicit collision geometry for skateable ramps, ground and rails. Decoration must not create tiny snagging surfaces. Hazard boundaries recover the player; optional hidden areas must have a reliable way out. Root transforms and scale changes cannot silently alter trick physics.

## Secrets and interactions

M03 reserves a hidden interior/court, a route shortcut, a reachable secret recording location and the cone event geometry. M04 connects mission events and persistence. An object looking like a collectible does not count as a functioning objective.

## Current prototype scope

The M01 square uses procedural blockout meshes, ramps, boundary walls, signs and a statue silhouette. It is a compact controller test scene. Follow `docs/STATUS.md` for its actual render and collision evidence. The full district plan remains M03 work even if the prototype displays familiar district names.

## Reference workflow

A05 may consult public architectural facts and owned/licensed references for proportions and atmosphere. Record each actual imported asset and its licence in `docs/licences/REGISTER.md`. External images are reference-only unless explicit redistribution permission is established. Do not download asset packs just because they are labelled free.

## Implemented square geometry

`game/levels/glasgow_square.gd` generates an original civic skating court: sandstone tenements, slate rooftops, teal shop fronts, a clock tower silhouette and a cone-topped statue named **The Provost of Push**. The statue is an original standing skater, not a reproduction of a real monument. Procedural meshes, colours and signs require no downloaded assets.

Coordinates are metres, +Y up; spawn is `(0, 0.8, 12)` facing -Z. The 70 × 84 m collision floor is at Y=0. Perimeter walls have inside faces at X±34, Z±41. Mesh overlays and paving joints are visual only. All four ramps use convex wedge collision and inclines below 15°. Rails currently use ordinary solid collision; grinding is reserved for M02.

| Route | Start / direction | Obstacle | Landing space |
| --- | --- | --- | --- |
| Central launch | Spawn, straight toward -Z | Width 7 m, Z=-4 to -12, rise 1.6 m; 11.2° | Clear center lane through Z=-28 |
| Tenement return | X=-17, Z=-23, toward +Z | Width 6 m, Z=-14.5 to -7.5, rise 1.35 m | Clear return toward Z=18 |
| North bank | X=-5, Z=-23, toward -Z | Width 9 m, Z=-29.5 to -36.5, rise 1.8 m | Short 4.5 m apron before boundary; turn or brake after landing |
| Warm-up bank | X=7, Z=24, toward +X | Width 6 m, X=12.5 to 19.5, rise 1.1 m | 14.5 m to east boundary |

Low ledges are 0.48–0.56 m tall. Central monument collision remains at X=11.5–16.5, Z=-17.5–-12.5, clear of the main skating line. The statue and distant skyline are visual ornaments above solid plinth/building collision. `get_location_name(position)` exposes five descriptive areas for HUD feedback; these are prototype labels within one square, not the four completed release districts. `skateable_ramps` identifies all wedge bodies, with rise/run/width metadata for inspection.

## Rendering and collision evidence

The Compatibility renderer uses shared rough materials, linear tonemapping and one directional sun with shadows limited to 75 m. There are no local light shadows, screen-space effects, downloaded textures or external services. Facade windows currently use individual mesh instances; consider MultiMesh batching after profiling establishes a need.

Independent QE passed supporting colliders and gentle normals for all four ramps, actual player traversal/landing on the central and return ramps, and all four boundary walls. A software OpenGL frame was captured at `.local/prototype.png` using `tools/capture.sh` (originally an equivalent manually started Xorg display). This verified visible original geometry and informed a fix for overexposed lighting; it does not establish physical controller feel or Apple Silicon performance. See `docs/STATUS.md` for final aggregate validation.

The cone remains static decoration. Future districts, grind paths, shortcuts, art replacements and cone interaction remain distinct roadmap work.
