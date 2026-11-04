class_name CaramelBodyguard
extends BossCompanion

var encounter: CaramelEncounter

func _ready() -> void:
	setup(encounter.enemy, encounter.profile.enforcer, &"caramel_enforcer", encounter._cooking_bounds, _suspended)

func _suspended() -> bool:
	return encounter.enemy.health <= 0 or encounter.enemy.dying
