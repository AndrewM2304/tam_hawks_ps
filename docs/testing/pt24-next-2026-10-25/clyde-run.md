# C04-L05 — safe Clyde crossing to quay continuation

Source baseline: main `258fec4`, after the personal Mac soundtrack merge.
Scope: a genuine safe-bridge arrival → controlled turn/manual → existing west
quay ledge → dry runout and single bank. The pond preview, cable backing,
career/save/route IDs, benches, bowl, relay and ordinary bridge stay intact.

## Existing physical ingredients

The safe bridge follows X−25 from the north quay at Z67, across its actual
Y2→3.4→2 deck, to the south quay at Z122. The previous placement pass reused
`Grind_Ledge_clyde_south_return` at X−32.2, Y2.60, Z131…138. Its original physical
seat and contact metadata moved together; this task does not add another obstacle.
The existing east/west manual bank is relocated to centre `(-22,2,139.5)`, keeping
its resource/guide/route identities. Its graded Z140 return remains skateable;
Z124 remains the clear cross-quay bypass.

The technical line starts a controlled westward diagonal near Z118.5, then
enters a real Manual before leaving the bridge. The flatland approach crosses
the south landfall toward X−31.5/Z129.9. A normal tap Ollie catches the existing
north/south ledge. A short native grind releases via an inboard Ollie onto dry
quay support. The east/west Z124 through lane remains a separate safe choice.

The Manual begins after the controlled turn, so the fixture does not ask the
same stick axis to perform an entire right-angle ground turn and balance a
manual simultaneously. The ledge catch admits the resulting modest diagonal
through the existing angle, height and volume gates; no snap radius is expanded.

## Verification design

`tests/pt24_clyde_flagship_tests.gd` supplies `run(tree,game,check,observer)` and
`run_player(tree,game,check,observer)`. It uses normal Main and only declares the
initial north-quay spawn/facing. Every later position, heading, speed, Manual,
Ollie, grind contact and score comes from ordinary mapped input/native physics.
Push/brake strengths regulate a moderate crossing speed without editing velocity.

Independent fixed native probes cover the bridge, actual landfall, manual apron
and protected cross-quay bypass. Actual-input assertions cover supported full
crossing, Manual start before Z122, at least24 Manual ticks, an actual named ledge
capture held at least18 ticks, dry recovery/runout, zero bails and one earned bank.
The existing strict whole-rider camera helper checks head/board/soles, real convex
board extrema and camera volume throughout the run. Observers may read actual
phases for rendering; no camera transform is assigned by the driver.

No new draw, triangle, body, shape, asset, light or runtime query is added to the
game by this test/documentation task. Existing cable and optional river-transfer
proofs remain separate; this line does not need a water risk to link the quay.

The combined integration record owns source-bound results and native captures.
Before a measured run, this document describes the bounded acceptance workload;
it does not claim a passing line, target performance or human fun.

## First actual finding and bounded correction

The first actual native input attempt crossed the full safe bridge and began its
Manual at `(-25.776,2.111,120.838)`, before the landfall. It then stopped at
`(-29.305,2.001,126.195)`: the north side of `clyde_south_linkManualDeck` at Z126.5
blocked the diagonal. The strict camera probe also identified that same face
occluding a real rider extremity. This was a placement defect, not permission
to relax camera, capture or contact tolerances. No ledge capture occurred.

The existing bank is moved, without adding resources, from `(-27.5,2,128)` to
`(-22,2,139.5)`. Fixed native witnesses now check both the cleared diagonal and
the bank's graded return, including its real annular-deck east endpoint. The
failed raw log `.local/clyde-flagship-second.log` is retained separately from any
later accepted source. An earlier parser-only failure is also preserved; explicit
Vector3 declarations corrected it without changing gameplay.

## Preserve the bank's existing complete line

The relocated bank's east endpoint `(-11.5,2,139.5)` is on the actual bowl's
annular deck, approximately1.37m before its curved lip along eastward travel.
It must not be described as a long dry runout. The test therefore also calls the
unchanged `Density._manual_crossing` input fixture, including its entire existing
post-bank coast, and observes native support, camera and bails throughout.

After that actual coast, ordinary steering/Push/brake input returns to the
supported Z124 bypass. The controller preserves momentum/full Push in the bowl
and requests its documented fresh in-air Push exit when appropriate; flatland
speed limiting resumes outside. It neither relocates the player nor changes any
transition forces or contact rules. The earned bank must survive unchanged and
strict full-body chase/native support checks remain required.

## Flagship outcome after the placement correction

The focused structural/native and flagship checks pass7/0. Ordinary input crossed
from the north quay, began Manual at Z120.838, held112 Manual ticks and21 actual
`Grind_Ledge_clyde_south_return` ticks, then landed dry and banked1,900 exactly
once. Zero bails; all127 strict whole-rider/camera-volume samples remained clear.
No position, heading, velocity, contact or score was assigned after initial setup.

The extended preservation job was10/1: the unchanged old bank crossing/coast
passed (38 Manual frames, one100 bank, zero bails and clear camera), with an actual
bowl-side coast endpoint `(-2.032,0.940,136.775)`. Its subsequent goal-steered
return bailed once while preserving the100 bank; support stayed finite and56
strict camera samples stayed clear. That failure remains in
`.local/clyde-flagship-third.log`, separate from the accepted flagship proof.

Source inspection identified that Steer is also the mapped Spin input in air.
The return controller is corrected to aim only while supported and reuse the
existing owner bowl escape's release-Push-at8/fresh-Push-at10 sequence. A
return-only targeted runner records the exact bail signal site/reason/phase,
previous native state and mapped inputs; no physics or tolerance change is made.

The return-only follow-up (`.local/clyde-bank-return-first.log`) passes the actual
return and bank requirements: zero bails, bank100 preserved, finite support and
arrival at `(-14.242,2.014,123.982)`. The corrected driver avoids an unintended
mapped Spin during bowl air. The strict camera assertion remains failed: three
observed marker rays intersect `ContinuousBowlWall` during the actual coast and
return. Result3/1, retained as rejected extended admission. Marker positions and
native hits are in the raw log; no production contact/camera assertion is relaxed.
The complete flagship's earlier1900 bank remains separate from this newly exposed
curved-bowl presentation issue.

## Exact curved-bowl marker classification

The bounded return-only classifier `.local/clyde-bowl-contact-trace.gd` records
all three exact witnesses without changing the strict test: result4/1, with the
known camera failure retained. The markers belong to the actual combined native
`TamSkateboard` mesh, not the rider's head or soles. Independent probes along the
native wall normal establish real current-geometry penetration:

| Witness | Board-local convex marker | Independent normal gap | Source component |
| --- | --- | --- | --- |
| 0 | `(0.123994,-0.118448,0.26482)` | −0.751mm | Urethane, right rear wheel |
| 1 | `(0.14,-0.092282,-0.256401)` | −9.696mm | CastAluminium, right front axle end |
| 2 | `(0.14,-0.092282,-0.256401)` | −30.722mm | Same right front axle end |

The raw trace also reports per-wheel native extrema (as low as−57mm on the right
front rubber in witness2) and current/interpolated transforms. The latter differ,
but the independent gaps show the current geometry itself enters the native
wall. Camera landmark coverage or an interpolation explanation alone cannot
close this contact defect.

A Python-only source-GLB decoder independently identifies the material surfaces:
`.local/clyde-board-material-classify.py` / `.json`. Witness0 is70µm from its
nearest Urethane source vertex; witnesses1/2 are10.7µm from CastAluminium and11.7mm
from the nearest Urethane vertex. The original generator explicitly creates the
axle fromX±0.14 atY−0.088/Z±0.255 with radius0.0045
(`tools/art/build_skateboard.py:258`). No material/vertex is exempted from the
strict clearance test. Source GLB SHA256:
`d5a68a8bd94fa8ad5c374ceddeb3804cc38d7ef780c5b87d3093ef8e15431f99`.
