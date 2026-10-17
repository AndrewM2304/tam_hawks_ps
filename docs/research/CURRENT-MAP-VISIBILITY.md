# Current-map visibility, camera and loading

17 October 2026. Owner-requested research for the active performance pass. Scope is the existing map, Godot 4.6.3 Compatibility and the owner's Mac; no new areas, paid tools or renderer replacement. Read [PERFORMANCE-NEXT](../planning/PERFORMANCE-NEXT.md), [render review](RENDER-EFFICIENCY-REVIEW.md), [static batches](../testing/STATIC-BATCHES.md) and [camera measurements](../testing/CLASSIC-CAMERA-TURNS.md). This is a source/design review; it runs no graphics job and claims no new frame-time result.

## Does rendering or loading less explain classic skating performance?

**Reducing invisible rendering is directly useful. Loading less is a different decision.** Godot already rejects bounds outside the camera frustum. Objects inside that frustum but behind a building can still require submission/geometry work unless occlusion rejects them. Resident meshes/textures, animation/script work and collision remain present even when a visual is culled. Culling reduces rendering; resource unloading reduces residency; suspending simulation reduces CPU work. They must be measured independently.

The inspected THPS manuals and community level guides establish controls, corridors, plazas and branching routes. They do not establish the proprietary engine's streaming, visibility cells, polygon budgets or camera implementation. No original-game engine source or developer performance talk was obtained in this review, so we do not claim a particular classic game loaded one district at a time. It is reasonable design inference that enclosing streets and building masses offer more visibility-control opportunities than an exposed map; Godot's documented culling model supports using that property here.

An actually inspected **open-source comparison**, [Not Pro Skater's pinned README](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/readme.md), describes merging static geometry by bake group, retaining imported LODs and using baked Blender lightmaps. That shows a reusable production approach, not evidence of Neversoft's internals or measured performance in our game. Our current map need not acquire a streaming system before using batching, culling and better near assets.

## Current implementation and what each part saves

The integration currently uses **64 m compatible opaque static batches**. It also builds **23 inset closed-wall occluder candidates**, but native occlusion is **disabled**: exact off/on/off-repeat captures exposed missing distant opaque wall planes. Protecting occluder-owner meshes repaired most of one view but did not restore parity; contained boxes and reduced counters were insufficient. `GraphicsQuality` chooses the following budgets. Exact final acceptance and runtime identity belong in STATUS.

| Current setting | Performance | Balanced | High |
|---|---:|---:|---:|
| 3D render scale | 0.75 | 1.0 | 1.0 |
| Camera far plane | 150 m | 220 m | 220 m |
| Directional shadow distance | 30 m | 45 m | 75 m |
| MSAA | Disabled | 2× | 2× |

The native UI remains separate from 3D render scale. Scaling both 3D dimensions to 0.75 uses **56.25% of native 3D pixels** before any implementation overhead; that is a pixel-count calculation, not a 43.75% frame-time guarantee. All current gameplay/collision stays live. Native 60 Hz rider interpolation and an interpolated chase can make displayed motion smoother between ticks; they do not increase physics frequency or replace the need to hit the frame budget.

| Mechanism / inspected Godot 4.6 constraint | Consequence for this map |
|---|---|
| **Frustum culling** excludes whole visual bounds outside the camera view. Lowering far range helps only where bounds leave the frustum. Offscreen geometry can still be needed in a visible shadow pass. | Keep skyline/route mouths visible; measure far-plane and shadow changes separately. An already-hidden wall cannot be made cheaper repeatedly by shrinking the range. |
| **MultiMesh** is one spatial visibility object. Its instances are not individually culled, and the whole AABB must be occluded to reject it. Correct custom bounds must enclose every rendered instance. | Spatially group repeated static decor while preserving material/state compatibility. A city-wide material batch can remain visible because one small corner is visible; a batch per window can overwhelm draws. The chosen 64 m cell is a measured tradeoff, not a rule for every asset. Never shrink bounds to hide legitimate geometry. |
| **Occlusion** rasterizes simplified occluders on the CPU, then tests occludee AABBs. It adds work and benefits enclosed streets more than open water/park vistas. Automatic occluder baking ignores MultiMesh, though MultiMesh can be an occludee. | Explicit solid-wall boxes are appropriate. Do not close station canopies, Barras aisles, gallery porticos, doorways or bridge arches with an occluder. Verify off/on/off-repeat frames, high/low views and rapid turns; fewer counters alone cannot establish correct visibility. |
| **Shadow range** controls a separate workload. More distance includes more casters and reduces detail per covered area. | The 30/45/75 m choices already offer a useful tradeoff. Detailed buildings beyond the shadow range should use restrained baked/contact detail rather than extra far dynamic lights. Check nearby skater/board shadows and fast-motion fading. |
| **Near plane** affects depth precision across the entire view. Lower near values increase Z-fighting risk. | The production camera now uses **0.20 m near**, with a protected clear camera arm. Keep that improvement. A closer chase is a camera-position choice, not a reason to lower near to 0.01 m. Coplanar facade geometry still needs fixing rather than being hidden by a precision setting. |
| **Visibility ranges/HLOD** can replace fine detail with simpler meshes. In 4.6, `FADE_SELF` and `FADE_DEPENDENCIES` are **Forward+ only**; on Compatibility they act as disabled fade **without hysteresis**. | Use `VISIBILITY_RANGE_FADE_DISABLED` with begin/end margins for actual hysteresis. Avoid assuming a smooth alpha transition works on our renderer. Separate fine decor from structural trim before assigning ranges; mixed material batches are unsuitable for indiscriminate cutoffs. |
| **Imported mesh LOD** reduces triangles according to screen size; batching reduces submissions. They address different bottlenecks. Automatic identical MeshInstance instancing is Forward+ only. | Keep explicit native batching on Compatibility, and add imported GLB LODs to the next foreground asset proof. Sharing a mesh resource alone does not merge its draws. A different file extension alone does not improve fidelity or submission cost. |

## Would a narrower or closer camera help?

**A small camera comparison is worthwhile; it is not the main optimization.** Current chase settles at 66° vertical FOV, rising to 69.75° at 15 m/s; nominal rear distance is 5.8→6.325 m, normal height 2.7 m. With Godot's default keep-height mode, vertical FOV is not horizontal FOV: the visible horizontal angle also depends on aspect ratio. A 66° vertical view is already broad on a widescreen display.

A narrower view can cull extra side geometry and reduce exposed distant scenery. It retains the same output pixel count, makes surviving objects larger, and can select higher mesh LODs; a draw-limited view may improve while a pixel-limited view does not. Moving the camera closer changes projection/framing and foreground occlusion, but does not unload the world or automatically shorten the 150/220 m far plane. It can reduce landing-space awareness, hide a rail entry and enlarge expensive close materials. Camera collision alternatives and reverse travel must still work.

Keep the present camera as baseline. Compare **66° fixed**, **62° fixed** and the existing **66→69.75° dynamic** FOV with the same far plane, resolution, quality and actual route. If a closer variant is wanted, change only rear distance from 5.8 to **5.3 m** in a separate comparison; retain the 0.25 m sphere, minimum useful arm, body visibility checks and reverse hysteresis. These are proposed comparison values, not installed changes. Record draws, primitives, process/physics intervals, frame percentiles and visible next landing/rail. Review fountain circles, market approaches, station undercroft, quay jumps, park descents and a reverse bank. A faster frame that obscures the next move is not a useful skate camera.

## Next actions on the existing map

1. **Finish the active measured pass first.** Preserve 64 m batching's complete authored/live records and unchanged physics; keep the rejected 23-occluder native-culling experiment disabled until remaining missing geometry is identified and exact matched frames restore parity. Keep the current source's ordinary checks, normal chase/settings captures and moving-route evidence together. Do not select a camera or culling policy from screenshots taken at different source/settings.
2. **Tag secondary visual detail explicitly.** Pilot close-only stall books/clothing, tiny facade mouldings and interior dressing on one existing block. Start with a proposed 30–45 m detail range and 5 m hysteresis; retain full storefront, landmark/sign, coping and passage silhouettes. Use simpler farther meshes where an abrupt disappearance would be noticeable. Confirm low/high chase views and both directions before extending it to other blocks.
3. **Spend recovered budget near the rider.** Continue the connected clothed hero and one existing facade/GLB/PBR/LOD proof. Bake high-poly detail into normal/roughness maps where silhouette does not need geometry. Keep simple collision and rail paths independent; count material surfaces/shadow submissions alongside triangles. More invisible polygons do not improve the visible game.
4. **Use measured causes to choose the next tool.** High main-thread rendering/submission time suggests fewer surfaces/batches; high shading/GPU time suggests scale, materials and shadows; long first-use spikes suggest resource/upload/warmup investigation; periodic CPU spikes suggest HUD/actor/query work. Occlusion, FOV and streaming cannot substitute for one another.
5. **Consider streaming only for a demonstrated residency/startup problem.** Current procedural world construction creates the whole map up front. First time scene construction/import and first use must be measured separately from steady movement. Authoring reusable static content as imported scenes can reduce construction complexity before introducing district lifetime changes.

If future imported scenery exceeds the memory/startup budget, prefetch **visual-only** chunks around the player's reachable region, with overlap and time to turn back. At 15 m/s, even two seconds of lead time is 30 m, before accounting for a jump/camera vista. Keep collision, rail identity, goals, encounter timers and save state independent of visual residency. Unloading because the camera looks away would create popping on a fast turn and could break gameplay if simulation shared that lifetime.

Godot's `ResourceLoader.load_threaded_request()` can load resources in the background; poll `load_threaded_get_status()` before retrieval. Calling `load_threaded_get()` too soon blocks. Background resource loading does not prove that scene instantiation, `add_child`, procedural `_ready` work or first GPU uploads are spike-free. Stage those operations and measure them; no asynchronous streaming is currently implemented by the culling work.

## Target-Mac diagnostic

Use the owner's normal Mac desktop and free installed Godot 4.6.3. Prepare imports outside measurement, record Mac model/chip/RAM/macOS, source commit, renderer, actual render resolution, quality and thermal/power conditions. Run the source-stable stationary diagnostic, then the existing normal-render moving diagnostic:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/profile.sh --duration 60 --resolution 1920x1080
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/moving_profile.sh --duration 120 --resolution 1920x1080
```

The moving runner currently uses three actual-input quay/market/park loops; it is not a whole-city human playtest. It records render intervals, simulation progress, route deviation, bails and source hashes, and rejects insufficient motion. Then play a separate ten-minute keyboard/DualSense route through every existing area, with quick 180° turns, grinds, transition airs, dense shop views and pause/settings changes. Compare p50/p95/p99/max against **16.67 ms** for 60 fps, and count frames above 33/50/100 ms. Separate startup/first traversal from a warmed repeat; retain actual CPU/process/physics and draw/primitive/memory counters. Post-draw intervals include CPU, rendering and presentation; they are not isolated GPU timings.

Do not run multiple render tests concurrently, use fixed-time captures as FPS evidence, or treat Linux llvmpipe as an Apple M5 measurement. No new Mac, streaming or subjective-camera acceptance result is claimed by this research.

## Sources inspected on 17 October 2026

Official Godot **4.6 branch**, pinned to [`b10b7ed373c2d15555186914b82e167169b5b87b`](https://github.com/godotengine/godot-docs/tree/b10b7ed373c2d15555186914b82e167169b5b87b), retrieved from the official repository's raw source using ordinary HTTPS. These are engine API/design facts, not measured project outcomes. No source text or third-party runtime code was imported.

| Inspected URL | Relevant evidence |
|---|---|
| [Optimizing 3D performance](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/performance/optimizing_3d_performance.rst) | Frustum/occlusion, transparent costs, LOD and Forward+-only automatic instancing. |
| [MultiMesh](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_multimesh.rst) | Whole-object bounds and visibility, custom AABB, batching tradeoffs. |
| [Occlusion culling](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/3d/occlusion_culling.rst) | CPU buffer/AABB tests, fully occluded bounds, manual MultiMesh occluder setup, simple geometry and overhead. |
| [Camera3D](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_camera3d.rst) | Far culling, vertical/horizontal FOV and keep-aspect behavior, near-plane depth precision. |
| [GeometryInstance3D](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_geometryinstance3d.rst) and [visibility ranges](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/3d/visibility_ranges.rst) | Begin/end margins, hysteresis, HLOD and renderer-specific fade limitations. |
| [DirectionalLight3D](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_directionallight3d.rst) | Shadow distance, detail/performance cost and fade behavior during fast travel. |
| [Background loading](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/io/background_loading.rst) | Threaded request/status/get; a premature get can block. |

Retrieval SHA-256: Camera3D `6950169c0a0e7279d75eab1ce6ffa32038a19ed08f8dce26a8a9ed9684cc340d`; GeometryInstance3D `cf83911dc3297054e43d784775b369fea71a7b462aabfa11c1fb0db9168cf5ee`; MultiMesh `1ce66cb9327e11e0bd571af0c99e32e5fd6bf667eef84432c01694f1fa5ecc36`; occlusion `9b685cd6a0362a70991695cae6415aca241adbbfabce834f53d20555a0db3d78`; background loading `cddd158492d056d9b5d4d020cbba1999568cc2cc7445579269f98a7bd2ed5d8f`. NPS README at the exact revision linked above: `3e56cfdf41f4d419f2c7435dca955e37dd8ab31f37620d976a97a22915943bcf`. Re-fetch those pinned raw paths after cache replacement; no generated cache is required in the repository.
