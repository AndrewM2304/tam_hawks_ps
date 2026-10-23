**Historical ef0eb9f checkpoint:** these results certify the recorded flat-ollie source. The subsequent local named-grind candidate changes the source; newest [STATUS](../../STATUS.md) owns its fresh admission.

# Flat ollie correction and complete trick audit

23 October 2026. Control: `de6505d`. This packet follows the owner's rejection of excessive flat pop and request for front-foot-first motion and a complete trick-family audit. [Audit](../../research/TRICK-STYLE-AUDIT-2026-10-23.md), [tracked implementation order](../../planning/TRICK-FIDELITY-2026-10-23.md), [ADR-028](../../architecture/decisions/ADR-028-flat-ollie-and-foot-sequence.md). Final required regression passes **2314/0**, clean/frozen; source/artifact audit verifies the recorded source and original frames. Fully isolated rendering, independent QE and owner/hardware/feel acceptance remain open. [STATUS](../../STATUS.md) owns the current checkpoint.

## Change and reference boundary

Separate ordinary ground/rail impulses (tap7.2/full9m/s) from deliberate ramp/lip impulses (8/13). Gravity, carried horizontal momentum, collision, scoring and quiet ordinary-jump camera are retained. The original short board-pitch curve raises the front sole first, then lets the rear foot follow as the deck levels; flip/grab poses take precedence. Falls cannot invent a pop pose, and support/bail/reset clears it. These are local measured values and original analytic animation, not recovered THPS3 constants or skeletal curves.

The original THPS3 PS2 manual distinguishes ground Ollie from quarter-pipe Air and establishes trick families. The pinned THPS1 HandleJump reconstruction helps identify support/charge/animation branches but cannot establish THPS3 timing. No external code, clips, models or manual imagery is bundled. The source receipt records exact hashes and uncertainty.

Budget: no new meshes, surfaces, primitives, materials, imported textures, collision bodies/shapes, physics queries or per-frame construction. Native rendering admission uses actual matched input/settings, intentional different trajectories, p50/p95/p99, long frames, pose/global physics CPU, draws/primitives, static and render memory. It does not infer FPS from geometry or certify long-play stutter.

## Initial results and retained negatives

`focused-01`:71/0 (flat19/ramp7/limbs45); `controls-01`:73/0 (camera/turn/ordinary response). Actual stationary tap/full peaks0.835/1.277m, airtime0.433/0.533s. Moving peaks0.829/1.271m. Early front sole leads0.169–0.189m and subsequently levels within contact tolerances, with preserved XZ momentum. Ramp8/13 gates and quiet-camera gates pass.

`compare-01`: strict native A/B/A passes with five charged jumps each and zero bails/framing errors. Old peaks2.601m, candidate~1.27m. Frame p50/p95/p99 ms4.046/6.446/7.381 →4.104/6.667/7.394 →4.131/6.447/7.297; no>33.333ms frames. Full distributions/resources and raw samples are retained. Later final-source receipts supersede these initial source bindings.

`capture-01` is rejected: native samples saw the0.189m front lead, but the coroutine captured after the brief leading stage. Fix the observer to freeze at the actual third airborne physics sample, then read back frames; do not alter production motion or lower the threshold. `capture-02` passes2/0 and saves20original PNGs. Chase uses production camera; profile views explicitly place/restore it, and paused readbacks are excluded from timing. Root inspected charged front-lead and rear-level profile frames.

`grind-01` is rejected: old early tap no longer reaches the existing Exchange rail. `grind-02` passes16/0 using a deliberate24-frame charge on the same real approach, preserving clearance/capture/score/recovery criteria. `ramp-capture-01` passes1/0 with21original PNGs and~6.247m rise. Nothing weakens ramp pop to repair flat height.

The first full run is retained with every failure and its frozen source. Its obsolete schedules need explicit migration: bounded new release velocity, actual clip-end timing for a fresh second flip, rail request relative to real eligibility, charged real Central gap approach and charged cat rail transfers at the same takeoff points. Route geometry, gap triggers, score/capture ordering, collision gates and production behavior must not be changed merely to pass these fixtures. Final targeted and complete results follow when verified.

## Reproduction and limits

Use installed native Godot4.6.3 (`/Applications/Godot.app/Contents/MacOS/Godot`), Compatibility Metal/OpenGL,1280×800/balanced/Dummy audio, one engine at a time. `docs/testing/horizon-background/observers/run_checked.py` records exact commands, before/after source manifests, counts, exit status, log checks and monotonic duration. Observers under this packet retain baseline source with only preload redirects. `analyze_compare.py` keeps the existing strict two-control envelope and<=1.05×worse-control p95/p99 gates; capture readbacks never count as timing evidence. `archive.py` retains raw data/receipts and unmodified native PNGs, with large JSON compressed losslessly. `audit.py` verifies final loaded source, all24catalog IDs,75unchanged complete backlog bodies and actual PNG hashes/dimensions.

Named grind styles, wallrides, wallies, head-on wall plants, predictive landing assist and other inventoried gaps remain planned. Existing reverts and forgiving yaw landings are not evidence of those missing systems. Automated/root checks are distinct from independent QE, owner feel/anatomy, physical DualSense, exports, sustained target performance and final art acceptance.

The retained first full run finished2,288/26 on382stable inputs (1,346.514monotonic seconds). In addition to old timing assumptions, a yard endpoint capture corrected1.08467m in one tick: unchanged radius plus current-step travel can exceed the line's existing<1m continuity gate. Test a deliberate closer input request and retain that gate; record the broad capture-margin limitation for the style pass rather than claiming it vanished globally. Deck containment itself passed (150real wall contacts, no void/bail/extra Ollie); its additional old peak>=6.8m absolute-height witness is incompatible with the new1.27m rise above5.2m and needs the independently bounded new rise instead. The two bridge checks share the old91.8m release schedule; test93m supported release before the real94m edge, without moving decks/triggers.

Final compact02 passes12/0: two additional supported yard-charge ticks plus a closer request preserve the same line/5000bank and reduce its maximum native step to0.490616m, without changing the general capture envelope. Both bridge checks now use supported93m release, and the deck witness bounds the new charged height6.35–6.65m above the unchanged5.2m deck. Cat-probe02 passes15/0: the first capture's synthetic release must be sampled before a new charge press; same-tick release+press produced a7.2m/s hop and recaptured A. One real intervening tick restores full-charge A→B→C,1050bank,0bails and earned payoff, with all input state retained in raw observations.

Controls02 is rejected at72/1: reduced-mode body angle measured18.121° across coroutine polls while the gate explicitly promises per-physics-tick<12°. Move that observation to a contiguous native post-physics sampler, retaining the12°gate, >0.99body-normal bound and all camera/framing checks. No production ramp/camera changes. Final focused03 passes71/0; controls03 passes73/0, each mode records220contiguous native ramp-air samples and8.241691°maximum step. Source-bound native/full repeats supersede earlier loaded-test bindings. Failed fixture01(239/8), cat-probe01(7/8), compact01(9/3) and exact loaded source remain retained, not passing admission.


## Final-source visual review

Actual native profile frames: [front foot/nose lifts first](evidence/capture-03/charged-front-lead-profile.png), then [rear foot follows and deck levels](evidence/capture-03/charged-rear-level-profile.png). Profiles are explicitly placed diagnostic views; production chase captures and quiet-camera measurements remain separate. Root inspected both final frames. Their visible pose supports ordering/contact, not final human animation/art acceptance.

Strict native compare02 and03 are retained/rejected for p99 ceiling failures (9.636>9.463ms and9.461>8.637ms). Two predeclared consecutive fresh comparisons04/05 pass both unchanged strict p95/p99 gates with five real jumps each and0bails/framing errors. No constants, input schedule or thresholds changed between them. The monitored repetitions include per-second read-only system process records: only one diagnostic renderer is launched, but an idle pre-existing Godot front end and background desktop/speech/analysis CPU bursts are present. Do not claim a fully isolated-rendering or sustained-stutter acceptance. Exact distributions, failed and passing comparisons and system-load.jsonl stay in the packet; no apps/services were stopped.


| Frozen timing phase | Frame p50 / p95 / p99 ms | Pose CPU p95 / p99 µs | Frames>33.333ms |
|---|---|---|---|
| compare-04 / original-before | 4.200 / 5.771 / 8.234 | 43 / 47 | 0 |
| compare-04 / candidate | 4.258 / 5.832 / 8.496 | 43 / 46 | 0 |
| compare-04 / original-after | 4.288 / 6.193 / 10.151 | 45 / 51 | 0 |
| compare-05 / original-before | 4.175 / 6.024 / 10.280 | 46 / 50 | 0 |
| compare-05 / candidate | 4.211 / 5.872 / 8.200 | 44 / 48 | 0 |
| compare-05 / original-after | 4.214 / 5.959 / 9.400 | 45 / 50 | 0 |

All six phases retain15,431,804buffer/52,408,664texture/67,840,468video bytes. Raw draws, primitives, static-memory and global-physics distributions are in each comparison JSON; identical render-memory totals do not imply identical views, physics or stutter resolution. Candidate captures measure0.836/1.277m tap/full,0.189m front-foot lead, then<0.000001m sole-height difference. Ordinary camera vertical span0.00038/0.04219m remains under the existing0.1m limit. Deliberate ramp capture retains16.762m/s launch and6.24656m rise,0bails/discontinuities.


Final required02: **2314/0**, 382 unchanged receipt inputs, 1338.721 monotonic seconds; recorded London `2026-10-23T12:51:54.075151+01:00` → `2026-10-23T13:54:03.354054+01:00`. [Exact command/counts/source receipt](evidence/required-02/receipt.json), [source/artifact audit](audit.json). PNG decoder passes **46/0**, validating every retained original PNG at1280×800 with matching SHA256. All24catalog IDs and75byte-identical complete backlog bodies are checked. Receipt `git_head` is the control checkout before the local source commit; before/after hashes bind the tested working tree, not an assertion that de6505d already contained the correction.
