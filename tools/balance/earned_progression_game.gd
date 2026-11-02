extends "res://scripts/game/game.gd"
## Real rewards/shop flow; only input, random seeds and persistence are controlled.

var probe_seed := 0
var probe_dead := false
var probe_boss_killed := false


func _ready() -> void:
	super._ready()
	seed(probe_seed)


func _save_run() -> void:
	pass


func _save_completed_report(_won: bool) -> void:
	pass


func _sync_music() -> void:
	pass


func _on_player_died() -> void:
	probe_dead = true
	get_tree().paused = true


func _on_boss_death_started(at: Vector2) -> void:
	super._on_boss_death_started(at)
	if BossEncounter.remaining($Enemies, false).is_empty(): probe_boss_killed = true


func _show_level_choice() -> void:
	var earned_level := level - maxi(rewards.pending_levels - 1, 0)
	seed(probe_seed + wave.current_wave * 100003 + earned_level * 1009)
	super._show_level_choice()


func _open_shop() -> void:
	shop.rng.seed = probe_seed + wave.current_wave * 1000033
	super._open_shop()
