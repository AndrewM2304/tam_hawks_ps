# Native manual-meter investigation — rejected capture

The immutable source run saves six original 1280×800 native frames. Independent
decoding verifies all six PNGs against their native RGBA8 hashes and all three
current Canvas synchronization swatches. All 787 source/observer/wrapper inputs
are unchanged. See [the independent review](independent-review.json), exact
[observer](observer.gd.txt), [wrapper](wrapper.py.txt) and [original receipt](receipt.json).

**The whole capture remains rejected.** Although capture assertions report 32/0,
the inherited `_snapshot` helper accesses `transition_ride.state`, which does not
exist, and treats its Dictionary feature as a Node. The engine logs three script
errors and the resulting state dictionaries are empty. Read-only `git show
HEAD:tools/full_fidelity_capture.gd` confirms this bug already exists at baseline
`0b62035`, before the new push instrumentation. Motion owns the narrow helper
correction and actual Main snapshot smoke. The retained epoch is never rewritten
or upgraded after that fix.

The exact originals still establish the negative visual finding **FID-D011/P1**:

- [UI scale 1.4](manual-ui-1.4.png): the panel occupies
  `(490.67, 164.27, 298.67, 256.36)` and crosses the rendered upper head. The head
  centre is at `(675.05, 421.86)`, only 1.23 px below its bottom; a centre-only
  overlap test misses the visible silhouette interference.
- [UI scale 1.0](manual-ui-1.0.png): the large, mostly empty central panel obscures
  the forward approach and architecture. Its full source text is
  `MANUAL\nW FORWARD  /  S BACK`; both frames render only `MANUAL...` and omit the
  correction lines. Lower general W/S help remains visible, but does not restore
  the missing meter label.
- [Actual release](manual-release.png): the active meter clears; this narrow
  observation cannot accept the preceding presentation.

The probe reaches a supported manual using actual default-spawn push and manual
input, then changes the normal user-facing UI scale without persistence. No
trajectory, balance, score, pose or gameplay state is assigned after startup.
This is a static chase investigation, not a normal-speed reel or a target-device
performance result. The combo engineer owns compact placement outside the rider
and landing corridor, readable axis/risk/prompts, resolution/remap checks and a
clean source/pixel-proven native retest.
