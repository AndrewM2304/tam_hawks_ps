# PT24 code repairs — 25 October 2026

Work is directly on `main`, starting at `0b8b30e`. Six agents divided park,
outdoor, skating/camera, recorder/pose, station/gate and independent geometry
checks; integration owns the city and combined admission. The owner's 38 images,
coordinates and notes in [the original packet](../debug-session-2026-10-24/INDEX.md)
remain the defect evidence. The archival candidate patch was not reapplied.

## Implemented changes

| Tickets / captures | Code change | Deterministic evidence |
| --- | --- | --- |
| PT24-02/03 · 4/6 | Close the civic frontage return and the north edge of the park connector; keep the westbound park opening | Fixed required spans, native rays in both directions, displayed foundations and protected mouths |
| PT24-04/07 · 7/8/11/12 | Smooth the existing grass shoulders, close promenade sides, and select the highest eligible city/outdoor support | 130 lateral native samples/public-height comparisons; separate lower/upper station support |
| PT24-08 · 13/14/15 | Close the shelter terrace/spur and both arrival/bypass ramp sides | 66 shelter side rays; 456 ramp side rays plus outward-face checks |
| PT24-01/05/06/09 · 2/3/9/10/16/17 | Remove 56m² of duplicate civic paving, overlapping summit skins, station halfpipe flat display and redundant bowl cheek caps | Actual projected overlap/area, original planes, collision preservation and face ownership; temporal flicker remains open |
| PT24-11 · 19 | Turn the existing station spine across the clear concourse | 32 native support rays and 32 rider-capsule clearance samples; input transfer regression uses local coordinates |
| PT24-13/14 · 21/22 | Extend the climbing-lane shoulder to the frontage and provide a broad graded exit from the lower court | Dense support/native-height checks and continuous exit profile |
| PT24-22 · 30/31 | Extend existing retail backs to the quay wall and replace station-edge ironwork with matching opaque masonry | Actual visible triangles/native rays across independently fixed spans; both Exchange closes and station/quay port remain open |
| PT24-23 · 32 | Classify natural steep departures as ramp air, preserve the actual departed face normal and reset the camera handoff per physical launch | Opposite-wall natural launches/returns, fresh versus held Push, coping pop and one monotone apex handoff |
| PT24-24 · 33 | Admit the existing backed print-yard wall through the surface audit | Exact solid-wall dimensions/backing rays, actual ollie→Wallride→Wallie, single awards and head-on rejection; other safety fences remain excluded |
| PT24-26 · 36 | Fit 64-segment water to the matching basin with a 24cm coping margin | Native mesh vertex containment and unchanged fountain collision/grind identities |
| PT24-27 · 37/38 | Identify both service-shortcut destinations and reduce the existing sign | Supported endpoints, mapped interaction wording and existing gate passage/closure-safety checks |
| PT24-28/29 · 1/14/all reports | Apply a complete neutral pose before the first physics tick; distinguish configured IDs from active states; record player ticks, rendered presentation, input edges and historical bail cause; move recorder indicator | Startup/reset rig invariants, capture/note/ZIP/retry tests and HUD layouts at three scales |

The startup pose has a reproduced source cause. This does **not** establish that
the earlier contracted-body photographs had the same cause.

## Checks without replaying the game

`tests/pt24_boundary_tests.gd` declares required closed spans independently of
the wall generator. Its 1,209 fixed sample operations fail when an entire wall
is omitted; both native collision and actual visible triangles must cover the
required locations. It separately checks that intentional connections stay open.
The park/shelter suites inspect outward winding and real side collision. The
terrain suite checks exact material ownership without changing native support.
The backdrop suite adds 16,614 two-sided face probes; foundation checks cover
800 sites on 32 fixed faces. These checks are registered in `tests/run_tests.gd`,
including the previously unregistered recorder tests.

Existing inventory failures were reconciled against independently checked
geometry. Relative to the captured candidate, no bodies were added; seven
convex panels/prisms were added to existing city bodies. The final contract is
564 bodies / 1,681 shapes, including 271 protected bodies / 728 protected shapes,
the same twelve bench identities and all earlier addition categories. Horizon
geometry is 904 regional + 18 water triangles = 922; every incremental contour
segment is accounted for. The held backdrop remains within its original 4,040
triangle ceiling (2,948 actual triangles). Old rejected consolidation logs remain intact.

## Cost and evidence limits

All world construction is at startup. No new lights, textures, materials,
collision bodies or district are introduced. Outdoor side closure adds
three resident material surfaces and 1,138 triangles. Ramp/cheek repairs remove
twelve net triangles; halfpipe flat display removes one mesh. Fountain refinement
adds 272 triangles to its existing two meshes, removing unnecessary vertical
subdivision rings while refining their circular edges. Station opaque boundaries
replace existing ironwork resources rather than adding another visual layer.
These are construction bounds, not a measured Mac frame-time pass.

The new walls exposed a finite-tyre fitting defect: wheel-centre rays could all
see flat ground while an outer tyre rim overlapped the neighbouring bank by
about 6mm. Four actual tyre convex volumes are cached at rider startup. Ordinary
planar support adds four native overlap queries; genuinely overlapping tyres
use a bounded clear-pose/downcast correction, at most twelve queries total.
The rigid visual correction is capped at 25mm; physical rider motion and camera
visibility assertions are unchanged. No per-frame tyre-vertex scan is added.
Target hardware timing for this bounded query addition remains open.

## Final validation

Required command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-admitted ./tools/check.sh
```

**4,657 passed / 0 failed**, exit 0, clean engine/script log, **538 unchanged
inputs**, 344.941 seconds. [Receipt](validation/receipt.json),
[console](validation/console.log), [before](validation/source-before.json) and
[after](validation/source-after.json). Source-manifest SHA-256:
`b9360478a14b11cbe4d04ab6d4c2a285bfa739e19cdd670134b5f9b711421c70`.
The receipt records the parent HEAD; its complete input hashes bind the repaired
working source that is committed with this record.

`python3 tools/source_launch_smoke.py --output .local/pt24-cold-final` passes all
four phases against **451 unchanged inputs**: cold launch, normal title-to-play
**44/0**, warm launch and refusal of deliberately broken source in the disposable
copy. The refusal's exit 1 is expected. [Cold-launch receipt](cold-launch/SOURCE-LAUNCH.json)
and [console](cold-launch-console.log) preserve the exact phase results.

The bounded render uses Godot 4.6.3 Compatibility / Linux llvmpipe at 1280×800.
[Frame manifest](frames/manifest.json) binds 198 source files to fourteen supplied
camera views and one forced pre-process diagnostic. The separate
[normal startup frame](frames/startup-normal-frame.png) and
[receipt](frames/startup-normal-frame.json) show the complete rider after a normal
completed draw. All sixteen PNGs are retained. [Capture runner](../../../tools/pt24_capture.gd),
[startup observer](observers/startup_frame.gd), [engine log](capture-engine.log).
Static frames do not establish moving shadow stability, skating enjoyment or
target performance.

The forced pre-process draw is preserved as rejected fixture evidence: it bypassed
normal scene/render synchronization and showed an under-board view despite correct
CPU camera coordinates. A separate completed normal startup draw shows the complete
rider. Do not use the rejected fixture as ordinary startup acceptance.

Rejected combined runs are retained: [4,632/17](diagnostics/first-combined/receipt.json)
and [4,654/1](diagnostics/second-combined/receipt.json). Their route, inventory,
finite-wheel and camera findings were repaired rather than hidden by changing
assertion tolerances. Only the final clean receipt above admits this code batch.

## Still open

PT24-01 retains temporal shadow diagnosis even though confirmed duplicate civic
paving was removed. PT24-09 similarly retains moving tile/shadow acceptance.
PT24-10/12/21 have no proven temporal rendering repair in this batch. Matched
Mac clips and receiver/caster controls remain necessary; no global bias change
or shadow disabling was shipped.

The captured lower-park view 11 still shows small grass/asphalt material
intrusions. Native shoulder continuity and no-jump routes pass, but that visible
finish is not accepted; keep the PT24-04/07 material-ownership cleanup open.

PT24-15/16/17/18/19/20/25 remain Planned: station/tunnel/train, pond/ducks/grind
loop, central-green purpose, civic ramp payoff, corridor furniture, market-wall
redesign and bridge-cable transfers. The report and ADR-032 require the existing
stutter admission before new rendering expansion. No target Mac is attached to
this cloud workspace, so that gate cannot be certified here. Existing safety
and behavior repairs do not constitute implementation of those design items.

PT24-28's older contraction case, human Mac/DualSense, moving visual acceptance,
target performance and exports remain open. PT24-30 stays In progress until
every witness and the outstanding design work have their required evidence.
