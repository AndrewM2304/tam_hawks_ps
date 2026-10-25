# PT24-15 station railway candidate

25 October 2026. The owner approved implementation of the consolidated remaining
work. This slice implements an original station-edge building and scenic train;
it does not claim final art, target-Mac timing or live rendering admission.

## Integration and default gate

`game/levels/station_railway.gd` is a `Node3D` helper. Root integration calls
`Railway.new().build(world)` **after `_build_city()` and before art/batch
finalization**, only when the explicit `pt24_design_preview` world metadata is
true. A caller can pass the existing shared material dictionary as the optional
second argument. Normal gameplay constructs none of this candidate until the
existing stutter/rendering gate is satisfied. This is a complete inspectable
implementation candidate, not a claim that the gate has passed.

The returned node owns pausable native physics processing. `reset_run()` restores
its concealed start phase and must be delegated from world `reset_interactions()`.
`tick(delta)` rejects invalid/nonpositive time steps. It moves one parent transform;
no per-frame mesh, material, timer, actor or collision resource is constructed.
Train meshes are ordinary unregistered `MeshInstance3D` children, so static
MultiMesh finalization cannot flatten the animated branch.

## Placement and original design

The two old `STATION APPROACH` facade groups at `(−136,2,±26)` are replaced only
when their exact original positions and `Facade` native body match. The railway
wing retains their X−142…−130 frontage. Closed tunnel ends extend to Z±68 in the
nonplayable west-edge strip. Grounded masonry is opaque on the hillside side.
An east-facing clerestory reveals the actual track and passing train to the
station, with native safety glazing separating it from skating.

The existing park mouth is preserved at Z−10…10. An elevated rail deck crosses
above it with underside Y7.2, giving 5.2m clear above the existing Y2 route. The
station platform, mandatory gap, upper walk, underpass and city/Clyde connections
are not moved or retagged. Track is scenic, absent from grind registration.

The original two-coach train has bogies/wheels, side windows/doors, driving ends
and roofs. It carries no operator branding. A 13-second native loop runs at
8m/s; the ±52m wrap occurs with the complete ±8.25m vehicle inside the opaque
end tunnels, well beyond the Z±28 viewing opening. Train geometry never doubles
as an invisible player collision volume or train-dodge objective.

Reference scope is the existing 17 October Glasgow reference dossier and
ART_DIRECTION station treatment (masonry, canopy, layered railway edge). The
Network Rail link in `GLASGOW_REFERENCES.md` was historically inaccessible; this
slice does **not** claim a new inspected photograph or surveyed real station
reconstruction. All new geometry is original, using existing shared materials;
no external asset/licence import or paid source is introduced.

## Predeclared construction budget

- At most eight material surfaces, including the existing-font station label.
- At most 3,000 triangles and 512KiB estimated mesh vertex payload
  (position/normal/UV/tangent; estimate, not measured VRAM).
- At most six static bodies and twenty primitive shapes; no moving train body.
- No new texture, material, light, render target or per-frame geometry.

`report` exposes actual geometry/surface/native counts and the budget predicate
when built. This cap is not a frame-time acceptance result. Removing the old
facades may reduce their detail resources, but no cost saving is claimed before
matched measurement.

## Deterministic evidence and limits

`tests/station_railway_tests.gd` builds the candidate at an isolated native-world
position using the existing materials. It checks exact facade replacement,
construction bounds, all train geometry fitting the concealment envelope,
repeated complete loops, reset/invalid-delta behavior, lower-route capsule
clearance, continuous rail separation, native deck support and scene pause.
Normal-world inventories remain independently checked; the test does not enable
the candidate in ordinary play or rewrite those fixtures.

Root owns the combined parse/test run, source-bound rendered capture and any
matched profile. At this handoff no station-specific engine run or screenshot is
claimed. Proposed capture: camera `(−111,8,27)` targeting `(−136,10,0)` for the
station-facing clerestory; park approach `(−147,5,0)` targeting `(−130,8,0)` for the
open lower route. Actual moving review, final realistic finish and target-Mac
stutter acceptance remain open.

## Bounded continuation capture runner

`tools/pt24_design_capture.gd` is ready for root's source-frozen rendering run.
It records twelve PNGs from actual `Main` construction: ordinary startup and
owner views11/27/28/38, then explicit candidate views25/26, pond overview, station
overview, concealed/visible train phases and safe-bridge cable detail. It waits
for normal process frames and `frame_post_draw`; it does not force a pre-process
draw. The JSON manifest includes all game-file/source hashes before and after,
PNG hashes, full camera/phase notes and native rendering/memory counters. The
train phases are deliberately selected while paused, not motion acceptance.

The runner accepts `-- --output PATH` (or `--output=PATH`), owns both preview
states itself and rejects an extra design-preview CLI flag. It stops after the
fixed twelve frames or a 180-second watchdog.

The specialist's source-only handoff above is historical. Root integration now
retains the actual [station overview](captures/preview-station-overview.png),
[concealed train](captures/preview-train-concealed.png) and
[visible train](captures/preview-train-visible.png), with zero capture failures
and unchanged sources in the [manifest](captures/manifest.json). Native loop,
pause/reset, budget and actual Main construction checks are registered in the
required suite; its final result belongs to [the integration record](README.md).
The deliberately selected paused train phases do not establish moving visual
acceptance, target timing or execution of a Mac binary.
