class_name WeaponInstance
extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/game/weapon_projectile.tscn")

var data: WeaponData
var tier: int = 1
var invested_coins: int = 0
var cooldown: float = 0.0
var attack_time: float = 0.0
var attack_duration: float = 0.32
var idle_time: float = 0.0
var aim: Vector2 = Vector2.RIGHT
var home_position: Vector2 = Vector2.ZERO
var hold_position: Vector2 = Vector2.ZERO
var visual_density: float = 1.0
var attack_phase: float = 0.0
var engagement_pending: bool = true
var aim_distance: float = 1000.0
var hit_point: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var working_head: WeaponWorkingHead
var player: Player
var strike := WeaponStrike.new()
var focus_target_id: int = 0
var focus_hits: int = 0
var focus_time: float = 0.0


func configure(weapon: WeaponData, weapon_tier: int = 1) -> void:
	data = weapon
	tier = clampi(weapon_tier, 1, 4)
	name = "%s_%d" % [str(data.id), get_instance_id()]


func _ready() -> void:
	player = get_parent().get_parent() as Player
	sprite = Sprite2D.new()
	sprite.texture = data.sprite
	sprite.offset = (Vector2(0.5, 0.5) - data.grip_anchor) * data.sprite.get_size()
	add_child(sprite)
	if data.working_head_radius > 0.0:
		working_head = WeaponWorkingHead.new()
		working_head.configure(data)
		sprite.add_child(working_head)
	z_index = 1
	update_visual()


func progress() -> float:
	return 1.0 - attack_time / attack_duration if attack_time > 0.0 else -1.0


func muzzle_position() -> Vector2:
	return sprite.to_global(WeaponMotion.tip_local(data))


func update_visual() -> void:
	if sprite == null:
		return
	var home := home_position if WeaponMotion.is_contact(data) else hold_position
	var pose_data := WeaponMotion.pose(data, tier, home, aim, progress(), idle_time, aim_distance, visual_density)
	sprite.position = pose_data.position
	sprite.rotation = pose_data.rotation
	sprite.scale = pose_data.scale
	# Denti's face stays readable even when a rear hand thrusts across the body.
	z_index = -1 if WeaponMotion.is_contact(data) or sprite.position.y < -12.0 else 1


func _physics_process(delta: float) -> void:
	idle_time += delta
	if working_head != null:
		working_head.rotation += delta * TAU * data.head_turns_per_second * (1.0 if attack_time > 0.0 else 0.15)
	focus_time = maxf(focus_time - delta, 0.0)
	cooldown = maxf(cooldown - delta, 0.0)
	if attack_time > 0.0:
		var previous := progress()
		attack_time = maxf(attack_time - delta, 0.0)
		if WeaponMotion.is_contact(data):
			strike.tick(self, previous, 1.0 if attack_time <= 0.0 else progress())
		queue_redraw()
	update_visual()
	if cooldown > 0.0 or attack_time > 0.0:
		return
	var targets: Array[Enemy] = []
	var reach := data.range_at_tier(tier)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.health > 0.0 and player.global_position.distance_squared_to(enemy.global_position) <= pow(reach + enemy.data.radius, 2):
			targets.append(enemy)
	if targets.is_empty():
		focus_target_id = 0
		focus_hits = 0
		engagement_pending = true
		return
	if engagement_pending:
		engagement_pending = false
		cooldown = attack_interval() * attack_phase
		if cooldown > 0.0:
			return
	var origin := player.global_position + home_position
	var closest := 0
	var distance := INF
	for index in targets.size():
		var candidate := origin.distance_squared_to(targets[index].global_position)
		if candidate < distance:
			distance = candidate
			closest = index
	var first := targets[0]
	targets[0] = targets[closest]
	targets[closest] = first
	_begin_attack(targets)


func attack_interval() -> float:
	return data.interval_at_tier(tier) * player.stats.attack_interval / 0.65 * player.items.attack_interval_factor()


func _begin_attack(targets: Array[Enemy]) -> void:
	var nearest := targets[0]
	aim_distance = player.global_position.distance_to(nearest.global_position)
	aim = player.global_position.direction_to(nearest.global_position)
	if not WeaponMotion.is_contact(data):
		hold_position = WeaponMotion.hand_position(home_position, aim)
	hit_point = to_local(nearest.global_position)
	if focus_target_id != nearest.get_instance_id() or focus_time <= 0.0:
		focus_target_id = nearest.get_instance_id()
		focus_hits = 0
	var guaranteed := data.crit_cycle > 0 and (focus_hits + 1) % data.crit_cycle == 0
	var damage := player.stats.roll_damage(data.damage_at_tier(tier) / 18.0, data.crit_bonus, data.crit_multiplier, guaranteed)
	damage *= 1.0 + minf(float(focus_hits) * data.focus_step, data.focus_cap)
	focus_hits = mini(focus_hits + 1, 1000)
	cooldown = attack_interval()
	focus_time = maxf(cooldown * 1.5, 0.6)
	attack_duration = maxf(minf(data.animation_duration, cooldown * 0.85), 0.035)
	attack_time = attack_duration
	var critical := player.stats.last_roll_critical
	update_visual()
	if WeaponMotion.is_contact(data):
		strike.begin(damage, critical, nearest)
	else:
		# Aim the actual barrel at the target, including its offset from the hand.
		if data.held_style == "aimed" and data.attack_mode in [&"projectile", &"beam"]:
			aim = (nearest.global_position - player.global_position - hold_position).normalized()
			update_visual()
		elif data.held_style == "upright":
			aim = muzzle_position().direction_to(nearest.global_position)
			update_visual()
		_fire(targets, damage, critical)
	var sound_kind: StringName = &"brush"
	if data.attack_mode in [&"area", &"sweep"]:
		sound_kind = &"floss"
	elif data.attack_mode in [&"melee", &"thrust"]:
		sound_kind = &"drill"
	player.play_attack_animation(aim, sound_kind)
	queue_redraw()


func _fire(targets: Array[Enemy], damage: float, critical: bool) -> void:
	var muzzle := muzzle_position()
	match data.attack_mode:
		&"projectile":
			var count := data.projectile_count_at_tier(tier)
			for index in count:
				var angle := 0.0 if index == 0 else (-0.12 if index == 1 else 0.12)
				var projectile: WeaponProjectile = PROJECTILE_SCENE.instantiate()
				player.get_parent().get_node("Projectiles").add_child(projectile)
				projectile.launch(muzzle, aim.rotated(angle), damage if is_zero_approx(angle) else damage * 0.55, data, player.items, critical, tier)
		&"beam":
			WeaponAttackShapes.hit(targets[0], data, tier, damage, critical, player.items, aim)
		&"beam_line", &"cone":
			for enemy in targets:
				if WeaponAttackShapes.contains(data, tier, player.global_position, aim, enemy.global_position, enemy.data.radius):
					WeaponAttackShapes.hit(enemy, data, tier, damage, critical, player.items, aim)


func save_motion(enemy_indices: Dictionary) -> Dictionary:
	var hit_enemies: Array[int] = []
	for id in strike.hit_ids:
		if enemy_indices.has(id):
			hit_enemies.append(enemy_indices[id])
	return {"remaining": attack_time, "duration": attack_duration, "damage": strike.damage,
		"critical": strike.critical, "target": enemy_indices.get(strike.target_id, -1), "hits": hit_enemies,
		"aim": [aim.x, aim.y], "hit_point": [hit_point.x, hit_point.y], "idle_time": idle_time, "aim_distance": aim_distance,
		"hold": [hold_position.x, hold_position.y], "engagement_pending": engagement_pending}


func restore_motion(saved: Dictionary, enemies: Array[Node]) -> void:
	attack_duration = clampf(float(saved.get("duration", data.animation_duration)), 0.035, 0.8)
	attack_time = clampf(float(saved.get("remaining", 0.0)), 0.0, attack_duration)
	strike.damage = maxf(float(saved.get("damage", 0.0)), 0.0)
	strike.critical = bool(saved.get("critical", false))
	engagement_pending = bool(saved.get("engagement_pending", false))
	strike.hit_ids.clear()
	for index in saved.get("hits", []):
		if int(index) >= 0 and int(index) < enemies.size():
			strike.hit_ids[enemies[int(index)].get_instance_id()] = true
	var target_index := int(saved.get("target", -1))
	strike.target_id = enemies[target_index].get_instance_id() if target_index >= 0 and target_index < enemies.size() else 0
	var saved_aim: Array = saved.get("aim", [1.0, 0.0])
	if saved_aim.size() == 2:
		aim = Vector2(float(saved_aim[0]), float(saved_aim[1])).normalized()
	var saved_point: Array = saved.get("hit_point", [0.0, 0.0])
	if saved_point.size() == 2:
		hit_point = Vector2(float(saved_point[0]), float(saved_point[1]))
	var saved_hold: Array = saved.get("hold", [home_position.x, home_position.y])
	if saved_hold.size() == 2:
		hold_position = Vector2(float(saved_hold[0]), float(saved_hold[1]))
	idle_time = maxf(float(saved.get("idle_time", 0.0)), 0.0)
	aim_distance = maxf(float(saved.get("aim_distance", 1000.0)), 0.0)
	update_visual()
	queue_redraw()


func _draw() -> void:
	if attack_time <= 0.0 or sprite == null:
		return
	var fraction := progress()
	var fade := 1.0 - fraction
	var color := Color(data.projectile_color, fade)
	var muzzle := to_local(muzzle_position())
	if WeaponMotion.is_contact(data):
		if fraction < WeaponMotion.ACTIVE_START:
			return
		var blade := WeaponMotion.segment(data, WeaponMotion.pose(data, tier, home_position, aim, fraction, idle_time, aim_distance, visual_density))
		draw_line(blade[0], blade[1], Color(color, fade * 0.35), 3.0)
		if data.attack_animation in ["drill", "polish"]:
			draw_arc(muzzle, 7.0, idle_time * 25.0, idle_time * 25.0 + PI, 12, color, 2.0)
		else:
			var previous := WeaponMotion.segment(data, WeaponMotion.pose(data, tier, home_position, aim, maxf(fraction - 0.06, WeaponMotion.ACTIVE_START), idle_time, aim_distance, visual_density))
			draw_line(previous[1], blade[1], Color(color, fade * 0.65), 4.0)
		return
	match data.attack_mode:
		&"projectile":
			if fraction < 0.25:
				draw_circle(muzzle, (1.0 - fraction / 0.25) * 7.0, color)
		&"beam":
			draw_line(muzzle, hit_point, color, 4.0)
			draw_circle(hit_point, 6.0, Color(1, 1, 1, fade))
		&"beam_line":
			var end := aim * data.range_at_tier(tier)
			draw_line(muzzle, end, Color(color, fade * 0.2), data.attack_width)
			draw_line(muzzle, end, color, 4.0)
		&"cone":
			var half_angle := deg_to_rad(data.arc_degrees * 0.5)
			var reach := maxf(data.range_at_tier(tier) - muzzle.length(), 10.0)
			var points := PackedVector2Array([muzzle])
			for index in 13:
				points.append(muzzle + aim.rotated(-half_angle + float(index) / 12.0 * half_angle * 2.0) * reach)
			draw_colored_polygon(points, Color(color, fade * 0.12))
			for index in 3:
				var direction := aim.rotated(lerpf(-half_angle, half_angle, float(index) / 2.0))
				draw_line(muzzle, muzzle + direction * reach * (0.4 + fraction * 0.6), Color(color, fade * 0.6), 2.0)
