# Actual wall crouch and Ollie frames — 27 October 2026

Four native 960×640 frames pass with zero failures, exit0 and a clean log. The
[outer receipt](native/receipt.json) binds628 unchanged inputs,20.6645s and
source manifest `a9505cac79cc61778db9026ae98a208ba51b38b4627411f46be230db396f85cd`.
The [inner manifest](captures/manifest.json) records every PNG hash, completed
render/physics frame, actual/interpolated vertex metric, camera and counter.
QE inspected all four real PNGs and verified their hashes after archiving.

| Actual input pose | Before board clearance | After board clearance | After shoe clearance |
| --- | ---: | ---: | ---: |
| Held crouch,12 native ticks | −124.320mm | 8.000mm | 139.652mm |
| Released Ollie,5 native ticks | −91.447mm | 40.873mm | 165.148mm |

The two controllers have identical native positions, velocities, headings and
contact ticks at each matched pose. The actual crouch actor is
`(0.000000395,0.011666665,−0.383179933)` at rest. In the air witness it is
`(0.000000395,0.648906589,−0.383179933)` with velocity `(0,6.486562729,0)`.
The repair moves the connected visual; it does not change native motion.
The before shoes already clear this particular wall. These frames establish
board intrusion and repair, with preserved finite shoe clearance, rather than
claiming that both shoes visibly penetrated in these exact captured poses.

The before controller is the exact Git `b257b56` source; the after controller is
current. BOTH use the same current rig, assets, native ServiceGate and declared
20m native/display floor. Each actor has one declared initial placement and
heading, then actual mapped Push until native gate contact, Brake20, neutral2,
held Ollie12, followed by release and five native ticks. No actor pose, velocity,
trick flag or animation value is assigned after initial placement. Processing
freezes only at each completed native pose for matched `frame_post_draw`
readback; it resumes between crouch and air. The cameras and shutter remain
fixed across variants. The scripts retain the complete method and source maps.

- [Before crouch](captures/before-crouch.png), [after crouch](captures/after-crouch.png).
- [Before air](captures/before-air.png), [after air](captures/after-air.png).

These are bounded static causal controls in a small native fixture. Frame
counters are snapshots, not comparative frame-time admission, Mac performance,
full-map or moving-shadow proof. They do not certify every arm/body wall pose,
active flips/grabs/manuals, actual controller feel or final realistic art.

Repeat from the repository root:

```sh
python3 docs/testing/pt24-pose-finish-2026-10-27/wall/observers/prepare_capture.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/wall-ollie-native-repeat bash .local/wall_ollie_capture.sh
```

[Exact capture source reconstruction](capture-source-map.json) verifies608
unchanged Git-parent blobs and retains20 exact changed-input snapshots for all628
outer inputs. The captured controller-menu test was revised later; its original
bytes are preserved rather than substituting the final test. Wall controller,
visual and contact-test code match their captured bytes.

The preparer verifies the retained immutable controller against its exact Git
object and stages the exact observers. The retained wrapper has Git head
`b257b56`, the development parent; its source maps bind the checked candidate
bytes rather than claiming the parent commit itself contains the repair.
