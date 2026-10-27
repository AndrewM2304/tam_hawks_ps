# Finite wall contact through a flat Ollie — 27 October 2026

C03's ordinary neutral wall fit previously cleared immediately when the rider
pressed Ollie. Actual Push → native shutter contact → Brake → Ollie therefore
moved the connected board/shoes back through the wall, while the physical
capsule and movement remained unchanged. The existing synthetic active-state
exclusion checks did not exercise this real transition.

## Repair and bounds

Ordinary grounded crouching now uses the same flat-support proof as neutral
skating. Only an actual ordinary, flat-ground Ollie can carry an already proven
nonzero wall offset into flight; the jump event arms this continuation, including
a genuine within-frame tap. Generic falls, transition launches and synthetic
air flags do not arm it. Manual, flip, grab, special, wallride, transition,
setup, lip, skitch, slide and bail policies retain their exclusions.

The airborne continuation considers only the decaying prior offset and the
unchanged prior offset, with the existing 18 cm ceiling. Each proposal needs
fresh finite native clearance for the actual board convex envelope and both
conservative shoe envelopes. A 7.99 mm native query margin retains the existing
8 mm skin with a declared 10 micrometre numerical tolerance. No remembered
infinite wall plane, new air correction, floor support claim or physical actor
movement supplies the fit. Once the finite obstacle disappears, the existing
45 ms decay can proceed. An impossible secondary obstruction refuses both
candidates; refusal does not claim that the resulting unfitted pose clears
mutually incompatible obstacles.

Shoe bounds are cached once from the authored child mesh bounds/transforms.
The existing reusable board query/box supplies the shoe checks, and its shape,
size, margin and transform are restored on every success/refusal path. The
existing whole-board hull, already constructed to obtain support faces, is
retained in the static visual cache with zero shape margin and exposed read-only
through `board_contact_geometry().convex_shape`. Native checks confirm its
published support faces are unchanged from the original temporary hull.

This retains **one additional shared convex shape/RID** that previously became
temporary garbage; resident bytes are unmeasured. There is no additional hull
construction, per-frame hull rebuilding, visible mesh, texture, material or
light. Clear ordinary skating adds no candidate query. The existing grounded
fit remains at most two proposals × four support rays/one board query. Retained
plain-Ollie flight adds at most two proposals × three native shape queries:
**six bounded queries**, with early rejection. These source bounds are not a
frame-time or target-Mac performance result.

## Focused native result

[Final receipt](focused/final/receipt.json): **33 passed / 0 failed**, exit0,
clean log, 628 unchanged inputs, 5.7155 seconds. This comprises 20 retained
ordinary-wall assertions and 13 new transition/hull assertions. The former
synthetic crouch exclusion is replaced by real positive crouch/flight coverage;
all other active-state exclusions remain. Exact raw logs, source maps and source
snapshots are retained with the receipt.

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/wall-ollie-final timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/wall_ollie_focused.gd
```

The exact runner is archived at
[its snapshot](focused/final/source-snapshot/.local/wall_ollie_focused.gd).
The receipt's manifest SHA256 is
`9c350b0f320ab3cd18516e522ee0f7aa3f51ac1f5624b6f48858d40c6456c6a1`.
Its Git head `b257b56` is the development parent, not a claim that the parent
contained the repair; the actual checked bytes are mapped independently.

| Actual native witness | Result |
| --- | --- |
| Held Ollie after real wall impact/braking | 12 crouch ticks, 31 air ticks, native landing; minimum actual board/shoe gap 8.00002 mm, maximum offset 132.320 mm. |
| Unfitted input twin | Actual geometry penetrates 124.320 mm; physical motion and local rider/deck poses remain exactly equal to the fitted actor. |
| Genuine within-frame gamepad Ollie tap | 26 real air ticks; minimum gap 8.00002 mm, maximum offset 129.542 mm, identical physical motion. |
| Finite wall moved away during actual flight | Monotone 132.320 → 0.168 mm offset over 18 native ticks, identical physical motion, no bail. |
| Declared paused-air secondary obstruction | Both unsafe visual candidates refused; shared query shape, bounds and margin restored. |
| Cached hull compatibility | Zero shape margin; actual support faces equal the original temporary-hull margin control. |

## Retained rejection and diagnosis

The [first candidate](focused/rejected-obb/receipt.json) passes 26 assertions
and fails three. Crouch is repaired, but the existing conservative board box
rejects an otherwise safe real Ollie pose, then clears its retained offset.
This result is preserved, not accepted as a repair.

The [first-air native query diagnostic](focused/firstair-query/receipt.json)
completes in 0.851 seconds with a clean, stable source. It identifies the box's
empty lower nose corner intersecting the actual shutter under board pitch;
both actual shoe envelopes clear. The existing exact-component cache contains
32 convex components. Retaining its already constructed whole-board hull avoids
replacing the six-query bound with 64 board-component queries. Exact snapshots
of the rejected controller, current rig, tests and diagnostic runner are linked
from each `SNAPSHOTS.json`.

The [original quick-tap causal diagnostic](focused/original-quick-tap/receipt.json)
uses the unchanged controller and retains the real within-frame release/press
behavior separately from the final fresh held-Ollie witness. Its initial
[unregistered-action driver rejection](focused/rejected-unregistered-actions/receipt.json)
is retained with exact script snapshots; it is not valid gameplay evidence.

Independent QE owns the matched [native frame explanation](native-frames.md),
[outer receipt](native/receipt.json) and [four captured frames](captures/).
Those exact frames show board intrusion and repair; their before shoes already
clear the wall, and their after shoe clearance remains positive.
All full combined, cold-launch and package claims belong to the parent batch
record. This bounded result does not accept active flips/grabs/manuals at walls,
all corner arrangements, moving target-Mac visuals, hardware feel or target
performance. Normal merged features remain available.
