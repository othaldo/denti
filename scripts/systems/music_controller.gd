class_name MusicController
extends Node

const BUS := &"Music"
const FADE_DURATION := 3.2
const PLAY_DB := -12.0
const DIALOGUE_DB := -22.0
const SILENT_DB := -80.0
const RESUMABLE := [
	&"arena", &"arena_late", &"endless", &"endless_alt",
	&"pillow", &"sugar", &"acid", &"palace",
]

const CUES := {
	&"menu": "res://assets/audio/classic/menu.ogg",
	&"intermission": "res://assets/audio/themes/rast.ogg",
	&"victory": "res://assets/audio/classic/victory.ogg",
	&"arena": "res://assets/audio/classic/arena.ogg",
	&"arena_late": "res://assets/audio/classic/arena-late.ogg",
	&"pillow": "res://assets/audio/classic/pillow.ogg",
	&"sugar": "res://assets/audio/themes/karamellkurven.ogg",
	&"acid": "res://assets/audio/themes/saeurestrom.ogg",
	&"palace": "res://assets/audio/classic/palace.ogg",
	&"boss": "res://assets/audio/classic/boss.ogg",
	&"boss_alt": "res://assets/audio/classic/boss-alt.ogg",
	&"finale": "res://assets/audio/classic/finale.ogg",
	&"finale_overtime": "res://assets/audio/classic/finale-overtime.ogg",
	&"endless": "res://assets/audio/classic/endless.ogg",
	&"endless_alt": "res://assets/audio/themes/wurzelstrom.ogg",
	&"endless_double": "res://assets/audio/classic/endless-double.ogg",
}

var current_cue: StringName = &""
var player: AudioStreamPlayer
var outgoing: AudioStreamPlayer
var _outgoing_cue: StringName = &""
var _positions: Dictionary[StringName, float] = {}
var _under_dialogue := false
var _fade_elapsed := FADE_DURATION
var _outgoing_fade_duration := FADE_DURATION
var _start_gain := 0.0
var _outgoing_gain := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = _make_player()
	outgoing = _make_player()


func _exit_tree() -> void:
	stop_music()


func _process(delta: float) -> void:
	if _fade_elapsed >= FADE_DURATION:
		return
	_fade_elapsed = minf(_fade_elapsed + delta, FADE_DURATION)
	var weight := smoothstep(0.0, FADE_DURATION, _fade_elapsed)
	var target := db_to_linear(DIALOGUE_DB if _under_dialogue else PLAY_DB)
	_set_gain(player, lerpf(_start_gain, target, weight))
	if outgoing.playing:
		if _fade_elapsed >= _outgoing_fade_duration:
			_stop_outgoing()
		else:
			var release_weight := smoothstep(0.0, _outgoing_fade_duration, _fade_elapsed)
			_set_gain(outgoing, _outgoing_gain * (1.0 - release_weight))


func play_menu() -> void:
	play_cue(&"menu")


func play_intermission() -> void:
	play_cue(&"intermission")


func play_wave(wave_number: int, chapter: StringName = &"", overtime: bool = false) -> void:
	if WaveController.is_boss_wave(wave_number):
		if wave_number == WaveController.MAX_WAVES:
			play_cue(&"finale_overtime" if overtime else &"finale")
		elif wave_number > WaveController.MAX_WAVES:
			play_cue(&"endless_double" if wave_number % 10 == 0 else &"finale")
		else:
			play_cue(&"boss_alt" if wave_number % 10 == 0 else &"boss")
	elif wave_number > WaveController.MAX_WAVES:
		var boss_interval := WaveController.MINI_BOSS_INTERVAL
		var block_position := posmod(wave_number - EndlessRules.FIRST_WAVE, boss_interval * 2)
		play_cue(&"endless_alt" if block_position >= boss_interval else &"endless")
	elif chapter != &"":
		play_cue(chapter)
	else:
		play_cue(&"arena_late" if wave_number > 10 else &"arena")


func play_cue(cue: StringName, under_dialogue: bool = false) -> void:
	if current_cue != cue:
		_under_dialogue = under_dialogue
		_switch_to(cue)
	elif _under_dialogue != under_dialogue:
		_under_dialogue = under_dialogue
		_begin_fade(_outgoing_fade_duration - _fade_elapsed)


func fade_out_and_stop() -> void:
	play_cue(&"")


func stop_music() -> void:
	_release(player)
	_release(outgoing)
	current_cue = &""
	_outgoing_cue = &""
	_positions.clear()
	_fade_elapsed = FADE_DURATION


func _switch_to(cue: StringName) -> void:
	var matches_outgoing := cue == _outgoing_cue and outgoing.playing
	# A new break always starts with the arrangement's quiet opening.
	var resume_outgoing := matches_outgoing and cue != &"intermission"
	var replaced_cue := current_cue
	var release_time := _outgoing_fade_duration - _fade_elapsed
	# Loot collection can lead straight to victory or dialogue. Keep the
	# audible deck if a third cue is requested before the current fade settles.
	if matches_outgoing or (player.playing and (not outgoing.playing or player.volume_db >= outgoing.volume_db)):
		replaced_cue = _outgoing_cue
		_outgoing_cue = current_cue
		var previous := player
		player = outgoing
		outgoing = previous
		release_time = FADE_DURATION
	if not resume_outgoing:
		_remember_position(player, replaced_cue)
		_release(player)
		if cue != &"":
			player.stream = load(CUES[cue]) as AudioStreamOggVorbis
			player.volume_db = SILENT_DB
			player.play(_positions.get(cue, 0.0))
	current_cue = cue
	_begin_fade(release_time)


func _begin_fade(release_time: float) -> void:
	_fade_elapsed = 0.0
	_outgoing_fade_duration = maxf(release_time, 0.0)
	_start_gain = db_to_linear(player.volume_db) if player.playing else 0.0
	_outgoing_gain = db_to_linear(outgoing.volume_db) if outgoing.playing else 0.0


func _make_player() -> AudioStreamPlayer:
	var deck := AudioStreamPlayer.new()
	deck.bus = BUS
	add_child(deck)
	return deck


func _release(deck: AudioStreamPlayer) -> void:
	deck.stop()
	deck.stream = null


func _stop_outgoing() -> void:
	_remember_position(outgoing, _outgoing_cue)
	_release(outgoing)
	_outgoing_cue = &""
	_outgoing_gain = 0.0


func _remember_position(deck: AudioStreamPlayer, cue: StringName) -> void:
	if deck.playing and cue in RESUMABLE:
		_positions[cue] = deck.get_playback_position()


func _set_gain(deck: AudioStreamPlayer, gain: float) -> void:
	deck.volume_db = maxf(linear_to_db(gain), SILENT_DB)
