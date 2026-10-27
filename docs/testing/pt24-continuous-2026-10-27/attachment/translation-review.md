# Bounded source-only torso translation review

Reviewed only `game/player/skater_visual.gd`, SHA256
`442a9913a798ec404c99a394a107e074ba8c21ebb23d4baf4e7bb5e2554c46cb`,
while root's required combined check owns the engine/source freeze. No engine,
scanned source edits, pose-suite reruns or broad audit were performed.

No remaining unmatched **reach translation** was found before leg fitting:

- Existing grab, tow toward/reach, and Pogo translations all share their exact
  applied torso delta with `hips_origin`, refreshing `hips_y` (lines 477–541).
- Ground-drag crouch lowers pelvis/hips/upper together (680–682).
- The fixed-length foot-contact fit applies `pelvis_offset` to both pelvis and
  torso before `pose_body` and all `pose_leg` calls (695–709).
- Handplant's separate inverted solve sets `upper.transform` and `pose_body`
  from the same `hips` transform, then recomputes legs from those hips
  (1030–1055). Its blend snapshots/restores upper, feet, hands and every native
  skeleton bone together (1076–1102); it is not a torso-only override.
- `begin_bail` clears handplant and cached tow influence. Remaining fade paths
  use the same shared grab/Pogo translations above. `reset` clears pose weights
  then calls complete neutral `animate(0.0, ...)` immediately (134–186,203–209).

The initial authored torso/pelvis offset is deliberate and bounded: the lean
uses 100% torso/70% pelvis of a maximum 11cm grab lean (at most 3.3cm relative),
plus small push/brake lateral shift (2.5/1.8cm), 4mm breathing, and the existing
8cm bail hip-back pose. These are distinct from an unshared iterative reach
solver. This source review alone does not newly certify all combinations or
motion/human acceptance and provides no evidence requiring their alteration.

No additional probe is warranted by this bounded finding. Native skin/bind
and interruption evidence remains in the existing focused/full checks.
