extends RefCounted
## Original synthesized plucked open chord. No melody, recording or external file.
## Cached once across encounter instances; mono PCM and modest spatial gain.

const SAMPLE_RATE := 22050
const SECONDS := 8.0
const FREQUENCIES: Array[float] = [146.8324, 220.0, 293.6648, 369.9944, 440.0, 587.3295]
const STROKES: Array[float] = [0.10, 1.20, 4.30, 5.40]
static var _cached: AudioStreamWAV

static func stream() -> AudioStreamWAV:
	if _cached != null:
		return _cached
	var count := int(SAMPLE_RATE * SECONDS)
	var values := PackedFloat32Array()
	values.resize(count)
	for stroke_index in STROKES.size():
		for string_index in FREQUENCIES.size():
			var onset := STROKES[stroke_index] + string_index * 0.027
			var first := int(onset * SAMPLE_RATE)
			var duration := mini(int(SAMPLE_RATE * 2.35), count - first)
			var frequency := FREQUENCIES[string_index]
			for sample in duration:
				var t := float(sample) / SAMPLE_RATE
				var attack := minf(1.0, t * 550.0)
				var release := minf(1.0, (float(duration - sample) / SAMPLE_RATE) * 18.0)
				var envelope := attack * release * exp(-2.35 * t)
				var angle := TAU * frequency * t
				var tone := sin(angle) * 0.73 + sin(angle * 2.001) * 0.16 * exp(-t * 2.0)
				tone += sin(angle * 3.004) * 0.08 * exp(-t * 4.0) + sin(angle * 4.008) * 0.03 * exp(-t * 6.0)
				values[first + sample] += tone * envelope * 0.064
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for index in count:
		pcm.encode_s16(index * 2, int(clampf(values[index], -0.95, 0.95) * 32767.0))
	_cached = AudioStreamWAV.new()
	_cached.format = AudioStreamWAV.FORMAT_16_BITS
	_cached.mix_rate = SAMPLE_RATE
	_cached.stereo = false
	_cached.data = pcm
	_cached.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_cached.loop_begin = 0
	_cached.loop_end = count
	return _cached
