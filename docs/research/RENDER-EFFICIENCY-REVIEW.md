# Rendering efficiency review — 17 October 2026

**Historical resource-sharing review.** The later current-map pass now also ships selected 64 m architectural batching, 30/45/75 m graphics-profile shadow ranges, HUD caching and displayed-motion interpolation. Native occlusion and tree partitioning remain off. Current source-bound counters, rejected candidates and completed timings belong in [PERFORMANCE-HARDENING](../testing/PERFORMANCE-HARDENING.md) and [after/control/moving evidence](../testing/performance-after-20261017/README.md); the counts/defaults below describe this earlier source.

Owner direction: harden the current map, raise fidelity and investigate rendering only the visible/current area. No new areas, paid services, asset purchases or renderer migration are required by this review.

## What the engine already does

Godot automatically frustum-culls objects outside the camera's viewport. The current chase camera already has a **220m far plane**, and the single directional shadow source already stops at **75m**. Drawing the viewport is therefore already the starting point. An object can still cost work when hidden behind a building inside that frustum, and all instances in one visible MultiMesh are submitted as a group. An object outside the main camera can also remain necessary to cast a visible shadow.

Rendering visibility, loaded assets, scene-tree/CPU work and physics state are separate budgets. Hiding a district does not remove its nodes, imported textures, collision shapes or gameplay processing. Disabling an area's collision/actors merely because the camera points away would break landings, grinds, combos, goals and fast turnarounds. A 220m camera should not be shortened globally before checking cross-river landmarks, station sightlines, park vistas, airborne travel and the chase camera's collision alternatives.

## Inspected baseline

An isolated **Godot 4.6.3 headless world construction**, using `glasgow_square.gd` and excluding player, HUD and encounter actors, counted:

| Item | Before helper | After exact primitive sharing |
|---|---:|---:|
| Nodes | 3,927 | 3,927 |
| MeshInstance3D | 672 | 672 |
| MultiMeshInstance3D | 762 | 762 |
| Unique mesh resources | 1,419 | 324 |
| Unique instance override materials | 55 | 55 |
| StaticBody3D | 338 | 338 |
| CollisionShape3D | 1,850 | 1,850 |

The helper replaced **1,095 duplicate primitive mesh assignments** with equal resources. These counts show fewer distinct mesh resources. They do **not** measure VRAM bytes, upload time, CPU time or a frame-rate improvement. Compatibility does not provide the automatic identical-MeshInstance draw instancing available in Forward+, so resource sharing must not be sold as a draw-call reduction.

The park currently uses two scene-wide MultiMeshes, one for trunks and one for canopies; each contains **55 trees**. The cached canopy contains **3,080 triangles** before instance transforms, plus trunk geometry. One visible tree batch can therefore submit trees across a much larger region than the camera actually needs. Facades, market architecture and Clyde buildings already use material batches; turning every small window back into an independent node would be a regression.

The historical six-area rendered package at `docs/testing/performance/six-area-20261017/` is useful context, not the baseline for a claimed improvement on today's source. It used Godot 4.6.3 Compatibility, **1920×1080**, Linux **llvmpipe (LLVM 19.1.7)** software rendering, source base `64000fdbff6812906a02ea4e4447143a75b8f623`, 114 samples. Its per-view median draw-call counts were Royal Exchange **1,892**, George Square **937**, Central Station **713**, Barras **1,900**, Clyde **459**, Kelvingrove **211**; maximum scene node count was **2,687**. The newer world has more nodes, and the historical stationary software-rendered timings do not establish Mac performance or a moving-route budget.

## Current implementation and measurement contract

`game/levels/render_budget.gd` exposes one production startup call:

```gdscript
var report: Dictionary = RenderBudget.apply_static_decor(world)
```

It shares exact built-in primitive resources, considering all stored mesh properties and surface material identity. Imported/procedural ArrayMeshes, scripted resources and resources marked local to scene remain with their author. Instance transforms and material overrides remain unchanged. **Production defaults to primitive sharing only.** It does not split tree batches, change any draw distance or claim a measured FPS gain.

An opt-in diagnostic operation, `apply_static_decor(world, true)`, spatially partitions only the explicitly named static `ParkTreeTrunks` and `ParkTreeCanopies` batches. Both **48m** and **96m** cells were tried. Each resulting batch retains the same mesh, instance transform, colour and custom channel; cloned visual properties preserve shadows, layers, visibility and material overrides. It changes no distances, collision, floor/rail geometry, actor state or district lifetime. Smaller batches improve the renderer's culling granularity but can increase draw calls when several cells are visible. **Neither candidate was selected as the production default**, because the normal park checkpoint's draw/primitive tradeoff did not demonstrate an efficiency win. The helper retains the 96m option for explicit diagnostics only.

`tests/render_budget_tests.gd` passes **10/0** isolated headless checks. These verify exact primitive sharing and geometry/material distinctions, untouched physics/ArrayMesh resources, production-default tree retention, two-call idempotence, and pure authored partition records with complete transforms/colours/custom channels retained exactly once. **Godot's dummy headless RenderingServer returns identity MultiMesh transforms and empty buffers.** The tests deliberately do not claim live MultiMesh readback or visual proof from that backend.

`tools/render_budget_probe.sh --private-display` provides a bounded, same-process rendered comparison: frozen production world only, the same eight fixed cameras and **1280×800** framebuffer, two warmup frames and three counter samples per view, before/after screenshots, source hashes and an actual renderer tree-data equality check. Six cameras match the historical district viewing directions; two extra park views face opposite directions. The output stays under `.local/`. It is not a gameplay FPS, target-hardware or human visual acceptance test. Normal-world integration must honor the diagnostic's `render_budget_probe_baseline` metadata while constructing its before state.

The [48m rendered candidate](../testing/render-budget-20261017/README.md) completed successfully on Compatibility/llvmpipe with **16 actual PNGs**, unchanged source inputs and exact equality of all **110** tree instance records. The candidate produces **22** chunks from the original two batches: world nodes **3,927→3,947**, MultiMesh nodes **762→782**, unique meshes **1,419→324**, physics bodies/shapes unchanged. Both park-north and normal park-checkpoint PNGs are pixel-identical before/after; city land views differ only in isolated subpixel/raster samples. Water animates with `TIME`, so the Clyde before/after image changes in the water band.

| Fixed world-only view | Draw calls before → after | Submitted primitives before → after |
|---|---:|---:|
| Royal Exchange | 1,576 → 1,588 | 807,606 → 757,766 |
| George Square | 660 → 656 | 720,870 → 329,270 |
| Central Station | 567 → 581 | 466,078 → 419,798 |
| Barras | 1,271 → 1,271 | 1,000,274 → 832,954 |
| Clyde | 146 → 146 | 147,552 → 147,552 |
| Kelvingrove checkpoint | 73 → 109 | 465,538 → 447,738 |
| Park north | 54 → 78 | 462,560 → 352,200 |
| Park south | 444 → 468 | 606,290 → 485,250 |

The 48m result demonstrates culling granularity, with an explicit tradeoff: **0–54.3%** fewer submitted primitives across these views, with **−4 to +36** draw calls. The normal park checkpoint has only a **3.8%** primitive reduction while draws increase **73→109**, so the candidate was rejected as the production default. No frame-time improvement or Mac speedup follows from these counters. The viewport, camera far plane, world state and shadow configuration were not shortened to obtain the result. Source manifest SHA-256: `9f1811fdbc852bcb0440f8d1f290631e4202a2cdac58ca07a4918764778fd82d`.

The [96m rendered candidate](../testing/render-budget-96m-20261017/README.md) also produced **16 actual PNGs**, stable source and exact preservation of all **110** tree instance records. It produces **10** chunks, for **3,935** world nodes and **770** MultiMesh nodes; unique meshes and physics counts match the other candidate. All eight baseline counter sets reproduce exactly.

| Fixed world-only view | Draw calls before → 96m after | Submitted primitives before → 96m after |
|---|---:|---:|
| Royal Exchange | 1,576 → 1,580 | 807,606 → 772,006 |
| George Square | 660 → 656 | 720,870 → 329,270 |
| Central Station | 567 → 573 | 466,078 → 430,478 |
| Barras | 1,271 → 1,273 | 1,000,274 → 879,234 |
| Clyde | 146 → 146 | 147,552 → 147,552 |
| Kelvingrove checkpoint | 73 → 89 | 465,538 → 465,538 |
| Park north | 54 → 62 | 462,560 → 391,360 |
| Park south | 444 → 456 | 606,290 → 535,090 |

96m retains the civic distant-tree savings with fewer extra batches. However, the normal park checkpoint adds **16 draws with zero primitive reduction**, so it was also rejected as a production default. Production keeps exact primitive sharing alone; the current normal-game graphical capture owns final integration evidence. The candidate's source manifest SHA-256 is `4dc3d3dbdab972dffb786f438859268245ab2e6c17ca52b631e514aa04c35f3a`.

## Further batch merging: feasibility only

A cheap headless inventory after resource sharing found **744** opaque static MultiMesh candidates representing **41,104** instances. Grouping by the same parent, shared mesh/material and key render state yields **739** groups; only **five nodes** could be removed across four groups. That narrow case is unlikely to justify a new runtime rewrite.

Grouping across parents by **64m node-origin cells** instead yields **330** groups, an upper bound of **414** fewer batch nodes. This is only a candidate count: headless MultiMesh instance transforms/bounds are unavailable, parent origins do not describe complete instance coverage, and every author-owned transform, visibility dependency, surface, shader channel, shadow and potential motion needs review. The current generated batch names are not a stable semantic permission to merge them. Prefer author-time batching with explicit static metadata or baked local imported geometry, followed by the same source-stable counter/image comparison, before attempting this larger change. No batch-merging production code was added.

## Fidelity and performance priorities

1. **Improve near-player material and silhouette quality.** Ground, board, shoes, skater anatomy and garments occupy the most useful screen area. More polygons on hidden buildings cannot compensate for repeated flat materials, incorrect scale, simple silhouettes or lighting. Keep detailed render meshes separate from simple skating collision and authored rail tracks.
2. **Use imported glTF/GLB meshes with generated LODs.** Godot generates meshoptimizer LODs on scene import. This preserves a detailed near model while drawing fewer distant triangles. Runtime PrimitiveMeshes and these authored ArrayMeshes do not automatically gain imported LOD chains merely because their file format changes. Standalone OBJ files default to mesh-resource import and do not automatically gain scene-import LODs; their Import As mode must be changed to Scene first. Check the import's Generate LODs option, inspect generated surfaces, and verify at the chase camera's FOV/resolution. Inspect skinned/organic deformation because automatic simplification can damage it. Preserve readable rail/coping silhouettes and use simple collision separately.
3. **Keep textures mipmapped and compressed.** Current external brick/concrete imports use a **1024px limit**, S3TC/ETC2 VRAM compression and mipmaps; much of the remaining art uses generated **256px** albedo tiles. Raise resolution selectively where a close chase-camera comparison shows a real texel shortage. A 2048² texture has four times the base texels of 1024²; normal/roughness maps and mip chains add cost. Mipmaps improve distance stability and sampling bandwidth. Compatibility ignores the importer's High Quality/BPTC/ASTC option, so checking that box is not a quality upgrade on this renderer.
4. **Keep repeated decor spatially batched.** Prefer reusable meshes/materials and small local MultiMeshes for repeated facade/foliage props. Split by geography only when submitted triangles are actually reduced enough to pay for the added draw calls. Global one-batch-per-material approaches sacrifice culling granularity; one-node-per-leaf approaches sacrifice CPU/draw efficiency.
5. **Test occlusion on solid city architecture.** Godot's occlusion culling uses simplified static occluders rasterized on the CPU. It needs explicit occluder setup and offers the most benefit in enclosed street/court/undercroft views. Do not bake a closed wall across a skateable passage, shop window, portico or canopy gap. It adds CPU work and may not help open park/Clyde views. Measure representative moving routes before enabling it globally.
6. **Use visibility ranges for truly secondary detail after proof.** Small interior displays, fine trim and distant background detail can transition to simpler meshes or disappear before the full landmark does. Use hysteresis to avoid boundary flicker. Alpha fade can add transparent draw/overdraw costs; Compatibility and target-device results must guide the choice. Keep skateable surfaces, rails, route mouths, landmarks and useful silhouettes readable during fast turns and jumps.
7. **Retain the bounded shadow source.** Raising shadow distance includes more casters and spreads shadow detail across a larger area. Test whether nearby garments/board/landmark lighting improve before increasing distance or adding local dynamic lights. High-detail assets still need a per-material/surface and shadow budget, not just a polygon budget.

The existing `tools/profile.sh` is appropriate for source-stable stationary counter baselines. Final acceptance still needs the owner's Apple Silicon Mac at the chosen resolution during moving play, including rapid camera reversal, market/undercroft passages, high park/Clyde views and long combo chains. Report median/p95 frame time, CPU physics/process time, submitted draws/primitives, memory and loading spikes separately; do not infer that a high polygon count or a Linux software-rendered change means a Mac speedup.

## Inspected official sources

Read on **17 October 2026**, Godot docs **4.6** branch, inspected revision [`b10b7ed373c2d15555186914b82e167169b5b87b`](https://github.com/godotengine/godot-docs/tree/b10b7ed373c2d15555186914b82e167169b5b87b). The public docs host returned HTTP 403 in this environment; the official repository's raw source was retrieved instead. No article code or third-party assets were copied into the game.

| Source | Reviewed result |
|---|---|
| [Optimizing 3D performance](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/performance/optimizing_3d_performance.rst) | Automatic frustum culling; occlusion/transparent costs; automatic instancing is Forward+ only. |
| [MultiMesh](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_multimesh.rst) | Draw-call batching; one visibility object for all instances; per-instance colour/custom data precision differs in Compatibility. |
| [Mesh LOD](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/3d/mesh_lod.rst) | meshoptimizer LOD on import; screen-size selection; split widely separated MultiMeshes so culling/LOD can work effectively. |
| [Visibility ranges](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/3d/visibility_ranges.rst) | HLOD, begin/end ranges and hysteresis; alpha fading can force transparent rendering and has a cost. |
| [Occlusion culling](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/3d/occlusion_culling.rst) | Simplified static occluders and CPU rasterization; open scenes can offer too few culling opportunities to repay its overhead. |
| [Importing images](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/tutorials/assets_pipeline/importing_images.rst) | VRAM compression, Compatibility's HQ-compression limitation, mipmaps and their approximate 33% storage overhead. |
| [DirectionalLight3D](https://github.com/godotengine/godot-docs/blob/b10b7ed373c2d15555186914b82e167169b5b87b/classes/class_directionallight3d.rst) | Increasing directional shadow distance costs detail/performance by including more casters. |
