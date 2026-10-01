class_name WaveController
extends Node

signal enemy_requested(data: EnemyData)
signal boss_requested(data: EnemyData)
signal horde_requested(data: EnemyData, count: int)
signal elite_requested(data: EnemyData)
signal wave_finished(wave_number: int)

const DURATION := 45.0
const MAX_WAVES := 20
const MINI_BOSS_INTERVAL := 5
const HORDE_TIME_FRACTION := 0.40
const ELITE_TIME_START_FRACTION := 0.40
const ELITE_TIME_END_FRACTION := 0.56
const ELITE_SECOND_START_FRACTION := 0.62
const ELITE_SECOND_END_FRACTION := 0.69
const ELITE_THIRD_START_FRACTION := 0.78
const ELITE_THIRD_END_FRACTION := 0.84
const SPAWN_INTERVAL_START := 1.25
const SPAWN_INTERVAL_WAVE_STEP := 0.06
const SPAWN_INTERVAL_ACCELERATION := 0.012
const SPAWN_INTERVAL_MIN := 0.24
const BOSS_WAVE_SPAWN_INTERVAL_MIN := 0.30
const MOB_HEALTH_WAVE_STEP := 0.17
const MOB_HEALTH_LATE_ACCELERATION := 0.018
const BOSS_HEALTH_WAVE_STEP := 0.27
const MOB_DEFENSE_WAVE_STEP := 0.01
const MOB_DEFENSE_LATE_STEP := 0.004
const BOSS_DEFENSE_WAVE_STEP := 0.006
const MAX_DAMAGE_REDUCTION := 0.42
const ENEMY_DAMAGE_WAVE_STEP := 0.06
const MOB_DAMAGE_LATE_STEP := 0.03
const ENEMY_SPEED_WAVE_STEP := 0.025
const MOB_SPEED_LATE_STEP := 0.018
const MOB_LATE_START_WAVE := 6
const LOOT_CHANCE_WAVE_STEP := 0.04
const LOOT_CHANCE_MIN := 0.38
const BOSS_WAVE_LOOT_CHANCE_STEP := 0.035
const BOSS_WAVE_LOOT_CHANCE_MIN := 0.45
const ACID_VOLLEY_WAVE_3 := 7
const ACID_VOLLEY_WAVE_5 := 14
const RANGED_INTERVAL_WAVE_STEP := 0.025
const RANGED_INTERVAL_MIN := 0.65
const PLAQUE: EnemyData = preload("res://data/enemies/plaque.tres")
const BACTERIA: EnemyData = preload("res://data/enemies/bacteria.tres")
const SUGAR: EnemyData = preload("res://data/enemies/sugar.tres")
const ACID_SPITTER: EnemyData = preload("res://data/enemies/acid_spitter.tres")
const ACID_CROWN: EnemyData = preload("res://data/enemies/acid_crown.tres")
const HUNT_GERM: EnemyData = preload("res://data/enemies/hunt_germ.tres")
const CAVITY_COUNT: EnemyData = preload("res://data/enemies/cavity_count.tres")
const CAVITY_PRINCE: EnemyData = preload("res://data/enemies/cavity_prince.tres")
const CAVITY_KING: EnemyData = preload("res://data/enemies/cavity_king.tres")
const CAVITY_EMPEROR: EnemyData = preload("res://data/enemies/cavity_emperor.tres")
# Compatibility aliases for older tests/tools that refer to the first and final boss.
const BOSS: EnemyData = CAVITY_COUNT
const FINAL_BOSS: EnemyData = CAVITY_EMPEROR

var duration: float = DURATION
var remaining: float = DURATION
var spawn_cooldown: float = 0.0
var active: bool = false
var current_wave: int = 0
var horde_waves: Array[int] = []
var horde_spawned: bool = false
var burst_times: Array[float] = []
var burst_index: int = 0
var elite_times: Array[float] = []
var elite_counts: Array[int] = []
var elite_index: int = 0
var current_profile_id: StringName = &""
var next_profile_id: StringName = &""
var difficulty_id: StringName = &"normal"
var endless_enabled: bool = false


func plan_hordes() -> void:
	horde_waves = [4, randi_range(7, 8), randi_range(11, 13), randi_range(16, 18)]


static func is_boss_wave(wave_number: int) -> bool:
	return wave_number > 0 and wave_number % MINI_BOSS_INTERVAL == 0


static func duration_for_wave(wave_number: int) -> float:
	if wave_number >= EndlessRules.FIRST_WAVE:
		return EndlessRules.WAVE_DURATION
	if wave_number <= 0 or is_boss_wave(wave_number):
		return DURATION
	if wave_number <= 4:
		return 32.0 + wave_number * 3.0
	if wave_number <= 9:
		return 42.0
	if wave_number <= 14:
		return 46.0
	return 50.0


static func boss_for_wave(wave_number: int) -> EnemyData:
	if wave_number >= MAX_WAVES:
		return CAVITY_EMPEROR
	if wave_number >= 15:
		return CAVITY_KING
	if wave_number >= 10:
		return CAVITY_PRINCE
	return CAVITY_COUNT


static func elite_for_wave(wave_number: int) -> EnemyData:
	return HUNT_GERM if wave_number >= 12 and wave_number % 2 == 0 else ACID_CROWN


static func elite_groups_for_wave(wave_number: int, selected_difficulty_id: StringName = &"normal") -> Array[int]:
	var difficulty := DifficultyCatalog.by_id(selected_difficulty_id)
	if wave_number >= EndlessRules.FIRST_WAVE:
		var extra := EndlessRules.extra_elites(wave_number) + difficulty.elite_group_bonus
		if is_boss_wave(wave_number):
			return [clampi(extra, 1, EndlessRules.MAX_ELITE_GROUP)]
		return [clampi(2 + extra, 1, EndlessRules.MAX_ELITE_GROUP), clampi(1 + extra, 1, EndlessRules.MAX_ELITE_GROUP), 1]
	var stage_wave := wave_number + difficulty.elite_wave_offset
	if stage_wave < 8 or is_boss_wave(wave_number):
		return []
	var groups: Array[int]
	if stage_wave < 11:
		groups = [1]
	elif stage_wave < 14:
		groups = [1, 1]
	elif stage_wave < 17:
		groups = [2, 1]
	else:
		groups = [3, 2, 1]
	for index in groups.size():
		groups[index] += difficulty.elite_group_bonus
	return groups


static func elite_for_event(wave_number: int, event_index: int, member: int) -> EnemyData:
	return elite_for_wave(wave_number + ((event_index + member) % 2 if wave_number >= 12 else 0))


func elite_reserved_slots() -> int:
	var slots := 0
	for event_index in elite_counts.size():
		for member in elite_counts[event_index]:
			slots += 1 + elite_for_event(current_wave, event_index, member).escort_count
	return slots


static func health_multiplier(data: EnemyData, wave_number: int) -> float:
	if wave_number >= EndlessRules.FIRST_WAVE:
		return health_multiplier(data, EndlessRules.baseline_wave(wave_number)) * EndlessRules.health_factor(wave_number)
	if not data.is_boss and data.health_per_wave > 0.0:
		var late_waves := maxi(wave_number - MOB_LATE_START_WAVE, 0)
		return 1.0 + (maxi(wave_number - 1, 0) * data.health_per_wave + late_waves * late_waves * data.late_health_acceleration) / maxf(data.max_health, 1.0)
	var step := BOSS_HEALTH_WAVE_STEP if data.is_boss else MOB_HEALTH_WAVE_STEP
	var multiplier := 1.0 + maxi(wave_number - 1, 0) * step
	if not data.is_boss:
		var late_waves := maxi(wave_number - MOB_LATE_START_WAVE, 0)
		multiplier += late_waves * late_waves * MOB_HEALTH_LATE_ACCELERATION
	return multiplier


static func damage_reduction(data: EnemyData, wave_number: int) -> float:
	wave_number = EndlessRules.baseline_wave(wave_number)
	var step := BOSS_DEFENSE_WAVE_STEP if data.is_boss else MOB_DEFENSE_WAVE_STEP
	var reduction := data.damage_reduction + maxi(wave_number - 1, 0) * step
	if not data.is_boss:
		reduction += maxi(wave_number - MOB_LATE_START_WAVE, 0) * MOB_DEFENSE_LATE_STEP
	return clampf(reduction, 0.0, MAX_DAMAGE_REDUCTION)


static func enemy_damage_multiplier(data: EnemyData, wave_number: int) -> float:
	if wave_number >= EndlessRules.FIRST_WAVE:
		return enemy_damage_multiplier(data, EndlessRules.baseline_wave(wave_number)) * EndlessRules.damage_factor(wave_number)
	var multiplier := 1.0 + maxi(wave_number - 1, 0) * ENEMY_DAMAGE_WAVE_STEP
	if not data.is_boss:
		multiplier += maxi(wave_number - MOB_LATE_START_WAVE, 0) * MOB_DAMAGE_LATE_STEP
	return multiplier


static func enemy_speed_multiplier(data: EnemyData, wave_number: int) -> float:
	if wave_number >= EndlessRules.FIRST_WAVE:
		return enemy_speed_multiplier(data, EndlessRules.baseline_wave(wave_number)) * EndlessRules.speed_factor(wave_number)
	var multiplier := 1.0 + maxi(wave_number - 1, 0) * ENEMY_SPEED_WAVE_STEP
	if not data.is_boss:
		multiplier += maxi(wave_number - MOB_LATE_START_WAVE, 0) * MOB_SPEED_LATE_STEP
	return multiplier


static func loot_chance(wave_number: int) -> float:
	if is_boss_wave(wave_number):
		return maxf(1.0 - maxi(wave_number - 1, 0) * BOSS_WAVE_LOOT_CHANCE_STEP, BOSS_WAVE_LOOT_CHANCE_MIN)
	return maxf(1.0 - maxi(wave_number - 1, 0) * LOOT_CHANCE_WAVE_STEP, LOOT_CHANCE_MIN)


static func acid_volley_count(wave_number: int) -> int:
	return 5 if wave_number >= ACID_VOLLEY_WAVE_5 else (3 if wave_number >= ACID_VOLLEY_WAVE_3 else 1)


static func ranged_interval_multiplier(wave_number: int) -> float:
	return maxf(1.0 - maxi(wave_number - 1, 0) * RANGED_INTERVAL_WAVE_STEP, RANGED_INTERVAL_MIN)


func next_wave_preview() -> String:
	var next_wave := current_wave + 1
	var details: Array[String] = []
	if next_wave == 2:
		details.append("Bakterium")
	elif next_wave == 3:
		details.append("Zuckerstück")
	elif next_wave == 4:
		details.append("Säurespucker")
	if is_boss_wave(next_wave):
		details.append(boss_for_wave(next_wave).display_name)
	var profile := WaveProfileCatalog.by_id(next_profile_id)
	if profile != null:
		details.append("Muster: %s" % profile.display_name)
	if horde_waves.has(next_wave):
		details.append("%s-Horde" % _horde_data(next_wave).display_name)
	var elite_total := 0
	for count in elite_groups_for_wave(next_wave, difficulty_id):
		elite_total += count
	if elite_total == 1:
		details.append("Elite: %s" % elite_for_wave(next_wave).display_name)
	elif elite_total > 1:
		details.append("%d Eliten" % elite_total)
	return "Welle %d: %s" % [next_wave, " · ".join(details)] if not details.is_empty() else "Nächste Welle: %d" % next_wave


func prepare_next_wave_profile() -> StringName:
	if next_profile_id == &"" and (current_wave + 1 <= MAX_WAVES or endless_enabled) and not is_boss_wave(current_wave + 1):
		next_profile_id = _roll_profile(current_wave + 1, current_profile_id)
	return next_profile_id


func start_next_wave() -> void:
	if current_wave >= MAX_WAVES and not endless_enabled:
		return
	if horde_waves.is_empty():
		plan_hordes()
	current_wave += 1
	current_profile_id = &"" if is_boss_wave(current_wave) else (prepare_next_wave_profile() if next_profile_id == &"" else next_profile_id)
	next_profile_id = _roll_profile(current_wave + 1, current_profile_id)
	duration = duration_for_wave(current_wave)
	remaining = duration
	spawn_cooldown = 0.0
	horde_spawned = false
	plan_bursts()
	plan_elites()
	active = true
	if is_boss_wave(current_wave):
		boss_requested.emit(boss_for_wave(current_wave))
		if current_wave > MAX_WAVES and current_wave % 10 == 0:
			boss_requested.emit(CAVITY_KING if current_wave % 20 == 10 else CAVITY_PRINCE)


func _process(delta: float) -> void:
	if not active:
		return
	remaining = maxf(remaining - delta, 0.0)
	if remaining <= 0.0:
		active = false
		wave_finished.emit(current_wave)
		return
	if not horde_spawned and horde_waves.has(current_wave) and remaining <= duration * (1.0 - HORDE_TIME_FRACTION):
		horde_spawned = true
		horde_requested.emit(_horde_data(current_wave), maxi(roundi(float(5 + current_wave) * DifficultyCatalog.by_id(difficulty_id).horde_size_multiplier), 1))
	var elapsed := duration - remaining
	while elite_index < elite_times.size() and elapsed >= elite_times[elite_index]:
		for member in elite_counts[elite_index]:
			elite_requested.emit(elite_for_event(current_wave, elite_index, member))
		elite_index += 1
	while burst_index < burst_times.size() and elapsed >= burst_times[burst_index]:
		var index := burst_index
		burst_index += 1
		horde_requested.emit(_burst_data(index), _burst_count(index))
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		enemy_requested.emit(_choose_enemy())
		var spawn_floor := BOSS_WAVE_SPAWN_INTERVAL_MIN if is_boss_wave(current_wave) else SPAWN_INTERVAL_MIN
		spawn_cooldown = maxf(SPAWN_INTERVAL_START - elapsed * SPAWN_INTERVAL_ACCELERATION - (current_wave - 1) * SPAWN_INTERVAL_WAVE_STEP, spawn_floor) * DifficultyCatalog.by_id(difficulty_id).spawn_interval_multiplier / EndlessRules.density_factor(current_wave)


func plan_bursts() -> void:
	burst_times.clear()
	var difficulty := DifficultyCatalog.by_id(difficulty_id)
	if difficulty.extra_burst_first_wave > 0 and current_wave >= difficulty.extra_burst_first_wave:
		burst_times.append(randf_range(duration * 0.12, duration * 0.18))
	burst_times.append(randf_range(duration * 0.22, duration * 0.31))
	if current_wave >= 12 and not is_boss_wave(current_wave):
		burst_times.append(randf_range(duration * 0.40, duration * 0.47))
	burst_times.append(randf_range(duration * 0.58, duration * 0.67))
	if current_wave >= 6:
		burst_times.append(randf_range(duration * 0.82, duration * 0.89))
	burst_index = 0


func plan_elites() -> void:
	elite_times.clear()
	elite_counts = elite_groups_for_wave(current_wave, difficulty_id)
	elite_index = 0
	if elite_counts.is_empty():
		return
	elite_times.append(randf_range(duration * ELITE_TIME_START_FRACTION, duration * ELITE_TIME_END_FRACTION))
	if elite_counts.size() >= 2:
		elite_times.append(randf_range(duration * ELITE_SECOND_START_FRACTION, duration * ELITE_SECOND_END_FRACTION))
	if elite_counts.size() >= 3:
		elite_times.append(randf_range(duration * ELITE_THIRD_START_FRACTION, duration * ELITE_THIRD_END_FRACTION))


func _burst_data(index: int) -> EnemyData:
	match index:
		0:
			return BACTERIA if current_wave >= 7 else PLAQUE
		1:
			return SUGAR if current_wave >= 6 else (BACTERIA if current_wave >= 2 else PLAQUE)
		_:
			return ACID_SPITTER


func _burst_count(index: int) -> int:
	var base_count: int
	match index:
		0:
			base_count = 4 + current_wave / 2
		1:
			base_count = 5 + current_wave
		_:
			base_count = 2 + current_wave / 5 if is_boss_wave(current_wave) else 3 + current_wave / 3
	return clampi(roundi(float(base_count) * DifficultyCatalog.by_id(difficulty_id).horde_size_multiplier), 1, 60)


func _choose_enemy() -> EnemyData:
	var elapsed := duration - remaining
	var choices: Array[EnemyData] = [PLAQUE]
	var late_role_shift := 0 if is_boss_wave(current_wave) else maxi(current_wave - 10, 0)
	var weights: Array[float] = [maxf(5.0 - late_role_shift * 0.3, 2.0)]
	if current_wave >= 2 and elapsed >= 8.0:
		choices.append(BACTERIA)
		weights.append(2.0 + (current_wave - 2) * 0.12)
	if current_wave >= 3 and elapsed >= 12.0:
		choices.append(SUGAR)
		weights.append(1.3 + (current_wave - 3) * 0.08 + late_role_shift * 0.18)
	if current_wave >= 4 and elapsed >= 15.0:
		choices.append(ACID_SPITTER)
		weights.append(1.0 + (current_wave - 4) * 0.12 + late_role_shift * 0.25)
	var total_weight := 0.0
	var profile := WaveProfileCatalog.by_id(current_profile_id)
	for index in weights.size():
		var adjusted := weights[index] * profile.multiplier_for(choices[index]) if profile != null else weights[index]
		weights[index] = adjusted
		total_weight += adjusted
	var roll := randf() * total_weight
	for index in choices.size():
		roll -= weights[index]
		if roll < 0.0:
			return choices[index]
	return PLAQUE


func _horde_data(wave_number: int) -> EnemyData:
	return PLAQUE if wave_number <= 5 else BACTERIA


func _roll_profile(wave_number: int, avoid_id: StringName = &"") -> StringName:
	if (wave_number > MAX_WAVES and not endless_enabled) or is_boss_wave(wave_number):
		return &""
	return WaveProfileCatalog.roll_for_wave(wave_number, avoid_id)
