# Reduced four-slot facade: offline and isolated native admission

The accepted M05-001 / M06-004 / M06-007 source experiment now retains the
original four materials while reducing near geometry from 18,392 to **9,864
triangles**. All 246 near parts and authored UV phase remain. Mid/far decoded
geometry and attributes remain exact. No live asset or normal feature setting
is changed by this slice.

[Editable source](../../../art_source/glasgow_bay/reduced_four_slot/README.md),
[independent geometry audit](offline/audit.json) and [independent native
review](independent-review.md) own their precise scopes. Existing original,
fitted and two-surface sources and all preceding failed timing/atlas receipts
remain unchanged.

## Deterministic offline results

Two Blender 4.3.2 factory-startup exports finish in 7.536 s and 7.083 s. The
three GLBs, generation report and actual part-triangle payload match byte for
byte; all 61 preserved proof inputs keep their hashes. The independent decoder
checks every near material/position/authored-UV triangle against the immutable
reduced two-surface geometry oracle. Every mid/far position, normal, tangent,
UV and index array matches the fitted four-slot asset exactly. Actual pre-join
triangle unions bind all 246 / 142 / 54 parts to the final GLBs, including their
historical dimensions/envelopes/counts, four named surfaces, original bounds,
0.53 m entry threshold, finite unit/orthogonal normals/tangents and nondegenerate
geometry/UVs.

| LOD | Triangles | Parts | GLB SHA256 |
| --- | ---: | ---: | --- |
| Near |9,864|246|`67c0ebfbe88f83ddb0108e9c1ba6c861766905c641ed5c72bff102c4d87f8001`|
| Mid |3,544|142|`481f8ed518be457a7df00ba720aec75e2dc81351a91b90c2b208c2e370ed7d0c`|
| Far |648|54|`01347133a605228272dfaa8afefd38dd849e1df183707670b9466f9ff24d64d0`|

Both raw export logs retain the installed exporter's optional-library diagnostic
`ERROR Draco mesh compression is not available ... libextern_draco.so`.
Compression is not requested or used. Exports complete normally; the independent
decoder confirms ordinary uncompressed buffers without a Draco extension. The
logs are not called marker-free.

## Source-bound native comparison

The [parser](parser/parser-receipt.json) passes exit 0, no errors, **77 stable
inputs** in 0.184 s. The [native receipt](native/receipt.json) passes exit 0 on
Godot 4.6.3 Compatibility/Linux llvmpipe: **32 actual 1920×1080 scene PNGs,
34 decoded imported mip PNGs, 44 native LOD/hysteresis samples, twelve meshes
and seven unique textures**, zero errors and 77 unchanged sources. Receipt SHA256:
`a21d9781f63a90a042ab28002b12af3e233ee31a5ef6946cf7eda27bb67ecdb6`.

All four approaches use the same eight camera/light/fixture conditions, with
near/mid/far native counts and both hysteresis directions checked. Fitted and
reduced share the exact same original four material objects/maps. Paint and
metal stay scalar; glazing retains its original repeated colour lookup. The
atlas controls share the same ORM and geometry; lossless changes only import
compression on an identical colour PNG. Each frame's actual native stage is
verified by subtracting the identical camera's fixture-only primitive count.

| Variant | Actual imported map-data bytes | Visible objects / draws |
| --- | ---: | ---: |
| Fitted four-slot reference |3,495,320|8 / 8|
| Reduced four-slot source |3,495,320|8 / 8|
| Existing compressed atlas |3,503,512|6 / 6|
| Existing lossless-colour atlas |6,998,751|6 / 6|

These are imported image-data sizes and static counters, without a resident GPU
memory or frame-time claim. All comparison resources are loaded together.
The fixture preserves its source **75 m shadow range**; current Balanced uses
45 m. It is not a current Balanced performance workload. The private software
display retains its unsupported V-Sync warning, without a parse/import/runtime
error. No timing gate is waived by these counters.

Root, author and independent reviewer accept this bounded appearance/resource
slice. The author opened all 32 original scene PNGs. Recesses, window/sill rhythm,
entry/threshold and handle joins remain readable, with no missing part observed.
Single-segment chamfers give broader/sharper highlights and alter small rounded
profiles/normals. Scalar fascia and door colour avoid the compressed atlas's
repeated streaks; the lossless control also removes colour streaks at its higher
byte cost. Fitted/reduced mid and far images are exactly equal in decoded pixels.
Near differences are retained as diagnostics rather than a numeric quality gate.

This supports preparing a new explicit startup-only live diagnostic. Full-city
art, owner signoff, target Mac, moving shadows and live frame-time/spike gates
remain separate; the earlier failed live candidate and atlas mip mixing are not
relabelled as repaired performance results. No game rerun, release, upload,
hosted CI, signing or spending is part of this source comparison.

## Exact execution provenance and reproduction

The geometry oracle is commit **`98311cba78944d1828d1cb528be0293273d9c3b5`**.
The native comparison was staged before the new live diagnostic, from main
`838e6f4dc02dfd48e9f122744238a1ad66de7a17`. The pre-diagnostic helper hash is
`5532963556c976e350423b7305b7e32110bcdf4c2042cda445c4844899359ef6`.
Later helper edits do not change that scope. All 77 exact raw inputs are retained
under each epoch's ignored `execution-sources/`, including the executed recipes,
old helper, geometry, textures, original provenance and independent audit.
Before/after hashes and actual staged-copy checks remain exact. Generated
`.godot`/profile caches and display credentials are omitted; raw import configs,
logs, PNGs and JSON receipts are preserved.

To reproduce offline geometry without modifying preserved inputs, create two
separate disposable trees. The audit reference must remain the exact 61 original
files, with no new variant added beneath it:

```sh
TASK_FACADE_REPRO="$(mktemp -d /tmp/tam-hawks-four-slot-XXXXXX)"
mkdir -p "$TASK_FACADE_REPRO/reference" "$TASK_FACADE_REPRO/author"
git archive 98311cba78944d1828d1cb528be0293273d9c3b5 art_source/glasgow_bay | tar -x -C "$TASK_FACADE_REPRO/reference"
git archive 98311cba78944d1828d1cb528be0293273d9c3b5 art_source/glasgow_bay | tar -x -C "$TASK_FACADE_REPRO/author"
cp -R art_source/glasgow_bay/reduced_four_slot "$TASK_FACADE_REPRO/author/art_source/glasgow_bay/reduced_four_slot"
blender -b --factory-startup -t 2 --python "$TASK_FACADE_REPRO/author/art_source/glasgow_bay/reduced_four_slot/generator.py" -- --allow-generate --output "$TASK_FACADE_REPRO/first"
blender -b --factory-startup -t 2 --python "$TASK_FACADE_REPRO/author/art_source/glasgow_bay/reduced_four_slot/generator.py" -- --allow-generate --output "$TASK_FACADE_REPRO/second"
python3 art_source/glasgow_bay/reduced_four_slot/audit.py --candidate "$TASK_FACADE_REPRO/first" --repeat "$TASK_FACADE_REPRO/second" --reference "$TASK_FACADE_REPRO/reference/art_source/glasgow_bay" --output "$TASK_FACADE_REPRO/audit.json"
```

Native reproduction uses the separate source `preview/run.sh --render-approved`
only during the orchestrator's sole-engine window. A rerun owns its own source
identity; it does not replace this admitted receipt. No engine is needed to
review the retained evidence or change prose.
