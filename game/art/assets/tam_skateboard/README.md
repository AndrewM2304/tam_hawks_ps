# Original Tam skateboard

Project-owned original content, within ART-001's existing provenance scope. No external geometry, imagery, font, paid API or model-generation service is used. No public licence grant is implied.

Regenerate with installed free Blender:

```sh
blender --background --factory-startup --python tools/art/build_skateboard.py
```

`manifest.json` records the generator/output SHA-256 values, actual triangle/material count and unchanged board-local contact contract. The GLB contains one mesh, four surfaces and the original 1024² colour atlas. `board_albedo.png` retains the source atlas for authoring. Runtime material factors carry roughness/metallic values; the model needs no custom shader, lights, animation or collision.

Instantiate the GLB below the existing board node with identity transform. Its export is already Godot Y-up, in metres. Do not add a conversion rotation or scale. The root integrator owns import settings, gameplay contact checks and rendered acceptance. Research, budgets and remaining tasks are in [RIDER-FIDELITY-REVIEW](../../../../docs/research/RIDER-FIDELITY-REVIEW.md).
