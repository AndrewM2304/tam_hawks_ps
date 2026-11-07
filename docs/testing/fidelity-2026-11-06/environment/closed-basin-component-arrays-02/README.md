# Indexed native metadata correction and full baseline/candidate streams

The same512-triangle helper remains unchanged. The corrected test inspects referenced native surface-array indices instead of snapped `Mesh.get_faces()` coordinates and now reports exact64outer/64inner annulus vertices,128annular/64floor triangles. The component completes clean on801stable inputs; both tiny diagnostic executions together take less than one second of wrapper time within the approved5s scope. Earlier false-assertion and timeout epochs remain preserved.

`native-arrays.json` now retains **both original CylinderMesh and candidate ArrayMesh** actual/native-render-server positions, normals, UV, tangents and indices, plus candidate `get_faces()` values. This permits independent welded topology/UV/winding and original-side/bottom preservation reconstruction without another engine. Main ordinary support/cohort retest is still separate and pending. No runtime performance or visual acceptance is inferred.
