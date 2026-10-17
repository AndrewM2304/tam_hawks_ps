# Current-map rendering and moving measurements

Recorded 17 October 2026, 23:30–23:43 UTC (18 October in Europe/London). Production game is `8a975b2c0e0bce5ffbc212c91368d659e6f8b30d`. These are completed, source-stable Linux diagnostics, **not Apple M5 FPS acceptance**. No other Godot/render jobs overlapped these measurements. The final ordinary suite started afterward.

## Retained runs and source identity

All reports, raw CSV, engine logs, source manifests, original artifact inventories and all **21 actual PNGs** are retained without modification. [verification.json](verification.json) independently verifies every raw artifact hash, full PNG CRC/decompression/scanline dimensions, CSV sample counts, per-view timing percentiles/median draws and every source fingerprint against its named Git object.

| Folder | Command suffix after `./tools/` | Source inputs | Verified source revision | Frames |
| --- | --- | ---: | --- | ---: |
| [balanced](balanced/report.json) | `profile.sh --private-display --duration 60 --resolution 1280x800` | 143 | `b379294f4978431973342ab56f2a8e068516e073` | 71 |
| [performance](performance/report.json) | `profile.sh --private-display --duration 60 --resolution 1280x800 --quality performance` | 143 | `9e3931666bbdaccccbdda997931afba9a53243b1` | 249 |
| [control-repeat](control-repeat/report.json) | unchanged archived `profile.sh --private-display --duration 60 --resolution 1280x800` | 137 | `1b20e262b41910da663347d1bc5c73462db4e04d` | 80 |
| [moving](moving/report.json) | `moving_profile.sh --private-display --duration 120 --resolution 1280x800 --quality balanced` | 148 | `9e3931666bbdaccccbdda997931afba9a53243b1` | 217 |

The Performance helper was uncommitted at invocation; its raw dirty/HEAD fields remain intact. Every one of its recorded inputs subsequently matches committed `9e39316`. Balanced predates the explicit quality argument and uses its default Balanced settings; its game files are identical. The control is an isolated `git archive`, not a worktree; parent Git discovery was disabled, so its raw `git_commit: unavailable` is expected. All 137 control inputs match the archived old revision. [Control provenance](performance-control-provenance.json) records that identity independently. [Host observation](performance-control-host.json) is a single mid-control cgroup sample, not evidence of a quota change between runs.

The separate [original baseline](../performance-baseline-20261017/README.md) retains its 102-frame run from the same old source. [Rejected first control attempt](rejected-control-first-use/report.json) has zero timed views because the original 12-second supported-camera settling limit expired. Its report/log/empty CSV/source/inventory are retained. No bound was relaxed: one unchanged retry after exercising first-use resources passed all six views. Its original inventory is retained as an inventory, without claiming it certifies that rejected run.

## Rendering workload and frame distributions

Godot official 4.6.3, Compatibility/OpenGL 4.5 Mesa 25.0.7, llvmpipe LLVM 19.1.7 **software rendering**, Linux 13, Xeon Platinum 8573C and five engine-reported CPUs. Window/design/render dimensions are 1280×800; audio uses Dummy, V-Sync/frame cap off, time scale 1, 60 Hz physics/eight maximum steps, real native rendering without forced draws or fixed FPS. Profile writes are disabled. Supported rider/chase settling and screenshot readbacks are outside timed samples. Intervals include CPU/render/presentation, not isolated GPU timer queries.

Original/control use native 3D scale, 2× MSAA, 220 m range and 75 m shadows. Balanced changes batching/interpolation/presentation plus shadows to 45 m. Performance uses 0.75 3D scale, no MSAA and 30 m shadows. Both keep 220 m range and native UI; native occlusion is **off**. Applied actual settings are explicit in the newer Performance/moving reports.

| Supported chase view | Original draws | Repeated old draws | Balanced draws | Performance draws | Original p50/p95 ms | Repeated old p50/p95 ms | Balanced p50/p95 ms | Performance p50/p95 ms |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- |
| Exchange | 1,930 | 1,931 | 1,183 | 1,054 | 773.065 / 877.880 | 1,106.771 / 2,086.841 | 851.952 / 2,101.846 | 208.609 / 366.727 |
| George Square | 933 | 933 | 815 | 749 | 600.912 / 627.981 | 932.686 / 1,689.857 | 969.287 / 1,552.007 | 194.967 / 446.452 |
| Central | 669 | 669 | 603 | 471 | 451.925 / 554.142 | 488.325 / 1,041.954 | 495.374 / 1,659.733 | 189.698 / 491.207 |
| Barras near hall | 1,617 | 1,617 | 1,148 | 983 | 737.310 / 899.118 | 1,134.339 / 1,391.854 | 834.347 / 1,430.663 | 197.156 / 385.083 |
| Clyde | 279 | 279 | 272 | 250 | 273.130 / 415.582 | 287.783 / 605.866 | 301.097 / 698.377 | 96.866 / 222.333 |
| Kelvingrove | 179 | 179 | 158 | 150 | 417.721 / 574.941 | 451.561 / 1,020.867 | 538.808 / 1,630.680 | 154.182 / 343.751 |

Full-game Balanced Exchange/Barras draws fall **38.7% / 29.0%** against the original. This includes shorter shadows; it is separate from [batching-only world counters](../performance-static-20261017/README.md), which show smaller savings and a Central regression. The unchanged control also became slower than the original. Host variability prevents attributing every interval change to game code: Balanced medians improve in the two busiest views versus that control and regress slightly elsewhere, while p95 is mixed. There is **no universal Balanced FPS win** established here.

Performance reduces measured frame cost substantially across all six views in this software run. Aggregate Performance p50/p95/p99 is **186.492 / 392.026 / 545.971 ms**, versus Balanced **672.944 / 1,613.057 / 2,101.846 ms**; counts differ (249 versus 71) because sampling is time bounded. Per-view samples remain small, especially the old/Balanced busy views. These are useful workload/settings diagnostics, far below 60 FPS on this software renderer, and do not predict the Mac's FPS or remove the need for repeated target-hardware measurement.

## Actual-input moving diagnostic

All three trials pass their unchanged movement/turn/deviation/support/recovery gates. Initial placements and stationary warmups are declared; thereafter mapped push/coast/brake/steer inputs drive the body with **no per-tick position, heading or speed correction**. Camera is the production displayed-rider chase, HUD visible. Root inspected all three actual end images: body/board visible, UI intact, market aisle/park/quay supported. These stills cannot prove freedom from temporal shader flicker.

| Trial | Frames | Travel m | Simulated seconds | Absolute turn radians | Maximum route deviation m | Bails / discontinuous recoveries | Completed laps |
| --- | ---: | ---: | ---: | ---: | ---: | --- | ---: |
| Quay weave | 62 | 45.197 | 8.267 | 1.267 | 0.179 | 0 / 0 | 0 |
| Market inner loop | 63 | 43.885 | 8.400 | 3.287 | 0.557 | 0 / 0 | 0 |
| Park rolling loop | 92 | 67.721 | 12.267 | 1.265 | 0.060 | 0 / 0 | 0 |

217 frames cover **120.591946 sampled wall seconds**. Slow rendering advances only 8–12 simulated seconds per trial: these are admitted moving route segments, **not completed city circuits or a full loop**. Every sample exceeds 100 ms on this software renderer. Aggregate p50/p95/p99 is 526.972 / 971.337 / 1,276.197 ms; physics monitor p50/p95/p99 1.318 / 5.315 / 20.729 ms, input-driver p50/p95/p99 37 / 118 / 157 µs. Normal engine process/physics monitors and post-draw intervals have different scopes; do not subtract these percentiles to invent GPU timing. No pre-change moving run exists, so this result establishes tool/route behavior, not a moving improvement delta.

## Next evidence

On the owner's Apple M5, repeat stationary and moving diagnostics at 1920×1080 with Balanced and Performance, retaining hardware/macOS/source/power conditions and raw files. Then record a separate ten-minute human route across all areas, tricks, transitions, grinds and menus with keyboard and real DualSense; compare p50/p95/p99/max and long frames against 16.67 ms. Check cold/first traversal separately from warmed play. Performance is available in Settings now; it preserves current simulation, routes and skyline. No new areas, paid dependency, hosted CI or unattended work was introduced.
