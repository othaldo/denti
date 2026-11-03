class_name CrownCourtData
extends Resource

@export var retinue_profile: ImperialRetinueData

@export var warning_seconds: float = 1.05
@export var followup_warning_seconds: float = 0.90
@export var impact_seconds: float = 0.22
@export var portal_warning_seconds: float = 1.0
@export var nerve_warning_seconds: float = 1.05
@export var needle_warning_seconds: float = 1.20
@export var turn_seconds: float = 0.7
@export var position_seconds: float = 0.40
@export var recovery_seconds: float = 0.40
@export var open_seconds: float = 1.25
@export var recovery_settle_seconds: float = 0.25
@export var recovery_move_factor: float = 0.50
@export var court_radius: float = 390.0
@export var court_half_angle: float = 30.0
@export var verdict_damage_factor: float = 0.7
@export var verdict_lead_seconds: float = 0.0
@export var verdict_lead_distance: float = 0.0
@export var guard_turn_degrees: float = 90.0
@export var portal_angle_step_radians: float = 0.3
@export var nerve_cycle_radians: float = 0.31
@export var nerve_step_radians: float = 0.19
@export var guard_half_angle: float = 70.0
@export var guard_damage_factor: float = 0.55
@export var open_damage_factor: float = 1.2
@export var portal_half_length: float = 230.0
@export var portal_lead_distance: float = 180.0
@export var preferred_distance: float = 320.0
@export var court_approach_distance: float = 240.0
@export var court_position_tolerance: float = 20.0
@export var movement_factor: float = 1.5
@export var portal_drift_factor: float = 0.16
@export var shots: BossProjectileData = preload("res://data/encounters/emperor_shots.tres")
@export var lance: BossProjectileData = preload("res://data/encounters/emperor_lance.tres")
@export var needles: BossProjectileData = preload("res://data/encounters/emperor_needles.tres")
@export var needle_lead_seconds: float = 0.45
@export var needle_lead_distance: float = 140.0
@export var needle_spacing: float = 0.16
@export var action_bonus: int = 0
@export var max_verdicts: int = 3
@export var max_portals: int = 3
@export var max_pulses: int = 3
@export var reposition_seconds: float = 0.32
@export var reposition_move_factor: float = 1.0
@export var combo_phase: int = 1
@export var combo_warning_seconds: float = 1.4

func for_difficulty(difficulty: DifficultyData) -> CrownCourtData:
	var result := duplicate(true) as CrownCourtData
	if retinue_profile != null: result.retinue_profile = retinue_profile.for_difficulty(difficulty)
	result.shots = shots.duplicate() as BossProjectileData
	result.lance = lance.duplicate() as BossProjectileData
	result.needles = needles.duplicate() as BossProjectileData
	result.action_bonus = clampi(difficulty.boss_volley_bonus, -1, 2)
	# Easy retains direct aim. Other tiers expose the same fixed, readable lead.
	if result.action_bonus < 0:
		result.verdict_lead_seconds = 0.0
		result.verdict_lead_distance = 0.0
	var extra := maxi(result.action_bonus - 1, 0)
	result.max_verdicts += extra
	result.max_portals += extra
	result.max_pulses += extra
	result.portal_lead_distance *= 0.45 + 0.55 * (result.action_bonus + 1)
	result.portal_drift_factor = 0.10 + 0.06 * (result.action_bonus + 1)
	result.movement_factor *= 0.75 + 0.25 * (result.action_bonus + 1)
	result.position_seconds *= difficulty.boss_recovery_multiplier
	result.recovery_seconds *= difficulty.boss_recovery_multiplier
	result.combo_phase = 0 if result.action_bonus >= 1 else (2 if result.action_bonus < 0 else combo_phase)
	result.shots.speed *= difficulty.boss_projectile_speed_multiplier
	result.lance.speed *= difficulty.boss_projectile_speed_multiplier
	result.needles.speed *= difficulty.boss_projectile_speed_multiplier
	return result

func verdicts(phase: int) -> int: return mini(2 + action_bonus + (1 if phase >= 2 else 0), max_verdicts)
func portals(phase: int) -> int: return mini(2 + action_bonus + (1 if phase >= 2 else 0), max_portals)
func pulses(phase: int) -> int: return mini(2 + action_bonus + (1 if phase >= 1 else 0), max_pulses)
func rays(phase: int) -> int: return 12 + action_bonus * 2 + (4 if phase >= 2 else 0)
func fan_count() -> int: return 5 + action_bonus * 2
func needle_count() -> int: return mini(5 + action_bonus * 2, 7)
