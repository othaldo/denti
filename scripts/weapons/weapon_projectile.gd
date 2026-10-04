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
var orbit_time: float = 0.0
var orbit_center: Vector2
var orbit_finished: bool = false
var orbit_hits: Array[int] = []
var enemy_index: EnemySpatialIndex
var body_sprite: Sprite2D
var tail_sprite: Sprite2D
var outline_sprite: Sprite2D
var visual_radius: float = 7.0
var flight_range: float = 0.0
var splash_radius: float = 0.0


func launch(start: Vector2, aim: Vector2, attack_damage: float, weapon: WeaponData, inventory: ItemInventory = null, is_critical: bool = false, weapon_tier: int = 1) -> void:
	global_position = start
	items = inventory
	enemy_index = items.player.enemy_index if items != null else null
	if enemy_index == null and get_parent() != null and get_parent().get_parent() != null:
		enemy_index = get_parent().get_parent().get_node_or_null("Enemies") as EnemySpatialIndex
	direction = aim.normalized()
	damage = attack_damage
	data = weapon
	tier = weapon_tier
	critical = is_critical
	splash_radius = weapon.splash_at_tier(tier)
	flight_range = weapon.range_at_tier(tier) + 40.0
	visual_radius = 11.0 if splash_radius > 0 or weapon.pierce_at_tier(tier) > 0 else 7.0
	pierces_left = weapon.pierce_at_tier(tier)
	return_factor = inventory.projectile_return_factor() if inventory != null and weapon.splash_at_tier(tier) <= 0.0 else 0.0
	if data.evolution_kind == &"halo":
		return_factor += 1.0
	_create_visuals()
	_sync_visuals()


func _create_visuals() -> void:
	if body_sprite != null:
		return
	var radius := visual_radius
	if data.projectile_shape != &"rocket":
		tail_sprite = _visual_sprite(CombatSpriteTextures.projectile_tail(data.projectile_color, radius))
		outline_sprite = _visual_sprite(CombatSpriteTextures.projectile_outline(data.projectile_color, radius))
		body_sprite = _visual_sprite(CombatSpriteTextures.projectile_body(data.projectile_color, radius))
	else:
		body_sprite = _visual_sprite(CombatSpriteTextures.rocket(data.projectile_color))


func _visual_sprite(texture: Texture2D) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.texture = texture
	visual.scale = Vector2.ONE / CombatSpriteTextures.RESOLUTION
	add_child(visual)
	return visual


func _sync_visuals() -> void:
	if body_sprite == null:
		return
	body_sprite.visible = impact_time <= 0.0
	if tail_sprite != null:
		tail_sprite.visible = body_sprite.visible
		tail_sprite.rotation = direction.angle()
		outline_sprite.visible = body_sprite.visible
		var radius := visual_radius
		outline_sprite.scale = Vector2.ONE * (radius + sin(animation_time * 20.0)) / (radius + 1.0) / CombatSpriteTextures.RESOLUTION
	else:
		body_sprite.rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if orbit_time > 0:
		orbit_time = maxf(orbit_time - delta, 0)
		animation_time += delta
		global_position = orbit_center + Vector2.from_angle(animation_time * 9) * data.evolution_radius
		for enemy in EnemySpatialIndex.circle(get_tree(), enemy_index, orbit_center, data.evolution_radius):
			if enemy.health > 0 and not orbit_hits.has(enemy.get_instance_id()):
				orbit_hits.append(enemy.get_instance_id())
				enemy.take_damage(damage * data.evolution_damage_factor, null, false, &"evolution")
		_sync_visuals()
		if orbit_time <= 0:
			_start_return()
		return
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
	var travel_left := maxf(flight_range - traveled, 0.0)
	var step := direction * minf(data.projectile_speed * delta, travel_left)
	var previous_position := global_position
	global_position += step
	traveled += step.length()
	if returning and not return_rearmed and traveled >= 32.0:
		hit_ids.clear()
		return_rearmed = true
	var collisions := EnemySpatialIndex.segment(get_tree(), enemy_index, previous_position, global_position, HIT_RADIUS, false, hit_ids)
	if collisions.size() > 1:
		collisions.sort_custom(func(a: Enemy, b: Enemy) -> bool:
			var a_distance := (a.global_position - previous_position).dot(direction)
			var b_distance := (b.global_position - previous_position).dot(direction)
			return a.spatial_order < b.spatial_order if a_distance == b_distance else a_distance < b_distance)
	for enemy in collisions:
		if enemy.health <= 0.0:
			continue
		if splash_radius > 0.0:
			global_position = Geometry2D.get_closest_point_to_segment(enemy.global_position, previous_position, global_position)
			_explode()
			return
		hit_ids.append(enemy.get_instance_id())
		var collision_point := Geometry2D.get_closest_point_to_segment(enemy.global_position, previous_position, global_position)
		WeaponAttackShapes.hit(enemy, data, tier, damage, critical, items, direction)
		if returning:
			return_hits_left -= 1
			if return_hits_left <= 0:
				global_position = collision_point
				impact_time = IMPACT_DURATION
				break
			continue
		if pierces_left <= 0:
			global_position = collision_point
			if return_factor > 0.0:
				_start_return()
			else:
				impact_time = IMPACT_DURATION
			break
		pierces_left -= 1
	if impact_time <= 0.0 and traveled >= flight_range:
		if splash_radius > 0.0:
			_explode()
		elif return_factor > 0.0 and not returning:
			_start_return()
		else:
			queue_free()
	_sync_visuals()
	if impact_time > 0.0:
		queue_redraw()


func _start_return() -> void:
	if data.evolution_kind == &"halo" and not orbit_finished:
		orbit_finished = true
		orbit_time = data.evolution_duration
		orbit_center = global_position
		return
	returning = true
	traveled = 0.0
	damage *= return_factor
	critical = false
	return_hits_left = maxi(roundi(return_factor / 0.35), 1)
	queue_redraw()


func _explode() -> void:
	for enemy in EnemySpatialIndex.circle(get_tree(), enemy_index, global_position, splash_radius):
		if enemy.health > 0:
			var push_direction := global_position.direction_to(enemy.global_position)
			WeaponAttackShapes.hit(enemy, data, tier, damage, critical, items, direction if push_direction.is_zero_approx() else push_direction)
	impact_time = IMPACT_DURATION
	_sync_visuals()
	queue_redraw()


func save_state(indices: Dictionary) -> Dictionary:
	var hits: Array[int] = []
	var orbit: Array[int] = []
	for id in hit_ids:
		if indices.has(id):
			hits.append(indices[id])
	for id in orbit_hits:
		if indices.has(id):
			orbit.append(indices[id])
	return {"id": str(data.id), "tier": tier, "x": global_position.x, "y": global_position.y,
		"dx": direction.x, "dy": direction.y, "damage": damage, "critical": critical,
		"traveled": traveled, "animation": animation_time, "impact": impact_time, "pierce": pierces_left,
		"hits": hits, "factor": return_factor, "returning": returning, "rearmed": return_rearmed,
		"return_hits": return_hits_left, "orbit": orbit_time, "cx": orbit_center.x, "cy": orbit_center.y,
		"orbit_finished": orbit_finished, "orbit_hits": orbit}


func restore_state(saved: Dictionary, inventory: ItemInventory, enemies: Array[Node]) -> void:
	launch(Vector2(saved.x, saved.y), Vector2(saved.dx, saved.dy), maxf(saved.damage, 0),
		WeaponCatalog.by_id(StringName(saved.id)), inventory, bool(saved.get("critical", false)), clampi(saved.get("tier", 1), 1, 4))
	traveled = maxf(saved.get("traveled", 0), 0)
	animation_time = maxf(saved.get("animation", 0), 0)
	impact_time = clampf(saved.get("impact", 0), 0, IMPACT_DURATION)
	pierces_left = maxi(saved.get("pierce", 0), 0)
	return_factor = maxf(saved.get("factor", 0), 0)
	returning = bool(saved.get("returning", false))
	return_rearmed = bool(saved.get("rearmed", false))
	return_hits_left = maxi(saved.get("return_hits", 0), 0)
	orbit_time = clampf(saved.get("orbit", 0), 0, data.evolution_duration)
	orbit_center = Vector2(saved.get("cx", 0), saved.get("cy", 0))
	orbit_finished = bool(saved.get("orbit_finished", false))
	for index in saved.get("hits", []):
		if index >= 0 and index < enemies.size():
			hit_ids.append(enemies[index].get_instance_id())
	for index in saved.get("orbit_hits", []):
		if index >= 0 and index < enemies.size():
			orbit_hits.append(enemies[index].get_instance_id())

	_sync_visuals()
	if impact_time > 0.0:
		queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if impact_time > 0.0:
		var progress := 1.0 - impact_time / IMPACT_DURATION
		var radius := data.splash_at_tier(tier) if data.splash_at_tier(tier) > 0.0 else 20.0
		CombatDrawCache.arc(self, Vector2.ZERO, radius * progress, 0.0, TAU, 40, Color(data.projectile_color, 1.0 - progress), 4.0)
		return
