# Steering landings and wallride continuity — 28 October 2026

Continue on main from `21b0e86`. The owner reports that an Ollie followed by a
left/right steering turn bails on landing, and that wallrides feel abrupt.
Their input clarification explicitly identifies ordinary steering, rather than
the shoulder spin buttons. These C03 defects take priority over further polish.

| Task | Owner | Priority / milestone | Dependencies | Acceptance and verification |
| --- | --- | --- | --- | --- |
| TURN-01: steering landing | Landing agent; root integrates | P0 / M01, M02, M06 | Native landing, weighted Ollie, existing spin/stance/scoring contracts | Real left/right input during a normal Ollie lands cleanly and continues in the chosen direction. Preserve contact-adjusted speed, ballistic air momentum, collision response and once-only scoring. No heading discontinuity at a spin-award threshold. Explicit shoulder spins, unfinished flip/special and genuine obstruction/hazard guards retain their own rules. Verify mirrored native-input cases, slopes/collision negatives and existing spin controls. |
| WALL-01: wallride presentation | Wall agent; root integrates | P1 / M02, M05, M06 | Actual wall support, connected rig and finite model clearance | Replace the immediate approximately37-degree entry tilt with a bounded transition from the actual support pose. Verify mirrored entry, travel, release and wallie continuity; retain genuine native contact, finite endpoints, capsule motion, planted-wheel fitting and body attachment. Inspect original rendered frames. |
| TURN-WALL-QE: combined handoff | Root plus independent capture/reference agent | P0 / M06, M07 | TURN-01, WALL-01 | Focused native assertions, current-source full `tools/check.sh`, cold launch and source-bound original captures. Record failures honestly. Commit and non-force push main with `[skip ci]`; keep normal trial content enabled and personal Music isolated. |

The [pinned source review](../research/THPS-LANDING-WALLRIDE-2026-10-28.md)
distinguishes the community THPS1 reconstruction from verified THPS3 behaviour.
Its sideways-landing bail is not evidence that the reported steering bail should
be retained. Its mirrored wallride states and support alignment provide design
guidance; no reconstructed code or game animation assets are imported.

Agents own disjoint production files. The landing agent owns `skater.gd` and
applies the wall helper's agreed integration call. The wall agent owns the wall
helper and wall-specific visual/test changes. Root grants one engine/render
workload at a time and freezes source during measured checks. No long gameplay
replay, new rendering content, hosted CI, release, spending or unattended job is
part of this repair. Mac/controller and human feel remain separate acceptance.
