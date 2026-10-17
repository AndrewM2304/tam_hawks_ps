# Reproducible rendered performance diagnostic

`tools/profile.sh` runs the installed **Godot 4.6.3** through `tools/run.sh` and measures four fixed views using the game's actual chase camera, HUD, world and idle physics. It provides a repeatable rendering workload for M06-004. **The Apple Silicon 60 fps acceptance gate remains open:** this diagnostic does not replace a ten-minute moving gameplay route on the declared target Mac.

## Run on the target Mac

From the repository root, with the free Godot 4.6.3 app and Python 3 already installed, first prepare a fresh checkout with the ordinary import/check command. This prerequisite runs outside the measured workload:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/setup.sh
```

After setup passes, run:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/profile.sh --duration 36 --resolution 1920x1080
```

Use the normal graphical desktop. Close other demanding applications, connect power, record the Mac model/chip/memory and macOS version, and keep those conditions consistent between runs. The script records the engine-reported CPU, graphics adapter, OS, renderer/driver/API, window and actual render resolution, settings, physics tick rate, V-Sync state and frame cap. macOS scaling or window-management restrictions that prevent the requested render size cause a failed run rather than an incorrectly labelled 1080p result.

The default duration is 36 seconds: four 1.5-second camera/material warmups and approximately 7.5 sampled seconds per district. Loading and screenshot encoding add a little wall time. `--duration` accepts whole seconds from 12 to 600; this remains a stationary-view diagnostic at every duration. `--resolution WIDTHxHEIGHT` accepts 320–3840 by 200–2160. No software is downloaded or installed, no paid service is used, and there is no scheduler or unattended continuation.

On this Linux development image, isolate the run from other agents' captures with:

```bash
./tools/profile.sh --private-display --duration 36 --resolution 1920x1080
```

The Linux private-display option requires the already installed Xorg dummy driver. It creates a unique display/config/log directory, explicitly uses software OpenGL, and stops only its own display and game process on completion, interruption or failure. Do not use `--private-display` on macOS. `--headless` is rejected: a headless engine cannot supply rendered frame evidence. A missing graphical display is not a passing performance result.

## Workload and output

The rider resets to each authored district checkpoint: Royal Exchange, George Square, Central Station and the Barras. Exchange/George look north; Central looks northwest; Barras looks northeast. The real follow camera settles during warmup, including its collision handling. No alternate overview camera replaces it. Player input is disabled, but normal world/HUD/physics processing continues in free skate. Default presentation settings are recorded with each run. Profile loading and saving are explicitly disabled before the game enters the tree; no career progress, records or settings are written.

For this diagnostic, both the window and content-scale design size are explicitly set to the requested resolution, matching the verified UI capture helper. The HUD then scales from that actual viewport. This is recorded as `benchmark_content_scale_override: true`; the project's ordinary 1440×900 design canvas is not silently treated as a native 1080p measurement. An initial local attempt with only the window size set was rejected because the render texture was approximately 2074×1296. No frames from that rejected run contribute to the results below.

Audio synthesis/event processing uses Godot's Dummy output driver for comparable, silent measurements. These results do not measure audible playback, output latency or listening quality. The script requests V-Sync off and no frame cap and records the actual reported configuration.

Each run prints a new ignored `.local/profile-<UTC timestamp>-<unique suffix>/` directory containing:

- `report.json`: engine/hardware/settings provenance, aggregate and district summaries, exact invocation, commit/dirty state, timing bounds, camera transforms, and explicit acceptance limitations.
- `frames.csv`: one row per rendered sample, with monotonic elapsed microseconds, frame interval, process/physics monitors, draw calls, rendered objects/primitives, nodes and static memory.
- Four district PNGs: the actual rendered chase views, captured after each measured interval.
- `source-manifest.json`: SHA-256 fingerprints of game/assets/project and profiler source inputs. Any change during measurement marks the result non-comparable and fails the wrapper; rerun after concurrent edits settle.
- `engine.log` plus private-display logs/config when used. Keep the JSON/CSV and source manifest together when comparing results.

`PROFILE_OK` requires four populated views, the requested actual render resolution, successful captures, a clean engine log, stable source inputs and a successful child exit. The parent bounds engine runtime to the requested duration plus 90 seconds, then terminates its own process group if needed. Ctrl-C also stops its children. Output files are local diagnostics, not cloud uploads or a release certificate.

## Interpreting the metrics

Frame intervals use `Time.get_ticks_usec()` between `RenderingServer.frame_post_draw` signals. They are monotonic wall-clock intervals covering CPU work, rendering and presentation, **not isolated GPU timer queries**. Each view and the overall report contain nearest-rank p50/p95/p99/max frame milliseconds and throughput FPS (`sample count / measured seconds`). The target 60 fps budget is 16.67 ms; average FPS alone can hide long frames. CSV rows retain the full distribution for inspection.

Warmups and screenshot readbacks are excluded from timed samples. Scene loading, moving-camera visibility changes, streaming/traversal stutters, player input, tricks, effects during long combinations, thermal behavior and the operating system's background workload are not fully represented. Godot's draw-call/node counters are workload diagnostics, not a guarantee that one material or one node corresponds to one submitted draw. Compare only the same engine, source revision, resolution, renderer, viewpoints, settings and host conditions.

Historical 1280×800 art-review captures use authored cameras; their draw-call reductions belong to that matched before/after capture series. Do not treat them as a timing baseline for this 1920×1080 production-camera diagnostic.

## Required target-hardware follow-up

Owner + A09 record a real Apple Silicon model/chip/memory/macOS, native build/version and exact settings. Run this diagnostic, then play a separate ten-minute 1920×1080 route through all four districts with real keyboard/DualSense input: turns, ramps, grinds, manual links, both specials, all goals, dense market/civic sightlines and pause/settings transitions. Capture frame-time evidence for that moving workload, long-frame causes and any thermal degradation; verify audio and controller behavior separately. Investigate p95/p99 spikes against the 16.67 ms target before claiming 60 fps acceptance. Preserve the raw evidence and resulting fixes in M06-004/QE rather than marking the gate complete from Linux or fixed views alone.

## Local validation

Shell syntax, embedded Python parsing and CLI help have been checked. Five invalid invocations (headless, below/above duration bounds and below/above resolution bounds) each exit 2. A direct headless script launch also intentionally exits 2 with the message that headless cannot provide GPU/frame evidence. Independent read-only QE found no concrete defect in the persistence isolation, sampling or process cleanup.

The corrected 36-second command completed **exit 0** on **17 October 2026 at 14:09:44 UTC**, using the final cleanup working tree based on commit `550a6dac7892f970724ef10d9856a66af9f52fcb` (`git_dirty: true`). Source inputs were unchanged during the run. Other agents' Godot test/render processes were stopped for the measurement window, and this helper's own game/display were confirmed stopped afterward.

- Host: Linux 13, engine-reported AMD EPYC 9V74 80-Core Processor, **5 logical CPUs available to this process**.
- Graphics: X11, Compatibility/OpenGL 3 driver, Mesa OpenGL 4.5, **llvmpipe LLVM 19.1.7 software renderer**. This is CPU rendering, not Apple Silicon GPU evidence.
- Godot: official 4.6.3, engine hash `7d41c59c457bd5a245092b4e7eb2d833e3b3f8c3`; physics 60 ticks/s, frame cap 0, reported V-Sync mode 0. Xorg logged its expected unsupported V-Sync-change warning; there were no engine/script errors.
- Actual window and render texture: **1920×1080**; four images inspected. Default UI scale 1, camera sensitivity 1, captions on, reduced motion off; master 0.8, SFX 1, ambience 0.6 with Dummy output. Career-profile writes remained disabled.
- Duration: 50.849 seconds including engine startup/capture overhead; 40.722 seconds for the district scan; **31.477 sampled seconds / 72 frames** after warmup and frame-boundary rounding.

| District | Frames | Mean FPS | p50 ms | p95 ms | p99 ms | Max ms | Median draw calls | Maximum nodes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Royal Exchange | 14 | 1.77 | 554.328 | 623.087 | 623.087 | 623.087 | 1,797 | 2,247 |
| George Square | 20 | 2.55 | 388.982 | 424.124 | 440.337 | 440.337 | 838 | 2,247 |
| Central Station | 19 | 2.42 | 409.874 | 453.983 | 453.983 | 453.983 | 730 | 2,247 |
| Barras | 19 | 2.42 | 402.391 | 490.269 | 490.269 | 490.269 | 1,306 | 2,247 |
| Combined | 72 | 2.29 | 405.330 | 594.891 | 623.087 | 623.087 | 838 | 2,247 |

This software-rendered cloud workload is far below 60 fps. These measurements validate the diagnostic and establish a local baseline; they provide **no target-Mac performance result**. Short per-view samples mean p99 often equals the maximum. The greatest measured draw-call load was Exchange (1,800 maximum), making it a useful first investigation view when target-hardware profiling is available. No percentage improvement is inferred from the older cameras or resolutions.

The compact baseline is preserved in [report.json](performance/cleanup-20261017/report.json), [frames.csv](performance/cleanup-20261017/frames.csv) and [source-manifest.json](performance/cleanup-20261017/source-manifest.json). CSV row counts, per-view nearest-rank quantiles and throughput FPS were independently recomputed from the raw CSV and matched the JSON; resolution, disabled persistence and stable-source flags were also checked. The report intentionally retains the dirty working-tree provenance and original local invocation; it does not claim to be a clean release build.

Original logs and the four inspected PNGs remain ignored under `.local/profile-20261017T140853Z-kCBlTx/`; running the command above reproduces the same checkpoint/headings/camera procedure in a new uniquely named directory. Keep those optional images/logs before replacing the workspace if needed. The JSON stores each camera transform and screenshot filename even when the ignored image is unavailable.

- `report.json` SHA-256: `63db4aeca01114ad23e0271f385fc5aab7ecd0368f8637e58cff43a0e5e24521`
- `source-manifest.json` SHA-256: `b6ce78c102ae4bd5f951d6b15ca06badad1a7e9451fdb31f2416bae3ab42a167`

M06-004 remains open for the real target Mac and ten-minute moving route. No physical controller, thermal, audible-output or final visual acceptance is inferred from these four still views.
