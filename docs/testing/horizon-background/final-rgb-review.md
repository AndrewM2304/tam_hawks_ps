# Horizon background: final RGB composition review — timing rejected

**Composition review complete; reject overall admission because the timing gate fails.** This is a new review of `.local/horizon-background/render-rgb-final-02/`; it does not replace the rejected [final-02 and components-cube-01 review](final-review.md). Both previously observed floating facades are grounded at the exact connector observer, and no additional composition blocker was found in these 37 stationary chase views. This is a bounded visual finding, not a claim that the map is finished or every possible viewpoint is repaired.

Checkpoint `41cd63a` uses one direct 512 RGB8 sky lookup and eight existing grounded building masses, including Civic Chambers. No engine or production changes were performed by this reviewer.

## Evidence coverage

All **37/37 candidate chase images**, plus `route-map.png` and `authored-overview.png`, were individually opened. The other 30 PNGs are original controls for the timing comparisons; their hashes were verified, but they are not claimed as independently reviewed visual frames.

The final receipt records HEAD `41cd63a21247b82458d1a8ca8e035e341eaf4a08`, 368 stable source inputs, exit 0, a clean log and `valid=true`, completed at `2026-10-18T19:40:03.295533+01:00`. Before/after source manifests are byte-identical. Source-manifest SHA-256: `20f6eefb6f32eea0e26be25427cd545949498ef319e67570b40af7fb4bcced59`. Receipt SHA-256: `5ea16659320c33830bb71106206640b7865beedcfbf4f2957a4ac49a4c18cec4`. Independently recomputed hashes match **69/69 PNGs** in that receipt.

Capture metadata confirms native `gl_compatibility` on llvmpipe LLVM 19.1.7, 1280 × 800, FOV approximately 66, 67 valid observations and no capture errors. The 15 original/candidate/original timing triples use 40 post-draw intervals per phase; with the other candidate views, the run contains 2,680 samples. Screenshot readback is outside those intervals.

## Actual frame findings

| Opened candidate frames | Composition finding |
| --- | --- |
| `exchange-west`, `exchange-east`, `exchange-gallery`, `exchange-quay-mouth` | Readable shop/gallery bearings and street mouths remain. The quay passage still frames the river crossing; no new visual obstruction is apparent. |
| `civic-east-gap`, `civic-west-gap`, `civic-north-terrace`, `civic-reported-gap` | Real streets remain distinguishable from fenced frontages. The reported gap retains the actual cross-street and now has a distant hill/city bearing. Preserve that street mouth. |
| `station-west`, `station-south`, `station-north`, `station-platform-axis` | Station frontage, platform/rail and connected park/city/quay bearings remain. North/south still expose broad plain footing/apron bands behind fences: closure with unfinished art. |
| `barras-east`, `barras-north`, `barras-south`, `barras-reported-gap` | Market/venue frontages remain visible. The reported slit has a continuous service back, although it is a conspicuously plain tan face. South retains a broad apron; these are not finished detailed streets. |
| `clyde-west-end`, `clyde-east-end` | Existing solid quay-end boundaries meet the shown floor; hills and bank context sit beyond. No inviting dry opening is apparent in these two samples. |
| `clyde-safe-mouth`, `clyde-south-return`, `clyde-yard-east`, `clyde-southwest-corner`, `clyde-southeast-corner` | The bridge entrance remains legible. South wall/floor/corner joins are closed in these samples, with distant context behind them. The quiet yard remains visually spare and its walls monolithic; preserve the tested clear return space during future finish work. |
| `clyde-raised-deck`, `halfpipe-city-bearing` | The corrected 1.25 m photographic brick period remains plausible beside the skater. The high wall is still repetitive and dominant; its required containment must not be reduced for appearance. No motion-shimmer acceptance comes from a still. |
| `clyde-river-east`, `clyde-river-west` | Both scenic bends continue to hide the former straight water-plane truncation. The channel reads as turning behind a bank. Pale simple banks are adequate closure direction, not completed waterfront detail. |
| `park-west-slope`, `park-north-slope`, `park-terrace-west`, `park-terrace-north` | The native terrain/path/coping remain dominant; hill and city layers give depth. There is no obvious sky seam in these samples. The distant city is visibly painted and stylized. |
| `park-city-return` | The city/station direction remains visible. Deep squared retaining/foundation faces and sparse middle ground remain abrupt; the sky does not make this a polished continuous landscape. No new dry opening is apparent in this sample. |
| `park-civic-connector` | **Both known floating lower edges are visibly repaired.** Brick continues below the left storefront to the boundary; the partial sandstone facade at the extreme right now extends down to the dark ground strip instead of ending above blue. The true promenade opening remains visible. |
| `park-northwest-corner`, `park-northeast-corner`, `park-southwest-corner`, `park-southeast-corner` | Fences/plinths meet the shown grass. Hills/city fill the distance and no inviting dry path is apparent. The jump from near park edge into pale painted valley remains cliff-like, with little middle-distance terrain; western corners expose larger painted city silhouettes. SE also exposes the squared station retaining faces. These are art limitations, not inferred collision holes. |

The connector finding specifically revisits the rider at approximately `(-52,6,-122)` looking north: the left storefront gap from final-02 and right-edge sandstone gap from components-cube-01 no longer appear there. This does not generalize into a claim that every building base is repaired from every camera angle.

The authored overview still exposes the lower panorama as tall flat curtains, and the downward-extended background masses visibly project below the model. That elevated 700 m-far overview is a diagnostic camera, not a substitute for the normal chase captures. The route map retains the existing six-area connections and compact Clyde safe↔yard return; scenic banks are not presented as new playable routes.

## Performance status and remaining work

The capture receipt is valid, but `comparison.json` reports **5 passed / 10 failed**, `timing_pass=false`, under the unchanged gate: each p95/p99 must be within the control midpoint plus repeat difference plus 5%, and no greater than 1.05 times the worse original control. The ten failing views are `exchange-east`, `station-south`, `clyde-west-end`, `park-west-slope`, `park-terrace-west`, `clyde-river-east`, `civic-reported-gap`, `barras-reported-gap`, `park-northwest-corner` and `clyde-southeast-corner`; each fails both p95 and p99 in this comparison.

Therefore the improved composition does **not** admit the feature. Preserve this valid capture and failed timing result, diagnose the remaining cost or measurement problem, and rerun the unchanged appropriate gate on frozen source after any correction. Required regression checks remain root-owned; no result is invented here.

Future art work should refine the existing plain service back, apron bands, middle-distance transition and repetitive walls within an explicit measured budget. It should not consume return clearance or expand the playable map. This review accepts neither final Glasgow-specific detail nor a finished realistic presentation.

## Limits

PNG inspection is a visual composition review only. It cannot establish temporal flicker, route traversal, fun, Mac performance, controller response or all possible camera angles. Existing physical openings and retained support must remain independently tested. Candidate allocations remain resident during appearance-off controls, and reported 3D draw counts include shadow work; this does not isolate main-view submissions or a cold memory baseline. Do not reinterpret a populated skyline or low draw/triangle count as performance acceptance.
