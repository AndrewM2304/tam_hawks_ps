extends Node
## Local Music.app remote control with the owner's chosen default soundtrack.
## No developer tokens or audio copying.
## Apple Events run off the game thread; tests never launch an external player.

signal changed

const PREFERENCES := "user://soundtrack.cfg"
const ARTWORK_PATH := "user://soundtrack-artwork.bin"
const POLL_SECONDS := 2.0
const MAX_PENDING := 4
const MAX_ARTWORK_BYTES := 8 * 1024 * 1024
const PROCESS_TIMEOUT_MS := 30000
const MAX_RESPONSE_BYTES := 1024 * 1024
const DEFAULT_PLAYLIST_URL := "https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8"
const DEFAULT_PLAYLIST_NAME := "Tony Hawk Pro Skater"
const DEFAULT_PLAYLIST_CURATOR := "Alex Troyan"

# Constant source and separate argv values keep playlist metadata out of code.
# Foundation serializes Unicode, quotes and line breaks without custom escaping.
const BRIDGE := """
use framework "Foundation"
use scripting additions

on putValue(container, fieldName, fieldValue)
    container's setObject:fieldValue forKey:fieldName
end putValue

on encodeJSON(container)
    set jsonData to current application's NSJSONSerialization's dataWithJSONObject:container options:0 |error|:(missing value)
    set jsonText to current application's NSString's alloc()'s initWithData:jsonData encoding:4
    return jsonText as text
end encodeJSON

on run argv
    set resultObject to current application's NSMutableDictionary's dictionary()
    try
        set actionName to item 1 of argv
        set selectedID to item 2 of argv
        set artPath to item 3 of argv
        set previousTrack to item 4 of argv
        with timeout of 12 seconds
            if actionName is "connect" or actionName is "play" then
                tell application id "com.apple.Music" to launch
            else if application id "com.apple.Music" is not running then
                error "Music is closed. Connect again to reopen it." number -600
            end if
            if actionName is "play" then
                tell application id "com.apple.Music"
                    set matches to every playlist whose persistent ID is selectedID
                    if (count matches) is 0 then error "That playlist is no longer in Music. Refresh the playlist list." number -1728
                    set chosenPlaylist to item 1 of matches
                    if (count tracks of chosenPlaylist) is 0 then error "That playlist has no available songs." number -1728
                    set shuffle mode to songs
                    set shuffle enabled to true
                    if shuffle enabled is false then error "Music did not enable shuffle. Enable Shuffle in Music, then try again." number -1708
                    set song repeat to all
                    play chosenPlaylist
                    -- Advance inside this playlist's shuffled queue, including
                    -- when Music had retained an old start position.
                    if (count tracks of chosenPlaylist) > 1 then next track
                end tell
            else if actionName is "next" then
                tell application id "com.apple.Music" to next track
            else if actionName is "toggle" then
                tell application id "com.apple.Music" to playpause
            end if
            if actionName is "connect" or actionName is "refresh" then
                set playlistObjects to current application's NSMutableArray's array()
                tell application id "com.apple.Music"
                    -- Curated playlists saved from Apple Music use a distinct
                    -- subscription playlist class, rather than user playlist.
                    set availablePlaylists to (every user playlist) & (every subscription playlist)
                    repeat with candidate in availablePlaylists
                        if class of candidate is not folder playlist then
                            set entryObject to current application's NSMutableDictionary's dictionary()
                            my putValue(entryObject, "id", persistent ID of candidate as text)
                            my putValue(entryObject, "name", name of candidate as text)
                            playlistObjects's addObject:entryObject
                        end if
                    end repeat
                end tell
                my putValue(resultObject, "playlists", playlistObjects)
            end if
            set trackTitle to ""
            set trackArtist to ""
            set trackAlbum to ""
            set trackKey to ""
            set currentPlaylistID to ""
            set isPlaying to false
            set isShuffled to false
            set hasCurrentTrack to false
            tell application id "com.apple.Music"
                set isPlaying to (player state is playing)
                try
                    set isShuffled to shuffle enabled
                end try
                if player state is not stopped then
                    set hasCurrentTrack to true
                    try
                        set currentPlaylistID to persistent ID of current playlist as text
                    end try
                    -- Some macOS versions omit properties for catalog streams.
                    -- One missing field must not discard the remaining fields.
                    try
                        set trackTitle to name of current track as text
                    end try
                    try
                        set trackArtist to artist of current track as text
                    end try
                    try
                        set trackAlbum to album of current track as text
                    end try
                    try
                        set trackKey to persistent ID of current track as text
                    end try
                end if
            end tell
            if trackKey is "" and hasCurrentTrack then set trackKey to trackTitle & "|" & trackArtist & "|" & trackAlbum
            my putValue(resultObject, "playing", isPlaying)
            my putValue(resultObject, "shuffle", isShuffled)
            my putValue(resultObject, "title", trackTitle)
            my putValue(resultObject, "artist", trackArtist)
            my putValue(resultObject, "album", trackAlbum)
            my putValue(resultObject, "track_key", trackKey)
            my putValue(resultObject, "current_playlist_id", currentPlaylistID)
            my putValue(resultObject, "artwork_changed", (trackKey is not previousTrack))
            if trackKey is not previousTrack then
                set hasArtwork to false
                set artFile to missing value
                try
                    if not hasCurrentTrack then error "No current track."
                    tell application id "com.apple.Music"
                        set artData to raw data of artwork 1 of current track
                    end tell
                    set artFile to open for access (POSIX file artPath) with write permission
                    set eof artFile to 0
                    write artData to artFile
                    close access artFile
                    set artFile to missing value
                    set hasArtwork to true
                on error
                    if artFile is not missing value then
                        try
                            close access artFile
                        end try
                    end if
                end try
                my putValue(resultObject, "artwork_available", hasArtwork)
            end if
        end timeout
        my putValue(resultObject, "ok", true)
    on error errorText number errorNumber
        my putValue(resultObject, "ok", false)
        my putValue(resultObject, "error", errorText)
        my putValue(resultObject, "code", errorNumber)
    end try
    return my encodeJSON(resultObject)
end run
"""

var _state: Dictionary = {
	"supported": false, "enabled": false, "connected": false, "busy": false,
	"status": "Connect to the Music app to choose a soundtrack.",
	"playlists": [], "playlist_id": "", "playlist_name": "",
	"title": "", "artist": "", "album": "", "playing": false,
	"artwork": null, "shuffle": false,
	"current_playlist_id": "",
	"default_playlist_url": DEFAULT_PLAYLIST_URL,
	"default_playlist_name": DEFAULT_PLAYLIST_NAME,
	"default_playlist_curator": DEFAULT_PLAYLIST_CURATOR,
}
var _can_control := false
var _persist := false
var _worker: Thread
var _pending: Array[Dictionary] = []
var _poll_remaining := POLL_SECONDS
var _track_key := ""
var _generation := 0
var _worker_generation := 0
var _worker_action := ""
var _notice := ""
var _autoplay_after_connect := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func configure(persistence_enabled: bool) -> void:
	_state.supported = OS.get_name() == "macOS"
	_persist = persistence_enabled and not OS.get_cmdline_args().has("--script")
	_can_control = _state.supported and _persist
	if not _state.supported:
		_state.status = "Apple Music control is available on macOS."
	elif not _can_control:
		_state.status = "Music control is disabled in automated/scripted runs."
	else:
		# The owner explicitly chose this playlist and requested automatic music.
		# A saved off/disconnect preference below always takes precedence.
		_state.enabled = true
		_state.playlist_name = DEFAULT_PLAYLIST_NAME
		_load_preferences()
	changed.emit()


func snapshot() -> Dictionary:
	return _state.duplicate(true)


func begin_session() -> void:
	if not _can_control or not _state.enabled:
		return
	if str(_state.playlist_id).is_empty():
		_autoplay_after_connect = true
		request("connect")
		return
	_autoplay_after_connect = false
	# Restarting a run must not restart the current song or shuffled queue.
	if _state.connected and _state.playing and _state.current_playlist_id == _state.playlist_id:
		return
	request("play")


func request(action: String, value: String = "") -> void:
	if not _can_control:
		return
	match action:
		"open_default":
			if OS.create_process("/usr/bin/open", PackedStringArray(["-a", "Music", DEFAULT_PLAYLIST_URL])) < 0:
				_state.status = "Could not open the default playlist. Open it in the Music app, then refresh."
			changed.emit()
			return
		"disconnect":
			_generation += 1
			_pending.clear()
			_state.connected = false
			_state.enabled = false
			_state.status = "Disconnected. Music keeps playing in the Music app."
			_notice = ""
			_autoplay_after_connect = false
			_clear_track()
			_save_preferences()
			changed.emit()
			return
		"enable":
			_state.enabled = value == "true"
			if not _state.enabled:
				_autoplay_after_connect = false
			_save_preferences()
			changed.emit()
			return
		"select":
			for entry: Dictionary in _state.playlists:
				if str(entry.get("id", "")) == value:
					_state.playlist_id = value
					_state.playlist_name = str(entry.get("name", ""))
					_state.status = "Ready to shuffle " + str(_state.playlist_name) + "."
					_notice = ""
					_autoplay_after_connect = false
					_save_preferences()
					changed.emit()
					return
			_state.status = "Refresh playlists, then choose one from your Music library."
			changed.emit()
			return
		"connect", "refresh", "play", "toggle", "next":
			pass
		_:
			return
	if action != "connect" and action != "play" and not _state.connected:
		_state.status = "Connect to the Music app first."
		changed.emit()
		return
	if action == "play" and str(_state.playlist_id).is_empty():
		_state.status = "Choose a playlist from your Music library first."
		changed.emit()
		return
	_enqueue(action)


func _process(delta: float) -> void:
	if _worker != null and not _worker.is_alive():
		var result: Dictionary = _worker.wait_to_finish()
		_worker = null
		_state.busy = false
		if _worker_generation == _generation:
			_apply_result(result, _worker_action)
	if _worker == null and not _pending.is_empty():
		_start(_pending.pop_front().action)
		return
	if not _can_control or not _state.connected or _worker != null:
		return
	_poll_remaining -= maxf(delta, 0.0)
	if _poll_remaining <= 0.0:
		_start("status")


func _enqueue(action: String) -> void:
	if _worker == null:
		_start(action)
		return
	# Keep control clicks received during a status poll. The bounded queue also
	# prevents held/repeated controls creating an unbounded external command list.
	if action in ["connect", "refresh"]:
		if _worker_action == action:
			return
		for command: Dictionary in _pending:
			if command.action == action:
				return
	if _pending.size() >= MAX_PENDING:
		_state.status = "Music is busy. Wait a moment, then try again."
		changed.emit()
		return
	_pending.append({"action": action})


func _start(action: String) -> void:
	if action != "status":
		_notice = ""
	_worker = Thread.new()
	_worker_action = action
	_worker_generation = _generation
	_poll_remaining = POLL_SECONDS
	_state.busy = true
	var task := _execute.bind(action, str(_state.playlist_id),
		ProjectSettings.globalize_path(ARTWORK_PATH), _track_key)
	var error := _worker.start(task)
	if error != OK:
		_worker = null
		_state.busy = false
		_state.status = "Could not start Music control. Reconnect to try again."
	changed.emit()


static func _execute(action: String, playlist_id: String, artwork_path: String, track_key: String) -> Dictionary:
	# Nonblocking pipes let this worker enforce a wall-clock deadline as well as
	# AppleScript's per-event timeout (consent/sign-in can outlast an event).
	var pipes := OS.execute_with_pipe("/usr/bin/osascript",
		PackedStringArray(["-e", BRIDGE, action, playlist_id, artwork_path, track_key]), false)
	if pipes.is_empty():
		return {"ok": false, "error": "Could not open Music control. Reconnect to try again.", "transport_failure": true}
	var output := PackedByteArray()
	var started := Time.get_ticks_msec()
	while true:
		output.append_array(pipes.stdio.get_buffer(65536))
		# Drain stderr too, so a diagnostic cannot fill its pipe and block exit.
		pipes.stderr.get_buffer(65536)
		if output.size() > MAX_RESPONSE_BYTES:
			OS.kill(pipes.pid)
			return {"ok": false, "error": "Music returned too many playlists. Reduce the library list, then reconnect.", "transport_failure": true}
		if not OS.is_process_running(pipes.pid):
			var tail: PackedByteArray = pipes.stdio.get_buffer(65536)
			while not tail.is_empty() and output.size() <= MAX_RESPONSE_BYTES:
				output.append_array(tail)
				tail = pipes.stdio.get_buffer(65536)
			break
		if Time.get_ticks_msec() - started >= PROCESS_TIMEOUT_MS:
			OS.kill(pipes.pid)
			return {"ok": false, "error": "Music did not respond.", "code": -1712}
		OS.delay_msec(20)
	var exit_code := OS.get_process_exit_code(pipes.pid)
	if exit_code != 0:
		return {"ok": false, "error": "Music control failed. Reconnect after checking Music and Automation permissions.", "code": exit_code, "transport_failure": true}
	var parsed: Variant = JSON.parse_string(output.get_string_from_utf8().strip_edges())
	if not parsed is Dictionary:
		return {"ok": false, "error": "Music returned an unreadable response. Reconnect to try again.", "code": 0, "transport_failure": true}
	return parsed


func _apply_result(result: Dictionary, action: String) -> void:
	if not result.get("ok", false):
		var code := int(result.get("code", 0))
		_state.status = _error_message(code, str(result.get("error", "Music control failed. Reconnect to try again.")))
		_notice = _state.status
		if code in [-1743, -1712, -600] or action == "connect" or result.get("transport_failure", false):
			_state.connected = false
			_pending.clear()
			_clear_track()
		changed.emit()
		return
	_state.connected = true
	var default_notice := ""
	if result.get("playlists") is Array:
		var entries: Array[Dictionary] = []
		for item: Variant in result.playlists:
			if item is Dictionary and _valid_playlist_id(str(item.get("id", ""))):
				entries.append({"id": str(item.id), "name": str(item.get("name", "Untitled playlist"))})
		_state.playlists = entries
		default_notice = _resolve_default_playlist()
		# Persistent IDs, rather than editable/nonunique names, identify selections.
		for entry: Dictionary in entries:
			if entry.id == _state.playlist_id:
				_state.playlist_name = entry.name
	for key in ["title", "artist", "album"]:
		_state[key] = str(result.get(key, ""))
	_state.playing = bool(result.get("playing", false))
	_state.shuffle = bool(result.get("shuffle", false))
	_state.current_playlist_id = str(result.get("current_playlist_id", ""))
	_track_key = str(result.get("track_key", ""))
	if result.get("artwork_changed", false):
		_state.artwork = _load_artwork() if result.get("artwork_available", false) else null
	if _state.playing:
		_state.status = "Playing from Music" + (" · Shuffle on" if _state.shuffle else " · Shuffle off")
		if str(_state.title).is_empty():
			_state.status += ". Add the playlist songs to your Music library for track details."
	elif not str(_state.title).is_empty():
		_state.status = "Music paused."
	elif action in ["connect", "refresh"] and _state.playlists.is_empty():
		_state.status = "No playlists found. Add a playlist to your Music library, then refresh."
	else:
		_state.status = "Connected. Choose a playlist, then shuffle and play."
	if not default_notice.is_empty():
		_notice = default_notice
		_state.status = default_notice
	if action == "status" and not _notice.is_empty():
		_state.status = _notice
	changed.emit()
	if _autoplay_after_connect and _state.enabled and not str(_state.playlist_id).is_empty() and action in ["connect", "refresh"]:
		_autoplay_after_connect = false
		begin_session()


func _resolve_default_playlist() -> String:
	# Public pl.u tokens identify web playlists; only Music's native persistent ID
	# can select a local playback queue. Never substitute one for the other.
	if not str(_state.playlist_id).is_empty():
		return ""
	var matches: Array[Dictionary] = []
	for entry: Dictionary in _state.playlists:
		if str(entry.name).strip_edges().nocasecmp_to(DEFAULT_PLAYLIST_NAME) == 0:
			matches.append(entry)
	if matches.size() == 1:
		_state.playlist_id = matches[0].id
		_state.playlist_name = matches[0].name
		_save_preferences()
		return ""
	if matches.size() > 1:
		return "More than one playlist is named “%s”. Choose the intended one from the playlist list." % DEFAULT_PLAYLIST_NAME
	return "Add “%s” by %s to your Music library using Open default playlist, then refresh." % [DEFAULT_PLAYLIST_NAME, DEFAULT_PLAYLIST_CURATOR]


static func _error_message(code: int, fallback: String) -> String:
	if code == -1743:
		return "Allow Music control in System Settings → Privacy & Security → Automation, then reconnect."
	if code == -1712:
		return "Music did not respond. Finish any Music sign-in or permission dialog, then reconnect."
	return fallback.left(500)


static func _valid_playlist_id(value: String) -> bool:
	return value.length() == 16 and value.is_valid_hex_number(false)


func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(PREFERENCES) != OK:
		return
	_apply_preferences(config)


func _apply_preferences(config: ConfigFile) -> void:
	# Autoplay off must survive even if the playlist has not been added yet.
	if config.has_section_key("soundtrack", "enabled"):
		var enabled: Variant = config.get_value("soundtrack", "enabled", false)
		_state.enabled = enabled if enabled is bool else false
	var id := str(config.get_value("soundtrack", "playlist_id", ""))
	if not _valid_playlist_id(id):
		return
	_state.playlist_id = id
	_state.playlist_name = str(config.get_value("soundtrack", "playlist_name", "")).left(500)


func _save_preferences() -> void:
	if not _persist:
		return
	var config := ConfigFile.new()
	config.set_value("soundtrack", "enabled", _state.enabled)
	config.set_value("soundtrack", "playlist_id", _state.playlist_id)
	config.set_value("soundtrack", "playlist_name", _state.playlist_name)
	if config.save(PREFERENCES) != OK:
		_state.status = "Soundtrack preferences could not be saved. This session still works."


func _load_artwork() -> Texture2D:
	var file := FileAccess.open(ARTWORK_PATH, FileAccess.READ)
	if file == null or file.get_length() > MAX_ARTWORK_BYTES:
		return null
	var bytes := file.get_buffer(file.get_length())
	return _decode_artwork(bytes)


static func _decode_artwork(bytes: PackedByteArray) -> Texture2D:
	var image := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	if bytes.size() >= 3 and bytes[0] == 0xff and bytes[1] == 0xd8 and bytes[2] == 0xff:
		error = image.load_jpg_from_buffer(bytes)
	elif bytes.size() >= 8 and bytes.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		error = image.load_png_from_buffer(bytes)
	if error != OK or image.is_empty():
		return null
	# Bound the in-game texture independently of a Music library image's size.
	if maxi(image.get_width(), image.get_height()) > 512:
		var ratio := 512.0 / maxi(image.get_width(), image.get_height())
		image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _clear_track() -> void:
	for key in ["title", "artist", "album"]:
		_state[key] = ""
	_state.artwork = null
	_state.playing = false
	_state.current_playlist_id = ""
	_track_key = ""


func _exit_tree() -> void:
	# Music playback belongs to Music.app and intentionally survives game exit.
	# A 30-second wall-clock deadline bounds the sole worker; none outlives Node.
	if _worker != null:
		_worker.wait_to_finish()
		_worker = null
