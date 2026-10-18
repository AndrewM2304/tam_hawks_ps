# Independent cubemap test design

18 October 2026. **Design record; native admission remains pending.** This began as a replacement test contract before changing the frozen panorama regression. Implementation follow-ups below distinguish the current representation from rejected attempts. The integration owner schedules the renderer; this reviewer runs no engine or asset generator.

Implementation follow-up: the owner has now bound a native layered cubemap to`context_sky` and released the helper migration; validation remains pending. Seven floating CityArt masses plus the identified Civic Chambers visual are existing BoxMeshes extended down toY−35, preserving roofs/footprints and their12 triangles each, so no revised triangle ceiling is needed. The revised helper validates the inspected Godot4.6.3 S3TC file headers, actual payload lengths andEOF and samples those actual imported images in both modes. Dummy cannot provide GPU readback, and a separate warmed native Compatibility probe returns all-black layer readback despite a correctly rendered sky. GPU-layer pixels are therefore explicitly unverified, with no substitute pass; actual native composition/timing is a separate required gate. No broader image loader or engine change is introduced.

Current follow-up supersedes the initial1024/DXT1 representation below: a native half-resolution experiment failed GLSL330 compilation despite34/0 finite checks. The current candidate is a direct six-face512² RGB8 cube with nine mip levels,1536×1024 source atlas and no extra half-resolution target. The same pinned raw-image header reader now requires plain remap/path,512²/format4/mips9 and1,048,575bytes per face,6,291,450bytes total (6MiB−6). Every coordinate/atlas operation uses the512 face-size constant; the offline reference remains4096×2048. The direction table and all12 join orientations below are unchanged. Source-oracle/mip bounds stay fixed; actual native composition and timing remain pending.

The complete panorama candidate remains rejected at7 of15 strict timing gates. A cubemap is a candidate for preserving its original distant scenery with a different native sampling path; fewer angular operations are not a measured performance result. Retain the panorama as an offline reference, the failed native images/timings and the existing finite geometry proofs. Do not enable an alternate sky merely to mark the task complete.

## Resource and runtime contract

Use one native `Cubemap`/`CompressedCubemap` resource with exactly six512×512 layers in native order **+X,−X,+Y,−Y,+Z,−Z**. Each actual imported layer must be opaque uncompressed RGB8 with nine mip levels; validate and sum actual import-chain pixel payloads and require≤6MiB. The inspected Godot4.6.3 layered format has an exactGSTL/version1/six-layer/cubemap header followed by six raw512²/9-mip/format4-RGB8 records, each1,048,575bytes,6,291,450bytes total; reject any header/body/EOF mismatch. Runtime `get_layer_data` is GPU readback and cannot be used as imported-payload or driver-residency evidence. Reject missing/duplicated layers, empty data, absent mipmaps or transparent/black missing faces. PNG/file-header bytes and actual driver allocation are separate from pixel payload.

The runtime sky may use one static sky `ShaderMaterial` with one `samplerCube` and direct `EYEDIR` lookup. Require declared colour-space/filter intent, no `TIME`, screen-space or player-position dependence, no per-frame callback, no extra light/camera/scene sky, and the same QUALITY sky. Confirm actual shader source and bound resource rather than accepting material class or metadata alone. Keep ambient light, sun, fog, exposure, camera and viewport settings unchanged. Reversible comparison must restore the original procedural material and the candidate cubemap without changing physical support, routes or water material.

The retained4096×2048 panorama must remain available to development tests without being preloaded as a second runtime sky texture. Count resident shipped imports separately from offline source files. A same-process appearance-off control retains candidate allocations; equal memory counters across its phases do not prove zero additional residency.

## Independent world-direction oracle

Use the native order above and the following face-to-direction table. Let `s=2*(column+0.5)/N−1` and `t=2*(row+0.5)/N−1`, with current face size`N=512` and image row increasing downward. Normalize each direction. Derive the test oracle independently; do not call the bake generator or trust its face labels.

| Native layer | Face | Unnormalized world direction |
|---|---|---|
|0 |+X |`(1,−t,−s)` |
|1 |−X |`(−1,−t,s)` |
|2 |+Y |`(s,1,t)` |
|3 |−Y |`(s,−1,−t)` |
|4 |+Z |`(s,−t,1)` |
|5 |−Z |`(−s,−t,−1)` |

For the retained panorama, the canonical world mapping is`u=positive_mod(atan2(direction.x,−direction.z)/(2π),1)` and`v=acos(clamp(direction.y,−1,1))/π`. Thus horizontal−Z,+X,+Z,−X correspond respectively toU0,0.25,0.5,0.75; +Y and−Y are the top and bottom poles. Sample with explicitly agreed pixel-centre bilinear coordinates (`u*width−0.5`, `v*height−0.5`), repeatU and clampV. CPU decoded image colours and the source comparison use the same sRGB encoding; do not accidentally compare raw sRGB bytes with a GPU-linear sample.

The inspected Godot4.6 Compatibility source under the owner's retained `godot-sky.glsl` uses`atan2_approx(cube_normal.x,−cube_normal.z)` and`acos_approx(cube_normal.y)` for `SKY_COORDS`, wrapping negativeU, while native `PanoramaSkyMaterial` samples that coordinate directly. Its approximation introduces a small angular difference from canonical trigonometry away from the equator. Record this distinction before baking: prefer an explicit canonical direction contract; do not silently claim pixel identity with the former approximate panorama shader. Confirm orientation on the actual native renderer because importer row orientation or a shader sign flip can defeat a correct CPU bake.

Required direction fixtures include all six face axes, horizontal bearings every15°, several non-equatorial landmark bearings at±15°/±30° latitude, and asymmetric directions such as normalized`(1,.3,−.7)`, `(−.2,.6,1)` and`(.4,−.8,−.3)`. These distinguish flipped, rotated, swapped and mirrored faces. Fixture positions come from the world-direction definition, not the candidate face-selection branch.

## All twelve face joins, eight corners and poles

Name left/right by`s=−1/+1` and top/bottom by`t=−1/+1`. A horizontal edge's parameter increases left→right; a vertical edge's increases top→bottom. The paired parameter order is:

| Join | First edge | Second edge | Parameter order |
|---|---|---|---|
|1 |+X left |+Z right |same |
|2 |+X right |−Z left |same |
|3 |−X left |−Z right |same |
|4 |−X right |+Z left |same |
|5 |+X top |+Y right |reversed |
|6 |+X bottom |−Y right |same |
|7 |−X top |+Y left |same |
|8 |−X bottom |−Y left |reversed |
|9 |+Z top |+Y bottom |same |
|10 |+Z bottom |−Y top |same |
|11 |−Z top |+Y top |reversed |
|12 |−Z bottom |−Y bottom |reversed |

Sample at least nine locations per join, spanning its length but avoiding exact triple corners, on both sides of the edge at independently defined texel-centre directions. Test all eight normalized`(±1,±1,±1)` triple corners separately on their three incident faces. Test the exact north/south pole and near-pole rings in several azimuths; the retained source poles are uniform, so an upside-down or missing cap cannot hide behind a horizon-only comparison. Cover at least two lower mip levels as well as the full-size layers, since per-face mip generation can introduce a seam absent at mip0.

Do not demand that adjacent raw decoded edge texels are identical. They represent slightly different directions; earlier DXT1 attempts also dithered differently across rotated faces. For each selected4×4 comparison block, independently calculate the corresponding sixteen panorama directions and reference colours. Compare the baked-source block mean to that oracle with the declared0.005 resampling/8-bit rounding allowance, then compare the actual imported block mean to that source block with the existing0.04 Euclidean RGB bound. The current RGB8 representation has no DXT codec step; ordinary8-bit/mip rounding still needs a bounded comparison. Print worst errors and coordinates before deciding any mismatch; do not tune a tolerance after observing a failed candidate.

Across a join, compare the **residual** between each side's imported-minus-source colour error rather than interpreting a real source skyline edge as a seam. Each incident face still individually satisfies the0.04 bound; the derived pairwise residual bound is at most0.08 by the triangle inequality. Also verify correct paired geometry/orientation against the source oracle. Raw outer-texel jumps remain diagnostics. If the native compression cannot satisfy this bounded contract, investigate format/bake/mipmap behavior and retain failures; do not automatically raise tolerances.

## Native validation and existing gates

A separately scheduled sky-only native calibration chart remains an optional diagnostic if source/ordinary-view evidence exposes an orientation or sampling problem; do not build new GPU infrastructure merely to bypass the confirmed broken readback API. Such a diagnostic would inspect six axes, twelve joins, eight corners and poles against the independent oracle, and any synthetic calibration texture must stay out of shipped art/final captures. The current candidate's actual native37-view composition gate remains required, with the GPU-layer readback limitation stated explicitly.

The final normal-World capture must repeat all37 settled supported chase fixtures, the real map, the labelled overview and the15 matched original/candidate/original40-frame triples under the unchanged strict p95/p99 gate. Include the raised deck's actualY5.2 contact, high park viewpoints, both river directions and reported Civic/Barras openings. Keep source manifests, actual positions/layers,67 observations/2,680 intervals, PNG hashes and failed attempts. Imported resource budget and cold-memory evidence remain separate from the same-process timing result.

Keep the independent raw-footing, service-plane, river-top/water separation, protected-port,354-body/1,296-shape,48-route and six-area support tests intact. The real floating CityArt frontage identified nearX−70/−105,Z−149,baseY6 requires its own exact visible-foundation contract and a declared revised triangle budget; a new sky does not close that defect. New support, collision, route closure or a catch floor is outside this visual repair.

Passing finite native checks and stills does not certify temporal flicker, target Mac/M5 FPS, DualSense input, human fun or final realistic art. Those limits persist for any admitted sky representation.
