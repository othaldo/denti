class_name DifficultyData
extends Resource

@export var id: StringName = &"normal"
@export var display_name: String = "Normal"
@export_multiline var description: String = ""
@export var spawn_interval_multiplier: float = 1.0
@export var horde_size_multiplier: float = 1.0
@export var extra_burst_first_wave: int = 0
@export var elite_wave_offset: int = 0
@export var elite_group_bonus: int = 0
@export var enemy_damage_multiplier: float = 1.0
@export var ranged_interval_multiplier: float = 1.0
@export var boss_volley_bonus: int = 0
@export var reward_chance_multiplier: float = 1.0
@export_group("Player ailments")
@export var poison_first_wave: int = 6
@export var bleed_first_wave: int = 8
@export var status_trait_first_wave: int = 9
@export var status_trait_chance_step: float = 0.012
@export var status_trait_chance_cap: float = 0.18
@export var status_damage_multiplier: float = 1.0
@export var status_duration_multiplier: float = 1.0
@export var status_specialist_weight: float = 1.0


# Extra bonuses at wave 1 / wave 20, layered on the shared Normal curves.
@export_group("Enemy stat curves")
@export var enemy_health_bonus: Vector2 = Vector2.ZERO
@export var enemy_defense_bonus: Vector2 = Vector2.ZERO
@export var enemy_speed_bonus: Vector2 = Vector2.ZERO
@export var enemy_damage_late_bonus: float = 0.0

func stat_bonus(endpoints: Vector2, wave_number: int) -> float:
	var progress := clampf(float(wave_number - 1) / 19.0, 0.0, 1.0)
	return lerpf(endpoints.x, endpoints.y, (progress + progress * progress) * 0.5)

func health_factor(wave_number: int) -> float:
	return 1.0 + stat_bonus(enemy_health_bonus, wave_number)

func speed_factor(wave_number: int) -> float:
	return 1.0 + stat_bonus(enemy_speed_bonus, wave_number)

func defense_bonus(wave_number: int) -> float:
	return stat_bonus(enemy_defense_bonus, wave_number)

func damage_factor(wave_number: int) -> float:
	return enemy_damage_multiplier + stat_bonus(Vector2(0.0, enemy_damage_late_bonus), wave_number)
