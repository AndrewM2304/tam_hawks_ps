# Specific free Flip arm / live shutter follow-up

Read-only preparation while root runs the required pre-push check. No engine,
scanned edits, commits or candidate pose assignments have occurred.

## Observed defect and causal scope

The real native frame
`docs/testing/pt24-continuous-2026-10-27/wall/captures/flip/after-flip.png`
shows the near-side sleeve crossing the shutter while board/shoes clear.
Active-wall owner confirmed its current native schedule and face: ServiceGate
north face Z=-.09, normal(0,0,-1); actor after6Flip ticks at approximately
(0,.949471,-.383180), shared visual offset(0,0,-.132320). That face datum is
an explicit diagnostic fixture, not proposed production memory.

`SkaterVisual.animate` currently chooses the ungripped elbow from
`_joint(shoulder, hand, .30, .29, Vector3(side*.65,-.10,.55))`. It has the actual
hand/shoulder in rider space and fixed lengths, but no ordinary obstacle face.
Its `wall_local` comes from `state.wall_normal`, supplied by the WallRide object;
this is not a fresh ordinary wall contact. `Skater._place_obstacle_wheels`
finishes after rig animation. Its airborne Flip branch proves only finite
board and shoe clearance; it retains an offset and armed plain-Ollie bool,
not a remembered wall plane. The late-Grab helper obtains a live same-RID
finite face but is not run for this Flip. A pose correction cannot reuse a
known test plane or a stale WallRide normal.

## Minimal conditional correction

First establish whether the fixed shoulder and wrist are clear and the sleeve
intrusion is caused by the present elbow pole. If so, the smallest candidate is
one ungripped-arm two-bone solve with the same shoulder, wrist and .30/.29 lengths,
using the authenticated outward face normal projected onto the elbow-circle
plane to select a nonintersecting elbow. This changes arm bones/orientation only;
torso, pelvis, legs, board, shared root, capsule, input and score remain unchanged.
The initial candidate should keep wrist position unchanged. It must be admitted
against the actual deformed sleeve and hand envelope, not joint centres alone.

Qualification must use a fresh native finite same-collider face at the actual
sleeve/hand envelope or a proved conservative startup-cached envelope. A
shoulder→wrist centreline ray is insufficient. No expanded full-body framework
or production per-frame whole-mesh scan is proposed. Scope is the already armed
plain-Ollie, active ungripped Flip; ordinary clear skating adds no queries.
Current target budgets/query count require a concrete envelope choice after the
native diagnostic, before any production implementation.

If the fixed shoulder/torso is itself inside the solid, an elbow-only correction
cannot repair it. If the wrist also penetrates, retracting that ungripped arm is
an explicitly larger second candidate, not permission to break a real palm grip.
Such results must be reported before changing scope. Existing18cm root limit
stays intact. Genuine Grab/Boneless/Pogo/tow/handplant grips and residual grip
blends must bypass this free-arm correction. No mesh hiding or limb scaling.

## Prepared diagnostic and later admission

`.local/active_wall_arm_probe.gd` reconstructs the exact current-controller
ServiceGate native workload: initial spawn only,10settle,Push(.55) to real panel
collision,Brake20,neutral2,heldOllie20,release2,then freshFlip held6 with90 native
updates through catch/landing. It never changes actor poses, velocity, trick
flags, garments or bones after construction.

Each sampled arm records actual sleeve vertices deformed with native Skin binds
and Skeleton global poses, actual normalized GripCurl anatomical hand vertices,
shoulder/elbow/wrist signed distances, .30/.29 chain lengths, and fresh native
same-panel rays at the worst sleeve/hand envelope points. It also retains physical
body/velocity, shared root, board/rider, nonarm bone poses and actual cloth/neck
samples. Negative clearance remains a defect, not a healthy-state pass.

Pending root's post-push serial engine lease:

```
python3 docs/testing/horizon-background/observers/run_checked.py \
  .local/active-wall-arm-before timeout 15s ./tools/run.sh --headless \
  --audio-driver Dummy --fixed-fps 60 --script .local/active_wall_arm_probe.gd
```

No diagnostic has run yet. A later candidate must preserve exact physical/
score parity, all non-target bones/root/board/shoes, current cloth/limb/marker
limits and genuine Grab palms, reject absent/moved/short/edge-face cases, then
supply a matched native frame of this actual Flip and root's required checks.
