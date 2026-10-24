# ADR-014: Directional trick vocabulary and connected execution

Accepted implementation contract, 23 October 2026. The owner's current direction
is to continue trick fidelity with polished trick sets and combinations inspired
by classic arcade skating. This supersedes the one-flip/one-grab-per-jump limits
in ADR-006. Original content, current map, Godot 4.6.3 and existing bindings remain.

## Delivery and ownership

Root integrates the player/Main, interfaces and handoff; catalog/input, scoring/UI,
articulation and independent QE own separate files. Existing M02-001/003/004/006/007,
M05-002 and M06-003/007 track this work. No paid dependency or upstream asset is
introduced. Reuse review remains in SKATING_REUSE; original helpers extend the
existing Godot controller rather than replacing its validated physics.

## Input, actions and presentation

- A cardinal/diagonal direction plus the existing flip, grab or grind action selects
  its catalog definition. Neutral keeps Kickflip, Melon Grab and Rail Grind. A
  0.18-second recent-direction memory supports a flick followed by a trick press.
  Launch clears old ground direction memory; opposite axes cancel. Nose Manual
  requires a deliberate recent north direction edge, so sustained pushing alone
  does not change manual type. All prompts respect remapping.
- Flips have authored roll/yaw/pitch, duration and a 0.06-second catch cooldown.
  Another fresh press after completion can execute another flip in the same air
  segment. Holding or rapid presses cannot repeatedly award an entry. A flip and
  grab pressed together execute in order: the grab waits for the flip's catch.
- Grabs have distinct hand/board targets and posture. A tap has a short minimum
  readable pose; holding sustains the grab. Release and re-grab can add entries
  with ordinary repetition decay. A new flip releases an existing grab.
- Each rail attachment selects a real grind/slide identity with corresponding
  board yaw/pitch and rider counter-rotation. Signed rail motion, clearance,
  balance, cooldown and authored rail-ID encounter signals remain authoritative.
- A fresh manual press within 0.18 seconds before actual touchdown is buffered
  only while still held. Old held input, release, reset, disabled controls and run
  expiry cannot create a new manual entry. Nose/tail manuals use opposite board
  pitch and balance posture. Reverts keep the original non-extending bank deadline.
- Completed air half-turns and reverts toggle visible regular/switch stance while
  retaining forgiving travel heading. An unfinished flip below 80% of its authored
  motion bails on ground contact. Near-complete flips receive a catch tolerance;
  rail capture waits until that tolerance. Spin alone remains forgiving.
- Specials retain career unlock/meter ownership, once-per-air eligibility and
  original names. Conflicting active flip/grab execution rejects a special before
  meter consumption. Pause freezes all action and input-memory timers.

## Scoring and lifetime

Legacy two-argument trick signals and ScoreSession.add_trick remain supported.
The player sets last_trick_id synchronously before emitting; Main supplies it as
the optional stable repetition identity. Styling a label or changing stance does
not turn the same trick into a new multiplier. The existing distinct-identity
multiplier cap (8), repeat decay, integer saturation, 0.35-second bank window and
3-second overtime remain.
World-authored gaps retain their distinct fixed-name identities through the
legacy score call; changing a skater's displayed stance cannot create variety.

Held grabs and grinds add 25 base points each quarter-second after a quarter-second
grace: first addition at 0.50 seconds. They add no multiplier, history entry,
fresh-trick event or deadline extension. Grabs share a 300-point budget for the
entire air segment, including re-grabs; grinds cap at 300 per real attachment.
Manual balance holds do not award duration points in this implementation.
Score receipts preserve the banked trick list, entry count, latest effective award,
repetition feedback and dropped value for truthful HUD/results feedback.

## Acceptance and limits

Catalog/input/scoring checks cover all variants, malformed metadata, diagonal and
opposite inputs, memory expiry, stable identity and bounded holds. Independent
real-input tests cover ordered aerial actions, fresh repeated flips, held-button
nonfarming, late-flip bail, landing-buffered manuals, rail styles and lifecycle
boundaries. Existing career/route/encounter regressions remain. Run tools/check.sh
after source freeze; inspect actual rendered trick/guide frames and source-bound
capture receipts. Record exact commands/counts in STATUS.

The aggregate uses Godot's `--fixed-fps 60`, matching the project's 60 Hz physics.
Each scripted physics/process observation advances one logical frame rather than
allowing CPU contention to pack catch-up physics between button-edge samples.
Actual collision and all exact route/connection/score assertions remain enabled.
Production timing is unchanged; this test mode measures no hardware frame rate.

Linux automated checks and authored inspection cameras cannot certify Mac,
DualSense comfort, animation in continuous human play or parity with a commercial
game. Transition/vert/lip/wallride tickets remain separate physical systems; this
contract does not claim those mechanics from trick names or cosmetic rotations.
