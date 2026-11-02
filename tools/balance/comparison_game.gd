extends "res://scripts/game/game.gd"
## Keep deaths/finishes inspectable and never write a player's run or progression.

var probe_outcome := ""
var probe_seed := 0


func _ready() -> void:
	super._ready()
	# The normal game's _ready randomizes the global generator.
	seed(probe_seed)


func _save_run() -> void:
	pass


func _sync_music() -> void:
	pass


func _save_completed_report(_won: bool) -> void:
	pass


func _on_player_died() -> void:
	probe_outcome = "death"
	get_tree().paused = true


func _on_boss_death_started(at: Vector2) -> void:
	super._on_boss_death_started(at)
	if BossEncounter.remaining($Enemies, false).is_empty():
		probe_outcome = "boss_killed"
		get_tree().paused = true


func _on_wave_finished(wave_number: int) -> void:
	if WaveController.is_boss_wave(wave_number) and not BossEncounter.remaining($Enemies).is_empty():
		super._on_wave_finished(wave_number)
	else:
		probe_outcome = "wave_complete"
