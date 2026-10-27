# Pogo connected-body entry and release

**C03 / PT24-28 · A04 · P0 · M01/M05.** Depends on the existing real Skin/bind,
fixed-length limb and controller/contact contracts. The ordinary Pogo manual
still moved only the torso toward its nose-palm contacts. Actual clothed entry
could open233mm between jacket/waist centres and182mm between torso/pelvis.
The existing fixed-length leg fit could not remove that relative displacement.

The correction solves the original bounded two-palm reach, applies its total
translation once by the actual Pogo influence, and shares it with torso and
pelvis before fitting the legs. Full settled reach, assets/binds/limb lengths,
board/sole targets, input, movement, scoring, camera and world defaults remain.
No new native query, render resource or persistent state is introduced.

[Final focused receipt](focused/admitted/receipt.json): **189 passed /0 failed**,
exit0, clean log,622 unchanged inputs,5.713s. This includes19 new attachment
assertions and170 unchanged AuthenticPose checks. Both deck stances keep actual
skinned garment centres within60.890mm and torso/pelvis within4.000mm. Marker
motion stays210.799mm, below the unchanged220mm bound. Settled sole/palm errors
are under0.003mm; original native contact and limb checks remain unchanged.
Real mapped Push→Manual→Down/Grab enters Pogo once with the catalog's450-point
award, followed by ordinary release or actual bail/get-up/restart and skating.

[Old-source causal control](focused/old-input-control/receipt.json) is deliberately
rejected13/6. The first minimal shared-delta candidate is also
[retained and rejected185/4](focused/rejected-shared-delta/receipt.json): it fixed
attachment but moved a knee274.6mm. Applying a partial reach blend on each of
five iterations had over-applied entry translation; blending the solved total
once restores original continuity. No threshold was relaxed.
[Investigation](investigation.md) includes the separate initial neutral pose
probe and its explicit controller limits. [Snapshot hashes](source-snapshots.json)
retain the exact old visual, redirected controls, test sources and rejected
candidate rather than silently replacing raw evidence.

The root batch's required combined admission and native captures are separate.
These checks do not certify the target Mac, human anatomy/feel, every historical
contracted-body photograph or deferred skitch variants. Normal merged content
remains available; Music/personal-account isolation is preserved.

Run from the repository root, with no other engine/render workload active:

```sh
cp docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/pogo_attachment_focused.gd .local/
python3 docs/testing/horizon-background/observers/run_checked.py .local/pogo-repeat timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/pogo_attachment_focused.gd
```

For the isolated old-source negative control, first run the preparation helper
from the repository root and stage the before runner; its expected assertion
failures produce exit1. The helper only redirects preloads in ignored local
copies and verifies the exact committed old visual SHA256.

```sh
python3 docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/prepare_pogo_legacy.py
cp docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/pogo_attachment_before_focused.gd .local/
python3 docs/testing/horizon-background/observers/run_checked.py .local/pogo-old-repeat timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/pogo_attachment_before_focused.gd
```

[Four actual native frames](captures/manifest.json) compare both deck stances at
exactly one Pogo entry call after40 ordinary-Manual calls, selected by the old
source's peak opening. [Before](captures/before-regular-entry.png) and
[after](captures/after-regular-entry.png) show the repaired relative placement;
all four PNGs were inspected. The completed frame has233.17→51.27mm garment-centre
separation and182.25→3.96mm torso/pelvis separation. The physical actor is fixed
and automatic controller processing is disabled. These are declared static
causal poses using real native Skaters, meshes and Skin binds, supported by the
separate mapped-input tests; they are not ordinary gameplay motion or final-art
acceptance. The legacy controller shares current controller source with only its
visual preload redirected. Its old visual is immutable; the new hull key is
accessed lazily only by the inactive wall fit, so no compatibility adapter or
new collision state is used for these poses.

[Capture wrapper](capture-validation/receipt.json): exit0, clean log,628 unchanged
inputs,12.392s. All four frames are960×800 and report86 draws/60,700 primitives,
with22,675,745 texture bytes. Video bytes rise from30,956,161 on the first actor
to30,974,217 and remain there as actors are recreated; this is a sequential
static resource snapshot, not a target-Mac memory/frame-time benchmark. The
[exact changed-input snapshots](capture-source-map.json) and immutable local
controls are retained. Unchanged bytes resolve from the recorded Git parent.
The capture source includes the wall agent's retained hull pointer; Pogo pose
logic is identical to focused admission, and required integration remains root's.

Repeat the graphical control only when a visible change or unresolved evidence
justifies it; stage its shell and GDScript observers into `.local`, prepare the
legacy controls, then run the wrapper with one graphical engine at a time:

```sh
cp docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/pogo_attachment_capture.gd .local/
cp docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/pogo_attachment_capture.sh .local/
python3 docs/testing/pt24-pose-finish-2026-10-27/pogo/observers/prepare_pogo_legacy.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/pogo-capture-repeat bash .local/pogo_attachment_capture.sh
```
