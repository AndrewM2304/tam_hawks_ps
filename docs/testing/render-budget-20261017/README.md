# Render budget before/after — 17 October 2026

**48m experimental tree-cell candidate; rejected as a production default.** Production keeps exact primitive sharing only. The [96m follow-up](../render-budget-96m-20261017/README.md) also failed to improve the normal park checkpoint's draw/primitive tradeoff.

Actual Godot 4.6.3 Compatibility rendering, **1280×800**, Linux **llvmpipe (LLVM 19.1.7, 256 bits)**. Command: `./tools/render_budget_probe.sh --private-display`.

The same production world is rendered before and after `RenderBudget.apply_static_decor(world)` in one process, using identical cameras. There is no rider, HUD, encounter simulation or frame-time benchmark. Physics bodies remain present but the world is frozen. Six cameras use the recorded district checkpoint viewing directions, with two extra opposing park views. Two warmup frames and three actual renderer counter samples are recorded per phase/view. No paid tools, asset downloads or profile writes occur.

The wrapper accepted **16 actual screenshots**, clean script/engine logs, stable source inputs, and exact preservation of **110** tree instance records including transforms, colours, custom channels, mesh/material identity, visibility, layers and shadow mode. The only warning concerns unsupported V-sync switching on the dummy display.

| View | Draw calls before → after | Submitted primitives before → after | Actual images |
|---|---:|---:|---|
| Royal Exchange | 1,576 → 1,588 | 807,606 → 757,766 | [before](before-royal_exchange.png) / [after](after-royal_exchange.png) |
| George Square | 660 → 656 | 720,870 → 329,270 | [before](before-george_square.png) / [after](after-george_square.png) |
| Central Station | 567 → 581 | 466,078 → 419,798 | [before](before-central_station.png) / [after](after-central_station.png) |
| Barras | 1,271 → 1,271 | 1,000,274 → 832,954 | [before](before-barras.png) / [after](after-barras.png) |
| Clyde | 146 → 146 | 147,552 → 147,552 | [before](before-clyde.png) / [after](after-clyde.png) |
| Kelvingrove | 73 → 109 | 465,538 → 447,738 | [before](before-kelvingrove.png) / [after](after-kelvingrove.png) |
| Park north | 54 → 78 | 462,560 → 352,200 | [before](before-park_north.png) / [after](after-park_north.png) |
| Park south | 444 → 468 | 606,290 → 485,250 | [before](before-park_south.png) / [after](after-park_south.png) |

Counts are medians of the three samples; raw sorted samples are in [report.json](report.json). They are renderer-submitted primitive counts, not unique asset triangles. Draws can increase when a single batch becomes several smaller culling cells. The normal park checkpoint gains only a small primitive reduction while adding draws; this is not a claim of uniform faster rendering. No Mac FPS, gameplay CPU, animation, rapid-camera-turn or final realistic-art acceptance follows.

World inventory changes: **3,927→3,947 nodes**, **762→782 MultiMesh nodes**, **1,419→324 unique mesh resources**, **338 physics bodies and 1,850 shapes unchanged**. The helper shares 1,095 duplicate primitive assignments and divides two 55-tree batches into 22 local batches. The camera retains its 220m far plane, and the directional light retains 75m shadow range. No district is hidden or unloaded.

Actual park images were inspected for lost foliage/shadows. George Square, Kelvingrove and park-north RGB images are pixel-identical between phases. Other land views have only isolated subpixel differences (mean absolute channel difference <0.001 on an 8-bit channel); Clyde's animated `TIME` water changes in its visible band. Broad grass and sparse foliage still need higher-fidelity art; these images do not close that work.

[artifacts.json](artifacts.json) fingerprints all actual PNGs plus the engine log, report and source manifest. Report SHA-256: `75dd20ff4a79e336c0189e891f235efa99e0cd49bd96360c3d2517808221b335`. Source-manifest SHA-256: `9f1811fdbc852bcb0440f8d1f290631e4202a2cdac58ca07a4918764778fd82d`. This is a direct-helper before/after diagnostic before normal-world integration; later source/handoff changes must not be described as having these exact source hashes.
