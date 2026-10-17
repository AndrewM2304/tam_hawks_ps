# Reproducible rendered performance diagnostic

**Checkpoint note:** The retained six-view measurements below predate the bin-drum/dancing-cat correction. They remain a historical software-rendered checkpoint; no new-actor or target-Mac performance pass is claimed. Current corrected-scene evidence belongs in STATUS and screenshots/bin-cats.

`tools/profile.sh` runs the installed **Godot 4.6.3** through `tools/run.sh` and measures six supported checkpoint views using the game's actual chase camera, HUD, world and idle physics. It provides a repeatable rendering workload for M06-004. **The Apple Silicon 60 fps acceptance gate remains open:** this diagnostic does not replace a ten-minute moving gameplay route on the declared target Mac.

**Current workload:** schema 2 samples all six current checkpoints, including Clyde and Kelvingrove, using the actual production chase camera. It requires supported, stationary rider/camera settling and fingerprints source inputs and each image. The six-view run completed successfully on 17 October 2026 at 16:28 UTC with 114 samples, six inspected images and 101 unchanged source inputs. Its Linux software-rendered results are recorded below. The four-view numbers below remain historical and are not a before/after comparison with this expanded workload.

## Current resource/culling review

The new [render-efficiency review](../research/RENDER-EFFICIENCY-REVIEW.md) audits the current world independently of the historical timing runs below. At the preceding control/fidelity checkpoint, exact primitive sharing reduced unique world mesh resources **1,419→324**, preserving nodes, instances, materials and physics. Those counts predate the new quarter/half-pipes and have not been remeasured for the expanded scene. This is a resource-count reduction, not measured VRAM bytes, draw savings or FPS. Production keeps the existing automatic frustum culling, 220m camera far plane and 75m shadows.

Two matched eight-view world-only candidates, [48m cells](render-budget-20261017/README.md) and [96m cells](render-budget-96m-20261017/README.md), retain all 110 tree records and stable source. Both improve distant-tree submissions in some city views, but the normal park checkpoint regresses from 73 draws to 109/89; the 96m candidate saves no primitives there. Both remain opt-in diagnostics. Their fixed three-sample counters are not frame-time or target-Mac evidence. The original GLB board replaces 25 separate procedural mesh instances with four material surfaces; its actual view performance still needs measurement.

The next measured optimization is author-time static facade batching/shared PBR atlases and imported LODs, preserving gameplay collision and skyline readability. See the existing M06-004 work package in CONTROL-AND-FIDELITY-NEXT. Do not hide whole districts by current-area ID or assume a lower far plane improves every view. Actual Apple M5 model/memory/macOS/settings and ten-minute moving-route p50/p95/p99 remain required.

## Run on the target Mac

From the repository root, with the free Godot 4.6.3 app and Python 3 already installed, first prepare a fresh checkout with the ordinary import/check command. This prerequisite runs outside the measured workload:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/setup.sh
```

After setup passes, run:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/profile.sh --duration 60 --resolution 1920x1080
```

Use the normal graphical desktop. Close other demanding applications, connect power, record the Mac model/chip/memory and macOS version, and keep those conditions consistent between runs. The script records the engine-reported CPU, graphics adapter, OS, renderer/driver/API, window and actual render resolution, settings, physics tick rate, V-Sync state and frame cap. macOS scaling or window-management restrictions that prevent the requested render size cause a failed run rather than an incorrectly labelled 1080p result.

The default and minimum duration is 60 seconds: six minimum two-second warmups and at least eight sampled seconds per area. Each warmup may extend to 12 seconds while the rider/camera settles; frame-boundary rounding, loading and screenshot encoding add wall time. `--duration` accepts whole seconds from 60 to 600, with sample time per view equal to `duration / 6 - 2`. At least three actual rendered samples are required for every view. A slower host that cannot provide those samples fails; choose a longer duration deliberately rather than interpreting an incomplete run. This remains a stationary-view diagnostic at every duration. `--resolution WIDTHxHEIGHT` accepts 320–3840 by 200–2160. No software is downloaded or installed, no paid service is used, and there is no scheduler or unattended continuation.

On this Linux development image, isolate the run from other agents' captures with:

```bash
./tools/profile.sh --private-display --duration 60 --resolution 1920x1080
```

The Linux private-display option requires the already installed Xorg dummy driver. It creates a unique display/config/log directory, explicitly uses software OpenGL, and stops only its own display and game process on completion, interruption or failure. Do not use `--private-display` on macOS. `--headless` is rejected: a headless engine cannot supply rendered frame evidence. A missing graphical display is not a passing performance result.

## Workload and output

The rider resets to each authored checkpoint in this fixed order: Royal Exchange, George Square, Central Station, Barras, Clyde and Kelvingrove. Exchange/George/Barras look north (heading 0), Central/Kelvingrove northwest (π/4), and Clyde south across the river (π). The runner queries the current ground height and starts 0.8 m above it. Warmup requires at least two wall-clock seconds and three consecutive rendered frames with actual floor contact, real speed ≤0.05 m/s, rider movement ≤0.01 m, camera movement ≤0.02 m and camera rotation ≤0.005 radians between frames. Missing support or failure to settle within 12 seconds rejects the run. During sampling, floor contact must remain true, speed stays bounded, and displacement/rotation from the settled pose must remain within the same tolerances. Each view records its checkpoint, authored ground height, measured pose, camera transform and settling evidence. The real chase camera retains its collision handling; no alternate overview camera replaces it. Player input is disabled, but normal world/HUD/physics processing continues in free skate. Default presentation settings are recorded with each run. Profile loading and saving are explicitly disabled before the game enters the tree; no career progress, records or settings are written.

For this diagnostic, both the window and content-scale design size are explicitly set to the requested resolution, matching the verified UI capture helper. The HUD then scales from that actual viewport. This is recorded as `benchmark_content_scale_override: true`; the project's ordinary 1440×900 design canvas is not silently treated as a native 1080p measurement. An initial local attempt with only the window size set was rejected because the render texture was approximately 2074×1296. No frames from that rejected run contribute to the results below.

Audio synthesis/event processing uses Godot's Dummy output driver for comparable, silent measurements. These results do not measure audible playback, output latency or listening quality. The script requests V-Sync off and no frame cap and records the actual reported configuration.

Each run prints a new ignored `.local/profile-<UTC timestamp>-<unique suffix>/` directory containing:

- `report.json`: engine/hardware/settings provenance, aggregate and district summaries, exact invocation, commit/dirty state, timing bounds, camera transforms, and explicit acceptance limitations.
- `frames.csv`: one row per rendered sample, with monotonic elapsed microseconds, frame interval, process/physics monitors, draw calls, rendered objects/primitives, nodes and static memory.
- Six area PNGs: the actual rendered chase views, captured after each measured interval. Each view records its image SHA-256/byte count, source-manifest SHA-256 and a hash of its raw CSV rows.
- `source-manifest.json`: SHA-256 fingerprints of game/assets/project, profiler and run-wrapper source inputs. Any change during measurement marks the result non-comparable and fails the wrapper; rerun after concurrent edits settle.
- `artifacts.json`: byte counts and SHA-256 digests for the report, CSV, source manifest, engine log and six actual images. It is separate to avoid a self-hash cycle.
- `engine.log` plus private-display logs/config when used. Keep the JSON/CSV and source manifest together when comparing results.

`PROFILE_OK` requires exactly the six expected views in order, supported settling and stationary samples, at least three CSV rows per view, the requested minimum sampling duration, matching report/CSV counts, six PNG headers with the requested dimensions, a clean engine log, disabled profile writes, stable source inputs and a successful child exit. Completed child runs rejected by validation retain `wrapper_validation_errors` and never set `source_stable_rendered_run` true; an interrupted/timed-out child may leave only partial logs/artifacts and never prints `PROFILE_OK`. The parent bounds engine runtime to the requested duration plus 90 seconds, then terminates its own process group if needed. Ctrl-C also stops its children. Output files are local diagnostics, not cloud uploads or a release certificate.

## Interpreting the metrics

Frame intervals use `Time.get_ticks_usec()` between `RenderingServer.frame_post_draw` signals. They are monotonic wall-clock intervals covering CPU work, rendering and presentation, **not isolated GPU timer queries**. Each view and the overall report contain nearest-rank p50/p95/p99/max frame milliseconds and throughput FPS (`sample count / measured seconds`). The target 60 fps budget is 16.67 ms; average FPS alone can hide long frames. CSV rows retain the full distribution for inspection.

Normal rendering and physics continue without `--fixed-fps`, forced draws or scripted frame advancement. The report records time scale and the maximum physics steps per render frame; a very slow renderer may not maintain real-time physics. Warmups and screenshot readbacks are excluded from timed samples. Scene loading, moving-camera visibility changes, streaming/traversal stutters, player input, tricks, effects during long combinations, thermal behavior and the operating system's background workload are not fully represented. Godot's draw-call/node counters are workload diagnostics, not a guarantee that one material or one node corresponds to one submitted draw. Compare only the same engine, source revision, resolution, renderer, viewpoints, settings and host conditions.

Historical 1280×800 art-review captures use authored cameras; their draw-call reductions belong to that matched before/after capture series. Do not treat them as a timing baseline for this 1920×1080 production-camera diagnostic.

## Required target-hardware follow-up

Owner + A09 record a real Apple Silicon model/chip/memory/macOS, native build/version and exact settings. Run this diagnostic, then play a separate ten-minute 1920×1080 route through all six areas with real keyboard/DualSense input: turns, slopes, grinds, manual links, both specials, all goals, dense market/civic sightlines, fountain, Clyde bridges/water, the full park climb and pause/settings/map transitions. Capture frame-time evidence for that moving workload, long-frame causes and any thermal degradation; verify audio and controller behavior separately. Investigate p95/p99 spikes against the 16.67 ms target before claiming 60 fps acceptance. Preserve the raw evidence and resulting fixes in M06-004/QE rather than marking the gate complete from Linux or fixed views alone.

## Current six-view local measurement — 17 October 2026

Shell syntax, embedded Python parsing and `./tools/run.sh --headless --script tools/profile.gd --check-only` pass. CLI help reports the 60–600 second bound. Five invalid invocations (`--headless`, durations 59/601 and resolutions 319×200/3840×2161) each exit 2. A direct headless script launch also exits 2 and explicitly rejects rendered evidence. Independent read-only QE found no concrete blocker in the current timing labels, supported settling, six-view/sample validation, source fingerprinting or bounded process cleanup. No graphical measurement was performed in that review. These are tooling checks, not six-view performance results.

The command `./tools/profile.sh --private-display --duration 60 --resolution 1920x1080` completed **exit 0**, with no other game/test/render process active during measurement. The working tree was based on `64000fdbff6812906a02ea4e4447143a75b8f623`, with the new court/cat changes present (`git_dirty: true`). All **101 source inputs** remained unchanged. The actual graphical workload used Godot 4.6.3 Compatibility/OpenGL 3, Mesa OpenGL 4.5, Linux 13, **llvmpipe LLVM 19.1.7 software rendering**, engine-reported AMD EPYC 9V74 and five available logical CPUs. V-Sync mode 0 and max FPS 0 were reported; the driver printed only its expected unsupported V-Sync-change warning. No engine/script errors occurred.

Actual window, framebuffer and design dimensions were 1920×1080. All six PNGs were visually inspected: Exchange fountain court, George civic terrace/cat workshop, Central canopy, the Barras hall edge, Clyde quay and park paths. The Barras checkpoint `(60, 0.8, 22)` looks north toward the nearby hall's brick side; its numbers describe that close-hall view, **not the open market aisle or the full district**. Every viewpoint is one local sample, not an area-wide worst case.

All views retained floor contact, zero measured player displacement and zero real speed throughout sampling. Camera drift was at most 0.001267 m / 0.000691 radians. Actual warmups took 2.857–5.318 seconds and each ended with three consecutive stable frames. The scan lasted 77.265 seconds and the child process 88.368 seconds including startup/readbacks; **49.279667 seconds / 114 frames** were sampled. Physics remained configured at 60 Hz, eight maximum physics steps per render frame and time scale 1; normal rendering ran without forced or fixed-time frames. Default settings and persistence-disabled state are retained in the report.

| Checkpoint view | Frames | Mean FPS | p50 ms | p95 ms | p99 ms | Max ms | Median draw calls | Maximum nodes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Royal Exchange | 13 | 1.55 | 640.840 | 682.145 | 682.145 | 682.145 | 1,892 | 2,687 |
| George Square | 16 | 1.92 | 515.198 | 557.705 | 557.705 | 557.705 | 937 | 2,687 |
| Central Station | 22 | 2.72 | 366.079 | 393.456 | 403.688 | 403.688 | 713 | 2,687 |
| Barras near-hall | 13 | 1.57 | 632.763 | 660.962 | 660.962 | 660.962 | 1,900 | 2,687 |
| Clyde quay | 27 | 3.37 | 295.734 | 311.046 | 315.142 | 315.142 | 459 | 2,687 |
| Kelvingrove paths | 23 | 2.80 | 357.633 | 373.903 | 385.542 | 385.542 | 211 | 2,687 |
| Combined | 114 | 2.31 | 367.624 | 656.522 | 676.108 | 682.145 | 713 | 2,687 |

Raw CSV counts, durations, throughput FPS and all nearest-rank p50/p95/p99/max values were recomputed against the JSON. Independent QE separately confirmed all 114 rows, per-view/aggregate timing and draw/node/primitive summaries, timestamps, all ten hashed artifacts and 101 current source hashes; all six PNGs fully decoded at 1920×1080. Image/source/raw-row hashes and every artifact-manifest digest match. The profiler's private game/display stopped after completion. Durable evidence is retained in [six-area-20261017](performance/six-area-20261017/README.md), including all six unmodified images, [report.json](performance/six-area-20261017/report.json), [frames.csv](performance/six-area-20261017/frames.csv), source hashes and engine log. Original ignored output: `.local/profile-20261017T162639Z-qfW4jk/`.

- Report SHA-256: `f0f942c31e00f90586754d853339bbe77c25783013a86072f605304e51c6b67f`
- Source-manifest SHA-256: `016a68fdad16d4c8f5f243291abea5d6d907781e68b4e86203abea6e97135db9`
- Artifact-manifest SHA-256: `ad0ebd675146374218caf06ca8eb5a0627b33dea33ab30b2cb659b8b55f6cfc3`

This software-rendered result is far below the 60 fps target and provides **no target-Mac acceptance result**. Small per-view sample counts limit percentile precision. There is no improvement/delta claim against the different historical four-view workload. Any future comparison must keep duration, engine, host, resolution, settings, headings and checkpoint positions identical and record changed production inputs. A separate moving-route measurement remains required.

## Historical four-view validation — 17 October 2026

The earlier four-view helper passed shell/Python syntax, invalid-invocation and direct-headless rejection checks. Independent read-only QE found no concrete defect in that version's persistence isolation, sampling or process cleanup. That earlier review does not by itself validate the new six-view implementation.

The corrected 36-second command completed **exit 0** on **17 October 2026 at 14:09:44 UTC**, using the earlier cleanup working tree based on commit `550a6dac7892f970724ef10d9856a66af9f52fcb` (`git_dirty: true`). This predates ADR-007's terrain redesign and used the earlier checkpoint geometry plus a northeast-facing Barras camera. Source inputs were unchanged during that run. Other agents' Godot test/render processes were stopped for the measurement window, and this helper's own game/display were confirmed stopped afterward.

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

This software-rendered cloud workload is far below 60 fps. These measurements validated the earlier four-view diagnostic and established its historical local baseline; they provide **no target-Mac performance result**. Short per-view samples mean p99 often equals the maximum. The greatest measured draw-call load was Exchange (1,800 maximum), making it a useful first investigation view when target-hardware profiling is available. No percentage improvement is inferred from the older cameras or resolutions.

The compact baseline is preserved in [report.json](performance/cleanup-20261017/report.json), [frames.csv](performance/cleanup-20261017/frames.csv) and [source-manifest.json](performance/cleanup-20261017/source-manifest.json). CSV row counts, per-view nearest-rank quantiles and throughput FPS were independently recomputed from the raw CSV and matched the JSON; resolution, disabled persistence and stable-source flags were also checked. The report intentionally retains the dirty working-tree provenance and original local invocation; it does not claim to be a clean release build.

Original logs and the four inspected PNGs remain ignored under `.local/profile-20261017T140853Z-kCBlTx/`; running the command above now uses six supported checkpoints and the current headings/duration, so it does not reproduce the old geometry or old workload. Keep those optional images/logs before replacing the workspace if needed. The historical JSON stores each old camera transform and screenshot filename even when the ignored image is unavailable.

- `report.json` SHA-256: `63db4aeca01114ad23e0271f385fc5aab7ecd0368f8637e58cff43a0e5e24521`
- `source-manifest.json` SHA-256: `b6ce78c102ae4bd5f951d6b15ca06badad1a7e9451fdb31f2416bae3ab42a167`

M06-004 remains open for the real target Mac and ten-minute moving route. No physical controller, thermal, audible-output or final visual acceptance is inferred from these four still views.
