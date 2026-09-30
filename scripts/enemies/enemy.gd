class_name Enemy
extends Node2D

signal defeated(position: Vector2, data: EnemyData)
signal damaged(position: Vector2, amount: float)
signal damage_recorded(amount: float, weapon_id: StringName, proc_id: StringName)
signal weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool)
signal attack_performed(kind: StringName)
signal death_started(position: Vector2)
signal enraged(position: Vector2)
signal boss_phase_started(position: Vector2, phase: int)
signal boss_guarded(position: Vector2)
signal elite_guarded(position: Vector2)
signal reinforcements_requested(count: int)

enum SpecialPhase { COOLDOWN, WARNING, ACTIVE }
enum BossMove { CHARGE, PULSE }

const PULSE_FLASH_DURATION := 0.18
const BOSS_DEATH_DURATION := 0.9
const AURA_PULSE_INTERVAL := 0.4
const AURA_HASTE_DURATION := 0.65

@onready var sprite: Sprite2D = $Sprite2D

var data: EnemyData
var target: Player
var health: float
var max_health: float
var damage_reduction: float
var contact_damage: float
var attack_damage: float
var move_speed: float
var contact_timer: float = 0.0
var animation_time: float = 0.0
var special_phase: SpecialPhase = SpecialPhase.COOLDOWN
var special_timer: float = 0.0
var special_direction: Vector2 = Vector2.ZERO
var boss_move: BossMove = BossMove.CHARGE
var boss_charge_next: bool = true
var boss_dash_end: Vector2 = Vector2.ZERO
var boss_dash_origin: Vector2 = Vector2.ZERO
var pulse_flash_time: float = 0.0
var dying: bool = false
var death_elapsed: float = 0.0
var is_enraged: bool = false
var sprite_base_scale: Vector2 = Vector2.ONE
var bleed_stacks: int = 0
var bleed_dps: float = 0.0
var bleed_time: float = 0.0
var bleed_tick: float = 1.0
var wet_time: float = 0.0
var haste_time: float = 0.0
var haste_bonus: float = 0.0
var aura_timer: float = 0.0
var boss_damage_budget: float = 0.0
var elite_damage_budget: float = 0.0
var boss_phase: int = 0
var boss_phase_timer: float = 0.0
var boss_phase_burst_fired: bool = false
var boss_phase_gap_angle: float = 0.0
var boss_radial_volleys_remaining: int = 0
var boss_radial_volley_timer: float = 0.0
var boss_radial_volley_index: int = 0
var boss_guard_feedback_time: float = 0.0
var spawn_wave: int = 1
var active_special_attack: int = EnemyData.SpecialAttack.NONE
var active_trigger_range: float = 0.0


func configure(enemy_data: EnemyData, player: Player, wave_number: int = 1) -> void:
	data = enemy_data
	target = player
	spawn_wave = wave_number
	var advanced := data.advanced_special_wave > 0 and wave_number >= data.advanced_special_wave
	active_special_attack = data.advanced_special_attack if advanced else data.special_attack
	active_trigger_range = data.advanced_trigger_range if advanced and data.advanced_trigger_range > 0.0 else data.trigger_range
	max_health = data.max_health * WaveController.health_multiplier(data, wave_number)
	health = max_health
	damage_reduction = WaveController.damage_reduction(data, wave_number)
	contact_damage = data.contact_damage * WaveController.enemy_damage_multiplier(data, wave_number)
	attack_damage = data.attack_damage * WaveController.enemy_damage_multiplier(data, wave_number)
	move_speed = data.move_speed * WaveController.enemy_speed_multiplier(data, wave_number)
	special_phase = SpecialPhase.COOLDOWN
	var interval := data.special_interval * (WaveController.ranged_interval_multiplier(wave_number) if active_special_attack == EnemyData.SpecialAttack.SHOOT else 1.0)
	if data.is_elite:
		special_timer = randf_range(0.35, 0.55)
	else:
		special_timer = interval * randf_range(0.35, 0.5) if active_special_attack == EnemyData.SpecialAttack.BOSS else interval * randf_range(0.65, 1.0)
	if data.is_boss:
		boss_damage_budget = max_health * data.boss_guard_burst_fraction
	if data.is_elite:
		elite_damage_budget = max_health * data.elite_guard_fraction
	queue_redraw()


func _ready() -> void:
	add_to_group("enemies")
	sprite.texture = data.sprite
	sprite.modulate = data.sprite_tint
	var side := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * (data.radius * 2.35 / side)
	sprite_base_scale = sprite.scale
	animation_time = randf_range(0.0, TAU)


func _process(delta: float) -> void:
	boss_guard_feedback_time = maxf(boss_guard_feedback_time - delta, 0.0)
	if dying:
		death_elapsed += delta
		var progress := clampf(death_elapsed / BOSS_DEATH_DURATION, 0.0, 1.0)
		sprite.position.y = -18.0 * progress
		sprite.rotation += delta * 2.2
		sprite.scale = sprite_base_scale * (1.0 + 0.28 * sin(progress * PI) - 0.45 * progress)
		sprite.modulate = Color(1.45, 1.27, 0.95, 1.0) if progress < 0.2 else data.sprite_tint.lerp(Color(0.50, 0.25, 0.57, 0.0), (progress - 0.2) / 0.8)
		queue_redraw()
		if death_elapsed >= BOSS_DEATH_DURATION:
			defeated.emit(global_position, data)
			queue_free()
		return
	animation_time += delta * (2.5 if data.is_boss else 5.0)
	sprite.position.y = sin(animation_time) * (2.2 if data.is_boss else 1.2)
	sprite.rotation = sin(animation_time * 0.7) * (0.025 if data.is_boss else 0.045)
	if active_special_attack == EnemyData.SpecialAttack.SHOOT and target != null:
		sprite.flip_h = target.global_position.x < global_position.x
	if pulse_flash_time > 0.0:
		pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)
		queue_redraw()


func _physics_process(delta: float) -> void:
	if haste_time > 0.0:
		haste_time = maxf(haste_time - delta, 0.0)
		if haste_time <= 0.0:
			haste_bonus = 0.0
			queue_redraw()
	if wet_time > 0.0:
		wet_time = maxf(wet_time - delta, 0.0)
		if wet_time <= 0.0:
			queue_redraw()
	if data.is_boss and data.boss_guard_recharge_seconds > 0.0:
		boss_damage_budget = minf(boss_damage_budget + max_health * delta / data.boss_guard_recharge_seconds, max_health * data.boss_guard_burst_fraction)
		if boss_phase_timer > 0.0:
			boss_phase_timer = maxf(boss_phase_timer - delta, 0.0)
			if not boss_phase_burst_fired and boss_phase_timer <= data.boss_phase_duration * 0.5:
				boss_phase_burst_fired = true
				_fire_phase_burst()
		if boss_radial_volleys_remaining > 0:
			boss_radial_volley_timer -= delta
			while boss_radial_volleys_remaining > 0 and boss_radial_volley_timer <= 0.0:
				_fire_next_boss_radial_volley()
		if boss_phase_timer > 0.0 or boss_radial_volleys_remaining > 0:
			queue_redraw()
	if data.is_elite and data.elite_guard_recharge_seconds > 0.0 and health > 0.0:
		elite_damage_budget = minf(elite_damage_budget + max_health * data.elite_guard_fraction * delta / data.elite_guard_recharge_seconds, max_health * data.elite_guard_fraction)
		queue_redraw()
	if bleed_time > 0.0 and health > 0.0:
		bleed_time = maxf(bleed_time - delta, 0.0)
		bleed_tick -= delta
		if bleed_tick <= 0.0:
			bleed_tick += 1.0
			take_damage(bleed_dps * float(bleed_stacks), null, false, &"bleed")
		if bleed_time <= 0.0:
			bleed_stacks = 0
			bleed_dps = 0.0
			queue_redraw()
	if health <= 0.0:
		return
	if target == null or target.stats.health <= 0.0:
		return
	if data.aura_radius > 0.0:
		aura_timer -= delta
		if aura_timer <= 0.0:
			aura_timer = AURA_PULSE_INTERVAL
			_pulse_aura()
	var direction := global_position.direction_to(target.global_position)
	var before_move := global_position
	var charging := special_phase == SpecialPhase.ACTIVE and (active_special_attack == EnemyData.SpecialAttack.DASH or active_special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE)
	contact_timer = maxf(contact_timer - delta, 0.0)
	if active_special_attack == EnemyData.SpecialAttack.NONE:
		global_position += direction * _movement_speed() * delta
	else:
		_process_special(delta, direction)
	var closest := Geometry2D.get_closest_point_to_segment(target.global_position, before_move, global_position)
	if closest.distance_to(target.global_position) < data.radius + 20.0 and contact_timer <= 0.0:
		var damage := attack_damage if charging else contact_damage
		contact_timer = 0.8
		target.take_hit(damage)


func _process_special(delta: float, direction: Vector2) -> void:
	if data.is_boss and boss_phase_timer > 0.0:
		return
	var chase_speed := _movement_speed()
	match special_phase:
		SpecialPhase.COOLDOWN:
			special_timer = maxf(special_timer - delta, 0.0)
			var distance := global_position.distance_to(target.global_position)
			if special_timer <= 0.0 and distance <= active_trigger_range:
				special_phase = SpecialPhase.WARNING
				special_timer = data.warning_time
				special_direction = direction
				if active_special_attack == EnemyData.SpecialAttack.BOSS:
					boss_move = BossMove.CHARGE if distance > data.attack_radius + 45.0 or boss_charge_next else BossMove.PULSE
					boss_charge_next = boss_move != BossMove.CHARGE
					if boss_move == BossMove.CHARGE:
						boss_dash_end = _boss_dash_target(direction)
					attack_performed.emit(&"boss_warning")
				queue_redraw()
			else:
				if active_special_attack == EnemyData.SpecialAttack.SHOOT:
					if distance > data.preferred_range + 30.0:
						global_position += direction * chase_speed * delta
					elif distance < data.preferred_range - 50.0:
						global_position -= direction * chase_speed * 0.7 * delta
					else:
						global_position += direction.orthogonal() * chase_speed * 0.4 * delta
				else:
					global_position += direction * chase_speed * (1.25 if is_enraged else 1.0) * delta
		SpecialPhase.WARNING:
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0:
				_activate_special()
		SpecialPhase.ACTIVE:
			if active_special_attack == EnemyData.SpecialAttack.BOSS:
				global_position = global_position.move_toward(boss_dash_end, data.attack_speed * delta)
			else:
				global_position += special_direction * data.attack_speed * delta
				var margin := DentiArena.WALL_WIDTH + data.radius + 6.0
				global_position = global_position.clamp(Vector2.ONE * margin, target.arena.arena_size - Vector2.ONE * margin)
			special_timer -= delta
			queue_redraw()
			if special_timer <= 0.0 or active_special_attack == EnemyData.SpecialAttack.BOSS and global_position.distance_to(boss_dash_end) < 1.0:
				if active_special_attack == EnemyData.SpecialAttack.BOSS:
					_fire_boss_fan()
				elif active_special_attack == EnemyData.SpecialAttack.DASH and data.dash_impact_radius > 0.0:
					_dash_impact()
				_reset_special()


func _movement_speed() -> float:
	return move_speed * (1.0 + haste_bonus if haste_time > 0.0 else 1.0)


func apply_haste(bonus: float, duration: float) -> void:
	if health <= 0.0 or bonus <= 0.0:
		return
	var was_hasted := haste_time > 0.0
	haste_time = maxf(haste_time, duration)
	haste_bonus = maxf(haste_bonus, bonus)
	if not was_hasted:
		queue_redraw()


func _pulse_aura() -> void:
	var radius_squared := data.aura_radius * data.aura_radius
	for node in get_tree().get_nodes_in_group("enemies"):
		var ally := node as Enemy
		if ally == null or ally == self or ally.data.is_boss or ally.data.is_elite:
			continue
		if global_position.distance_squared_to(ally.global_position) <= radius_squared:
			ally.apply_haste(data.aura_move_bonus, AURA_HASTE_DURATION)


func _boss_dash_target(direction: Vector2) -> Vector2:
	var margin := DentiArena.WALL_WIDTH + data.radius + 6.0
	return (global_position + direction * data.attack_speed * data.attack_duration).clamp(Vector2.ONE * margin, target.arena.arena_size - Vector2.ONE * margin)


func _activate_special() -> void:
	if active_special_attack == EnemyData.SpecialAttack.BOSS:
		if boss_move == BossMove.CHARGE:
			special_phase = SpecialPhase.ACTIVE
			special_timer = data.attack_duration
			boss_dash_origin = global_position
			contact_timer = 0.0
			attack_performed.emit(&"boss_charge")
		else:
			if global_position.distance_to(target.global_position) <= data.attack_radius:
				target.take_hit(attack_damage)
			pulse_flash_time = PULSE_FLASH_DURATION
			attack_performed.emit(&"boss_pulse")
			_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.DASH:
		special_phase = SpecialPhase.ACTIVE
		special_timer = data.attack_duration
	elif active_special_attack == EnemyData.SpecialAttack.SHOOT:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_aimed_fan(root, global_position, special_direction, WaveController.acid_volley_count(spawn_wave), data.attack_speed, attack_damage, target, EnemyProjectilePatterns.ACID_COLOR, 2.2)
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.RADIAL:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_radial(root, global_position, data.radial_count, special_direction.angle() + PI, data.attack_speed, attack_damage, target, Color(1.0, 0.52, 0.22))
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.LANE:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_lane(root, global_position, special_direction, data.lane_projectile_count, data.lane_projectile_spacing, data.attack_speed, attack_damage, target)
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.SPACE_ORB:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_space_orb(root, global_position, special_direction, data.attack_speed, attack_damage, data.space_orb_radius, target)
		attack_performed.emit(&"acid")
		_reset_special()
	else:
		if global_position.distance_to(target.global_position) <= data.attack_radius:
			target.take_hit(attack_damage)
		pulse_flash_time = PULSE_FLASH_DURATION
		_reset_special()
	queue_redraw()


func _reset_special() -> void:
	special_phase = SpecialPhase.COOLDOWN
	special_timer = data.special_interval * (0.72 if is_enraged else (WaveController.ranged_interval_multiplier(spawn_wave) if active_special_attack == EnemyData.SpecialAttack.SHOOT else 1.0))
	queue_redraw()


func _dash_impact() -> void:
	if global_position.distance_to(target.global_position) <= data.dash_impact_radius:
		target.take_hit(attack_damage)
	pulse_flash_time = PULSE_FLASH_DURATION
	queue_redraw()


func _fire_phase_burst() -> void:
	boss_radial_volleys_remaining = maxi(data.boss_radial_volley_count, 1)
	boss_radial_volley_timer = 0.0
	boss_radial_volley_index = 0
	_fire_next_boss_radial_volley()


func _fire_next_boss_radial_volley() -> void:
	var root := _projectile_root()
	var volley_angle := boss_phase_gap_angle + deg_to_rad(data.boss_radial_angle_step_degrees * float(boss_radial_volley_index))
	if root != null:
		EnemyProjectilePatterns.fire_radial(root, global_position, data.boss_radial_count + boss_phase * 2, volley_angle, data.boss_projectile_speed, attack_damage * 0.55, target)
	boss_radial_volley_index += 1
	boss_radial_volleys_remaining -= 1
	if boss_radial_volleys_remaining > 0:
		boss_radial_volley_timer += data.boss_radial_volley_interval
	elif boss_phase >= 2:
		_fire_boss_signature(Vector2.RIGHT.rotated(boss_phase_gap_angle))


func _fire_boss_fan() -> void:
	_fire_boss_signature(special_direction)


func _fire_boss_signature(charge_direction: Vector2) -> void:
	var root := _projectile_root()
	if root == null:
		return
	match data.boss_signature:
		EnemyData.BossSignature.AIMED_FAN:
			EnemyProjectilePatterns.fire_aimed_fan(root, global_position, target.global_position - global_position, data.boss_fan_count, data.boss_projectile_speed, attack_damage * 0.45, target)
		EnemyData.BossSignature.TRAIL_FAN:
			EnemyProjectilePatterns.fire_aimed_fan(root, global_position, -charge_direction, data.boss_fan_count, data.boss_projectile_speed, attack_damage * 0.45, target)
		EnemyData.BossSignature.LANE:
			EnemyProjectilePatterns.fire_lane(root, global_position, charge_direction, data.boss_signature_projectile_count, data.boss_signature_projectile_spacing, data.boss_projectile_speed, attack_damage * 0.45, target, EnemyProjectilePatterns.BOSS_COLOR)
		EnemyData.BossSignature.SPACE_ORB:
			EnemyProjectilePatterns.fire_space_orb(root, global_position, charge_direction, data.boss_projectile_speed, attack_damage * 0.5, data.boss_signature_orb_radius, target)


func _projectile_root() -> Node2D:
	var scene := get_tree().current_scene
	return scene.get_node_or_null("EnemyProjectiles") as Node2D if scene != null else get_parent() as Node2D


func apply_bleed(dps: float, duration: float, stack_cap: int = 3) -> void:
	bleed_stacks = mini(bleed_stacks + 1, stack_cap)
	bleed_dps = maxf(bleed_dps, dps)
	bleed_time = maxf(bleed_time, duration)
	queue_redraw()


func apply_wet(duration: float) -> void:
	wet_time = maxf(wet_time, duration)
	queue_redraw()


func take_damage(amount: float, weapon: WeaponData = null, critical: bool = false, proc_id: StringName = &"") -> void:
	if health <= 0.0:
		return
	var applied := maxf(amount * (1.0 - damage_reduction), 1.0)
	if data.is_boss and data.boss_guard_recharge_seconds > 0.0:
		if boss_phase_timer > 0.0:
			_guard_boss_hit()
			return
		applied = minf(applied, boss_damage_budget)
		if boss_phase < 2:
			applied = minf(applied, maxf(health - _boss_phase_floor(), 0.0))
		if applied <= 0.0:
			_guard_boss_hit()
			return
		boss_damage_budget = maxf(boss_damage_budget - applied, 0.0)
	elif data.is_elite and data.elite_guard_recharge_seconds > 0.0:
		applied = minf(applied, elite_damage_budget)
		if applied <= 0.0:
			_guard_elite_hit()
			return
		elite_damage_budget = maxf(elite_damage_budget - applied, 0.0)
	var counted := minf(applied, health)
	health -= applied
	damaged.emit(global_position + Vector2(0.0, -data.radius), applied)
	damage_recorded.emit(counted, weapon.id if weapon != null else &"", proc_id)
	if weapon != null:
		weapon_hit.emit(self, applied, weapon, critical)
	if data.is_boss and not is_enraged and health > 0.0 and health <= max_health * 0.5:
		is_enraged = true
		enraged.emit(global_position)
	if data.is_boss and boss_phase < 2 and health <= _boss_phase_floor() + 0.01:
		_start_boss_phase()
	if health <= 0.0:
		health = 0.0
		remove_from_group("enemies")
		if data.is_boss:
			dying = true
			death_elapsed = 0.0
			death_started.emit(global_position)
			queue_redraw()
		else:
			defeated.emit(global_position, data)
			queue_free()
	else:
		queue_redraw()
		modulate = Color(1.6, 1.6, 1.6)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.12)


func _boss_phase_floor() -> float:
	return max_health * (2.0 - float(boss_phase)) / 3.0


func _start_boss_phase() -> void:
	boss_phase += 1
	boss_phase_timer = data.boss_phase_duration
	boss_phase_burst_fired = false
	boss_radial_volleys_remaining = 0
	boss_radial_volley_timer = 0.0
	boss_radial_volley_index = 0
	boss_phase_gap_angle = global_position.angle_to_point(target.global_position)
	special_direction = Vector2.RIGHT.rotated(boss_phase_gap_angle)
	special_phase = SpecialPhase.COOLDOWN
	special_timer = data.special_interval * (0.72 if is_enraged else 1.0)
	boss_phase_started.emit(global_position, boss_phase)
	reinforcements_requested.emit(data.boss_phase_adds)
	queue_redraw()


func _guard_boss_hit() -> void:
	if boss_guard_feedback_time <= 0.0:
		boss_guarded.emit(global_position)
		boss_guard_feedback_time = 0.8
	queue_redraw()


func _guard_elite_hit() -> void:
	if boss_guard_feedback_time <= 0.0:
		elite_guarded.emit(global_position)
		boss_guard_feedback_time = 0.8
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	if dying:
		var progress := clampf(death_elapsed / BOSS_DEATH_DURATION, 0.0, 1.0)
		var fade := 1.0 - progress
		draw_circle(Vector2.ZERO, data.radius * (1.0 + progress * 3.0), Color(0.56, 0.15, 0.42, 0.18 * fade))
		draw_arc(Vector2.ZERO, data.radius * (0.8 + progress * 3.4), 0.0, TAU, 48, Color(1.0, 0.78, 0.38, 0.95 * fade), 11.0 * fade + 2.0)
		for index in 12:
			var ray := Vector2.RIGHT.rotated(TAU * float(index) / 12.0 + 0.2)
			var shard_at := ray * (data.radius * 0.7 + progress * 180.0)
			draw_line(shard_at, shard_at + ray * (16.0 + 26.0 * fade), Color(1.0, 0.76, 0.35, fade), 6.0 * fade + 1.0)
		return
	if data.is_boss and data.boss_guard_recharge_seconds > 0.0:
		if boss_phase_timer > 0.0 or boss_radial_volleys_remaining > 0:
			draw_arc(Vector2.ZERO, data.radius + 19.0, 0.0, TAU, 48, Color(0.95, 0.32, 0.63, 0.9), 7.0)
			if not boss_phase_burst_fired or boss_radial_volleys_remaining > 0:
				var first_preview_index := boss_radial_volley_index if boss_phase_burst_fired else 0
				var preview_count := boss_radial_volleys_remaining if boss_phase_burst_fired else data.boss_radial_volley_count
				var current_gap_angle := boss_phase_gap_angle + deg_to_rad(data.boss_radial_angle_step_degrees * float(first_preview_index))
				for ray in EnemyProjectilePatterns.radial_directions(data.boss_radial_count + boss_phase * 2, current_gap_angle):
					draw_line(ray * data.radius, ray * 290.0, Color(0.95, 0.25, 0.42, 0.3), 3.0)
				for volley_offset in preview_count:
					var preview_angle := boss_phase_gap_angle + deg_to_rad(data.boss_radial_angle_step_degrees * float(first_preview_index + volley_offset))
					var gap_marker := Vector2.RIGHT.rotated(preview_angle) * 290.0
					draw_arc(gap_marker, 10.0, 0.0, TAU, 20, Color(1.0, 0.78, 0.3, 0.88), 3.0)
				if boss_phase >= 2:
					var phase_aim := Vector2.RIGHT.rotated(boss_phase_gap_angle)
					match data.boss_signature:
						EnemyData.BossSignature.AIMED_FAN:
							for ray in EnemyProjectilePatterns.fan_directions(phase_aim, data.boss_fan_count):
								draw_line(ray * data.radius, ray * 320.0, Color(1.0, 0.78, 0.3, 0.42), 4.0)
						EnemyData.BossSignature.TRAIL_FAN:
							for ray in EnemyProjectilePatterns.fan_directions(-phase_aim, data.boss_fan_count):
								draw_line(ray * data.radius, ray * 320.0, Color(1.0, 0.78, 0.3, 0.42), 4.0)
						EnemyData.BossSignature.LANE:
							var lane_side := phase_aim.orthogonal() * (data.boss_signature_projectile_spacing * float(data.boss_signature_projectile_count - 1) * 0.5 + 21.0)
							var lane_end := phase_aim * 520.0
							draw_colored_polygon(PackedVector2Array([-lane_side, lane_end - lane_side, lane_end + lane_side, lane_side]), Color(0.95, 0.32, 0.63, 0.13))
							draw_line(-lane_side, lane_end - lane_side, Color(1.0, 0.78, 0.3, 0.6), 3.0)
							draw_line(lane_side, lane_end + lane_side, Color(1.0, 0.78, 0.3, 0.6), 3.0)
						EnemyData.BossSignature.SPACE_ORB:
							var orb_end := phase_aim * 520.0
							draw_line(Vector2.ZERO, orb_end, Color(0.95, 0.32, 0.63, 0.24), data.boss_signature_orb_radius * 1.4)
							draw_arc(orb_end, data.boss_signature_orb_radius, 0.0, TAU, 40, Color(1.0, 0.78, 0.3, 0.75), 4.0)
		elif boss_damage_budget <= max_health * 0.01:
			draw_arc(Vector2.ZERO, data.radius + 19.0, 0.0, TAU, 48, Color(0.43, 0.84, 0.94, 0.8), 5.0)
	if data.is_elite and data.elite_guard_fraction > 0.0:
		var guard_ratio := clampf(elite_damage_budget / (max_health * data.elite_guard_fraction), 0.0, 1.0)
		draw_arc(Vector2.ZERO, data.radius + 18.0, 0.0, TAU, 40, Color(0.43, 0.84, 0.94, 0.22), 4.0)
		if guard_ratio > 0.0:
			draw_arc(Vector2.ZERO, data.radius + 18.0, -PI / 2.0, -PI / 2.0 + TAU * guard_ratio, 40, Color(0.43, 0.84, 0.94, 0.85), 4.0)
	if special_phase == SpecialPhase.WARNING:
		var warning_color := Color(0.73, 0.20, 0.19, 0.85)
		var warning_progress := 1.0 - clampf(special_timer / maxf(data.warning_time, 0.01), 0.0, 1.0)
		if active_special_attack == EnemyData.SpecialAttack.DASH or active_special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE:
			var dash_path := boss_dash_end - global_position
			if active_special_attack == EnemyData.SpecialAttack.DASH:
				var margin := DentiArena.WALL_WIDTH + data.radius + 6.0
				dash_path = (global_position + special_direction * data.attack_speed * data.attack_duration).clamp(Vector2.ONE * margin, target.arena.arena_size - Vector2.ONE * margin) - global_position
			if active_special_attack == EnemyData.SpecialAttack.BOSS:
				var side := special_direction.orthogonal() * (data.radius + 19.0)
				var start := special_direction * data.radius * 0.5
				draw_colored_polygon(PackedVector2Array([start - side, dash_path - side, dash_path + side, start + side]), Color(0.95, 0.20, 0.29, 0.18 + warning_progress * 0.22))
				draw_line(start - side, dash_path - side, warning_color, 3.0 + warning_progress * 3.0)
				draw_line(start + side, dash_path + side, warning_color, 3.0 + warning_progress * 3.0)
			draw_line(Vector2.ZERO, dash_path, warning_color, 5.0)
			draw_circle(dash_path, data.dash_impact_radius if active_special_attack == EnemyData.SpecialAttack.DASH and data.dash_impact_radius > 0.0 else (data.radius * 0.55 if data.is_boss else 6.0), Color(0.95, 0.20, 0.29, 0.20 + warning_progress * 0.25))
			if active_special_attack == EnemyData.SpecialAttack.DASH and data.dash_impact_radius > 0.0:
				draw_arc(dash_path, data.dash_impact_radius, 0.0, TAU, 32, warning_color, 3.0)
			draw_arc(Vector2.ZERO, data.radius + 7.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, Color(1.0, 0.72, 0.27), 4.0)
		elif active_special_attack == EnemyData.SpecialAttack.SHOOT:
			var shot_color := Color(0.50, 0.88, 0.14, 0.9)
			for ray in EnemyProjectilePatterns.fan_directions(special_direction, WaveController.acid_volley_count(spawn_wave)):
				draw_line(Vector2.ZERO, ray * 150.0, shot_color, 3.0)
			draw_arc(Vector2.ZERO, data.radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, shot_color, 4.0)
		elif active_special_attack == EnemyData.SpecialAttack.RADIAL:
			var shot_color := Color(1.0, 0.48, 0.19, 0.9)
			for ray in EnemyProjectilePatterns.radial_directions(data.radial_count, special_direction.angle() + PI):
				draw_line(ray * data.radius, ray * 235.0, Color(shot_color, 0.3 + warning_progress * 0.35), 3.0)
			draw_arc(Vector2.ZERO, data.radius + 9.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, shot_color, 5.0)
		elif active_special_attack == EnemyData.SpecialAttack.LANE:
			var lane_color := Color(0.50, 0.88, 0.14, 0.9)
			var lane_direction := special_direction.normalized()
			var lane_side := lane_direction.orthogonal() * (data.lane_projectile_spacing * float(data.lane_projectile_count - 1) * 0.5 + 21.0)
			var lane_end := lane_direction * 550.0
			draw_colored_polygon(PackedVector2Array([-lane_side, lane_end - lane_side, lane_end + lane_side, lane_side]), Color(lane_color, 0.10 + warning_progress * 0.12))
			draw_line(-lane_side, lane_end - lane_side, lane_color, 3.0)
			draw_line(lane_side, lane_end + lane_side, lane_color, 3.0)
			draw_arc(Vector2.ZERO, data.radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, lane_color, 4.0)
		elif active_special_attack == EnemyData.SpecialAttack.SPACE_ORB:
			var orb_color := Color(1.0, 0.43, 0.25, 0.88)
			var orb_direction := special_direction.normalized()
			var orb_end := orb_direction * 550.0
			draw_line(Vector2.ZERO, orb_end, Color(orb_color, 0.42), data.space_orb_radius * 1.4)
			draw_arc(orb_end, data.space_orb_radius, 0.0, TAU, 40, orb_color, 4.0)
			draw_arc(Vector2.ZERO, data.radius + 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 32, orb_color, 4.0)
		else:
			draw_circle(Vector2.ZERO, data.attack_radius, Color(0.95, 0.36, 0.28, 0.13))
			draw_arc(Vector2.ZERO, data.attack_radius, 0.0, TAU, 64, warning_color, 4.0)
			draw_arc(Vector2.ZERO, data.attack_radius - 8.0, -PI / 2.0, -PI / 2.0 + TAU * warning_progress, 64, Color(1.0, 0.72, 0.27), 4.0)
	elif special_phase == SpecialPhase.ACTIVE and (active_special_attack == EnemyData.SpecialAttack.DASH or active_special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE):
		draw_line(boss_dash_origin - global_position if data.is_boss else -special_direction * data.radius, Vector2.ZERO, Color(1.0, 0.72, 0.27, 0.7), 15.0 if data.is_boss else 7.0)
	if pulse_flash_time > 0.0:
		var flash_radius := data.dash_impact_radius if active_special_attack == EnemyData.SpecialAttack.DASH and data.dash_impact_radius > 0.0 else data.attack_radius
		draw_arc(Vector2.ZERO, flash_radius, 0.0, TAU, 64, Color(1.0, 0.72, 0.27, pulse_flash_time / PULSE_FLASH_DURATION), 8.0)
	if bleed_stacks > 0:
		draw_arc(Vector2.ZERO, data.radius + 4.0, 0.0, TAU, 24, Color(0.78, 0.25, 0.48, 0.85), 2.5 + bleed_stacks)
	if wet_time > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 8.0, 0.0, TAU, 24, Color(0.36, 0.86, 1.0, 0.88), 3.0)
	if haste_time > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 8.0, 0.0, TAU, 24, Color(1.0, 0.46, 0.73, 0.9), 3.0)
	if data.is_elite:
		draw_arc(Vector2.ZERO, data.radius + 12.0, 0.0, TAU, 40, Color(1.0, 0.73, 0.24, 0.95), 4.0)
	if data.aura_radius > 0.0:
		draw_arc(Vector2.ZERO, data.aura_radius, 0.0, TAU, 48, Color(1.0, 0.46, 0.73, 0.45), 2.0)
	if is_enraged:
		draw_arc(Vector2.ZERO, data.radius + 12.0, 0.0, TAU, 40, Color(1.0, 0.26, 0.23, 0.85), 4.0)
	draw_circle(Vector2(0.0, data.radius * 0.7), data.radius * 0.7, Color(0.17, 0.13, 0.17, 0.17))
	if data.is_boss:
		draw_rect(Rect2(Vector2(-data.radius, data.radius + 11.0), Vector2(data.radius * 2.0, 8.0)), Color(0.18, 0.13, 0.2))
		draw_rect(Rect2(Vector2(-data.radius + 1.0, data.radius + 12.0), Vector2((data.radius * 2.0 - 2.0) * health / max_health, 6.0)), Color(0.92, 0.49, 0.25))
