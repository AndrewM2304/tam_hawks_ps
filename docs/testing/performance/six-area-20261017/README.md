# Six supported checkpoint views — 17 October 2026

Actual Godot 4.6.3 rendered diagnostic, completed at 16:28 UTC. See [PERFORMANCE](../../PERFORMANCE.md) for method, complete metrics, source identity and limits. This is Linux llvmpipe software rendering, not Apple Silicon acceptance or a moving gameplay test.

Command: `./tools/profile.sh --private-display --duration 60 --resolution 1920x1080`.

The report preserves the exact original invocation and dirty working-tree provenance based on `64000fd`. All 101 source inputs stayed unchanged; six views, 114 frames, 49.279667 sampled seconds. All PNGs below are unmodified actual 1920×1080 screenshots captured after their timed intervals. They were inspected after the run; each retained the production rider, chase camera and HUD.

| Image | Actual view and scope |
|---|---|
| [royal_exchange.png](royal_exchange.png) | Supported spawn looking north through the fountain court |
| [george_square.png](george_square.png) | Supported civic checkpoint looking north toward terraces and the cat workshop |
| [central_station.png](central_station.png) | Supported checkpoint facing northwest beneath the station canopy |
| [barras.png](barras.png) | North-facing checkpoint near the hall's brick side; not the open market aisle or full-district cost |
| [clyde.png](clyde.png) | Supported north quay checkpoint facing south across the river |
| [kelvingrove.png](kelvingrove.png) | Supported park checkpoint facing northwest toward the paths/hills |

`report.json`, `frames.csv`, `source-manifest.json`, `engine.log` and the image files are fingerprinted in `artifacts.json`. Each report view also contains its source-manifest, screenshot and canonical raw-row hashes. Recomputed CSV counts, durations, FPS/quantiles and all artifact hashes match. Independent QE separately audited all 114 rows, timing/counter summaries, ten artifact hashes and 101 current source hashes, and fully decoded all six PNGs. No historical improvement percentage, human feel, controller/audio certification or final-art approval follows from these stationary views.
