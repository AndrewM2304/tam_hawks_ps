# Retained1280 cost analysis

Read-only analysis of the interrupted838e6f4-parent epoch. No engine or new
profile run was launched. Three1280×800 phases completed;1920×1080-a1 was
interrupted and the remaining two phases never started. The original cohort
remains **interrupted**, without a full-six-phase or current-source outcome.

[Machine-readable results](analysis.json) retain the original comparator's
unchanged gates. The analysis authenticates the retained archive manifest,
three original receipts and their source/artifact bindings, including raw CSV
quantiles and PNGs. The three inner maps match on666 inputs; the outer bound
contains672. Raw data, source snapshots and original manifests are unchanged.

| View | p95 a1 / candidate / a2 ms | p99 a1 / candidate / a2 ms | Draw delta | Completed1280 cell |
| --- | --- | --- | ---: | --- |
| Spawn |523.189 /536.841 /516.075|538.577 /544.996 /563.636|+3|Pass|
| Frontage wide |429.859 /427.940 /413.022|463.202 /434.091 /426.851|+2|Pass|
| Frontage near |447.234 /467.133 /456.207|456.328 /565.407 /456.362|+2|Fail p99|
| Moving loop |556.702 /591.113 /556.007|570.521 /660.178 /608.400|—|Fail p95/p99|

Near p99 exceeds the479.1801ms worse-baseline cap. Moving p95 and p99 exceed
584.5371ms and638.8200ms. All three also exceed both repeat noise and5percent
of the baseline midpoint. No threshold is waived. These completed1280 cells
give no reason to repeat the unchanged seventeen-minute full candidate now.

The near candidate's process p99 is556.855ms against frame p99 of565.407ms;
physics p99 is9.726ms. Moving process p99 is643.006ms against660.178ms, with
controller p99 only78µs. This points investigation toward the process/render
path, but does not attribute geometry, texture sampling, GPU execution or
scheduling. Lower polygon counts do not identify or repair the measured cause.

The next bounded source experiment should isolate the existing sandstone
material's normal/ORM sampling at the failing near camera, keeping geometry,
camera, light and four opaque material classes identical. Separate no-normal
and constant-roughness controls would identify whether that material path earns
a source optimization; they would not be admitted artwork. Choose a production
sampling/source change only after measured attribution and matched appearance
checks. Do not recreate the rejected atlas, infer a performance gain, alter
ordinary trial features or rerun the full cohort without a justified change.

Fresh six-phase paths and the explicitly dependency-bound foreground command
are prepared in ignored `.local/facade_resume_prepare/README.md`; they were not
executed. Any eventual new run owns the then-current source and must use new
output directories. Mac, owner art acceptance and FPS improvement stay open.
