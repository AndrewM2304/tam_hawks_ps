# Private source UV03 — physically scaled periodic side grain

Private, unimported/unrendered; no actual board/controller edits or final contact,
M5, appearance or ticket acceptance. Root controls native leases and integration.

The first [UV01](../source-uv01/README.md) corrects collapsed mapping but stretches
one strip over the whole1.937752m perimeter, only211horizontal texels/m. UV02's
periodic replacement then fails a new actual seam-correspondence control21/1:
the perimeter is not an integer multiple of its fixed93.75mm repeat, producing a
nose seam. That failed source packet is [retained](../rejected-uv02/author-source-checks.json)
and cannot inherit the later correction.

UV03 instead fits21whole192pixel texture periods to the actual measured perimeter,
approximately92.274mm per repeat and2080.76horizontal texels/m. Each actual triangle
unwraps its UV tile independently without splitting geometry; adjacent occurrences
of an actual point differ by exact integer192pixel periods. The encoded atlas
repeats byte-for-byte across its padded sampling strip. No triangle, material,
node, draw surface, collider or atlas dimension/RGBA allocation is added.

The same-author separate source arithmetic passes22controls, including the old
172/224strict-side defect, all2600wood-triangle UV Jacobians, tangent sign, exact
protected geometry/buffers/artwork, actual seam phases/pixel periodicity, and five
corruption negatives. It shares only the binary accessor reader with the generator;
this is not independent QE. The28mm physical thickness remains deliberately
unchanged and is not certified credible by a layer pattern.

Current private GLB SHA-256:
`954ff19340b1c41d6ea0f2153f7e41a8242f853b135486bbdc6cf8b2c024993d`.
It adds290seam vertices and34,880geometry-buffer bytes; encoded GLB adds10,048bytes.
Every old wood triangle corner and normal/winding remains exact, and the three
other primitive streams remain byte-exact. One mesh/four surfaces/5696triangles,
original river underside and grip quadrant remain intact.

A tiny isolated11input native project is prepared under
`.local/board-fidelity/native-project`, using the actual scene-import parameters
and current unchanged GrindClearance constructor. It has no copied import cache
and has not been imported, parsed or run. The bounded wrapper must parse first,
then perform isolated editor import/native inspection within the root's aggregate
30second lease. Native imported buffers, component identities, markers/resources,
close shaded/normal views and ordinary action/moving/full regression remain open.
