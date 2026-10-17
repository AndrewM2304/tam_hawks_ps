# M01 skating implementation notes

Owner: A04 Gameplay. Source: `game/player/skater.gd`. Godot 4.6.3.

## Current loop

- Hold W / up / left stick forward to push to 15 metres per second; S / down / stick backward brakes. A/D or left stick steers at rest and in motion. Coasting gradually slows the board.
- Space / Cross ollies with 0.10-second coyote time and 0.12-second input buffering. Flat launch is 8.8 m/s with 22 m/s² gravity, giving approximately 0.8 seconds in the air before collision tolerances.
- J / Square performs one Kickflip per airborne period, worth 300 base points. K / Circle performs one Melon Grab per airborne period, worth 250. Ollies award 100 base points. Main owns banking, repetition degradation, and multipliers.
- Q/E / L1/R1 holds a cosmetic aerial spin. A net 180 degrees earns 200 base points, with a 20-degree landing tolerance. Larger net rotations name the corresponding 360/540/etc. Spin score emits before landing so it joins the same combo. Aerial steering controls travel independently of these cosmetic spins.
- Flat and ramp landings are forgiving: all contacted skateable floors land cleanly, regardless of unfinished visual rotation. Falling below Y -8 or escaping the world guard bounds bails and respawns. M02 should add intentional bail rules rather than silently changing this contract.
- Original procedural board/rider meshes include a teal hoodie, orange cap, bent stance, grip surface, trucks, four wheels, visible board flip, grab crouch, slope pitch, and steering lean.
- Chase camera has exponential smoothing, a small speed-based field-of-view change, and a collision ray to shorten its distance near walls.

## Boundaries and further work

This is the M01 movement slice. Grinds, manuals, reverts, animation blending, grounded push animation, late-trick failure windows, and camera shoulder controls remain future work. The grab uses a readable crouch pose; articulated hand-to-board animation is not yet implemented. The movement and camera constants need human playtesting before acceptance as a fun skating loop. DualSense mapping requires a physical controller, and macOS performance needs the target hardware.

Ground movement projects travel onto the current floor tangent; ordinary static collision ramps should remain within the 56-degree floor limit. Leaving a ramp carries its upward motion into the air. Visual slope pitch is separate from the upright collision capsule.

## Verification

`godot --headless --path . --script game/player/skater.gd --check-only` passed with Godot 4.6.3 on the Linux cloud machine. Independent QE owns the integrated movement/trick test results. The orchestrator records final `tools/check.sh` and frame capture evidence in `docs/STATUS.md`; this note does not certify controller feel or hardware support.
