# Loaded manual axle at finite grade joins

25 October 2026. Targeted C03 repair from the unchanged Civic input run on main
`258fec4`. No terrain, camera tolerance, physics force, score rule or trick
requirement is changed by this slice.

## Native diagnosis

The original Civic line travels 88.151m, holds an ordinary Manual for 556 physics
ticks, banks 400 once and records zero bails. Its unchanged strict camera check
finds two embedded board markers after completed node processing.

A bounded diagnostic classified both exact reported markers against the actual
displayed GLB convex vertices and individual real wheel components:

| Witness | Exact reported marker | Actual native support | Reported signed gap | Complete loaded tyre minimum |
| --- | --- | --- | --- | --- |
| Grade exit, rider `(−12.00201,1.999328,−41.88755)` | TamSkateboard rear tyre component3, matching within0.079mm | GalleryWestClose, normal `(0,.989949,.141428)` | −0.746mm | Rear tyres2/3: −7.275/−7.328mm |
| Bank entry, rider `(−9.898241,2.03735,−37.07586)` | TamSkateboard rear tyre component3, matching within0.032mm | Flat GalleryTerrace, normal UP | −9.437mm | Tyre3: −20.606mm; opposite loaded tyre2 floats7.297mm |

These are tyre vertices, not sole/toe endpoints. The existing4mm grounded-rubber
endpoint band cannot explain the full penetrations. The manual board child pitch
is0.285342rad (16.348°), with its existing rig compensation at localY0.18822.
At the first witness the capsule already reports flat UP while the loaded axle
remains on the grade. At the second it reports the bank normal while the axle
remains on flat paving.

The first diagnostic invocation was refused for an observer-only type-inference
error; that log is retained. Correcting its Transform3D annotation permitted the
actual unchanged input run. `.local/pt24-manual-grade-diagnostic-02/receipt.json`
records the expected rejected5/1 result, exit1,589 stable inputs and9.223s. The
only behavioral failure is the strict camera/contact witness. Root owns durable
evidence copying and final combined-source admission.

## Presentation-only repair

Ordinary grounded Manual/Nose Manual now fits the actual loaded axle after the
rig has applied its manual pivot and planted the shoes. The selected pair comes
from actual pitched board coordinates, including committed deck orientation.
Native rays supply each wheel's finite support. The two hit positions constrain
axle roll across different planes; their native planes supply longitudinal grade.
No capsule-normal average or neutral four-wheel pose replaces the manual.

The whole existing presentation moves rigidly. The board's local pitch/position,
foot-on-deck relations and authored limb lengths remain unchanged. Correct planar
manuals take an exact no-change shortcut only when both loaded tyre gaps agree
within1mm; matching normals alone cannot justify leaving one tyre floating over
a lower plane. The existing8mm presentation skin is retained. No physical force
or physical collision/contact policy changes. Pogo, Casper and rolling manual
variants keep their separate existing poses. Actual immutable tyre hulls provide
the finite-rim safety check; an obstructing wall cannot be hidden with a lift.

Cost ceiling: zero meshes, draws, materials, textures, lights, bodies or shapes
added to the world. Reuse the existing startup-cached tyre vertices/hulls. Only
eligible grounded manuals run the helper: at most three passes of two support
rays, then four overlaps plus at most four raised overlaps/four native casts
(18 local native queries maximum); an agreeing planar case uses two rays and
returns. No per-frame mesh scan or convex construction is added.

## Independent verification contract

`tests/pt24_manual_grade_tests.gd` constructs finite native joins in a private
World3D for ordinary and nose manuals, including a finite50mm lateral step under
the two loaded wheels and unchanged flat controls. Each presentation is compared with a
subclass retaining the former capsule-normal behavior. Declared initial active
manual state and speed are shared; subsequent motion/balance uses the same
production physics and mapped input. This is contact verification, not a claimed
earned manual or scored route.

Both loaded real tyre rims must remain supported; the old controls must expose
penetration for both manual directions. Physics/capsule/velocity/manual state
must remain exactly equal, local board pitch/pivot must match the control,
shoes must stay planted and planar presentation must remain exactly unchanged.
The original Civic actual-input/camera/400-point receipt is a separate mandatory
regression, with all assertions retained.

## Focused result and retained rejection

The first post-repair run is retained as rejected20/6. Every tyre, physics,
local-pivot, sole and flat-control assertion passed, as did the unchanged Civic
line. Its six failures were a new fixture bookkeeping inconsistency: traversal
required a coordinate above0.80m, but the observer stopped above0.70m. The
correction stops above0.85m and keeps the original meaningful0.80m requirement.
No production tolerance or input was changed to repair that observer.

The clean focused run passes **34/0**, exit0, clean log, **590 unchanged inputs**,
12.330s. It includes29 independent manual-grade assertions, an inert-Music
assertion and the four unchanged Civic actual-input assertions. Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-manual-grade-focused-02 timeout 180 ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_manual_grade_focused.gd
```

Manifest SHA256:
`8cac6206563346117dc3ff709edceb454ad35cebeb896bff91d1d5dddf63837c`.
Root owns durable copying of the observer/log/receipt and final combined admission.

All eight native fixtures pass: ordinary/nose manuals on downhill→flat,
flat→bank, split50mm planes and unchanged flat controls. Loaded tyre minima
are6.90…8.00mm above actual support, versus13.45…31.28mm penetration in the
unchanged capsule-normal controls. On the split planes the old lower tyre
floats58.015mm; both fitted tyres bear at8.000…8.003mm. Physical histories and
local board pitch/pivot match exactly; sole-to-grip error stays below0.854mm,
and the flat presentation remains exactly unchanged.

The unchanged Civic line now passes all137 strict camera samples while retaining
the same88.151m trajectory,556 manual ticks, one400-point bank and zero bails.
No camera/Density assertion or endpoint band was altered. The Gallery agent's
separate grade-exit witness may share this cause, but remains unclaimed until
that actual line is rerun. Target-Mac moving visual/feel acceptance and final
source-bound combined results remain separate.
