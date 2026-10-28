# Original reduced four-slot facade source

Prepared 27 October 2026 as the next source-only experiment under existing
M05-001 / M06-004 / M06-007, following `docs/planning/FACADE-COST-NEXT.md`.

Geometry derives from the repository's preserved original
`art_source/glasgow_bay/generator.py`. The wrapper retains all boxes, dimensions,
material classes and authored metre-scaled UV phase. Only the near LOD's rounded
edge subdivision becomes one-segment chamfers, matching the reduced geometry
previously exported by the two-surface experiment. The existing fitted entry
translation is applied after UV creation. Every original, fitted and two-surface
source/asset/receipt remains unchanged.

The four exported opaque slot names match the existing native shared material
definitions. The existing original sandstone colour, normal and ORM maps and
opaque glazing colour map are reused; paint and metal retain scalar factors.
There is no atlas, additional texture, shader, image bake or downloaded content.
GLBs contain named slots and geometry without embedded images/PBR payloads.

The editable source is this Python wrapper and the preserved original authoring
functions. Installed Blender 4.3.2 is an offline export tool; its GPL source and
binaries are not bundled. Rights follow the repository owner's project licence;
see `../LICENSE-NOTICE.md`. No third-party asset is added by this variant.

This is a source-only experiment. Near chamfers alter small rounded profiles and
their normals; equivalent macro bounds do not establish complete silhouette or
shading preservation. Native import/resource, matched appearance, live timing,
target Mac performance and owner visual acceptance require their own source-bound
results. No live GLB/default feature is replaced by running this generator.
