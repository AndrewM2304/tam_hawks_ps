# Fitted original Glasgow bay

Three explicit geometry-only LODs with four named opaque surface slots; no embedded textures or PBR material copies. Assign the same four shared runtime materials to near, mid and far. `textures/` contains exactly four original shared 1024² maps; `manifest.json` records actual exported geometry, vertex formats, bounds, UV/normal/tangent validation and source/image hashes.

Editable source, exact material recipe and reproduction commands: [fitted source README](../../../../art_source/glasgow_bay/fitted/README.md). Geometry is the original proof with the complete entry raised +0.33 m, threshold top Y0.53, and the authored metre-scaled UV layer selected as UV0. Overall bounds remain 6.5×16×0.86 m. Original source files are preserved; this directory is the runtime asset handoff, not evidence that live integration or performance acceptance passed.

Do not generate additional automatic mesh LODs for these explicit three levels. The integration owner controls Godot import settings, shared material/texture resources, hard LOD switching, placement and visual/gameplay/performance checks. Collision and grind geometry remain independent.
