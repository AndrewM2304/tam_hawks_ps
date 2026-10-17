# Integrated QE report — 17 October 2026

Scope: the playable alpha's skating/combo loop, four-district world, career/persistence, audio, input and UI. Godot `4.6.3.stable.official.7d41c59c4`, Linux cloud machine. `./tools/check.sh`: **778 passed, 0 failed**, exit 0, clean import and engine/script logs after the final visual contact fix. This report does not certify real Mac/controller behavior, fun, listening quality or final artwork.

## Reproduce and evidence

Run `./tools/check.sh` from the repository root. It imports the project, runs `tests/run_tests.gd`, fails nonzero for failed assertions and scans logs for engine/script errors. The tests use actual production nodes, signals, physics frames and injected input where appropriate. Persistence fixtures live in unique ignored `.local/` directories; integrated game instances disable real profile writes. `./tools/setup.sh` verifies the installed pinned engine and invokes the same check.

Final command result and exact source verification are recorded in STATUS. The cleanup logs are `.local/cleanup-check.log`, `.local/import.log` and `.local/tests.log`. The previous alpha at 550a6da passed 717 assertions. The new wave adds 39 UI/feedback checks, 9 presentation/contact checks and 13 full-route checks. Assertions never replace the error scan; missing imported textures and long-route basis errors were corrected before accepting clean runs.

## Coverage

| Area | Tested outcomes |
|---|---|
| Movement and takeoff | Actual push/brake/steering, floor support, ramp traversal, grounded/air transition, input edge gating, momentum on uphill/downhill/flat departures and collision-adjusted air velocity; [takeoff report](TAKEOFF-MOMENTUM.md) preserves prior failing/passing evidence |
| Rail geometry/ride | Pinned adapted MIT geometry on straight/bent/sloped/reverse/transformed paths; invalid/duplicate data; candidate alignment/clearance; real push→ollie→descending capture; balance, obstruction, exit, release, pause/reset and one-entry score |
| Manuals and reverts | Deliberate supported entry, fore/aft correction, balance bail, release/cooldown, air/grind transition guards; early-held/late/duplicate revert rejection, valid 15% speed cost and no deadline extension |
| Combo ownership | Exact production ollie/flip→landing link→manual→ollie/grab line banks 3,200 once; repeat degradation, multiplier caps, 0.35-second inside/outside boundaries, pause/bail/reset and bounded three-second overtime with fresh-entry gates |
| Specials and gaps | Bank-earned charge, unlock/ground/air/timer gates, consume only on successful admission; unique ordered swept crossings, timeout/rearm/teleport guards; actual ramp climb and Central gap landing/score/goal integration |
| World | Four canonical districts, paired entrances and northern connectors with standing/capsule sweep clearance; nine ramp supports, six rails, marker/gap metadata, secret access, elevated platforms, safe NPC floors; real cone animation freezes on pause and resets |
| Career | All ten definition/progression/reward cases; incomplete sets, duplicates, mode isolation, score/record behavior; real movement collects a letter, actual input activates the cone, actual gap awards once, restart retains earned career |
| Persistence | Version/schema/range validation, verified atomic saves, local relaunch read, backups, malformed/truncated data, future-version protection including temporary/backup files, explicit archival recovery, settings/bindings and earned cosmetic validation |
| Input | All 19 actions have keyboard/pad bindings; remapping preserves other slots, rejects conflicts/reserved inputs, validates saved representations atomically and matches any device ID; synthetic Options and disconnect handling |
| UI | Actual focused Enter buttons, Tab/Escape navigation, career/free start, goals' pause ownership, results/replay, five sliders/toggles applied to real subsystems, rebinding followed by actual B-key ollie, conflict/cancel/reset, earned/locked cosmetic selection |
| Audio | Deterministic finite PCM, peaks/fades/loop boundaries, generated voice hashes/durations, bounded event pool, debounce, district/wheel/grind state, mix/mute/pause, global/per-line bark cooldown and caption admission |

The focused suites are called by the shared runner and restore their shared-scene fixtures. New coverage:

- `ui_feedback_tests.gd`: nested page return/focus/scroll, modifier rejection, current device/remapped cues, separate simultaneous event/combo feedback, persistent warnings, large scores, narrow/scaled bounds and visible/focused menu readiness.
- `presentation_integration_tests.gd`: actual stone/asphalt/metal support contacts, readable district/pickup/goal messages, absence of redundant district orbs and a real future-version protected-save failure without byte changes.
- `career_route_tests.gd`: all ten goals on one continuous production route, all four checkpoints, return to spawn without bail/stall, recording entrance/exit, and six bidirectional air/manual combo links. See [CAREER-ROUTES](CAREER-ROUTES.md) for exact timing and the direct-ground-heading limitation. No goal/score/collection event or in-route position/speed is injected.

Normal startup is checked separately because developer `--script` runs bypass the title branch. `tools/ui_feedback_capture.sh` creates a local scene entry with persistence disabled and no `--script`: title layout is pending at process frames 0–2, then visible/focused/ready at 3–5. The retained 1080p image is `screenshots/ui-cleanup/title-normal-boot-1080.png`. The standalone package also gets its own Linux startup probe; see EXPORT.

## Rendering evidence

`./tools/capture.sh` uses real scene rendering through Compatibility/OpenGL with installed Mesa llvmpipe on a temporary Xorg dummy display. Window is 1280×800; project internal canvas is 1440×900, 2× MSAA. The script records configured action/frame sequences and fixed overview transforms, saves unedited PNGs, and stops its own display. It never writes a player profile.

Final capture command result: **15 captures, every save result 0, script exit 0**, no engine/script errors. Durable images are copied to `docs/testing/screenshots/` after inspection:

- `prototype.png`, `air-tricks.png`, `rail-grind.png`, `manual.png`: real ground/air/rail/manual gameplay states. The rail starts at the documented approach with speed 10 m/s, then performs real push/ollie/capture physics; manual starts through real push input.
- `pause-menu.png`, `career-goals.png`, `settings.png`, `settings-large.png`, `controls-large.png`, `title.png`, `results.png`: actual production panels. Large settings/controls use the supported 1.4× preference. Results capture shortens the empty run to its final frame and waits for actual production timeout, not a fabricated record.
- `district-george.png`, `district-central.png`, `district-barras.png`, `district-overview.png`: authored fixed-camera scenery views. These establish architecture/visibility, not complete traversal or current real-world frontage accuracy.

Dedicated cleanup evidence extends the standard 15 views:

- [VISUAL_PASS](../levels/VISUAL_PASS.md): 16 matched world images with exact cameras, baseline/source and render counters. Review corrected facade/awning text clipping and jagged arch geometry; imported CC0 maps visibly load.
- `screenshots/ui-cleanup/`: six real images covering 1080p/960px, 1.4× UI preference, long scores/tricks, remapped prompts, save warnings, settings/controls and actual normal startup. Independent QE reviewed all six plus all 16 matched world frames and found no blocking clipping/overlap/missing geometry in this evidence set.
- Rider action/close captures and a 7.4s fixed-timestep 30 fps motion sequence are reproducible with `tools/rider_capture.sh` and `tools/rider_motion.sh`. The clip uses actual gameplay input with declared placement/charge fixtures and cuts; it is encoded at simulation speed and is not real-time performance evidence.
- [PERFORMANCE](PERFORMANCE.md): a bounded four-view 1920×1080 rendered diagnostic records wall-clock frame distributions, hardware/settings/source hashes and raw CSV. It does not substitute for the moving ten-minute Mac route.

A capture-specific defect was found during root review: physics ticks could advance before the menu's process-frame layout, so successful PNG writes contained only the temporary dark overlay. The standard runner now requires the expected modal page, actual run expiry for results, visible bounds/focus and a second readiness check after drawing. This was fixed in the capture contract; normal startup was independently observed becoming ready. Do not accept image counts alone.

The continuous route also exposed quaternion conversion errors from drifting foot bases; orthonormalized interpolation fixes them. Rider close review corrected open garment attachments, the tumble rotation pivot and board-wheel contact during manuals. Final captures must match those fixes.

Historical title-corrected blockout frames remain at `ad31a56`, first rails at `07ec43a`, and the previous alpha at `550a6da`. The new facades/materials, clothing skin and UI improve the blockout, while procedural repetition, stylized character/NPC detail and unverified real shop borders remain. **M06-007 is open.**

## Packages and acceptance limits

See [EXPORT.md](EXPORT.md) for official template checksum, actual exported artifact digests, imported resource/notice checks and Linux standalone smoke. Universal Mach-O inspection proves included architectures; it does not prove Mac launch. Builds are unsigned and unnotarized; no Apple enrollment or paid signing is used.

No physical DualSense, Mac launch/offline save/relaunch, Apple Silicon frame-time run, human ten-goal/score-balance playtest, listening review or final owner visual/feel acceptance has run here. Synthetic disconnect events are not USB/Bluetooth testing. Software-rendered screenshots are not target-performance evidence. Skinned clothing and the recorded animation sequence do not establish final character quality or human motion acceptance.

Continue with the concrete remaining tasks in STATUS/BACKLOG without routine approval stops. Preserve current tested behavior, reproduce new defects before fixing them and keep missing human/hardware evidence distinct from automation passes. Do not declare release completion merely because local tests pass.
