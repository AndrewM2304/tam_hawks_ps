# Runtime interfaces

Updated for the integrated repertoire, connected terrain and activities in [ADR-016](decisions/ADR-016-full-fidelity-integration.md), extending [ADR-015](decisions/ADR-015-complete-skate-process.md) and [ADR-014](decisions/ADR-014-trick-fidelity.md). Godot 4.6.3, Compatibility renderer, native GDScript, one attributed MIT rail-geometry component, original world/garment geometry, CC0 cropped MakeHuman anatomical meshes, two attributed CC0 material sets, and local audio. Runtime has no network service or paid dependency. This describes enabled prototype behavior, not human acceptance, complete commercial-game parity or target-Mac certification.

Coordinates use +Y up and local -Z forward. The board-contact origin starts at `(-22, 0.8, 28)` and settles onto Y=0. Six connected, originally authored places comprise the map: Royal Exchange, George Square, Central Station, the Barras, Clyde Quays and Kelvingrove Park. Exchange gallery is 2 m above the lower fountain court; George is 4 m with a 6 m civic terrace; Central concourse 2 m with 5 m platforms; Barras loading terrace 1.5 m. The river lies south, the hilly park northwest. These are compressed game coordinates, not surveyed Glasgow street geometry. Generic player recovery catches Y below -8 or absolute X/Z above 400; the world also supplies a local safe-quay return for river falls.

## Input and profiles

`game/core/input_setup.gd` registers the following defaults with action deadzone 0.2. Gamepad events use device -1, so they accept any connected controller. Physical DualSense mapping, trigger ergonomics and wired/Bluetooth behavior remain hardware checks.

| Actions | Keyboard | Standard DualSense candidate |
|---|---|---|
| `push`, `brake` | W/up, S/down | Left stick up/down |
| `steer_left`, `steer_right` | A/left, D/right | Left stick left/right |
| `ollie`, `flip`, `grab` | Space, J, K | Cross, Square, Circle |
| `grind`, `manual` | L, M | R2, L2 |
| `revert` | C | R3 |
| `spin_left`, `spin_right` | Q, E | L1, R1 |
| `special_one`, `special_two` | U, I | D-pad up/right |
| `interact`, `goals` | X, Tab | D-pad down, Create |
| `restart`, `pause`, `free_skate` | R, Escape, F | Triangle, Options, touchpad |

Ollie is held to crouch/charge and released to pop. The first 0.12 seconds retain
the normal tap impulse; charge then rises over 0.45 seconds, reaching full at a
0.57-second hold. At release, a direction edge at most 0.18 seconds old selects
north=Nollie; south selects Boneless, or No Comply with held Manual, only on an
ordinary native floor outside rail/wall/transition support. Sustained approach
pushing does not select a setup. Boneless/No Comply require an additional real
foot-support admission before their delayed launch. These reuse existing actions
and remapping. Held inputs are synchronized across reset/entry gates; an Ollie
held through reset must release before a new deliberate charge can begin.

`game/core/input_profile.gd` owns validated overrides. `binding_snapshot()` supplies readable live bindings; `rebind(action,event)` returns `{ok,error,bindings}`; `apply_saved(bindings)` validates the complete candidate before changing InputMap; `reset_defaults()` restores defaults. Overrides contain only permitted physical key/button/axis fields. Duplicate bindings, unknown actions, unsupported axes, modifier/echo keys and weak axis capture are rejected. Analog capture requires magnitude 0.5. Keyboard and controller overrides are separate; Godot `ui_*` actions are preserved. Career settings persist accepted binding dictionaries. A controller disconnect pauses active gameplay; keyboard fallback remains available.

## Skater and presentation

`game/player/skater.gd` extends `CharacterBody3D`. Public state includes `speed`,
`airborne`, `spawn_position`, `grinding`, `grind_balance`, `manual_active`,
`manual_balance`, `revert_remaining`, `special_name`, `wallriding`,
`transition_active`, `lip_active`, `lip_balance`, `ollie_charge`, `crouching`,
`powersliding`, `takeoff_mode`, `setup_active`, `setup_id`, `setup_phase`,
`bail_active`, `bail_phase`, `recovery_fade`, `skitching`, `skitch_caught`,
`skitch_balance`, `lip_name` and `lip_trick_id`. `stance` reports REGULAR, SWITCH or FAKIE from
the functional facing/signed travel state. Signals are `grind_captured(rail_id)`,
`trick_performed(name,points)`, `trick_upgraded(name,total_points,id)`,
`hold_points_awarded(points)`, `special_requested(id)`, `landed(clean)`, `bailed()`,
`combo_link_started()` and `combo_link_ended()`.

`reset_skater(preserve_camera=false,preserve_support=false)` restores motion,
input queues, charge, stance, support helpers and transient trick/visual state,
including the cached ordinary collision transform. A normal teleport/restart
flushes Godot's cached platform support on the next real native move;
`preserve_support` is used only for a genuinely supported in-place get-up.
`recover_to(safe_position)` starts one animated bail with that finite recovery
target, then restores the original run spawn. Main uses it for river falls.
`bailed` drops pending score/gap/special state immediately once; banked score
survives while native slide/fall and the get-up or faded safe return continue.
`set_controls_enabled(false)` stops ordinary movement, setup/tow and an active manual;
`set_trick_entries_enabled(false)` clears pending input/charge and rejects new
entries while an existing physical link resolves during bounded overtime.
Pausable node processing freezes physics and visual timers. Actual landings emit
once. Player spin must finish within 45 degrees of a half-turn multiple; otherwise
landing bails. A completed half-turn commits physical heading, toggles switch
stance and recomputes signed speed while preserving travel momentum. Automatic
transition return alignment does not manufacture a player spin award.

The expanded player exposes `last_trick_id`, `flip_trick_id`, `grab_trick_id`,
`grind_trick_id`, `manual_trick_id`, `stance`, `active_trick` and `hold_points`.
`last_trick_id` is set before the existing two-argument `trick_performed` signal.
`hold_points_awarded(points)` is separate and cannot add entry/multiplier events.
Flip execution uses catalog duration plus a 0.06-second catch cooldown; fresh
presses can repeat in one actual air segment. A second/third Flip tap within
0.22 seconds of its previous tap upgrades the unfinished directional flip along
its catalog chain. All eight base flips have three stages, including 180/360/540
Shove-it. `trick_upgraded` carries the final definition's full base points. Main
replaces one provisional score entry rather than adding another. Upgrading
retains the visible current rotation in `_flip_motion_origin`, starts the new
duration and interpolates toward its remaining rotations before catch.
Simultaneous grabs queue until catch; held grabs sustain and share one 300-point
duration budget per air. One fresh double-tap Grab upgrade per active grab uses
`grab_tweak`: neutral/north=Boned, south=Tucked, east=Twisted, west=Extended
(south takes precedence in a diagonal). It preserves the original hand contact
and stable identity, adds 150 to full base value and replaces that entry.
Late flips below 80% completion and specials with over 0.15 seconds remaining bail
on landing. Rail capture also checks flip/spin eligibility. Air receipts can add
Switch/Fakie/Nollie styling; Main forwards canonical catalog names to encounter
lookups so styling does not break family recognition.

`TrickCatalog.resolve(family,direction)` returns a deep copy for neutral/cardinal/
diagonal selection; `family_ids` enumerates authored entries. `resolve_upgrade`
selects the next/explicit tap stage, `resolve_extension` selects manual/lip styles,
`grab_tweak` produces a same-ID modified grab, and `special_commands` returns a
defensive copy of the six original commands. `TrickInput.sample`
reads current remapped movement actions, with 0.5 axis threshold, immediate
opposing-axis cancellation and 0.18-second flick memory. `direction_age`
distinguishes a deliberate gesture from sustained pushing. Button history holds
at most 16 fresh edges; `pop_action(action,max_age=0.18)` consumes one eligible
edge and queued history expires after 0.45 seconds. `consume_double_tap` consumes
the second tap once, with a 0.025–0.22-second interval. `consume_manual_gesture`
recognizes north→south=Manual or south→north=Nose Manual within 0.30 seconds.
`consume_tap_upgrade(action)` returns the fresh multi-tap action record;
`consume_special` uses `TrickCatalog.SPECIAL_COMMANDS` within 0.45 seconds,
consuming that action before normal trick processing:

| Directions + action | Catalog ID |
|---|---|
| west→east + Flip | `special_clyde_carousel` |
| north→south + Grab | `special_tenement_tumble` |
| east→west + Flip | `special_kelvin_corkscrew` |
| south→north + Grab | `special_barras_butterflip` |
| north→east + Flip | `special_bridge_blender` |
| south→west + Grab | `special_sandstone_salute` |

Existing `special_one`/`special_two` shortcuts request Carousel/Tumble. Short
pre-pop commands may queue until eligible air; none score on the ground.
`clear_actions` clears intent without inventing a fresh held press;
`clear_recent` clears takeoff approach memory without a false direction edge.
`sample_frame(axes,pressed_actions,delta)` is the deterministic input seam and
uses the same edge recognition as runtime sampling.

Ground motion projects onto the current floor. Air carries collision-adjusted
horizontal velocity and rotates it by bounded steering. Ground speed uses capped
actual travel velocity to avoid artificial downhill braking. The 56° native floor
classification handles ordinary banks; the separate transition helper handles
tagged curved surfaces through 90 degrees. Brake>0.5, steering magnitude>0.6 and
ground speed>4 m/s activate a powerslide with additional turn and controlled drag.

Moving-ground carrying remains Godot `CharacterBody3D` platform motion. Signed
`speed` measures skater travel relative to support: after a move, the controller
tracks the actual native floor collider RID and whether inheritance is enabled
for the next move. Continued support subtracts the current completed move's
platform velocity, including a stop at zero; fresh reset contacts cannot subtract
carry that was never applied. Air landings convert world momentum into the newly
contacted platform frame. Helper movement discards stale inherited support until
the next real native slide; a first-snap zero normal uses an actual native floor
ray. Jump/leave inherits support momentum once;
it does not become next frame's relative push speed. The service cart's bed/cab
are current moving surfaces. Ordinary scenery collision remains authoritative.

- `set_grind_lines(lines)` snapshots world-space authored/generated tracks. Held eligible air capture uses `GrindRide`; capsule sweeps reject scenery obstruction. Direction selects one of nine ride styles. Capture resolves prior spin without a landing, retains backwards rail orientation and emits the actual rail ID once. Fresh Flip/Grab direction selects a different style after a 0.25-second cooldown, awarding one new entry. Fresh Revert produces `grind_pivot`, physically turning facing 180°, toggling backwards rail facing and retaining 85% of rail speed; it has a 0.35-second cooldown. These ten catalog grind actions share the same finite ride/hold budget. Release preserves signed tangent momentum; recapture waits 0.35 seconds. Released charged Ollie adds launch impulse and up to 4 m/s lateral pop from steering. Duration adds bounded hold points without new entries; style changes do not reset the ride's 300-point hold budget.
- Manual requires a fresh supported press, a still-held press buffered at most 0.18 seconds before landing, or a fresh recognized gesture; speed must be at least 2 m/s and exit cooldown is 0.35 seconds. Recent north selects Nose Manual; sustained pushing keeps Manual. Gesture entry latches until another Manual press, launch, loss of support or insufficient speed. Push/brake correct fore/aft balance and left/right steer. A changed extension awards one entry after a 0.35-second cooldown without resetting balance. Neutral Flip/Grab/Revert select One-foot Manual/Spacewalk/Manual Pivot; north+Flip selects One-foot Nose Manual, south+Flip Casper, horizontal+Flip/Grab Crossfoot, north+Grab Hang Ten, south+Grab Pogo, north+Revert Nose Manual Pivot. Diagonals use their north/south component. Pivots perform the physical revert. Entry emits link-start before scoring; supported exit emits link-end once. Losing support clears the manual without a false ground-end. Absolute balance 1 bails.
- Revert requires fresh grounded input within `revert_remaining` after actual air landing and is once per landing; a manual uses its separate pivot action. It awards 150, commits a physical 180° heading/stance change, retains 85% of motion and recomputes signed speed. Its visual turn lasts 0.18 seconds. It emits no continuation event and never resets the score deadline. `revert_remaining` is input eligibility, not the authoritative banking timer.
- `try_special(id) -> bool` accepts any of the six catalog specials during eligible unpaused airtime, rejecting active special/flip/grab/pending-grab, rail/manual/wall/lip/setup/tow/bail states. Catalog durations are 0.65–0.90 seconds. Main checks the definition's `required_unlock` and `special_meter.ready()` and calls `consume()` only after `true`; this does not empty the sustained meter. Completed authored body/board half-turns commit physical facing/rest-deck yaw once through the catch path. The animated collider never tumbles with the visual special.

`set_presentation_settings(sensitivity,reduced_motion)` clamps camera sensitivity to 0.5–2 and removes speed-dependent camera distance/FOV when reduced motion is enabled. `chase_camera.gd` follows actual planar travel rather than board-facing alone, retains its bearing through near-zero horizontal vert motion, and uses `get_support_normal()` for chest/head framing with a world-up horizon. Collision-volume sweeps, full-body sightlines and retained side-orbit smoothing remain active. `set_skater_color(Color)` changes the shared shirt material.

`get_support_normal()` returns the active curved helper's normal, or the native
floor normal during ordinary supported travel. The ordinary branch rejects
airtime, the forced-air departure tick, rail/wall support and bail recovery;
it also requires floor data from an actual native move, invalidated during
rail/transition helper frames. Without valid support it returns world UP.
On native floors and curved `surface` support,
the presentation composes its heading/spin yaw inside the full support plane:
pitch and cross-slope roll match the current normal without smoothing lag.
Torso action lean remains separate. The ordinary upright collision capsule
retains its native transform, which can place its origin above a steep plane.
Before solving rig contacts, an excluding-self ray against the player's floor
mask (`1 | 8`, world and cart) places the visual origin 8 mm above a real hit
whose normal agrees with the native floor normal (dot greater than 0.98).
This correction changes presentation only; curved support retains its own
physical placement. A natively supported bail uses the same full floor frame and
origin correction throughout getting up, so its final visible recovery target
matches the first ordinary supported frame. Its presentation reads the native
normal directly; the public camera getter keeps its bail guard. Setup soles/palms
still use their supplied world contacts, air catches continue over their bounded
blend, and bail begins from the visible world transforms captured before support
and trick state are cleared.

Airborne presentation reads a finite native floor ray below the flight and keeps
a continuous support frame across associated/ordinary air handoff. Its rotation
is capped at 4.5 radians/second; only ordinary near-floor presentation anticipates
the upright capsule's foot offset. Physics support, velocity, trick eligibility
and scoring remain unchanged. This prepares descending bowl catches rather than
rotating the entire visible figure only after contact. Actual all-wheel rays,
head motion relative to body travel, real griptape/sole distances, leg reach and
once-only bank regressions cover takeoff, handoff, catch and toe exit.

The presentation helpers `skater_visual.gd`/`skater_garments.gd` build an original
ten-bone `Skeleton3D` with continuous skinned jacket/trousers, structured shoes,
detailed board and analytic action poses. The CC0 cropped adult head, scalp and
five-finger hands retain their attribution; no complete MakeHuman body/program
or new asset licence is implied. `Footwear.SOLE_CONTACT=(0,-0.0605,0)` and
`TOE_CONTACT=(0,0.001,-0.115)` are actual mesh contacts (toe is local −Z).
`Anatomy.PALM_CONTACT=(0,-0.075,-0.015)` remains fixed as distal fingers curl.
The original deck's wood top/bottom and griptape use 24 concentric rings to
retain a flat stance area and curved kicks; the exposed wood border is closed.
Bolt caps finish at the actual grip triangles. Ordinary planted feet sit at
deck Z±0.220, inside the trucks at Z±0.255; world-space setup anchors retain their
existing offsets. Nose/Tail Grab targets use Y=0.039 at Z∓0.38 so their palms
contact the raised kicks instead of entering the wood.

`animate(delta,state)` consumes ordinary action/balance state, signed
`travel_sign`, setup/launch/catch parameters, full manual/grab/lip/special
definitions and world-space lip/setup/tow/recovery contacts. Definitions drive
Hang Ten, crossfoot, Pogo, Casper, Boned/Tucked/Twisted/Extended poses and the six
original specials. `setup_foot_offset()` returns physical-board-space
`(-0.34,0,-0.255)`; `boneless_grab_target()` returns deck-space `(0.128,0.022,0.02)`.
Committed rest-deck yaw is compensated when selecting the same physical foot or
grab end. The front sole plants on the supplied ray point, the Boneless right
palm meets the actual edge, and separation catches back over 0.28 seconds.

Crossfoot, Pogo and Casper transitions blend at rate 16 and reset explicitly.
The Hang Ten shift uses rate 12 with a smooth endpoint curve so its forward
torso/hand turn also releases continuously. One-foot Manual leaves the rear foot
loaded and raises the front; One-foot Nose Manual leaves the front loaded and
raises the rear. Independent lift blends plant the former free foot before the
opposite leg rises when the weighted role changes.

Hang Ten places both forward-facing shoes side by side near functional deck
Z−0.24 rather than applying a uniform offset to the ordinary stance. Its rigid
cupsoles bridge the curved kick on real heel and forefoot contacts; those
contacts may lie on the exposed wood beside the narrower griptape cap. The sole
centre can therefore sit above the concavity. A fitted support pose is cached
at loading, and a grid of actual top triangles bounds moving sole compression
to 1 mm during one-foot/Hang Ten transitions. Native balance, score and inputs
do not change. Pogo pitches the deck by 1.22 radians; its horizontal soles
meet the real functional rear-wheel crowns returned by
`pogo_foot_contact(side,rest_yaw)`, and both palms meet the authored griptape
vertices returned by `pogo_hand_target(side)` after inverse rest-yaw compensation.
Casper uses 0.35 radians of tail-bearing pitch and a half-roll: the actual front
toe supports the inverted nose while the rear sole supports the underside.
During those changing orientations the rig projects a cached native convex hull
of the rendered board, trucks and wheels against the support plane, and checks
the actual sole vertices before solving legs. A tail-only offset cannot represent
the lowest edge during the half-roll. These adjustments are presentation contact
solutions; the native manual, balance and score rules remain authoritative.

Palm lip styles solve the real coping point (two-palm Invert spreads contacts
±0.14 m along its tangent); deck and weighted axle lip styles meet their actual
bearing surfaces. Skitch uses the cart's two real bar points and normal with
reachable arms; cached tow release yields to a fresh live board grab. Root owns
whole-special Euler rotation about the 0.8 m body pivot; additional deck rotations
and the rig's tuck, Salute contact and flip separation preserve catches.

Call `begin_bail()` before clearing trick/support/presentation state. It captures
interrupted world transforms and articulated bones. During `bail_active`, the
rig uses `bail_phase`, actual `bail_ground_point`/`bail_normal` and optional local
`bail_recovery_transform` to fall, roll and get up continuously. A distant floor
ray cannot move the visual body ahead of the native falling capsule. Preserve
`SkaterVisual`, `Board`, `Rider` and `BodyCollision`; only transition support
temporarily reorients the capsule, restoring it on exit/reset. Human animation,
character-art and controller acceptance remain open.

### Setup, recovery and tow helpers

`game/player/launch_setup.gd` exposes `active`, `id`, `phase`, `ground_point`,
`normal`, `duration` and `elapsed`. `try_start(body,trick_id,foot_offset)` admits
only Boneless/No Comply on a native floor with a real sole ray, upward normal
dot at least 0.65 and ground-height difference at most 0.22 m. It retains a weak
reference/local contact on that supporting body, so a moving deck carries the
plant. Preparation lasts 0.22/0.16 seconds and caps tangent travel at 1.65 m/s.
`step(body,delta)` rechecks the same support and owns one native move while
preparing. Results are `{event:preparing|launch|unsupported,moved,...}`; the
controller performs the launch move only when `moved=false`. A failed plant
cannot award its name or boosted impulse. `reset()` clears preparation.

`game/player/bail_recovery.gd` exposes `active`, `phase`, `elapsed`,
`ground_point`, `normal` and `recovery_target`. `start(body,fallback,target=INF,
outward=ZERO)` starts one native slide/fall; `step(body,delta)` returns
`recovering` or `{event:recovered,target}`. Floor get-up progresses over 1.05
seconds; airborne phase stops at 0.45 until support, while a void/explicit hazard
return or three-second bound may select a safe target. The actual capsule must
have floor support and free standing clearance for in-place recovery. `fade()`
handles ordinary get-up versus elapsed-time hazard fade; the controller keeps
its short arrival fade active after movement controls stop. `reset()` clears
only recovery state. Native movement and visual ground rays are separate from
the immediate one-time `bailed` signal.

`game/player/skitch_ride.gd` exposes `active`, `caught`, `speed`, `balance`,
`elapsed`, `cooldown` and `travel_velocity`. Skater gates admission on held Grind
plus a fresh Interact while grounded and outside competing support states.
`try_start(body,vehicle)` requires a moving `skate_vehicles` body, matched travel
and facing, native line/sweep clearance and an anchor within 1.65 m horizontally
and 0.6 m vertically. Pending attraction has no Skitch award or hand targets;
native following must close the planar anchor gap to 0.12 m within 0.70 seconds.
Only `caught` starts one entry/link. `step(body,delta,steer=0,jump=false,held=true,
jump_impulse=8.8)` owns the native move and returns active/caught/pending,
velocity/speed/balance, launched/bailed and reason. Caught tow lasts at most six
seconds, balance magnitude 1 or obstructing impact bails, while release, stopped
vehicle, lost support or timeout ends support. Jump releases actual momentum
with the charged upward impulse and bounded lateral steering. `hand_targets()`
and `hand_normal()` expose real handle data only while caught. `stop()` starts
the 0.70-second recapture delay; `tick(delta)` advances it while inactive;
`reset()` clears it. The caller must not integrate these moves twice.

## Score and combo resolution

`game/scoring/score_session.gd` is the authoritative `RefCounted` score/deadline model. It exposes `total_score`, `combo_base`, `combo_multiplier`, `best_combo`, `last_trick`, `last_banked`, `trick_history`, `pending_landing` and `landing_remaining`.

`add_trick(name,points,identity="") -> int` adds repeat-degraded points and returns
the actual base addition after saturation. Main passes stable catalog IDs (or
`gap:<id>`); legacy callers default to name identity. Every accepted entry,
including repeats, increases the multiplier up to `MULTIPLIER_LIMIT=100`.
`add_hold_points(points)` and `add_spin_bonus(points,label="")` return actual
bonus additions to an existing combo without entries, repetition or timer changes.
Rotation text decorates the last receipt. `upgrade_last_trick(name,total_points,
identity="")` replaces only the current provisional entry, restores its old
identity's pre-entry repeat count and applies the final identity's repeat count.
It preserves holds, rotation labels, count, multiplier and deadline, returning
the signed actual base adjustment. A stale upgraded move can reduce its value;
Main earns live charge only from positive new points. `last_award` describes the
final entry value and `last_bonus` describes the latest bonus award.

`begin_landing()` opens one **0.35-second** pending bank for a nonempty combo;
duplicates cannot extend it. `continue_combo()` clears pending banking for a
valid physical link. `tick(delta)` consumes active-play time and returns a bank
exactly once. Adding a trick, including Revert, does not refresh/cancel the timer.
Bank/drop clear active entry state and the deadline, retain the appropriate
outcome receipt and keep run-long repetition;
`reset()` alone restores fresh repetition. `combo_trick_count`, `last_award`,
`last_repeat`, `last_bonus`, `last_banked_tricks` and `last_dropped_value` expose
live and outcome receipts.

Per-event values are capped at 1,000,000; base, multiplied combo and total records saturate at 2,147,483,647. Repeats halve to a sixteenth across banks and bails for the run. Entry count drives the multiplier, including repeated entries. Career records separately clamp to their save-model bound of 2,000,000,000.

Main connects link-start to `continue_combo`, link-end/clean landing to
`begin_landing`, and bail to score drop plus special reset. Physical air, rail,
manual, wallride, lip stall, actual caught skitch or admitted setup continues an existing combo. Supported transition
carving alone is ground travel and must bank. Ordinary loss of support sustains
air without inventing an Ollie award. Main routes `spin_180` to the bonus API,
not another entry. Current ordering follows [ADR-015](decisions/ADR-015-complete-skate-process.md)
and retains the bounded landing/overtime rules from [ADR-006](decisions/ADR-006-trick-state-and-input.md).

## Rail helpers and catalog

The adapted MIT `game/tricks/grind_line.gd` owns a world-space `Curve3D`. Constructor `(id,world_points,kind)` and `from_local_points(id,points,transform,kind)` snapshot geometry. `is_valid` rejects invalid/collapsed lines; `point_at(distance)` clamps endpoints; `dir_at(distance)` returns a full 3D tangent; `closest(position)` returns `{dist,point,gap}` or `{}`. Units are world metres. Rebuild after authoring transforms change. Retain its complete upstream notice.

Original `game/tricks/grind_ride.gd` owns signed progress, speed and balance. `start(lines,from,velocity,clearance)` selects an eligible clear candidate; `step(delta,balance_input)` returns `riding`, `end`, `bail` or `slow`. `position()` and `travel_velocity()` retain the release sample; `stop()` deactivates the ride. The player supplies collision sweeps, input gating and scoring. See [GRINDING](../testing/GRINDING.md) for tuning and actual authored tracks.

`game/tricks/trick_catalog.gd` provides copy-returning definitions, stable IDs,
known-state/transition guards and repeat arithmetic. Its **78 definitions** comprise
24 flip stages (eight base/double/triple chains), 8 grabs, 10 grind actions,
11 manuals, 5 launches (including Wallie), 9 lip styles, 6 original specials,
Wallride, Skitch, one rotation-bonus definition, Revert and one shared named-gap
definition. Tweaked grabs are modified copies rather than additional IDs.
Structural permission does not prove physical
eligibility, unlocks, charge or input freshness.

## Wall and curved-transition support

`game/player/wall_ride.gd` is an original `RefCounted` native-contact helper.
`try_start(body,motion)` requires real two-height vertical side contact, a capsule
entry sweep, at least 3 m/s tangent motion and a glancing approach. Skater owns
held Grind and competing-state eligibility. `is_surface_eligible(collider)`
respects inherited `no_wallride`, explicit `wallrideable` and water/glass/fabric
exclusions, falling back to substantial solid collision dimensions when untagged.
`tick(delta)` advances inactive recapture cooldown. `step(body,delta,steer=0,
jump=false,held=true)` owns one native `move_and_slide` and returns `{active,
velocity,normal,launched,bailed,reason,wall_id}`. It rechecks the retained real
wall, limits support to 1.25 seconds, loses momentum, releases at edges/slowdown
or input release, and bails on obstructing impact. Jump exits with outward/upward
Wallie velocity. `stop()` starts the 0.35-second recapture cooldown; `reset()`
clears the helper. Skater must not integrate this motion again.

`game/levels/transition_feature.gd` builds one finite 90-degree quarter-pipe from
shared visible/collision vertices, with steel coping, deck, closed sides and a
side roll-in. It registers `skate_transitions`; `surface_body` carries the
`transition_feature` reference. Author `feature_id`, `radius`, `width` and
`deck_length` before `build()`/ready; yaw and translation are supported, scale must
remain one. `local_sample(theta,lateral)` and `sample(theta,lateral)` return
`{point,normal,tangent,lateral,theta,x}` in local/world space respectively.
`surface_sample(world_point)` adds finite `in_bounds` and contact `distance`;
`get_grind_lines()` returns its world-space coping path. `advance_lateral(theta,
lateral,metres)` advances the surface coordinate; `lip_frame(lateral)` exposes
the real steel top point, world-UP standing `normal`, original horizontal
`face_normal` and `coping_tangent`. `air_return_frame(world_point,lateral)`
describes finite over-lip return geometry.

`bowl_feature.gd` implements the same contract with a shared visible/native
circular wall, flat bottom, annular deck, roll-in and a continuous coping path.
It sets `wrap_lateral=true`, advances lateral coordinates using the surface
metric and supplies `lateral_acceleration` for parallel transport without an
artificial energy gain. `halfpipe_feature.gd` joins two real quarter faces with
a native flat bottom; `spine_feature.gd` joins opposing faces across a 0.6 m
solid cap. Both publish child coping paths and feature definitions. Current
infill places the bowl at `(122,2,66)`, the halfpipe at `(-60,2,35)` and the spine
at `(-110,2,30)`, within the existing Clyde/Central layout.

`game/player/transition_ride.gd` owns support states `idle`, `surface`, `lip` and
associated `air`. Public `active` stays true through surface/lip/associated air;
Skater's `airborne` distinguishes actual air for scoring. `try_enter(body,velocity)`
searches tagged features and requires a real face probe within 0.10 m and native
oriented-capsule clearance. `step(body,delta,push,brake,steer,jump=false,
lip_held=false,jump_impulse=8.8)` owns all support/air motion with full 22 m/s²
gravity; Skater must not apply gravity or integrate motion a second time.
Its result exposes `event` for launch, landed, lip, exit, exit_air or bail.
Surface travel uses tangent gravity, low-speed rollback and bounded collision
substeps (at most 0.055 m/2 degrees); analytic samples cannot attach a rider to
missing geometry. Descending re-entry requires the finite tagged face and native
clearance. Associated descending air can acquire another eligible face through
`_find_return`, enabling native halfpipe/spine transfers rather than a return
restricted to the departure face. Bowl motion transports its two tangent
components around the curved metric; root heading follows accepted travel
without manufacturing a spin award.

Holding Grind while crossing the real coping enters `lip` only after a short
native move to its steel top, a coping ray and upright-capsule clearance. Lip
standing `normal=UP` remains distinct from the wall's `face_normal`.
`lip_frame()` exposes the current frame; `refresh_frame(body)` reapplies the
accepted collision axis after root heading changes. Entry uses a fresh direction
at most 0.18 seconds old: neutral Lip Stall, N/S Nose/Tail Stall, E Axle Stall,
W Rock and Roll, NE Handplant, NW Invert, SE Eggplant, SW Disaster Stall.
Held lip rechecks both curved face and steel support. Flip/Grab/Revert style
actions have a 0.35-second cooldown; neutral actions choose Handplant/Invert/
Rock and Roll respectively, otherwise their direction selects the lip table.
Changing into Rock and Roll commits a physical 180° return-facing change.
Release drops in, Ollie release launches upward/away, and balance magnitude 1
bails. These are supported states and score entries; the rig's palm/axle/deck
contacts do not create substitute physics planes.

`reset(body=null)` restores the cached `BodyCollision` transform even when
inactive and restores `up_direction=UP` when a body is supplied. `get_support_normal()`
on Skater exposes the transition normal or world up. The registered quarter,
bowl, halfpipe and spine geometry is supported; arbitrary imported curved meshes
or vertical walls do not become transition features without this contract and
native collision. Side exits still require real clearance.

## World, gaps and objective markers

`game/levels/glasgow_square.gd` owns core city collision, terraced courts, graded streets, stairs, fountain coping, authored rails, goal/gap definitions, cone interaction and NPC locations. `core_terrain.gd` builds matching mesh/collision patches. `outdoor_routes.gd` adds Clyde quays, an eight-metre bridge opening with a continuous alternative, and rolling park terrain with paved climbs. `city_art.gd` dresses that layout with original materials/facades/landmark silhouettes and NPC figures. `get_spawn_position()`, `get_location_name(position)`, `get_district_id(position)` and `get_district_checkpoints()` expose navigation data for six areas. `get_ground_height(world_position)` returns highest authored terrain height or NAN outside authored terrain; props/roofs are not terrain. `get_support_height(world_position,max_step_up=1.0)` returns the highest authored terrain support at or below the supplied height plus the step tolerance, allowing a lower station passage beneath an upper deck. Actual ray/capsule checks remain the collision evidence. `support_probe` metadata on core graded bodies supplies a world-space surface-center point for local collision checks without confusing legitimate stacked routes. `get_route_definitions()` returns `{id,label,points,requires_jump}` with ordered world-space ground points. `get_recovery_position(position)` returns a safe local quay spawn or `Vector3.INF` when no hazard applies. `get_grind_lines()` returns fresh transformed track snapshots; ordinary scenery is layer 1 and rail props layer 2/mask 0, so unacquired rails do not obstruct normal travel or award tricks. `activate_cone()`/`reset_interactions()` manage the local visual interaction; `get_npc_positions()` supports nearby audio barks.

`get_gap_definitions()` returns `{id,name,start,end,radius,points,airborne_required}` in world space. Core routes are Gallery Steps (300), Mind The Gap (600) and Market Loading Steps (350), retaining their existing IDs; outdoor gap definitions extend the set. The Clyde transfer awards a real swept, airborne crossing of the bridge opening. `game/tricks/gap_tracker.gd` validates/snapshots definitions and `update(position,airborne,delta)` returns `{id,name,points}` for ordered swept crossings within 4 seconds. Reverse travel, invalid data, overlapping triggers, teleport steps over 20 m and missing required airtime reject. A completed/failed route locks until the rider leaves both triggers. First update only establishes position. Main resets the tracker after bail/restart, awards named points into the combo and records the career event; a grounded gap opens ordinary pending banking.

After city dressing, `SurfaceAudit.build(world,authored_lines)` walks actual
`StaticBody3D` collision and annotates wall eligibility/exclusion plus grind IDs.
It recognizes substantial opaque vertical box faces and exposed retaining
masonry; transparent/open/thin props, rail-only layers, perimeter containment and
curved transition support have explicit exclusions. Selected seating/planter/
plinth/practice-box top edges produce world-space ledge paths at least 1.2 m long,
deduplicated against existing authored paths. Native capsule sweeps still decide
live capture; a generated line does not create an invisible support plane.

`world.get_surface_audit()` returns a defensive version-1 snapshot with
`collider_count`, `wallrideable_count`, `ledge_body_count`, `generated_grind_count`,
`authored_grind_count`, `grind_track_count`, `wall_exclusions`, `surfaces`,
`visual_exclusions` and `limits`. Per-surface records
include audit `id`, scene `path`, `label`, position, shape count/type/box
size, collision layer, `wallrideable`, `wall_reason`, `grind_ids`,
`generated_ledge`, `capture_check_ids` and `grind_reason`. Collider metadata
includes `surface_audit_id`, `wallrideable`, `no_wallride`,
`wallride_exclusion_reason` and `grind_surface_ids`. This is an eligibility
inventory, not certification that every approach is reachable or human-tested.
Scenic furniture beyond the retained boundary, glass/canopies/foliage/iron detail
and flush 25 mm park edging are recorded as visual exclusions; stocked counters
and overhead shelters are not low ledges.
The [level surface audit](../levels/FULL-FIDELITY-LEVEL-AUDIT.md) records the current
inventory, sampled native clearance evidence and practical reachability limits.

`world.get_skate_feature_definitions()` returns defensive feature definitions.
Common records include `id`, `district`, `kind` and position/support information;
`bounds`, `features`, `approach`, `landing`, `line`, `grind_ids`, `lips` and review
viewpoints depend on the feature kind. The original practice-pocket records
retain `{id,district,bounds,floor_y,features,approach,landing}`. The
Clyde west quay pocket contains a quarter-pipe, manual pad, ledge and flatbar;
the Kelvingrove promenade pocket contains a quarter-pipe, manual pad and ledge.
Approach/landing corridors, the existing through routes and safety boundaries
remain part of the level's collision/navigation checks. `get_grind_lines()`
includes authored rails, transition coping and audit-generated ledges.

`fidelity_infill.gd` adds bank/manual-deck/return-ledge lines across all six
places, two climbing handrails, graded park ledges and the three connected curved
features above. `world.get_level_density_audit()` returns per-district samples,
counts within 20/35 m, maximum distance/farthest point, 6 m sample spacing and the
number of new lines. It measures horizontal proximity from non-jump route
samples to actual tracks/features within 2.5 m vertically; it is not pathfinding
or proof that every approach is reachable. The current inventory and exclusions
are in [FULL-FIDELITY-LEVEL-AUDIT](../levels/FULL-FIDELITY-LEVEL-AUDIT.md).

`get_goal_markers()` supplies `{id,kind,position,radius}` definitions. `game/progression/objective_tracker.gd` renders markers, `poll(position,interact)` returns each nearby event once per run, `nearby_prompt()` exposes content for the HUD's live binding prompt, `collected_count(kind)` reports the actual collected count, and `reset_run()` restores markers. District visits use world regions and do not create collectible orbs. The cone needs deliberate interaction; letters/market items/recording collect by proximity. `reduced_motion` disables marker bob/rotation. Location thresholds and marker radii are gameplay authoring, not verified real-world frontage geometry.

## FeatureHub, service route, stunt, lap and vehicle

`game/features/feature_hub.gd` is exposed as `main.feature_hub`/scene node
`GlasgowActivities`. `configure(world,skater)` builds once. `challenges()` returns
the cone and lap components for Main's existing nearest-offer arbitration;
`poll(position,interact,delta,combo_value=0,audience_visible=false,selected_id="")`
ticks their actual play and the gate. Main forwards admitted `on_trick(name,
points,position,identity)`, `on_landed(clean)`, `on_bank(points,position)` and
`on_bail`; `cancel_attempt`, `finish_run` and `reset_run` follow run lifecycle.
Signals are `feedback(text)` and `routes_changed()`. `nearby_id`,
`nearby_prompt` and `gate_prompt` select wording without injecting progress.
`status_snapshot()` selects an active/nearby challenge; `definitions_snapshot()`
returns all gate/route/cone/lap/vehicle observations. Reduced motion controls
cone/lap presentation; their required physical play, gate and vehicle movement
remain gameplay. Main applies pause, expiry and reset. These components add no score, saved goal, unlock or
profile schema field.

All source positions below are world X/Z; offer, gate, route and cart Y values
are resolved through actual authored terrain height by `_ground`.

| Feature | Location / authored path |
|---|---|
| Service cut-through | Switch/door at `(-48.5,-2)`; route `(-48.5,-18) → (-48.5,-2) → (-48.5,12)` |
| Cone on a Cruise | Steward `(-5,66)`, launch `(-5,74)`, ring `(-5,1.2,80)`, recovery raft `(-5,-1.9,82)` (last two are full XYZ) |
| One More Lap | Offer/finish `(-155,-82)` on the lower park promenade |
| Full park loop | `(-164,-88) → (-195,-106) → (-208,-126) → (-181,-164) → (-145,-146) → (-145,-104)`, then return |
| Grass-bank cut | `(-148,-92) → (-156,-112) → (-179,-136) → (-195,-106) → (-164,-88)`, then return |
| Quay Crew electric cart | West quay between `(-78,70.5)` and `(-28,70.5)` |

`service_gate.gd` owns one layer-1 `AnimatableBody3D` shutter. `request_toggle()`
opens/closes reversibly; its layer-2 player sensor refuses an occupied closing
request and rechecks throughout closing. `tick(delta)` moves the real panel over
1.25 seconds; it does not disable collision to fake opening. `status_snapshot()`
reports `open`, `requested_open`, `progress`, `blocked` and actual position.
`route_definition()` supplies stable `service_gate_shortcut` points and an
`enabled` flag only at full opening. Main appends `FeatureHub.get_route_definitions()`
to the world map and refreshes on `routes_changed`; Restart restores closed.
Its permanent bypass and collision/navigation checks remain authoritative.

`cone_stunt.gd` owns a native 0.35 kg foam `RigidBody3D` with matching hull/base/
band collision, torus rim and recovery raft. A settled-combo interaction accepts
`cone_on_a_cruise` for 25 seconds. A second fresh interaction near the mark must
observe actual airborne skating, positive pending trick score, at least 6 m/s
planar travel and alignment dot above 0.85. Native impulse uses actual approach
direction/speed and fixed upward impulse; callbacks cannot award a crossing.
Every swept hull point must pass within the clear aperture without native rim
contact, and the trailing hull must leave the ring. Success also requires real
raft contact, a clean player landing and positive ordinary bank on the quay.
Rejected prelaunch input can be retried; rim/miss, bail, timeout or area exit
fails and recovers the prop. Snapshot includes launch/target/raft, target/hull/
rim observations, landed/banked/raft flags and ordinary attempt/win/timer state.
The prop uses layer 4 against world/prop collision, independently of player
world/cart masks.

`lap_challenge.gd` accepts `one_more_lap` only with no pending combo and grants
75 seconds. The first real swept numbered gate chooses six-gate `park_full_loop`
or five-gate `park_bank_cut`; later gates are ordered, with a 3 m horizontal and
1.6 m vertical gate tolerance and a 6 m maximum accepted position sweep. A real
admitted launch inside the park must be followed by a clean landing. All gates,
that landed pop and physical return within 3.2 m of the offer are required.
Skipping a later gate, leaving its XZ bounds, bail, cancellation or expiry fails;
the component cannot complete through teleports. Snapshot exposes branch,
`gate_index`, `landed_pop`, `next_gate`, branches and attempt/win/timer state.

`skate_vehicle.gd` is one layer-8 native `CharacterBody3D` in `skate_vehicles`,
moving before the skater (`process_physics_priority=-10`). It accelerates to
6 m/s, waits 1.8 seconds at the quay-lane ends and stops before native world
obstruction or its front pedestrian sensor. The chassis/cab/four wheel colliders
match visible geometry. Ground-level players block the sensor; an actual
supported roof rider does not create mutual blocking feedback. Player collision
mask `1|8` permits ordinary bed/cab platform support and leaves momentum native.
This is one bounded service vehicle, not a general traffic simulation.
`get_skitch_anchor()` returns local `(0,0,2.25)` in world space;
`get_skitch_hand_targets()` returns left/right rear-bar surface points from
`(-0.40,0.93,1.745)` / `(0.40,0.93,1.745)`, and
`get_skitch_surface_normal()` returns its outward rear normal. These observations
come from the real cart; `travel_velocity` is measured native travel.
`stop_run()` halts physics and `reset_run()` restores its original path state.

## Career and local persistence

`game/progression/career_progress.gd` (`CareerProgress`) owns ten goals: three banked-score targets (1,000/5,000/15,000), one 3,000-point combo, HAWKS letters, cone duty, Central gap, three market items, four districts and the hidden recording. `begin_run(free_skate)` resets run-local progress; `record_score(total,best_combo)`, `record_event(kind,id)` and `finish_run(total,best_combo)` return newly completed goal IDs. Only an active career run accepts progress; free skate does not advance career records/unlocks. `goals_snapshot()` and `unlocks()` return UI data. Score goals grant orange/Clyde Carousel at First shift, purple at Some shift, and Tenement Tumble at One long line. Blue is always available.

The four added specials reuse those two unlock IDs through catalog
`required_unlock`: Carousel, Barras Butterflip and Bridge Blender share
`special_clyde_carousel`; Tumble, Kelvin Corkscrew and Sandstone Salute share
`special_tenement_tumble`. The ten goal IDs, existing unlock IDs and profile schema
are unchanged. Native cart/stunt/lap/gate observations are run-local, not new
career fields.

`load_profile(path)`/`save_profile(path)` default to `user://career.json`, schema version 1, with validated settings and a verified backup/temp replacement path. A known version-0 schema migrates; unreadable/newer data is preserved and automatic overwrite is blocked. `recover_profile(path)` is an explicit local reset API that archives existing files first; main does not invoke it automatically. Failures leave session play available with save status. Script runners disable persistence by default, and integration tests set it off explicitly.

`game/tricks/special_meter.gd` gains live charge through `earn_trick(points)`:
accepted effective base points/10, at most 50 units per event, capacity 100. Main
credits entry, hold, spin, gap and positive upgrade additions; banking gives no
second charge. The deprecated `earn_bank` alias exists only for older tooling.
Reaching capacity activates a sustained state; public `active` persists below
full while value remains positive, and `ready()` is its usable-state gate.
`consume()` returns readiness without emptying charge. `tick(delta,
combo_active=false)` drains an active meter over six seconds, or twelve while
continuing a real combo without new awards. Accepted awards refresh charge.
Inactive partial charge has a two-second idle grace then drains 4 units/second.
Main ticks once during active unpaused play; nonfinite/nonpositive deltas cannot
advance it. `on_bail()` and `reset()` clear value, active state and idle time.
Free skate bypasses career-special unlock gating but still requires charge and
player eligibility. Rejected requests earn no points or special charge.

## Main, HUD, audio and settings

`game/main.gd` owns component creation, event wiring, 120-second career runs,
free skate, pause/results, objective polling and saves. At expiry it rejects new
entries and allows an existing air/rail/manual/wall/lip/setup/caught-tow/pending-ground combo at
most 3 seconds to resolve; the deadline cannot be extended. Clean banking routes
through `_on_combo_banked` for goals, feedback and saving. Hard expiry/bail drops
unbanked points. Restart clears score repetition, meter and transient gameplay
while preserving career data. `special_requested` gestures and existing direct
special buttons route to the same Main unlock/readiness/eligibility gate.

`game/ui/hud.gd` is a CanvasLayer receiving `update_display(snapshot)`: score/combo/history, timers, speed, manual/rail balance, landing/revert windows, location, mode/results, goals/unlocks/records, special charge, settings, captions and save/interaction status. `save_warning` is persistent failure information, separate from ordinary `save_status`; timed objective notifications have their own area alongside live combo feedback. Signals include restart, pause, free skate, `start_requested(free_skate)`, `settings_changed(values)`, `cosmetic_selected(id)` and UI feedback. Title/settings/controls/goals/pause/results and City map & routes pages are enabled, with nested return navigation and focus restoration. Live binding snapshots drive device-specific remap and interaction prompts. `set_map_data(checkpoints,routes)` supplies the route diagram from actual world coordinates. `show_map()` opens it through the existing paused subpage stack; the arrow shows snapshot position/heading, brighter route segments indicate greater height and dashed orange paths indicate jumps. Pause and Goals expose the map without adding another input action.

The skating snapshot also supplies `last_bonus`, `stance`, `takeoff_mode`,
`ollie_charge`, `crouching`, `powersliding`, `wallriding`, `transition_active`,
`lip_active`, `lip_name`, `lip_balance`, `setup_active`, `setup_id`, `setup_phase`,
`bail_active`, `recovery_fade`, `skitching`, `skitch_caught`, `skitch_balance`,
`special_ready` and `special_active`. The HUD shows
current preparation/recovery/movement state, charge, the relevant rail/manual/lip/tow balance, sustained
special readiness and contextual bindings. The Trick Guide uses catalog
directions, upgrade/extension commands, all six special sequences and live
remapped controls. Moving-ground HUD speed includes actual carried motion;
`Skater.speed` remains relative signed skating speed.

`apply_settings(settings,persist)` validates/clamps bindings, master/SFX/ambience volumes, captions, reduced motion, UI scale 1–1.4, sensitivity 0.5–2 and earned cosmetics. `select_cosmetic(id,persist)` rejects locked choices. `game/audio/skate_audio.gd` exposes `set_motion`, `set_mix`, `set_surface`, `play_event`, `play_bark`, `set_paused` and a caption signal. Original local synthesis supplies rolling/grinding/events/district beds; generated bark files have separate recorded provenance. No runtime voice/network service is used. Main reads upward floor contacts and their `surface_audio` metadata: asphalt connectors, metal ramps, stone fallback. Air and grinds do not change the last floor selection; audio motion gates their wheel loop. Run completion can trigger the nearby NPC's cooldown-protected “again” line.

## Validation boundaries

Run `./tools/check.sh` for import and unit/real-physics integration suites. `./tools/capture.sh` and other documented capture runners require a rendering display. Use the scripts' writable `.local` XDG directories. Test counts and newest rendered evidence belong in STATUS/QE-REPORT. Automated Linux tests, software rendering and a remap UI do not establish controller comfort, macOS launch, Apple Silicon performance or final-art acceptance. Those gates remain open while authorized implementation continues.


## Glasgow side encounters

`game/characters/glasgow_encounters.gd` is an original session-local encounter component, exposed as `main.encounters`. World `get_encounter_definitions()` provides `{id,position,heading}` for original fictional locals. Mo's Big Finish starts through a fresh nearby interaction with no pending combo, then requires one clean bank of at least 1,000 points containing three distinct trick families inside the court within 35 active seconds. It is available in both modes and does not create another career/save goal.

Main calls `poll(position,interact,delta,pending_combo)` only during active unpaused play, forwards real `on_trick`, `on_bank` and `on_bail` events, ends an active attempt at run expiry and resets it on Restart/mode change. A short bank clears family evidence for a fresh line within the same attempt; leaving the court invalidates the current line; a bail/timeout fails the attempt. Interaction near Mo replays after either result. The component never awards score or writes the career profile.

`status_snapshot()` includes state, remaining time, families, attempts/wins, reason and `hud_text`; HUD receives that text in a dedicated persistent feedback-stack line. `nearby_prompt` returns action wording only, so HUD can add the actual remapped input. The animated musician reuses the verified anatomical/garment helpers with an original guitar/case and is pausable. `set_mix(master,ambience)` controls an original cached eight-second spatial plucked-chord texture; Dummy-driver tests inspect PCM while real listening remains open; final likeness, listening and human-fun acceptance remain separate. Research sources and adaptations are in GLASGOW-CHARACTERS and GLASGOW-FUN.


`game/characters/cat_encounter.gd` is the separate original bin-drum/dancing-cat busking challenge, exposed as `main.cat_encounter`. `configure` reads world definition `cat_got_the_beat` with world-space `position`, `heading`, three unique `sequence` IDs, `area_center` and `area_radius`. Public methods are `poll(position,interact,delta,combo_value,audience_visible=false)`, `on_grind_capture(id,position)`, `on_bank(points,position)`, `on_bail`, `cancel_attempt`, `finish_run`, `reset_run`, `nearby_prompt`, `status_snapshot`, `set_mix(master,ambience)`; signal `feedback(text)` and setting `reduced_motion` follow the busker interface.

The new player signal emits once only after real GrindRide admission, clearance and installed position/velocity, before the ordinary grind trick award. Main forwards the actual authored ID/position. The cat sequence can span intermediate clean banks; after all three ordered captures the next positive actual bank inside the area wins. Duplicate-most-recent captures are ignored; wrong marked captures reset or restart at1; unrelated rails are ignored. A bail, timeout or area exit fails the attempt. The component adds no score, goal, unlock or save data. Snapshot fields include `id`, `state`, `remaining`, `sequence_index`, `next_rail_id`, `required_ids`, `attempts`, `wins`, `position`, `area_center`, `area_radius`, `hud_text`, `reason`, `celebration_state` and `celebration_started`.

Objectives retain interaction priority. Main chooses the closest nearby side offer; accepting with no pending combo calls the other components’ `cancel_attempt` before starting. Only one side attempt is active, and its persistent HUD text takes priority over a previous result. The shared list now includes busker, cats, delivery, cone stunt and park lap; every active side attempt ends at the positive→zero career-timer edge independently of ordinary score overtime. The service gate remains a separate interaction. Pause freezes clocks/actors. Original encounter contracts remain in ADR-009 and GLASGOW-FUN; new activities follow ADR-016, and physical/capture results belong in STATUS/QE.


A successful cat bank queues its one-shot 3.2-second celebration. Main supplies `audience_visible` from the actual active `Camera3D.is_position_in_frustum` test on the stage point. Only returning within 10m horizontally/2.5m vertically with that view starts it; no camera takeover or extra reward occurs. Replay/reset clears the queue. Run end cancels queued/playing animation while preserving the earned win. Reduced motion uses a static raised paw; enabling it during the dance stops movement without replaying it on later toggles. The success HUD/world sign explains returning to see the payoff.

The corrected actor is `RaeBinBusker`, with a seated original drummer, container percussion and two fabric cat props. `PitchSign` and the world sign describe busking rather than charging machinery. Main forwards settings to the spatial original bin-percussion loop through `set_mix`; finish/reset must respectively suppress/restore it. Reduced motion holds the drummer and cats still. Legacy internal workshop terrain/route IDs remain stable; their public labels now describe the busking pitch. ADR-010 supersedes ADR-009’s mechanical presentation only.


## Barras delivery and landmark revision

`main.market_encounter` is the third pausable side component, ID `gull_proof_delivery`. `configure` reads world-space pickup `position`, `heading`, `delivery_position`, `delivery_heading`, `area_bounds` (XZ Rect2), `required_gap`, two unique three-gate `routes`, `gate_radius` and `delivery_radius`. `set_carrier(rider)` attaches an original courier bag to the rider's TorsoRig. The public lifecycle follows the other encounters: `poll(position,interact,delta,combo_value=0,audience_visible=false)`, `on_trick(name,points,position)`, `on_gap(id,position)`, `on_bank(points,position)`, `on_bail`, `cancel_attempt`, `finish_run`, `reset_run`, `nearby_prompt`, `status_snapshot`, signal `feedback` and setting `reduced_motion`.

Its `navigation_targets` snapshot is an array of `{label,position}` observations: empty before the admitted gap or outside an active attempt, both first gates before branch choice, the selected next gate, then delivery. Steady numbered world markers share the configured coordinates and add no collision. Main appends target bearing and distance relative to the rider's travel heading to the existing challenge HUD, including an explicit turn-back cue for a target behind the stair landing. These presentation cues cannot advance gates or alter scoring.

Main forwards the actual admitted Manual event and actual GapTracker awards, followed by ordinary banks. A Manual then `market_hop` in the same clean line qualifies after a positive bank; an incomplete bank clears its line/route evidence while the attempt clock continues. The actual post-gap first gate commits either `covered` or `west`, each ordered Z−5→7→18. All three gates, a qualifying bank and physical delivery are required. The 60-second deadline, market bounds, pause/bail/leave/reset/retry and career-expiry behavior are run-local and add no score, goal, unlock or save field. Objectives retain priority; delivery joins the nearest-offer arbitration with the other four side activities, and fresh eligible acceptance cancels other active attempts. Active HUD feedback takes precedence over previous results.

A successful delivery queues a bounded 3.2-second original gull/spare-wrapper response. Main checks the actual camera frustum against `status_snapshot().payoff_position + Vector3(0,0.8,0)`; nearby visibility gates playback, and reduced motion uses a static alternative. The delivered parcel never follows the bird. The pickup actor is MarketStallholder; the remote delivery counter and courier bag supply visible parcel state.

World art uses original Barrowland-style tube lettering, stars and frontage plus a market aisle with two side-canopy rows. OutdoorRoutes calls `ClydeLandmarks.build` for a compressed South Portland-derived suspension bridge and Carlton Place-derived joined terrace. The helper has no collision; OutdoorRoutes supplies matching house boundary bodies at Z145.4..157.4. Existing bridge decks/rails, water, recovery and protected quay/yard routes remain authoritative. ADR-011 and BARRAS-CLYDE-BRIEF record coordinates, observed references and gameplay adaptations.

## Exchange/gallery architectural skating edges

The gallery entrance and west shopfront attachments use the existing authored terrain, support-height, route and grind interfaces. Their raised floors and banks are terrain support; seating/coping and building details are separate props. Core world geometry owns matching solids for the reachable gallery column shafts/bases, while the art helper remains collision-free. Column positions, plinth heights and roof datum must agree across both layers. The gallery cross-bank line stays in front of the columns.

The optional ledge lines use ordinary admitted grind capture, release/ollie, Manual and clean banking. They introduce no player state, score bonus, career goal, encounter or save field. The X±22 approaches, Z−22 crossing, original stair launch/landing, cone and south station port remain supported beginner routes. The exact authored footprints and protected envelopes are recorded in `docs/levels/EXCHANGE-GALLERY-BRIEF.md`; current physical/rendered acceptance belongs in STATUS/QE rather than being inferred from route metadata.

## Source launch and ordinary-play repair

ADR-012 records the owner's reproduced cold-source failure and playability repairs. Ordinary `tools/run.sh` play prepares asset imports/global script classes before launching and refuses preparation errors. Editor/test/export invocations retain explicit preparation. Generated `.godot/` state is local, never a distributable dependency.

Skater retains collision, push/brake, takeoff, manual/grind and scoring admission. The original `skate_response.gd` helper owns ordinary coast and bounded ground/air steering through `coast_speed`, `steering_step` and `reset`; manuals keep their existing balance coast. Reset/disabled controls clear steering response. Presentation sensitivity affects camera follow only. Camera/world repair contracts and current normal-frame/cold-launch evidence belong in PLAYABILITY-REPAIR-BRIEF, STATUS and QE.

Fresh directional vert transfers use a released/repressed Push or Brake during
associated air. Inherited approach Push does not transfer. Native air movement
adds up to3.5 m/s horizontal correction from near-vertical air at6 m/s², retaining
larger existing horizontal momentum without boosting its magnitude; deckward steering waits
until0.30m above the lip for clearance; no vertical boost is added. The helper's
`grind_path_clear(from,to,body)` uses an upright capsule query without mutating
the current support frame. Root resets the transition only after a successful
rail acquisition, preserving safe associated air after a refused capture.

HUD speed is the actual three-dimensional velocity magnitude while transition
movement owns the rider, so a vertical ascent cannot display0 km/h. This is only
presentation: `Skater.speed` retains its signed board-forward semantics. Runtime
reset synchronizes held buttons without manufacturing edges, and a held Ollie
must release before another deliberate charge can begin after reset/entry gates.
