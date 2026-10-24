# ADR-015: Complete skating process and surface coverage

Accepted 24 October 2026 (Europe/London), following the owner's explicit overnight
instruction to implement all previously identified mechanics and polish the
existing level without stopping for routine feedback. This supersedes ADR-014
where the decisions below differ. No paid dependency, copied franchise content,
new district, hosted CI or publication is authorized or required.

## Ownership and integration

Root owns Skater, Main, visual/HUD integration and durable handoff. Specialists
own transition helper/feature; wall helper; world surface audit/dressing; score/
meter; catalog/input language; and independent tests/captures. Files are disjoint.
Existing M01-003/004/005, M02-001–012, M03-013/014, M05-001/002 and M06-003/007
track this work. The latest user instruction authorizes revising underused
existing areas and promoting tested transitions/wallrides into optional lines.

## Controls and actions

- Hold Ollie to crouch/prepare and accelerate; release to pop. Short tap preserves
  the existing 8.8 m/s minimum impulse so existing city routes remain reachable;
  charge over .45 seconds increases the vertical impulse up to 11 m/s. No charge
  is manufactured by pause/reset/overtime. Buffered release/coyote stays bounded.
- Direction at takeoff selects nollie (north), boneless (south), or no-comply
  (south plus manual). Other input launches an ollie. Existing bindings remain.
- Timed direction/button histories support manual gestures, original special
  sequences, double-tap flip upgrades and one short queued action. Queues are
  bounded/expiring and reset or disabled when the run cannot admit new entries.
- Spins determine landing alignment and functional stance. Complete half-turns
  preserve trajectory but change facing/signed travel; sideways residual rotation
  over 45 degrees bails. Switch/fakie/nollie presentation follows actual state;
  automatic transition return adjustments never award player spin.
- Ground braking plus steering supports a deliberate powerslide/quick turn.
- Fresh directional flip/grab presses while grinding select another authored
  style after a cooldown, scoring a real new trick entry. Directional ollie-off
  adds a bounded lateral pop while preserving rail tangent momentum. Manuals
  support deliberate extensions/pivots with cooldown and continuing balance.

## Surface movement

Native collision remains authoritative. Transition features share visible and
collision vertices through a full 90-degree quarter-pipe, with a deck and safe
bypass. A separate ride helper handles support-relative collision, tangent
gravity, low-speed rollback, real lip departure, associated air, descending
re-entry and bounded lip balance. It must restore the ordinary capsule on exit,
reset and bail; analytic surface knowledge cannot keep the rider attached to
missing geometry. Actual contact/clearance and energy traces are acceptance.

Wallrides require a real substantial vertical solid wall, eligible speed/angle
and held Grind. They have a finite duration, momentum loss, a recapture cooldown,
native obstruction checks and an intentional outward/upward wallie exit.
Transparent surfaces, water, thin unsafe props and containment boundaries receive
explicit exclusions. A wallride label without verified motion is not completion.

Every plausible low ledge/coping candidate gets a grind path or a documented
reason for exclusion. A post-build audit reports eligible walls, playable ledges,
authored rails and exclusions. Purposeful feature clusters fill unused existing
park/quay space; keep approach/landing corridors and career/encounter paths clear.
Do not scatter clutter solely to increase object count.

## Combo and special economy

Each accepted trick entry increases the multiplier, capped at 100 for bounded
arithmetic. Repeat decay persists for the run across bank and bail; Restart
clears it. Spin adds an effective rotation bonus without inventing a new entry.
Hold points retain their caps and never increase entry count or extend deadlines.
The .35-second landing grace and three-second maximum overtime remain explicit;
real manuals, rails and air maintain the line. Reverts cannot extend the timer.

Accepted effective trick points fill the special meter during a line. Full meter
activates a maintained special state; accepted specials do not empty the meter.
The state drains over time and is refreshed by further tricks. Bail/reset clear
it; pause freezes it. Main owns unlocks and refuses invalid requests before any
meter effect. This is original arcade tuning, not a claim of identical THPS math.

## Validation and stopping boundary

Each specialist supplies focused meaningful checks. Root integrates, then runs
the full fixed-step suite without weakening physical route/connection/camera
assertions. Changed score expectations must be reconstructed independently from
accepted entry/hold/spin events. Capture real actions and the updated places.
Record actual results and remaining defects; Linux cannot certify Mac/DualSense
feel or Apple Silicon performance. Continue until complete or the active session
ends, saving exact resumable state. A bounded overnight continuation must read
the lease/status first and avoid simultaneous edits with an active session.
