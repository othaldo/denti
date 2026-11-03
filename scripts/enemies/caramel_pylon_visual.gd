class_name CaramelPylonVisual
extends Node2D

var pylon: Enemy

func _process(_delta: float) -> void:
	var beat := 1.0 + sin(pylon.animation_time * 2) * 0.07
	pylon.sprite.scale = pylon.sprite_base_scale * beat
	if is_instance_valid(pylon.boss_objective_owner):
		var ritual := pylon.boss_objective_owner.caramel_encounter.overload
		if ritual.trial().kind == CaramelTrialData.Kind.COURIERS:
			pylon.sprite.position.y = -absf(sin(pylon.animation_time * 2.5)) * 10
			pylon.sprite.rotation = sin(pylon.animation_time * 1.5) * 0.13
	queue_redraw()

func _draw() -> void:
	if pylon.health <= 0 or not is_instance_valid(pylon.boss_objective_owner): return
	var overload := pylon.boss_objective_owner.caramel_encounter.overload
	var open := overload.objective_open(pylon)
	var tint := Color("ffbe61") if open else Color("8ce4ed")
	draw_circle(Vector2(0, 18), 36, Color(0.15, 0.05, 0.12, 0.55))
	CombatDrawCache.arc(self, Vector2.ZERO, 37, 0, TAU, 40, Color(tint, 0.85), 3)
	if not open: draw_circle(Vector2.ZERO, 34, Color(0.45, 0.85, 0.95, 0.17))
	draw_line(Vector2(-24, 45), Vector2(24, 45), Color("352439"), 6)
	draw_line(Vector2(-24, 45), Vector2(-24 + 48 * pylon.health / pylon.max_health, 45), tint, 4)

