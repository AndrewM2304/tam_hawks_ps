# Environment fidelity asset provenance

Inspected 6 November 2026. This appendix records the material expansion before import. Downloads use ordinary public HTTPS, no payment, account, API key or hosted job.

## Included material sources

The [Poly Haven asset licence](https://polyhaven.com/license) was inspected using the web research tool. It explicitly dedicates downloadable assets under **Creative Commons CC0 1.0 Universal** and permits commercial use, modification and redistribution. The [ZC source licence](https://github.com/DaZCDude/ZCs-Spectacular-Textures/blob/a866769b0ccb5e041f8855a52223d7d1a1166125/LICENSE) and author statement are already independently inspected and retained in the main register. The complete standard dedication is retained at `third-party/zc-spectacular-textures-CC0.txt`.

| Asset | Official source and creator | Included maps | Physical tile scale |
|---|---|---|---|
| Pavement 01 | [Poly Haven](https://polyhaven.com/a/pavement_01), Rob Tuytel | 2K JPEG diffuse, OpenGL normal, packed AO/roughness/metal | **1.5m**, published on asset page |
| Sandstone Blocks 04 | [Poly Haven](https://polyhaven.com/a/sandstone_blocks_04), Rob Tuytel | 2K JPEG diffuse, OpenGL normal, packed AO/roughness/metal | **3m**, published on asset page |
| Asphalt 02 | [Poly Haven](https://polyhaven.com/a/asphalt_02), Rob Tuytel | 2K JPEG diffuse, OpenGL normal, packed AO/roughness/metal | **3m**, published on asset page |
| T_grass01 | [ZC pinned source](https://github.com/DaZCDude/ZCs-Spectacular-Textures/tree/a866769b0ccb5e041f8855a52223d7d1a1166125/textures/T_grass01), ZC / DaZCDude | Source JPEG albedo, OpenGL normal, AO | **1.5m** authored starting value; no provider measurement |
| T_wood01 | [ZC pinned source](https://github.com/DaZCDude/ZCs-Spectacular-Textures/tree/a866769b0ccb5e041f8855a52223d7d1a1166125/textures/T_wood01), ZC / DaZCDude | Source JPEG albedo, OpenGL normal, AO | **2m** authored starting value; no provider measurement |

Source images are retained unchanged. `game/art/assets/environment_pbr/manifest.json` records exact download URLs, UTC retrieval, file hashes, bytes, source dimensions and import policy. `tools/fetch_environment_materials.py` repeats the inspected subset and refuses a changed upstream file against the saved manifest. Normal maps use OpenGL +Y. Packed map red is AO, green roughness; metallic is zero for dielectric surfaces. Grass/wood scalar roughness is authored because that source supplies no roughness maps. Unused displacement and DirectX maps are excluded; geometry and collision remain original.

### Bounded photographic derivatives

Actual native review found a bright repeated patch in the paving and excessive saturation/illumination repetition in the grass. `tools/build_environment_derivatives.py` produces four replacement maps from the retained CC0 sources: a 2K paving albedo with restrained broad-luminance correction, plus 1K muted/de-lit grass albedo, tangent-normal and restrained AO. Grass uses four reflected quadrants with correct tangent-normal component signs, so the original authored 1.5m patch becomes a **3m** derivative tile without enlarging the grass blades. Paving retains the provider **1.5m** width. These replace four existing bindings; they do not add resident maps, draw families or shader samples.

`game/art/assets/environment_pbr/derived/manifest.json` records the exact recipe, Pillow/NumPy authoring versions, source identity, output bytes/dimensions/hashes and physical scale. Originals remain byte-identical and independently verifiable. `python3 tools/build_environment_derivatives.py --verify-only` rebuilds all four PNGs in memory and compares complete receipts and byte identity without network or writes. The runtime has no Python, Pillow or NumPy dependency. Asset generation uses atomic file replacement so an editor cannot import partially written pixels. This preprocessing is a bounded visual correction, not new survey evidence or a provider-certified physical measurement.

The Poly Haven API returned HTTP 403 from the execution environment; the official asset pages/licence were inspected through the available web tool and official direct downloads were accessible. ambientCG metadata and licence were inspected as candidates, but its archive download host returned HTTP 403; **no ambientCG assets are included**. No networking policy bypass was used.

## Original work

Environment shading, window interiors, river response, layout-neutral architectural detail and material integration authored in this session are project-owned original work. No Tony Hawk/other commercial game assets, level layouts, Google imagery, architectural photographs, music, logos or animation data are bundled.

## Acceptance boundary

Material source and licence verification establish lawful availability, not AAA quality. Actual close/chase captures, shader stability, ordinary regression and target-Mac performance require separate evidence. A material replacement cannot by itself close final art direction and authored set-piece acceptance.

## Declared resource and cost budget

Surface upgrade target: **zero added geometry and zero added draw families**, no extra render passes, and **at most 32 MiB additional resident texture memory** in the matched renderer. Core albedo maps import at 2048px; their normals and packed AO/roughness import at 1024px; ZC grass/wood maps import at 1024px. All use mipmapped VRAM compression. The first 2K normal candidate's imported files totalled approximately 44 MiB, above the declared ceiling. The three core normal imports are therefore reduced to 1K while preserving 2K albedo. The completed fresh native allocation control measures **32,768,403 additional bytes / 31.250384 MiB**, within the original ceiling, with unchanged 8 draws / 96 primitives on its isolated material grid. This is native allocation evidence, not acceptance from file sizes or a whole-world performance claim. Close/chase originals support bounded static quality review; complete natural-frame metadata and moving/target-Mac review remain separate. [Exact native report and evidence limits](../testing/fidelity-2026-11-06/environment/native-material-subsets/completed-subsets.json). The original window shader is admitted only through an exact-object static-batch exception, with overlays, next passes and all other shaders still excluded.

Lighting conditionally adds native SSAO and low-intensity SSIL only under Forward+, with no claim of no render cost. Renderer comparison and target-Mac acceptance own that cost. The bounded three-direction water-normal candidate has zero new textures/draws and retains derivative filtering; matched before/after river/fountain static and moving review plus cost comparison remain required before its acceptance.
