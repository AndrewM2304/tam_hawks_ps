# Closed basin geometry candidate

**Native headless geometry17/0. GPU allocation and actual Main shadow/readability acceptance remain open. Production is unchanged.**

The512-triangle closed basin retains192original exterior side/bottom triangles and adds128annular-top,128inward-wall and64upward-floor triangles. Its welded surface has258vertices,768edges, Euler2 and no nonmanifold edges. Interior UV handedness passes; the floor sits approximately0.05m above the original bottom,0.505m below the water. The64sector water seam differs by0.477µm with zero measured upper-ring footprint overlap. [Native report](native-geometry-report.json).

Original position/UV/index values and collider identity/dimensions remain unchanged; native normal/tangent repacking differs by0.00336°. The helper and direct unit guard are preserved exactly. This run did not collect a whole-project before/after source-freeze receipt. [Identity scope](preservation.json).

The revised ceiling is512source triangles,64KiB additional native buffers and zero new nodes/maps/materials/lights/colliders. A fresh allocation process must release the old mesh before measuring; visual A/B/A counters that hold both meshes cannot admit that budget. Actual Main must also preserve the exterior contact shadow while removing water bands.
