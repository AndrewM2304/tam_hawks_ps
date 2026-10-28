# Steering landings and wallride transitions — 28 October 2026

This implements the [owner's clarified left/right steering report](../../planning/OWNER-TURN-WALLRIDE-2026-10-28.md).
The baseline is main `21b0e86`. The earlier 5,746/0 whole-project result belongs
to the preceding gameplay source; it does not certify this new repair.

## Behaviour

Ordinary airborne steering retains its separately earned rotation until actual
native floor contact. A successful landing commits that complete steering
heading and redirects only the signed, collision-adjusted ground speed into the
new floor tangent. Airborne momentum is unchanged. Spin scoring still counts
the actual total rotation once; only explicit shoulder half-turns change the
spin/fakie stance. A steering turn cannot cancel the completion requirement for
an unfinished shoulder spin. Restart, bail, new flight and scored captures clear
the prior steering contribution.

Wallride presentation eases from the actual pre-trick support frame into the
existing mirrored lean. The nearest native tyre gap approaches its existing
15mm bearing over a bounded number of frames; a candidate intrusion is pushed
out immediately. Physical wall probes, capsule motion, eligibility, duration,
entry reach and obstruction response remain unchanged. An early wall release or
Wallie retains only the last drawn world translation and decays it at the existing
4.5 m/s presentation rate. It applies only in ordinary, non-ramp air after fresh
board and both-shoe endpoint clearance, at most three existing native queries per
pending update. No wall plane or physical motion is reused. New flight, landing,
reset, bail, new wall capture and competing modes clear the handoff.

A successful native wall capture also clears the departed ramp-air tag and return
context. It preserves the actual incoming support basis, so the wall blend starts
from the figure that was drawn instead of an obsolete ramp apex pose.

The [actual pinned THPS source review](../../research/THPS-LANDING-WALLRIDE-2026-10-28.md)
supports distinct air momentum, grounded travel, mirrored wall states and normal
alignment. The community reconstruction also contains sideways landing bails.
The requested ordinary steering continuation is our explicit gameplay choice.
No reconstructed implementation or animation clip was imported; the existing
approximately 37-degree wall lean is our authored pose.

## Retained focused evidence

| Epoch | Result | Meaning |
| --- | --- | --- |
| [First parser](parser-first-rejected/receipt.json) | Rejected; exit0 but script errors,676 stable inputs | A new test declaration needed an explicit bool type. The clean-log check correctly refused admission. |
| [Corrected parser](parser-current/receipt.json) | Pass,1.406s,676 stable inputs | Corrected test parses without script errors. |
| [First native cohort](focused-first-rejected/receipt.json) | **193/8**,17.701s,676 stable inputs | All steering and original shoulder controls pass. Eight wall-entry marker checks expose a250–500mm positional snap despite bounded rotation. |
| [Second parser](parser-final/receipt.json) | Pass,1.457s,676 stable inputs | Includes bounded positive-gap approach. |
| [Second native cohort](focused-final/receipt.json) | **203/0**, 17.597 s, 676 stable inputs | Twelve mirrored 45/90/135/159/161/180-degree ordinary steering landings, mixed-input/late-flip/reset/blocked-rollout controls, original native walls, eight mirrored wall presentation cases, weighted Ollies and actual Main shoulder quarter/180/360 controls pass. Early wall exits remain a subsequent distinct check. |
| [Early-exit parser](early-wall-parser-01/receipt.json) | Pass, 0.803 s, 678 stable inputs | Adds early release/Wallie controls after normal editor import generated the new test UIDs. |
| [First early-exit cohort](early-wall-first-rejected/receipt.json) | **134/8 rejected**, 18.996 s, 678 stable inputs | Four early five-tick exits expose about 352 mm marker travel; four raw quaternion small-angle checks also fail. The exact source, raw quaternion metrics and basis witnesses remain retained. |
| [Corrected early-exit parser](early-wall-parser-02/receipt.json) | Pass, 0.905 s, 678 stable inputs | Includes earned residual handoff, actual ramp-to-wall ownership clearing and the independent matrix angle metric. |
| [Corrected wall cohort](early-wall-corrected/receipt.json) | **153/0**, 19.850 s, 678 stable inputs | All 13 cases pass, including mirrored early release/Wallie, genuine native wall takeover from a declared ramp-flight fixture, native contact and connected presentation. |

These receipts retain their exact source maps and non-parent snapshots. The
second cohort records zero airborne XZ velocity or physical heading change in
the steering cases, one landing each and preserved native landing speed about
8.954m/s. Steered159/161-degree headings remain continuous across the scoring
threshold while points correctly change from100 to300. Original explicit
shoulder quarter-turn refusal and completed180/360 travel/stance rules pass.

The second wall cohort retains220mm marker and native skin/attachment bounds;
observed maximum marker movement is below178mm. Tyres reach the15mm bearing
after two or four updates for the tested650/900mm body entry distances, with no
penetration. All cloth-joint, fixed-limb, planted-shoe and once-only event checks
pass in those held-ride and later-exit cases.

The corrected wall cohort separately binds manifest
`41863b2cef50b99cdaa9a336ce4efe177959baccb1c9ccf4bb78be9ae59628ff`
to its exact 678 inputs. It is not an additive extension of 203/0. Early-exit
marker travel is now 83–130 mm; the overall maximum is 177.361 mm, within the
unchanged 220 mm limit. Minimum actual tyre gap is 14.99994 mm; all tested rides
settle by the fourth update, at most 15.000075 mm from the wall. Shoe grip error
is below 0.856 mm and actual garment joint gap below 0.220 mm.

The independent small-angle metric uses `atan2` from the relative basis matrix,
keeping the original **0.075001 rad** step bound. Its maximum is **0.075000572 rad**.
The raw quaternion maximum **0.075003333 rad** and exact before/after basis pairs
remain recorded; they are not deleted or reclassified as a production pose change.
This addresses small-angle quaternion cancellation without enlarging the bound.

## Complete required check and cold source launch

Repair source **`40a6615d0c1837594a7e65fa73876d2ced08db11`** is pushed to main.
The [complete required check](required-01/receipt.json) runs `./tools/check.sh`
and passes **5,888/0** in **638.089 s**, exit0 with clean logs and **677 unchanged
source inputs**. The actual short-script launch separately passes Music isolation
**2/0**, as retained in its console log. All 677 inputs match exact committed
blobs at the receipt's `40a6615` head; no non-parent source snapshots are needed.
Before/after maps share SHA-256
`5a22e2a7ca8e3beb64df27043e75856c80e55f7a64e7660ab2abf323a1dd800c`.
This is the whole-project result for the repair, distinct from focused epochs.

The [cold observer](cold-01/receipt.json) passes in **56.457 s**, clean/stable on
the same 677-input manifest and head. The [four-phase cold source record](cold-source/SOURCE-LAUNCH.json)
retains **583 unchanged copied-source inputs**: cache-free import/launch, ordinary
title→play **50/0**, warm launch and correct refusal of deliberately invalid
copied source. The invalid control's exit1 and parser messages are expected and
retained; the normal source is restored and unchanged. All eight original import/
launch logs are retained with their hashes. These headless fixed-clock checks
certify source launch and mapped gameplay, not target frame rate or Mac execution.

## Original rendered evidence and handoff

The [separate final native capture](captures/README.md) passes **8/0** in
**32.300 s** on **680 unchanged inputs**, with eight original960×640 PNGs retained
and inspected. Mirrored wall-entry pairs use the unedited preceding controller
and the repaired controller with identical current rig/assets; native body
position, velocity and yaw match exactly in both46-sample pairs. Repaired early
release/Wallie and both left/right turned rollouts retain one connected rider.
All eight completed-draw/interpolation witnesses and separate strict chase
frustum/occlusion/sphere controls pass. The capture's plain fixtures and fixed
clock do not certify whole-city art, moving target performance or human feel.
Its earlier parser/native rejections remain separate and unchanged.

Fresh unsigned Linux/universal-Mac packages are in progress. Older exports retain
their recorded source and do not contain this repair. Ordinary merged content
stays enabled and personal Music stays isolated. Actual Mac execution, physical
controls, effective Music Automation/TCC, saves/audio, target performance, final
art and human feel remain open. No release, upload or hosted CI is implied.
