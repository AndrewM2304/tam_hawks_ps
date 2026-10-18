# Recording-driven rendering repair — 18 October 2026

**The confirmed surface flicker is repaired. All new backdrop drafts remain disabled in normal play after failing performance gates.** The original 56.69-second Mac recording is visual evidence, not task instructions. Owner frames and the recording stay local/ignored; retained visual examples are actual game diagnostics generated here. No new playable area, paid service or unattended work.

## Findings and repair

| Recording time (approximate) | Observation | Response |
| --- | --- | --- |
| 14–22 s | Thin terrain edges/sky behind ironwork; dark retained walls | Background coverage needs work. The dark retained asphalt sides are authored geometry, not evidence of a faulty custom shader. |
| 30–33 s | Station canopy axis ends in detached background blocks and gaps | A shallow original service-back draft is saved, but remains disabled after failed cost admission. |
| 46–54 s | Abrupt river/quay ends and isolated distant building backs | Original bank/warehouse context drafts are saved, but remain disabled after failed cost admission. |
| 50.7–51.5 s | Large dark angular patches alternate across paving between adjacent frames | **Confirmed coplanar road/quay triangles.** Both asphalt approaches draw at Y2 over Y2 paving. |

Matched full-world controls hold camera/light/materials fixed and change only the road visual. Normal and shadow-disabled controls both reproduce the bands; hiding the road visual removes them. Original overlap areas are **160 m² west / 208 m² east**. Visible Clyde road strips now stop at Z55. Complete original collision meshes, grade, support queries, audio metadata and routes remain intact.

Independent review also found **99.817594 m²** of flat MerchantClose0 asphalt over CentralStationFloor paving. Only its displayed top triangles are clipped at Z−42. Original retaining prisms, side walls and authored height data remain intact. No surface offset, depth bias or global shader/shadow change masks the cause.

For four matched Clyde diagnostic poses, repaired paving versus the road-hidden control differs by at most **1/255 RGB** in the declared paving region; mean difference is 0.0040–0.0045. Original-to-repaired mean difference is 1.73–5.70. These are bounded Linux reproductions, not claims that every Mac rendering defect is fixed. [Actual before/after diagnostic montage](rendering-repair/surface-diagnosis.jpg).

## Boundary drafts and rejection

The original drafts add vertical retaining skirts with no fake top floor, shallow station building backs, riverbank/warehouse context beyond quay-end fences and park hillsides behind the existing retained edge. Independent tests check actual arrays, materials and projected vertical segments against five protected river/route openings. Existing **351 bodies / 1,863 shapes / 48 routes** remain strict checks.

| Draft | Rendering design | Result |
| --- | --- | --- |
| [V1](rendering-repair/rejected-v1/measurements.json) | Six chunks, 4,040 triangles, lit stone/vertex-colour materials | All six p95 and five p99 gates fail; focused geometry also catches two civic-corner skirts entering a protected opening. Rejected. |
| [V2](rendering-repair/rejected-v2/measurements.json) | One unshaded material, baked directional colour, offending skirts removed: 4,032 triangles | Two p95 and one p99 gates fail. Rejected. |
| [V3](rendering-repair/rejected-v3/audit.json) | Retaining faces merged into native regional bounds: 4,036 triangles | Culling improves: far-east/west additions fall to 1,072/1,882 submitted triangles from 2,936/2,908. Station/park still fail both percentile gates. Rejected. |
| [V4](rendering-repair/rejected-v4/audit.json) | Only two Clyde chunks constructed: 2,132 triangles, one unshaded texture-free material | Five of twelve percentile gates fail across the six observers. Park submits zero added draws/triangles. Rejected for normal play. |

**Normal startup constructs none of these meshes.** Their exact source snapshots, raw timings, receipts and preview code remain saved. Polygon/draw savings cannot override failed frame-spike gates. There is no Mac FPS improvement claim. Previous footage uses the existing world; the held facade/atlas prototypes are separate and remain disabled.

The measured series use the actual Linux Compatibility renderer, fixed 1280×800 observers, 2×MSAA, 45m shadows, 220m camera range, native frame scheduling and 24 measured post-draw frames per A/B/A phase, followed by eight perturbed Clyde poses and road-hidden controls. Screenshot readbacks stay outside samples. No other engine/render job overlaps. The gate requires **both p95 and p99** to be at most control midpoint + absolute control difference + 5% midpoint, and at most 1.05× the worse control.

Controls show large host variation, so no slowdown is attributed to the target Mac. This host exposes five CPUs under a four-CPU cgroup quota; CPU throttling is observed. A limited Mesa-thread calibration is an **unexecuted next experiment**, not a reason to discard failed results. These short, world-only stationary samples do not certify moving gameplay or target hardware. Memory counters keep resources resident throughout visibility A/B/A; they do not isolate candidate allocation. V1 has a manual source freeze/post-run snapshot; V2–V4 have automatic before/after fingerprints, 318 stable inputs each and all 28 PNG hashes. Full rejected-draft PNGs remain ignored locally; [V3](rendering-repair/rejected-v3/preview.jpg) and [V4](rendering-repair/rejected-v4/preview.jpg) previews are explicitly resized diagnostic montages. Current ordinary source captures are retained in full. The initial surface [recipe](rendering-repair/surface-recipe.json) and [pixel differences](rendering-repair/surface-pixel-differences.json) state exact observer/ROI limits, including the Merchant montage’s backdrop-context change.

## Validation and publication

- Independent focused surface/backdrop/default-OFF checks: **33 passed, 0 failed**. They detect original overlap counterexamples using collision/prism geometry, reject displayed overlap, inspect actual materials/meshes/nodes, protect openings and verify ordinary startup constructs no candidate. Explicit preview and held-context fixtures remain checked separately.
- Required `./tools/check.sh`: **1,772 passed / 0 failed**, exit 0, clean logs, **318 unchanged inputs** on pushed runtime `4cd1f35`; 870.60 s, 10:33:48–10:48:19 Europe/London. [Full log](logs/rendering-repair-ordinary.log), [source receipt](logs/rendering-repair-source.json). Career replay: all ten goals at 75.98 s, circuit finished at 89.03 s, zero bails, 19,900 banked / 3,200 best combo; all six cross-district combo directions pass.
- Ordinary source/title/player capture: **19 frames / 0 failures**, **257 unchanged inputs**, all 19 PNGs independently decoded/hash-verified. All 257 source overlaps match the full suite; all 318 current inputs still match. [Manifest](rendering-repair/ordinary-play/manifest.json), [final audit](rendering-repair/final-audit.json). Root reviewed actual title/spawn/Clyde views. Manifest SHA256 `0dbd794154c8917b843db3ac6961e009b42844e0259f4181876702e0421b1588`.
- All **75 original full backlog records are byte-identical**: [audit](rendering-repair/backlog-preservation.json).

Commands: `./tools/check.sh`; `./tools/playability_capture.sh --private-display --publish-dir docs/testing/rendering-repair/ordinary-play`; `./tools/render_repair_capture.sh` explicitly enables the rejected diagnostic preview. The latter imports first, records game/assets/test/tool/project hashes before/after, rejects source drift/error logs and verifies 28 PNG hashes/sizes. Source capture has its own source guard. The validated publish directory preserves previous evidence. Previous native packages are historical after these runtime changes; updated source uses `tools/run.sh`.

## Exact continuation

1. Preserve the enabled surface repairs and the default-OFF backdrop/facade decisions. Do not expand the map or alter collision/controls/goals/saves to conceal a rendering issue.
2. Calibrate the local rendering harness with unchanged controls before another art admission. Inspect CPU quota/throttling, record any `LP_NUM_THREADS=2` diagnostic configuration explicitly, declare a larger sample minimum before collection, and keep all raw frames/long-frame counts/source receipts. This experiment has not been run. Linux software timings cannot close the actual Apple M5 ten-minute 1080p gate.
3. Reduce the retained backdrop’s cost while preserving real openings and the original 220m skyline. Near under-fence gaps need local retaining context; a distant painted sky alone cannot explain those edges. No textured horizon plane may cover the Clyde. Compare exact selected geometry in **all six** observers, because Clyde meshes can also appear from station viewpoints.
4. Preview requires an explicit World metadata flag set **before** it enters the tree: `render_repair_backdrop_preview=true`; optional `render_repair_full_context=true` selects the saved six-chunk draft. Ordinary Main sets neither. The builder is idempotent: a second call does not toggle an existing live backdrop.
5. After accepted cost/visual evidence, resume measured Glasgow frontage/hero/UI fidelity. Final realistic art/UI, real keyboard/DualSense feel, Mac performance and wider human off-route review remain open. All owners, priorities, dependencies, acceptance criteria and test strategies persist in BACKLOG/ACTIVE_WORK; no unattended job is scheduled.
