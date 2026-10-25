extends RefCounted
## Linux checks exercise opt-in isolation, queueing and metadata handling.
## Real Music playback, macOS consent and AppleScript compilation need a Mac.

const Music = preload("res://game/audio/apple_music.gd")
const PLAYLIST_ID := "ABCDEF0123456789"

class PreferenceSpy extends Music:
	var preference_reads := 0
	func _load_preferences() -> void: preference_reads+=1


static func run(tree: SceneTree, check: Callable) -> void:
	check.call(Music.is_scripted_launch(PackedStringArray(["--script", "res://fixture.gd"]))
		and Music.is_scripted_launch(PackedStringArray(["-s", "res://fixture.gd"]))
		and Music.is_scripted_launch(PackedStringArray(["--script=res://fixture.gd"])),
		"soundtrack: every script option spelling blocks profile access and external Music control")
	check.call(not Music.is_scripted_launch(PackedStringArray(["--path", "/tmp/game", "--", "--script", "a song"]))
		and not Music.is_scripted_launch(PackedStringArray(["--scripted-playlist", "res://a-script.gd"]))
		and not Music.is_scripted_launch(PackedStringArray()),
		"soundtrack: ordinary launches and user metadata preserve the owner's normal playback choice")
	var music = Music.new()
	music.configure(false)
	tree.root.add_child(music)
	music.set_process(false)
	check.call(not music.snapshot().enabled and not music.snapshot().connected,
		"soundtrack: automated runs stay disconnected with default autoplay disabled")
	for action in ["connect", "play", "refresh", "toggle", "next", "enable", "open_default"]:
		music.request(action, "true")
	music.begin_session()
	check.call(music._worker == null and music._pending.is_empty() and not music.snapshot().enabled,
		"soundtrack: scripted/no-persistence runs cannot launch Music, control playback or save opt-in")
	check.call(music.snapshot().supported == (OS.get_name() == "macOS"),
		"soundtrack: platform capability is separate from automated-run permission")
	var returned: Dictionary = music.snapshot()
	returned.playlists.append({"id": PLAYLIST_ID, "name": "changed copy"})
	check.call(music.snapshot().playlists.is_empty(),
		"soundtrack: callers cannot mutate internal playlist data through a snapshot")
	check.call(Music._valid_playlist_id(PLAYLIST_ID) and not Music._valid_playlist_id("Rock \"Punk\" ")
		and not Music._valid_playlist_id("../soundtrack.cfg"),
		"soundtrack: saved playlist identity accepts Music persistent IDs only")
	var name := "Skate \"punk\"\n& friends — Glasgow"
	music._apply_result({"ok": true, "playlists": [{"id": PLAYLIST_ID, "name": name},
		{"id": "invalid", "name": "bad ID"}], "playing": true, "shuffle": true,
		"title": "Song \"A\"\nPart II", "artist": "An artist", "album": "An album",
		"track_key": "TRACK_A", "artwork_changed": true, "artwork_available": false}, "connect")
	var state: Dictionary = music.snapshot()
	check.call(state.playlists.size() == 1 and state.playlists[0].name == name
		and state.title == "Song \"A\"\nPart II" and state.artist == "An artist" and state.album == "An album",
		"soundtrack: Unicode, quotes and newlines survive playlist and now-playing metadata")
	check.call(state.playing and state.shuffle and state.artwork == null,
		"soundtrack: missing catalog artwork keeps playback metadata and exposes a clear fallback")
	music._can_control = true
	music.request("select", PLAYLIST_ID)
	music.request("enable", "true")
	check.call(music.snapshot().playlist_id == PLAYLIST_ID and music.snapshot().playlist_name == name
		and music.snapshot().enabled,
		"soundtrack: selection uses persistent ID while retaining the full display name")
	music._worker = Thread.new() # An idle stand-in; never starts an OS process.
	music._state.current_playlist_id = "1111111111111111"
	music.begin_session()
	check.call(music._pending.size() == 1 and music._pending[0].action == "play",
		"soundtrack: autoplay replaces an unrelated playing playlist with the selected playlist")
	music._pending.clear()
	music._state.current_playlist_id = PLAYLIST_ID
	music.begin_session()
	check.call(music._pending.is_empty(),
		"soundtrack: entering a mode preserves a song already playing from the selected playlist")
	for i in 7:
		music._enqueue("next")
	check.call(music._pending.size() == Music.MAX_PENDING,
		"soundtrack: clicks during polling are retained in a bounded command queue")
	music._worker = null
	music._apply_result({"ok": false, "code": -1743, "error": "denied"}, "status")
	check.call(not music.snapshot().connected and music._pending.is_empty()
		and "Automation" in music.snapshot().status,
		"soundtrack: denied Automation stops polling/queued controls and explains how to reconnect")
	music._apply_result({"ok": true, "playing": false, "title": "", "artist": "", "album": "",
		"artwork_changed": true, "artwork_available": false}, "status")
	check.call(music.snapshot().title.is_empty() and music.snapshot().artwork == null,
		"soundtrack: stopped/unknown tracks cannot leave stale song text or artwork")
	music.request("disconnect")
	check.call(not music.snapshot().connected and not music.snapshot().enabled
		and music._worker == null and "keeps playing" in music.snapshot().status,
		"soundtrack: disconnect disables future autoplay without sending pause to Music")
	check.call("permission dialog" in Music._error_message(-1712, "timeout"),
		"soundtrack: a bounded Apple Event timeout gives a recoverable sign-in/consent message")
	check.call(Music._decode_artwork(PackedByteArray([1, 2, 3, 4])) == null,
		"soundtrack: unavailable/unrecognized artwork uses the UI fallback")
	var image := Image.create(1024, 640, false, Image.FORMAT_RGB8)
	image.fill(Color("293b4b"))
	var artwork: Texture2D = Music._decode_artwork(image.save_png_to_buffer())
	check.call(artwork != null and artwork.get_size() == Vector2(512, 320),
		"soundtrack: real PNG artwork decodes and bounds its texture to 512 pixels")
	music._can_control = false
	tree.root.remove_child(music)
	music.free()
	_test_default_playlist(check)


static func _test_default_playlist(check: Callable) -> void:
	var music = PreferenceSpy.new()
	music.configure(true) # Script runners must stay inert even with persistence requested.
	var isolated: bool = not music._can_control and not music._persist and not music.snapshot().enabled and music.preference_reads==0
	check.call(isolated,
		"soundtrack: requesting persistence cannot enable Music in an automated script")
	if not isolated:
		music.free()
		return
	check.call(music.snapshot().default_playlist_url == "https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8"
		and music.snapshot().default_playlist_name == "Tony Hawk Pro Skater"
		and not Music._valid_playlist_id("pl.u-jV89Dq9t27eY8"),
		"soundtrack: exact owner-supplied playlist link stays separate from native library IDs")
	music._apply_result({"ok": true, "playlists": []}, "connect")
	check.call(music.snapshot().playlist_id.is_empty()
		and "Add “Tony Hawk Pro Skater”" in music.snapshot().status,
		"soundtrack: missing default playlist explains adding it to Music then refreshing")
	music._apply_result({"ok": true, "playlists": [
		{"id": PLAYLIST_ID, "name": Music.DEFAULT_PLAYLIST_NAME},
		{"id": "1111111111111111", "name": Music.DEFAULT_PLAYLIST_NAME}]}, "refresh")
	check.call(music.snapshot().playlist_id.is_empty() and "More than one" in music.snapshot().status,
		"soundtrack: duplicate default playlist titles require selection instead of guessing")
	music._apply_result({"ok": true, "playlists": [
		{"id": PLAYLIST_ID, "name": "tony hawk pro skater"}]}, "refresh")
	check.call(music.snapshot().playlist_id == PLAYLIST_ID
		and music.snapshot().playlist_name == "tony hawk pro skater",
		"soundtrack: one exact default title resolves to its native persistent ID")
	music._state.playlist_name = "My chosen soundtrack"
	music._apply_result({"ok": true, "playlists": [
		{"id": "1111111111111111", "name": Music.DEFAULT_PLAYLIST_NAME}]}, "refresh")
	check.call(music.snapshot().playlist_id == PLAYLIST_ID
		and music.snapshot().playlist_name == "My chosen soundtrack",
		"soundtrack: default discovery cannot override a saved or manually selected playlist")
	music._state.playlist_id = ""
	music._state.enabled = true
	var config := ConfigFile.new()
	config.parse("[soundtrack]\nenabled=false\nplaylist_id=\"\"\n")
	music._apply_preferences(config)
	check.call(not music.snapshot().enabled and music.snapshot().playlist_id.is_empty(),
		"soundtrack: saved autoplay off survives an unresolved or empty playlist ID")
	music._state.enabled = true
	config.parse("[soundtrack]\nenabled=\"true\"\nplaylist_id=\"pl.u-jV89Dq9t27eY8\"\n")
	music._apply_preferences(config)
	check.call(not music.snapshot().enabled and music.snapshot().playlist_id.is_empty(),
		"soundtrack: invalid saved autoplay types and web tokens cannot authorize playback")
	music._can_control = true
	music._worker = Thread.new() # Queues only; no external Music or browser process.
	music._worker_action = "status"
	music.begin_session()
	check.call(music._pending.is_empty(),
		"soundtrack: entering play with a saved off preference never connects to Music")
	music._state.enabled = true
	music.begin_session()
	check.call(music._pending.size() == 1 and music._pending[0].action == "connect",
		"soundtrack: unresolved default autoplay connects and enumerates before selecting a queue")
	music._pending.clear()
	music._apply_result({"ok": true, "playlists": [
		{"id": PLAYLIST_ID, "name": Music.DEFAULT_PLAYLIST_NAME}]}, "connect")
	check.call(music._pending.size() == 1 and music._pending[0].action == "play"
		and music.snapshot().playlist_id == PLAYLIST_ID,
		"soundtrack: default autoplay queues playback only after a unique native playlist match")
	music._pending.clear()
	music._state.playlist_id = ""
	music._autoplay_after_connect = true
	music._apply_result({"ok": true, "playlists": [
		{"id": PLAYLIST_ID, "name": Music.DEFAULT_PLAYLIST_NAME}],
		"playing": true, "current_playlist_id": PLAYLIST_ID}, "connect")
	check.call(music._pending.is_empty(),
		"soundtrack: default discovery preserves an already playing song from the matching playlist")
	music._worker = null
	music.free()
