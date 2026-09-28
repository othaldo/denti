class_name SoundController
extends Node

const SHOOT: AudioStreamWAV = preload("res://assets/audio/sfx/toothpaste_shot.wav")
const HIT: AudioStreamWAV = preload("res://assets/audio/sfx/enemy_hit.wav")
const HURT: AudioStreamWAV = preload("res://assets/audio/sfx/player_hurt.wav")
const FLOSS: AudioStreamWAV = preload("res://assets/audio/sfx/floss_swish.wav")
const DRILL: AudioStreamWAV = preload("res://assets/audio/sfx/drill_strike.wav")
const ACID: AudioStreamWAV = preload("res://assets/audio/sfx/acid_shot.wav")
const DOWN: AudioStreamWAV = preload("res://assets/audio/sfx/enemy_down.wav")
const PICKUP: AudioStreamWAV = preload("res://assets/audio/sfx/pickup.wav")
const VOICE_COUNT := 12

var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0
var last_play_ms: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		voice.bus = &"SFX"
		add_child(voice)
		voices.append(voice)


func play_attack(kind: StringName) -> void:
	match kind:
		&"floss": play_cue(&"floss")
		&"drill": play_cue(&"drill")
		_: play_cue(&"shoot")


func play_cue(cue: StringName) -> void:
	var effect := _stream_for(cue)
	if effect == null:
		return
	var now := Time.get_ticks_msec()
	var gap := 55 if cue == &"hit" else 85 if cue == &"pickup" or cue == &"down" else 0
	if gap > 0 and last_play_ms.has(cue) and now - int(last_play_ms[cue]) < gap:
		return
	last_play_ms[cue] = now
	var voice := _available_voice()
	voice.stop()
	voice.stream = effect
	voice.volume_db = _volume_for(cue)
	voice.pitch_scale = randf_range(0.95, 1.05)
	voice.play()


func _available_voice() -> AudioStreamPlayer:
	for voice in voices:
		if not voice.playing:
			return voice
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	return voice


func _stream_for(cue: StringName) -> AudioStreamWAV:
	match cue:
		&"shoot": return SHOOT
		&"hit": return HIT
		&"hurt": return HURT
		&"floss": return FLOSS
		&"drill": return DRILL
		&"acid": return ACID
		&"down": return DOWN
		&"pickup": return PICKUP
	return null


func _volume_for(cue: StringName) -> float:
	match cue:
		&"drill", &"acid", &"pickup": return -8.0
		&"floss", &"down": return -6.0
		&"hit": return -5.0
	return -3.0
