# Disposable four-way facade comparison

This standalone comparison preserves the preceding two-surface fixture's eight
camera views, native LOD hysteresis sweeps, actual stage subtraction and source
lighting. It compares the fitted four-slot reference, reduced four-slot source,
existing compressed atlas and identical atlas with lossless colour import.
It launches no live game, changes no runtime asset and makes no FPS claim.

Only after the orchestrator grants an exclusive engine window:

```sh
bash art_source/glasgow_bay/reduced_four_slot/preview/run.sh --render-approved
```

`--repo /absolute/repository` and `--candidate-output /absolute/export-directory`
support scratch preparation without copying source files into the live game.
Every run stages a fresh ignored `runs/comparison-*` project with isolated data,
config and cache directories. Imports and rendering are sequential and bounded;
the private display and Godot process are removed on success or failure.

Declared checks are 32 matched 1920×1080 scene PNGs, 44 actual native-stage
samples spanning both hysteresis directions, twelve mesh imports and seven
unique texture imports. Original and reduced four-slot variants share the exact
same four material objects and original maps. Paint/metal remain scalar, glazing
keeps the original repeated colour map, and the three sandstone maps are shared
by all four variants. The lossless diagnostic changes only colour import on an
identical PNG; the compressed no-mip ORM remains shared by both atlas variants.

Actual imported map-data bytes are checked per variant: 3,495,320 for fitted and
reduced, 3,503,512 for compressed atlas and 6,998,751 for lossless atlas. These are
image-data byte budgets rather than resident GPU memory: all seven textures are
loaded together. Source textures, actual imported formats/mips/material graphs,
34 decoded imported mip PNGs and each scene frame's native stage are recorded.

The fixture keeps its source's **75 m shadow range**. The current Balanced
runtime uses 45 m; results here do not certify current Balanced timing. This
static fixture does not measure frame times, hardware-selected mips, moving
shadows, full-city performance, Mac execution, final art or owner acceptance.

Source hashes are checked before staging and after execution. The staged
`render.gd` and `project.godot` hashes are checked against their recipes before
launch, inside the executed fixture and after completion. PNG decoding/hash and
native primitive-delta checks fail nonzero. Pixel differences are diagnostics,
without an automatic visual-quality threshold. Historical rejected live timing
and atlas-band/mip evidence remain unchanged; geometric success cannot waive
those gates. The [completed native comparison](../../../../docs/testing/facade-bay-four-slot-2026-10-27/README.md)
passes those declared counts and image-data budgets on 77 unchanged sources.
All actual execution inputs are retained beneath `.gdignore` for later review.
Root, author and independent reviewer accept the bounded appearance/resource
slice, with chamfer-highlight differences recorded and live timing still open.
