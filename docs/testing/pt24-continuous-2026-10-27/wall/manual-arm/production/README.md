# Production ordinary Manual arm proof

The production candidate fits ungripped arms during an **earned ordinary Manual
or Nose Manual** and its residual pose. It reuses the just-completed native
board/loaded-tyre certificate and the existing finite Skin/hand solver. All other
styles, grips, contacts and unsafe geometry retain their exclusions. The original
shoulder origin is now read directly in its shared rider/Skeleton frame, removing
the world round-trip that changed its bits by up to0.36 micrometres.

[Parser](parse/receipt.json) is clean. [Focused production](native/receipt.json)
passes **145/0**, exit0, clean/stable **658** inputs in **13.531 s**. This contains
54 retained wall checks, the original24 Manual checks, four added Nose arm checks,
eight genuine ordinary Manual checks and55 safety controls. The source manifest
is `353a2120f453be4ae153f40d86539d3b4b9bbf570a3642a3672133449f6c39e0`.
All inputs resolve to649 immutable `98311cb` Git blobs plus nine exact snapshots.
Only this run's own raw console is included. [Decoded metrics](metrics.json)
retain the quantitative fields; the original console remains authoritative.
Required combined admission and matched native frames are separate records.

## Genuine input representatives

Nose Manual retains the original held-Push/fresh-Manual route at2.658 m/s:
52 active ticks, native impact79, four pre-capsule fits and46 residual fits. The
complete board/shoes retain7.999990 mm minimum wall clearance within145.927 mm
root translation; both loaded front tyres retain7.999964–8.392751 mm support.
The real catalog event banks100 exactly once. No scored-route actor pose,
velocity or trick state is assigned after initial placement.

The new Nose arm checks cover51 earned root-fit frames. Original Skin/curl
samples have **zero** panel hits versus **10,503 accumulated hit samples** in the
same-root no-arm control. There are60 arm fits, maximum five native queries and
83.519 mm wrist shift. Changed wrist/elbow actor-relative steps are75.715 mm and
108.792 mm, including the first correction. Every shoulder origin, unmodified
marker and unblocked right arm remains exact; fixed .30/.29 m arm lengths and
conservative envelope containment pass.

Ordinary Manual uses real Push, releases at tick50, coasts for12 actual neutral
physics ticks, then presses fresh Manual at tick62. It earns the genuine neutral
catalog **Manual** at4.177 m/s, reaches native impact104 and banks100 exactly
once in both twins. Its two active fits include one pre-capsule frame;46 residual
fits follow. The actual catalog-loaded rear tyres retain7.999994–8.392774 mm
support, and board/shoes retain7.999960 mm wall clearance.

During earned ordinary fits, original Skin/curl has **zero** hits versus a
**2,138-hit per-frame maximum** in the same-root no-arm control. All62 arm fits
succeed, at most five queries and197.952 mm wrist shift. Actual changed wrist/
elbow **world** travel stays195.558 mm and pose travel inside the exact common
visual root stays197.689 mm, both below the unchanged220 mm bound. Shoulder
drift is exactly zero in world, actor, visual-root and bone-local coordinates.
Native body/balance, common root, local board/rider, every non-arm bone, head,
feet, far hand and far elbow match their fitted-root no-arm twin exactly.

## Coordinate and parity contracts

The original board/root slice's every-bone parity is intentionally narrowed only
to the two sleeve/forearm bone pairs and hand nodes that receive the arm fit.
Every non-arm bone and each physical/root/board/contact/scoring contract remains
strict. The no-arm control receives the same finite root fit and native inputs;
its helper is replaced before tree entry. The unfitted-root control separately
retains the original board-clearance and physical/local-pose checks.

Raw actor-relative ordinary wrist travel remains **256.631 mm**. On its first
fit the actor moves forward61.073 mm while the common visual root backs off
58.942 mm. Those motions cancel in visible space. Accordingly the220 mm pose
criterion is applied to actual world markers and the same common visual-root
frame as the fixed-rig pose, retaining the actor-relative value for inspection.
The earlier6/2 epoch remains archived; no cap or finite-clearance threshold was
increased. The production log's legacy `bones_equal` field now refers to the
explicit non-arm assertion, not every arm bone.

## Safety and cost

All55 native controls pass with the production helper: other catalog Manual IDs
cannot borrow an earned flag; stale active/residual IDs, all other grip/style
influences, air/force-air/invalid floor, invalid axes and unarmed full fade refuse.
Actual disabled, moved, lowered and graded floor first runs the **normal final
board/loaded-tyre solver**, whose current certificate blocks arm eligibility.
Moved-away wall geometry permits no remembered infinite-plane correction.
Actual bail/restart clear both arm continuation and Manual root authority.

The existing three query resources, **12-call** arm ceiling, **20 cm** wrist
ceiling, **18 cm** shared-root ceiling and original query skins remain unchanged.
The new eligibility adds up to two clear-envelope checks on an earned Manual
wall-fit frame, or the existing bounded solver when needed. It adds no floor
queries, shapes or per-frame mesh reads. This focused proof does not measure
moving render time or target-Mac performance, nor accept every variant/corner.
