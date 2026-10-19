class_name DashData
extends Resource

@export var capacity: float = 100.0
@export var cost: float = 100.0
@export var distance: float = 150.0
@export var duration: float = 0.16
@export var recovery_delay: float = 0.35
@export var refill_duration: float = 4.0
@export var cooldown: float = 1.5
@export var max_stamina_bonus: float = 400.0

func recharge_per_second(maximum: float) -> float:
	return maximum / refill_duration
