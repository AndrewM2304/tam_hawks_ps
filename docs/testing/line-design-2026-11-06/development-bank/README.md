# First terminal-bank native diagnostic

Command: `./tools/run.sh --headless --fixed-fps 60 --script .local/line_bank_runner.gd`. Run completed7November2026 approximately00:01UTC: **9passed/0failed, engine0, no script/resource errors**. This is a development diagnostic against changing shared November source, not a frozen integrated acceptance or performance measurement. The exact log is retained. Independent QA must replay the final source.

Actual native geometry: boundsX[80.8,84.7], Z[71.62333,77.8]. Original4shape slots and one display remain. Closed bank/wall profile has80native and80display triangles, compared with48original prism triangles: **+32triangles**, zero added bodies/shapes/meshes/materials/textures. Eighteen independent points matched actual ray, displayed triangle, query height and bank normal; nine elevated rays preserved opaque backing; five two-way diagonal mouth/shoulder sweeps and ordinary no-jump Barras exit passed.

| Actual speed at input release | Peak native position | Release→observed native reversal | Release→old toe witness |
| --- | --- | --- | --- |
|3.1888m/s|(81.5387,2.4214,74.7116)|63physics ticks=1.050s|113ticks=1.883s|
|3.9139m/s|(81.9201,2.6251,74.7119)|73ticks=1.217s|344ticks=5.733s|
|4.7241m/s|(82.4401,2.8918,74.7121)|88ticks=1.467s|405ticks=6.750s|

All three climbs, native stops/reversals and returns retained support, clear full-model chase, zero bails/recoveries and no hidden trick/capture award. The high-speed returns coast slowly near the toe, so this is **not** a smoothness/fun pass. The first fixture also stopped atX80.6, where part of the upright capsule/board can still straddle the toeX80.8. Final fixture is stricter: X80.3 fully clears it; native grade gravity must establish negative speed first, then ordinary mapped fakie Push continues the supported re-entry. That input is recorded explicitly; no velocity, yaw or position is forced after spawn.

Matched rendered discovery views, awkward/high-speed attempts, connected full relay/return, final unchanged-resource audit, uncontended performance and actual M5/human finish remain open.
