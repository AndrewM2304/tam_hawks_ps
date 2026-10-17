extends RefCounted
## Original container-percussion/techno texture, synthesized locally from equations.
## No sampled drum, song, recording or external resource is included.

const SAMPLE_RATE := 22050
const SECONDS := 8.0
const BPM := 120.0
static var _cached: AudioStreamWAV

static func stream() -> AudioStreamWAV:
	if _cached != null: return _cached
	var count := int(SAMPLE_RATE * SECONDS)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for beat in 16:
		_add_kick(samples, float(beat) * 0.5)
		if beat % 4 in [1,3]: _add_noise(samples, float(beat) * 0.5, 0.13, 0.065, beat + 81)
	for eighth in 32:
		_add_noise(samples, float(eighth) * 0.25 + 0.125, 0.045, 0.025, eighth + 137)
	for bar in 4:
		_add_tub(samples, bar * 2.0 + 0.0, 147.0, 0.100)
		_add_tub(samples, bar * 2.0 + 0.75, 223.0, 0.075)
		_add_tub(samples, bar * 2.0 + 1.25, 317.0, 0.070)
	var peak := 0.0
	for value in samples: peak = maxf(peak, absf(value))
	var headroom := minf(1.0, 0.78 / maxf(peak, 0.000001))
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for index in count:
		pcm.encode_s16(index * 2, int(clampf(samples[index] * headroom,-0.95,0.95) * 32767.0))
	_cached = AudioStreamWAV.new()
	_cached.format = AudioStreamWAV.FORMAT_16_BITS
	_cached.mix_rate = SAMPLE_RATE
	_cached.stereo = false
	_cached.data = pcm
	_cached.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_cached.loop_begin = 0
	_cached.loop_end = count
	return _cached

static func _add_kick(samples: PackedFloat32Array, at: float) -> void:
	var first := int(at * SAMPLE_RATE)
	var duration := mini(int(0.22 * SAMPLE_RATE), samples.size() - first)
	for index in duration:
		var t := float(index) / SAMPLE_RATE
		var phase := TAU * (45.0 * t + 1.6 * (1.0 - exp(-28.0 * t)))
		var envelope := minf(1.0,t * 800.0) * exp(-t * 22.0)
		samples[first+index] += sin(phase) * envelope * 0.25

static func _add_tub(samples: PackedFloat32Array, at: float, frequency: float, gain: float) -> void:
	var first := int(at * SAMPLE_RATE)
	var duration := mini(int(0.29 * SAMPLE_RATE), samples.size()-first)
	for index in duration:
		var t := float(index) / SAMPLE_RATE
		var phase := TAU * frequency * t
		var envelope := minf(1.0,t*1100.0) * exp(-t * 17.0)
		var ring := sin(phase) * 0.52 + sin(phase * 1.483) * 0.27 + sin(phase * 2.147) * 0.15 + sin(phase * 3.31) * 0.06
		samples[first+index] += ring * envelope * gain

static func _add_noise(samples: PackedFloat32Array, at: float, seconds: float, gain: float, seed_value: int) -> void:
	var first := int(at * SAMPLE_RATE)
	var duration := mini(int(seconds * SAMPLE_RATE), samples.size()-first)
	var seed_state := seed_value
	var previous := 0.0
	for index in duration:
		seed_state = (seed_state * 1103515245 + 12345) & 0x7fffffff
		var noise := float(seed_state) / 1073741824.0 - 1.0
		var high_pass := noise - previous * 0.75
		previous = noise
		var t := float(index) / SAMPLE_RATE
		var envelope := minf(1.0,t*1500.0) * exp(-t * (8.0 / seconds))
		samples[first+index] += high_pass * envelope * gain
