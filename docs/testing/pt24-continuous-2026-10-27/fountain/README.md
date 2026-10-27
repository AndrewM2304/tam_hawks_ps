# C07 original fountain ornament finish — 27 October 2026

Owner A05, priority P1, milestone M05/M06; independent QE A09. This bounded
display finish depends on the accepted basin/water and C03 coping contracts.
Corrected native acceptance passes16/0. Matched rendered semantic/image/source
checks pass43/0 and every resource gate passes, but timing admission is rejected.
C07 cost/final-art acceptance remains open; failed results below are retained.

## Change and preserved contract

The former three ten-sided closed frusta had redundant straight height rings,
a solid flat bowl top and a cone-like crown. The existing three display slots
now use shared indexed profiles: a moulded pedestal/capital, a recessed stone
cup with an annular lip and a patinated finial whose foot meets the inner floor.
This is an original authored fountain. Inspected Exchange sources E2/E3 in the
[architectural dossier](../../../research/EXCHANGE-GALLERY-REFERENCES.md) inform
the warm stone and moulding vocabulary; they do not establish a real fountain
at this position. No reference image/model, new texture or third-party asset
was imported.

The three node names, transforms, art labels and existing material references
remain. No extra display slot, surface/material, light, body, shape, texture or
per-frame update is added. Construction uses the shared profiles directly,
without allocating and discarding the old primitives first. The declared budget
is at most360 triangles/270 vertices across three original display slots, no
texture or render-memory increase, and both existing view-specific timing caps.
Actual candidate native arrays contain288 triangles/259 indexed vertices.

The authored circular radius/height envelope is preserved, maximum radius1.65m
and topY3.125m. More radial segments deliberately approximate the authored
circular silhouette; this does not claim exact containment inside the former
ten-gon faces. Original water, basin/coping geometry, material sharing, guide ID,
all65 guide points, native collision, route/goal IDs and recovery remain.
The unchanged physical pedestal is a simple radius.7m cylinder reachingY2.7.
The recessed display cup is decorative, not newly playable interior support.

## Rejected native result and precision control

The [first focused run](focused/native-rejected/receipt.json) is rejected15/1.
Its source is frozen in the attached snapshots. All seven existing fountain
checks, two fixture checks and six of seven ornament checks passed. The assumed
decoded tangent/normal dot tolerance1e-4 failed; no geometry was changed to make
that assertion pass.

An isolated [native array diagnostic](focused/arrays/console.log) found zero
invalid winding, degenerate triangles or nonfinite values. Normal length error
is at most1.2e-7, tangent length error at most6e-8 and handedness exact. Maximum
decoded dot error is0.00016746, an angular deviation below0.00960degrees.

The independent [built-in packing control](focused/packing-control/console.log)
demonstrates the same native precision in Godot4.6.3. A built-in ten-segment
pedestal with the same former radius/height profile yields0.007112degrees, and
an eighteen-segment control uploaded through ArrayMesh yields0.007534degrees.
The control uses three height subdivisions; it proves direction packing, not
the old mesh's exact cost (the original display helper uses four). Native
ArrayMesh format is34359742487. All control winding, finite, handedness and
degenerate checks remain clean. The corrected diagnostic completed in0.201s.

The test therefore declares a0.02degree tangent/normal angular allowance from
normalized decoded directions and reports the actual worst angle. The authored
analytical basis is orthogonal before native packing. Unit length, finite data,
handedness, index validity, clockwise winding, shape/envelope, material/resource
and unchanged-native checks retain their strict criteria. Independent QE agreed
with this precision correction; it does not establish rendered acceptance.

The [corrected focused run](focused/native-current/receipt.json) passes16/0,
clean/stable644 inputs in7.274s. Seven existing water/contact checks and seven
ornament checks run with two isolation fixtures. Actual maximum native frame
angle is0.009594708degrees. Displayed triangle intersections find floor/finial
footY2.079999924m, inner wallY2.155000210m and lipY2.349999905m. The two unchanged
native cylinders and actual centre support atY2.7 remain verified.

The [first packing observer](focused/packing-observer-rejected/receipt.json)
used an unsupported PrimitiveMesh format query. Its API failure and exact
observer snapshot remain separate from the ornament geometry result.

## Matched rendered result: resource pass, timing rejection

The [executed comparison](render/receipt.json) uses three fresh native processes: exact former
ornaments, current profiles, then exact former ornaments again. Only the three
ornament constructors are restored in an ignored World copy; an ignored Main
copy changes only its World preload. Old processes do not instantiate candidate
meshes. All other game, rider, shader and feature source is identical.

Each phase uses ordinary default-enabled Main, persistence false before tree
entry,30 ordinary native updates and equal semantic fixture frames. Gameplay is
then explicitly paused, HUD hidden and two labelled authored views used at
960x640/Balanced/Compatibility: cup overhead and court approach. Each view has
18 warm frames and36 measured native frame_post_draw intervals at the same
camera bearings. The shared water shader TIME remains live. All216 intervals,
native viewport/Performance counters, six native PNGs and exact input identity
are retained with this record. The outer execution completed in183.570s with
clean/stable644 inputs. Per-phase internal maps bind649 identical inputs and
all three phases have the same camera/physics-frame counters. Original-A/B PNGs
are byte-identical. Phase assertions pass12/0,19/0 and12/0 respectively; those
assertions do not include the separately rejected timing comparison.

The previously declared water-control timing caps apply independently to each
view: candidate p95 and p99 must be no greater than both control midpoint plus
absolute repeat spread plus5% midpoint, and1.05 times the worse control.
Draw/object/texture counts must match both controls at every bearing; primitive,
render-buffer and video bytes must not exceed the worse matching control.
No failed view is pooled or waived. The [raw comparison](render/comparison.json)
rejects the candidate because two individual timing cells fail:

| View / phase | p50 ms | p95 ms | p99 / maximum ms |
| --- | ---: | ---: | ---: |
| Overhead / original-A |115.106|133.775|137.232|
| Overhead / current |113.744|132.258|157.450|
| Overhead / original-B |112.400|139.847|144.131|
| Approach / original-A |414.029|452.737|460.083|
| Approach / current |411.642|494.563|505.556|
| Approach / original-B |414.572|470.949|883.299|

Overhead current p99 exceeds its stricter151.33755ms cap. Approach current p95
exceeds its stricter494.49645ms cap by0.06655ms; it is still rejected without a
rounding exception. The other two timing cells pass. Every one of the216 samples
exceeds16.667ms,33.333ms and50ms on llvmpipe. Lower medians, geometry counts or
successful assertions do not establish timing acceptance or explain the tails.
No repeat was run to replace these results.

Every matching bearing passes the declared resource criteria. Native visible
draws/objects are238–393 overhead and843–871 on approach in every phase; total
draws and texture bytes match both controls. The current meshes remove72 visible
and total primitives at every bearing. Render-buffer and video bytes each fall
by740 (27,194,106→27,193,366 buffer;71,535,007→71,534,267 video). Texture memory is
unchanged at44,340,901 bytes. Actual old geometry is360triangles/270vertices and
current geometry288triangles/259vertices, both with three single-surface slots.

| Native frame | Original-A | Current profile | Original-B |
| --- | --- | --- | --- |
| Cup overhead |[PNG](render/original-a/cup-overhead.png)|[PNG](render/profile/cup-overhead.png)|[PNG](render/original-b/cup-overhead.png)|
| Court approach |[PNG](render/original-a/court-approach.png)|[PNG](render/profile/court-approach.png)|[PNG](render/original-b/court-approach.png)|

The lower approach makes the annular lip and slimmer flared finial visible;
the shallow recess is subtle from the near-vertical overhead view with existing
stone mapping. These actual frames establish the bounded displayed change and
preserved surroundings; they do not close human visual acceptance.

Exact observers/producers and ignored legacy copies are retained under
[observers](observers/) and [render/source-snapshot](render/source-snapshot/).
Hashes were checked against the original complete execution maps, including all
six native PNG hashes. The commands used were:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/fountain-ornament-native-packing-corrected timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/fountain_ornament_focused.gd
python3 .local/prepare_fountain_ornament.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/fountain-ornament-render timeout 300s bash .local/fountain_ornament_capture.sh
python3 .local/compare_fountain_ornament.py
```

The comparator exits1 for the timing rejection. Its thresholds and raw samples
were not changed after execution. The source preparer ran before the frozen
render block and restored only the three former constructors/default ring count.

Linux software diagnostics cannot certify target-Mac performance, normal chase
play, physical controls, final world art or human visual/fun acceptance. Those
remain separate open gates and do not hide the merged trial content.
