# 96m tree-cell experiment — 17 October 2026

**Rejected as a production default.** The normal Kelvingrove checkpoint adds **16 draw calls with zero submitted-primitive reduction**. Production retains exact primitive sharing alone; tree partitioning is an explicit diagnostic option.

Actual Godot 4.6.3 Compatibility rendering, **1280×800**, Linux **llvmpipe (LLVM 19.1.7, 256 bits)**. Command: `./tools/render_budget_probe.sh --private-display`, with the helper's tree-cell constant set to **96m** for this experiment. The same production world renders before and after the helper in one process, with identical fixed cameras, two warmup frames and three counter samples per phase/view. It excludes rider, HUD and encounter simulation and makes no FPS, Mac or gameplay CPU claim.

The wrapper accepted **16 actual PNGs**, source-stable inputs and exact preservation of **110** tree-instance records including transforms/colours/custom data/materials/layers/shadow state. There are no script/engine errors; the dummy display reports its expected unsupported V-sync warning. All eight before counter sets exactly reproduce the [48m run](../render-budget-20261017/README.md).

| View | Draw calls before → after | Submitted primitives before → after | Actual images |
|---|---:|---:|---|
| Royal Exchange | 1,576 → 1,580 | 807,606 → 772,006 | [before](before-royal_exchange.png) / [after](after-royal_exchange.png) |
| George Square | 660 → 656 | 720,870 → 329,270 | [before](before-george_square.png) / [after](after-george_square.png) |
| Central Station | 567 → 573 | 466,078 → 430,478 | [before](before-central_station.png) / [after](after-central_station.png) |
| Barras | 1,271 → 1,273 | 1,000,274 → 879,234 | [before](before-barras.png) / [after](after-barras.png) |
| Clyde | 146 → 146 | 147,552 → 147,552 | [before](before-clyde.png) / [after](after-clyde.png) |
| Kelvingrove | 73 → 89 | 465,538 → 465,538 | [before](before-kelvingrove.png) / [after](after-kelvingrove.png) |
| Park north | 54 → 62 | 462,560 → 391,360 | [before](before-park_north.png) / [after](after-park_north.png) |
| Park south | 444 → 456 | 606,290 → 535,090 | [before](before-park_south.png) / [after](after-park_south.png) |

Counts are three-sample medians; [report.json](report.json) preserves raw samples. This candidate replaces two park-tree MultiMeshes with **10** cells: nodes **3,927→3,935**, MultiMesh nodes **762→770**, unique mesh resources **1,419→324**, bodies **338** / collision shapes **1,850** unchanged. The resource-sharing improvement is independent of tree chunking. Camera distance remains 220m and directional shadows 75m.

The park-north, Kelvingrove and George Square images are pixel-identical between phases. Other land views have only isolated raster differences; Clyde's animated water changes with `TIME`. Content preservation passes, but the normal park checkpoint's counter regression prevents claiming uniform rendering efficiency. Current grass/foliage remain temporary art.

[artifacts.json](artifacts.json) fingerprints all images, source manifest, report and engine log. Report SHA-256: `ba785b22eef03648e952087581557a245f9d6e27d1a8c079c83680da46b721aa`. Source manifest SHA-256: `4dc3d3dbdab972dffb786f438859268245ab2e6c17ca52b631e514aa04c35f3a`. The source precedes production-default integration and the explicit optional flag; these hashes identify this experiment only.
