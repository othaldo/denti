class_name WeaponProjectile
extends Node2D

const HIT_RADIUS := 10.0
const IMPACT_DURATION := 0.18

var data: WeaponData
var direction: Vector2
var damage: float
var traveled: float = 0.0
var animation_time: float = 0.0
var impact_time: float = 0.0
var pierces_left: int = 0
var hit_ids: Array[int] = []
var items: ItemInventory
var critical: bool = false
var return_factor: float = 0.0
var returning: bool = false
var return_rearmed: bool = false
var return_hits_left: int = 0
var tier: int = 1


func launch(start: Vector2, aim: Vector2, attack_damage: float, weapon: WeaponData, inventory: ItemInventory = null, is_critical: bool = false, weapon_tier: int = 1) -> void:
	global_position = start
	direction = aim.normalized()
	damage = attack_damage
	data = weapon
	tier = weapon_tier
	items = inventory
	critical = is_critical
	pierces_left = weapon.pierce_at_tier(tier)
	return_factor = inventory.projectile_return_factor() if inventory != null and weapon.splash_at_tier(tier) <= 0.0 else 0.0


func _physics_process(delta: float) -> void:
	if impact_time > 0.0:
		impact_time -= delta
		queue_redraw()
		if impact_time <= 0.0:
			queue_free()
		return
	animation_time += delta
	if returning:
		if items == null or global_position.distance_to(items.player.global_position) <= 24.0:
			queue_free()
			return
		direction = global_position.direction_to(items.player.global_position)
	var step := direction * data.projectile_speed * delta
	global_position += step
	traveled += step.length()
	if traveled >= data.range_at_tier(tier) + 40.0:
		if return_factor > 0.0 and not returning:
			_start_return()
		else:
			queue_free()
		return
	if returning and not return_rearmed and traveled >= 32.0:
		hit_ids.clear()
		return_rearmed = true
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or hit_ids.has(enemy.get_instance_id()):
			continue
		if global_position.distance_to(enemy.global_position) > enemy.data.radius + HIT_RADIUS:
			continue
		if data.splash_at_tier(tier) > 0.0:
			_explode()
			return
		hit_ids.append(enemy.get_instance_id())
		if data.knockback_at_tier(tier) > 0.0:
			enemy.global_position += direction * data.knockback_at_tier(tier) * (1.0 - enemy.data.knockback_resistance)
		enemy.take_damage(data.damage_against(enemy, items.modify_damage(enemy, data, damage) if items != null else damage, tier), data, critical)
		if returning:
			return_hits_left -= 1
			if return_hits_left <= 0:
				impact_time = IMPACT_DURATION
				break
			continue
		if pierces_left <= 0:
			if return_factor > 0.0:
				_start_return()
			else:
				impact_time = IMPACT_DURATION
			break
		pierces_left -= 1
	queue_redraw()


func _start_return() -> void:
	returning = true
	traveled = 0.0
	damage *= return_factor
	critical = false
	return_hits_left = maxi(roundi(return_factor / 0.35), 1)
	queue_redraw()


func _explode() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and global_position.distance_to(enemy.global_position) <= data.splash_at_tier(tier) + enemy.data.radius:
			enemy.take_damage(data.damage_against(enemy, items.modify_damage(enemy, data, damage) if items != null else damage, tier), data, critical)
	impact_time = IMPACT_DURATION
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if impact_time > 0.0:
		var progress := 1.0 - impact_time / IMPACT_DURATION
		var radius := data.splash_at_tier(tier) if data.splash_at_tier(tier) > 0.0 else 20.0
		draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 40, Color(data.projectile_color, 1.0 - progress), 4.0)
		return
	var color := data.projectile_color
	var radius := 11.0 if data.splash_at_tier(tier) > 0.0 or data.pierce_at_tier(tier) > 0 else 7.0
	for index in 3:
		var tail := -direction * (float(index) + 1.0) * 8.0
		draw_circle(tail, radius * (0.75 - float(index) * 0.16), Color(color, 0.34 - float(index) * 0.08))
	draw_circle(Vector2.ZERO, radius + sin(animation_time * 20.0) * 1.0, Color(0.11, 0.24, 0.27, 0.42))
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2(-2.5, -2.5), radius * 0.32, Color.WHITE)
