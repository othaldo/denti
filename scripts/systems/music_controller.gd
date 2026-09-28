class_name MusicController
extends AudioStreamPlayer

const MAIN_MENU: AudioStreamMP3 = preload("res://assets/audio/main-manu.mp3")
const WAVE_ONE: AudioStreamMP3 = preload("res://assets/audio/wave-1.mp3")
const WAVE_TWO: AudioStreamMP3 = preload("res://assets/audio/wave-2.mp3")
const MINI_BOSS_ONE: AudioStreamMP3 = preload("res://assets/audio/mini-boss-1.mp3")
const MINI_BOSS_TWO: AudioStreamMP3 = preload("res://assets/audio/mini-boss-2.mp3")
const FINAL_ONE: AudioStreamMP3 = preload("res://assets/audio/final-boss-1.mp3")
const FINAL_TWO: AudioStreamMP3 = preload("res://assets/audio/final-boss-2.mp3")

const PLAY_VOLUME_DB := -12.0
const SILENT_VOLUME_DB := -60.0
const FADE_DURATION := 1.8

enum FadeState { IDLE, FADING_IN, PLAYING, FADING_OUT }

var current_cue: StringName = &""
var mode: StringName = &""
var queued_cue: StringName = &""
var next_normal_index: int = 0
var fade_state: FadeState = FadeState.IDLE
var fade_elapsed: float = 0.0
var fade_start_gain: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = &"Music"
	volume_db = PLAY_VOLUME_DB
	for track in [MAIN_MENU, WAVE_ONE, WAVE_TWO, MINI_BOSS_ONE, MINI_BOSS_TWO, FINAL_ONE, FINAL_TWO]:
		track.loop = false


func _process(delta: float) -> void:
	if fade_state == FadeState.IDLE:
		return
	if not playing:
		if fade_state == FadeState.FADING_OUT:
			_finish_fade_out()
		else:
			_start_track(_cue_for_mode())
		return
	match fade_state:
		FadeState.FADING_IN:
			fade_elapsed += delta
			_set_gain(lerpf(fade_start_gain, db_to_linear(PLAY_VOLUME_DB), minf(fade_elapsed / FADE_DURATION, 1.0)))
			if fade_elapsed >= FADE_DURATION:
				fade_state = FadeState.PLAYING
		FadeState.PLAYING:
			if get_playback_position() >= stream.get_length() - FADE_DURATION:
				_begin_fade_out(_cue_for_mode())
		FadeState.FADING_OUT:
			fade_elapsed += delta
			_set_gain(lerpf(fade_start_gain, db_to_linear(SILENT_VOLUME_DB), minf(fade_elapsed / FADE_DURATION, 1.0)))
			if fade_elapsed >= FADE_DURATION:
				_finish_fade_out()


func play_wave(wave_number: int) -> void:
	if wave_number >= WaveController.MAX_WAVES:
		_request_mode(&"final_boss_1")
	elif WaveController.is_boss_wave(wave_number):
		_request_mode(&"mini_boss_1" if wave_number % (WaveController.MINI_BOSS_INTERVAL * 2) == WaveController.MINI_BOSS_INTERVAL else &"mini_boss_2")
	else:
		_request_mode(&"normal")


func play_menu() -> void:
	_request_mode(&"main_menu")


func play_boss_overtime(wave_number: int) -> void:
	if wave_number >= WaveController.MAX_WAVES:
		_request_mode(&"final_boss_2")
	else:
		play_wave(wave_number)


func fade_out_and_stop() -> void:
	_request_mode(&"")


func stop_music() -> void:
	stop()
	stream = null
	current_cue = &""
	mode = &""
	queued_cue = &""
	fade_state = FadeState.IDLE
	volume_db = PLAY_VOLUME_DB


func _request_mode(requested_mode: StringName) -> void:
	if mode == requested_mode:
		return
	mode = requested_mode
	if current_cue == &"":
		if mode != &"":
			_start_track(_cue_for_mode())
		return
	if mode == &"normal" and _is_normal_cue(current_cue) or mode == current_cue:
		if fade_state == FadeState.FADING_OUT:
			_begin_fade_in()
		return
	_begin_fade_out(_cue_for_mode())


func _cue_for_mode() -> StringName:
	if mode == &"normal":
		return &"wave_1" if next_normal_index == 0 else &"wave_2"
	return mode


func _is_normal_cue(cue: StringName) -> bool:
	return cue == &"wave_1" or cue == &"wave_2"


func _stream_for(cue: StringName) -> AudioStreamMP3:
	match cue:
		&"main_menu": return MAIN_MENU
		&"wave_1": return WAVE_ONE
		&"wave_2": return WAVE_TWO
		&"mini_boss_1": return MINI_BOSS_ONE
		&"mini_boss_2": return MINI_BOSS_TWO
		&"final_boss_1": return FINAL_ONE
		&"final_boss_2": return FINAL_TWO
	return null


func _start_track(cue: StringName) -> void:
	if cue == &"":
		stop_music()
		return
	stream = _stream_for(cue)
	current_cue = cue
	if cue == &"wave_1":
		next_normal_index = 1
	elif cue == &"wave_2":
		next_normal_index = 0
	volume_db = SILENT_VOLUME_DB
	play()
	_begin_fade_in()


func _begin_fade_in() -> void:
	fade_state = FadeState.FADING_IN
	fade_elapsed = 0.0
	fade_start_gain = db_to_linear(volume_db)
	queued_cue = &""


func _begin_fade_out(next_cue: StringName) -> void:
	if fade_state == FadeState.FADING_OUT:
		queued_cue = next_cue
		return
	queued_cue = next_cue
	fade_state = FadeState.FADING_OUT
	fade_elapsed = 0.0
	fade_start_gain = db_to_linear(volume_db)


func _finish_fade_out() -> void:
	var next_cue := queued_cue
	stop()
	queued_cue = &""
	_start_track(next_cue)


func _set_gain(gain: float) -> void:
	volume_db = linear_to_db(maxf(gain, db_to_linear(SILENT_VOLUME_DB)))
