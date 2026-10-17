# ADR-006: Trick states, input and combo continuation contract

Status: Accepted engineering specification for M02-001; tuning and controller feel remain provisional until physical QA. Date: 17 October 2026. Owners: A01/A04 with A08/A09 review through integration. No M01/M02 human acceptance is implied.

## Context and reuse decision

The existing controller supports ground/air movement and basic tricks. `main.gd` banks immediately on clean landing; a held flip/grab is already edge-gated, and score repetition halves value down to a sixteenth. The adopted `GrindLine` provides world-space rail geometry but does not own input, movement, balance or scoring. M02 needs explicit boundaries before rails, manuals and reverts can join combos.

Read the inspected sources and pinned revisions in [SKATING_REUSE](../../research/SKATING_REUSE.md): 3deric's state separation and input buffer, Not Pro Skater's signed rail travel and combo grace, and their documented compatibility/correctness caveats. Use built-in Godot input, `CharacterBody3D` and the already adopted rail helper. The catalog and contracts here are original project work informed by those inspections; they contain no copied upstream implementation. The existing rail helper remains an attributed MIT adaptation. Do not import an entire controller or its assets merely to obtain a small timing/state pattern.

Alternatives considered: preserving immediate landing-bank forever would prevent the requested manual/revert combo links; copying an upstream 0.5-second grace and whole controller would introduce unrelated tuning and coupling. Choose an explicit 0.35-second future landing window and keep its implementation separate from the first grind integration.

## State ownership and transition table

The player owns movement state and verifies physical/input guards. The session owns scoring, pending combo resolution, run timeout and results. The catalog's `can_transition` checks structural permission only: it cannot prove floor contact, rail clearance, input freshness or meter availability. Same-state updates do not produce transition awards. Unknown states/IDs always reject.

| From | Allowed destination | Required runtime guard / effect |
|---|---|---|
| `ground` | `air` | Fresh/buffered eligible ollie, or actual loss of support. Walking off a ledge does not award Ollie. |
| `ground` | `manual` | Fresh manual action, enough forward speed, stable floor support, balance initialised. |
| `ground` | `revert` | Fresh revert action within the eligible landing window; one revert per landing. Ordinary ground travel cannot enter it. |
| `ground` | `bail` | Confirmed hazard or invalid position; emit bail once and drop only unbanked points. |
| `air` | `ground` | Actual clean support transition; resolve spin once, then emit landing once. |
| `air` | `grind` | Grind held, valid nearby rail, angle/height/speed checks, clear snap path and reacquisition cooldown passed. |
| `air` | `bail` | Confirmed unsafe/hazard outcome; current forgiving heading-only landings remain until a tested rule replaces them. |
| `grind` | `air` | Ollie-off, released input or rail endpoint without floor support; preserve signed tangent momentum. |
| `grind` | `ground` | Release/end with real floor support; landing/score resolution occurs once. |
| `grind` | `bail` | Failed balance, obstructed travel or hazard; clear rail reference and emit one bail. |
| `manual` | `ground` | Release, insufficient speed or clean balance resolution; end manual once. |
| `manual` | `air` | Eligible ollie or loss of support; preserve motion and active combo eligibility. |
| `manual` | `bail` | Balance failure or hazard; emit one bail. |
| `revert` | `ground` | Revert animation/timing finishes with support. |
| `revert` | `manual` | Eligible manual input within the same original landing window. |
| `revert` | `air` | Eligible ollie or actual loss of support. |
| `revert` | `bail` | Hazard or physically invalid transition. |
| `bail` | `ground` | Recovery/reset completes at a safe supported location; clear transient trick/rail state. |

No ground-to-grind snap, air-to-manual, grind-to-manual or manual-to-revert shortcut is implicit. Those paths must pass the listed support transitions, with the guards checked on each transition. A restart is an explicit out-of-band reset of the whole player/session, not a scored transition. Pause freezes all timers/state updates. Controls disabled by results prevent all new action transitions.

## Input contract

| Action | Keyboard | DualSense candidate | Semantics / rollout |
|---|---|---|---|
| Ollie | Space | Cross | Fresh press; existing short buffer/coyote behaviour stays. |
| Flip / grab | J / K | Square / Circle | Fresh press while eligible in air; one execution per actual press. |
| Spin | Q / E | L1 / R1 | Held rotational intent; award completed half-turns once on ground landing or successful rail capture. |
| Grind | L | R2 positive trigger axis | Hold to request eligible capture and sustain grind. R2 is not the digital Triangle button. Initial M02-002 implementation. |
| Manual | M | L2 positive trigger axis | Candidate: fresh press enters a supported manual; holding sustains it. Future M02-003. |
| Revert | C | Right-stick press | Candidate: fresh press in landing window; cannot restart the window. Future M02-004. |
| Restart | R | Triangle | Preserved. Grind must not consume or rebind it. |
| Pause / free skate | Escape / F | Options / touchpad | Preserved session actions. |

Use the existing standard Godot/SDL gamepad mapping and action deadzones. Trigger threshold, manual/revert ergonomics and deliberate versus accidental actuation need real wired/Bluetooth DualSense tests. These controls are an engineering candidate, not a claim of owner-approved final feel. Do not activate manual/revert actions before their mechanics and tests exist. No global 0.5-second trick input queue is introduced now; preserve the tested ollie buffer and add only explicitly tested contextual buffers later.

## Trick data and repeat rules

`game/tricks/trick_catalog.gd` exposes immutable-by-copy lookup data and structural guards. Each record has a stable lowercase ID, display name, positive integer base points, allowed states and activation event. `definition(id)` returns a deep copy or `{}` for an unknown ID; `base_points` returns zero for unknown IDs. `can_perform` checks structural eligibility only and does not enable an unimplemented mechanic. `validate_definitions` reports malformed types/fields, duplicate IDs/states, unknown states/activation events and invalid point bounds without executing game events.

| ID | Base points | Award event |
|---|---:|---|
| `ollie` | 100 | Actual eligible launch, not every airborne frame |
| `kickflip` | 300 | One accepted fresh air action |
| `melon_grab` | 250 | One accepted fresh air action |
| `spin_180` | 200 per completed half-turn | One ground/rail contact resolution; retain direction/rotation in visible label |
| `rail_grind` | 200 | One successful rail entry |
| `manual` | 100 | One successful manual entry; future |
| `revert` | 150 | One successful revert entry; future |
| `special_clyde_carousel` | 1000 | Eligible special press with meter consumption; future |
| `special_tenement_tumble` | 1200 | Eligible special press with meter consumption; future |
| `named_gap` | 500 default | One validated authored traversal; future per-gap data |

Special names/values are original provisional content definitions, not implemented animations or unlocks. Gap records will provide unique gap IDs and authored values. The generic catalog entry is a schema baseline, not permission to award every trigger crossing. Completed spin half-turns currently use a dynamic display label and multiplied base value; do not silently change existing score semantics during a catalog migration.

A repeat's points are `max(1, floor(base / 2^min(previous_repeats, 4)))`. Non-positive base values produce zero, and negative repeat counts clamp to zero. Unique trick count multiplies accumulated base, capped at 8. Current `score_session.gd` keys repetitions by display name; a future M02-005 migration to stable IDs must preserve reference scores and document spin/gap identity rules. The catalog helper matches today's numeric degradation but does not automatically replace the session's implementation.

Grind entry awards once per attachment. First integration has no time-based hold points; holding a button must never call `add_trick` every frame. Later hold scoring must introduce a separately tested duration cap and cannot inflate the unique-trick multiplier by emitting synthetic names. Same-rail cooldown and fresh physical capture guard against immediate repeat entry exploits. Manual/revert repeated input cannot manufacture transitions or extend landing grace.

## Landing continuation and bounded run timeout

**Current integration boundary:** the first playable grind retains immediate clean-landing banking. `LANDING_LINK_SECONDS = 0.35` is a specification constant for M02-004/M02-005, not an enabled timing change. Do not mark continuous combo acceptance complete merely because the constant and rail state exist.

The future rule starts a single 0.35-second pending bank on a clean landing with an active combo. A valid manual, revert-to-manual or supported launch within that original window can continue the combo. A revert alone does not refresh or extend the deadline. Clean ground travel after expiry banks exactly once; a bail before resolution drops the pending combo. Restart clears it. Pausing freezes it. Empty combos do not create pending windows.

At 120 seconds the session stops admitting new trick/rail/manual/revert entries. An already active combo may resolve for at most **3.0 seconds** of active-play overtime; pause freezes this timer. No accepted event can extend the deadline. During overtime the player can release a hold and physically finish a landing but cannot start a fresh scoring link. Clean resolution banks once. Bail or an unresolved combo at the hard deadline drops unbanked points and enters results. Timeout and landing in the same physics tick must resolve in a defined order and never double-bank. Main now bounds air/rail landing grace at 3.0 seconds and disables fresh trick/capture inputs during it. Manual eligibility and pending landing banks remain M02-004/M02-005 work.

## Validation and consequences

A09 must validate all records, lookup-copy isolation, unknown IDs/states, illegal transitions, repeat boundaries, existing point compatibility and future timing constants. Runtime integration checks additionally cover fresh input edges, signed rail directions, capture clearance, endpoints, same-rail cooldown, bail/reset, pause and timeout. Structural guards must not replace those checks.

Use a controller playtest to tune acquisition and the proposed 0.35-second link window after manuals/reverts exist. Keep M01/M02 human gates open until that evidence arrives. This ADR adds no paid dependency, copied implementation, asset or background service. It gives subsequent sessions a stable definition while keeping actual enabled features and scoring ownership explicit.
