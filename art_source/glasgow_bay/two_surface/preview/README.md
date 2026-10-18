# Disposable two-surface / fitted comparison

**Prepared source only. No import, native-LOD check, capture or visual pass is
claimed yet. Wait for the root's exclusive render window before execution.**
This directory owns the entire disposable fixture. `runs/` is ignored; the
parent `.gdignore` keeps every source and generated asset outside the live
Godot project. No original/fitted/runtime asset, collision, route, gameplay
script or project setting is modified. Installed local tools only; no spend.

After the explicit render-window release:

```sh
bash art_source/glasgow_bay/two_surface/preview/run.sh --render-approved
```

`GODOT_BIN` may select the installed Godot **4.6.3** executable. On Linux the
runner starts its own 1920×1080 dummy Xorg display even when another DISPLAY
exists. It uses private XDG directories, bounded processes and exit cleanup.
The absolute output path is printed at completion. No Blender, asset generation
or live-project launch occurs. Output stays under this directory's `runs/`.

The runner copies three current fitted four-slot GLBs, three experimental
two-slot GLBs and their original maps into a disposable project. Common stone
map bytes are verified identical and copied once. After initial import, it sets
`meshes/generate_lods=false` for all six GLBs and performs a second import.
Every texture uses the current low-quality VRAM-compressed import policy;
only the OpenGL normal map is marked as a normal map, with no Y inversion.
**Only `accent_orm.png` has `mipmaps/generate=false`; all colour and stone maps
retain mips.** Both import metadata and actual loaded texture dimensions/data
and mip chains are checked before rendering.

The candidate uses one shared `StandardMaterial3D` sandstone and one shared
built-in `ORMMaterial3D` accent. The fitted reference uses the same stone
resource plus its existing paint/glazing/metal materials. All three stages
reuse the relevant material objects. Stone uses the production neutral tint
`Color(.32,.42,.57).linear_to_srgb()`, original normal and green roughness
channel. The accent uses white albedo with the sRGB colour atlas and a packed
linear ORM: R=occlusion, G=roughness, B=metallic, unit factors. Both are opaque,
backface-culled, with linear mipmapped anisotropic filtering. No custom shader.
The receipt records the actual material class, factors and texture graph.

The imported ORM is read back, decompressed and sampled at actual exported
triangle-interior UVs. A one-RGB565-step bound checks effective class/channel
values after compression. Actual imported colour mip images are also retained
and sampled at the same UVs, independently of the ORM check. The previous bad
ORM mip-4 example remains in `source-asset-audit.json`. Disabling ORM mips does
not solve or conceal colour-atlas region bleeding; distant/foreshortened colour
appearance remains its own acceptance gate. Numeric mip errors include normal
minification/compression loss and do not identify the GPU-selected mip level.

Lighting uses the production ambient colour/energy, warm directional light,
ACES settings and west Exchange frontage yaw. A neutral background and a simple
0.45 m apron replace the surrounding city; scene fog is omitted deliberately.
Detailed mesh casters are OFF. Both variants share one identical original-mass
30×16×12 shadow-only box. These fixture differences are recorded; this is not a
full-city grounding, route, lighting or performance comparison.

Six imported meshes are checked for exact source hashes, metre bounds, surface
names/counts and 9,864/3,544/648 versus 18,392/3,544/648 triangles. A real 256²
SubViewport checks native stage counts and bidirectional hysteresis at 22
samples, using the existing 25±4 m / 80±6 m native visibility-parent chain.
This also catches unexpected imported automatic simplification at those
distances. No camera culling result is inferred from a successfully saved PNG.

Sixteen matched **1920×1080** frames cover front, close, threshold, oblique,
foreshortened and near/mid/far distance views for both variants. Camera poses,
asset hashes and expected native stages are recorded. PNGs are fully decoded,
checked for dimensions/non-flat output and hashed; pairwise differences are
reported without pretending that a low pixel difference certifies quality.
Actual decoded colour/ORM mip PNGs and their hashes are separate diagnostics.
Each captured frame also has an exact same-camera fixture-only primitive
baseline. The holder-visible minus fixture-only count must equal the intended
stage's actual triangle count; the PNG is taken from that verified frame.
An unambiguous native distance seeds each view before entering hysteresis;
no individual stage is forced visible. Thus the separate LOD sweep cannot
substitute for admission checks on the actual comparison images.

`input-manifest.json` binds the copied assets, recipes and inspected production
material/light sources. `report.json` records actual resource/native/render
checks. `receipt.json` verifies all source hashes remained stable and records
decoded pixels, import-mip analysis and comparison differences. A parse/import,
native-count, texture-role or source-stability failure exits nonzero. Rendered
visual review, actual hardware filtering behavior, full-game frame-spike
gates, Apple Silicon, human acceptance and live integration remain open.
The staged, executed `render.gd` and `project.godot` copies are hashed against
their source recipes before staging, inside the running fixture and at final
receipt time; unchanged source hashes alone are not accepted as execution proof.
