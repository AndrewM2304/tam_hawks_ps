# Prototype interfaces

Godot 4.6.3 with the Compatibility renderer. Native GDScript with one adapted MIT rail-geometry helper; no plug-ins or downloaded game assets. Scene geometry is procedural and fully original. Coordinates: +Y up, player forward is local -Z, ground surface Y=0, spawn `(0, 0.8, 12)` facing -Z. World bounds approximately X ±35, Z ±42.

## Input actions (registered by game/core/input_setup.gd)
`push`, `brake`, `steer_left`, `steer_right`, `ollie`, `flip`, `grab`, `spin_left`, `spin_right`, `restart`, `pause`, `free_skate`.
Keyboard: W/up push, S/down brake, A/D or left/right steer, Space ollie, J flip, K grab, Q/E spin, R restart, Escape pause, F free skate. DualSense through SDL standard mapping: left stick push/brake/steer, Cross ollie, Square flip, Circle grab, L1/R1 spin, Options pause, Triangle restart, touchpad free skate. Physical mapping requires hardware verification.

## Skater — game/player/skater.gd
Extends `CharacterBody3D`, instantiated by main. Owns body meshes, movement, trick timing, and camera. Public properties `speed: float`, `airborne: bool`, `spawn_position: Vector3`; signals `trick_performed(trick_name: String, points: int)`, `landed(clean: bool)`, `bailed()`. Public `reset_skater()` restores spawn and physics; `set_controls_enabled(enabled: bool)` gates input. Emit landing only when transitioning from airborne to grounded; do not score held-button tricks repeatedly. Main handles combo/total scoring. Flat ground landing succeeds; over-rotated/unsafe landing may bail only if documented. Ramps use ordinary static collision; no rail/manual mechanics in M01.

## World — game/levels/glasgow_square.gd
Extends `Node3D`, instantiated by main. Generates a readable, skateable fictional Glasgow square with static collision, ramps, ledges, boundary walls, buildings, cone-topped statue, signs, and lighting/environment. No external resources. `get_spawn_position() -> Vector3` returns `(0, 0.8, 12)`. `get_location_name(position: Vector3) -> String` returns a district/landmark label. World owns visual geometry and collision; no scoring, input, or player creation. Keep central path unobstructed and all slopes skateable.

## Score — game/scoring/score_session.gd
Extends `RefCounted`. Holds `total_score`, `combo_base`, `combo_multiplier`, `best_combo`, `last_trick`, `last_banked`, `trick_history`. `add_trick(name, points)` accumulates with repeat-trick degradation; `bank_combo() -> int` awards combo and resets; `drop_combo()` loses active combo; `reset()` resets the run. `get_combo_value() -> int` computes preview.

## Main and UI
`game/main.gd` creates world and skater, wires signals to scoring, implements 120-second runs, free skate, pause/restart, and passes snapshots to `game/ui/hud.gd`. HUD extends CanvasLayer with `update_display(snapshot: Dictionary)`; UI controls emit restart/pause/free-skate signals. Timer runs only during active play. The root orchestrator owns these files.

## Rail geometry — game/tricks/grind_line.gd
Adapted MIT `GrindLine` extends `RefCounted`. Constructor `(id, world_points: PackedVector3Array, optional_kind)` builds a world-space `Curve3D`; `from_local_points(id, points, authoring_transform, optional_kind)` snapshots transformed authored points. `is_valid` requires finite geometry and nonzero length. `point_at(distance)` clamps to endpoints; `dir_at(distance)` returns the full 3D unit tangent for positive progress; `closest(world_position)` returns `{dist, point, gap}`. Invalid sample requests return zero vectors and invalid closest queries return `{}`; callers must check `is_valid`. Distances are world metres; recreate after changing parent transforms. The future grind state owns signed motion, endpoint release, collision, balance and scoring. This helper is not yet wired to the skater or visual rail props.

## Testing
`godot --headless --path . --editor --import` validates imports. `godot --headless --path . --script tests/run_tests.gd` runs focused unit/integration tests. Use writable XDG data/cache/config directories inside `.local` in this cloud machine. Rendered capture is separate from headless physics tests. No remote services or runtime secrets required.
