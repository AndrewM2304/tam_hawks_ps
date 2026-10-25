extends SceneTree
## Real rendered soundtrack layout using explicitly synthetic metadata/artwork.
## No Apple Music connection, playback, account access or profile writes occur.

const HudSource = preload("res://game/ui/hud.gd")
const OUTPUT := "res://docs/testing/screenshots/apple-music"
var hud: CanvasLayer
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Soundtrack capture requires a rendering display.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	hud = HudSource.new()
	root.add_child(hud)
	var image := Image.create(128, 128, false, Image.FORMAT_RGB8)
	image.fill(Color("42615c"))
	for y: int in range(128):
		for x: int in range(128):
			if absi(x - y) < 12 or absi(x + y - 127) < 12:
				image.set_pixel(x, y, Color("d8ef96"))
	var snapshot := {"paused": true, "finished": false, "score": 12500, "best": 3600,
		"settings": {"ui_scale": 1.4, "reduced_motion": true},
		"music": {"supported": true, "connected": true, "enabled": true, "playing": true,
			"busy": false, "status": "UI FIXTURE • No account connected or music playing.",
			"title": "A song for the long way home", "artist": "The Fictional Skate Band",
			"album": "Synthetic artwork & metadata fixture", "playlist_id": "fixture-punk",
			"playlist_name": "My skate punk playlist",
			"default_playlist_name": "Tony Hawk Pro Skater", "default_playlist_curator": "Alex Troyan",
			"default_playlist_url": "https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8",
			"artwork": ImageTexture.create_from_image(image),
			"playlists": [{"id": "fixture-punk", "name": "My skate punk playlist"},
				{"id": "fixture-other", "name": "Another library playlist"}]}}
	_set_size(Vector2i(1920, 1080))
	hud.update_display(snapshot)
	await _save_frame("pause-1080-large-fixture", "pause")
	await _save_frame("setup-1080-large-fixture", "soundtrack", "music:open_default")
	_set_size(Vector2i(960, 600))
	hud.update_display(snapshot)
	await _save_frame("pause-960-large-fixture", "pause")
	await _save_frame("setup-960-large-fixture", "soundtrack", "music:open_default")
	snapshot.music = {"supported": false, "connected": false, "playlists": []}
	hud.update_display(snapshot)
	await _save_frame("unsupported-960-large-fixture", "soundtrack")
	print("MUSIC UI CAPTURE RESULT: %d failures; synthetic metadata/artwork only; no playback or profile writes" % failures)
	quit(1 if failures > 0 else 0)


func _set_size(value: Vector2i) -> void:
	root.size = value
	root.content_scale_size = value


func _save_frame(label: String, page: String, focus_token: String = "") -> void:
	hud._show_page(page, focus_token)
	for index: int in 8: await process_frame
	await RenderingServer.frame_post_draw
	if not hud.is_menu_ready():
		failures += 1
		push_error("Soundtrack capture dialog is out of bounds or unfocused: " + label)
		return
	var result := root.get_texture().get_image().save_png(OUTPUT.path_join(label + ".png"))
	if result != OK: failures += 1
	print("MUSIC UI CAPTURE %s result=%d" % [label, result])
