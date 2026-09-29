class_name WaveController
extends Node

signal enemy_requested(data: EnemyData)
signal boss_requested(data: EnemyData)
signal horde_requested(data: EnemyData, count: int)
signal wave_finished(wave_number: int)

const DURATION := 45.0
const MAX_WAVES := 20
const MINI_BOSS_INTERVAL := 5
const SPAWN_INTERVAL_START := 1.4
const SPAWN_INTERVAL_WAVE_STEP := 0.055
const SPAWN_INTERVAL_ACCELERATION := 0.012
const SPAWN_INTERVAL_MIN := 0.35
const MOB_HEALTH_WAVE_STEP := 0.17
const BOSS_HEALTH_WAVE_STEP := 0.27
const MOB_DEFENSE_WAVE_STEP := 0.01
const BOSS_DEFENSE_WAVE_STEP := 0.006
const MAX_DAMAGE_REDUCTION := 0.42
const ENEMY_DAMAGE_WAVE_STEP := 0.06
const PLAQUE: EnemyData = preload("res://data/enemies/plaque.tres")
const BACTERIA: EnemyData = preload("res://data/enemies/bacteria.tres")
const SUGAR: EnemyData = preload("res://data/enemies/sugar.tres")
const ACID_SPITTER: EnemyData = preload("res://data/enemies/acid_spitter.tres")
const BOSS: EnemyData = preload("res://data/enemies/cavity_king.tres")
const FINAL_BOSS: EnemyData = preload("res://data/enemies/cavity_emperor.tres")

var remaining: float = DURATION
var spawn_cooldown: float = 0.0
var active: bool = false
var current_wave: int = 0
var horde_waves: Array[int] = []
var horde_spawned: bool = false


func plan_hordes() -> void:
	horde_waves = [4, randi_range(7, 8), randi_range(11, 13), randi_range(16, 18)]


static func is_boss_wave(wave_number: int) -> bool:
	return wave_number > 0 and wave_number % MINI_BOSS_INTERVAL == 0


static func health_multiplier(data: EnemyData, wave_number: int) -> float:
	var step := BOSS_HEALTH_WAVE_STEP if data.is_boss else MOB_HEALTH_WAVE_STEP
	return 1.0 + maxi(wave_number - 1, 0) * step


static func damage_reduction(data: EnemyData, wave_number: int) -> float:
	var step := BOSS_DEFENSE_WAVE_STEP if data.is_boss else MOB_DEFENSE_WAVE_STEP
	return clampf(data.damage_reduction + maxi(wave_number - 1, 0) * step, 0.0, MAX_DAMAGE_REDUCTION)


func next_wave_preview() -> String:
	var next_wave := current_wave + 1
	var details: Array[String] = []
	if next_wave == 2:
		details.append("Bakterium")
	elif next_wave == 3:
		details.append("Zuckerstück")
	elif next_wave == 4:
		details.append("Säurespucker")
	if next_wave == MAX_WAVES:
		details.append(FINAL_BOSS.display_name)
	elif is_boss_wave(next_wave):
		details.append(BOSS.display_name)
	if horde_waves.has(next_wave):
		details.append("%s-Horde" % _horde_data(next_wave).display_name)
	return "Welle %d: %s" % [next_wave, " · ".join(details)] if not details.is_empty() else "Nächste Welle: %d" % next_wave


func start_next_wave() -> void:
	if horde_waves.is_empty():
		plan_hordes()
	current_wave += 1
	remaining = DURATION
	spawn_cooldown = 0.0
	horde_spawned = false
	active = true
	if is_boss_wave(current_wave):
		boss_requested.emit(FINAL_BOSS if current_wave == MAX_WAVES else BOSS)


func _process(delta: float) -> void:
	if not active:
		return
	remaining = maxf(remaining - delta, 0.0)
	if remaining <= 0.0:
		active = false
		wave_finished.emit(current_wave)
		return
	if not horde_spawned and horde_waves.has(current_wave) and remaining <= DURATION - 18.0:
		horde_spawned = true
		horde_requested.emit(_horde_data(current_wave), 5 + current_wave)
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		enemy_requested.emit(_choose_enemy())
		var elapsed := DURATION - remaining
		spawn_cooldown = maxf(SPAWN_INTERVAL_START - elapsed * SPAWN_INTERVAL_ACCELERATION - (current_wave - 1) * SPAWN_INTERVAL_WAVE_STEP, SPAWN_INTERVAL_MIN)


func _choose_enemy() -> EnemyData:
	var elapsed := DURATION - remaining
	var choices: Array[EnemyData] = [PLAQUE]
	var weights: Array[float] = [5.0]
	if current_wave >= 2 and elapsed >= 8.0:
		choices.append(BACTERIA)
		weights.append(2.0 + (current_wave - 2) * 0.12)
	if current_wave >= 3 and elapsed >= 12.0:
		choices.append(SUGAR)
		weights.append(1.3 + (current_wave - 3) * 0.08)
	if current_wave >= 4 and elapsed >= 15.0:
		choices.append(ACID_SPITTER)
		weights.append(1.0 + (current_wave - 4) * 0.12)
	var total_weight := 0.0
	for weight in weights:
		total_weight += weight
	var roll := randf() * total_weight
	for index in choices.size():
		roll -= weights[index]
		if roll < 0.0:
			return choices[index]
	return PLAQUE


func _horde_data(wave_number: int) -> EnemyData:
	return PLAQUE if wave_number <= 5 else BACTERIA
