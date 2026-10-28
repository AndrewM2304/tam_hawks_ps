# Native turning-landing and wallride frames — 28 October 2026

The [final capture](native-final/receipt.json) passes **8/0** in **32.300 s**,
exit0 with clean logs and **680 unchanged source inputs**. Its manifest is
`c9f5d0d13d511764d6228efb13ae297274d663b727fe18eb688e8653cdaabcbb`.
The [final parser](parser-final/receipt.json) passes in0.856s. Parent source is
`21b0e86d79d9934a9b482cb6887ae91897b60467`; exact changed source snapshots retain
the subsequently committed repair, observer and current tests at capture time.
The [derived readout](READOUT.json) and [original native record](frames-final/CAPTURE.json)
retain the full measurements. This is supporting fixture evidence, separate
from the complete required check.

## Eight original images

| Actual native stage | Prior controller | Repaired controller |
| --- | --- | --- |
| First capture, wall on rider's left | [Original](frames-final/before-wall-on-left-wall-entry.png) | [Original](frames-final/after-wall-on-left-wall-entry.png) |
| First capture, wall on rider's right | [Original](frames-final/before-wall-on-right-wall-entry.png) | [Original](frames-final/after-wall-on-right-wall-entry.png) |
| Early ordinary release, wall on left | — | [Original](frames-final/after-wall-on-left-wall-release.png) |
| Early Wallie, wall on right | — | [Original](frames-final/after-wall-on-right-wallie.png) |
| Left steering-Ollie, eight rollout ticks | — | [Original](frames-final/left-turned-rollout.png) |
| Right steering-Ollie, eight rollout ticks | — | [Original](frames-final/right-turned-rollout.png) |

All eight960×640 original PNGs were inspected. The first-contact pairs show
the smaller initial mirrored lean; the early release/Wallie and turning rollout
frames show one connected rider with feet and board together. The plain fixture
wall fills the background, so native measurements govern clearance. These frames
do not certify whole-city art, human feel or complete moving-animation quality.

Each readback freezes a completed native sample, resets interpolation and waits
for two completed draws. Actual/interpolated actor, visual, board, rider, head,
two feet and two hands agree in all eight images. Every full rider fits the
fixed diagnostic camera. The separately retained ordinary chase-camera states
also pass the existing native board/head/foot frustum, visibility and camera-sphere
checks in all eight observations. Their last processed state is frozen at that
sample; they are not a new moving-camera route acceptance.

## Wall approach and early exits

Four sequential real Skaters use the same current rig, meshes and assets, a
native0.4×24×40m wall centered at(0,8,0), a floor and a declared initial-air
placement at(side×0.90,8,8), heading0, velocity(−side×1.2,0,−8). Eight initial
frozen-physics frames prime the ordinary camera; held Grind then earns real
native support. There is no direct wall-active assignment. The positive-X
fixture has its wall on the rider's left; the negative-X fixture mirrors it.

Both controller epochs use identical early inputs: release Grind at zero-based
control tick5, or press Ollie at1/release at5 with Grind held. First native catch
is sample1; early exit/Wallie is sample6. All46 consecutive samples per actor
are retained. Native body position, velocity and yaw match **exactly**, with
maximum measured difference0 in both before/after pairs. Both ordinary release
cases emit one wallride; both Wallie cases emit one wallride and one Wallie,
with zero bails. No lost physical momentum is restored by the capture.

| Measured original/repaired wall presentation | Before | After |
| --- | ---: | ---: |
| Maximum adjacent visual rotation |0.649999992rad|0.075000149rad|
| Maximum adjacent local visual offset |544.120729mm|75.000003mm|

The rotation measurement uses independent relative-matrix `atan2` on the exact
recorded previous/current orthonormalized bases. Raw `Quaternion.angle_to` is
also retained; its repaired maximum is0.075003333rad. That small-angle acos
conditioning is not erased or used to raise the presentation limit. The focused
wall controls own rate/precision admission; this capture retains both metrics
and exact basis witnesses without changing their criterion.

## Actual turned landings

Each current-controller case begins once at(0,0.8,12) on the native100m floor,
settles45 ticks, receives Push30 ticks and held Ollie24 ticks, then releases
Ollie. After its first earned flight tick, left/right steering is held20 ticks
at the exact analog quarter-turn strength. No later physical pose, heading,
velocity or trick flag is assigned by the observer.

Both flights run from native sample100 through137 and land at138. Their XZ
velocity is unchanged throughout flight: `(0,−8.954272)m/s`. On contact it
becomes approximately `(±8.954287,0)m/s`, matching the chosen heading. After
eight grounded rollout samples the velocity is `(±8.632455,−0.000000652)m/s`
and body yaw is∓1.57079625rad. Each earns one Ollie event, one scoped clean
Ollie landing and zero bails. The earlier fixture-settling fall is separately
retained in `total_lands=2`; it cannot satisfy the earned-flight capture gate.
Actual prelanding transforms remain at sample135 in the metrics.

Continuous real Skin/bind sampling keeps the maximum clothing seam below59.21mm,
joint gap below24.91mm and neck gap below23.37mm, within the existing80/60/50mm
controls. Focused tests separately own finite wheel/path and incomplete-trick
negative controls; the screenshots do not replace them.

## Retained harness rejections and provenance

The [first parser](parser-first-rejected/receipt.json) remains rejected: an
inferred Variant/bool declaration failed to parse. Adding the explicit bool
type produced the [intermediate clean parser](parser-corrected/receipt.json).
The [first native attempt](native-first-rejected/receipt.json) remains **0/2**,
29.326s, clean/stable: the capture gate armed on the initial fixture fall and
paused before the actual Ollie input, so both outgoing-direction guards correctly
failed on zero velocity. Its [eight images and raw record](frames-first-rejected/CAPTURE.json)
are preserved unchanged. The final harness adds only a setup/earned-flight
capture gate and separate total/scoped landing counters; no existing direction,
pose, attachment or native-motion tolerance was loosened. Fresh output paths
retain both epochs.

[The baseline declaration](observers/BASELINE.json) records the unedited prior
Skater controller. Its195,447 bytes were independently compared byte-for-byte
with `git show21b0e86:game/player/skater.gd`; SHA-256 is
`609afff41622a6587c37073641b5096f255494bdaba79c379fe6f34e0291ccf5`.
The actual baseline script, capture script and Python runner are source-bound
by the outer observer. `BASELINE.json` metadata is hashed by the inner capture
before/after maps and this artifact index; it is **not** claimed as an outer
code-map member. All670 unchanged inputs resolve to immutable parent Git blobs;
ten exact changed input snapshots are retained in each final parser/native
archive. The same current rig/assets are used by both controller epochs.

The [observer sources](observers/) and all original maps/logs/JSON/PNGs are indexed
by [ARTIFACTS.json](ARTIFACTS.json), with case-safe paths. The Python runner reuses
the existing bounded private-Xorg capture wrapper. It uses a fixed60 diagnostic
clock and a90-second engine bound. No Main/personal profile is constructed.
No Mac, display-FPS, performance, ordinary Main-route or final human acceptance
is inferred. No THPS implementation or animation asset is imported.
