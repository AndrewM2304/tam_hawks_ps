# Near facade material attribution — 28 October 2026

This continues the accepted C07/C10 reduced four-slot facade diagnostic after
the gameplay package handoff. It makes no production change or admission claim.
The historical failed six-cell cost cohort retains its own source and limits.

## Corrected sequence: valid diagnostic, no attribution signal

After preserving the first rejected epoch, one harness line gained a short-circuit
`typeof` check before comparing values. This safely distinguishes a Resource's
Dictionary contract from a null texture's String contract. Property representation,
expected changed-field checks and every production input remain unchanged.
The exact old and corrected harnesses are retained in their sequence snapshots.

The [fresh parser](corrected-parser/receipt.json) passes in 1.255 seconds. The
[corrected bounded run](corrected-bound/receipt.json) passes in **228.047 seconds**,
exit 0, clean log, 677 unchanged outer inputs at the same `c61ac7a` source. The
inner sequence binds **676 inputs: 672 committed Git blobs and four exact ignored
harness snapshots**; every blob/snapshot hash was independently verified.

| Phase | Samples | p50 ms | p95 ms | p99 ms |
| --- | ---: | ---: | ---: | ---: |
| First full control | 46 | 434.856 | 474.464 | 500.876 |
| Normal disabled | 46 | 431.479 | 471.163 | 477.460 |
| Constant ORM roughness | 46 | 437.172 | 461.443 | 478.826 |
| Both controls | 47 | 429.295 | 456.959 | 463.772 |
| Final full control | 43 | 461.594 | 521.957 | 591.909 |

The p95 control midpoint is **498.2105 ms**, with **47.493 ms** bracket variation;
the p99 midpoint is **546.3925 ms**, with **91.033 ms** variation. Even disabling
both maps improves the midpoint by only **41.2515 / 82.6205 ms**, below those
respective control differences. All three candidates fail the declared
beyond-bracket-noise criterion, although their midpoint reductions exceed five
percent. **No material cost attribution is established. Keep the original maps.**
An unchanged retry or reverse-order confirmation is not justified by this result.

All five phases have identical medians: **1,097 total draws, 1,084 visible draws,
zero shadow draws, 613,761 primitives, 1,165 render objects and 5,212 nodes**.
Reported texture/buffer memory remains **57,666,621 / 27,849,870 bytes**. These
counters bind matched diagnostic work; they do not establish target performance.

The author inspected all five original PNGs. Geometry, four shopfronts, signage,
window rhythm, composition and ordinary content stay present. Fine sandstone
shading changes as intended; the diagnostic removes detail deliberately and is
not a final-art candidate. An independent reviewer recomputed every CSV percentile,
all counter comparisons, 35 per-phase artifact hashes and all source bindings;
the recorded no-signal conclusion matches that review.

[Corrected readout](CORRECTED-READOUT.json), [raw comparison](corrected-sequence/comparison.json)
and [complete artifact index](ARTIFACTS.json) retain exact results. No game,
test, tool, project, art asset or production default changed. Existing failed
facade cost gates, target-Mac/human acceptance and C07/C10 remain open; this
bounded attribution attempt is complete without supporting a material downgrade.

## First sequence rejected: harness contract comparison

Source main `c61ac7ad83ddd62123aa085a3319613b9c399db4`, Godot 4.6.3,
1280×800 Balanced/Compatibility, Linux llvmpipe, one uncontended native process
at a time. The same near camera and geometry were used. Ordinary content stayed
on, personal Music/profile persistence stayed off before Main entered the tree,
and sampling used completed rendered frames without a fixed clock.

The [parser](first-parser/receipt.json) passes exit 0, clean log, 677 unchanged
inputs in 1.356 seconds. The complete ignored harness dependency closure is
explicitly included in the command/source maps.

The [bounded sequence](first-bound-rejected/receipt.json) rejects in 182.260 seconds,
exit 1, with 677 unchanged inputs. The [inner sequence](first-sequence-rejected/sequence.json)
completed full and no-normal phases, then stopped at constant-ORM. Its material
contract loop compared the original texture's Dictionary representation with
the removed texture's String/null representation, causing a GDScript runtime
error at `near_material_ablation.gd:84`. The per-process 90-second timeout
terminated that engine and its display. Both/baseline-repeat were never run.
The outer console has no error marker because this error is in the retained
[phase engine log](first-sequence-rejected/r/engine.log); outer `valid=false`
and exit 1 remain authoritative. No timing attribution is admitted.

| Completed phase | Samples | p50 ms | p95 ms | p99 ms |
| --- | ---: | ---: | ---: | ---: |
| First full control | 46 | 442.249 | 473.912 | 498.538 |
| Normal disabled | 46 | 437.655 | 458.790 | 522.827 |

These partial distributions cannot establish a material improvement: the second
full control is missing, and normal-disabled p99 is already higher than the first
control. Source maps, Git-blob bindings, exact non-HEAD harness snapshots, all
logs and two original PNGs are preserved. Both original images were inspected:
the facade, shopfronts, window rhythm and camera composition remain present;
fine sandstone shading differs as intended by the diagnostic control. This
does not grant final-art or performance acceptance.

[First readout](FIRST-READOUT.json) and [artifact hashes](FIRST-ARTIFACTS.json)
bind the retained first epoch. A corrected harness needs a fresh parser and fresh
sequence; this rejected epoch must not be overwritten or relabelled.

Full attribution requires both p95 and p99 improvement beyond the full-control
bracket difference and five percent of its midpoint, with equal median draw,
visible/shadow, primitive and object counters. A positive first bracket still
needs reverse-order confirmation before selecting a source change. Target-Mac,
moving-route, second-resolution, facade-off baseline and human/art acceptance
remain separate. The existing failed-cost facade diagnostic stays disabled in
ordinary Main; merged train/station/pond/route content remains available.
