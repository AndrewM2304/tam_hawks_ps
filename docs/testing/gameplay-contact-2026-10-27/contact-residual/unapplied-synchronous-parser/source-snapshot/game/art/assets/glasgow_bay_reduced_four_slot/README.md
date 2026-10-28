# Reduced original four-material Glasgow bay

Geometry-only revision: 9,864 / 3,544 / 648 triangles, 246 / 142 / 54 authored parts, three explicit LODs and four original named opaque material slots. Geometry and material layout are independently audited; actual native import and live-world/performance admission remain pending until their new receipts exist.

`game/levels/art/facade_bay.gd` uses this directory for meshes through `MESH_ROOT`, while `ASSET_ROOT` continues to share the original four textures and materials. No copied texture set or embedded image is added. The original fitted GLBs remain in `game/art/assets/glasgow_bay/` unchanged.

Editable source and provenance: `art_source/glasgow_bay/reduced_four_slot/`, with default exports under `generated/`. `manifest.json` records exact geometry/shared-map hashes. Fresh Godot scene imports must generate unique UIDs and preserve the authored hard-LOD import flags; do not copy old remap/dependency/UID fields.

This handoff does not change ordinary feature defaults or claim timing, target-Mac, human appearance or full-city acceptance. Preserve the rejected historical pilot measurements.

The fresh near import disables attribute compression to retain the authored Y0.53 threshold within the unchanged native1e-4 criterion. Mid/far retain the original import policy. The first automatic-compression threshold rejection and native byte-array cost remain in the new live evidence; original imports are unchanged.
