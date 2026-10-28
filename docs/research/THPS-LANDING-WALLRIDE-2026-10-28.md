# Turning landings and wallride presentation — 28 October 2026

Owner Codex research; P0 support for C03/M01/M02/M05. This responds to the
owner's report that turning an Ollie causes a bail and wallrides feel janky.
Implementation and native acceptance belong to the repair agents; this is
source research, with no engine run or imported implementation/animation.

## Source and limits

Inspected actual bodies in [LANCommander/THPS at fa128f5b](https://github.com/LANCommander/THPS/tree/fa128f5ba222e0f24a9bff019d59262b79141e48).
This is a community reconstruction of THPS1 PlayStation, not verified THPS3
source or measured THPS3 feel. Its own matching tables list the air, wallride,
spin and helpers below as matched; ground physics remains a near-match. Those
matching claims were read, not independently checked against retail bytes.
[Exact file hashes and matching rows](THPS-LANDING-WALLRIDE-SOURCES-2026-10-28.json)
bind this inspection to the pinned revision.

The complete 2,493-entry Git tree has no licence-named paths, consistent with
the [existing licence review](SKATING_REUSE.md). No compatible permission to
copy this implementation was found. It supplies behavioural evidence only;
no source, character, animation, level, audio or binary is bundled. Existing
MIT component reuse remains governed by [ADR-004](../architecture/decisions/ADR-004-selective-reuse.md).

## Findings that matter to these fixes

| Inspected function | Supported behaviour | Application and boundary |
| --- | --- | --- |
| [DoInAirPhysics](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/doinair.cpp) | Ordinary spin updates orientation and accumulated rotation while carried velocity advances flight. Landing projects velocity into the contacted plane. | Keep airborne momentum separate from visual rotation. The owner's requested continuation in the turned direction is an explicit local landing choice, not proof that an airborne spin bends the reference trajectory. |
| [DoOnGroundPhysics](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/doonground.cpp) | Ground turning calls `RotateHeadingAndVelocity`; the support frame follows terrain, and lateral velocity is removed. | Resolve a successful landing into one consistent board heading, signed travel and actual support tangent. Preserve collision-adjusted speed and the existing grounded motion rules. This function is a reported near-match. |
| [HandleBailPerpendicular](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/handlebailperpendicular.cpp) | A sufficient in-plane speed and nearly sideways front/velocity relationship can trigger a bail. | **The reconstruction does not establish that every 90-degree landing succeeds.** Separate a deliberate ordinary steering turn from an unfinished scored spin; implement the owner's requested forgiveness explicitly. Raw thresholds are not Godot units. |
| [HandleBailOnLanding](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/unnamed/80031108.c) and [80035f30](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/unnamed/80035f30.c) | Other landing gates inspect trick/animation fields, signed rotation fields and up-vector/contact-normal alignment. Many field meanings remain unnamed. | Landing completion, upright support and lateral heading are distinct concerns. Keep meaningful incomplete-flip, upside-down and real-impact failures; do not translate unknown fields into alleged THPS3 windows. |
| [Trick_Land](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/trickland.cpp) | Counts the landing, scores accumulated half-turns, refreshes feedback and clears trick bookkeeping. | Score once after a physical landing succeeds. This score routine supplies no physical landing-angle tolerance. |
| [DoInAirPhysics wall entry](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/doinair.cpp) | After collision/approach/state gates, projects front and velocity into the wall plane, sets up to the wall normal, rebuilds the frame and invokes `FlipToVelocity`. Chooses animation 35 or 36 using travel relative to world-up cross wall-normal and a stance flag. | Wallride presentation needs mirrored side/stance choices and a coherent wall frame, with the actual contacted wall controlling admission. A universal same-sided lean is unsupported. The helper can flip heading; it does not describe a smooth universal apex turn. |
| [DoWallRidePhysics](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/dowallride.cpp) | Advances motion, follows the fall line, sweeps forward and probes toward the wall. Gravity is projected into its plane. Skateable floor contact transitions to ground and projects heading/velocity into that support. | Continue to authenticate finite native contact. Pose smoothing cannot create support through a gap or restore momentum removed by an obstruction. |
| [OrientToNormal](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/orienttonormal.cpp) | Blends the prior normal toward the current normal, normalizes it and reconstructs an orthogonal frame; repeated contact eventually selects the exact normal. | Supports bounded presentation blending across entry/travel/exit. Its quarter-step and repeat counter are original-frame choices, not a verified duration for our engine. Keep physical support and visual blending distinct. |
| [DoWallRidePhysics animation/exit branches](https://github.com/LANCommander/THPS/blob/fa128f5ba222e0f24a9bff019d59262b79141e48/decomp/src/physics/dowallride.cpp) | Wall animations 35/36 loop a limited frame range under an animation gate. Missing support returns to air and selects exit animation 26/27 by a state flag. | Author connected entry, sustained contact and exit poses for this rider, preserving both feet/board and torso/legs through the transition. The repository supplies animation IDs and state calls, not the skeletal clips or their exact poses. |

## Local acceptance to accompany implementation

Our existing authored wall lean is 0.65 radians (about 37 degrees). That is
shallower than the reconstruction's wall-normal frame. This repair smooths
the game's original pose and native contact approach; it does not copy a clip
or replace that authoring with an asserted THPS skeletal animation.

Use ordinary input-driven Ollie/steering landings in both directions and several
partial/full turns. Verify no false bail, intended outgoing heading, finite
support, collision-adjusted speed and once-only score. Retain explicit spin,
unfinished flip/special, real obstacle and hazard controls.

For wallrides, compare left/right entry, sustained travel, normal changes,
release, wall edge, floor and Wallie. Record adjacent drawn frames and connected
garment/feet/board transforms; check native clearance and real contact throughout.
Animation timing and human feel remain our authored choices and owner acceptance,
with no claim of copied or verified THPS3 animation. Production changes require
the repository's focused tests and full check.
