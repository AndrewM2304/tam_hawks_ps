# Actual preview update — 18 October 2026

The [disposable import/native LOD/capture comparison](../../../docs/testing/facade-bay-two-surface/README.md) now passes 16 scene images, 23 diagnostic mip images, 22 exact stage checks and 26 stable inputs under production source lighting. Actual ORM-only no-mipmap sampling passes at 128² DXT1/8,192 data bytes; total imported texture data adds 8,192 bytes versus the fitted reference. This is not resident VRAM or timing. **Paint compression banding and coarse colour-mip contamination keep visual quality open.** The optional lossless-colour diagnostic now removes the paint pattern with +3,495,239 imported bytes and eight unchanged fitted controls; coarse mip mixing persists. A reduced-poly four-slot source comparison is next under FACADE-COST-NEXT; no live import or two-slot rollout. The prospective statements below describe the original offline scope and are superseded only by those exact measured results; the original bad ORM mip counterexample is retained.

# Experimental two-surface Glasgow bay

**Offline generation and independent structural/base-level sampling audit pass;
rendered quality and runtime acceptance remain open.** This is
an unintegrated cost-reduction experiment for the existing facade pilot. It
adds no district, collision, mechanics, live asset or runtime script. The
parent `.gdignore` excludes the entire directory from the game importer.

The preserved original proof and fitted/runtime assets are inputs only. The
generator calls the original box authoring functions without invoking either
original `main()`. It retains every part, its dimensions and entry lift of
0.33 m, targeting the same 6.5 × 16 × 0.86 m bounds. Near rounded bevels become
single-segment chamfers with the same widths; their tiny curved profiles are
therefore changed and require matched visual review. Targets, not measured
results: near ≤10,000 triangles (prefer 8–10k), mid about 3,544, far 648;
two opaque slots at every stage. The generation gate fails rather than
silently relaxing the near budget.

Stone retains its three original 1024² PNGs byte-for-byte and its authored
metre-scaled UV0. Paint, opaque glazing and metal share `02_Original_accent_atlas`.
One 1024² sRGB colour atlas and one 128² linear ORM atlas replace the original
glazing map and scalar accent definitions. An optional 512² colour variant is
available for a later comparison; it is not the default. No normal map is
assigned to the accent material. ORM is R=1 (no invented baked AO), G=roughness,
B=metallic; base colour is white with the atlas, all surfaces opaque and
single-sided. The three stone maps and two accent maps are the only five PNGs.

Glazing crosses integer UV boundaries. A simple atlas scale/offset followed
by repeat or per-vertex `fract()` would be wrong. Instead, the generator bakes
the original repeated glazing lookup over the full authored domain
U[-1.75,1.75], V[-0.25,8], filtering original sRGB pixels in linear space. A
continuous affine mapping then fits that complete field inside the glazing
rectangle. Every accent UV is checked against the bounded source domain.
The atlas has 32-pixel colour / 4-pixel ORM edge-extruded gutters at the default
sizes. Deep mips can still blend regions; gutters are not a universal guarantee.

The original authored coordinates remain in UV1 for recovery and independent
comparison. UV0 drives materials and regenerated tangents; stone UV0 is
unchanged. The added UV1 stream is a real memory cost recorded in the audit,
not a free optimization. The GLBs contain two minimal named opaque slots and
no embedded images, samplers or copied PBR material definitions.

The first actual export measures **9,864 / 3,544 / 648 triangles**, two surfaces
each, and **11,088 / 4,796 / 1,296 exported vertices**. Mid/far positions and
authored UVs compare identically to every fitted triangle. Near retains all
246 authored parts but changes rounded-edge profiles; measured macro support
differs by at most 8.81 mm. Bounds and the 0.53 m threshold top remain exact.
`audit.json` contains exact formats, output hashes and file sizes.

Actual glazing triangle-interior error is mean 0.0000975 / maximum 0.003856 in
linear RGB. The 3,157 source integer-seam samples report mean 0.001297 / maximum
0.007490. **Coarse ORM mip bleeding is an open preview/integration gate:** the
simulated atlas preserves class values through mip level 3, but at level 4
(8×8 ORM) maximum metallic/roughness-channel errors reach 0.237 for metal and
0.149 for glazing. This is not a full-quality pass. An actual disposable preview
must measure whether those levels occur at the intended distances and inspect
their effect before any live integration. No material/shader workaround is
silently assumed.

The bounded **future** Godot import experiment is to set
`mipmaps/generate=false` for `accent_orm.png` only. Its regions are categorical
material constants, not high-frequency surface detail; base-level linear
sampling inside the validated domains/gutters preserves those values. Keep
colour and all stone mipmaps enabled. This contract has not been imported or
tested here. Retain the reported bad mip-4 case as the regression
counterexample, then verify the actual imported sampler/resource, distant and
foreshortened views in a disposable project. No custom shader or larger map is
proposed. The integration gate remains open until those checks pass.

Keeping UV1 adds 137,440 bytes across exported vertex streams before import.
The default colour atlas has the same dimensions as the old glazing map;
three stone maps are identical. The additional 128² ORM is approximately
21.3 KiB including a full mip chain under an explicit 8-bit/pixel compression
assumption. GPU formats and resident bytes remain unmeasured. PNG file size
and the audit's illustrative total estimate are not GPU-residency measurements.
The future no-mip ORM contract would use 16 KiB under that same format
assumption, but this is still a calculation rather than measured residency.

After the exclusive profiling window is released, run locally (no network,
install, paid service, renderer or Godot process):

```sh
OMP_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2 PYTHONDONTWRITEBYTECODE=1 blender -b --factory-startup -t 2 --python art_source/glasgow_bay/two_surface/generator.py -- --allow-generate
OMP_NUM_THREADS=2 OPENBLAS_NUM_THREADS=2 PYTHONDONTWRITEBYTECODE=1 python3 -B art_source/glasgow_bay/two_surface/audit.py
```

All outputs stay here. `generation.json` records input/source hashes and part
metadata; `audit.json` independently decodes actual GLB attributes and PNGs.
`reproducibility.json` records two actual factory-startup exports: all three
GLBs and five PNGs match byte-for-byte. Both audits exit 0. Blender's optional
Draco library and read-only extension-cache diagnostics remain in the logs;
neither facility is used, and the decoded assets require no Draco extension.
No Blender, generator or audit process remained after this bounded run.
The audit checks two surfaces, budgets, finite/unit normals/tangents, exact
bounds, UV degeneracy, source phase, entry height, unchanged mid/far geometry,
original stone map hashes, edge extrusion and source preservation. Near gets
macro-bound and shared-triangle checks; those do not certify every silhouette.

Colour error is measured at decoded triangle-interior UVs and both sides of
all integer seams in the source field. Prospective base-level gates are mean
absolute linear RGB ≤0.003 and 95th-percentile maximum channel error ≤0.01;
the maximum error is always reported. Simulated mip errors and metal/roughness
bleed are reported separately. These numerical gates do not certify appearance
or claim exact downsampled shading. A failed sampling gate writes its report
and exits nonzero. Structural assertions also fail nonzero.

Before any future integration: preserve two repeatable factory-startup export
hashes; inspect matched near, threshold, oblique and native LOD views in a
disposable project; review chamfer silhouettes, glazing phase/blur and metallic
bleed; confirm shared material roles and no autogenerated mesh LODs; then run
the owner's controlled A/B/A draw and frame-spike gates. No FPS improvement,
Mac result, full final-art acceptance or rollout is claimed by this prototype.
