# Tyre27 versus Station west rim — offline classification

This identifies the rejected contact; it does not repair or admit it. No new
engine was run. The native packet uses controller`56787e07` and visual`6f6d6dca`;
subsequent actual source has changed, so this is not a current-source replay.

The tyre crosses **its own bank's west rim** while in grounded Manual. It is not
an off-route prop or a foreign feature. That makes the location intentional,
but **2.33mm of tyre inside a native solid is not authenticated acceptable
bearing contact**. There is no active grind capture in the full route, no Grind
input at this sample, and no authority to borrow the named truck/hanger contact
tolerance. The separate loaded capsule solver limit does not apply to tyres.

## Source point and time

- Actual physics frame **319**,5.016667s after first retained prefix row18 at the
  configured60Hz. This is a physics interval, not a wall-clock timestamp.
- Exact GLB hash`76103e39e5ed91c5c8381d38c58af8272915952f000ba475dbda30206b7d0943`.
- Primitive/material3`Urethane`, POSITION accessor12, bufferView13, **vertex100**.
- Float32 position: `(-0.12399999797344208,-0.11388854682445526,-0.27380913496017456)`.
  Its12 bytes at file offset557780 are`b6f3fdbd663ee9bdb6308cbe`.
- This is `wheel(side=-1,z=-0.255)`, profile index2 (axial−9mm/radius32mm),
  angular sample12/20 =216°. Native cache part27 point68 maps to it. All160
  rounded cache points map one-to-one to160 exact source positions; maximum
  rounding displacement is0.05983mm.
- Source triangles106/107/109/146/148/149 contain that vertex. These are **GLB
  source triangle indices**, not returned native face indices.

## Finite cylinder calculation

The positive native shape query reports the real
`Grind_Ledge_station_low_manual/NativeGrindBearing`, integer shape **3**,
shapeRID`21010980013154`, bodyRID`20993800143291`. It is enabled and has radius
70.0000003mm, length2199.99981mm. The retained static Node/backend matrices agree
as serialized. Composing body and native-local shape frames gives centre
`C≈(-91,2.31,37.2)` and unit axis`a=(0,0,-1)`.

For source point transformed by the retained displayed board frame, use
`s=(P−C)·a`, `q=(P−C)−s·a`, `gap=length(q)−radius`:

| Quantity | Derived value |
| --- | --- |
| Source point in world | `(-90.96853959,2.36991118,37.24556745)` |
| Point minus cylinder centre | `(31.4604,59.9112,45.5674)` mm |
| Axis coordinate | −45.5674mm |
| Radial vector | `(31.4604,59.9112,0)` mm |
| Radial length |67.6691mm |
| Signed radial gap | **−2.3309mm** |
| Ideal cylinder outward normal |`(.464915,.885355,0)` |
| Closest radial surface point |`(-90.96745592,2.37197486,37.24556745)` |
| Distance to closest axial cap |1054.4325mm |

Every source tyre vertex is inside the finite axial bounds, so this is a side
contact on the downstream/east upper quadrant, not an endcap or an infinite-axis
extension. The actual native overlap is positive; native rest-info and contact
pairs were empty. The normal above is **analytic shape geometry**, not a claimed
native returned ray/contact normal. World matrices/positions were serialized as
rounded strings, so calculated world distances are estimates; source vertex
bytes and physics/shape identity are exact. No positive clearance certificate
or altered tolerance follows from this arithmetic.

## Pose and likely mechanism

This is a normal transverse bank crossing. Actual travel is almost+X and the
rim axis is−Z, about88.86° apart. The lower/trailing tyre centres are atY2.4000;
the raised axle centres areY2.5414. The displayed board's axle has worldY0 to
serialization precision and longitudinal pitch about16.095°. This is a Manual
pitch, not the substantial side roll used to clear a round50/50 bearing.

The two lower axle centres are staggered about4.59mm inX by the ordinary1.14°
heading correction. Analytic cylinder tops beneath them differ about3.83mm.
Those are predicted shape surfaces, **not fresh observed ray hits**. A small
finite simultaneous axle fit may therefore be needed as the tyres pass the
crest. Blind extra roll does not solve it: a static−1° illustration still leaves
both lower tyres about0.83/1.35mm radially inside; +1° worsens tyre27. These are
vertex-only illustrations, not native candidate tests.

At317 the real actor isY2.381404, at318 it is on the flat deck atY2.360141.
Only319 has the board-component rejection;320 is clear. This supports the
hypothesis that the capsule reaches the flat before its trailing Manual tyres
finish the rounded crest. The production branch is **not instrumented**, so it
is not established whether a centre-ray fit, later finite-rim fallback or
another presentation stage rejected/overwrote the needed fit. Empty rest-info
must not be equated with an empty shape query.

For scale only, moving this isolated tyre vertically about2.62mm reaches zero
radial overlap,7.07mm reaches4mm radial separation and11.46mm reaches8mm.
These are **not runtime correction proposals**: they omit the complete model,
other tyres, connected shoes/body, load/float and per-step continuity authority.
Any fit must prove all of those inside existing limits. Moving the bank a few
centimetres merely to miss this physics phase would hide the approach-variation
defect rather than resolve it. No geometry, input threshold, actor or controller
was changed for this classification.

The portable read-only `inspect-source-vertex.py.txt` recomputes source mapping,
axis/radial vector and identity against the pinned GLB. The other JSON retains
separately labelled fixed-origin roll/vertical illustrations. Keep the native
Station04 aggregate28/3 and early-stop diagnostic0/1 rejected.
