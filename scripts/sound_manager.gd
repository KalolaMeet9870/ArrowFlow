class_name SoundManager
extends Node

## Procedural Sound Manager for ArrowFlow
## Generates clean synthesized sound effects without external audio asset dependencies.

static var instance: SoundManager

var is_muted: bool = false
var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var current_player: int = 0

var sfx_paint: AudioStreamWAV
var sfx_hit: AudioStreamWAV
var sfx_win: AudioStreamWAV
var sfx_swipe: AudioStreamWAV
var sfx_click: AudioStreamWAV
var sfx_error: AudioStreamWAV
var sfx_whoosh: AudioStreamWAV
var sfx_guidance: AudioStreamWAV
var sfx_hint: AudioStreamWAV

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	# Sync initial mute state with SaveManager
	if SaveManager.instance:
		is_muted = not SaveManager.instance.sound_enabled

	# Initialize audio player pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		audio_players.append(player)

	# Generate procedural sound waveforms
	sfx_paint = _generate_paint_sfx()
	sfx_hit = _generate_hit_sfx()
	sfx_win = _generate_win_sfx()
	sfx_swipe = _generate_swipe_sfx()
	sfx_click = _generate_click_sfx()
	sfx_error = _generate_error_sfx()
	sfx_whoosh = _generate_whoosh_sfx()
	sfx_guidance = _generate_guidance_sfx()
	sfx_hint = _generate_hint_sfx()

func play_whoosh(pitch: float = 1.0) -> void:
	_play_stream(sfx_whoosh, -4.0, pitch)

func play_guidance_hum() -> void:
	_play_stream(sfx_guidance, -8.0, 1.0)

func play_hint() -> void:
	_play_stream(sfx_hint, -3.0, 1.0)

# Ascending pentatonic scale notes (Do, Re, Mi, Sol, La, High Do)
const PENTATONIC_PITCHES = [1.0, 1.122, 1.26, 1.498, 1.682, 2.0]

func play_combo(streak: int) -> void:
	var idx = (maxi(1, streak) - 1) % PENTATONIC_PITCHES.size()
	var pitch = PENTATONIC_PITCHES[idx]
	_play_stream(sfx_paint, -5.0, pitch)
	_play_stream(sfx_whoosh, -7.0, pitch * 0.95)

func play_pentatonic_combo(streak: int) -> void:
	play_combo(streak)

func vibrate(duration_ms: int = 30) -> void:
	if SaveManager.instance and not SaveManager.instance.vibration_enabled:
		return
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms)

func play_paint(pitch_multiplier: float = 1.0) -> void:
	_play_stream(sfx_paint, -6.0, clampf(pitch_multiplier, 0.8, 1.8))

func play_hit() -> void:
	_play_stream(sfx_hit, -4.0, randf_range(0.95, 1.05))

func play_error() -> void:
	_play_stream(sfx_error, -4.0, 1.0)
	vibrate(70)

func play_win() -> void:
	_play_stream(sfx_win, -2.0, 1.0)

func play_swipe() -> void:
	_play_stream(sfx_swipe, -10.0, randf_range(0.9, 1.1))

func play_click() -> void:
	_play_stream(sfx_click, -6.0, 1.0)
	vibrate(15)

func toggle_mute() -> bool:
	is_muted = !is_muted
	return is_muted

func _play_stream(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if is_muted or stream == null or audio_players.is_empty():
		return
	var player = audio_players[current_player]
	current_player = (current_player + 1) % POOL_SIZE
	if player and player.is_inside_tree():
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()

## Generates a cute bubble/paint pop sound (frequency glide up with fast decay)
func _generate_paint_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.12
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		# Pitch sweeps up from 500Hz to 950Hz
		var freq = lerpf(520.0, 960.0, progress * progress)
		# Exponential envelope
		var envelope = (1.0 - progress) * (1.0 - progress)
		var sample_val = sin(t * freq * TAU) * envelope * 24000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a soft, bouncy wall thud
func _generate_hit_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.14
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		# Low frequency drops fast: 130Hz -> 50Hz
		var freq = lerpf(130.0, 50.0, progress)
		var envelope = exp(-progress * 9.0)
		var sample_val = sin(t * freq * TAU) * envelope * 28000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a triumphant arpeggio fanfare (C5 -> E5 -> G5 -> C6)
func _generate_win_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var note_dur: float = 0.14
	var total_dur: float = note_dur * 4.0 + 0.5
	var samples: int = int(rate * total_dur)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	var notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6

	for i in range(samples):
		var t = float(i) / float(rate)
		var total_sample: float = 0.0

		for n in range(notes.size()):
			var note_start = n * note_dur
			if t >= note_start:
				var note_t = t - note_start
				var dur = total_dur - note_start if n == 3 else note_dur * 1.5
				if note_t < dur:
					var env = exp(-note_t * (3.0 if n == 3 else 7.0))
					var f = notes[n]
					# Main tone + harmonic
					var wave = sin(note_t * f * TAU) * 0.75 + sin(note_t * f * 2.0 * TAU) * 0.25
					total_sample += wave * env * 14000.0

		bytes.encode_s16(i * 2, int(clampf(total_sample, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a soft whoosh for ball swipe
func _generate_swipe_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.16
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	var noise_seed = 12345
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		# Bell curve envelope
		var env = sin(progress * PI)
		# Pseudo noise
		noise_seed = (noise_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var n_val = (float(noise_seed & 0xFFFF) / 32768.0) - 1.0
		# Gentle tone mixed with noise
		var tone = sin(t * 300.0 * TAU) * 0.4
		var sample_val = (n_val * 0.6 + tone) * env * 16000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a crisp UI tap click
func _generate_click_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.04
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		var env = exp(-progress * 25.0)
		var sample_val = sin(t * 1200.0 * TAU) * env * 22000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a soft rejection buzz sound
func _generate_error_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.18
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		var env = exp(-progress * 8.0)
		# Dual square/saw buzz at 140Hz and 180Hz
		var tone = (1.0 if sin(t * 140.0 * TAU) > 0.0 else -1.0) * 0.5
		tone += (1.0 if sin(t * 185.0 * TAU) > 0.0 else -1.0) * 0.5
		var sample_val = tone * env * 22000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a silky smooth ASMR airy slide whoosh (pink-noise + sine glide)
func _generate_whoosh_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.24
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	var noise_seed = 54321
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		# Smooth symmetric rise and exponential decay envelope
		var env = sin(progress * PI) * exp(-progress * 2.2)
		noise_seed = (noise_seed * 1103515245 + 12345) & 0x7FFFFFFF
		var n_val = (float(noise_seed & 0xFFFF) / 32768.0) - 1.0
		# Frequency sweeps downward smoothly: 680Hz -> 280Hz
		var freq = lerpf(680.0, 280.0, progress)
		var tone = sin(t * freq * TAU) * 0.45
		var sample_val = (n_val * 0.55 + tone) * env * 22000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a calm, meditative pure sine harmonic for long-press guidance preview
func _generate_guidance_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.35
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		var env = sin(progress * PI)
		# 528 Hz (Solfeggio 'transformation/clarity' tone) + subtle 1056 Hz octave
		var wave = sin(t * 528.0 * TAU) * 0.8 + sin(t * 1056.0 * TAU) * 0.2
		var sample_val = wave * env * 16000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

## Generates a crisp, warm bell chime for hints
func _generate_hint_sfx() -> AudioStreamWAV:
	var rate: int = 22050
	var duration: float = 0.4
	var samples: int = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(samples * 2)

	var f = 880.0 # A5
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = t / duration
		var env = exp(-progress * 6.5)
		var wave = sin(t * f * TAU) * 0.65 + sin(t * f * 2.0 * TAU) * 0.25 + sin(t * f * 3.0 * TAU) * 0.1
		var sample_val = wave * env * 24000.0
		bytes.encode_s16(i * 2, int(clampf(sample_val, -32767.0, 32767.0)))

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav


