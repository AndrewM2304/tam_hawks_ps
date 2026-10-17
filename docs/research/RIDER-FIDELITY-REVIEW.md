# Rider, skateboard and Blender fidelity review — 17 October 2026

The rider needs better silhouette, material authoring and motion before more subdivisions. The current chase capture shows a roughly 160-pixel-tall rider and a roughly 20-pixel-wide board at 1280×800. Screen size limits the value of extra face, finger and hardware polygons. This review covers the existing rider and an original board replacement; it adds no level area and does not claim final visual acceptance.

## What the current source actually does

Inspected `game/player/skater_visual.gd`, `skater_anatomy.gd`, `skater_garments.gd`, `skater_footwear.gd`, the MakeHuman asset manifest and the normal-spawn capture. The anatomical head already has **8,508 triangles**, the two hands **6,632** combined, and the scalp **748**: **15,888 triangles before clothing, eyes, shoes or board**. The problem is not uniformly low polygon count.

| Observation | Consequence | Useful next change |
| --- | --- | --- |
| Clothing uses 20-sided rings/tubes and the same 64×64 repeated weave with near-uniform roughness. | Jacket, sleeves and trousers have round continuous forms and little garment construction, wear or fold information. More radial segments preserve that appearance. | Author a jacket with shoulder/cuff/hem folds, asymmetric trouser drape, pockets and seams; unwrap a single outfit atlas. Bake small creases into a normal map. |
| Head pigmentation is vertex colouring; scalp is a solid-colour shell; six separate eye/iris/pupil ellipsoids use a much denser sphere than their chase-view size needs. | Smooth featureless skin and cap-like hair remain despite a detailed face mesh. Fine eye geometry consumes vertices without a corresponding silhouette gain. | Add an original low-contrast skin/roughness atlas, brows/hairline and a solid short-hair silhouette. Simplify eye meshes outside close views. Avoid alpha hair cards as the first Compatibility-renderer solution. |
| Garments use native GPU skinning, with ten independent bones supplied by analytic contact targets. | There is no per-frame mesh rebuild, which is worth retaining. Independent torso/limb motion lacks the continuous spine/shoulder/hip weighting of an authored character. | Use a conventional 30–45-deformation-bone hierarchy and map existing foot/hand targets to it. Preserve analytical contact correction after animation blending. |
| Push, landing, hands and torso use analytic curves. Steering affects shoulders by a small fixed amount; airborne tucks/blends lack authored anticipation and recovery clips. | Human weight, stance, cadence and board/rider separation influence perceived skating feel more than small mesh details. | Author coast/carve, push, crouch/ollie, landing, balance and bail clips; align timing with actual gameplay transitions. Keep camera and physics independent. |
| Original shoes add each stitch/lace as separate cylinder meshes. Original board creates **25 MeshInstance3D nodes**. | Tiny objects cost separate submissions and traversal even when their details cover fewer than a few pixels. | Merge static shoe details into two or fewer material surfaces; use normal/colour maps for stitching. Replace board assembly with a batched imported scene. |

The current MakeHuman head/scalp LOD must remain coordinated: the earlier documented scalp-only simplification collapsed it into the full-detail head. A whole-rider LOD authored from matching parts is safer than independently simplifying overlapping skin/hair.

## Concrete working budgets

These are proposed authoring caps to measure on the owner's Apple Silicon Mac, not claims about measured target performance. Spend triangles on silhouette and joints first; a higher-resolution texture does not repair a flat garment or an overly broad camera framing.

| Asset / distance | Triangle target | Material / texture target | Acceptance |
| --- | ---: | --- | --- |
| Player hero LOD0, visible throughout play | 28k–40k body, clothing, shoes and hair; board separate ≤6.5k | Body ≤4 surfaces; one 2048² outfit/skin base-colour + normal + packed ORM set. Board 4 surfaces, one 1024² colour atlas. | Shoulder, elbow and knee folds remain plausible at crouch/grab extremes; feet and hands contact the visible board. |
| Other full-body actors within ~15m | 12k–20k | ≤3 surfaces, one 1024² set, shared across actors where appropriate | Recognisable clothed silhouette and gesture at ordinary chase distance. |
| Actor LOD1 beyond ~15m, subject to screen-size check | 5k–8k | ≤2 surfaces, same texture atlas/mipmaps | No exposed clothing seams or visible scalp intersection while crossing the threshold. |
| Actor LOD2 beyond ~35m | 1.5k–3k or disable behind solid scenery | 1–2 surfaces; use current atlas mip levels | Preserve readable silhouette; transition during occlusion where possible. |

A 2048² RGBA image alone is ~16MiB before mipmaps or runtime compression, so do not assign a separate 4K map set to every shoe, hand or prop. Normal/ORM data is not sRGB. Use ordinary mipmaps and anisotropy where appropriate; preview both ordinary chase frames and fixed close views. Keep roughness calibrated for stone, cloth, skin, coated wood and metal so the scene does not look uniformly plastic or uniformly chalky. Godot already frustum-culls mesh bounds; the performance owner handles measured district visibility and submissions separately.

## Free source and pipeline findings

The existing MakeHuman data remains a viable reusable anatomical source. Its exact geometry, bundled adult morphs, licence texts, pins and hashes are already recorded in [HUMAN_MODEL_REUSE](HUMAN_MODEL_REUSE.md) and `game/art/assets/makehuman_hm08/manifest.json`. Do not replace an anatomically useful head with a nominally higher-poly mannequin. No new third-party character was imported during this review.

Re-read the actual [MPFB2 licence](https://github.com/makehumancommunity/mpfb2/blob/3af0cd5a2ffba072e93a34e5f6f494fdc4813ddf/LICENSE.md) at **`3af0cd5a2ffba072e93a34e5f6f494fdc4813ddf`**. It distinguishes **GPLv3 addon code** from **CC0 bundled mesh/proxy/target/texture/clothing/rig/pose data**, and explicitly disclaims rights over exported/generated output. Licence SHA-256 is `5cefb60680cb9efd4550a2e65d719021cfbec9dad3658481d11d48ae863ce04d`; README SHA-256 `9023f557668abc39de850fcced32fede5d34aa295c569410d91e5fb607decd0e`. This offers a free Blender human/rig authoring path, but individually downloaded community clothing/hair/animations still need their own licence inspection. The addon was not installed or executed here. No general clearance for community packs is implied.

[Godot's official format guide](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), inspected this date, recommends **glTF2 / GLB** and documents that OBJ lacks skeletons, animation, UV2 and PBR materials. A larger OBJ is therefore a poor final rider format. Use **Blender as authoring source → exported GLB for runtime**. GLB can package mesh/material textures, skeletons, animations and morph targets in a stable asset. Keep Blender authoring sources outside the automatically imported runtime asset tree unless the team intentionally accepts that dependency: importing `.blend` in Godot runs Blender's glTF export and requires every collaborator to have Blender installed, including on the owner's Mac. The format guide also recommends enabling backface culling before export to avoid unnecessary double-sided surfaces.

The [official model export guidance](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html) covers coordinate conventions, applied transforms and explicit triangulation. The [Blender4.3 glTF exporter documentation](https://docs.blender.org/manual/en/4.3/addons/import_export/scene_gltf2.html) describes metal/rough PBR, base colour, tangent-space OpenGL normals, baked AO and animation. Procedural Blender node graphs are not an automatic runtime material: bake the supported channels or use explicit scalar factors and inspect Godot's result.

## Is Blender MCP useful here?

It is useful for an interactive artist loop: inspect objects, see the Blender viewport, adjust a mesh/material, and run Blender Python in a live scene. It does not supply anatomical judgement, good UVs, a skating rig or a performance budget automatically.

Inspected [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp/tree/7a0373ec9199183cb460068c4f96aed9c579fb4f) at **`7a0373ec9199183cb460068c4f96aed9c579fb4f`**. Actual `LICENSE` is **MIT**, copyright Siddharth Ahuja2025, SHA-256 `049501fd54d27852507853a5b88094ca1c6ff97404418a5032f3310eecc9cde6`. The inspected `addon.py` defines a localhost socket server, viewport screenshot retrieval and `execute_code` using Blender's Python context; source hash `eb0facf69781a30e69792532087d8d41c6a14fcd323353250abe7988ee297fa5`. The README also exposes optional external model/asset services, including premium generation. The bridge licence does not clear any asset returned by those services. No MCP, service account or paid generator is installed, called or needed here.

The current environment already has **Blender4.3.2** at `/usr/bin/blender`, with Python/NumPy and glTF export. A checked-in batch Python generator gives a concrete original asset, known dimensions, repeatable outputs and a manifest without requiring a live GUI bridge or making the owner's Mac install Blender merely to play. Keep this route for modular props. Consider an optional MCP only when live artist editing materially helps a clothed character; its integration is a separate tooling choice, not a prerequisite for fidelity work.

## Original skateboard delivered in this pass

`tools/art/build_skateboard.py` generates `game/art/assets/tam_skateboard/tam_skateboard.glb`, one shared 1024² original colour atlas and a provenance manifest. There are **no external input assets or network calls**. The board adds a pressed deck with a small bevel around its rim, continuous concave/kicked grip, shaped cast trucks/bushings, rounded urethane wheel profiles, bearings and flush deck bolts. Its original underside graphic is an abstract river/bridges pattern; it contains no copied franchise or shop artwork.

Actual exported budget: **one mesh, four material surfaces, 5,696 triangles, one embedded image**. Surfaces are maple/river ink (2,600 triangles), grip (800), aluminium (928) and urethane (1,368). GLB is 626,756 bytes; source PNG is 469,086 bytes. Compared with the former 25-node board assembly, four material submissions reduce the number of independently submitted pieces. This is not a measured frame-rate claim.

Coordinate contract is **metres, Godot board-local**, with no runtime offset/scale: X `[-0.14,0.14]`, Y `[-0.12,0.0468632]`, Z `[-0.4175,0.4175]`. Wheel centres remain Y−0.088, radius0.032, axles Z±0.255 and central grip surface Y0.017. Existing planted shoe targets and physics stay authoritative. The generator converts to Blender's Z-up frame and exports glTF Y-up; do not add another axis rotation when instancing beneath the current board node.

Run `blender --background --factory-startup --python tools/art/build_skateboard.py`. Two consecutive final-source builds reproduced the same GLB and atlas hashes. Binary accessor inspection verifies finite positions/normals/UVs, in-range triangle indices, **0 zero-area faces**, **0 geometric-normal disagreements**, four material primitives and no Draco-required extension. Blender's installed exporter prints an optional unavailable-Draco-library diagnostic despite the explicitly ordinary uncompressed output; export finishes successfully. Root owns Godot integration and normal-scene capture after code freeze. A GLB structural audit does not establish in-game visual acceptance.

No extra board LOD is added: the whole asset is small, player-visible and needs a stable silhouette at shoe contact. Spend the next asset budget on the body/clothing instead of hiding an already small player board at range.

## Durable continuation tasks

| ID | Owner / priority | Dependencies | Acceptance and validation |
| --- | --- | --- | --- |
| RF-001 | A05 art / P0 — original board integration | Delivered asset; root's current physics state | Replace only visible geometry at the existing board transform. Capture coast, crouch/ollie, flip, manual/grind and grab from chase and fixed close views; no shoe/wheel contact or camera regression. |
| RF-002 | A05 character / P1 — authored outfit and UVs | RF-001; M05-001/M06-007 hardening | Author connected clothed skater from cleared/original data, using the triangle/material caps above. Preserve cosmetic colour selection and all current visual hooks. Inspect shoulder/cuff/collar and hips/knees under full crouch, push, grab and balance poses. |
| RF-003 | A04/A05 animation / P0 — weight and stance | Current movement review; pose/contact contract | Add anticipation, push recovery, carve lean, compressed landing and rail/manual balance poses/clips with timing driven by actual state. A real human must judge weight and readability during imperfect control input. Geometry-only screenshots do not close this. |
| RF-004 | A05 art/A09 QE / P1 — coherent actor LOD and batching | RF-002; measured visibility/performance plan | Use matched head/scalp/clothing LODs and merged small details. Capture thresholds without scalp/neck/cuff holes; measure actual Mac moving-route frame times and draw calls. Preserve interaction, audio and collision while a remote actor is visually culled. |

These are scoped subtasks of existing M05-001/M06-007 and movement hardening, not new gameplay-area milestones. Human Mac visual/feel acceptance, target frame time and final artist approval remain open.
