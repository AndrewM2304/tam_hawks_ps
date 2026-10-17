# Independent QE report — 17 October 2026

Owner: A09 QE. Scope: M01 gameplay, measured takeoff fixes, trick definitions and first playable M02 rail integration. Latest result: **260 assertions passed, 0 failed** using Godot `4.6.3.stable.official.7d41c59c4` on the Linux cloud machine. The tested slice is suitable for the next human playtest; this is not M01 hardware/feel acceptance or a release certification.

## Reproduce

From the repository root:

```sh
./tools/setup.sh
./tools/check.sh
```

The final integrated `tools/check.sh` invocation returned exit code 0 and printed `RESULT: 260 passed, 0 failed`. It imported the project successfully, ran `tests/run_tests.gd`, and checked both logs for engine/script errors. Generated evidence is `.local/import.log` and `.local/tests.log`; these files are intentionally ignored and can be recreated. `tools/run.sh` supplies writable XDG directories. No external testing framework, paid service, hosted CI or downloaded test dependency is involved.

The standalone runner exits 1 when an assertion fails, uses deferred initialization, and reports explicit counts. It instantiates the production main script, uses real physics frames, and sends action input through the Godot input system. UI routing checks inject key and standard gamepad button events. These are synthetic inputs, not evidence of a connected physical device.

## Coverage and evidence

| Area | Verified behavior |
|---|---|
| Score session | Empty state; half/quarter repeat degradation; distinct-trick multiplier; cap; pending preview; bank exactly once; best combo; per-combo degradation reset; bail loss; full run reset |
| Scene and bindings | Production world/skater/camera creation; visible geometry and static bodies; all 13 actions registered with keyboard and gamepad bindings; spawn contract; location text |
| Floor and ramps | Spawn floor at Y=0; stable floor settling; all four ramps expose raised collision surfaces and top normals below 15°; each ramp has visible mesh geometry; four boundary collision rays |
| Route traversal | Actual push-driven central approach climbs the ramp, clears its crest and lands; the tenement return route also climbs, clears and lands |
| Basic skating | Forward acceleration; heading stability; braking; steering; ollie ascent; disabled controls prevent movement and tricks |
| Tricks and landing | Held ollie does not automatically jump again; held flip/grab award once per jump; exactly one clean landing transition; pending combo banks through main signals; resting does not duplicate awards |
| Spins | Sustained right spin registers one Backside 180; its points bank in the same combo as the ollie; equal opposing spins cancel net rotation without a rotation award |
| Bail recovery | Forced out-of-world fall returns to spawn, drops pending combo and preserves previously banked score |
| Run lifecycle | Active countdown; timer/physics pause; resume; unlimited free skate; grounded expiry; finished control gate; restart position and score; fresh 120-second timer |
| Overtime | Active aerial combo gets landing grace; clean landing banks before run ends; a deliberately stalled airborne combo cannot survive past the bounded grace period |
| Event routing | Escape pauses/resumes; synthetic standard Options button pauses; R restarts directly from pause |

The runner intentionally checks outcomes, not only whether methods return successfully. Route tests inspect achieved height, final position and grounded state. Trick tests observe real player signals and banked production scores.

## Reuse follow-up: isolated rail helper

The original gameplay baseline had 94 assertions. `tests/rail_geometry_tests.gd` adds 42 independent assertions for the adapted MIT `GrindLine`: straight/bent/sloped paths, closest points, full 3D tangents, signed reverse travel, endpoint clamps, translated/rotated/nonuniformly-scaled authoring, input snapshots, explicit/inferred kinds, and empty/single/duplicate/non-finite data.

The first focused run reported **40 passed, 2 failed**, with Godot duplicate-geometry errors. The two issues were an out-of-range bent-rail tangent falling back to the endpoint chord, and duplicate points reaching the engine bake/sample path. Production now clamps the tangent distance before finite-difference sampling and removes consecutive duplicate vertices before baking. The assertions were not weakened. Focused rerun: **42 passed, 0 failed**. Final `tools/check.sh`: **136 passed, 0 failed**, exit 0; no scanned engine/script errors.

A09 independently reviewed the fixes. This verifies the isolated helper under Godot 4.6.3, not the entire upstream 4.7.2 game or complete grinding gameplay. Source, licence, changes and limits are in `docs/research/SKATING_REUSE.md`. The helper integration adds no active player/world/UI behavior. After the title correction to Tam Hawks, the orchestrator reran the full check successfully (136 passed, 0 failed, exit 0), regenerated all three captures and inspected the renamed HUD and menu. No new gameplay acceptance is inferred from that rename check.

## Momentum and first playable rail follow-up

M01-008 independently reproduced uphill/flat takeoff boosts, unintended downhill damping and restored horizontal motion after removing an airborne collision wall. The same real-physics regressions passed after the controller preserved collision-adjusted planar momentum and used capped actual surface travel. [TAKEOFF-MOMENTUM.md](TAKEOFF-MOMENTUM.md) records diagnostic fixtures, exact before/after values and 21 durable assertions.

M02-001 adds the documented state/input contract and validated trick catalog, with 27 checks for valid/malformed definitions, unknown IDs, illegal transitions, defensive copies and score compatibility. Future manual/revert/special entries do not enable those mechanics.

M02-002 integrates the reused geometry helper with original ride state, two authored rails, L/R2 input, balance UI, capsule clearance sweeps and one-entry scoring. `tests/grind_ride_tests.gd` has 41 checks for capture bounds, nearest/obstructed candidates, reverse/sloped/curved travel, speed/friction/end handling and balance. `tests/grinding_tests.gd` adds 19 production-scene checks for input, travel/release/ollie/end, pause, combo preservation/banking, obstruction, bail, reset and overtime. One additional structure check verifies the new input action.

A09's independent review found that the first integration still admitted new tricks during overtime despite ADR-006. Production now gates fresh trick/spin/capture/rail-ollie inputs at timer expiry while letting existing combos release and land. `tests/grind_regression_tests.gd` adds 15 passing assertions for an actual from-rest push→ollie→descending rail catch, a newly inserted rail obstruction causing exactly one bail, and overtime admission/earned-score resolution. These checks use the production scene and physical frames; they do not replace the hardware trial.

All previous 136 assertions remain; the added groups total 124. Final integrated command results are recorded at the top of this report and in STATUS. No failed assertion was weakened to obtain a pass. [GRINDING.md](GRINDING.md) records exact tuning, controls, fixture/capture routes and remaining acceptance.

## Defects and limits

No failing automated cases remain in the tested slice. QE did not edit production behavior to achieve these results. This is limited evidence, not proof that all untested routes, inputs or edge cases work.

The following require separate evidence before milestone acceptance:

- Physical DualSense on the target Mac, including wired/Bluetooth mappings, reconnect behavior and button glyphs.
- macOS/Apple Silicon executable/export, actual launch, permissions and target-machine frame times. Linux physics assertions do not establish 60 fps at 1080p on a Mac.
- Human skating feel, turn comfort, jump timing, camera behavior across the whole level, legibility during motion, and the desire to replay.
- Full traversal of the north and warm-up banks, every ledge/rail prop and extreme-speed/corner contacts. Current automated passage coverage is the central and tenement routes; all four ramps have collision-normal checks.
- Input buffering/coyote-time edge boundaries, camera obstruction recovery, and longer randomized regression runs. These are useful next test additions when related behavior changes.

Rendered-frame evidence belongs in the rendering record below and `docs/STATUS.md`; headless execution alone cannot certify the visual result. Manuals, reverts, missions, progression, saves, audio, multiple districts and cone interaction remain roadmap work. First grinds have local evidence; physical feel and full M02 acceptance remain open.

## Rendering record

`./tools/capture.sh` produced four real 1280×800 Compatibility-renderer frames using Mesa llvmpipe software OpenGL on a temporary Xorg dummy display; every capture returned 0 and the script exited 0. The orchestrator reviewed all four, and A09 independently reviewed the new rail frame:

- [Initial square](screenshots/prototype.png): normal prototype route and updated grind controls.
- [Aerial tricks](screenshots/air-tricks.png): actual airborne rider, 650 ×3 and 1,950 pending points, unclipped speed/control labels.
- [Pause menu](screenshots/pause-menu.png): readable actions, visible focus and dimmed game context.
- [Rail grind](screenshots/rail-grind.png): actual ground-approach/ollie/capture sequence, rail alignment, balance meter, Ollie + Rail Grind, 300 ×2 and 600 pending points. No visible clipping or panel overlap in the reviewed frame.

The repeatable scenario is in `tools/capture.gd` and GRINDING.md. The rail capture initializes a fixed approach speed; independent QE also verifies acceleration from rest through normal push input. No mocked grinding flag or image edit supplies the evidence. The new capture baseline is the commit introducing `docs/testing/GRINDING.md` (`git log -1 -- docs/testing/GRINDING.md`). Previous title-corrected baseline is retained in Git at `ad31a56c3cf6c324c10bb13520a3b8890dd54afb`.

These remain gameplay blockout captures. Static/software-rendered frames do not establish final visual quality, readable motion, comfortable camera behavior, real controller prompts or target-Mac 1080p/60 fps. Follow `docs/testing/VISUAL_ACCEPTANCE.md` and mandatory M06-007 for final art/UI acceptance.

## Next QE session

Read `docs/STATUS.md` and the earliest ready QE ticket in `docs/planning/BACKLOG.md`, then run `./tools/check.sh`. Preserve the separation between local automated evidence and the human/platform gates. For a new regression, record exact inputs, starting position, observed/expected result and affected build before changing production code. Keep the 260-check baseline unless an intentional behavior change makes a specific assertion obsolete; document the reason for any replacement.
