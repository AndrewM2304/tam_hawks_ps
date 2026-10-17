# HUD CPU efficiency — 17 October 2026

Owner: A01/A08 integration and UI; A09 final regression/hardware review. Scope: existing Main/HUD/Career presentation work. No frame-rate throttle, save-schema/reward change, new area, service or spend.

## Delivered change

Main previously built ten deep goal records, unlock arrays and repeated encounter status dictionaries on every rendered frame. HUD then deep-copied the whole state/settings, repeatedly formatted binding prompts, measured the same score text and recalculated unchanged feedback geometry. These are CPU presentation costs; they do not establish the cause of the owner's graphics stutter.

- Career exposes `presentation_revision() -> int` for **goals/unlocks only**, using exact comparison of score/combo, completed IDs and collection values against owned prior copies. Copies occur only on a source change. This notices load/reset/event/bank operations and direct fixture edits without hash collisions or Main reading Career private fields. Existing `goals_snapshot()` and `unlocks()` remain defensive public APIs. Settings/records update independently.
- Main caches those snapshots by career identity and revision, and builds each side encounter's status once per refresh for shared challenge/prompt selection. The authoritative 60Hz gameplay loop and immediate explicit `_refresh_hud()` calls remain.
- HUD skips an unchanged display snapshot when device, viewport, editable settings and required menu transition also agree. Changed nested arrays/dictionaries are detached; equal owned nested snapshots are retained. HUD-editable settings remain separate from caller data.
- Binding prompt formatting is cached by action/device/fallback and invalidated on bindings changes. Score fitting only repeats for changed text/width; feedback geometry only repeats for changed text or relayout. Balance-marker updates remain in the same call, with no 30Hz delay.
- Main sets physics interpolation **OFF** before building children, so only physics-driven actors explicitly opt in. Root owns the separate player/camera/project interpolation change; this document does not certify that integration.

## Matched warm CPU probe

Before is the unchanged `1b20e26` Main/HUD/Career checkpoint. After is the bounded HUD implementation before root adds graphics-quality settings. Both use the exact same ignored runner below, Godot **4.6.3 official**, Linux **headless** display, actual production Main/HUD with profile writes disabled, 200 warmup refreshes and **seven samples of 1,000 synchronous `_refresh_hud()` calls** per case. No other Godot process was running during these brief measurements. Times are **microseconds per refresh**, not milliseconds or rendered frame times.

| Case | Before median | After median | Absolute reduction | Relative reduction |
|---|---:|---:|---:|---:|
| Unchanged idle presentation | 268.035µs | 35.085µs | 232.950µs | 86.9% |
| Changing time/speed/manual balance | 258.357µs | 80.451µs | 177.906µs | 68.9% |

The absolute saving is about **0.18–0.23ms per refresh** on this host. That is useful removed overhead, and cannot by itself explain or fix severe multi-millisecond graphics stutter. The probe does not render pixels, advance gameplay between timed calls, measure GPU time, full UI canvas drawing, frame-time percentiles, allocation bytes, Mac performance or actual moving-route FPS. Its live-balance inputs are declared display fixtures rather than natural skating. Sample noise is retained below; there is no target-device speedup claim.

Raw per-refresh samples, in measurement order:

| Case | Before samples, µs | After samples, µs |
|---|---|---|
| Idle | 262.734, 309.766, 243.060, 364.532, 595.169, 237.153, 268.035 | 38.376, 36.068, 35.085, 34.621, 34.410, 35.218, 34.874 |
| Live balance | 263.381, 248.200, 288.799, 216.468, 258.357, 361.470, 215.999 | 80.851, 78.738, 82.441, 80.451, 86.579, 79.737, 80.235 |

Exact SHA-256 identities:

| Input | Before | After |
|---|---|---|
| `game/main.gd` | `a2d776bb408054406ea4b87a86eec44f5663614528ff9af1063bbcecaae2dfbb` | `6b5fe1dd670f251eb3d4c6a63bd49648ca6d86845cddb76b0653a10e6f640ad4` |
| `game/ui/hud.gd` | `b2cee1a0e2acaeaa6d88409bfa86851d6392dae2cbbfc45764ea85fcd5cfa493` | `43ca38afb928af0a1786930ac5603cd673eda2703ad013ae5a531c0bf573c67f` |
| `game/progression/career_progress.gd` | `174eb3864fd202a411f7cfc68458f0dea0260cb18ff3a9b2e1bdf558049e8a1b` | `8098f239c4abd44967f16afba6128dbf0e1c18b8082a51a1e6e6ec770c587b5b` |

Runner SHA-256: `ce1d24a2103eb21bb6a714d6ddce184ad16b677b43e4c41a52f4b42942a09623`. Raw checkpoint receipts/logs remain `.local/hud-efficiency-before.json`, `.local/hud-efficiency-after.json` and corresponding `.log` files; the complete numeric/source contents are preserved above. Later source changes need a fresh receipt before claiming the same exact checkpoint.

## Correctness evidence

`tests/hud_efficiency_tests.gd::run(tree,game,check)` passes **22/0**. Together with unchanged `ui_integration_tests.gd` and `ui_feedback_tests.gd`, the focused run passes **92/0**, exit 0, with a clean engine/script/error scan. The modules are also intended for the ordinary aggregate; do not add these focused counts to it. Log: `.local/hud-efficiency-integration.log`.

The checks exercise unchanged-refresh snapshot reuse, collection events, direct completed-ID edits, fresh-run progress clearing, score/rewards/records, duplicate events, loading a saved career on the same object, detached arbitrary nested state/settings, newly changed and removed nested values, actual side-encounter start/timer/feedback, immediate balance markers, remapped key/controller prompts, rejected local setting recovery, pause/resume/results and career-object replacement. The save/load check writes and removes only a unique `.local/hud-revision-*.json` regression fixture; Main never writes the player's profile. Existing UI tests retain real menu inputs, nested return/focus, long bindings, warning recovery, full-score fitting and constrained viewport checks.

Root owns the final complete production check and actual visual comparison. Existing menus/HUD are expected to look unchanged; this CPU-only focused probe does not substitute for their screenshots or the user's Mac replay. The broader renderer/draw-distance/interpolation work has its own evidence boundary in STATUS/PERFORMANCE.

## Reproduce the CPU probe

Save this exact runner as `.local/hud-efficiency-probe.gd`, then run `./tools/run.sh --headless --script .local/hud-efficiency-probe.gd -- .local/hud-efficiency-current.json`. Use an otherwise idle host and no concurrent game/render/test jobs. Source identities and raw samples are written into the JSON; recompute medians rather than comparing a single fastest sample.

```gdscript
extends SceneTree
const Main = preload("res://game/main.gd")
var game: Node
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	game = Main.new()
	game.persistence_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.skater.set_physics_process(false)
	game.skater.set_process(false)
	game.hud.hide_menu()
	game._feedback_timer = 0.0
	game._caption_time = 0.0
	game.time_remaining = 120.0
	var report := {"engine": Engine.get_version_info().string, "headless": DisplayServer.get_name(), "writes": game.persistence_enabled,
		"sources": {}, "warmup": 200, "samples": 7, "iterations": 1000, "cases": {}}
	for path: String in ["res://game/main.gd", "res://game/ui/hud.gd", "res://game/progression/career_progress.gd"]:
		report.sources[path] = FileAccess.get_sha256(path)
	for mode: String in ["idle", "live_balance"]:
		game.skater.manual_active = mode == "live_balance"
		for index in 200: _refresh(index, mode)
		var times: Array[float] = []
		for sample in 7:
			var begin := Time.get_ticks_usec()
			for index in 1000: _refresh(index, mode)
			times.append(float(Time.get_ticks_usec() - begin) / 1000.0)
		report.cases[mode] = times
	var output := ".local/hud-efficiency-before.json"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): output = args[0]
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit()
func _refresh(index: int, mode: String) -> void:
	if mode == "live_balance":
		game.time_remaining = 120.0 - float(index) / 60.0
		game.skater.speed = 8.0 + sin(float(index) * 0.02)
		game.skater.manual_balance = sin(float(index) * 0.03) * 0.6
	game._refresh_hud()
```
