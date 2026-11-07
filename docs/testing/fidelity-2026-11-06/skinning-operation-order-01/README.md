# Native skinning operation order — independent QE, 7 November 2026

**FID-D016/P2 reproduced.** Native Godot skinning weights local bone matrices,
then applies the actual mesh model transform once. The inherited contact helper
and its test reference weight the world translation per influence. These disagree
when valid decoded UNORM16 weights sum to less than one.

The actual native jacket vertex924 has weights0.579995393753052 and
0.419989317655563, sum0.999984711408615. An independent official-shader equation
reconstruction finds about1.7mm error with model Z112m and15.5mm at1012m. Exact
float32 observations and double-precision references are separately retained.

The active GPU epoch uses those actual decoded values in an isolated native
ArrayMesh/Skin triangle with a genuine1mm bone translation. A world-coordinate
shader encodes world Z into red. Native red remains153 at mesh Z0/100/1000m;
the detached-Skin negative gives128. The old world-weighted equation predicts
about114 and0 at100/1000m. Blue and Canvas epoch tags, native RGBA/PNG hashes
and unchanged readback counters authenticate all four natural frame_post_draw
readbacks. The native Skeleton stays at world0, distinguishing the actual mesh
model from a presumed Skeleton model. All four originals were personally opened.

The original identity-bone epoch remains its narrower model-translation diagnostic;
it does not alone prove the skin stage executed. The failed initial direct Godot
startup is retained separately. The successful headless retry took1.52s, and GPU
epochs took14.85/12.78s under20s process deadlines. These are wrapper durations,
not target frame-time measurements. Source before/after791-input byte equality
belongs to each GPU epoch; no earlier source-before record was invented.

[Independent checks and exact observations](independent-review.json) include the
actual native weights, bind matrices, model transforms and arithmetic. The exact
executed observers/wrappers, native originals, raw engine logs, receipts and source
inventories are retained. [Official4.6.3 source excerpts](official-source-excerpts.json)
record upstream URLs, full-file SHA256 and exact line ranges; the upstream MIT
licence is retained. The native CPU mesh-bake API uses a different residual-rest
formula, so it was rejected as a sole GPU oracle before any comparison used it.

The private corrected contact helper still needs its complete native trajectory,
resource-cache/budget, malformed-input and existing gameplay regressions. No full
Main, realistic-rider, visual-motion, M5, physical-controller or AAA pass is claimed.
