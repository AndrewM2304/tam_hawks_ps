# Current handoff — trick fidelity, 23 October 2026

**Tam Hawks Pro Skater**, Godot 4.6.3 Compatibility, local feature branch `work`.
The owner's current request is polished trick sets and combinations inspired by
classic arcade skating. The implementation now has **27 selectable variants**:
eight flips, eight grabs, nine grinds/slides and two manuals, alongside the two
original specials, spins, reverts and named gaps. The existing map, street
handling, ten career goals, save identities and three side challenges are retained.
No purchase, dependency, native export or remote publication was made.

## Completed implementation

- Directional/cardinal/diagonal input uses existing remapped actions, bounded
  flick memory, immediate opposite-axis cancellation and takeoff-safe cue clearing.
  Neutral defaults remain Kickflip, Melon Grab and Rail Grind.
- Fresh repeated flips fit ordinary flat ollie airtime; simultaneous flip/grab
  input executes in order. Grabs hold/release, flips catch before another entry,
  late incomplete flips bail once, and completed spins/reverts change stance.
- Rail styles have actual distinct deck/truck support and rider counter-rotation.
  Nose Manual has opposite pitch/balance posture. A deliberate held press in the
  last 0.18 seconds of airtime can buffer a manual into actual supported landing.
- Stable trick IDs own repetition, bounded grab/grind holds add base points
  without new entries/multipliers/deadline extension, and HUD receipts show
  entries, repeats, holds, stance, banked tricks and lost pending value.
- The remapping-aware Trick Guide exposes every direction. Actual rendered review
  found/fixed truncated instructions; wrapped-line/height/scroll checks now cover
  small resolution and large interface size. Grabs use authored palm contacts;
  shove/varial catches preserve feet through persistent deck yaw and later actions.
- Mo recognizes shove/slide families; Mairi accepts Nose Manual. Long-rail tests
  reconstruct entry/repeat/hold earnings independently. The cat-return fixture
  now clears a reproduced physical plinth obstruction before the visible payoff;
  its original distance/frustum/animation and bounded return assertions remain.

Contracts: [ADR-014](architecture/decisions/ADR-014-trick-fidelity.md),
[interfaces](architecture/interfaces.md), [plan/ownership](planning/TRICK-FIDELITY.md),
[verification](testing/TRICK-FIDELITY.md) and [player guide](PLAYER-GUIDE.md).
Existing M01/M02/M04/M05/M06 task records are updated in BACKLOG; all 75 IDs remain.

## Final source-bound verification

`./tools/check.sh` exits **0**, **1,489 passed / 0 failed**, with clean import and
test error scans. The scripted aggregate now uses `--fixed-fps 60`, matching the
project's 60 Hz collision physics while preventing skipped input-driver
observations under real-time CPU catch-up. No production timing or assertion was
weakened. The [cadence probe](testing/logs/trick-cadence-probe.gd.txt) reproduces
the scheduling mechanism; this test mode is not a performance measurement.

- [Full suite](testing/logs/trick-fidelity-final.log), SHA-256
  `a35736dd429884a77af1236c5f0a92804d27897eed1a40bb137ff91cdfa19d14`.
- [Import](testing/logs/trick-fidelity-import.log), SHA-256
  `9572934ad4d57fbab2c09b2c82f3821584fba7ba71d7e1dec5055bc7fa531f3f`.
- [Source/check receipt](testing/logs/trick-fidelity-source.json) binds commands,
  harness hash, logs and all 190 capture inputs to the unchanged checkout.
- `python3 tools/source_launch_smoke.py --output .local/trick-fidelity-cold-verified`
  passes cold source, normal title branch **44/0**, warm launch and broken-copy
  refusal/restoration with **186 unchanged inputs**. [Receipt](testing/source-launch-trick-fidelity/README.md),
  SHA-256 `113dabd42ec413522810f3c3706ba83cba2a3ff83142dbe9d9504ac9813e1eec`.
- `./tools/trick_fidelity_capture.sh --private-display` passes **36 actual PNGs,
  63 checks / 0 failures**, **190 unchanged inputs**, PNG CRC/row integrity and
  independent source rehash. [Reviewed images](testing/screenshots/trick-fidelity/README.md),
  manifest `d0e683b95d75de51b4ff79365c4d36376291b793f7d14804da10cd398b25361f`.

Actual captured flat Ollie→Heelflip→Kickflip banks **2,100**; ordered
flip→grab→buffered Manual banks **3,000**. The final aggregate preserves the
original exact **3,200** air/manual/air line and all six district-crossing combo
assertions; reverse Barras banks 3,200 connected with zero bails. The career
circuit reaches all ten goals at 75.98 simulated seconds and finishes at 89.03s,
19,900 banked, 3,200 best combo, zero bails and nine short stall samples. These
are scripted feasibility results, not human feel/performance acceptance.

## Resume and remaining gates

Play current source with `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/run.sh`
on Mac, or open `project.godot` in Godot 4.6.3. Old downloaded native/source
archives predate this implementation. Use the committed source; refresh unsigned
exports and their provenance separately when required.

1. Replay the new Trick Guide and actual flat/rail/manual/revert/special lines on
   Mac keyboard and physical wired/Bluetooth DualSense. Human response, continuous
   animation, final realistic art, listening and Apple Silicon frame times remain
   open M01-007/M02-008/M05/M06 acceptance gates. No final commercial-game parity
   or hardware certification is claimed.
2. Continue authorized polish/fixes from specific play feedback without routine
   approvals. Preserve the current input/score/hold/catch contracts, exact route
   assertions and source-bound evidence; rerun affected checks after changes.
3. Full transition/vert/lip (M02-011), wallride (M02-012), skitch/traffic assessment
   (M02-013) and a charge-release ollie input follow-up under M01-003 remain
   separate unimplemented work. No new area is added by this trick pass. Keep
   their existing research/acceptance criteria explicit.

The previous hardening handoff and packages below are historical evidence only.

---

# Historical handoff — 17 October 2026

**Tam Hawks Pro Skater**, Godot 4.6.3 Compatibility development alpha, feature branch `bootstrap/m00-m01`. The owner’s latest Mac play launches without errors but reports excessive coasting, messy shaders and buggy UI. Per that direction, this slice pauses map expansion and hardens the existing hills, rendering and HUD. The previous no-skater/cold-import, wall-camera and floor-support defects now have bounded repairs. Latest `./tools/check.sh` passes **1,264/0**; the normal-scene capture has **19 frames / 0 failures**, bound to the Compatibility renderer. The reverse Exchange→Barras combo regression now passes after signed slope gravity/rollback was added. Exact logs and image manifest are below. Human Mac/controller feel, target-hardware performance and final realistic-art/UI acceptance remain open. The previous **1,155/0** and `00da63a` packages certify older source only.

The owner authorizes ready work without recurring routine approval. No purchases, paid APIs, billing, hosted CI, infrastructure or unattended jobs. All **75 complete task records** remain in [BACKLOG](planning/BACKLOG.md); [ACTIVE_WORK](planning/ACTIVE_WORK.md), [RESUME](planning/RESUME.md), [interfaces](architecture/interfaces.md) and [ADR-012](architecture/decisions/ADR-012-source-launch-and-playability-repair.md) preserve implementation contracts and exact next actions. Final realistic art, human skating feel and hardware acceptance remain open.

The tested gameplay/evidence checkpoint **`86d286c512fc3e0a541ececfc970b28401f80f7f`** is pushed to `origin/bootstrap/m00-m01`; the remote ref was verified. The saved cloud startup draft points to that checkpoint and awaits review/publication in environment settings.

## Run and resume

Read `AGENTS.md`, this file, BACKLOG/ACTIVE_WORK/RESUME and ADR-007 through **013**. Preserve later edits in this checkout; no worktree is needed. The owner’s existing Mac command stays the same:

```sh
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/run.sh
```

The launcher now prepares local class discovery and imported assets automatically before ordinary play. Its receipt is `.local/source-import.log`; a failed import stops launch with an actionable message. Opening `project.godot` in free Godot 4.6.3 and pressing F5 remains supported. [PLAYER-GUIDE](PLAYER-GUIDE.md) covers keyboard/controller bindings and the three side challenges.

`./tools/check.sh` runs the ordinary regression. `python3 tools/source_launch_smoke.py` verifies a cold copied project, normal title-to-play, warm launch and refusal of a deliberately broken copied script. `./tools/export.sh` builds unsigned local Linux/macOS packages with verified free official templates; [EXPORT](testing/EXPORT.md) separates packaging from hardware acceptance. The current 19-frame normal-play render recipe is `./tools/playability_capture.sh --private-display`; the earlier 22-view Exchange recipe and clips remain historical evidence.

The cloud environment uses the installed free engine and task-local caches. Its saved setup draft describes this 75-task source workflow; no dependency, secret or paid service was added. Publishing an environment draft is unnecessary for source development.

## Repairs and preserved scope

- **Source startup:** a fresh source copy reproduces the Mac `GrindLine`, missing imported OBJ, `Anatomy.new()` and subsequent Nil errors. Asset preparation repairs the cause without hiding actor failures behind animation guards. Cold and warm unmodified Main now start cleanly; the real title-to-play wrapper verifies all four complete animated actors.
- **Third-person chase:** a 0.25m camera sphere, board/chest/head visibility checks, alternative side views and a delayed return behind the rider replace the single chest ray. The former shop-wall fixture cropped the body in 45/60 samples at a 1.042m arm; repaired focused checks keep the complete rider and board in view during natural turns, that wall case, station low ceiling and gallery columns. Camera sensitivity now affects camera response alone.
- **Skating response:** push acceleration, maximum speed, braking, takeoff and score rules are preserved. Ordinary coasting now uses stronger speed-dependent resistance; isolated actual input measures 15→**5.974m/s after three seconds**, near-rest in **6.917s / 40.200m**, versus 12.740m/s and 19.70s / 148.374m before. Ground carving eases into its turn; airborne correction is limited to 0.50rad/s rather than inheriting full ground steering. Full vert, slope gravity/rollback and charge-release ollies remain separate Planned work.
- **Current physics response:** existing floor contact now contributes **0.28g** of gravity along the board's signed tangent, capped to **±15m/s**. Symmetric coast lets rollback stop without reversing sign. A real 20° bank test rolls **0.511m** downhill in one second and ends at **−1.020m/s**, still supported. The formerly failing reverse Exchange→Barras route now banks connected; no new transition, terrain or area was added. This is a measured starting tune, not a claim of exact commercial-game feel.
- **Rendering and HUD:** Compatibility shaders use broad stable grass variation and softer teal water waves/highlights; ACES tone mapping restores contrast on pale stone. The transient event card is narrower and left-aligned so it leaves the center skating line clear; labels and speed/cue wording were enlarged/clarified. This stabilizes the existing output but does not yet make the broad park grass realistic or close final art/UI acceptance.
- **Supported exploration:** four six-metre-wide graded north-gallery/south-quay closes replace reproduced holes at X±12. Eight real-input trips and lateral support rays pass; **48 routes** now include those four connections. Foundation seams and service shoulders join adjacent plates. **58 visible ironwork/masonry boundaries** guard finite dry edges while retaining actual district mouths and intended river hazards. Market canvas collision matches the visible canopy. Park taper continuity and ground queries now follow actual terrain triangles; visible Clyde water receives its existing safe-quay recovery behavior.
- **Preserved game:** six connected areas with 0–17m terrain, original Barrowland tube sign, skate-through Barras and Mairi’s parcel delivery, South Portland-inspired Clyde bridge/Carlton Place-inspired frontage, gallery portico/terraces, station undercroft/high route, Merchant Close and park/fountain coping. Mo’s guitar line and Rae’s bin drummer with two fabric dancing cats remain alongside ten career goals, combos, saves, settings and local audio.

The helpers are original code using native Godot queries. Existing pinned source/licence research informed the handling review; no upstream assets, implementation or tuning profile were imported in this repair. Glasgow remains compressed authored geography. Final facade, material, horizon, animation and UI cleanup remains mandatory under M05-001/M06-007.

## Current evidence

**Reproduction and focused checks:** [PLAYABILITY-REPAIR](testing/PLAYABILITY-REPAIR.md) preserves actual before failures and ordinary-input contracts. The final normal-scene run passes **44/0**, exit 0, with clean engine/script logs. Its aggregate contribution is 43 because the extra normal-title-branch check applies only without `--script`. Checks include full rider/Mo/Rae/Mairi construction, actual menu activation, pause/restart/career, three resolutions, natural push/left/right curves, unassisted coast, tight cameras, eight close traversals, two actual boundary stops/turnbacks and six roof support contacts. This is bounded scripted evidence, not human enjoyment or target performance.

**Fresh source:** [source-launch receipt](testing/source-launch-playability/README.md), **21:09:36–21:10:14 UTC**, records four accepted phases and 174 unchanged game/test/project/launcher inputs against the latest physics/UI source. Cold/warm ordinary Main exit 0; the actual normal-title wrapper passes 44/0. A deliberate syntax error only in the disposable copy produces the expected refusal/exit 1, then the file is restored. Receipt SHA-256 `32ee0efc25169ba797868fb969b30b2db2cbc320e3750d3d7582982b73b50113`. Linux headless verification does not establish a repaired Mac replay.

**Handling:** [SKATE-RESPONSE](testing/SKATE-RESPONSE.md) records the measured baseline, signed coast/slope response, **32** pure helper checks, **23** takeoff checks and the actual rollback trace. The integrated route suite checks hill travel and combo continuity without forcing player position/velocity during movement.

**Ordinary suite:** `./tools/check.sh` completed exit **0**, reporting **1,264 passed / 0 failed**. The full captured log is [ordinary-hardening-final.log](testing/logs/ordinary-hardening-final.log), SHA-256 `b40322eba5f689341ea9c3820c8236bab9ed2eeafd7dc43348258649d35012e5`; clean import log is [ordinary-hardening-import.log](testing/logs/ordinary-hardening-import.log), SHA-256 `9572934ad4d57fbab2c09b2c82f3821584fba7ba71d7e1dec5055bc7fa531f3f`. All six tested Exchange→grade combo routes remain connected, including the formerly failing reverse Barras route (5.92s, 3,200 banked, zero bails). The 89.03s input-driven career loop completes all ten goals, returns to spawn and records zero bails.

**Rendered evidence:** [playability-repair capture](testing/screenshots/playability-repair/README.md) has 19 actual frames from the normal title branch, zero failures, no profile writes and stable source across the capture; the manifest hash is `f63cd1c720f9db9138314106fa9d0ed22532be6da04d92c535f4d6886e357238`. Review covers the normal spawn, movement, coast/stop, wall/undercroft/gallery camera, four closes, park taper/boundary, route map, Barras and Clyde. OpenGL/llvmpipe software output is not Mac GPU or final visual acceptance.

**Remaining verification:** replay on the owner's Mac and judge steering, uphill carry, coast, UI and Compatibility-shader output; continue graphics/UI cleanup against M05-001/M06-007 without adding areas. Refresh local native exports/audits after the tested source is committed. Human challenge discovery/fun/listening and Apple Silicon performance remain separate gates.

## Exact next work

1. Replay this tested source on the owner’s Mac using the existing `GODOT_BIN=... ./tools/run.sh` command. Judge release speed, level-ground push/brake, uphill carry/rollback, turning, UI readability and shader stability. Linux/llvmpipe does not close Mac acceptance.
2. Continue **M01-002/003/007 and M05-001/M06-007** on the current map: use the human play response to adjust coast/acceleration/slope/steering together, and refine existing grass/water, facades, rider and HUD. Keep the actual normal-scene render and focused regression evidence source-bound. Do not add areas during this hardening slice.
3. After the next tested source checkpoint, refresh unsigned local exports and provenance/resource audits; keep Mac launch, offline persistence, controller comfort and Apple Silicon performance separate from cross-export evidence.
4. **Defer M02-011/012/013, M03-015, M04-008/011** until current street skating and presentation are accepted. Transition/vert, wallride and new river/park encounters must not displace the owner-prioritized hardening work.
5. **M01-007/M02-008/M04-006/M05/M06-004–006:** replay on the owner’s actual Mac keyboard and wired/Bluetooth DualSense, offline save relaunch/reconnect, listening and Apple Silicon moving-route frame times. Human challenge discovery/fun and local tone remain open; Linux checks/cross-exports cannot close these gates.

## Historical evidence and artifacts

The prior Exchange/gallery clean runtime **`00da63a29990c0839cf15d4c9a34edc2fc167122`** passed **1,155/0**, 22 focused checks, 22 rendered views and audited local exports/startup. Its handoff commit is **`6ff294a7423dc581632a361390eb32830e9787c6`**. Exact previous identities remain in [EXCHANGE-PLACE](testing/EXCHANGE-PLACE.md), [ordinary receipt](testing/logs/exchange-gallery-source.json), [images](testing/screenshots/exchange-gallery/README.md) and [native receipts](testing/native-exchange-gallery/README.md). Its guided career circuit completed all ten goals at 75.22 simulated seconds, returning at 88.02s after 1,199.39m, 20,000 banked, 3,200 best combo and zero bails/stalls. These are older-source results after this repair.

Earlier Barras/Clyde and corrected bin-cat evidence remains in its own dated folders. [Imported Linux native baseline images](testing/screenshots/playability-diagnostics/README.md) show a visible rider in the earlier packed game, distinguishing it from the cold-source launch failure. Neither historical MP4 is current repair footage or a performance result.

Final source archives identify the committed handoff in the ZIP comment and are checked for complete CRC, exact tracked-file list and every file’s Git blob hash. `/workspace/TamHawks-downloads-SHA256SUMS.txt` records convenience package/source hashes and labels old clips historical. Local downloads/builds/caches are regenerable after environment replacement. No public release, remote issue or PR was created; the repository has no `main`/PR base. Work stays on the authorized [feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01).
