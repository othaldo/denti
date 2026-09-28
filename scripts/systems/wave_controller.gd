class_name WaveController
extends Node

signal enemy_requested(data: EnemyData)
signal boss_requested(data: EnemyData)
signal wave_finished(wave_number: int)

const DURATION := 45.0
const MAX_WAVES := 10
const PLAQUE: EnemyData = preload("res://data/enemies/plaque.tres")
const BACTERIA: EnemyData = preload("res://data/enemies/bacteria.tres")
const SUGAR: EnemyData = preload("res://data/enemies/sugar.tres")
const BOSS: EnemyData = preload("res://data/enemies/cavity_king.tres")

var remaining: float = DURATION
var spawn_cooldown: float = 0.0
var active: bool = false
var current_wave: int = 0


func start_next_wave() -> void:
	current_wave += 1
	remaining = DURATION
	spawn_cooldown = 0.0
	active = true
	if current_wave == MAX_WAVES:
		boss_requested.emit(BOSS)


func _process(delta: float) -> void:
	if not active:
		return
	remaining = maxf(remaining - delta, 0.0)
	if remaining <= 0.0:
		active = false
		wave_finished.emit(current_wave)
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		enemy_requested.emit(_choose_enemy())
		var elapsed := DURATION - remaining
		spawn_cooldown = maxf(1.25 - elapsed * 0.017 - (current_wave - 1) * 0.055, 0.32)


func _choose_enemy() -> EnemyData:
	var elapsed := DURATION - remaining
	var roll := randf()
	if elapsed > 28.0 and roll < 0.22 + (current_wave - 1) * 0.025:
		return SUGAR
	if elapsed > 12.0 and roll < 0.48 + (current_wave - 1) * 0.015:
		return BACTERIA
	return PLAQUE
