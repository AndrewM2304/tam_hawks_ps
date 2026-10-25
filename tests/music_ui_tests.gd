extends RefCounted
## UI fixtures exercise the real controls without Apple Events or music playback.

const HudSource = preload("res://game/ui/hud.gd")


static func run(tree: SceneTree, game: Node, check: Callable) -> void:
	var was_processing: bool = game.is_processing()
	var was_visible: bool = game.hud.visible
	game.set_process(false)
	game.hud.hide_menu()
	game.hud.visible = false
	var hud := HudSource.new()
	tree.root.add_child(hud)
	var requests: Array = []
	var pause_requests: Array = []
	hud.music_requested.connect(func(action: String, value: String): requests.append([action, value]))
	hud.pause_requested.connect(func(): pause_requests.append(true))
	var snapshot: Dictionary = game.hud._state.duplicate(true)
	snapshot.merge({"paused": true, "finished": false, "music": {
		"supported": false, "connected": false, "enabled": false,
		"status": "Unavailable", "playlists": [],
		"default_playlist_name": "Tony Hawk Pro Skater", "default_playlist_curator": "Alex Troyan",
		"default_playlist_url": "https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8",
	}}, true)
	hud.update_display(snapshot)
	hud.show_title()
	hud.show_soundtrack()
	await _frames(tree, 4)
	check.call(hud._music_controls.connect.disabled and hud._music_controls.playlist.disabled
		and hud._music_controls.status.text.contains("macOS"),
		"music UI: unsupported platforms explain availability and disable connection/playback")
	check.call(hud.is_menu_ready(), "music UI: unsupported setup keeps a visible focused Back control")
	check.call(hud._music_controls.open_default.disabled,
		"music UI: opening the supplied default playlist is unavailable on unsupported platforms")
	snapshot.music.supported = true
	hud.update_display(snapshot)
	check.call(not hud._music_controls.autoplay.disabled,
		"music UI: Mac autoplay preference remains available before connection or native playlist resolution")
	hud._music_controls.autoplay.button_pressed = true
	check.call(requests == [["enable", "true"]],
		"music UI: enabling autoplay before connection requests the user's preference")
	requests.clear()
	hud._back()
	await _frames(tree, 4)
	check.call(hud._page == "title" and pause_requests.is_empty(),
		"music UI: setup returns to title without starting or resuming gameplay")
	snapshot.music = {"supported": true, "connected": true, "playlist_id": "",
		"playlists": [{"id": "only", "name": "My only playlist"}]}
	hud.update_display(snapshot)
	hud.show_soundtrack()
	await _frames(tree, 4)
	check.call(hud._music_controls.playlist.selected == -1
		and hud._music_controls.playlist.text == "Choose playlist…"
		and hud._music_controls.play.disabled and requests.is_empty(),
		"music UI: a newly loaded sole playlist stays unselected until the user chooses it")
	# Exercise the OptionButton's real PopupMenu activation path. Merely emitting
	# item_selected would bypass the engine's same-item/reselection behavior.
	hud._music_controls.playlist.get_popup().index_pressed.emit(0)
	check.call(requests == [["select", "only"]],
		"music UI: choosing the first and only playlist emits its backend selection")
	hud._music_controls.playlist.get_popup().index_pressed.emit(0)
	check.call(requests == [["select", "only"], ["select", "only"]],
		"music UI: choosing the same first playlist again remains actionable")
	requests.clear()
	hud._back()
	await _frames(tree, 4)
	var image := Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color("486568"))
	var artwork := ImageTexture.create_from_image(image)
	snapshot.music = {
		"supported": true, "connected": true, "enabled": true, "playing": true,
		"busy": false, "status": "Connected to Music", "playlist_id": "punk",
		"playlist_name": "Skate playlist", "title": "Fixture track", "artist": "Fixture artist",
		"album": "Fixture album", "artwork": artwork,
		"default_playlist_name": "Tony Hawk Pro Skater", "default_playlist_curator": "Alex Troyan",
		"default_playlist_url": "https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8",
		"playlists": [{"id": "punk", "name": "Skate playlist"}, {"id": "other", "name": "Another playlist"}],
	}
	hud.update_display(snapshot)
	hud.show_soundtrack()
	await _frames(tree, 4)
	check.call(hud._music_controls.title.text == "Fixture track"
		and hud._music_controls.artist.text == "Fixture artist"
		and hud._music_controls.album.text == "Fixture album"
		and hud._music_controls.artwork.texture == artwork
		and not hud._music_controls.fallback.visible,
		"music UI: current song, artist, album and supplied artwork appear together")
	check.call(hud._music_controls.playlist.item_count == 2
		and hud._music_controls.playlist.get_item_metadata(hud._music_controls.playlist.selected) == "punk"
		and hud._music_controls.autoplay.button_pressed,
		"music UI: selected library playlist and autoplay reflect backend preferences")
	check.call(hud._music_controls.default_label.text == "Default: Tony Hawk Pro Skater · Alex Troyan"
		and hud._music_controls.playlist.get_item_metadata(hud._music_controls.playlist.selected) == "punk",
		"music UI: supplied default is identified separately from a manually selected playlist")
	hud._music_controls.open_default.pressed.emit()
	check.call(requests == [["open_default", ""]],
		"music UI: default playlist button requests opening the backend's exact supplied URL")
	requests.clear()
	var next_button: Button = hud._music_controls.next
	next_button.grab_focus()
	await _frames(tree, 1)
	var revision: int = hud._page_revision
	snapshot.music.title = "Next fixture track"
	snapshot.music.artist = "Another artist"
	snapshot.music.album = ""
	snapshot.music.artwork = null
	snapshot.music.playing = false
	hud.update_display(snapshot)
	await _frames(tree, 1)
	check.call(hud._page_revision == revision and hud._music_controls.next == next_button
		and tree.root.gui_get_focus_owner() == next_button,
		"music UI: polling metadata changes keeps the same controls and controller focus")
	check.call(hud._music_controls.title.text == "Next fixture track"
		and hud._music_controls.album.text.is_empty()
		and hud._music_controls.artwork.texture == null and hud._music_controls.fallback.visible
		and hud._music_controls.toggle.text == "PLAY MUSIC",
		"music UI: missing new-track artwork/album clears stale content and updates pause state")
	next_button.pressed.emit()
	hud._music_controls.toggle.pressed.emit()
	hud._music_controls.playlist.item_selected.emit(1)
	hud._music_controls.autoplay.button_pressed = false
	check.call(requests == [["next", ""], ["toggle", ""], ["select", "other"], ["enable", "false"]],
		"music UI: transport, playlist and autoplay controls emit exact backend requests")
	check.call(pause_requests.is_empty(), "music UI: soundtrack controls never toggle gameplay pause")
	hud._back()
	hud._show_page("pause")
	await _frames(tree, 4)
	check.call(hud._music_controls.title.text == "Next fixture track"
		and hud._music_controls.has("next") and not hud._music_controls.has("playlist"),
		"music UI: pause menu includes a compact live track card and skip control")
	snapshot.music.title = ""
	snapshot.music.artist = ""
	snapshot.music.album = ""
	snapshot.music.playing = true
	hud.update_display(snapshot)
	check.call(not hud._music_controls.next.disabled and not hud._music_controls.toggle.disabled
		and hud._music_controls.title.text == "Music is playing."
		and hud._music_controls.badge.text.begins_with("NOW PLAYING")
		and hud._music_controls.artist.text.contains("details unavailable")
		and hud._music_controls.album.text.is_empty(),
		"music UI: metadata-less streams retain transport controls without claiming a playlist source")
	hud._music_controls.next.pressed.emit()
	hud._music_controls.toggle.pressed.emit()
	check.call(requests.slice(4) == [["next", ""], ["toggle", ""]],
		"music UI: metadata-less playback can still request skip and pause")
	snapshot.music.connected = false
	snapshot.music.status = "Allow Music access in macOS Automation settings."
	snapshot.music.title = "Stale track after permission error"
	snapshot.music.artwork = artwork
	hud.update_display(snapshot)
	check.call(hud._music_controls.next.disabled and hud._music_controls.toggle.disabled
		and hud._music_controls.title.text == "Music is not connected."
		and hud._music_controls.artist.text == snapshot.music.status
		and hud._music_controls.album.text.is_empty() and hud._music_controls.artwork.texture == null,
		"music UI: disconnected pause card shows the connection error and clears stale playback claims")
	tree.root.remove_child(hud)
	hud.free()
	game.hud.visible = was_visible
	game.set_process(was_processing)
	game._refresh_hud()
	await _frames(tree, 3)


static func _frames(tree: SceneTree, count: int) -> void:
	for index: int in count: await tree.process_frame
