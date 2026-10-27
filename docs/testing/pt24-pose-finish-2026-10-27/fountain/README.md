# PT24-26 shared fountain water finish — 27 October 2026

The fountain now reuses the **same existing water material instance** as the
Clyde and park pond. It previously used the generic opaque metallic window/glass
finish, which produced a flat reflective disk. The original water shader supplies
restrained moving normals and filters subpixel wavelengths. It changes no vertex
positions, rim, native support, coping guide or recovery policy.

The production change is one material assignment after outdoor construction,
with two explanatory comment lines in `game/levels/glasgow_square.gd`. There are
**zero additional materials, shaders, textures, meshes, triangles, lights, bodies
or shapes**, and no new CPU update loop. The existing original shader is unchanged.
Final fountain art, actual Mac moving-rim appearance and owner acceptance remain
open; the faceted central ornament has not been rebuilt by this slice.

## Bounded native checks and source epoch

`tests/fountain_finish_tests.gd.run(tree, game, check)` adds **seven checks** on
ordinary default-enabled Main: shared material identity, exact fixed water mesh,
all768 face vertices, both original native shapes,32 actual basin ray contacts,
unchanged absence of a fountain recovery trigger, and the same65-point closed
coping identity. Root registers it in ordinary Main integration. Existing full
Gallery/coping input tests remain the movement/scoring acceptance, rather than
repeating those runs for a material assignment.

The actual native observer passes **19/0**, exit0, clean with **622 unchanged
inputs**,158.742s. It ran15:55:02–15:57:41 London time on27October2026. Exact
[receipt](validation/receipt.json), [log](validation/console.log), and
[source maps](validation/source-before.json) are retained. Manifest SHA256:
`f315ed04bd5d6bc7fc362233a4907535b4b0496857f7cb149d15f399f684d644`.

These frames belong to their recorded **intermediate batch source**, based on
main`b257b5682bdd40310660cc4be8b40ba20717ee7f`; later wall hull/input registration
work is not relabelled as tested by these frames. Every non-parent capture input
is preserved byte-for-byte in [source-snapshot](source-snapshot/MANIFEST.json).
Unchanged inputs resolve to that immutable Git parent. The fountain production
file itself is exact in this snapshot. The later full batch receipt owns final
integration admission.

## Actual A/B/A views and cost

The observer creates real Main with persistence disabled **before** tree entry,
uses ordinary default content and normal free-skate start, and lets30 native
updates finish. It then explicitly pauses gameplay, hides HUD and uses labelled
authored cameras. These are world finish observations, not ordinary chase or
route-play screenshots. No input/content/score/pose override establishes a run.

For each overhead and low inner-rim bearing, A restores only the prior shared
glass override, B uses the actual shared water override, and A restores the same
glass again. Each phase has18 warm rendered frames followed by60 identical
slightly moving camera positions,960×640 Balanced Compatibility rendering, and
native `frame_post_draw` wall-clock samples. Water shader TIME stays live. Six
unmodified completed viewport PNGs and all360 raw samples are in
[captures](captures/manifest.json). Both pairs of original A controls have
**byte-identical PNGs**; [read-only pixel comparisons](captures/pixel-comparison.json)
record133,247 changed water-view pixels overhead and90,886 at the low rim.

| View | Original A p50 / p95 / p99 ms | Shared water p50 / p95 / p99 ms | Original B p50 / p95 / p99 ms |
| --- | --- | --- | --- |
| Overhead |111.035 /134.345 /150.086 |107.796 /121.704 /126.088 |107.900 /121.456 /124.371 |
| Low inner rim |412.692 /450.813 /484.916 |412.289 /461.062 /474.659 |414.304 /465.881 /513.636 |

Both views independently pass both existing water-control p95/p99 caps:
control midpoint + absolute repeat difference +5% midpoint, **and**1.05×the
worse original control. No failed view is pooled or waived. Draws, visible and
total primitives, objects and texture/buffer/video bytes match at **every matching
camera sample**. Video memory is71,516,951bytes, texture44,340,901bytes and
buffer27,176,050bytes throughout. See [complete comparison](captures/comparison.json).

This is Linux **llvmpipe** diagnostic evidence. All360 samples exceed50ms;
it is not a60fps result or a target-Mac performance pass. Short sweeps and six
stills cannot certify long-play timing, target moving-shadow stability, final
realistic art or human visual acceptance. The overhead and low frames show the
same fitted circular boundary, fixed coping and unchanged surrounding world.

## Repeat the bounded observer

From the repository root, stage the exact observer copies under ignored`.local`:

```sh
cp docs/testing/pt24-pose-finish-2026-10-27/fountain/observers/fountain_capture.gd .local/fountain_capture.gd
cp docs/testing/pt24-pose-finish-2026-10-27/fountain/observers/fountain_capture.sh .local/fountain_capture.sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-fountain-finish-native bash .local/fountain_capture.sh
python3 docs/testing/pt24-pose-finish-2026-10-27/fountain/observers/compare.py .local/fountain-finish-captures/manifest.json
```

Serialize this with all other engine/render workloads. The launcher has a240s
bound and tears down its temporary Xorg display. A future rerun on newer code
creates new evidence; it does not replace this immutable source-bound record.
