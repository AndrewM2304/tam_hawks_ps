# Park canopy density comparison

Matched **actual Main** views show the original procedural canopy before and after its density repair. The park scene already contains the new sunken facility. All 68 listed game/project/capture inputs stayed unchanged within each run; **only `game/levels/art/foliage_mesh.gd` changed across the pair**. Camera positions, targets, FOV and 1280×800 resolution match exactly. See the unmodified [before](before-manifest.json) and [after](after-manifest.json) receipts and [comparison](comparison.json).

| View | Before | After |
|---|---|---|
| Ground / steep gate | [Original sparse crown](before-steep-gate-ground.png) | [Connected irregular leaf layers](after-steep-gate-ground.png) |
| Park overview | [Original](before-overview-park.png) | [Denser canopy](after-overview-park.png) |

The original deterministic canopy now combines 792 folded leaves with 99 irregular opaque leaf sprays and its 44 tapered branches. Overlapping inner layers fill the empty branch cage while uneven outer lobes retain individual leaf edges. It remains one cached mesh/surface and one opaque, double-sided material. Tree placements, vegetation batching, native collision and source asset/licence scope are unchanged; no spheres, alpha billboards or downloaded assets were added.

| Local measurement | Before | After |
|---|---:|---:|
| Canopy triangles | 3,080 | 4,796 (+55.7%) |
| First mesh build | 12.668 ms | 21.155 ms |
| Overview primitives | 777,081 | 928,089 |
| Ground primitives | 649,261 | 800,269 |
| Overview draw calls | 393 | 393 |
| Ground draw calls | 304 | 304 |
| Overview median draw + readback | 1,289.730 ms | 1,422.712 ms |
| Ground median draw + readback | 585.251 ms | 919.230 ms |

These are five local **Mesa software rendering** samples per view, excluding PNG encoding. Raw samples remain in the receipts; they show warm-up/load variation and include a 5,101.389 ms after-run outlier. They are a small cost comparison, not sustained game FPS, a speedup claim or target-Mac performance evidence. The two [render](before-render.log) [logs](after-render.log) each report **5 checks, 0 failures**, covering cache/material, saved views and within-run source stability.

The [capture recipe](capture-recipe.gd.txt), [display wrapper](display-wrapper.sh.txt), byte-exact [before source](before-foliage-source.gd.txt) and [after source](after-foliage-source.gd.txt) preserve replay/provenance. The [archive receipt](archive-receipt.json) maps copied files to original paths and hashes. Original receipt paths/hashes were not rewritten.

This is a scoped foliage inspection checkpoint with a paused native scene and inspection cameras. Later facility/controller changes require their own final integration evidence. It does not claim a complete final movie, gameplay-camera acceptance, physical-controller testing, target-Mac certification or final-art acceptance.
