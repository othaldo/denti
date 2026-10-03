class_name StorySpeech
extends Node

# Short, wordless syllables. Timbre and cadence distinguish speakers without VO.
const SAMPLE_RATE := 22050
const MIN_GAP := 0.075
const PROFILES := {
	"Denti": {"frequency": 300.0, "rate": 38.0, "body": 0.20, "volume": -19.0},
	"Zahnfee": {"frequency": 530.0, "rate": 43.0, "body": 0.08, "volume": -23.0},
	"Karies-Graf": {"frequency": 220.0, "rate": 35.0, "body": 0.38, "volume": -20.0},
	"Karies-Prinz": {"frequency": 360.0, "rate": 40.0, "body": 0.26, "volume": -21.0},
	"Karies-König": {"frequency": 170.0, "rate": 32.0, "body": 0.52, "volume": -20.0},
	"Karies-Imperator": {"frequency": 130.0, "rate": 30.0, "body": 0.62, "volume": -20.0},
}
static var _streams: Dictionary = {}
var voice: AudioStreamPlayer
var cooldown: float = 0.0
var syllable_index: int = 0
@onready var session: Node = get_node_or_null("/root/GameSession")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	voice = AudioStreamPlayer.new()
	voice.bus = &"SFX"
	add_child(voice)

func _process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	if not sound_enabled():
		voice.stop()

func sound_enabled() -> bool:
	return session == null or (session.ui_sounds and session.master_volume_percent > 0 and session.sfx_volume_percent > 0)

func begin_line() -> void:
	stop()
	syllable_index = 0

func stop() -> void:
	cooldown = 0
	if voice != null:
		voice.stop()

func syllable(speaker: String, glyph: String) -> void:
	if cooldown > 0 or not sound_enabled() or not speakable(glyph):
		return
	var profile: Dictionary = PROFILES.get(speaker, PROFILES.Denti)
	voice.stream = stream_for(speaker)
	voice.volume_db = float(profile.volume)
	# Deterministic variation avoids consuming the gameplay random sequence.
	voice.pitch_scale = 0.94 + ((glyph.unicode_at(0) + syllable_index) % 7) * 0.02
	voice.play()
	syllable_index += 1
	cooldown = MIN_GAP

static func speakable(glyph: String) -> bool:
	return not glyph.is_empty() and (glyph.to_lower() != glyph.to_upper() or glyph.is_valid_int())

static func character_interval(speaker: String) -> float:
	return 1.0 / float(PROFILES.get(speaker, PROFILES.Denti).rate)

static func stream_for(speaker: String) -> AudioStreamWAV:
	var key := speaker if PROFILES.has(speaker) else "Denti"
	if _streams.has(key):
		return _streams[key]
	var profile: Dictionary = PROFILES[key]
	var duration := 0.060
	var samples := int(SAMPLE_RATE * duration)
	var pcm := PackedByteArray()
	pcm.resize(samples * 2)
	var phase := 0.0
	for index in samples:
		var time := float(index) / SAMPLE_RATE
		var portion := time / duration
		var envelope := minf(time / 0.004, 1) * minf(float(samples - index - 1) / SAMPLE_RATE / 0.012, 1)
		# A small descending inflection and harmonics give a rounded "wah" sound.
		phase += TAU * float(profile.frequency) * (1.12 - portion * 0.24) / SAMPLE_RATE
		var body := float(profile.body)
		var wave := sin(phase) * (0.75 - body * 0.25) + sin(phase * 2) * body + sin(phase * 3) * 0.13
		var sample := clampi(roundi(wave * envelope * 0.65 * 32767), -32768, 32767)
		pcm[index * 2] = sample & 0xff
		pcm[index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	_streams[key] = stream
	return stream
