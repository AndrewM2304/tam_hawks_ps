# Half-pipe toe rendering repair — 18 October 2026

The actual first six-area run exposed a dotted line at the east toe in `halfpipe-08/13`. The flat's rendered BoxMesh top was6mm above the curved toe; its thin exposed side produced the line. Collision had already been repaired separately to meet the toe atY2.000.

**Retained:** a two-triangle PlaneMesh at the same four rendered top corners,Y2.006, with the original shared world-triplanar material and **shadow casting ON**. The physical BoxShape remains unchanged. It replaces the12-triangle visible box, adds no node/material/texture/surface and keeps one normal-play resident mesh. The alternative shadow-OFF plane is rejected after its north p95 gate fails. Do not enable it merely because it reports one fewer draw.

## Bounded native comparison

[Receipt](receipt.json):12:11:26–12:15:30 Europe/London, exit0, clean log, **348 unchanged inputs** (346 runtime/asset/test/tool/project files plus two executed local recipe files). Godot4.6.3 Compatibility/llvmpipe, four Mesa workers,960×600,0.75 rendering scale, MSAAOFF, near/far0.2/220m,FOV68°, directional shadows30m. Two authored world-only observers use the prior actual chase origins with target+0.95m. There is no player/HUD/input in this diagnostic; world processing is disabled, while the Clyde water shader still animates.

Each view runs Box-before → Plane-shadow-ON → Box-between → Plane-shadow-OFF → Box-after,15warmups and120measured native frames per phase: **1,200 samples /10decoded PNGs**. Readbacks follow each measured window. [Measurements](measurements.json) preserve every frame/counter; [admission](admission.json) applies the unchanged strict gate: candidate p95 and p99 must each be≤control midpoint+absolute control difference+5% midpoint and≤105% of the larger control. Draws/primitives must not increase.

| View | Box / retained plane / Box p95 ms | p99 ms | Draws | Reported primitives | Gate |
|---|---|---|---|---|---|
| East/north |481.473 /492.744 /321.229 |727.607 /610.367 /514.227 |907 /907 /907 |567064 /567054 /567064 |Pass |
| East/south |205.547 /183.698 /183.854 |336.629 /408.523 /410.403 |86 /86 /86 |79348 /79338 /79348 |Pass |

This is a retention pass with noisy software-rendered controls, **not an FPS improvement or target-Mac performance claim**. The diagnostic holds both meshes for swapping; the PlaneMesh's124-byte lazy buffer upload in the monitor is not an isolated normal-play allocation delta. Normal play creates only the selected plane.

## Actual pixels and source disposition

Root inspected both actual Box/Plane-shadow pairs. The dotted join disappears in the selected plane images. North's three Box controls are pixel-identical; replacing the box changes214pixels, all in the floor half. South's upper animated water changes between controls, but its lower half is pixel-identical across all Box controls; replacing the box changes291lower-half pixels. [Decision and all image hashes](decision.json) retain these comparisons and decoding results. Sparse stills do not certify moving-camera flicker.

The frozen candidate source defaulted its plane shadow casting OFF; the driver explicitly sets ON for the admitted phases. After capture, root removed the candidate-only OFF assignment so production uses the admitted ON state. Executed driver/wrapper, exact candidate source/test snapshots, before/after hashes and failed OFF measurements remain here. The full subsequent game tour/regression must bind final source independently.

Focused physical geometry checks pass **40/0**, including actual collision at both toe joins and all four original visible top corners. [Log](../diagnostics/geometry-focused-02.log). The12-second actual W-only pipe and six-area final tour remain separate from this stationary diagnostic. Existing distant boundary gaps and final realistic art are not solved by this small repair.
