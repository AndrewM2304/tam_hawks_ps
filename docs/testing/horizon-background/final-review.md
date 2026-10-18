# Horizon background: final-02 independent composition review

**Verdict: reject this candidate overall.** The distant setting and river ends are substantially more coherent, but the park/civic connector still exposes a floating foreground building. Independently, 7 of the 15 matched timing comparisons fail the unchanged gate. Neither outcome is waived by the small geometry count.

## Evidence and scope

This is a read-only level-design review of `.local/horizon-background/render-final-02/`, completed on 18 October 2026. All **37 candidate chase PNGs**, `authored-overview.png` and `route-map.png` were individually opened. The other 30 PNGs are the original controls for 15 timing triples; this review does not claim to have independently inspected all 69 images visually.

The capture receipt binds the images to HEAD `a617000a45518228466a6acf1f64b86da081117d`, 364 unchanged source inputs, exit 0 and a clean log, completed at `2026-10-18T18:33:35.897404+01:00`. Before and after source manifests are byte-identical. Source manifest SHA-256: `42c1d6fffa9782c9410999853c85b5b311f83aa03cb0fd438226c59ead882b7c`. Receipt SHA-256: `1a7e7b096a9eb07366747a94831f1de1435f799ee9665c3e995ae1f2a9f2588e`. All 69 PNG hashes independently match that receipt.

The 67 observations comprise 37 candidate views and 30 controls. They use stationary native Compatibility/llvmpipe rendering at 1280 × 800, FOV 66 and the existing 220 m far plane. These are composition samples, not a human playthrough, motion/flicker test, proof of every boundary collision, or Mac performance certification. Earlier rejected previews remain described in [preview-review.md](preview-review.md).

## Remaining blocker: a building still floats

`park-civic-connector-candidate.png` plainly shows blue/panorama beneath the full lower edge of the left decorated facade. The fence and paved promenade do not ground that facade. This is a close foreground gap, so more skyline detail or a different sky sampling backend cannot repair it.

The actual observer is rider `(-52, 5.999067, -122)`, camera `(-52, 8.699186, -116.2)`, yaw 0 looking north, supported by `KelvingroveGeorgePromenade` at Y 6. The sign says “STATION APPROACH”; that generic facade label must not misdirect the fix to the western station entrance. Static source suggests the background frontages at X −105/−70, Z −149, base Y 6, beside the north edge of the George embankment. This is a likely cause, distinct from the directly observed visual failure.

The proposed correction—extend the existing seven background box masses downward to Y −35, retaining each footprint, roof, storefront and decoration height—is appropriate for this defect. It can ground the existing faces without adding meshes, colliders or a wall across the true promenade. Keep material scale stable and restore original mass sizes/positions when comparing appearance-off controls. This remains a **proposed fix**, not something certified by these images. Fresh connector and raised city-return captures must show that the bottom and side seams are gone.

## View-specific findings

Names below identify `*-candidate.png` files in the capture directory.

| Area and reviewed views | Keep | Remaining limit or required correction |
| --- | --- | --- |
| Exchange: `exchange-east`, `exchange-west`, `exchange-gallery`, `exchange-quay-mouth` | Facades retain the gallery/street bearings; distant layers give context through openings. | Basic frontage repetition remains. No new route obstruction is apparent in these stills; route traversal is a separate test. |
| Civic: `civic-east-gap`, `civic-west-gap`, `civic-north-terrace`, `civic-reported-gap` | The reported far opening now has a hill/city bearing. The actual cross-street mouth remains open. | Preserve that working mouth when grounding nearby scenery. Do not mistake it for a gap that should be capped. |
| Station: `station-north`, `station-south`, `station-west`, `station-platform-axis` | Ground and edge silhouettes now read as a bounded station pocket, with a distant setting. | North/south views expose broad plain grey/beige footing bands. They close the world truthfully but still look like placeholder aprons rather than occupied Glasgow streets. |
| Barras: `barras-east`, `barras-north`, `barras-south`, `barras-reported-gap` | The reported slit has backing, and the market entrance/frontages remain readable. | The backed slit is bland; the south edge has a conspicuous plain footing band. Closure is improved, while market-specific finish remains open. |
| Park principal views: `park-west-slope`, `park-north-slope`, `park-terrace-west`, `park-terrace-north` | Restrained layered hills and a low city improve depth without competing with the native slope, path and coping. | Still a stylized distant painting. These views do not establish a finished landscape or justify additional playable ground. |
| Park connections: `park-city-return`, `park-civic-connector` | City and park remain recognizable as connected destinations. | **Connector floating facade is a blocker.** City-return also exposes abrupt squared retaining/foundation drops; inspect again after the same mass-grounding correction. |
| Park corners: `park-northeast-corner`, `park-northwest-corner`, `park-southeast-corner`, `park-southwest-corner` | Existing edge fences retain a visible boundary and the horizon is populated. | The near park edge jumps abruptly into a pale painted city/valley below. Larger painted building silhouettes are especially apparent toward the western corners. This is a cliff-like composition, not yet a convincing middle distance. No collision hole is inferred from that appearance alone. |
| Clyde north edge and pipes: `clyde-west-end`, `clyde-east-end`, `clyde-raised-deck`, `halfpipe-city-bearing` | End guards visibly close the quay. The corrected **1.25 m** photographic brick period is plausible beside the skater and is a clear improvement over the rejected 8 m brick scale. | The tall wall is still repetitive and visually heavy. A still cannot accept its shimmer/flicker in motion. Retain its required containment rather than lowering it to improve the picture. |
| Clyde river: `clyde-river-east`, `clyde-river-west` | Both scenic bends interrupt the former exposed straight water-plane termination. The river now appears to continue around a bank. Bending both ends south avoids invading the actual park ground to the west. | Distant banks are plain and pale; acceptable as a low-cost closure direction, not a completed Clyde waterfront. No extra viaduct or new playable extension is needed to solve the observed cut. |
| Clyde south: `clyde-safe-mouth`, `clyde-south-return`, `clyde-yard-east`, `clyde-southeast-corner`, `clyde-southwest-corner` | The safe bridge mouth is legible. South walls meet the shown floor and corner joins; no dry opening is apparent in these five views. Skyline layers sit behind the bounded yard. | Yard walls are monolithic and the quiet return space remains visually spare. Preserve the tested approach/return clearance; subsequent art should refine existing masses rather than scatter new obstacles. |

The authored overview makes the panorama's lower buildings read as very tall flat curtains around the whole model. It is useful for spotting that projection limit, but it is not a player camera and must not substitute for the park corner observations. The route map retains the compact Clyde safe↔yard return and the existing city/park connections; scenery has not been presented as a new playable route.

## Performance rejection and next admission

Reading the frozen `comparison.json` gives **8 passed / 7 failed** under the existing p95/p99 gate:

| Failed view | Failing percentile(s) |
| --- | --- |
| `exchange-east` | p95, p99 |
| `station-south` | p99 |
| `clyde-west-end` | p95, p99 |
| `park-terrace-west` | p99 |
| `barras-reported-gap` | p99 |
| `park-northeast-corner` | p95, p99 |
| `clyde-southeast-corner` | p95 |

Root is isolating sky and near-mesh cost before choosing a backend correction. This review does not attribute all slowdown to the panorama: some views add primitives even when their draw count is unchanged. Reducing mathematical sky sampling cost may help, but only fresh measurements can establish that.

Retain these rejected images and receipts. After grounding the background masses and any rendering change, capture the same observer set on stable source; explicitly recheck the connector, city-return, four park corners, both river axes, corrected wall scale and genuine street mouths. Repeat the unchanged matched timing gate and required regression checks. Accept only what those new results support. Glasgow-specific frontage finish, middle-distance polish, motion shimmer, human route enjoyment and target Mac/controller acceptance remain separate open work.

## Provisional correction review: components-cube-01

Three exact candidate images in `.local/horizon-background/components-cube-01/` were subsequently opened: `park-civic-connector`, `park-city-return` and `clyde-river-east`. Their hashes match that run's receipt. The run completed at `2026-10-18T18:55:28.934788+01:00`, with 368 byte-identical before/after source inputs; guard SHA-256 `029e35cfacb2aeb4d81bec79fe942c993b1a43eae6f554d9fe4532933524a12f`. This is a different source candidate from final-02 even though its recorded HEAD is still `a617000a45518228466a6acf1f64b86da081117d`.

**This run is also rejected:** receipt exit 1, `clean_log=false`, `valid=false`. The engine log records a nonexistent `Image.get_image_from_mipmap` call and a failed 6 MiB face-data check. Root identified the latter as the helper misinterpreting GPU readback memory and is correcting/calibrating the helper before a new series. The logged source-direction oracle and native geometry checks passed, including seven original masses reaching Y −35, unchanged footprints/roofs and protected openings. Those individual passes do not make the overall receipt valid, establish performance acceptance or waive fresh evidence.

The three stills support only these provisional composition findings:

- **Connector left facade:** brick now continues below the original storefront to the visible boundary. The large floating lower edge identified in final-02 is visibly repaired at this exact observer. Roof and storefront bearing remain fixed.
- **Connector right edge:** a partial sandstone facade at the extreme right still has blue/panorama beneath its lower edge, approximately image X 1190–1279, Y 310, above the dark strip near Y 390. This smaller but visible foreground gap needs inspection of its actual building/mass owner; it may lie outside the seven tagged background masses. The whole connector cannot yet be called grounded.
- **City-return:** the squared retaining/foundation drops remain essentially the same. The correction does not obstruct the visible approach, but it has not turned this join into a polished continuous urban landscape.
- **River-east:** the bank bend still conceals the former straight rectangular water end. The changed sky backend retains the relevant distant composition in this sample; this is not a review of every cubemap seam, park corner, river-west or moving camera.

Preserve the rejected run and its images. Correct the remaining visible frontage gap, fix the helper and establish the next valid frozen capture/timing receipt before updating any admission status. The final-02 failure history above remains unchanged.
