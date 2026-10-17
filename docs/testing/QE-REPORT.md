# Integrated QE report — 17 October 2026

Current scope: six connected city/river/park areas, nonlinear local routes, adult rider, original Mo busker encounter, existing skating/career/persistence/UI/audio. Engine is Godot 4.6.3, Compatibility renderer, Linux. **Current aggregate: `./tools/check.sh` passed 955 assertions, 0 failures, exit 0 with clean import/engine/script logs.** A final editor import also passed after the last display-label boundary correction; corrected source-stable captures verify those local labels. Runtime/package source identity is recorded in STATUS. The earlier 871/0 ordinary run is a foundation checkpoint preceding the last layout/encounter changes, not the current acceptance result.

## Reproduce

`./tools/check.sh` imports the project, runs `tests/run_tests.gd`, fails nonzero for assertion failures and scans engine/script logs. Script fixtures disable player-profile writes and use isolated `.local` paths. The complete 955-check log and final import log are retained in `docs/testing/logs/glasgow-nonlinear-final.log` and `glasgow-nonlinear-import.log`; `.local/extension-candidate-check.log` is the original working copy. The source and native artifact identities belong in STATUS/EXPORT. A preceding candidate run was deliberately stopped when actual rendered place defects required geometry correction; it is not a passing or failed final regression.

## Current feature evidence

| Area | Verified behavior and meaningful limits |
|---|---|
| Existing skating/combo | Push/brake/steer, buffered/coyote ollie, flip/grab/spin, slope momentum and collision-adjusted air velocity; rail alignment/clearance/balance, manual/revert rules, one 0.35-second bank window, repeated-trick degradation, meter-gated specials and bounded overtime remain covered by the integrated runner. |
| City topography | Real 0/2/4/6 m terraces, 5 m station platform, 1.5 m market loading level, actual slope contacts and upward/downward travel. Capsule sweeps and local probes verify support; authored route data alone is insufficient. |
| Nonlinear routes | Station undercroft below a genuinely suspended deck; bent Merchant Close; lower service court with two escape banks; park cutback/rejoin; angled Clyde yard. All seven new continuous branches are physically driven both ways with zero stalls/bails in the final focused probe. |
| Stacked access | Independent rays distinguish lower floor Y2, deck underside Y4.6 and upper floor Y5; actual rider traversal proves the lower corridor. Height-aware support query is separate from the highest-terrain query. |
| Curved bank/hip | Actual sampled 35-degree low masonry bank with varied surface normals, crest and descent. This proves a shallow supported transition, not vert/bowl/lip mechanics. |
| Fountain/river/park | Real push/ollie acquires curved fountain coping and banks after release; real bridge jump awards once; a missed jump emits one water bail, preserves earned bank and returns to supported quay. The complete park loop reaches the 17 m hill and returns without stalls/bails. |
| New local combo | Real ground push → ollie → yard ledge grind → rail ollie → flip/grab → fresh manual → bank. The focused test passes 3/0, banks exactly 5,000 once and has no bail; no score/trick/position injection after the fixture start. |
| Mo encounter | Focused suite passes 30/0: deliberate mapped interaction, actual 1,950-point ollie/flip/grab success, 1,800-point spin replay, repeat-win protection, pending-combo rejection, pause, actual manual-balance bail, restart, career expiry and free-skate isolation. Pure rule/edge tests are distinguished from physical success. |
| Busker audio | Original bounded PCM has finite/non-clipped non-silent samples and a controlled loop seam. Spatial range, actual master×ambience gains/mutes and pause/resume are checked. Dummy-driver structural checks do not establish audible quality or a Glasgow accent. |
| Career/save | Ten goal IDs, four required city districts, thresholds, records/unlocks and schema remain stable. The unchanged physical all-ten-goal circuit passes 13/0 after the close-mouth seam fix. No side-encounter save/score injection; future/corrupt-save protections remain covered. |
| UI/navigation | Actual map/offer/active/result pages, live input prompts, persistent challenge timer/types, nested focus/pause ownership, scaled text and save warnings. The busker challenge is a warm-up that can be completed with a stationary three-family line; depth/discovery remain human review. |
| Rider/assets | Verified CC0 cropped adult head/scalp/hands, original native garments/board/shoes, action/contact inspection and silent 7.4-second fixed-timestep preview. Source/licence hashes and native-pack resource probes are required; realistic-art and human motion acceptance remain open. |

The final focused correction probe is **30/0** for nonlinear/outdoor transit; the separate local combo is **3/0**. The integrated topography module now contains **60 assertions**, and encounter integration contains **30**. See [TOPOGRAPHY](TOPOGRAPHY.md), [CAREER-ROUTES](CAREER-ROUTES.md), [RIDER-REALISM](RIDER-REALISM.md) and the [design review](../levels/LEAD-DESIGN-REVIEW.md) for exact routes, observed fixes and reproduction.

Automated route drivers directly aim grounded heading and use controlled initial fixtures. They prove feasible collision/scoring routes, not human turning difficulty, discovery, fun or target performance. The final ordinary aggregate career circuit reports 75.20 simulated seconds to all ten goals and 88.00 to return, 1,199.52 m, 20,000 points/3,200 best combo and zero bails/stalls. Preserve ordinary-versus-fixed scheduling labels in CAREER-ROUTES; final aggregate logs are authoritative for its actual run.

## Rendering and review

`./tools/level_design_capture.sh --private-display` renders real production chase/overview/map/NPC frames at 1280×800, persistence disabled. Its source-fingerprint guard rejects changed/incomplete batches. It positions ordinary inspection fixtures, while Mo's active/result frames use real mapped inputs and an actual bank. The isolated medium actor shot hides only the unrelated rider visual and records that fact. A saved PNG alone is not evidence of physical route completion.

Initial nonlinear review found exposed Merchant Close voids, a border crossing the new park fork, an abrupt park verge, grass intruding into paving and inaccurate local HUD names. The initial four diagnostic images/manifest are retained in [level-redesign-diagnostics](screenshots/level-redesign-diagnostics/README.md). Corrections add a supported lower court/escape banks, matching fork openings, blended embankments and local surface cleanups. The corrected 21-frame set passed its source guard and independent lead/geometry/root review. Its manifest SHA-256 is `f0b3a30987a7731371ebb4b74102751dfbdfd192194a7db7b574669ba5b0674b` (28 routes, six checkpoints, 98 source inputs). The lead accepted this development slice and explicitly kept final-art/human-fun acceptance open.

Full realistic finish remains open: broad core courts and some long approaches, repeated facade/paving treatment, static background locals, finer materials, scenery and animation weight. No full vert/lip/wallride/skitch/traffic or changing-route system is enabled; those have explicit prototype tickets. Four additional local encounter ideas are Planned. This slice does not certify the whole game or close M06-007.

## Native and hardware boundary

Final native packages must be regenerated from a clean checked runtime, with isolated main/voice/texture/four-anatomical-mesh probes, complete notice/provenance copies, ZIP CRC and executable architecture checks. `tools/native_smoke.sh` provides bounded normal Linux startup with isolated profiles. EXPORT records the actual outcome; old a99f993 packages are historical until replaced.

Actual Mac launch, wired/Bluetooth DualSense, offline Mac save relaunch, Apple Silicon frame times, audible listening, Glasgow dialogue review, human line discovery and final owner visual/fun acceptance remain unverified. Local software rendering and automated input do not close those gates. No purchases, paid APIs, hosted CI or public release are involved.
