# Current-map performance baseline

17 October 2026, 23:33–23:35 BST (raw receipts use UTC). Clean source `1b20e262b41910da663347d1bc5c73462db4e04d`, Godot 4.6.3 Compatibility/OpenGL, Linux llvmpipe software renderer, 1280×800 actual framebuffer. No other Godot/render job was running. Command:

```sh
./tools/profile.sh --private-display --duration 60 --resolution 1280x800
```

The complete six-view stationary scan passes with 102 measured frames, supported settling, disabled profile writes and unchanged source. [report.json](report.json), [frames.csv](frames.csv), [source-manifest.json](source-manifest.json), engine log and six PNGs retain raw evidence. Artifact hashes are in [artifacts.json](artifacts.json).

| View | Median draws | Median frame ms | p95 frame ms |
|---|---:|---:|---:|
| Royal Exchange | 1,930 | 773.065 | 877.880 |
| George Square | 933 | 600.912 | 627.981 |
| Central Station | 669 | 451.925 | 554.142 |
| Barras | 1,617 | 737.310 | 899.118 |
| Clyde | 279 | 273.130 | 415.582 |
| Kelvingrove | 179 | 417.721 | 574.941 |

These are deliberately honest software-rendered measurements, **not the owner's Apple M5 frame rate or target acceptance**. Small per-view sample counts limit percentile precision. They include the full current actor/HUD/camera and new quay ramps, unlike older world-only snapshots. The scan is stationary and excludes warmup/readbacks; moving visibility changes and first-use hitches need the separate moving diagnostic. Source-manifest SHA-256: `a945e9572e1455f055f9728c22b1b2389131f9305735b224fc41ee17ff3627f5`; report SHA-256: `c10d201f900242e3515137860a0347280ccab98066e9aeaf7ea9b6f9eb4e1378`.
