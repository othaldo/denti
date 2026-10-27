class_name DashData
extends Resource

@export var capacity: float = 100.0
@export var cost: float = 100.0
@export var distance: float = 150.0
@export var duration: float = 0.16
@export var recovery_delay: float = 0.35
@export_range(1.0, 100.0, 0.5) var recharge_rate: float = 25.0
@export var cooldown: float = 0.5
@export var contact_damage_multiplier: float = 1.5
@export var max_stamina_bonus: float = 400.0

func refill_time(maximum: float) -> float:
	return maximum / recharge_rate
