# Compact Clyde results — DENSITY-01

18 October 2026. **Final regression admission is in progress.** The first required run is retained as rejected2097/3. Exact historical preview counts and the safe-rail fixture are now migrated; targeted actual input/preview49/0, fresh geometry373/0 and missed-input6/0 pass on committed6517d8a. The full clean rerun is running on frozen source. This report must not be read as a clean whole-game pass until the required receipt below is present.

The change puts the existing Clyde features in one smaller pocket. Bridges are 45 m apart instead of 133 m. The north quay is 170 m rather than 300 m; the south quay and rear yard are 115 m wide, replacing the 560×90 m roaming lawn. The 38 m river, real 8 m optional opening, continuous alternative crossing, native pipe dimensions and logical goal/save/encounter identities remain. Production skating forces, controls, camera, FOV and far plane are unchanged.

The quarter faces east at (−15,2,62), beside the Z69 cross-quay lane. A flush Y2 yard fixes an actual input return blocked by a 20 cm floor lip. Exact opaque boundary surfaces replace see-through guards at dry world ends. The west deck wall reaches Y12 because the former Y5 fence was below the native Y5.2 decks. Only duplicate hip/landing/ribbon display triangles are removed; their genuine support remains. The route map now joins the safe crossing to the existing yard return.

## Evidence and limits

- Independent geometry: **373/0** on the final material/layout source, including full rider-size route sweeps, pipe dimensions, raised-deck containment, exact graded prism display faces and nonvacuous coplanar overlap counterexamples. [Receipt](evidence/geometry-final-10/receipt.json).
- Support: **16,125 samples**, 8,070 route offsets and 3,084 boundary samples; zero sampled support, unmapped-route, boundary or crossing faults. The general grid intentionally includes unmapped scenery and solid occupied positions; those are not missing promised route floors. [Raw audit](evidence/support-final-06/support.json).
- Native controls: four distinct connected circuits and two raised-deck attempts are integrated into the required suite. Earlier focused 16/0 and 4/0 results remain separate from the pending aggregate. [Methods and raw traces](LINES.md).
- Deliberate mistakes: current final-source **6/0** no-Ollie bridge miss and late ledge-grind request. A real water bail loses the pending trick, preserves the earned bank and recovers on actual quay support; the late request awards no phantom grind. [Receipt](evidence/margins-04/receipt.json).
- Actual composition: all **27 final PNGs** decode/hash-verify and were independently opened. Eleven primary chase poses plus map/overview, twelve additional chase poses plus map/overview cover entries, returns, bridge crest/landings, deck and boundary corners. The corrected elevated observer settles on Y5.2 instead of the lower curve. [Review](QE-REVIEW.md), [primary](evidence/render-candidate-final/receipt.json), [detail](evidence/render-details-final/receipt.json).

The final lead-design review opened all27 images and found no new sampled blocker. It still flags quiet forward views at the quarter exit and yard-ledge exit, access-only city ports and the monolithic west wall. The yard apron has a landing/turn/return purpose; it is not evidence of dense attractions everywhere. The pipe's north end against the guard is not a second city exit. [Source-bound design verdict](../../levels/COMPACT-CLYDE-CONTRACT.md) preserves those limits; no claim that the whole map is now compact or fun follows.

The input driver uses one initial fixture then registered actions; it never sets movement/yaw/speed per tick. Its conservative braking and banks between groups establish feasibility, rather than expert flow or human enjoyment. Static frames do not certify temporal flicker, all camera extremes, final realistic graphics or discovery. Mac/DualSense, first-use and warmed ten-minute 1080p timing, listening, human feel and a refreshed native export remain open.

## Matched rendering

Final D/candidate/E: frozen original/candidate/original, ordinary Main, Balanced 1280×800, native Compatibility/llvmpipe, FOV66, far220 m. Each of 11 settled chase fixtures records 40 native frame intervals after warmup, excluding PNG readback: **1,320 measured rows** across the three batches. Settings, fixture/yaw, adapter and observer are matched; native occlusion remains OFF. The detail observer is composition evidence only.

The unchanged strict gate requires each p95 and p99 to satisfy both midpoint + peak-to-peak original-repeat noise + 5% midpoint, and 1.05× the slower original. **All 22 limits pass in all 11 views.** The independent reviewer recalculated every percentile and limit from raw rows. This is bounded retention evidence on a slow, noisy software renderer. Earlier unchanged controls also drift substantially; do not infer a stable Mac FPS gain or attribute the difference solely to the final wall colour.

Times below are milliseconds. Controls are D/E ranges; complete p50/p95/p99/max/long-frame/resource data and exact thresholds are in [the comparison](evidence/render-comparison.json). Counter deltas compare candidate with original D; D/E counter medians are identical. Reported draw/primitive work includes Compatibility shadow work, not just unique scene geometry.

| View | Candidate p50 / p95 / p99 | Original p95 range | Original p99 range | Draw delta | Primitive delta |
|---|---:|---:|---:|---:|---:|
| west-city-entry | 151.6 / 266.6 / 351.7 | 444.5–479.7 | 523.1–580.4 | -115 | -82784 |
| east-city-entry | 138.5 / 158.1 / 160.0 | 272.5–362.4 | 277.9–803.3 | -49 | -82266 |
| halfpipe-open-end | 802.4 / 896.9 / 1121.5 | 1320.1–1520.2 | 1717.8–1781.7 | +3 | -12022 |
| quarter-entry | 493.2 / 507.7 / 533.9 | 894.6–991.7 | 1213.6–1220.6 | -54 | -88572 |
| safe-bridge-mouth | 250.8 / 263.2 / 282.1 | 484.8–565.5 | 701.1–703.4 | +123 | -57560 |
| advanced-bridge-mouth | 260.7 / 284.6 / 403.1 | 512.6–699.1 | 724.2–860.2 | +33 | -59146 |
| print-yard-entry | 208.9 / 235.9 / 270.9 | 412.4–522.4 | 697.2–697.3 | -50 | -84206 |
| rear-property-boundary | 193.2 / 209.6 / 217.7 | 239.0–300.9 | 247.1–535.4 | -4 | -58487 |
| west-quay-end | 260.4 / 282.2 / 304.7 | 542.4–624.4 | 688.3–732.7 | -115 | -89962 |
| east-quay-end | 191.8 / 209.2 / 223.9 | 469.1–541.6 | 524.1–653.4 | -40 | -86416 |
| shared-city-junction | 288.2 / 428.7 / 478.8 | 627.4–804.7 | 660.5–894.5 | +113 | -65340 |

Reported texture data is unchanged in every view; buffer memory falls 476,460 bytes. No new texture/material/shader resource, light or per-frame world behavior is added. Existing `stone_light` guards, `paving` yard and `shop_navy` tall wall avoid the large close-view normal-mapped finish. Native hip/pipe materials remain. The tall wall is deliberately provisional; it needs a measured Glasgow-derived art/composition pass.

Compression increases reported draws in four sampled views (+3, +33, +113, +123) while reducing reported primitives in all eleven. Those increases are explicitly retained because the final source passes the actual matched timing and resource gates; fewer total objects alone would not justify them. Actual enabled collision falls from 363 bodies/1,907 shapes to 354/1,296; protected core 271/720 and all 12 street-bench bodies/44 boxes remain exact. No camera-distance or offscreen-gameplay trick hides the cost.

## Rejected development attempts

| Dataset | Rejection and concrete correction |
|---|---|
| `lines-01` / `geometry-final-03` | Test-only Variant inference prevented compilation; explicit typed locals correct the diagnostic. No failed assertion is removed. |
| `lines-02` | A diagonal return hit the genuine safe-bridge handrail; repeated corrective controls also issued manual gestures. Use the physically clear Z69 lane and ordinary brake-priority neutral snapshot. |
| `lines-03` | Both south returns hit the genuine Y1.8→2 floor lip. Make the real floor flush; retain hip/ribbon support and remove only duplicate display. The lip trial now waits for actual flat support. |
| `geometry-final-01` | One exact collider-name assumption failed at coincident native flat/quay support. Inspect the actual native box and moved corners, then require physical support allowing either coincident owner. |
| `margins-01` | Six assertions passed, but the ignored harness changed during execution. Reject the source-drifted receipt and rerun frozen. |
| `support-final` | Wrapper incorrectly fingerprinted a newly written output JSON as an input. Freeze actual existing code arguments at startup; corrected frozen audits pass. |
| `render-candidate` | Safe crossing appeared disconnected on the map; grey missing ground showed through guards. Extend the same yard-route metadata and replace only the exact existing guard display with opaque geometry. The old A/candidate/B timing series also fails 6/11 views. |
| `render-pbr-rejected-partial` | Interrupted expensive concrete-wall trial; no completed admission. Reuse existing cheaper finishes. |
| `render-stone-candidate` | Sampled composition passes, but strict B/stone/C half-pipe timing fails; 10/11 is insufficient. Retain exact source/patch and raw measurements. |
| `render-details-layer-rejected` | Clean receipt did not catch a semantic observer error: requested raised deck settled on a lower curve. Preserve the declared Y layer and require actual XZ/Y proximity before recapture. |
| First required full run | Preview snapshots still expected 2,132/4,040 rather than 940/2,848 triangles. A safe-bridge rail trial also still probed X−101.85 instead of translated X−28.85. The2097/3 source-stable run is rejected. Only those diagnostic expectations migrate, preserving clearance/capture/port/budget checks; targeted49/0 passes, required clean replay pending. |
| `render-plaster-candidate` / `render-plaster-details` | Bright tall wall is washed out; strict C/plaster/D timing fails 10/11 views amid strong control drift. Exact executed finish and corrected-deck still retained. |

Rejected receipts remain rejected even when their other assertions/images are useful. Raw traces are losslessly gzipped; hashes in native receipts refer to decompressed JSON. Original PNGs are copied without editing. [Evidence directory](evidence/) retains exact observers, source guards, logs, comparisons and representative rejected images.

## Required integration and continuation

The clean full-suite rerun and source/artifact audit are still pending. The first required run is retained as [rejected2097/3](evidence/ordinary-rejected-01/receipt.json). The exact two-file [migration hashes/copies](evidence/test-migrations.json) and [patch](evidence/test-migrations.patch) explain the corrected snapshots/fixture; a [49/0 native replay](evidence/fixture-migration-01/receipt.json) preserves all original geometric/port/resource/clearance/capture/ride/exit checks. Do not move another district before a clean required check, final audit and pushed handoff.

Next is [the compact park draft](../../levels/COMPACT-PARK-DRAFT.md), beginning with an engine survey and exact shared station-port contract. Its distance proof rejects pretending a short loop can connect two fixed mouths nearly160 m apart. It is a proposal, not an implemented park. [Ordered tasks](../../planning/LEVEL-DENSITY-NEXT.md) preserve owners, dependencies, acceptance and resume steps; all75 full backlog task bodies remain unchanged.
