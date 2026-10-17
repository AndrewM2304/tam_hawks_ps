extends RefCounted
## Real PCM/player-state checks; hardware listening remains a separate acceptance gate.

const AudioScript = preload("res://game/audio/skate_audio.gd")


static func run(tree: SceneTree, check: Callable) -> void:
	var sound = AudioScript.new()
	sound.set_surface("metal")
	sound.set_mix(0.7, 0.4)
	tree.root.add_child(sound)
	sound.set_process(false)
	check.call(sound.get_child_count() == 9,
		"audio: fixed players bound loop, event and UI resource usage")
	check.call(sound._roll.stream == AudioScript._streams["roll_metal"],
		"audio: surface selection made before ready is retained")
	_audit_pcm(check)
	var state: Dictionary = sound.get_debug_state()
	check.call(is_equal_approx(state.sfx, 0.7) and is_equal_approx(state.ambience, 0.4),
		"audio: separately supplied mix levels survive initialization")
	sound.set_motion(0.0, true, false, "EXCHANGE SQUARE")
	sound._process(0.25)
	check.call(sound._roll.volume_db <= -79.0 and sound._grind.volume_db <= -79.0,
		"audio: stationary skater produces no rolling or grinding loop")
	sound.set_motion(4.0, true, false, "GEORGE SQUARE")
	sound._process(0.25)
	var slow_volume: float = sound._roll.volume_db
	var slow_pitch: float = sound._roll.pitch_scale
	sound.set_motion(16.0, true, false, "GEORGE SQUARE")
	sound._process(0.25)
	check.call(sound._roll.volume_db > slow_volume and sound._roll.pitch_scale > slow_pitch,
		"audio: rolling gains level and pitch with skating speed")
	sound.set_motion(16.0, false, false, "GEORGE SQUARE")
	sound._process(0.25)
	check.call(sound._roll.volume_db <= -79.0,
		"audio: airborne travel fades wheel contact to silence")
	sound.set_motion(12.0, false, true, "CENTRAL STATION")
	sound._process(0.25)
	check.call(sound._grind.volume_db > -40.0 and sound._roll.volume_db <= -79.0,
		"audio: acquired grind replaces wheel roll with the metal loop")
	sound.set_motion(0.0, true, false, "CENTRAL STATION")
	sound._process(0.25)
	check.call(sound._grind.volume_db <= -79.0,
		"audio: grind exit fades its continuous loop")
	sound.set_surface("asphalt")
	check.call(sound._roll.stream == AudioScript._streams["roll_asphalt"],
		"audio: changing surface selects the appropriate original waveform")
	sound.set_surface("unknown")
	check.call(sound.get_debug_state().surface == "stone",
		"audio: unknown surfaces use the safe stone default")
	check.call(sound.play_event("landing") and not sound.play_event("landing"),
		"audio: repeated same-frame landing cannot stack duplicate impact sounds")
	check.call(not sound.play_event("unimplemented_event"),
		"audio: unknown event IDs are rejected")
	sound._process(0.25)
	check.call(sound.play_event("landing"),
		"audio: a later landing can play after its debounce window")
	sound.play_event("ollie")
	sound.play_event("grind")
	check.call(sound.get_debug_state().active_events == 3,
		"audio: simultaneous distinct gameplay events have a bounded three-voice pool")
	check.call(sound.play_event("bank") and sound.get_debug_state().active_events == 3,
		"audio: an important bank replaces a voice instead of exceeding the pool")
	for i in range(200):
		sound.play_event("landing")
		sound.play_event("bank")
		sound.play_event("ui")
	check.call(sound.get_child_count() == 9 and sound.get_debug_state().event_counts.bank == 1,
		"audio: event spam cannot allocate players or repeat the bank cue")
	sound.set_paused(true)
	check.call(sound.get_debug_state().paused and _inaudible(sound._roll) and _inaudible(sound._grind)
		and _inaudible(sound._beds[0]) and _inaudible(sound._beds[1]),
		"audio: pause suspends all gameplay and ambience loops")
	check.call(sound.get_debug_state().active_events == 0 and not sound.play_event("bail"),
		"audio: pause discards old impacts and rejects new gameplay sounds")
	sound._process(0.1)
	check.call(sound.play_event("ui") and not sound._ui.stream_paused,
		"audio: menu navigation feedback remains available during pause")
	sound.set_motion(10.0, true, false, "BARRAS MARKET")
	check.call(_inaudible(sound._beds[0]) and _inaudible(sound._beds[1]),
		"audio: district changes during pause cannot leak ambience")
	sound.set_paused(false)
	for i in range(4):
		sound._process(0.25)
	state = sound.get_debug_state()
	check.call(not sound._roll.stream_paused and state.district == "barras"
		and is_equal_approx(float(state.bed_levels[0]) + float(state.bed_levels[1]), 1.0),
		"audio: resume completes the requested district crossfade with bounded bed gain")
	sound.set_mix(0.0, 0.0)
	var all_silent := true
	for player in sound.get_children():
		all_silent = all_silent and player.volume_db <= -79.0
	check.call(all_silent and not sound.play_event("bank"),
		"audio: both channel mutes silence active loops and cues immediately")
	sound.set_mix(2.0, -3.0)
	check.call(sound.get_debug_state().sfx == 1.0 and sound.get_debug_state().ambience == 0.0,
		"audio: out-of-range volume preferences clamp safely")
	sound.set_mix(NAN, INF)
	sound.set_motion(NAN, true, true, "unrecognised")
	sound._process(INF)
	sound._process(0.25)
	state = sound.get_debug_state()
	check.call(state.speed == 0.0 and state.sfx == 0.0 and state.ambience == 0.0
		and is_finite(sound._roll.pitch_scale) and is_finite(sound._grind.volume_db),
		"audio: nonfinite external values cannot contaminate audio state")
	check.call(state.district == "exchange",
		"audio: unknown district labels fall back to the square ambience")
	_test_barks(sound, check)
	tree.root.remove_child(sound)
	sound.free()


static func _inaudible(player: AudioStreamPlayer) -> bool:
	return not player.playing or player.stream_paused


static func _test_barks(sound: Node, check: Callable) -> void:
	var captions: Array[String] = []
	sound.caption.connect(func(text: String) -> void: captions.append(text))
	sound.set_mix(0.0, 0.0)
	check.call(sound.play_bark("landing") and captions == ["Some landing."],
		"audio voice: a muted admitted bark still emits its exact accessible caption")
	check.call(not sound.play_bark("cone") and captions.size() == 1,
		"audio voice: shared cooldown prevents overlapping speech and caption spam")
	for i in range(41):
		sound._process(0.25)
	check.call(not sound.play_bark("landing"),
		"audio voice: per-line cooldown prevents repeated identical NPC reactions")
	check.call(sound.play_bark("cone") and captions.back() == "Mind the cone.",
		"audio voice: another nearby reaction can play after the shared cooldown")
	for i in range(41):
		sound._process(0.25)
	sound.set_paused(true)
	check.call(not sound.play_bark("again"), "audio voice: pause blocks new NPC reactions")
	sound.set_paused(false)
	check.call(sound.play_bark("again") and captions.back() == "One more run.",
		"audio voice: resume permits the next original reaction")
	check.call(not sound.play_bark("missing"), "audio voice: unknown bark IDs are rejected")
	for id: String in AudioScript.BARKS:
		var clip: AudioStreamWAV = AudioScript._bark_streams[id]
		var peak := 0
		for i in range(0, clip.data.size(), 2):
			peak = maxi(peak, absi(clip.data.decode_s16(i)))
		check.call(clip.mix_rate == 16000 and not clip.stereo and clip.get_length() < 5.0
			and peak > 1000 and peak <= 18023,
			"audio voice: pinned local speech is bounded mono PCM16: " + id)
		check.call(clip.data.decode_s16(0) == 0 and clip.data.decode_s16(clip.data.size() - 2) == 0,
			"audio voice: generated speech has silent endpoints: " + id)
	check.call(sound.get_child_count() == 9 and captions.size() == 3,
		"audio voice: repeated NPC triggers retain a single voice player and exactly three captions")


static func _audit_pcm(check: Callable) -> void:
	for key: String in AudioScript._streams:
		var stream: AudioStreamWAV = AudioScript._streams[key]
		var bytes := stream.data
		var peak := 0
		var sum := 0.0
		for i in range(0, bytes.size(), 2):
			var value := bytes.decode_s16(i)
			peak = maxi(peak, absi(value))
			sum += value
		check.call(stream.mix_rate == 22050 and not stream.stereo and bytes.size() > 3000
			and peak > 50 and peak <= 21300,
			"audio PCM: audible bounded 16-bit mono data for " + key)
		check.call(bytes.decode_s16(0) == 0 and bytes.decode_s16(bytes.size() - 2) == 0
			and absf(sum / (bytes.size() / 2.0)) < 300.0,
			"audio PCM: quiet endpoints and bounded DC offset for " + key)
		if stream.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			check.call(stream.loop_begin == 0 and stream.loop_end == bytes.size() / 2,
				"audio PCM: loop bounds cover exactly the available frames for " + key)
