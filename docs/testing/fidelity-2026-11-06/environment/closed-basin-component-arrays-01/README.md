# Native proper-basin arrays and test-metadata diagnosis

A tiny headless native component exports exact surface/native-render-server position, normal, UV, tangent and index arrays for the512-triangle helper, plus its `Mesh.get_faces()` output. It completes clean with801byte-stable inputs and no graphics/performance claim. The helper bytes match the prior geometry/Main candidate.

The old adapted test's boundary classifier reports20outer/12inner vertices because `Mesh.get_faces()` snaps some coordinates by roughly0.1mm while its radius tolerance is10µm. The actual indexed surface/native streams retain64outer/64inner annulus vertices, maximum radius error below0.51µm. This is a test-instrumentation defect; it does not require changing basin geometry. Earlier49/2 and timedout Main metadata epochs remain rejected. The test will instead classify referenced native surface indices; unused originalcap vertices are excluded.

These complete actual numerical arrays permit independent welded topology/UV/tangent reconstruction without launching another engine. Exact primitive source exterior preservation remains additionally covered by the prior17/0 source/native guard; this export does not include a second baseline mesh's full numerical arrays.
