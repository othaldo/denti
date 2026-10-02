class_name EnemyStatusRules
extends RefCounted

const POISON: StatusAttackData = preload("res://data/statuses/poison.tres")
const BLEED: StatusAttackData = preload("res://data/statuses/bleed.tres")
const DAMAGE_STEP := 0.035
const LATE_STEPS_CAP := 14
const ENDLESS_DAMAGE_STEP := 0.01
const ENDLESS_DAMAGE_CAP := 0.50
const ELITE_TRAIT_FACTOR := 1.4
const ELITE_TRAIT_CAP := 0.45
const ENDLESS_SPECIALIST_WEIGHT_STEP := 0.035

static func first_wave(kind: DentiStatus.Type, difficulty: DifficultyData) -> int:
	return difficulty.poison_first_wave if kind == DentiStatus.Type.POISON else difficulty.bleed_first_wave

static func damage_factor(wave: int, difficulty: DifficultyData) -> float:
	# Status damage has its own bounded curve; never compound contact/overtime.
	return difficulty.status_damage_multiplier * (1.0 + clampi(wave - 6, 0, LATE_STEPS_CAP) * DAMAGE_STEP + clampf((wave - 20) * ENDLESS_DAMAGE_STEP, 0.0, ENDLESS_DAMAGE_CAP))

static func trait_chance(wave: int, difficulty: DifficultyData, elite: bool = false) -> float:
	if wave < difficulty.status_trait_first_wave:
		return 0.0
	var chance := minf((wave - difficulty.status_trait_first_wave + 1) * difficulty.status_trait_chance_step, difficulty.status_trait_chance_cap)
	return minf(chance * ELITE_TRAIT_FACTOR, ELITE_TRAIT_CAP) if elite else chance

static func attacks_for(data: EnemyData, wave: int, difficulty: DifficultyData, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect: StatusAttackData in data.inflicted_statuses:
		if effect != null:
			result.append(effect.payload(damage_factor(wave, difficulty), difficulty.status_duration_multiplier))
	if not result.is_empty() or data.is_boss or not data.allow_random_status_trait:
		return DentiStatus.sanitize_attacks(result)
	var chance := trait_chance(wave, difficulty, data.is_elite)
	if chance <= 0.0 or (rng.randf() if rng != null else randf()) >= chance:
		return result
	var choices: Array[StatusAttackData] = []
	if wave >= difficulty.poison_first_wave:
		choices.append(POISON)
	if wave >= difficulty.bleed_first_wave:
		choices.append(BLEED)
	if not choices.is_empty():
		var index := rng.randi_range(0, choices.size() - 1) if rng != null else randi_range(0, choices.size() - 1)
		result.append(choices[index].payload(damage_factor(wave, difficulty), difficulty.status_duration_multiplier))
	return result

static func specialist_weight(kind: DentiStatus.Type, wave: int, difficulty: DifficultyData) -> float:
	var start := first_wave(kind, difficulty)
	if wave < start:
		return 0.0
	# Keep their share relevant as the existing ordinary-role weights grow.
	var endless_weight := 1.0 + maxi(wave - 20, 0) * ENDLESS_SPECIALIST_WEIGHT_STEP
	return minf(0.6 + (wave - start) * 0.05, 1.4) * difficulty.status_specialist_weight * endless_weight
