# Explicit static architecture batching

Owner: A05 implementation / A01 integration / A09 rendered comparison. This startup-only candidate follows the [rendering review](../research/RENDER-EFFICIENCY-REVIEW.md). No new district, asset, paid tool, streaming system or renderer is introduced.

The existing facade builder already batches one material and unit mesh kind inside each facade. Exact primitive-resource sharing reduces distinct mesh resources but does not combine those facade draws on Compatibility. `game/levels/static_batches.gd` combines explicitly registered static architectural batches in world-space cells, preserving their original unit mesh, materials and render state. It uses MultiMeshes, rather than expanding every repeated box into baked vertex geometry.

## Integration contract

```gdscript
const StaticBatches = preload("res://game/levels/static_batches.gd")

# After constructing a static MultiMesh from author-owned CPU arrays:
StaticBatches.register(source, authored_transforms, colors, custom_data)

# Before moving a threshold, read a copy, update both the author array and the
# MultiMesh, then register the resulting array again. Never read dummy GPU data.
var transforms: Array = StaticBatches.authored_transforms(source)

# After all decoration, threshold adjustments, final ancestor scales and exact
# mesh-resource sharing have finished, before ordinary play:
var report: Dictionary = StaticBatches.finalize(world, 64.0)
```

`register(source, transforms, colors=[], custom_data=[]) -> bool` is an explicit permission promise: the source and its ancestors will retain their final transforms and visibility after finalization. Arrays are copied; lengths must match the MultiMesh's instance count and enabled channels. Transforms must be finite, nonsingular and positively oriented; channel colors must be finite. Failed registration revokes permission rather than allowing stale records to be merged. The new helper never infers permission from a node name.

`authored_transforms(source) -> Array` returns a copy of the registered local transforms. In particular, Exchange Gallery's west threshold adjustment must update these records along with the actual MultiMesh. Print Works receives its final nonuniform ancestor scale after facade construction; finalizing before that scale would move its windows. The world integrator owns this ordering.

`finalize(world, cell_size=64.0) -> Dictionary` accepts finite cell sizes from 8–256m; the bounded comparison should try 32m and 64m. It derives cells from each actual world instance position, not the facade node origin. Unit mesh identity, material identity, enabled channels and every stored GeometryInstance3D/VisualInstance3D render property form a compatibility family. Each family is committed only when its occupied cell count is strictly lower than its original source count. Families without a batch-node saving remain intact. This guard does not prove fewer submitted draws from every camera; the rendered comparison remains required.

An output duplicates its source's visual settings and uses a cell anchor plus transformed local instance records. Every staged world transform must agree within 0.1mm and all render properties must match before the original source nodes are removed. Failed staging frees the staged outputs and retains the originals. Outputs carry a finalized marker, making a second call a no-op. The report counts registered/eligible/excluded sources, merged families, unchanged families, removed sources, created batches, preserved instances and validation failures.

`snapshot(world) -> Array[Dictionary]` returns one CPU receipt per registered instance, including final world transform, mesh, render properties, channel flags, color and custom data. It includes final output batches and excludes unregistered gameplay/art. Ordering changes during batching, so compare records as a multiset; use the same 0.1mm transform tolerance. CPU receipts are not GPU readback evidence. A real renderer must separately check the authored source/output MultiMesh transforms and enabled channels, allowing the renderer's documented color precision.

Public metadata constants are `META_RECORDS`, `META_PERMISSION`, `META_FINALIZED` and `META_STATIC_SCOPE`. A scripted static builder ancestor such as CityArt must explicitly set `static_batch_scope=true`; the supplied world root is the trusted outer boundary. This is a static ownership declaration, not a mechanism for freezing gameplay.

## Eligibility and preserved scope

Only registered childless MultiMeshInstance3D leaves are considered. Sources retain unchanged rendering when any of the following applies:

- Scripted sources, moving physics ancestors, animated ancestors, or an untrusted scripted ancestor.
- Hidden sources, a visibility parent, nondefault visibility ranges/margins/fades, node transparency, a top-level transform, partial instance visibility or custom bounds.
- ShaderMaterials, alpha/scissor/hash materials, billboards, distance/proximity fades or an unsupported material pass.
- Invalid author arrays, changed MultiMesh identity/channel flags, nonfinite/degenerate/reflected transforms or positions exceeding integer cell coordinates.
- A distinct mesh, material, shadow mode, layer, GI/occlusion setting or other stored render property that prevents a compatible family from saving batch nodes.

Material-based compatibility does not hide distant geometry. Source mesh geometry, instance scale/rotation, enabled colors/custom channels, material overrides, shadow settings, GI settings, layers and culling margins remain represented. Unregistered trees, actors, moving props, water, shop/roof transparency, floor meshes, rails, collision, goals and landmarks remain under their existing owners. No per-frame rebuilding, asynchronous streaming, district lifetime changes, draw-distance edits, occluders or shadow-distance changes are part of this helper.

The explicit permission assumes registered ancestor visibility remains static during play. Any future district-level runtime visibility system must deliberately integrate these batches rather than hiding an old facade parent and expecting a world-owned merged batch to follow it.

## Focused checks

`tests/static_batches_tests.gd` exposes `run(tree, check)`. The local headless runner completed **25 passed / 0 failed**, exit 0, with a clean engine/script log. It verifies author-array copies, world-space cells across distant parent origins, all instance/channel/render-state records preserved once, rotated/nonuniform parent and world transforms, untouched collision/unregistered art, idempotence, strict batch savings, distinct materials/meshes/shadows/layers, dynamic/hidden/transparent/shader/range/partial/bounds exclusions and invalid transform/cell rejection.

These tests intentionally rely on authored CPU records. Godot's headless dummy renderer does not provide real MultiMesh buffer readback, so this focused result does not certify rendering, frame times or Mac performance. The production aggregate check and rendered comparison remain integration gates.

## Comparison and acceptance recipe

1. Freeze the source and record all relevant input hashes. Construct the same production world with registration enabled and finalization suppressed. Preserve all physics/landmarks and normal material/shadow/far-plane settings.
2. Record the eight existing fixed render-budget cameras at the same 1280×800 Compatibility resolution, warmup and sample counts. Capture actual source MultiMesh buffer records and CPU snapshots. Record world mesh/MultiMesh/node/body/shape counts.
3. Finalize at 64m, capture the same cameras, and compare record multisets, unchanged physics counts, exact material/render settings, actual buffer transforms/channels, draw calls, objects and primitives. Repeat against a fresh identical baseline for 32m; never compare 32m after an already finalized 64m world.
4. Inspect Exchange shop fronts/gallery, Barras stalls/sign, civic facades, Central canopy, Clyde landmarks and park sightlines. Preserve images and source-bound counters even when a candidate is rejected. Do not promote a candidate that creates missing pieces, visibility regressions or unacceptable view workload.
5. Run the ordinary full regression after the final integrated source is frozen. Repeat stationary timing under matching settings, then obtain moving-route frame-time evidence on the owner's Mac. Lower batch/node/draw counts do not themselves certify 60fps or eliminate traversal stutter.

At initial implementation, **no rendered batch/FPS improvement is claimed**. The root integrator owns the source-stable 32m/64m comparison, final default choice and durable result links.

## Separate follow-ups

True opaque `Facade` boxes, Barrowland's solid backdrop and solid repair-hall walls are candidates for inset box occluders. Open market aisles, station canopies, suspension portals and retained ironwork must not become closed occluders. Occlusion needs a separate CPU/render comparison. Fine books/displays/window trim can receive explicit detail roles and visibility ranges later; existing material batches mix fine and structural geometry, so shortening a whole material batch can remove useful landmark edges. Neither follow-up is included here.
