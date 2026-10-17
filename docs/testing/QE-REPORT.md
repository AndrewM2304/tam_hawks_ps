# Integrated QE report — 17 October 2026

Current slice: **Exchange/gallery entrance terrace and west shopfront seating edge**, retaining the six-area world, ten canonical career goals, three side challenges, existing movement and saves. Godot 4.6.3, Compatibility, Linux. **Ordinary regression passes 1,155/0**, including the 22 Exchange checks, with exit 0 and clean engine/script scans. The corrected **22-frame rendered set passes bounded independent review**. Native handoff remains pending. The prior Barras/Clyde 1,106/0 checkpoint remains historical evidence for its source.

## Current behavioral evidence

| Area | Independent result |
|---|---|
| Gallery terrace and joins | Actual input traverses the side-bank loop, front return to the stair apron and permanent gallery bypass in both directions. The real bank contacts and approximately 0.65 m elevation change pass, with zero bails/stalls and clear finite chase samples. |
| West seating edge | Actual input traverses the 0.45 m bank loop and default-spine bypass in both directions. The route crosses the bank before the continuous optional seat begins, then returns around it; zero bails/stalls or camera obstruction. |
| Protected access | The gallery bypass rides both X±22 spines and the Z−22 crossline. Separate short physical trips preserve the station south port and cone/east corridor in both directions. The current ordinary aggregate also passes the broader terrain, career and three-encounter checks. |
| Portico collision | Actual rays hit all eight exposed column shafts above their bases. A rider-sized capsule sweep clears the terrace crossing in front of the columns; real gallery motion and chase sampling also pass. |
| Real new combo | A controlled push/brake approach climbs 0.274 m of the new bank before the ollie, captures `Grind_Ledge_GalleryEntrance` once, follows its south bend, rail-ollies, performs Kickflip/Melon Grab and lands into a fresh Manual. Ordinary scoring banks **5,000 exactly once**, with zero bails and **324 clear/visible camera samples**. |
| Initial input diagnosis | The first full-push approach passed the short ledge while still high in its uphill ollie: 19 checks passed and three combo assertions failed. An isolated real-input probe established the cause. Normal braking to approximately 6.5 m/s produces the reliable capture and continuation; production geometry/controller/capture/scoring rules remain unchanged. |

[EXCHANGE-PLACE](EXCHANGE-PLACE.md) gives route timings, exact fixture/driver API, the [first diagnostic](logs/exchange-initial-input-diagnostic.log) and [final focused log](logs/exchange-focused.log). Focused log SHA-256: `d7bc4a83af231316fb72bef8129ba74635e579a92a03f372e1b3c866f9ba627e`. Focused execution uses `--fixed-fps 60`; the same 22 checks are included in the ordinary 1,155-check aggregate, not added to it.

Each physical route starts from one declared supported fixture. Grounded heading is directly aimed; subsequent position, speed, velocity, capture, trick and bank are produced by normal inputs/physics. The combo's observed sequence is `Ollie → Rail Grind → Ollie → Kickflip → Melon Grab → Manual`, yielding `(100 + 200 + 50 + 300 + 250 + 100) × 5`. No subsequent gallery-stair gap or fountain grand line is claimed. Persistence is disabled throughout. These results establish idealized feasibility rather than natural turning, unaided difficulty or enjoyment.

## Current rendered evidence

The corrected [22-frame set](screenshots/exchange-gallery/README.md), recorded **18:39:01 UTC**, passes independent visual and receipt review. All **164 source hashes**, **22 PNG hashes** and **1280×800 dimensions** match; the manifest reports 44 authored routes and no changed inputs. Manifest SHA-256: `8c6122729aad2fda9c7c609fb6c53dda36accec62c41e3cef0571f7484b9e39e`. Actual stages 18–22 reproduce the real 5,000-point bank, 324 clear camera samples and zero bails/stalls. Seats, column bases, doorway contact and chase exits show no separate clipping or gameplay-state blocker in these views.

The [first diagnostic set](screenshots/exchange-gallery-diagnostics/README.md) exposed an identity defect: a tall generic facade overwhelmed the gallery portico. Geometry corrected the body and closed roof locally and moved its name to the front frieze while retaining the footprint, terrain, columns and ledge paths. Matched spawn/frontage/overview views now show the lower pale gallery as a distinct building with its portico and readable name. The unchanged 22 focused checks pass on that corrected source; their output matches the prior focused pass byte for byte. The capture runner reuses `ExchangeTests.combo_fixture` and `drive_ledge_combo`, including `bank_ascent`, `captured`, `rail_air`, `manual` and `banked`, and fingerprints all test dependencies. Static contextual placements and authored inspection cameras remain explicitly labelled.

Review covered the gallery door/terrace and facade foundations, all eight column bases, both seating edges and material joins, ordinary spawn and descent/chase exits, the map, and actual bank/ledge/manual/banked states. Every changed image was inspected; the remaining images match the already inspected first set byte for byte. This accepts the bounded place correction and documented gameplay views. Final realistic art and human first-minute quality remain separate acceptance gates.

## Ordinary regression and native handoff

Current `./tools/check.sh` completed at **18:50:38 UTC** with **1,155 passed, 0 failed**, exit 0, clean import and engine/script scans. The [source receipt](logs/exchange-gallery-source.json) records **162 unchanged game/test/tool inputs**; independent rehash finds no mismatch. The [ordinary log](logs/exchange-gallery-final.log) SHA-256 is `0313be0238a3288f4f75ce4f94e3afb85020ec4d201051c817eb53552076399a`.

The continuous input-driven career circuit completes all ten goals at **75.22 simulated seconds**, returns at **88.02 seconds** after **1,199.39 m**, and banks **20,000** with a **3,200** best combo, zero bails and zero stalled frames. Mo/Rae/Mairi encounter checks and six cross-district combo directions also pass. The new gallery line repeats **5,000 once with 324 clear camera samples** under ordinary execution. Direct grounded heading remains an explicit driver idealization; these are physical feasibility results, not human-play or frame-time claims.

**Native pending:** current clean exports, archive/resource audit and bounded Linux startup await their own receipts. No previous native pass is substituted.

The prior Barras/Clyde checkpoint remains in [MARKET-DELIVERY](MARKET-DELIVERY.md), the [1,106-check log](logs/barras-clyde-final.log), [24-image evidence](screenshots/barras-clyde/README.md) and [native receipts](native-barras-clyde/README.md). Its clean runtime was `2a7d20c51559907b0ca30a995d842dcc683ff320`; its actual career run completed all goals at 75.22 seconds and returned at 88.02 after 1,199.40 m. Those artifacts are historical after the Exchange changes. The earlier bin-drum/soft-cat checkpoint remains in [BIN-CATS](BIN-CATS.md). The stationary six-area [software diagnostic](performance/six-area-20261017/README.md) does not establish current moving-route or target-Mac performance.

## Open acceptance gates

Real Mac launch/Gatekeeper, wired/Bluetooth DualSense, offline Mac save relaunch, Apple Silicon moving-route frame times, audible listening, local dialogue review, unaided discovery and final realistic/fun art remain open. Broader facade repetition, ground wear/joins, horizon density and character animation remain part of the explicit cleanup gate. [LEAD-DESIGN-REVIEW](../levels/LEAD-DESIGN-REVIEW.md) retains design priorities and human criteria. Further skating mechanics and river/park encounter ideas remain planned. No purchases, paid APIs, hosted CI, public release or unattended jobs are part of this verification.
