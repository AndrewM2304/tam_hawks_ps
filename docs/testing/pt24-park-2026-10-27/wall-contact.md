# Connected presentation at ordinary wall contact

27 October 2026, C03 follow-up discovered by the actual service-gate input
witness. Source work remains on main from `c82ffac`; no physics, input, scoring,
Music or normal world-content gate changes.

## Defect and repair

The upright native locomotion capsule has radius 0.28m, while the existing
0.835m board and the posed shoes extend beyond it. The closed gate stops the
capsule correctly, but the ordinary pose previously had no finite wall fit.
The installed-gate adverse input found a shoe behind the shutter's north face;
the isolated native negative control also measures over 12cm of actual
board/shoe penetration. This is a contact presentation defect, separate from
the previously repaired grab/torso attachment cause.

`Skater._place_obstacle_wheels` runs after rig/contact animation. For ordinary
neutral native grounded flat-floor skating, it uses actual near-vertical native
slide-contact planes and cached real board support/sole vertices. It translates
the **whole connected presentation** horizontally, with 8mm contact skin and a
strict 0.18m total correction ceiling. Feet, board, torso and garment pose stay
together; physical transform, velocity, capsule, locomotion and score are not
modified. Current contact planes are checked again after sequential corner
corrections.

Every proposed offset must retain four finite wheel-centre supports on the
original flat plane, within 1mm, and pass the existing finite board box query.
Unsupported edges, a secondary obstruction and an oversized correction refuse
the fit. Air, manuals, flips/grabs/specials, transitions, wallrides, bails,
setups, skitching, lips, crouches and powerslides retain their own behavior.

The separate offset decays with the existing 45ms presentation timescale after
release. A real capsule rebound can lose wall contact while its longer deck
still needs clearance: if the decay proposal is blocked, the previous safe
offset is tried **after revalidating it**. Clearing it immediately would snap
the figure through the retained shutter. Restart and begin-bail clear stale
offset state. No historical rail-release offset is reused.

## Focused results

[Final receipt/log/exact source](focused/wall-presentation-final/) records
**21 passed / 0 failed**, exit zero, clean log, 609 unchanged inputs, 3.20572949s.
Manifest SHA256:
`a232e876bea2b4fdaa48bf21f5e57b4a6ef706a73124c299547c6c2e1cf8a174`.

```sh
python3 docs/testing/horizon-background/observers/run_checked.py \
  .local/wall-presentation-final timeout 40s ./tools/run.sh \
  --headless --audio-driver Dummy --fixed-fps 60 \
  --script .local/wall_presentation_focused.gd
```

Two real native Skaters receive the same mapped Push input; the control differs
only by omitting this presentation helper. Their bodies cannot collide with each
other. Independently measured actual board and shoe mesh vertices give:

| Witness | Previous presentation | Repaired presentation |
| --- | --- | --- |
| 141 blocked native-contact samples | Minimum gap −126.125630mm | All 141 fitted; minimum gap +8.000020mm; maximum shift 134.125635mm |
| First impact → Brake 20 ticks → idle 20 ticks | Intermediate decay defect reaches −121.542271mm | Minimum gap +8.000020mm; final retained shift 129.542mm |

Physical transform, velocity, floor state/normal and capsule remain identical
between the two actors throughout the declared inputs. Local board/rider poses
also remain identical; the correction is a single parent translation. Controls
cover repeated solves without drift, eight excluded states, the 18cm ceiling,
finite rear-wheel support loss, a secondary obstruction beyond the rear axle,
release with the wall retained, decay after the wall actually moves away,
actual begin-bail, and actual restart.

Retained development history:

- [First parser rejection](focused/wall-presentation-first/): a test-only dynamic
  `previous` variable needed an explicit float type; own engine was stopped.
  Source-stable, no assertion count; no gameplay result claimed.
- [Initial fit](focused/wall-presentation-second/): 17/0. It lacked the immediate
  first-impact release witness and is not acceptance of that case.
- [Long-held Push then release](focused/wall-presentation-held-release/): 18/0.
  Settling against the wall before release did not reproduce capsule rebound.
- [Immediate first-impact release rejection](focused/wall-presentation-first-release-before/):
  18/1, actual −121.542271mm penetration, unchanged physics. This exposed the
  unsafe clear-offset-on-decay-rejection behavior.
- [Validated fallback](focused/wall-presentation-first-release-after/): 19/0;
  final 21/0 adds the two explicit lifecycle controls without production changes.

Every directory retains its exact observer/test/controller snapshot, checked
against the recorded before-source hashes. Original logs and failures remain.

## Cost and acceptance limits

No new meshes, materials, bodies, shapes, textures, hull construction or rendering
work is introduced. Ordinary clear skating exits before candidate queries. A
nonzero wall/release candidate uses at most four support rays and the existing
board query; an obstructed decay may validate the previous candidate too, for a
strict maximum of **eight rays plus two reused box queries**. This is a bounded
work count, not measured target-Mac timing.

Native matched rendered frames and installed ordinary-Main gate/camera results
are recorded separately by integration. These focused controls do not certify
active trick/manual wall poses, arbitrary garment/hand clearance at unrelated
obstacles, actual Mac motion/performance, physical controls or human feel. The
earlier complete-body attachment repair and its negative controls remain intact.
