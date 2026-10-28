# Disposable two-surface / fitted comparison

**Corrected production-sky and optional lossless-colour comparisons completed:
import/capture evidence passes; live art/performance gates remain open.** Future reruns require
the root's exclusive render window.
This directory owns the entire disposable fixture. `runs/` is ignored; the
parent `.gdignore` keeps every source and generated asset outside the live
Godot project. No original/fitted/runtime asset, collision, route, gameplay
script or project setting is modified. Installed local tools only; no spend.

After the explicit render-window release:

```sh
bash art_source/glasgow_bay/two_surface/preview/run.sh --render-approved
```

The **optional**, separately authorized colour-compression diagnostic is:

```sh
bash art_source/glasgow_bay/two_surface/preview/run.sh --render-approved --accent-colour-lossless
```

Default execution still imports every texture through VRAM compression. The
optional flag changes only `accent_basecolor.png` to Godot lossless import
(`compress/mode=0`) in a fresh disposable project. The exact same 1024² PNG,
colour mipmaps, geometry, UVs, materials and production lighting remain; the
small ORM stays compressed with no mips and all other maps retain their prior
settings. Imported image format and data bytes are measured, not assumed. This
is an isolation experiment, not a live setting, free-memory optimization, mip
bleed fix or performance result. Unknown or repeated CLI options fail before
staging, and the policy is recorded and independently checked at runtime.

`GODOT_BIN` may select the installed Godot **4.6.3** executable. On Linux the
runner starts its own 1920×1080 dummy Xorg display even when another DISPLAY
exists. It uses private XDG directories, bounded processes and exit cleanup.
The absolute output path is printed at completion. No Blender, asset generation
or live-project launch occurs. Output stays under this directory's `runs/`.

The runner copies three current fitted four-slot GLBs, three experimental
two-slot GLBs and their original maps into a disposable project. Common stone
map bytes are verified identical and copied once. After initial import, it sets
`meshes/generate_lods=false` for all six GLBs and performs a second import.
By default every texture uses the current low-quality VRAM-compressed import policy;
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

Lighting uses the exact production procedural sky/radiance, ambient
colour/energy, fog, warm directional light, ACES settings and west Exchange
frontage yaw. Actual values and the inspected environment source hash are
recorded in `report.json`. A simple 0.45 m apron replaces the surrounding city.
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

The first trial, `runs/comparison-oGJMNm`, passed 16 captures, 22 actual native
stage checks and all source/import/mip receipts on 26 stable inputs. Its
inherited BG_COLOR fixture omitted the production sky/radiance and left both
versions' glazing nearly black. Preserve it as admitted diagnostic captures
with an inadequate visual-comparison fixture, **not** quality acceptance. The
corrected fixture copies the existing production sky/environment only; no live
lighting or asset change is involved. Every rerun uses a new disposable folder.

The accepted capture batch is `runs/comparison-mIMLuJ`: Godot 4.6.3 Compatibility
on Linux llvmpipe, exit 0, **16 matched 1920×1080 scene PNGs**, **23 independently
decoded/imported mip PNGs**, **22 native-stage/hysteresis samples**, six mesh
imports, six shared texture imports and **26 unchanged source inputs**. Both
executed-copy checks and every scene-image primitive delta pass. Receipt SHA-256:
`cc777d656cda350b43ffe798053ea28fa352bb685071b6f8691307d72663d10a`.
The exact source/environment/material graph and all PNG/mip hashes are in that
run's `report.json` and `receipt.json`. There were no parse/import/admission
failures in either trial. V-Sync is unsupported on this private software display;
this does not affect the explicitly non-performance purpose of the captures.

Actual imported compressed texture data totals **3,503,512 bytes** for the
candidate's five maps versus **3,495,320 bytes** for the reference's four: an
**8,192-byte** delta from the no-mip 128² DXT1 ORM. These are imported image-data
bytes, not measured resident GPU memory. Stone/colour chains have ten mip levels;
accent ORM has zero. Actual sampled ORM maximum linear-channel errors are
0.009725 paint, 0.012005 glazing and 0.027055 metal after compression. The built-in
ORM material has white albedo and unit roughness/metallic factors with the
recorded packed texture; no custom shader or hidden scalar material remains.

All sixteen corrected originals were visually inspected. The front, recesses,
entry threshold, oblique silhouette and near/mid/far composition remain aligned.
Single-segment chamfers change small edge highlights without an observed missing
part or entry join. Production sky restores readable glass and joinery compared
with the dark trial. The candidate has faint repeated streaks on broad painted
fascia/pilaster/door areas, especially in close and threshold views. This is
**accepted comparison evidence, not final candidate art acceptance**.

The repeatable post-capture `diagnose_paint.py` confirms that source paint is a
single RGB [47,82,73], while actual imported mip 0 becomes four periodically
arranged colours spanning [41,81,66] to [49,85,74]. The no-mip roughness field also
dithers from source G=122 to G=121..125. Broad fascia triangle positions are
identical; their weighted corner normals change modestly with the bevel policy.
Thus compression contributes a real repeated texture pattern; smooth normal
changes can also affect highlights. No out-of-region UV/phase failure was found,
and that compressed trial alone did not assign every changed pixel to one
cause. `paint-diagnostic.json` separately binds its script, decoded inputs and
geometry; it leaves the accepted capture receipt unchanged.

Colour mipmaps remain enabled. Actual decoded **8×8 and coarser** colour levels
mix material regions; for example, level 7 maximum linear-channel errors reach
about 0.031 paint / 0.025 glazing / 0.038 metal relative to base reference, and
coarser levels worsen. Mid/far images show no obvious broad colour breakout at
the captured framing, but do not establish GPU mip selection or blanket
filtering quality. Resolve/accept the paint pattern and distance/foreshortened
colour behaviour before any live integration, then perform controlled runtime
performance checks. The existing runtime loader still requires **four slots**;
these two-slot assets are **not drop-in replacements**. No live enablement,
frame-time improvement, Mac result, or final-art signoff follows from this run.

The optional lossless diagnostic is `runs/comparison-0ZsW35`. It completed on
the same Godot 4.6.3 Linux llvmpipe fixture with exit 0: all 16 scene PNGs,
23 mip PNGs, 22 native samples, six meshes/textures and 26 stable source inputs
passed the unchanged admission checks. Receipt SHA-256:
`28e38505e1bb8ed20a9f182771bd412809e2983784a4b7e88911e832ef94c153`.
There were no rejected parse/import/admission trials in this diagnostic.
The original dark and corrected compressed runs remain untouched.

Only the colour import changed. The actual accent image is **RGB8**, uncompressed,
with ten mip levels and **4,194,303 imported image-data bytes**, compared with
699,064 bytes for the original DXT1 chain. The five-map candidate total rises
from **3,503,512 to 6,998,751 bytes**, a **3,495,239-byte** increase. It is
3,503,431 bytes above the four-map fitted reference. These are actual imported
data sizes, not resident GPU-memory or performance measurements. ORM remains
the same compressed, no-mip DXT1 image, and its decoded PNG and sampled errors
are unchanged. All other imported formats, sizes, mip policies and source
texture hashes match the control.

The separately source-bound `compare_lossless.py` verifies the exact geometry,
material graph, production environment, camera poses and actual selected
stage counts against `comparison-mIMLuJ`. **All eight fitted control images
are byte-identical**, as well as decoded-pixel-identical. Its
`lossless-comparison.json` records image hashes, measured differences, both
colour-mip analyses and the byte costs; it does not rewrite either receipt.
Its SHA-256 is
`9516c77d9a76f2c7f2b625c4522303cca43832a2bd944dfc55b14a74545f3218`.
The new `paint-diagnostic.json` SHA-256 is
`9a10755454efcdbf4ec4727e9529b7712e5392b09025eb808699b3bcc9325962`.

Actual near, close, threshold, oblique, foreshortened and distance frames were
opened for review, including compressed/lossless pairs. The repeated vertical
paint pattern visible on the compressed fascia and lower door is absent in
the lossless close/threshold views; smooth edge highlights and readable joins
remain. The loaded paint rectangle is exactly one RGB [47,82,73], and metal
is one RGB [91,87,74], matching the original colour pixels. This identifies
colour compression as a contributor to those bands without attributing every
fitted-versus-candidate difference to it: chamfer normals and compressed ORM
still differ from the fitted scalar materials.

Lossless colour **does not fix atlas-region mip mixing**. At actual mip 7
(8×8), maximum linear-channel differences from base reference remain about
0.03447 paint / 0.01878 glazing / 0.04803 metal; at mip 10 (1×1), they reach
0.06562 / 0.01400 / 0.09271. Mid/far frames do not show an obvious broad colour
breakout at this framing, but do not establish GPU-selected mips or filtering
quality across hardware. Capture/import evidence is accepted; live filtering,
frame-time/spike cost, Apple Silicon and full-art acceptance remain open.
Default imports and live assets are unchanged. Renderer/display jobs exited.

A future experiment could compare a reduced-near-poly **four-slot** export
(the same 9,864-triangle bevel policy with scalar paint/metal and original
repeated glazing) against the two-slot atlas route. That would test the lower
geometry cost without the new colour-atlas banding, region mixing or lossless
byte increase. The prior +2/+3 reported-draw delta was within the +4 draw gate,
but failed its separate frame-spike gate; neither surface count nor triangle
count predicts the winner. This is a suggestion only: no such asset has been
created or integrated, and either route needs controlled matched timings.

To reproduce only the post-capture diagnostics without launching an engine:

```sh
python3 -B art_source/glasgow_bay/two_surface/preview/diagnose_paint.py art_source/glasgow_bay/two_surface/preview/runs/comparison-0ZsW35
python3 -B art_source/glasgow_bay/two_surface/preview/compare_lossless.py art_source/glasgow_bay/two_surface/preview/runs/comparison-mIMLuJ art_source/glasgow_bay/two_surface/preview/runs/comparison-0ZsW35
```
