class_name StatusAttackData
extends Resource

@export var kind: DentiStatus.Type = DentiStatus.Type.POISON
@export_range(0.1, 12.0, 0.1) var tick_damage: float = 1.5
@export_range(1.0, 6.0, 0.1) var duration: float = 4.0

func payload(damage_factor: float = 1.0, duration_factor: float = 1.0) -> Dictionary:
	return DentiStatus.sanitize({"kind": kind, "damage": tick_damage * damage_factor, "duration": duration * duration_factor})
