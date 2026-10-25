extends RefCounted
## Exercise production main/HUD wiring with a player spy, never the user's Music.

class PlayerSpy extends Node:
	var requests: Array = []
	var sessions := 0
	var snapshots := 0

	func request(action: String, value: String = "") -> void:
		requests.append([action, value])

	func begin_session() -> void:
		sessions += 1

	func snapshot() -> Dictionary:
		snapshots += 1
		return {"supported": true, "connected": true, "playing": true,
			"title": "Integration fixture", "artist": "Fixture artist", "album": "Fixture album"}


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var original: Node = game.music
	var spy := PlayerSpy.new()
	game.music = spy
	game.hud.music_requested.emit("select", "ABCDEF0123456789")
	game.hud.music_requested.emit("next", "")
	check.call(spy.requests == [["select", "ABCDEF0123456789"], ["next", ""]],
		"soundtrack integration: actual HUD signals reach the player with unchanged arguments")
	game.start_mode(true)
	check.call(spy.sessions == 1 and game.free_skate_mode,
		"soundtrack integration: entering gameplay gives saved opt-in playback a session start")
	game.toggle_pause()
	check.call(tree.paused and spy.sessions == 1 and spy.requests.size() == 2,
		"soundtrack integration: pausing gameplay does not send pause or restart to Music")
	check.call(game.hud._state.music.title == "Integration fixture"
		and game.hud._state.music.playing,
		"soundtrack integration: paused main snapshots still supply current playback metadata")
	var snapshots_before := spy.snapshots
	for index in 10:
		game._refresh_hud()
	check.call(spy.snapshots == snapshots_before,
		"soundtrack integration: unchanged paused frames do not copy the playlist snapshot again")
	game.restart_run()
	check.call(not tree.paused and spy.sessions == 1 and spy.requests.size() == 2,
		"soundtrack integration: run restart preserves the soundtrack queue and current song")
	game.music = original
	spy.free()
	var saved_state: Dictionary = original.snapshot()
	var saved_track_key: String = original._track_key
	original._apply_result({"ok": true, "playing": true, "title": "Changed metadata fixture",
		"artist": "Changed artist", "album": "Changed album"}, "status")
	check.call(game.hud._state.music.title == "Changed metadata fixture",
		"soundtrack integration: a real player change event refreshes cached pause metadata immediately")
	original._state = saved_state
	original._track_key = saved_track_key
	original.changed.emit()
	game.start_mode(false)
