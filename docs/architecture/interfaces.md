# Runtime interfaces

Updated 17 October 2026 against the current implementation. Godot 4.6.3, Compatibility renderer, native GDScript, one attributed MIT rail-geometry component, original procedural world/rider art, and local audio. Runtime has no network service or paid dependency. This describes enabled behavior, not human acceptance or target-Mac certification.

Coordinates use +Y up and local -Z forward. The board-contact origin starts at `(0, 0.8, 12)` and settles onto Y=0. The connected original skating map contains Royal Exchange, George Square, Central Station and the Barras. Its main floors extend roughly X ±128 and Z -125 to 42; scenery extends farther. Player recovery catches Y below -8 or absolute X/Z above 400. These are game coordinates, not surveyed Glasgow street geometry.

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

`game/core/input_profile.gd` owns validated overrides. `binding_snapshot()` supplies readable live bindings; `rebind(action,event)` returns `{ok,error,bindings}`; `apply_saved(bindings)` validates the complete candidate before changing InputMap; `reset_defaults()` restores defaults. Overrides contain only permitted physical key/button/axis fields. Duplicate bindings, unknown actions, unsupported axes, modifier/echo keys and weak axis capture are rejected. Analog capture requires magnitude 0.5. Keyboard and controller overrides are separate; Godot `ui_*` actions are preserved. Career settings persist accepted binding dictionaries. A controller disconnect pauses active gameplay; keyboard fallback remains available.

## Skater and presentation

`game/player/skater.gd` extends `CharacterBody3D`. Public state includes `speed`, `airborne`, `spawn_position`, `grinding`, `grind_balance`, `manual_active`, `manual_balance`, `revert_remaining` and `special_name`. Signals are `trick_performed(name,points)`, `landed(clean)`, `bailed()`, `combo_link_started()` and `combo_link_ended()`.

`reset_skater()` restores motion and all transient trick/visual state. `set_controls_enabled(false)` stops horizontal movement and an active manual; `set_trick_entries_enabled(false)` rejects new launches/tricks/captures/manuals/reverts/specials while allowing an existing rail/manual to resolve during overtime. Pausable node processing freezes physics and visual timers. Actual landings emit once; cosmetic spins remain independent of travel heading and ordinary heading-only landings are forgiving.

Ground motion projects onto the current floor. Air carries collision-adjusted horizontal velocity and rotates it by bounded steering, preserving the measured takeoff fix. Ground speed uses capped actual travel velocity to avoid artificial downhill braking. The 56° floor classification supports ordinary banks; near-vertical quarter-pipe support is not implemented.

- `set_grind_lines(lines)` snapshots world-space authored tracks. Held eligible air capture uses `GrindRide`; capsule sweeps reject scenery obstruction. Entry awards 200 once and resolves prior spin without a landing. Release preserves signed tangent momentum, and recapture waits 0.35 seconds.
- Manual requires a fresh supported press, speed at least 2 m/s and a 0.35-second exit cooldown. It coasts while push/brake correct fore/aft balance and left/right still steer. Entry awards 100 once and emits link-start before scoring. Release/insufficient speed emits link-end once; an actual ollie emits link-start and continues airtime. Losing support clears manual without a false ground-end. Absolute balance 1 bails.
- Revert requires fresh grounded input within `revert_remaining` after actual air landing, cannot occur during a manual/rail, and is once per landing. It costs 15% speed, awards 150 and animates a cosmetic 180° stance change over 0.18 seconds. It emits no continuation event and never resets the score deadline. `revert_remaining` is input eligibility; it is not the authoritative banking timer.
- `try_special(id) -> bool` accepts only the two catalog specials during eligible unpaused airtime, once per actual air segment. It emits the catalog award only on success. Main checks career unlock and meter first, and consumes the meter only after `true`. Original 0.65-second board-spin/body-tuck animations do not rotate the collision shape or change travel velocity.

`set_presentation_settings(sensitivity,reduced_motion)` clamps steering sensitivity to 0.5–2 and removes speed-dependent camera distance/FOV when reduced motion is enabled. `set_skater_color(Color)` changes the shared shirt material. The presentation helper `game/player/skater_visual.gd` builds and poses rounded original rider/board geometry, feet on the deck, articulated push/landing/air poses and a hand-to-board grab. Keep `SkaterVisual`, `Board`, `Rider`, and the upright `BodyCollision` contract intact. This is procedural articulated art, not a skinned production character or motion-capture certification.

## Score and combo resolution

`game/scoring/score_session.gd` is the authoritative `RefCounted` score/deadline model. It exposes `total_score`, `combo_base`, `combo_multiplier`, `best_combo`, `last_trick`, `last_banked`, `trick_history`, `pending_landing` and `landing_remaining`.

`add_trick(name,points)` adds repeat-degraded points; identity deliberately remains the display name, including distinct spin labels. `get_combo_value()` previews the capped multiplier. `begin_landing()` opens a single **0.35-second** pending bank only for a nonempty combo; duplicates cannot extend it. `continue_combo()` clears pending banking for a valid movement link. `tick(delta)` consumes active-play time and returns a bank exactly once on expiry. Adding a trick, including Revert, does not refresh or cancel the timer. `bank_combo()`, `drop_combo()` and `reset()` clear all pending deadline and repetition state.

Per-event values are capped at 1,000,000; base, multiplied combo and total records saturate at 2,147,483,647. Repeats halve to a sixteenth and distinct names multiply up to 8. Career records separately clamp to their save-model bound of 2,000,000,000.

Main connects player link-start to `continue_combo`, link-end/clean landing to `begin_landing`, and bail to `drop_combo`. While physical air, rail or manual remains active it calls `continue_combo`; ordinary loss of support therefore sustains an existing combo without inventing an Ollie award. Clean ground travel banks after the remaining window. The full ordering and overtime rules are in [ADR-006](decisions/ADR-006-trick-state-and-input.md).

## Rail helpers and catalog

The adapted MIT `game/tricks/grind_line.gd` owns a world-space `Curve3D`. Constructor `(id,world_points,kind)` and `from_local_points(id,points,transform,kind)` snapshot geometry. `is_valid` rejects invalid/collapsed lines; `point_at(distance)` clamps endpoints; `dir_at(distance)` returns a full 3D tangent; `closest(position)` returns `{dist,point,gap}` or `{}`. Units are world metres. Rebuild after authoring transforms change. Retain its complete upstream notice.

Original `game/tricks/grind_ride.gd` owns signed progress, speed and balance. `start(lines,from,velocity,clearance)` selects an eligible clear candidate; `step(delta,balance_input)` returns `riding`, `end`, `bail` or `slow`. `position()` and `travel_velocity()` retain the release sample; `stop()` deactivates the ride. The player supplies collision sweeps, input gating and scoring. See [GRINDING](../testing/GRINDING.md) for tuning and actual authored tracks.

`game/tricks/trick_catalog.gd` provides copy-returning definitions, stable IDs, known-state/transition guards and repeat arithmetic. Structural permission alone never proves physical eligibility, unlocks, charge or input freshness. Manual, revert, both specials and authored gaps are now wired to runtime systems; catalog presence remains insufficient to enable any later addition.

## World, gaps and objective markers

`game/levels/glasgow_square.gd` owns collision, four connected districts, ramps, six authored rails, goal/gap definitions, cone interaction and NPC locations. `city_art.gd` dresses that layout with original materials/facades/landmark silhouettes and NPC figures. `get_spawn_position()`, `get_location_name(position)`, `get_district_id(position)` and `get_district_checkpoints()` expose navigation data. `get_grind_lines()` returns fresh transformed track snapshots; ordinary scenery is layer 1 and rail props layer 2/mask 0, so unacquired rails do not obstruct normal travel or award tricks. `activate_cone()`/`reset_interactions()` manage the local visual interaction; `get_npc_positions()` supports nearby audio barks.

`get_gap_definitions()` returns `{id,name,start,end,radius,points,airborne_required}` in world space. Current routes are Exchange Air (300), Mind The Gap (600) and Barras Basket Hop (350). `game/tricks/gap_tracker.gd` validates/snapshots definitions and `update(position,airborne,delta)` returns `{id,name,points}` for ordered swept crossings within 4 seconds. Reverse travel, invalid data, overlapping triggers, teleport steps over 20 m and missing required airtime reject. A completed/failed route locks until the rider leaves both triggers. First update only establishes position. Main resets the tracker after bail/restart, awards named points into the combo and records the career event; a grounded gap opens ordinary pending banking.

`get_goal_markers()` supplies `{id,kind,position,radius}` definitions. `game/progression/objective_tracker.gd` renders markers, `poll(position,interact)` returns each nearby event once per run, `nearby_prompt()` exposes an interaction hint, and `reset_run()` restores markers. The cone needs deliberate interaction; letters/market items/recording collect by proximity. `reduced_motion` disables marker bob/rotation. Location thresholds and marker radii are gameplay authoring, not verified real-world frontage geometry.

## Career and local persistence

`game/progression/career_progress.gd` (`CareerProgress`) owns ten goals: three banked-score targets (1,000/5,000/15,000), one 3,000-point combo, HAWKS letters, cone duty, Central gap, three market items, four districts and the hidden recording. `begin_run(free_skate)` resets run-local progress; `record_score(total,best_combo)`, `record_event(kind,id)` and `finish_run(total,best_combo)` return newly completed goal IDs. Only an active career run accepts progress; free skate does not advance career records/unlocks. `goals_snapshot()` and `unlocks()` return UI data. Score goals grant orange/Clyde Carousel at First shift, purple at Some shift, and Tenement Tumble at One long line. Blue is always available.

`load_profile(path)`/`save_profile(path)` default to `user://career.json`, schema version 1, with validated settings and a verified backup/temp replacement path. A known version-0 schema migrates; unreadable/newer data is preserved and automatic overwrite is blocked. `recover_profile(path)` is an explicit local reset API that archives existing files first; main does not invoke it automatically. Failures leave session play available with save status. Script runners disable persistence by default, and integration tests set it off explicitly.

`game/tricks/special_meter.gd` earns charge only from resolved bank events: points/25, at most 50 units per bank, capped at 100. `consume()` succeeds only at full charge and resets to zero; restarting resets it. Free skate bypasses career-special unlock gating but still needs charge and player eligibility. Rejected requests spend nothing.

## Main, HUD, audio and settings

`game/main.gd` owns component creation, event wiring, 120-second career runs, free skate, pause/results, objective polling and saves. At expiry it rejects new trick links and allows an existing air/rail/manual/pending-ground combo at most 3 seconds to resolve; the deadline cannot be extended. Clean banking routes through `_on_combo_banked` for goals, special charge, feedback and saving. Hard expiry/bail drops unbanked points. Restart clears per-run state and preserves career data.

`game/ui/hud.gd` is a CanvasLayer receiving `update_display(snapshot)`: score/combo/history, timers, speed, manual/rail balance, landing/revert windows, location, mode/results, goals/unlocks/records, special charge, settings, captions and save/interaction status. Signals include restart, pause, free skate, `start_requested(free_skate)`, `settings_changed(values)`, `cosmetic_selected(id)` and UI feedback. Title/settings/controls/goals/pause/results pages are enabled. Live binding snapshots drive remap prompts.

`apply_settings(settings,persist)` validates/clamps bindings, master/SFX/ambience volumes, captions, reduced motion, UI scale 1–1.4, sensitivity 0.5–2 and earned cosmetics. `select_cosmetic(id,persist)` rejects locked choices. `game/audio/skate_audio.gd` exposes `set_motion`, `set_mix`, `set_surface`, `play_event`, `play_bark`, `set_paused` and a caption signal. Original local synthesis supplies rolling/grinding/events/district beds; generated bark files have separate recorded provenance. No runtime voice/network service is used. Main's present surface selection remains the default unless explicitly changed through the audio API.

## Validation boundaries

Run `./tools/check.sh` for import and unit/real-physics integration suites. `./tools/capture.sh` and other documented capture runners require a rendering display. Use the scripts' writable `.local` XDG directories. Test counts and newest rendered evidence belong in STATUS/QE-REPORT. Automated Linux tests, software rendering and a remap UI do not establish controller comfort, macOS launch, Apple Silicon performance or final-art acceptance. Those gates remain open while authorized implementation continues.
