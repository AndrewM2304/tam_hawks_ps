extends Node
## Original PCM synthesis and licensed pre-generated barks; no runtime plugins/network.

signal caption(text: String)

const SAMPLE_RATE := 22050
const EVENT_VOICES := 3
const SILENT_DB := -80.0
const EVENTS := {
	"ollie": [0.18, 0.10], "landing": [0.24, 0.12], "grind": [0.14, 0.18],
	"bail": [0.48, 0.45], "bank": [0.46, 0.18], "ui": [0.09, 0.07],
}
const BARKS := {"landing": "Some landing.", "cone": "Mind the cone.", "again": "One more run."}
static var _streams: Dictionary = {}
static var _bark_streams: Dictionary = {}

var _sfx := 0.8
var _ambience := 0.55
var _speed := 0.0
var _grounded := false
var _grinding := false
var _paused := false
var _surface := "stone"
var _district := "exchange"
var _elapsed := 0.0
var _roll_level := 0.0
var _grind_level := 0.0
var _roll: AudioStreamPlayer
var _grind: AudioStreamPlayer
var _beds: Array[AudioStreamPlayer] = []
var _bed_levels := [1.0, 0.0]
var _bed_targets := [1.0, 0.0]
var _voices: Array[AudioStreamPlayer] = []
var _voice_remaining: Array[float] = []
var _ui: AudioStreamPlayer
var _bark: AudioStreamPlayer
var _last_bark_time := -100.0
var _last_bark_by_id: Dictionary = {}
var _bark_counts: Dictionary = {}
var _last_event: Dictionary = {}
var _event_counts: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_bank()
	_roll = _make_player("roll_" + _surface)
	_grind = _make_player("grind_loop")
	_beds.append(_make_player("amb_" + _district))
	_beds.append(_make_player("amb_" + _district))
	for i in range(EVENT_VOICES):
		_voices.append(_make_player("landing", false))
		_voice_remaining.append(0.0)
	_ui = _make_player("ui", false)
	_bark = _make_player("ui", false)
	_apply_levels()
	set_paused(_paused)


func _exit_tree() -> void:
	for player in get_children():
		if player is AudioStreamPlayer:
			player.stop()


func set_mix(sfx: float, ambience: float) -> void:
	_sfx = clampf(sfx, 0.0, 1.0) if is_finite(sfx) else 0.0
	_ambience = clampf(ambience, 0.0, 1.0) if is_finite(ambience) else 0.0
	if is_instance_valid(_roll):
		_apply_levels()


func set_motion(speed: float, grounded: bool, grinding: bool, district: String) -> void:
	_speed = clampf(absf(speed), 0.0, 40.0) if is_finite(speed) else 0.0
	_grounded = grounded
	_grinding = grinding
	var next_district := _district_key(district)
	if next_district != _district:
		_district = next_district
		if not _beds.is_empty():
			# Reuse the quieter channel; rapid border changes never create more voices.
			var slot := 0 if _bed_levels[0] < _bed_levels[1] else 1
			_beds[slot].stream = _streams["amb_" + _district]
			_bed_levels[slot] = 0.0
			_bed_targets = [0.0, 0.0]
			_bed_targets[slot] = 1.0
			_beds[slot].volume_db = SILENT_DB
			_start_player(_beds[slot])
			_beds[slot].stream_paused = _paused


func set_surface(surface: String) -> void:
	var next_surface := surface.to_lower()
	if next_surface not in ["stone", "asphalt", "metal"]:
		next_surface = "stone"
	if next_surface == _surface:
		return
	_surface = next_surface
	if is_instance_valid(_roll):
		_roll.stream = _streams["roll_" + _surface]
		_roll.volume_db = SILENT_DB
		_roll_level = 0.0
		_start_player(_roll)
		_roll.stream_paused = _paused


func play_event(event: String) -> bool:
	if not EVENTS.has(event) or not is_instance_valid(_ui):
		return false
	if (_paused and event != "ui") or _sfx <= 0.0:
		return false
	if _elapsed - float(_last_event.get(event, -100.0)) < float(EVENTS[event][1]):
		return false
	var player: AudioStreamPlayer = _ui
	if event != "ui":
		var slot := _voice_remaining.find(0.0)
		if slot < 0:
			# Bail/bank carry important state; replace the voice nearest its end.
			if event not in ["bail", "bank"]:
				return false
			slot = 0
			for i in range(1, EVENT_VOICES):
				if _voice_remaining[i] < _voice_remaining[slot]:
					slot = i
		player = _voices[slot]
		_voice_remaining[slot] = float(EVENTS[event][0])
	player.stream = _streams[event]
	player.volume_db = _gain_db(_sfx * (0.12 if event == "ui" else 0.20))
	_start_player(player)
	_last_event[event] = _elapsed
	_event_counts[event] = int(_event_counts.get(event, 0)) + 1
	return true


func play_bark(id: String) -> bool:
	if not BARKS.has(id) or _paused or not is_instance_valid(_bark):
		return false
	if _elapsed - _last_bark_time < 10.0 or _elapsed - float(_last_bark_by_id.get(id, -100.0)) < 30.0:
		return false
	if not _bark_streams.has(id):
		var clip := load("res://game/audio/generated/%s.wav" % id) as AudioStreamWAV
		if clip == null:
			return false
		_bark_streams[id] = clip
	_bark.stream = _bark_streams[id]
	_bark.volume_db = _gain_db(_sfx * 0.20)
	if _sfx > 0.0:
		_start_player(_bark)
	_last_bark_time = _elapsed
	_last_bark_by_id[id] = _elapsed
	_bark_counts[id] = int(_bark_counts.get(id, 0)) + 1
	caption.emit(BARKS[id])
	return true


func set_paused(value: bool) -> void:
	_paused = value
	if not is_instance_valid(_roll):
		return
	_roll.stream_paused = value
	_grind.stream_paused = value
	for bed in _beds:
		bed.stream_paused = value
	# Do not resume an old impact or reward when leaving a menu.
	if value:
		_bark.stop()
		_roll_level = 0.0
		_grind_level = 0.0
		for i in range(EVENT_VOICES):
			_voices[i].stop()
			_voice_remaining[i] = 0.0
	_apply_levels()


func _process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0 or not is_instance_valid(_roll):
		return
	var step := minf(delta, 0.25)
	_elapsed += step
	for i in range(EVENT_VOICES):
		_voice_remaining[i] = maxf(0.0, _voice_remaining[i] - step)
	if not _paused:
		var speed_fraction := clampf(_speed / 16.0, 0.0, 1.0)
		var roll_target := speed_fraction if _grounded and not _grinding else 0.0
		var grind_target := maxf(0.15, speed_fraction) if _grinding else 0.0
		_roll_level = move_toward(_roll_level, roll_target, step * 5.0)
		_grind_level = move_toward(_grind_level, grind_target, step * 7.0)
		_roll.pitch_scale = 0.65 + speed_fraction * 0.8
		_grind.pitch_scale = 0.8 + speed_fraction * 0.5
		for i in range(2):
			_bed_levels[i] = move_toward(_bed_levels[i], _bed_targets[i], step * 1.5)
	_apply_levels()


func _apply_levels() -> void:
	_roll.volume_db = _gain_db(_sfx * _roll_level * 0.18)
	_grind.volume_db = _gain_db(_sfx * _grind_level * 0.19)
	for i in range(_beds.size()):
		_beds[i].volume_db = _gain_db(_ambience * float(_bed_levels[i]) * 0.10)
	for player in _voices:
		player.volume_db = _gain_db(_sfx * 0.20)
	_ui.volume_db = _gain_db(_sfx * 0.12)
	_bark.volume_db = _gain_db(_sfx * 0.20)


func _make_player(key: String, looping: bool = true) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = _streams[key]
	player.volume_db = SILENT_DB
	player.max_polyphony = 1
	add_child(player)
	if looping:
		_start_player(player)
	return player


static func _start_player(player: AudioStreamPlayer) -> void:
	# Dummy has no audible output. Keep events/PCM testable without queued mixer work.
	if AudioServer.get_driver_name() != "Dummy":
		player.play()


func get_debug_state() -> Dictionary:
	return {
		"sfx": _sfx, "ambience": _ambience, "speed": _speed, "paused": _paused,
		"surface": _surface, "district": _district, "roll_level": _roll_level,
		"grind_level": _grind_level, "bed_levels": _bed_levels.duplicate(),
		"event_counts": _event_counts.duplicate(), "voices": _voices.size(),
		"bark_counts": _bark_counts.duplicate(),
		"active_events": _voice_remaining.filter(func(t: float) -> bool: return t > 0.0).size(),
	}


static func _gain_db(gain: float) -> float:
	return linear_to_db(gain) if gain > 0.0001 else SILENT_DB


static func _district_key(label: String) -> String:
	var key := label.to_lower()
	if "central" in key or "station" in key:
		return "central"
	if "barras" in key or "barrow" in key or "market" in key:
		return "barras"
	if "george" in key:
		return "george"
	return "exchange"


static func _build_bank() -> void:
	if not _streams.is_empty():
		return
	for event: String in EVENTS:
		_streams[event] = _synth(event, float(EVENTS[event][0]), false)
	for kind in ["roll_stone", "roll_asphalt", "roll_metal", "grind_loop"]:
		_streams[kind] = _synth(kind, 1.0, true)
	for district in ["exchange", "george", "central", "barras"]:
		_streams["amb_" + district] = _synth("amb_" + district, 2.0, true)


static func _synth(kind: String, seconds: float, looping: bool) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * seconds)
	var pcm := PackedByteArray()
	pcm.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 194701 + kind.hash()
	var smooth_noise := 0.0
	for i in range(frames):
		var t := float(i) / SAMPLE_RATE
		var progress := float(i) / float(frames - 1)
		var noise := rng.randf_range(-1.0, 1.0)
		smooth_noise = lerpf(smooth_noise, noise, 0.12)
		var sample := 0.0
		match kind:
			"roll_stone":
				sample = smooth_noise * 0.5 + sin(TAU * 72.0 * t) * 0.10
				sample += noise * pow(maxf(0.0, sin(TAU * 12.0 * t)), 10.0) * 0.18
			"roll_asphalt":
				sample = smooth_noise * 0.42 + noise * 0.08
			"roll_metal":
				sample = smooth_noise * 0.25 + sin(TAU * 180.0 * t) * 0.14
			"grind_loop":
				sample = noise * 0.25 + sin(TAU * 420.0 * t) * 0.12 + smooth_noise * 0.2
			"ollie":
				sample = (noise * 0.55 + sin(TAU * 135.0 * t) * 0.22) * exp(-t * 32.0)
			"landing":
				sample = (smooth_noise * 0.65 + sin(TAU * 78.0 * t) * 0.36) * exp(-t * 20.0)
			"grind":
				sample = (noise * 0.4 + sin(TAU * 560.0 * t) * 0.2) * exp(-t * 24.0)
			"bail":
				sample = noise * 0.4 * exp(-t * 5.0) + sin(TAU * 65.0 * t) * 0.3 * exp(-t * 17.0)
			"bank":
				var note := 440.0 if t < 0.13 else (554.365 if t < 0.26 else 659.255)
				var note_time := fmod(t, 0.13) if t < 0.26 else t - 0.26
				var note_duration := 0.13 if t < 0.26 else 0.20
				var note_fade := minf(minf(note_time / 0.006, (note_duration - note_time) / 0.008), 1.0)
				sample = sin(TAU * note * note_time) * 0.36 * note_fade * exp(-note_time * 13.0)
			"ui":
				sample = sin(TAU * 740.0 * t) * 0.25 * exp(-t * 45.0)
			_:
				# Abstract city beds: distant air, street hum, market rhythm; no sampled voices.
				sample = smooth_noise * 0.35
				if kind == "amb_central":
					sample += sin(TAU * 55.0 * t) * 0.10 + sin(TAU * 82.5 * t) * 0.04
				elif kind == "amb_barras":
					sample += sin(TAU * 146.0 * t) * 0.03 * (0.5 + 0.5 * sin(TAU * 1.5 * t))
				elif kind == "amb_george":
					sample += sin(TAU * 220.0 * t) * 0.025
				else:
					sample += sin(TAU * 110.0 * t) * 0.035
		# Quiet endpoints prevent waveform seams and clicks; loops contain no DC step.
		var fade := minf(minf(progress * seconds / 0.006, (1.0 - progress) * seconds / 0.015), 1.0)
		sample = clampf(sample * fade, -0.65, 0.65)
		pcm.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = frames
	return stream
