# Independent QE report — 17 October 2026

Owner: A09 QE. Scope: initial M01 local gameplay slice. Result: **94 assertions passed, 0 failed** using Godot `4.6.3.stable.official.7d41c59c4` on the Linux cloud machine. The tested slice is suitable for the next human playtest; this is not M01 hardware/feel acceptance or a release certification.

## Reproduce

From the repository root:

```sh
./tools/setup.sh
./tools/check.sh
```

The final `tools/check.sh` invocation returned exit code 0 and printed `RESULT: 94 passed, 0 failed`. It imported the project successfully, ran `tests/run_tests.gd`, and checked both logs for engine/script errors. Generated evidence is `.local/import.log` and `.local/tests.log`; these files are intentionally ignored and can be recreated. `tools/run.sh` supplies writable XDG directories. No external testing framework, paid service, hosted CI or downloaded test dependency is involved.

The standalone runner exits 1 when an assertion fails, uses deferred initialization, and reports explicit counts. It instantiates the production main script, uses real physics frames, and sends action input through the Godot input system. UI routing checks inject key and standard gamepad button events. These are synthetic inputs, not evidence of a connected physical device.

## Coverage and evidence

| Area | Verified behavior |
|---|---|
| Score session | Empty state; half/quarter repeat degradation; distinct-trick multiplier; cap; pending preview; bank exactly once; best combo; per-combo degradation reset; bail loss; full run reset |
| Scene and bindings | Production world/skater/camera creation; visible geometry and static bodies; all 12 actions registered with keyboard and gamepad bindings; spawn contract; location text |
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

## Defects and limits

No failing automated cases remain in the tested slice. QE did not edit production behavior to achieve these results. This is limited evidence, not proof that all untested routes, inputs or edge cases work.

The following require separate evidence before milestone acceptance:

- Physical DualSense on the target Mac, including wired/Bluetooth mappings, reconnect behavior and button glyphs.
- macOS/Apple Silicon executable/export, actual launch, permissions and target-machine frame times. Linux physics assertions do not establish 60 fps at 1080p on a Mac.
- Human skating feel, turn comfort, jump timing, camera behavior across the whole level, legibility during motion, and the desire to replay.
- Full traversal of the north and warm-up banks, every ledge/rail prop and extreme-speed/corner contacts. Current automated passage coverage is the central and tenement routes; all four ramps have collision-normal checks.
- Input buffering/coyote-time edge boundaries, camera obstruction recovery, and longer randomized regression runs. These are useful next test additions when related behavior changes.

Rendered-frame evidence belongs in the rendering record below and `docs/STATUS.md`; headless execution alone cannot certify the visual result. Grinds, manuals, reverts, missions, progression, saves, audio, multiple districts and cone interaction remain roadmap work and are not certified by this suite.

## Rendering record

The orchestrator captured three real 1280×800 frames using the Compatibility renderer with software Mesa OpenGL on an Xorg dummy display. A09 independently opened all three images:

- [Initial square](screenshots/prototype.png): skater, board, forward ramp, statue and building facades are visible; score/timer/control instructions are legible and the central route is unobstructed.
- [Aerial tricks](screenshots/air-tricks.png): the skater is visibly airborne; HUD shows `650 ×3` and `1950 POINTS — LAND TO BANK IT` with the three trick names; the speed gauge is present without clipping.
- [Pause menu](screenshots/pause-menu.png): the dimmed gameplay context and three readable actions are visible; the resume action has an obvious focus outline.

Source captures were `.local/prototype.png`, `.local/air-tricks.png` and `.local/pause-menu.png`; the orchestrator copies the reviewed images to the linked durable paths. These samples show no obvious missing geometry, text clipping or overlap. Static frames do not establish readable motion, comfortable camera behavior, correct physical controller glyphs, or real-time performance on the target Mac.

## Next QE session

Read `docs/STATUS.md` and the earliest ready QE ticket in `docs/planning/BACKLOG.md`, then run `./tools/check.sh`. Preserve the separation between local automated evidence and the human/platform gates. For a new regression, record exact inputs, starting position, observed/expected result and affected build before changing production code. Keep the 94-check baseline unless an intentional behavior change makes a specific assertion obsolete; document the reason for any replacement.
