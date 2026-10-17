# Environment cleanup evidence — 17 October 2026

This is a measured second environment pass for M05-001 and M06-007. It replaces the most uniform shop strips with shallow facade modules and adds licensed material detail. It is locally implemented and rendered, with final realistic/fun visual acceptance still open. The four districts remain an original compressed interpretation of Glasgow; these shopfronts are architectural composites, not surveyed current businesses or accurate street reconstructions.

## Implemented

- Royal Exchange uses smaller retail bays, projecting window surrounds, shop doors, handles, display shelves, painted joinery, awnings, cornice brackets and dormers. George Square uses formal window rhythms, stone pilasters, smooth arched doors and restrained civic labels. Central uses wider arched ground bays and industrial upper glazing. Barras uses warehouse brick, painted market bays and parapets.
- Windows vary between dark panes, restrained reflections, curtains and occasional warm interiors. Roof and chimney silhouettes vary by facade style. Shop displays are shallow visual sets; doors do not lead to playable interiors.
- New side frontages frame George Square and the northern approaches. Their geometry stops before connector openings. Boundary coping, flush drains, and benches/bins outside the playable boundary give edges detail without adding collision.
- Inspected CC0 photographic brick and mineral concrete albedo/OpenGL-normal maps now dress warehouse walls and stone trims. All four source images retain their upstream bytes. Tracked Godot import settings limit them to 1024×1024 with mipmaps; materials share those resources. Sandstone coursing, paving, slate and asphalt retain original generated tiles. Texture provenance, hashes, licence and authored scale assumptions are in [VISUAL_ASSETS](../research/VISUAL_ASSETS.md) and the [asset manifest](../../game/art/assets/zc_textures/manifest.json).
- Facade boxes, cylinders, dormers and arches use material/shape MultiMeshes. Per-instance transforms carry dimensions and orientation. The reusable arch is a closed 24-segment band; it replaced visibly jagged rotated blocks during review.

The pass changes decorative meshes and materials only. Existing collision, ramps, rails, objective coordinates, gap definitions and route portals remain owned by `glasgow_square.gd`. Concurrent asphalt/contact-audio work belongs to the integration change; this pass supplies its asphalt material.

## Matched rendered evidence

The baseline environment was captured before these edits from `550a6dac7892f970724ef10d9856a66af9f52fcb`. The final views were captured after the four texture imports completed and after correcting sign/awning occlusion and arch edges. Each image is a direct viewport PNG, without post-processing outside Godot. The full game is instantiated with persistence disabled and the HUD hidden.

All 16 before/after PNGs and the two capture logs are retained under [screenshots/visual-pass](../testing/screenshots/visual-pass/). These are 1280×800 Compatibility-renderer images on Mesa llvmpipe software OpenGL, with the project's 2× MSAA. They show the actual production chase camera for four approaches plus a fixed close camera. They are not evidence of a human completing those routes or target-Mac performance.

| District | Chase comparison | Close comparison |
|---|---|---|
| Royal Exchange | [Before](../testing/screenshots/visual-pass/before-exchange-chase.png) · [After](../testing/screenshots/visual-pass/after-exchange-chase.png) | [Before](../testing/screenshots/visual-pass/before-exchange-close.png) · [After](../testing/screenshots/visual-pass/after-exchange-close.png) |
| George Square | [Before](../testing/screenshots/visual-pass/before-george-chase.png) · [After](../testing/screenshots/visual-pass/after-george-chase.png) | [Before](../testing/screenshots/visual-pass/before-george-close.png) · [After](../testing/screenshots/visual-pass/after-george-close.png) |
| Central | [Before](../testing/screenshots/visual-pass/before-central-chase.png) · [After](../testing/screenshots/visual-pass/after-central-chase.png) | [Before](../testing/screenshots/visual-pass/before-central-close.png) · [After](../testing/screenshots/visual-pass/after-central-close.png) |
| Barras | [Before](../testing/screenshots/visual-pass/before-barras-chase.png) · [After](../testing/screenshots/visual-pass/after-barras-chase.png) | [Before](../testing/screenshots/visual-pass/before-barras-close.png) · [After](../testing/screenshots/visual-pass/after-barras-close.png) |

Inspection confirmed individual shop entrances/displays, readable signs without facade/awning clipping, continuous curved arch edges, brick detail on market upper walls, and distinct shaded versus sunlit approaches. The Exchange lamppost still naturally occludes part of the close view; Central's right foreground platform and the Barras sign cropped by the chase framing are also retained rather than hidden for the comparison. Large paving/wall areas and repeated display props remain visibly procedural.

The fixed setup is recorded in [visual_pass_capture.gd](../../tools/visual_pass_capture.gd). Positions are world metres, yaw is radians. The detail camera uses FOV 68° and far distance 250 m. Each chase frame follows 35 physics/process cycles after placing the skater; close frames follow four cycles.

| District | Skater position / yaw | Close camera → target |
|---|---|---|
| Royal Exchange | `(-27, .04, 0)` / `PI/2` | `(-29, 2, -2)` → `(-35, 2.2, 1)` |
| George Square | `(13, .04, -114)` / `0` | `(12, 2.1, -119)` → `(12, 2.3, -125)` |
| Central | `(-117, .04, -8)` / `PI/2` | `(-121, 2, -8)` → `(-128, 2.4, -8)` |
| Barras | `(105, .04, -30)` / `0` | `(105, 2, -36)` → `(105, 2.4, -42)` |

## Render counters and checks

These are single-frame Godot render counters at matched views. They include the complete rendered scene and concurrent rider presentation, not only facade meshes. Geometry is more detailed, so fewer draw calls do not by themselves establish faster frames. No frame-rate or target-hardware claim is made here; the separate profiling task owns frame-time sampling.

| View | Before draw calls | After draw calls | Before primitives | After primitives |
|---|---:|---:|---:|---:|
| Exchange chase | 959 | 791 | 157,200 | 214,822 |
| Exchange close | 760 | 561 | 102,540 | 143,446 |
| George chase | 427 | 377 | 101,326 | 138,742 |
| George close | 189 | 160 | 40,380 | 72,276 |
| Central chase | 324 | 238 | 91,284 | 119,790 |
| Central close | 158 | 109 | 38,872 | 68,610 |
| Barras chase | 999 | 911 | 165,592 | 241,482 |
| Barras close | 479 | 453 | 86,102 | 156,716 |

The chase views reduce draw calls by approximately 18%, 12%, 27% and 9%, respectively. The final capture saved all eight after images with result 0 and process exit 0; its log contains no engine/script errors. The only rendering warning is the software driver's unsupported V-Sync setting.

Focused validation after the final geometry fixes: **89 world-route checks, 0 failures**, including existing support/connector capsule sweeps and cone behavior. A root-project resource probe loaded all four photographic maps as 1024×1024 textures with mipmaps, **4 checks passed**, exit 0. `bash -n tools/visual_pass_capture.sh` passed. The full integrated regression result is recorded by the orchestrator in [STATUS](../STATUS.md); this document does not substitute focused checks for that gate.

To reproduce after views on an imported checkout:

```sh
./tools/run.sh --headless --editor --import --quit
./tools/visual_pass_capture.sh
```

The capture wrapper reuses an existing display or starts its own temporary local Xorg dummy display on this Linux image, then stops that process on exit. It performs no downloads or hosted work. The default label is `after`; outputs go to ignored `.local/visual-pass/after-*.png`. For an intentional new baseline, use `./tools/visual_pass_capture.sh pass=before`. That explicit command replaces the ignored before images, so preserve the dated committed evidence when comparing a new pass. Review and copy new evidence deliberately; the runner never overwrites committed screenshots.

## Remaining cleanup and acceptance

M06-007 stays open. Continue independently through the following work without requiring routine task approval:

1. **A03/A05 · M03-006/007:** obtain current free reference access, inspect dated street/frontage relationships and replace unsurveyed composite edges with supported reference work. Existing location labels are not proof of a faithful present-day frontage. No Maps/Street View imagery is bundled.
2. **A05 · M05-001/M06-007:** reduce repeated upper-storey rows and displays, improve large procedural sandstone/paving surfaces, refine roof/gable continuity and material joins, and give remaining primitive foliage/street props more deliberate silhouettes. Inspect connectors and turning views as well as these four facade approaches. Keep collision routes intact and retain matched close/chase evidence.
3. **A05/A08/A09 · M05-002/M06-007:** assess the integrated rider, animations and UI with the environment at normal play speed. This environment evidence cannot certify character deformation, trick transitions or menu polish.
4. **A09/Owner · M06-004/M06-007:** run the declared Apple Silicon 1080p route, inspect frame-time outliers and transparency/shadow behavior, then obtain the owner's realistic-but-fun visual acceptance. Linux software rendering and automated route checks do not complete those gates.

The work uses original geometry and free licensed materials with no additional purchase, billing or external runtime dependency. It is a concrete improvement to the development alpha, not the final release-art signoff.
