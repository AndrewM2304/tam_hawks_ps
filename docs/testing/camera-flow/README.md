# Forward chase, ramp orbit and airborne pose

19 October 2026, `bootstrap/m00-m01`. [Contract](CONTRACT.md), [ADR-023](../../architecture/decisions/ADR-023-ramp-camera-heading-and-framing.md), [physics source comparison](../../research/THPS-PHYSICS-COMPARISON-2026-10-19.md). Newest STATUS owns complete-suite and audit admission. Older level/side and separate world-yaw/pitch candidates are superseded.

The camera follows ordinary turns with a short lag and ignores scored trick spins. On ramps it follows the unspun local frame skyward, then makes one fixed-side 180° arc around the apex to face downward. Local normal as camera-up avoids the world-up singularity at a vertical view. Rear view retracts before collision-side fallback, using a 1.6 m useful ramp minimum (3 m elsewhere); clear ramp views immediately release obsolete side offsets. Ground arm 4.9–5.2 m, flight arm 3.6 m, FOV 64–65.95°, near 0.2/far 220. Native volume/travel/three-landmark checks remain. Reduced motion fixes speed-dependent arm/FOV.

The rider/board retains the ramp launch normal/tangent in air, with a base turn near zero vertical momentum; scored tricks compose independently. Camera uses interpolated unspun base frames. Upward ramp departures and lip jumps preserve launch velocity and use 22 m/s² air gravity, ordinary flights retain 34. Landing/support/grind/reset clears the tag. No new world geometry/resources/callbacks or external code/assets. These are owner-requested local choices, not verified THPS3 constants.

## Corrected source evidence

| Gate | Result |
|---|---|
| Focused camera and height | `focused-forward-fixed`: **44 passed/0 failed**, clean/frozen 375 inputs, 72.041 s. Actual flat turns, four air-spin presentation settings, eight natural local orbits, visibility, update continuity, height/tag reset and scale-drift interpolation seam. Counts overlap the required suite. |
| Ordinary playability | `playability-idle-pitch-02`: **43/0**, clean/frozen 375 inputs, 63.175 s. Station canopy minimum camera distance **4.913 m**, zero hidden/blocked/close samples. |
| Native A/B/A | `compare-forward-fixed`: strict p95/p99, camera quality and physical equivalence **pass**. Three ≥30 s spans, **1933 common physics rows match position and velocity exactly**, each 321.165492 m, zero bails/discontinuities. **17,931 native samples**, clean/frozen 377 inputs, 106.301 s. |
| Render intervals | Candidate p50/p95/p99 **3.463/8.021/9.670 ms**, controls 5.792/9.521/10.994 and 5.855/9.596/10.846. **One 63.907 ms interval** versus zero controls >33.333 ms remains disclosed. No long-play/stutter resolution claim. |
| Camera readability and motion | Minimum projected body axis **153.41 px**, max view step **10.10°**, max short-interval move **0.499 m**. Projections are not silhouettes; actual phase PNGs inspected separately. |
| CPU and resources | Camera-update p95/p99 **379/593 µs** versus controls 334/371 and 340/374: query work increases. Visible draw median/p95 199/1410 versus 1087/1474 and 1089/1471; triangles 47,512/645,032 versus 593,172/875,912 and 593,172/875,438. Framing changes native culling, world geometry unchanged. All phases report texture 48,782,340 B/buffer 15,502,964 B/video 64,285,304 B; not cold allocation certification. |
| Labelled actual frames | `capture-forward-fixed`: **21 PNGs**, clean/frozen 377 inputs, 16.845 s; actual approach, climb, ascent/pre-apex/first-descent/re-entry, flat return inspected. Explicit CURRENT CAMERA banner. |
| Ordinary park round trip | `approach-forward-fixed`:639.789m/114.8simulateds,17waypoints,zero bails/discontinuities/framing errors,13actual PNGs. Clean/frozen376inputs/119.334s. Root inspected spawn/park approach/connector return/end. |
| Required complete suite | `required-forward-fixed`: **2,207/0**, exit0, clean/frozen 374 receipt inputs, 1228.243s. Complete station/compact Clyde checks pass without engine errors. First final run **2205/1** is rejected for station pitch plus engine interpolation errors. Earlier 2199/0 certifies superseded level-camera source. |
| PNG/source/backlog audit | 101actual PNGs decode/hash pass;373current core inputs,75unchanged full task bodies and6historical research hashes pass preflight. Final [audit](audit.json) binds the complete required receipt and retained artifacts. |

Source-bound receipts: [complete required suite](evidence/required-forward-fixed/receipt.json) and [full log](evidence/required-forward-fixed/console.log), [focused](evidence/focused-forward-fixed/receipt.json), [playability](evidence/playability-idle-pitch-02/receipt.json), [matched native comparison](evidence/compare-forward-fixed/receipt.json) and [analysis](evidence/compare-forward-fixed/comparison.json), [ramp capture](evidence/capture-forward-fixed/receipt.json), [park round trip](evidence/approach-forward-fixed/receipt.json), [PNG decode/hash](evidence/png-audit/receipt.json). Failed first complete run: [receipt](evidence/required-forward-final/receipt.json) and [log](evidence/required-forward-final/console.log).

The first final full run exposed two genuine defects missed by ramp-only checks. Stopped supported landings retained their falling pitch, collapsing the station camera arm to 1.405 m; idle supported pitch now returns to zero. Godot interpolated root bases can contain slight scale drift; frame slerp now orthonormalizes both endpoints, avoiding invalid quaternion errors on the compact Clyde circuit. A dedicated regression covers that seam. The failed receipt/log is retained in `required-forward-final`.

A/B/A uses fresh identical scenes, identical movement source, 60 neutral ticks, 2 s active warmup and 32.2 s phases. The diagnostic window is visible/always-on-top in all phases to avoid OS occlusion suspending draw observations. Actual push/floor are recorded; cached physical W is re-emitted only if native focus clears the mapped action, with a log entry. No per-tick pose/velocity/contact forcing. Earlier mismatches remain rejected, without claiming their causes fully isolated.

Earlier unlabeled original/current controls confused live previews. New comparison titles distinguish REFERENCE/CURRENT. The banner exists only in separate graphical capture, never production HUD or timing admission. This does not close unfinished general UI work.

The admitted ramp-orbit measurements use straight natural finite-half-pipe returns. The wider MAP-03 oblique/lateral-carry, alternate-ramp and low-speed matrix remains open; these measurements do not certify every ramp approach. Native 1280×800 evidence does not certify ten-minute 1080p stutter, physical DualSense, export, all-map comfort or human fun. Central Kelvingrove bowl/half-pipe/rails/downhill links, shared ports/budgets and broader world/UI stay open. All 75 complete backlog bodies remain intact.

## Retained superseded and failed work

- Original `baseline`:2233native samples, five~79° re-entry jumps, max8.577m displacement/minimum axis4.74px; actual held W,720physics samples/five natural returns/120.740325m, zero bails.
- Initial level-camera trials01–04 fail readability/continuity. Trial05/compare03 and34/0 focused+2199/0 required improve those proxies but owner explicitly supersedes that design. Its source is in `evidence/level-camera-rejected`. Compare03 passes strict distributions with exact1933-row physics/344.296893m traces; one67.515ms candidate interval stays disclosed. It is not current admission.
- `focused-02`24/4 measured root yaw instead of the visible SkaterVisual that spins. Corrected observation preserves production behaviour. Later visibility failures (6per return trial) inspected current physics support BEFORE camera _process, rather than the interpolated displayed pose. Corrected tests run after chase update and retain the same full-body/frustum/three-ray checks. Failed logs remain.
- Reused-scene compare01/02 fail exact physical-reset equivalence (up to0.018269m); fresh identical scenes match in03. Cause remains open as CAM-QA01. Compare01 also misses one30-second span by3.12ms. Original strict timing/trace gates remain unchanged.
- Original-control columns30–34 in archived compare03 are unsupported/stale candidate-only diagnostics, unused by gates. Exact loaded observers are retained. Current observer explicitly zeroes them.
- Full-route-warmup compare04 and momentum06 stopped incomplete after native progress stalled; no admission. Current observers have independent watchdogs. The interruption cause is unverified.
- Momentum01/02 fail body-axis readability;03 has a137°/9.42m snap;04/05 improve visibility but a delayed update turns38–43°. Actual update telemetry05 shows43.21° after70.151ms, while its same-row post-draw interval is38.993ms: these clocks must not be confused. Current camera bounds its response to one60Hz step instead of spending a stalled render interval in one turn.
- `apex-01` anticipates yaw but retains upward tilt at first descent; superseded by owner’s downward-view correction. `apex-down-01` fixes tilt but still fails zoom continuity. All retained raw intervals/receipts distinguish diagnostic physical validity from camera/performance admission.

## Reproduction

Use installed official `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot` with bounded wrapper `docs/testing/horizon-background/observers/run_checked.py`. No paid service/CI/agents/background loop. Fresh output folder per run; do not edit frozen core or run competing engines.

- Required: wrapper then `./tools/check.sh`.
- Focused: `./tools/run.sh --headless --audio-driver Dummy --script docs/testing/camera-flow/observers/focused.gd`.
- Native telemetry: Compatibility/windowed1280×800/Dummy audio with `--script docs/testing/camera-flow/observers/motion.gd -- OUTPUT`.
- Matched A/B/A: same options with `--script docs/testing/camera-flow/observers/compare.gd -- OUTPUT docs/testing/camera-flow/observers/motion.gd docs/testing/camera-flow/observers/baseline_camera.gd`. Extra paths bind loaded dependencies. Fresh identical scenes/60neutral ticks/equal2sactive warmup/32.2sphases; watchdog200s.
- Current-only labelled images: same options with `--script docs/testing/camera-flow/observers/current_preview.gd -- OUTPUT docs/testing/camera-flow/observers/capture.gd docs/testing/map-flow/observers/ramp_camera.gd`;21regular/key-phase images, no timing admission from readbacks.
- Ordinary park round trip: same native options with `--script docs/testing/camera-flow/observers/current_route.gd -- OUTPUT docs/testing/map-flow/observers/approach.gd`; physical input only, no per-tick pose/velocity override.
- PNG audit: headless `docs/testing/map-flow/observers/audit_pngs.gd --` followed by every retained PNG folder. Final source/evidence/backlog binding: `python3 docs/testing/camera-flow/observers/audit.py`.
- Analyze: `python3 docs/testing/camera-flow/observers/analyze_compare.py OUTPUT`; strict timing/trace/duration/quality gates, nonzero on failure. `summarize.py` reads JSON/gzip and reports diagnostic metrics without declaring admission.

Receipts bind actual source hashes, not old dirty checkout HEAD alone. The baseline helper is our own84f camera, not decompiled franchise code. Exact loaded observers are retained; large raw telemetry is losslessly gzip-compressed. Final audit binds current core, actual images and unchanged full backlog records.
