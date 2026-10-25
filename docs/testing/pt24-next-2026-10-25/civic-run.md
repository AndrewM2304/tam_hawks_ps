# C04-L03 — civic bank to gallery entrance

Candidate prepared from main `258fec4`. Tests and this record are the only files
owned by this slice. No production geometry or controller changes are proposed
without a reproduced obstacle or placement failure.

## Intended line

Start at (−22,6.08,−114), facing south. Ordinary Push descends the existing civic
west bank to Y4, then a real Ollie near Z−95 lands in the lower courtyard. A fresh
Manual follows the clear west side past the gardens, carves through approximately
(−22,−72) → (−18,−65) → (−12,−59), descends the west gallery close from Y4 to Y2,
then turns onto the existing west gallery-entrance bank and reaches its Y2.65
terrace near (−3,−37). Release and brake there to bank once.

This uses existing banks, meaningful flatland and the actual graded district
join. The separate `Grind_Rail_George` line is not silently included: its X14
southward release needs a distinct turn around the Cat course and gardens. No
gallery ledge catch or uninterrupted rail sequence is claimed by this bank route.
The gallery agent owns that separate flagship continuation.

## Driver and risk boundaries

`tests/pt24_civic_flagship_tests.gd` allows one initial spawn and facing. Every
later movement and heading change uses ordinary Push/Brake, Ollie, Manual and
steering inputs. During a manual, steering balances and shoulders carve through
the production control path. There are no per-tick actor transform, velocity,
speed, heading or score overrides. Existing direct-heading route helpers are
therefore not used to establish this line.

The main risks are losing speed across the long manual, an over-tight turn at
the gallery-close mouth, and camera obstruction near the portico. Fixed native
support/capsule samples cover the whole proposed footprint. The input driver
records actual slope contact in all three banks, actual Manual travel, camera
volume/body visibility, all awarded tricks and each bank. Separate ordinary
no-jump input runs cover the whole route in both directions. The existing lower
service-court escape banks and civic cross-street are independently protected.

Construction budget: zero new bodies, shapes, triangles, draws, materials,
textures or runtime world work. A failed approach must be retained as evidence;
do not add unrelated pads or weaken collision/camera tolerances to make it pass.

## First focused verification — rejected camera acceptance

Root granted one serialized engine run. Command:

```sh
timeout 180s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_civic_flagship_focused.gd
```

The auxiliary runner sets `persistence_enabled=false` before attaching Main.
Result: **7 passed / 1 failed, exit1**, with no engine/script error. This is
development evidence while other source owners could still edit; it is not a
frozen-source combined admission.

The complete input run traverses **88.151m**, with 70 native civic-bank slope
ticks, 134 close-slope ticks and 41 entrance-bank ticks. One real Ollie followed
by **556 Manual ticks** reaches the raised gallery terrace with **zero bails**.
The pending value is **400**, banked **once** as400 and unchanged during the
following observation. Both ordinary no-jump directions pass. The297 fixed
width/native support samples and protected lower-court returns also pass.

The one rejected gate is full rider/board/native camera visibility: two sampled
low markers cross actual terrain at the gallery grade changes. At rider
(−12.00201,1.999328,−41.88755), marker
(−12.1306,2.017051,−42.12531) is occluded by `GalleryWestClose`. At rider
(−9.898241,2.03735,−37.07586), marker
(−10.16565,1.990563,−37.12523) is occluded by `GalleryTerrace` atY2. These are
presentation/support witnesses, not evidence that the line needs another prop
or that the camera assertion should be weakened. Root owns the shared rider/
camera correction and subsequent serialized admission.

Source geometry remains unchanged by this slice. Automated reachability does
not certify human steering difficulty, fun or target-Mac performance. The engine
slot was released after this first run. Original focused output is retained
verbatim below so the rejected result survives ignored `.local` cleanup.

Raw console SHA-256: `e3d5855ac8c622e07cf2ff9be964a86b121effa10f68a72f3205c5ea03ef7591`.

```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

PASS C04-L03:297 fixed-width bank/court/close/entrance sites have native support and two-way rider clearance
PASS C04-L03: both actual Merchant lower-court escapes and the civic cross-street remain clear
CIVIC_FLAGSHIP_GEOMETRY samples=297 support=true clear=true lower_return=true added_bodies=0 added_triangles=0 added_draws=0
DENSITY CAMERA OCCLUSION rider=(-12.00201, 1.999328, -41.88755) camera=(-11.96237, 4.653471, -47.87803) marker=(-12.1306, 2.017051, -42.12531) hit=(-12.13053, 2.018146, -42.1277) collider=GalleryWestClose
DENSITY CAMERA OCCLUSION rider=(-9.898241, 2.03735, -37.07586) camera=(-13.73179, 4.147583, -40.41158) marker=(-10.16565, 1.990563, -37.12523) hit=(-10.18126, 2.0, -37.13961) collider=GalleryTerrace
PASS C04-L03: actual Push descends the civic bank and earns a lower-court Ollie before landing
PASS C04-L03: actual balanced Manual carves through the lower civic court and graded close onto the raised gallery entrance
PASS C04-L03: the complete civic/gallery Ollie-Manual route banks its exact earned value once
FAIL C04-L03: complete rider, board, soles and native chase volume stay clear along the full linked run
CIVIC_FLAGSHIP_RESULT {"at":"Vector3(-3.6979122, 2.6625443, -36.95125)","bails":0,"bank_slope_ticks":70,"banked":400,"banks":1,"camera_clear":false,"camera_samples":137,"close_slope_ticks":134,"descended":true,"distance":88.1511786109768,"entrance_slope_ticks":41,"landed":true,"manual":true,"manual_begin":"Vector3(-22, 4.012421, -90.0652)","manual_end":"Vector3(-4.011864, 2.6625443, -36.929337)","manual_ticks":556,"pending":400,"reached":true,"stages":[{"at":"Vector3(-22, 5.99987, -113.998055)","speed":0.116729728877544,"stage":"civic_bank_descent"},{"at":"Vector3(-22, 4.003694, -94.82182)","speed":10.1985158920288,"stage":"lower_court_pop"},{"at":"Vector3(-22, 4.126901, -94.48665)","speed":9.83207702636719,"stage":"lower_court_air"},{"at":"Vector3(-22, 4.012421, -90.0652)","speed":9.64874172210693,"stage":"manual_court_close_entrance"},{"at":"Vector3(-3.9530358, 2.6625443, -36.93344)","speed":3.53828239440918,"stage":"single_bank_on_entrance"},{"at":"Vector3(-3.6979122, 2.6625443, -36.95125)","speed":0.0,"stage":"stable_bank_observation"}],"target_index":7,"ticks":823,"tricks":["Ollie","Manual"]}
PASS C04-L03: ordinary no-jump civic-to-gallery bypass follows the entire supported line
CIVIC_FLAGSHIP_TRANSIT reverse=false reached=true target=12 grounded=true bails=0 at=(-3.905849, 2.662466, -37.00699)
PASS C04-L03: ordinary no-jump gallery-to-civic return follows the entire supported line
CIVIC_FLAGSHIP_TRANSIT reverse=true reached=true target=12 grounded=true bails=0 at=(-22.0, 6.012466, -113.1037)
CIVIC_FOCUSED_RESULT 7 passed / 1 failed
```
