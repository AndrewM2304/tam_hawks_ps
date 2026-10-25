extends RefCounted
## Exercise production main/HUD wiring with a player spy, never the user's Music.

class PlayerSpy extends Node:
	var requests: Array = []
	var sessions := 0

	func request(action: String, value: String = "") -> void:
		requests.append([action, value])

	func begin_session() -> void:
		sessions += 1

	func snapshot() -> Dictionary:
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
	game.restart_run()
	check.call(not tree.paused and spy.sessions == 1 and spy.requests.size() == 2,
		"soundtrack integration: run restart preserves the soundtrack queue and current song")
	game.music = original
	spy.free()
	game.start_mode(false)
