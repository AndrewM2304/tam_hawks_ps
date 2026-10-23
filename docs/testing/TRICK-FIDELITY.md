# Trick-fidelity verification

23 October 2026. Source contract: [ADR-014](../architecture/decisions/ADR-014-trick-fidelity.md).
Delivery ownership and acceptance: [implementation plan](../planning/TRICK-FIDELITY.md).

Final evidence: **1,489 checks / 0 failures**, `./tools/check.sh` exit 0;
[suite/source receipt](logs/trick-fidelity-source.json),
[36 actual frames / 63 capture checks](screenshots/trick-fidelity/README.md),
and [four-phase cold-source launch](source-launch-trick-fidelity/README.md).
All declared runtime/test inputs match the checkout after verification.

## Implemented behavior

The catalog contains 33 validated definitions: eight flips, eight grabs, nine
grinds/slides, two manuals, plus launch/spin/revert/special/gap events. Existing
movement bindings select directions; neutral preserves the original tricks.
The in-game Trick Guide derives its directory directly from the catalog and
uses remapped keyboard/controller labels.

| Direction | Flip | Grab | Grind/slide |
|---|---|---|---|
| Neutral / west | Kickflip | Melon Grab | Rail Grind neutral; Lipslide west |
| North | Hardflip | Nose Grab | Nosegrind |
| South | Pop Shove-it | Tail Grab | 5-0 Grind |
| East | Heelflip | Indy Grab | Boardslide |
| North-west | Varial Kickflip | Mute Grab | Crooked Grind |
| North-east | Inward Heelflip | Japan Grab | Overcrook Grind |
| South-west | 360 Flip | Method Grab | Smith Grind |
| South-east | Varial Heelflip | Stalefish Grab | Feeble Grind |

A fresh north cue plus Manual selects Nose Manual; a long-held push does not.
Flips last 0.30–0.40 seconds with a 0.06-second catch cooldown, allowing two basic
flips in a normal flat ollie. An additional fresh input is required; holding or
pressing during an incomplete flip cannot farm awards. A simultaneous grab waits
for the flip to recover. Held grabs and grinds add 25 base points per quarter
second after a quarter-second grace, capped at 300 per air segment/attachment.
Hold additions create no new multiplier, entry, challenge event or bank extension.

Completed half-turns and reverts change regular/switch stance independently of
travel. Board yaw persists after shove tricks; shoe contacts cancel deck yaw so
the catch does not swap feet. Subsequent grabs/manuals preserve the same stance.
An unfinished flip below 80% completion bails on actual contact; ordinary spin
headings remain forgiving. A fresh held manual input during the last 0.18 seconds
of airtime can link at real touchdown; an early hold or canceled press cannot.

## Independent checks and regression strategy

- `tests/trick_input_tests.gd`: cardinal/diagonal thresholds, conflicting axes,
  flick expiry, deliberate direction age, launch memory and real registered actions.
- `tests/trick_catalog_tests.gd`: defensive copies, complete directional mappings,
  eligible families, malformed pose metadata and retained legacy definitions.
- `tests/trick_score_tests.gd`: stable repetition identity, hold arithmetic,
  overflow bounds, bank/drop receipts, deadline ownership, HUD and guide navigation.
- `tests/trick_pose_tests.gd`: actual palm/deck and shoe/deck contacts, arm reach,
  flip separation/catch, odd-yaw continuity, rail support, reset and later poses.
- `tests/trick_fidelity_tests.gd`: production input/physics sequences, flat repeated
  flips, ordered flip/grab, bounded grab/grind holds, late-flip bail, stance,
  canceled/stale/buffered manuals, rail entry, pause/disabled/overtime/reset.
- `tests/trick_encounter_tests.gd`: new shove/slide/manual families retain existing
  side-challenge state, eligibility and completion rules.
- Existing takeoff, manual/revert, rail, exact combo, career route, camera, world,
  encounter, audio, save, input-profile and UI suites remain in `tools/check.sh`.

Original exact air/manual/air and six district combo assertions are retained;
tests must not accept early banking or weaken actual support/return/frustum
requirements. New duration scoring must be independently accounted for in an
encounter's earned score rather than replacing an exact assertion with a loose
positive-value check.

## Reproduction and evidence boundary

Run `./tools/check.sh` for the aggregate and
`python3 tools/source_launch_smoke.py` for cache-free source startup.
The aggregate uses `--fixed-fps 60` for deterministic input-driver stepping,
matching production's 60 Hz physics. Without it, multiple real-time catch-up
steps can occur between the driver's physics/process observations under load.
This is simulated Linux integration, with every physical/connection assertion
retained; it does not establish rendering performance or human input comfort.
An independent 30-observation probe with a deliberate 40 ms process workload
confirmed 2–8 physics steps between ordinary process observations under load,
versus exactly one for all 30 observations with fixed FPS. The
[probe source](logs/trick-cadence-probe.gd.txt),
[ordinary trace](logs/trick-cadence-realtime.log) and
[fixed trace](logs/trick-cadence-fixed.log) preserve the actual mechanism.
Copy the probe text to a `.gd` file beneath `.local` and run it with
`./tools/run.sh --headless --script PATH`, then the same command with
`--fixed-fps 60`. The injected delay is a diagnostic workload, not game behavior.
`./tools/trick_fidelity_capture.sh --private-display` creates actual gameplay
frames and authored close inspection views, validates PNG CRC/rows and records
SHA-256 fingerprints for all runtime/test inputs. A source change or failed
assertion prevents promotion of its evidence set. Profile writes are disabled.

Current command outcomes, logs and manifest identities belong in STATUS and the
capture README after final verification. The initial aggregate exposed a missing
input-registration precondition in the new runner integration; registering actions
before live input checks corrects the fixture. Independent review also found and
corrected remembered opposing directions, a 0.492 m shove-catch shoe discontinuity,
and missing new-family recognition in side challenges. These are real discovered
defects, not passing claims for earlier source.

Rendered review also exposed truncated instructional paragraphs inherited from
the generic label's ellipsis style. The guide/directory and bank receipt now
wrap without trimming. UI checks measure multi-line layout, visible line count,
allocated text height and scroll reach at 960×600 with 1.4× interface size.

Three existing long-rail fixtures intentionally keep forward held at capture,
so their expected entry is now Nosegrind. Cat/Exchange/yard checks reconstruct
the exact earned bank from real stable-ID entry awards, repeat decay and capped
hold signals. They preserve actual capture, uninterrupted links, zero bails and
single banking. A delayed-input cat reproduction found the old direct return
hit the real C plinth's east face at `(14.289,4.023,-91.118)`. Its return now
clears the north corridor with actual input; the same distance/frustum/dancing
checks and 240-frame bound remain. The focused delayed return passes at 9.66 m
after 78 frames with the full 3.20-second payoff, no free score and zero bails.

Linux/Compatibility software rendering establishes bounded local behavior.
Physical Mac/DualSense timing, human play, final character/environment art and
Apple Silicon performance remain open. Older downloaded native packages do not
contain this implementation; use the current source launcher until exports are
refreshed and identified separately.
