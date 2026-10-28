# Reduced near geometry with the original four materials

This source-only M05-001 / M06-004 / M06-007 experiment follows the exact next
edit in `docs/planning/FACADE-COST-NEXT.md`. It preserves the original four opaque
material slots and original map/UV semantics while replacing only near LOD
multi-segment rounding with one-segment chamfers. It does not alter live assets.

Generate only during the orchestrator's exclusive engine window:

```sh
blender -b --factory-startup -t 2 --python art_source/glasgow_bay/reduced_four_slot/generator.py -- --allow-generate
```

Use `--output /absolute/disposable/path` for independent factory-startup repeat
exports. The generator requires the unchanged original `../generator.py`, four
original maps and preserved proof files. It generates no textures or renders.

The declared exact geometry targets are 9,864 / 3,544 / 648 triangles and
246 / 142 / 54 authored parts for near / mid / far, four named surfaces, original
6.5 × 16 × 0.86 m bounds and fitted entry threshold Y0.53 m. Generation assertions
are prerequisites; an independent decoded-GLB audit owns actual acceptance.

Each export directory contains the three GLBs, `generation.json` and a
deterministic `part-triangles.json.gz`. The latter retains every actual pre-join
part triangle in game XYZ and glTF UV0 coordinates. It permits an independent
decoder to bind all part claims to the joined GLB's full triangle union, rather
than accepting the generator's counts or macro bounds alone. The report records
all preserved input hashes and original map hashes.

No import-memory, appearance, rendering-time, full-city or target-Mac result
follows from successful geometry generation. The original facade's failed live
timing and the two-slot atlas's paint/mip defects remain recorded. See
`PROVENANCE.md` for source and licensing scope.

## Completed offline export and independent audit

Two Blender 4.3.2 factory-startup exports complete in 7.536 s and 7.083 s. Their
three GLBs, actual part-triangle payload and generation report are byte-identical;
all 61 preserved source/asset/receipt inputs retain their hashes.

| LOD | Triangles | Parts | Bytes | SHA256 |
| --- | ---: | ---: | ---: | --- |
| Near | 9,864 | 246 | 595,768 | `67c0ebfbe88f83ddb0108e9c1ba6c861766905c641ed5c72bff102c4d87f8001` |
| Mid | 3,544 | 142 | 255,832 | `481f8ed518be457a7df00ba720aec75e2dc81351a91b90c2b208c2e370ed7d0c` |
| Far | 648 | 54 | 70,408 | `01347133a605228272dfaa8afefd38dd849e1df183707670b9466f9ff24d64d0` |

The independent standard-library GLB decoder passes in 0.647 s. Every near
material/position/authored-UV triangle matches the preserved reduced two-surface
geometry, while every decoded mid/far position, normal, tangent, UV and index
array matches the original fitted four-slot asset exactly. Actual per-part
triangle unions bind all 246 / 142 / 54 parts to the exported GLBs and match
their preserved dimensions, envelopes and triangle counts. Four slot names,
0.53 m threshold, finite unit/orthogonal normals and tangents, nondegenerate
geometry/UVs and absence of embedded textures/extensions pass. These are offline
structural checks, without rendered or live-performance acceptance.

Both raw export logs retain the installed Blender exporter's optional-library
diagnostic: `ERROR Draco mesh compression is not available ... libextern_draco.so`.
Draco compression is not requested or used. Both exports complete normally and
the independent decoder confirms ordinary uncompressed buffers without a Draco
extension. The logs are not described as marker-free.

The separate `preview/` recipes complete the source-bound four-way comparison of
the fitted reference, this reduced four-slot export and the existing compressed
and lossless two-slot atlas approaches. [Exact native evidence and scoped visual
review](../../../docs/testing/facade-bay-four-slot-2026-10-27/README.md) retain
32 scene PNGs, 34 imported mip PNGs, 44 native LOD/hysteresis samples and all
77 unchanged execution inputs. Actual original/reduced map data are both
3,495,320 bytes. The bounded isolated appearance/resource result supports a new
live diagnostic; it does not admit live frame times or alter normal play.

The original proof reference is the immutable commit
`98311cba78944d1828d1cb528be0293273d9c3b5`. The independent audit's `--reference`
must contain exactly that preserved 61-file tree, without this new variant.
Use a separate scratch authoring tree for repeat exports. Reproduction commands
are in the evidence record; audit receipts remain unchanged by this prose.
