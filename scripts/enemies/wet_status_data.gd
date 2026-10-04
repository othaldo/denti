class_name WetStatusData
extends Resource

# Wet affects locomotion, not attack clocks, projectiles or telegraphed charges.
@export_range(0.0, 0.5, 0.01) var normal_slow: float = 0.20
@export_range(0.0, 0.5, 0.01) var elite_slow: float = 0.10
@export_range(0.0, 0.5, 0.01) var boss_slow: float = 0.05


func speed_factor(enemy: EnemyData) -> float:
	var slow := boss_slow if enemy.is_boss else (elite_slow if enemy.is_elite else normal_slow)
	return 1.0 - clampf(slow, 0.0, 0.5)


func short_text() -> String:
	return "-%d %% Lauftempo" % roundi(normal_slow * 100.0)


func effect_text() -> String:
	return "%s (Eliten -%d %%, Bosse -%d %%; Anstürme unverändert)" % [short_text(), roundi(elite_slow * 100.0), roundi(boss_slow * 100.0)]
