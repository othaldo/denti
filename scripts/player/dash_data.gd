class_name DashData
extends Resource

@export var capacity: float = 100.0
@export var distance: float = 150.0
@export var duration: float = 0.16
@export var recovery_delay: float = 0.35
@export var recharge_per_second: float = 25.0
@export var cooldown: float = 1.5
@export var max_recovery_bonus: float = 400.0

func refill_seconds(bonus: float) -> float:
	return capacity / (recharge_per_second * (1.0 + clampf(bonus, 0, max_recovery_bonus) / 100.0))
