# Actual skinned body attachment witnesses

25 October 2026. Independent QE for the owner's report that the torso detaches
from the legs and stays on the ground after tricks/bails while skating.

The actual defect was reproduced before the production repair: a real mapped
Melon Grab left the skinned jacket approximately **668mm** from the trouser
waist during 180 subsequent Push observations. The global torso/pelvis joint
was **614mm** apart. Ordinary neutral geometry started at **51.071mm** between
the overlapping garment ring centres and **3.998mm** between those joints.
The old code continued applying a full torso-only palm-reach displacement for
an asymptotically decaying grab influence, including a measured **5.76e−10**.

The visual owner repaired the shared pelvis/torso displacement in
`skater_visual.gd`; no controller lifecycle, skin/bind, physics, rendering resource
or reset changes were needed. Fully active palm-reach solving is retained; its
displacement follows the actual influence and moves the common pelvis too.

## Independent geometry and negative control

`tests/skater_body_attachment_tests.gd` reads the real garment mesh vertex,
bone-index and weight arrays, resolves each actual Skin bind to the native
Skeleton bone, and reconstructs vertices using bone global pose × bind pose.
It observes jacket hem, trouser waist/thigh attachment and collar geometry.
It also transforms all **47 actual anatomical head neck-boundary vertices**;
head/control-node positions alone do not establish attachment.

An isolated negative control changes only the jacket's torso Skin bind. The
drawn garment metric becomes **850.814mm** while the node/global-bone joint
metric stays unchanged. This proves the test detects a skin/bind failure that
existing healthy-node and fixed-limb-length tests could miss. The original bind
is restored immediately.

The native actor runs through Push → Ollie → mapped Melon Grab → release →
180 Push observations, and through grab → bail → repeated bail/recovery requests
→ fall/slide/get-up/ready → Push. Further checks cover a real post-grab Kickflip,
an actual uncorrected manual-balance failure and recovery, and explicit restart
during a fall. Only initial native fixtures and explicit public lifecycle calls
are supplied; actor pose/velocity, animation timers and scores are not corrected
per tick. A 300m flat fixture keeps these long transitions away from unrelated
edge-fall recovery.

Separate visual fixtures settle actual Melon and Method grab states for 90
animation updates, reaching influence **1.0**. These pose fixtures validate cloth
and anatomy, not gameplay admission or scoring. Existing full Authentic Pose,
Trick Pose and Bail Recovery suites independently retain palm, Boned-extension,
sole-contact, limb-length and recovery behavior.

## Measured before/after

| Observation | Previous source | Repaired source |
| --- | ---: | ---: |
| Partial/active actual grab, hem/waist centres | 399.669mm | 61.893mm |
| Post-grab Push, hem/waist centres | 668.386mm | 64.634mm |
| Post-grab Push, global torso/pelvis joint | 614.186mm | 25.318mm |
| Post-bail Push, hem/waist centres | 668.389mm | 64.553mm |
| Post-bail Push, global torso/pelvis joint | 614.188mm | 25.318mm |
| Fully settled Melon / Method hem/waist centres | Not captured in the first baseline | 62.220 / 62.385mm |
| Fully settled Melon / Method global joint | Not captured in the first baseline | 33.000 / 33.000mm |
| Fully settled anatomical neck/collar connection | Not captured in the first baseline | ≤23.927mm |
| Restart → Push, hem/waist / global joint | Not captured in the first baseline | 57.967 / 25.261mm |

Normal post-grab Push uses **80mm** garment-centre and **60mm** global-joint
limits, tightened against the observed neutral/pushing envelope rather than a
12cm ordinary-body allowance. Anatomical neck/collar distance remains below
50mm. Full/partial grab states retain their explicit 120mm envelope.

A folded bail intentionally rotates the jacket around the pelvis while the
pelvis moves 80mm fore/aft. Ring-centre distance reaches approximately **121.35mm**
without a detached surface. Its test therefore measures real deformed jacket
hem vertices against the actual skinned trouser-waist triangles, retaining the
centroid value as a diagnostic. Maximum nearest-surface gap is **6.878mm** through
the real manual failure and **7.355mm** through interrupted grab recovery, within
the 50mm surface-connection limit; joint distance stays below 100mm. Ordinary
Push limits remain tighter. No production change was made to satisfy a
centroid-only assumption.

## Receipts and scope

The source-bound baseline `.local/skater_body_attachment_before.log` is **8/2**:
both real after-grab attachment assertions fail. An initial test-only inferred
bool parse error is separately retained at
`.local/skater_body_attachment_parse-rejected.log`.

The first expanded after run, `.local/skater_body_attachment_after.log`, is
rejected: **283/4**, plus a test helper incorrectly reading controller-only
state from a Node3D visual fixture. That leaked fixture floor also contaminated
two later absent-ground controls. The corrected helper disposes its fixtures;
those unchanged ground controls now pass. This receipt also rejected the
unjustified 120mm folded ring-centre cutoff rather than silently accepting it.

The corrected focused run is **290 passed / 0 failed**, exit zero, clean:
`.local/skater_body_attachment_after-corrected.log`. It includes **18 new
attachment assertions** and the complete existing Authentic Pose, Trick Pose
and Bail Recovery suites.

```sh
timeout 100s ./tools/run.sh --headless --fixed-fps 60 --script .local/skater_body_attachment_focused.gd
```

Frozen source SHA-256:

- `skater_visual.gd`: `f0e3f3287dacff041cdf3b82a6f7ce8629025472822870ee923c470f9d0dbde7`
- `skater_body_attachment_tests.gd`: `05a17c715246b66c33bd8e823f53b75891ec00852ac5eb3e3e15c20b5cc738b9`

Samples run after native physics and normal process callbacks, using current
and interpolated-root transforms; project physics interpolation is enabled.
These are reconstructed real mesh vertices from native bone/bind data, not GPU
readback or a claim that separate bone interpolation has been visually accepted.
Root owns bounded real-skin before/after captures, full combined regression and
portable receipt copies. Actual Mac/DualSense and owner visual confirmation
remain open.
