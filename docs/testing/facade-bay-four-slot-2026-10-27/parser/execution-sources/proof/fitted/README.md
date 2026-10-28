# Fitted Exchange bay — geometry and shared texture release

Original geometry fit for the proposed live frontage in [GLASGOW-BAY-INTEGRATION](../../../docs/planning/GLASGOW-BAY-INTEGRATION.md). **Asset preparation only:** this package does not implement or certify live placement, runtime materials, collision, LOD switching, appearance or performance. No Godot or renderer was launched for this preparation. The preserved original proof remains unchanged.

| Export | Triangles | File bytes | Entry triangles moved |
|---|---:|---:|---:|
| `glasgow_bay_near.glb` | 18,392 | 954,316 | 632 |
| `glasgow_bay_mid.glb` | 3,544 | 255,808 | 440 |
| `glasgow_bay_far.glb` | 648 | 70,384 | 48 |

All levels have the same metre bounds: **X−3.25…3.25, Y0…16, Z−0.5…0.36**. They contain one mesh, four named opaque single-sided material slots, positions/normals/UV0/tangents, and indexed triangles. There are **no embedded images, texture references, PBR material payloads, physics meshes, lights, cameras or animations**. glTF needs minimal named material entries to label each surface; the integrator replaces those slots with shared runtime materials.

## The two bounded changes

1. Translate the complete entry assembly **+0.33 m in Y**: door, door glazing, stone threshold, handle and both mounts; the far handle silhouette moves with them. Threshold top becomes **Y0.53**; whole-facade bounds stay identical. The entry's silhouette, dimensions and authored UVs do not change. The independent exported-triangle comparison verifies that all remaining geometry is unchanged.
2. Correct the fitted UV mapping. The preserved original has Blender's default cube UV layer in `TEXCOORD_0` and its authored metre-scaled `FacadeUV` in `TEXCOORD_1`; its original embedded material defaulted to UV0. This fitted source removes the default layer and exports **only `FacadeUV` as `TEXCOORD_0`**, rebuilding tangents against it. The independent audit compares original UV1 with fitted UV0, including translated entry parts. This is a documented source-pipeline repair, not an alteration of the preserved proof or a claim that the old preview already used the correct scale.

## Runtime handoff

The generator writes identical GLBs to `fitted/generated/` and `game/art/assets/glasgow_bay/`. The runtime directory has exactly **four shared original 1024×1024 PNGs** in `textures/`, copied byte-for-byte from the original proof. Each GLB's exact hash, vertex formats/counts, primitive data hashes, threshold evidence and each PNG's hash are in [audit.json](audit.json); the runtime copy is `manifest.json`.

Surface order and original PBR recipe (colour factors below are **linear glTF/Blender factors**, not sRGB swatches):

| Slot / name | Shared material recipe |
|---|---|
| 0 / `01_Original_sandstone` | `sandstone_basecolor.png` as sRGB albedo, white multiplier; `sandstone_normal_opengl.png` as non-colour +Y normal, scale 1; `sandstone_orm.png` non-colour, roughness G, metallic 0 (B=0), AO R=1. |
| 1 / `02_Painted_forest_joinery` | Base factor `(0.028,0.085,0.067,1)`, roughness 0.48, metallic 0. |
| 2 / `03_Opaque_glazing` | `opaque_glazing_basecolor.png` as sRGB albedo, white multiplier, roughness 0.32, metallic 0, alpha 1/opaque. |
| 3 / `04_Aged_dark_metal` | Base factor `(0.105,0.095,0.069,1)`, roughness 0.46, metallic 0.65. |

Use the sole authored UV0, repeat sampling and mipmap/anisotropic filtering; do not re-enable triplanar coordinates. The sandstone repeat is 2 m. Resolve the runtime API's colour-space convention explicitly when converting the stated scalar factors. Share four material resources and the same four texture resources across all LODs; never copy material/texture resources for each instance. Root owns tracked Godot import configuration and will disable `meshes/generate_lods` for all three imports, so extra automatic LODs do not obscure the authored near/mid/far audit.

Keep `.gdignore` on the parent original-source directory. Runtime art sits outside that ignored source tree. Mounting, omission of old facade records, the visual wall cutout, unchanged collision/rails and native hard-LOD selection are the root's separate integration work.

## Reproduce and verify

With installed free Blender 4.3.2 and local Python, from the repository root:

```sh
blender -b --factory-startup -t 2 --python art_source/glasgow_bay/fitted/generator.py
python3 art_source/glasgow_bay/fitted/audit.py
```

The generator imports the preserved original Python to reuse its authored geometry, applying the two explicit adaptations. It never invokes the original `main()` or regenerates original files. The audit reads actual GLB accessors, checks budgets/bounds, finite data, unit orthogonal normals/tangents, triangle/UV nondegeneracy, minimal opaque slots, absence of embedded textures, identical runtime/staging outputs and original PNG/proof hashes. It compares complete triangle/UV multisets against the original exports: only the agreed entry translation is allowed. [reproducibility.json](reproducibility.json) records independent repeated-export byte hashes. `generation.log` retains actual installed-tool output, including non-blocking extension-cache/optional-Draco diagnostics if emitted; these uncompressed GLBs have no Draco dependency.

See [PROVENANCE](PROVENANCE.md) for original-content rights and exact source chain. No external asset/code, purchase, service, download or installation was used. Live import, matched rendered views, route/camera clearance, material residency, LOD behaviour and target-Mac performance remain to be verified by the integration owner.
