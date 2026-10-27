# C03 / PT24-28 — Pogo connected-body transient

Existing grab repair is preserved. A separate included Pogo manual branch still
solves nose-palm reach by translating only `TorsoRig`, leaving `hips_origin`
unchanged. The later shared fixed-length leg correction preserves that relative
displacement. Actual skin/bind sampling detects the resulting visible opening;
healthy limb lengths alone miss it.

The immutable old visual is exact Git b257b5682bdd40310660cc4be8b40ba20717ee7f
`game/player/skater_visual.gd`, SHA256
`f0e3f3287dacff041cdf3b82a6f7ce8629025472822870ee923c470f9d0dbde7`.
The isolated old controller differs from current `skater.gd` only in that visual
preload; old AuthenticPose/Classic test copies only redirect those control
preloads. `.local/prepare_pogo_legacy.py` records exact source/target hashes.

## Retained evidence so far

- `.local/pogo-attachment-before`: initial <1 second native diagnostic enters Pogo
  directly from neutral and finds311.8mm garment-centre /259.8mm torso-pelvis gap
  in both deck stances. This is explicitly a declared pose-control sequence, not
  a claim that the real controller permits entering Pogo without a Manual.
- `.local/pogo-attachment-old-rejected`: stronger causal check begins through40
  settled ordinary Manual calls. **13/6**, exit1, unchanged622inputs,2.355s.
  Actual native geometry controls peak233.426mm cloth-centre /182.250mm joint gap
  (regular) and233.398/182.218mm (reversed). Both actual mapped Push→Manual→Down/
  Grab trials also expose attachment failures during hold/release or bail/get-up.
  Other finite limbs, exact450-point Pogo event, settled palm/sole contacts and
  normal recovery checks pass. This is an expected rejected old-source control.
- `.local/pogo-attachment-focused`: first minimal candidate shared the original
  loop delta with pelvis unchanged. **185/4**, exit1, unchanged622inputs,5.813s.
  Cloth/joint improve to60.890/4.000mm, but existing unchanged AuthenticPose
  continuity fails: knee marker movement274.6mm exceeds220mm. Both this newly
  detected failure and exact rejected candidate/test/runner bytes are retained.
  It is not admitted as a fix.

## Revised bounded correction

Pogo's existing five-iteration two-arm reach solver blends its correction on
every iteration. At initial influence~0.234 this can accumulate~0.737 of full
reach while actual palms blend once by0.234. Sharing that path exposes abrupt
pelvis/knee movement. Solve the same finite reach at full strength with the
original five iterations,0.5 averaging and0.565m reach, then multiply the total
translation once by existing `_pogo_blend` and move torso/pelvis together.
This matches the grab policy. Full settled reach is unchanged. No new persistent
state, pose clamp, limb/bind/asset/physics/score/camera/input/default change,
render resource, native query or allocation is introduced. Existing thresholds
and AuthenticPose tests remain unchanged. Deferred skitch is untouched; its
similar loop is only a source observation, not a claimed reproduced/fixed defect.

## Final focused admission

`.local/pogo-attachment-once-blended`: **189/0**, exit0, clean/stable622inputs,
5.712657s. Manifest SHA256
`f867d0344d034b3dd012d6e06c7fb3f9feaa8d3af195813c044b6577ac0270f1`.
19 new Pogo assertions plus170 unchanged AuthenticPose assertions. Both deck
yaws peak60.890mm real garment-centre separation and4.000mm torso/pelvis gap,
consistent with neutral mesh construction and breathing. Native marker maximum
210.799mm stays below the existing unchanged220mm limit; maximum actual limb
ratio1.000001. Settled sole error<=0.0012mm and palm error<=0.0026mm. Both mapped
controller trials enter Pogo with exactly its450-point event, then pass normal
release or real bail/get-up and restart. No score/controller/asset change.
The root combined suite still needs to admit the integrated source; this focused
receipt alone is not a complete game/hardware/rendering acceptance claim.
