# PT24-17 — deliberate central-green landscape

The owner's capture25 looks from approximately (−76.74,6,−119.25) toward the
enclosed low lawn between the civic promenade, station and Merchant Close. This
is a different space from the proposed pond near (−170,0.5,−12).

The bounded implementation chooses the ticket's **coherent landscaped edge**
option. It relocates six existing outer-row park trees into two small groves on
the existing native Y0.5 ground: west at (−120,−101), (−111,−96), (−103,−102),
east at (−65,−101), (−60,−94), (−57,−102), in world-local XZ metres. A broad
central view slot remains at X−96…−72/Z−108…−86. The planted wings frame the
station/Close view and explain the existing route around the lawn. They do not
add an unrelated manual-pad field, a new district or another mandatory route.

`pt24_central_green.gd.build(world)` is a **design-preview candidate only**,
pending measured rendering admission. It runs once after OutdoorRoutes has built its
native support and tree batches, before world dressing/final batching. Trunk and
crown instances move together, retaining their original meshes, materials,
colours, scale and yaw. The helper requires author-owned CPU instance transforms;
it never uses dummy headless GPU-buffer readback. It validates all destinations
and complete transformed trunk/crown bounds against native closed-facade boxes
before mutation and is idempotent. The initial proposed tree at (−47,−101) was
rejected in source review because it lies inside the actual civic-frontage box;
all eastern planting is now safely west of that facade.

Construction delta: **zero added instances, meshes, material surfaces, triangles,
textures, lights, collision bodies/shapes or per-frame work**. These are existing
tree resources moved from the far western park planting row, not additional
trees. Their expanded batch bounds and changed view coverage still require the
root-owned matched rendering/performance admission; no target timing is inferred
from the unchanged triangle count. Existing lawn support, fences, civic/park
ports, Merchant lower-court exits, skating features and stable IDs are untouched.

The focused test checks six independently fixed grounded sites against native
rays, paired transforms, original source scale/yaw, the actual crown-mesh view
envelopes, twelve full native trunk/crown volume probes excluding only terrain,
protected passage sweeps, and idempotence/resource preservation. Root owns suite
registration and serialized verification. These checks now run in real Main's
explicit preview integration; the [root receipt](README.md) owns final counts.
The [owner-camera frame](captures/preview-issue-0025.png) and
[source-bound manifest](captures/manifest.json) retain the completed native
readback. Landscape readability, moving shadows and target Mac performance
remain separate acceptance gates. The change does not close all PT24-17
witnesses by assertion.
