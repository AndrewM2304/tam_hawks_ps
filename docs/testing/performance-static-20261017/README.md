# Static submission comparison — 17 October 2026

Run `./tools/static_batches_probe.sh 32`, `48` and `64`. Each accepted run captures eight identical frozen world views before batching, after batching, and after enabling native occlusion. These are real renderer draw/primitive counters and images, not FPS measurements. See each candidate's report for its exact source manifest, command, hardware, inventory and geometry checks. All three passed the independent source guard and actual renderer record checks. **Native occlusion is visually rejected**: a subsequent exact-camera off/on/off-repeat diagnostic shows missing distant wall planes. Production leaves it disabled. Counter validity is not visual acceptance.

Select **64 m batching, native occlusion off** for the current map. Batching alone changes Exchange draws 1,585→1,302, Barras 1,284→1,015, George 660→598, Central 567→591 and park south 457→420. Clyde and the two closer park views are unchanged. Larger cells submit some additional off-screen primitives. Central is a recorded regression, not a universal improvement. The combined counters below document the rejected occlusion experiment and must not be represented as shipped savings.

| View | Original draws | 32 m + culling | 48 m + culling | Rejected 64 m + culling | Original / rejected combined primitives |
| --- | ---: | ---: | ---: | ---: | ---: |
| Exchange | 1,585 | 1,565 | 1,434 | 1,288 | 809,294 / 852,202 |
| George Square | 660 | 629 | 617 | 572 | 720,870 / 753,108 |
| Central | 567 | 554 | 583 | 576 | 466,078 / 479,060 |
| Barras | 1,284 | 939 | 827 | 739 | 1,002,800 / 971,442 |
| Clyde | 154 | 154 | 154 | 154 | 149,228 / 149,228 |
| Kelvingrove | 73 | 73 | 73 | 73 | 465,538 / 465,538 |
| Park north | 54 | 54 | 54 | 54 | 462,560 / 462,560 |
| Park south | 457 | 319 | 325 | 334 | 608,816 / 603,000 |

Selected batching removes 570 original sources and creates 336 spatial batches: 234 fewer nodes/MultiMeshes. Physics stays at **351 bodies / 1,863 shapes**. The rejected native culling stage adds 23 inset occluders inside actual opaque facade boxes. Open canopies, market aisles, bridges and the Exchange portico are excluded.

All **17,742 registered instances** match as consuming multisets, including mesh, material, complete render state, world transforms and enabled color/custom channels. Authored/live renderer records agree exactly after upload warmup; before/after world transformation error is at most **0.00000190735 m**. The gate uses a 0.0001 m tolerance and exact render-state identity, rather than rounded hash identity.

The first 64 m run (`.local/static-batches-64-0UBC33`) was rejected. Its validator read eight queued west-door transforms before the first renderer upload and treated six rounded 1 mm hash-boundary changes as missing records. The repair waits for real upload and checks authored/live correspondence on both sides plus consuming before/after multisets. The rejected run is not passing evidence. No geometry or assertion was removed to pass the comparison.

The eight retained comparison PNGs show original/rejected-culling Exchange, Central, Barras and park-south views. The accepted batching-only images are retained separately below. Reports and original artifact inventories retain all 24 image names/hashes per candidate; **the other images are deliberately not retained**. `retention.json` identifies the available subset. `manifest.json` hashes the retained package. Images keep the comparison camera's old 0.05 m near plane; the separate depth-precision diagnostic tests production's 0.20 m setting. Camera settings and world-only counters differ from the normal full-game stationary profile, so those draw counts must not be substituted for one another.


## Rejected native-occlusion diagnosis

`precision/report.json` records 12 actual images, 77 unchanged inputs and all 23 occluder boxes contained within their real opaque walls. Off-repeat images are pixel-identical. Nevertheless, native culling removes distant opaque facade planes, leaving window frames against the sky. At near 0.05/0.20 m, park-south differences are 2,925/2,920 pixels; Central stays at 136 pixels. **The near-plane change does not fix this defect.**

`owner-protection/report.json` records a second bounded diagnostic, 78 stable inputs and six images: keeping only the 23 occluder-owner wall meshes immune to native occlusion reduces park differences to 364 pixels but leaves Central unchanged at 136. Owner self-culling explains much of the park hole and is not a complete repair. Production leaves native occlusion off. Next work must identify the remaining geometry using per-object visibility/ray diagnostics, then verify still and moving views before enabling it. No incomplete protection patch is installed.

The precision folder retains the two .20 m off/on full views and enlarged diagnostic crops; the owner-protection folder retains reports/hashes only. Retention files identify omitted originals. These are pixel/counter diagnoses, not performance timings. Independent batching-only inspection found no missing walls across eight views, with small opaque seam/window/trim tone changes at Exchange/Central/Barras; those stills cannot establish absence of temporal flicker.
