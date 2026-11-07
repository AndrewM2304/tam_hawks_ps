# Independent manual controls: actual world-sign evidence

7 November 2026 UTC. **85 checks / 0 failures, engine exit 0, clean log, 785 unchanged input hashes, 24.85 seconds elapsed.** [Receipt](receipt.json), exact [before](source-before.json)/[after](source-after.json), [source-copy identity](source-copy.json), [log](engine.log), [independent tests](independent-tests.gd.txt), [observer](observer.gd.txt).

This is an immutable copy of the dirty November candidate, not a clean commit or final integrated-game pass. A separate stable before/after copy inventory proves the copied source matched its live input epoch. Exact game/assets/tests/tool hashes are authoritative. Cached imports were copied; no import or graphical engine was launched in this native diagnostic. Original main remains `0b62035`; copied changes include new fore/aft manuals and the rider/level improvements then present.

The verifier wrote these tests independently of the control implementation. They do **not** reuse its analytic sign formula. Real W/S inputs are compared with actual world-space board nose/tail endpoint heights, signed by real native travel. The same suite checks authoritative displayed balance, speed loss, heading and separate A/D turning.

Ten actual-input cases pass: ordinary Manual, Nose Manual, each after a real ollie/native landing/Revert into fakie, Pogo, Casper, Manual Pivot, Nose Manual Pivot, Hang Ten and One-foot Nose Manual. Every case resets only at its boundary, then accelerates through real pushing and selects its pose with mapped inputs. No velocity, balance, heading, pose or score is assigned during a run. Fakie comes from actual landing/Revert, not a negative-speed fixture.

In every case W lowers the travel-leading deck end and moves effective balance forward; S raises that end and moves balance backward. Both lose the same **0.074844 m/s per six ticks** to ordinary coasting: forward correction adds no acceleration, backward correction does not silently brake, and neither turns. A/D independently turn opposite ways while the manual stays supported/live. Near-vertical Pogo and inverted Casper are checked in actual drawn orientation.

This passes bounded physical-direction/steering-isolation parts of FID-304 C/D at this epoch. Landing-buffer/score timing, complete HUD/remap/accessibility, normal-speed animation/contact, owner usability, final combined source and Mac/controller gates remain separate.

Run `fidelity_acceptance_tests.gd.run(tree, game, check)` from scripted ordinary Main with persistence disabled. Its optional observer uses the established `(phase, game, step)` capture interface for later rendered review. Root must wire the independent suite into the combined runner and retest final changes.
