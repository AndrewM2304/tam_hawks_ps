# Integrated QE report — 17 October 2026

Scope: the playable alpha's skating/combo loop, four-district world, career/persistence, audio, input and UI. Godot `4.6.3.stable.official.7d41c59c4`, Linux cloud machine. **717 assertions passed, 0 failed** in the final integrated run; this report does not certify real Mac/controller behavior, fun, listening quality or final artwork.

## Reproduce and evidence

Run `./tools/check.sh` from the repository root. It imports the project, runs `tests/run_tests.gd`, fails nonzero for failed assertions and scans logs for engine/script errors. The tests use actual production nodes, signals, physics frames and injected input where appropriate. Persistence fixtures live in unique ignored `.local/` directories; integrated game instances disable real profile writes. `./tools/setup.sh` verifies the installed pinned engine and invokes the same check.

Final command result: **717 passed, 0 failed; exit 0**, clean import and no scanned engine/script errors. Reproducible logs: `.local/final-alpha-check.log`, `.local/import.log`, `.local/tests.log`. First broader integration passed 615; a later run exposed six generated-voice PCM checks failing after export-safe ResourceLoader imports. Godot's default QOA compression caused the mismatch; preserving PCM in the three small WAV imports corrected all 75 focused audio checks without weakening assertions. The final suite includes later UI and world-animation checks and awaits coroutine completion before subsequent shared-scene tests.

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

Focused suites remain available as small scripts called by the shared runner. `tests/ui_integration_tests.gd` recreates the title's public paused/show_title state because developer `--script` runners intentionally bypass normal startup title behavior. The standalone export smoke provides separate normal-boot evidence.

## Rendering evidence

`./tools/capture.sh` uses real scene rendering through Compatibility/OpenGL with installed Mesa llvmpipe on a temporary Xorg dummy display. Window is 1280×800; project internal canvas is 1440×900, 2× MSAA. The script records configured action/frame sequences and fixed overview transforms, saves unedited PNGs, and stops its own display. It never writes a player profile.

Final capture command result: **15 captures, every save result 0, script exit 0**, no engine/script errors. Durable images are copied to `docs/testing/screenshots/` after inspection:

- `prototype.png`, `air-tricks.png`, `rail-grind.png`, `manual.png`: real ground/air/rail/manual gameplay states. The rail starts at the documented approach with speed 10 m/s, then performs real push/ollie/capture physics; manual starts through real push input.
- `pause-menu.png`, `career-goals.png`, `settings.png`, `settings-large.png`, `controls-large.png`, `title.png`, `results.png`: actual production panels. Large settings/controls use the supported 1.4× preference. Results capture shortens the empty run to its final frame and waits for actual production timeout, not a fabricated record.
- `district-george.png`, `district-central.png`, `district-barras.png`, `district-overview.png`: authored fixed-camera scenery views. These establish architecture/visibility, not complete traversal or current real-world frontage accuracy.

The UI specialist also reviewed seven dedicated fixtures, including a long active combo and 1.4× goals. Independent QE reviewed nine final captures and found no blocking overlap, clipping or rendering defects. A forced-results screenshot showed 2:00 behind the finished dialog; the capture now uses actual expiry. Render review caught hidden autowrapped descriptions, collapsed numeric slider labels and a deferred focus issue that headless assertions had missed; production sizing/focus fixes preceded final integration.

Historical title-corrected blockout frames remain at `ad31a56`; the previous first-rail checkpoint is `07ec43a`. Current textures/facades, rounded articulated rider and themed UI improve the initial blockout, but scenery repetition, primitive-derived character surfaces, sparse street detail and unverified shop borders remain visible. **M06-007 is open.** See VISUAL_ACCEPTANCE for required normal-speed, 1080p, bright/shaded, route and final owner review.

## Packages and acceptance limits

See [EXPORT.md](EXPORT.md) for official template checksum, actual exported artifact digests, imported resource/notice checks and Linux standalone smoke. Universal Mach-O inspection proves included architectures; it does not prove Mac launch. Builds are unsigned and unnotarized; no Apple enrollment or paid signing is used.

No physical DualSense, Mac launch/offline save/relaunch, Apple Silicon frame-time run, human ten-goal/score-balance playtest, listening review or final owner visual/feel acceptance has run here. Synthetic disconnect events are not USB/Bluetooth testing. Software-rendered screenshots are not target-performance evidence. Original procedural art and a short grab pose preview do not establish a finished skinned character or convincing normal-speed animation.

Continue with the concrete remaining tasks in STATUS/BACKLOG without routine approval stops. Preserve current tested behavior, reproduce new defects before fixing them and keep missing human/hardware evidence distinct from automation passes. Do not declare release completion merely because local tests pass.
