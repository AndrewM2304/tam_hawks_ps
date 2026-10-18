# Final matched facade measurements

All ten datasets pass source/artifact/decoded-image/CSV validation: **52 images**, **309 executed inputs unchanged per run**. Two exact post-measurement changes are verified: the report-only shadow-counter clarification and the rejected normal-default toggle. Executed checkpoint: `c2e86ab`. **Feature retention gate: FAIL; normal play remains disabled.**

Reported3D draws include shadow work; Compatibility’s separate SHADOW counter is unavailable for separation. The <=4 draw gate covers stationary views. Timings are short Linux/llvmpipe diagnostics, not Apple M5 FPS or statistical certification.

| Size | View | p95 A1 / B / A2 (ms) | p99 A1 / B / A2 (ms) | Reported3D draw delta | Gate |
|---|---|---:|---:|---:|---|
| 1280×800 | spawn | 1138.2 / 1129.6 / 1189.5 | 2016.2 / 1289.8 / 1304.9 | 3.0 | pass |
| 1280×800 | 02-frontage-wide | 934.8 / 799.1 / 1176.3 | 964.7 / 926.0 / 1235.1 | 2.0 | pass |
| 1280×800 | 03-frontage-near | 741.0 / 1482.7 / 1272.1 | 808.8 / 1622.9 / 1567.7 | 2.0 | FAIL |
| 1280×800 | exchange_west_bank_loop | 845.0 / 1337.3 / 1360.5 | 995.1 / 1898.5 / 1607.7 | not separated | FAIL |
| 1920×1080 | spawn | 2015.2 / 1864.5 / 1919.9 | 2144.9 / 1974.0 / 2017.7 | 3.0 | pass |
| 1920×1080 | 02-frontage-wide | 1769.9 / 1686.4 / 1628.5 | 2114.8 / 1711.2 / 1885.0 | 3.0 | pass |
| 1920×1080 | 03-frontage-near | 2176.9 / 1947.1 / 1612.5 | 2658.2 / 2209.8 / 1650.7 | 2.0 | pass |
| 1920×1080 | exchange_west_bank_loop | 2001.3 / 2237.5 / 1814.1 | 2421.7 / 2634.7 / 1954.8 | not separated | FAIL |

The gate rejects p95/p99 growth exceeding both peak-to-peak repeat noise and 5% of the baseline midpoint, and also caps at 5% above the worse baseline. The stricter cap rejects the candidate despite substantial host drift. No FPS gain or Mac slowdown follows from these observations. All six moving trials pass actual-input motion/turning/corridor gates with zero bails/recovery teleports; exact distances/laps/clocks remain in the reports.

Repeat with new `.local/` output directories using `python3 tools/facade_bay_probe.py profile off … --seconds 20`, then on/off at1280×800; use `--size 1920x1080 --seconds 30` for1080p. Captures use `capture on/off`. `audit.py` verifies the retained executed scripts and permits only the two declared text changes; it exits1 for the intentionally failed feature gate.
