class_name Enemy
extends Node2D

signal defeated(position: Vector2, data: EnemyData)
signal damaged(position: Vector2, amount: float)
signal affix_damaged(position: Vector2, amount: float, kind: StringName)
signal damage_recorded(amount: float, weapon_id: StringName, proc_id: StringName)
signal weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool)
signal died(enemy: Enemy, amount: float)
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
const MAX_BLEED_STACKS := 9
const WET_STATUS = preload("res://data/statuses/wet.tres")

@onready var sprite: Sprite2D = $Sprite2D

var data: EnemyData
var difficulty: DifficultyData
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
var charge_aim_distance: float = 0.0
var boss_move: BossMove = BossMove.CHARGE
var boss_charge_next: bool = true
var boss_dash_end: Vector2 = Vector2.ZERO
var boss_dash_origin: Vector2 = Vector2.ZERO
var pulse_flash_time: float = 0.0
var dying: bool = false
var death_resolved: bool = false
var death_elapsed: float = 0.0
var is_enraged: bool = false
var overtime_active: bool = false
var overtime_seconds: int = 0
var overtime_tick: float = 0.0
var sprite_base_scale: Vector2 = Vector2.ONE
var affix_effects := EnemyAffixEffects.new()
var bleed_stacks: int = 0
var bleed_dps: float = 0.0
var bleed_time: float = 0.0
var bleed_tick: float = 1.0
var wet_time: float = 0.0
var chill_time: float = 0.0
var treasure_carrier: bool = false
var exposure_time: float = 0.0
var enamel_exposure: float = 0.0
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
var inflammation_aura: BossInflammationAura
var pillow_encounter: PillowEncounter
var cloak_encounter: CloakEncounter
var caramel_encounter: CaramelEncounter
var acid_king_encounter: AcidKingEncounter
var crown_court_encounter: CrownCourtEncounter
var loot_goblin: LootGoblin
var inflicted_statuses: Array[Dictionary] = []
var spatial_index: EnemySpatialIndex
var hit_flash_time: float = 0.0
var spatial_order: int = 0
var motion_slot: int = -1
var simulation_enabled: bool = true
var warning_ray_direction := Vector2.INF
var warning_ray_count := -1
var warning_rays: Array[Vector2] = []
var warning_ray_mode := -1


func configure(enemy_data: EnemyData, player: Player, wave_number: int = 1, difficulty_id: StringName = &"normal") -> void:
	data = enemy_data
	difficulty = DifficultyCatalog.by_id(difficulty_id)
	target = player
	spawn_wave = wave_number
	inflicted_statuses = EnemyStatusRules.attacks_for(data, wave_number, difficulty)
	var advanced := data.advanced_special_wave > 0 and wave_number >= data.advanced_special_wave
	active_special_attack = data.advanced_special_attack if advanced else data.special_attack
	active_trigger_range = data.advanced_trigger_range if advanced and data.advanced_trigger_range > 0.0 else data.trigger_range
	max_health = data.max_health * WaveController.health_multiplier(data, wave_number) * difficulty.health_factor(wave_number)
	health = max_health
	damage_reduction = WaveController.damage_reduction(data, wave_number) + difficulty.defense_bonus(wave_number)
	contact_damage = data.contact_damage * WaveController.enemy_damage_multiplier(data, wave_number) * difficulty.damage_factor(wave_number)
	attack_damage = data.attack_damage * WaveController.enemy_damage_multiplier(data, wave_number) * difficulty.damage_factor(wave_number)
	move_speed = data.move_speed * WaveController.enemy_speed_multiplier(data, wave_number) * difficulty.speed_factor(wave_number)
	if data.is_boss:
		move_speed *= difficulty.boss_movement_multiplier
	special_phase = SpecialPhase.COOLDOWN
	var interval := data.special_interval * (WaveController.ranged_interval_multiplier(wave_number) * difficulty.ranged_interval_multiplier if active_special_attack == EnemyData.SpecialAttack.SHOOT else 1.0)
	if data.is_boss: interval *= difficulty.boss_recovery_multiplier
	if data.is_elite:
		special_timer = randf_range(0.35, 0.55)
	else:
		special_timer = interval * randf_range(0.35, 0.5) if active_special_attack == EnemyData.SpecialAttack.BOSS else interval * randf_range(0.65, 1.0)
	if data.is_boss:
		boss_damage_budget = max_health * data.boss_guard_burst_fraction
	if data.is_elite:
		elite_damage_budget = max_health * data.elite_guard_fraction
	queue_redraw()


func make_treasure_carrier() -> void:
	treasure_carrier = true
	max_health *= ChestRewards.TREASURE_HEALTH_FACTOR
	health = max_health
	move_speed *= ChestRewards.TREASURE_SPEED_FACTOR


func _ready() -> void:
	add_to_group("enemies")
	spatial_index = get_parent() as EnemySpatialIndex
	if spatial_index != null:
		spatial_index.register(self)
		set_notify_local_transform(true)
		set_physics_process(false)
	sprite.texture = data.sprite
	sprite.modulate = ChestRewards.TREASURE_COLOR if treasure_carrier else data.sprite_tint
	var side := maxf(float(data.sprite.get_width()), float(data.sprite.get_height()))
	sprite.scale = Vector2.ONE * (data.radius * 2.35 / side)
	sprite_base_scale = sprite.scale
	animation_time = randf_range(0.0, TAU)
	if data.loot_goblin_profile != null:
		loot_goblin = LootGoblin.new()
		loot_goblin.enemy = self
		add_child(loot_goblin)
	if target != null:
		_update_sprite_facing(global_position.direction_to(target.global_position))
	if data.is_boss:
		inflammation_aura = BossInflammationAura.new()
		inflammation_aura.configure(data)
		add_child(inflammation_aura)
		if data.crown_court_profile != null:
			crown_court_encounter = CrownCourtEncounter.new()
			crown_court_encounter.enemy = self
			crown_court_encounter.profile = data.crown_court_profile.for_difficulty(difficulty)
			add_child(crown_court_encounter)
		elif data.acid_king_profile != null:
			acid_king_encounter = AcidKingEncounter.new()
			acid_king_encounter.enemy = self
			acid_king_encounter.profile = data.acid_king_profile.for_difficulty(difficulty)
			add_child(acid_king_encounter)
		elif data.caramel_profile != null:
			caramel_encounter = CaramelEncounter.new()
			caramel_encounter.enemy = self
			caramel_encounter.profile = data.caramel_profile.for_difficulty(difficulty)
			add_child(caramel_encounter)
		elif data.cloak_profile != null:
			cloak_encounter = CloakEncounter.new()
			cloak_encounter.enemy = self
			cloak_encounter.profile = data.cloak_profile.for_difficulty(difficulty)
			add_child(cloak_encounter)
		elif data.pillow_profile != null:
			pillow_encounter = PillowEncounter.new()
			pillow_encounter.enemy = self
			pillow_encounter.profile = data.pillow_profile
			add_child(pillow_encounter)


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and is_instance_valid(spatial_index):
		if not spatial_index.motion.applying:
			spatial_index.update(self)


func _exit_tree() -> void:
	if is_instance_valid(spatial_index):
		spatial_index.unregister(self)


func set_simulation_enabled(enabled: bool) -> void:
	simulation_enabled = enabled
	set_physics_process(enabled and spatial_index == null)


func _process(delta: float) -> void:
	if hit_flash_time > 0.0:
		hit_flash_time = maxf(hit_flash_time - delta, 0.0)
		modulate = Color.WHITE.lerp(Color(1.6, 1.6, 1.6), hit_flash_time / 0.12)
	boss_guard_feedback_time = maxf(boss_guard_feedback_time - delta, 0.0)
	if dying:
		death_elapsed += delta
		var progress := clampf(death_elapsed / BOSS_DEATH_DURATION, 0.0, 1.0)
		sprite.position.y = -18.0 * progress
		sprite.rotation += delta * 2.2
		sprite.scale = sprite_base_scale * (1.0 + 0.28 * sin(progress * PI) - 0.45 * progress)
		sprite.modulate = Color(1.45, 1.27, 0.95, 1.0) if progress < 0.2 else data.sprite_tint.lerp(Color(0.50, 0.25, 0.57, 0.0), (progress - 0.2) / 0.8)
		sync_inflammation_aura(delta, progress)
		queue_redraw()
		if death_elapsed >= BOSS_DEATH_DURATION:
			defeated.emit(global_position, data)
			queue_free()
		return
	animation_time += delta * (2.5 if data.is_boss else 5.0)
	if treasure_carrier:
		queue_redraw()
	sprite.position.y = sin(animation_time) * (2.2 if data.is_boss else 1.2)
	sprite.rotation = sin(animation_time * 0.7) * (0.025 if data.is_boss else 0.045)
	sync_inflammation_aura(delta)
	if pulse_flash_time > 0.0:
		pulse_flash_time = maxf(pulse_flash_time - delta, 0.0)
		queue_redraw()


func _physics_process(delta: float) -> void:
	_tick_overtime(delta)
	chill_time = maxf(chill_time - delta, 0.0)
	if exposure_time > 0.0:
		exposure_time = maxf(exposure_time - delta, 0.0)
		if exposure_time <= 0.0:
			enamel_exposure = 0.0
			queue_redraw()
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
		var was_low_guard := boss_damage_budget <= max_health * 0.01
		boss_damage_budget = minf(boss_damage_budget + max_health * delta / data.boss_guard_recharge_seconds, max_health * data.boss_guard_burst_fraction)
		if was_low_guard != (boss_damage_budget <= max_health * 0.01):
			queue_redraw()
		if boss_phase_timer > 0.0:
			boss_phase_timer = maxf(boss_phase_timer - delta, 0.0)
			if pillow_encounter == null and cloak_encounter == null and caramel_encounter == null and acid_king_encounter == null and crown_court_encounter == null and not boss_phase_burst_fired and boss_phase_timer <= data.boss_phase_duration * 0.5:
				boss_phase_burst_fired = true
				_fire_phase_burst()
		if boss_radial_volleys_remaining > 0:
			boss_radial_volley_timer -= delta * overtime_attack_factor()
			while boss_radial_volleys_remaining > 0 and boss_radial_volley_timer <= 0.0:
				_fire_next_boss_radial_volley()
		if boss_phase_timer > 0.0 or boss_radial_volleys_remaining > 0:
			queue_redraw()
	if data.is_elite and data.elite_guard_recharge_seconds > 0.0 and health > 0.0:
		var before_guard := elite_damage_budget
		elite_damage_budget = minf(elite_damage_budget + max_health * data.elite_guard_fraction * delta / data.elite_guard_recharge_seconds, max_health * data.elite_guard_fraction)
		if elite_damage_budget != before_guard:
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
	affix_effects.advance(self, delta)
	if health <= 0.0:
		return
	if target == null or target.stats.health <= 0.0:
		return
	if loot_goblin != null:
		loot_goblin.advance(delta)
		return
	if data.aura_radius > 0.0:
		aura_timer -= delta
		if aura_timer <= 0.0:
			aura_timer = AURA_PULSE_INTERVAL
			_pulse_aura()
	var direction := global_position.direction_to(target.global_position) if active_special_attack == EnemyData.SpecialAttack.NONE or special_phase == SpecialPhase.COOLDOWN else special_direction
	var before_move := global_position
	contact_timer = maxf(contact_timer - delta, 0.0)
	if active_special_attack == EnemyData.SpecialAttack.NONE:
		global_position += direction * _movement_speed() * delta
	else:
		if special_phase == SpecialPhase.WARNING:
			_update_sprite_facing(special_direction)
		_process_special(delta, direction)
	var movement := global_position - before_move
	# A warning is stationary, but its locked attack direction should be readable.
	if movement.is_zero_approx() and special_phase == SpecialPhase.WARNING:
		_update_sprite_facing(special_direction)
	else:
		_update_sprite_facing(movement)
	var contact_radius := data.radius + 20.0
	if contact_timer <= 0.0:
		# Reject distant sweeps before computing the exact closest point. Fast
		# charges still test their whole traveled segment, including crossings.
		var player_at := target.global_position
		if player_at.x >= minf(before_move.x, global_position.x) - contact_radius and player_at.x <= maxf(before_move.x, global_position.x) + contact_radius and player_at.y >= minf(before_move.y, global_position.y) - contact_radius and player_at.y <= maxf(before_move.y, global_position.y) + contact_radius:
			var closest := Geometry2D.get_closest_point_to_segment(player_at, before_move, global_position)
			if closest.distance_squared_to(player_at) < contact_radius * contact_radius:
				try_contact_hit()


func try_contact_hit() -> void:
	if loot_goblin != null: return
	if contact_timer > 0.0 or health <= 0.0 or is_queued_for_deletion() or target == null:
		return
	var charging := special_phase == SpecialPhase.ACTIVE and (active_special_attack == EnemyData.SpecialAttack.DASH or active_special_attack == EnemyData.SpecialAttack.BOSS and boss_move == BossMove.CHARGE)
	charging = charging or caramel_encounter != null and caramel_encounter.state == CaramelEncounter.State.RUSH_ACTIVE
	contact_timer = 0.8 / overtime_attack_factor()
	target.take_hit(attack_damage if charging else contact_damage, inflicted_statuses)


func _update_sprite_facing(direction: Vector2) -> void:
	if data.sprite_facing == EnemyData.SpriteFacing.FRONT:
		sprite.flip_h = false
	elif absf(direction.x) > 0.01:
		sprite.flip_h = direction.x < 0.0 if data.sprite_facing == EnemyData.SpriteFacing.RIGHT else direction.x > 0.0


func _process_special(delta: float, direction: Vector2) -> void:
	if crown_court_encounter != null:
		crown_court_encounter.advance(delta)
		return
	if acid_king_encounter != null:
		acid_king_encounter.advance(delta)
		return
	if caramel_encounter != null:
		caramel_encounter.advance(delta)
		return
	if cloak_encounter != null:
		cloak_encounter.advance(delta)
		return
	if pillow_encounter != null:
		pillow_encounter.advance(delta)
		return
	if data.is_boss and boss_phase_timer > 0.0:
		return
	var chase_speed := _movement_speed()
	match special_phase:
		SpecialPhase.COOLDOWN:
			special_timer = maxf(special_timer - delta * overtime_attack_factor(), 0.0)
			var distance_squared := global_position.distance_squared_to(target.global_position)
			if special_timer <= 0.0 and distance_squared <= active_trigger_range * active_trigger_range:
				special_phase = SpecialPhase.WARNING
				special_timer = data.warning_time
				special_direction = direction
				# The advancing warning ends at the position aimed at now, not a moving target.
				charge_aim_distance = sqrt(distance_squared)
				if active_special_attack == EnemyData.SpecialAttack.BOSS:
					boss_move = BossMove.CHARGE if distance_squared > (data.attack_radius + 45.0) * (data.attack_radius + 45.0) or boss_charge_next else BossMove.PULSE
					boss_charge_next = boss_move != BossMove.CHARGE
					if boss_move == BossMove.CHARGE:
						boss_dash_end = _boss_dash_target(direction)
					attack_performed.emit(&"boss_warning")
				queue_redraw()
			else:
				if active_special_attack == EnemyData.SpecialAttack.SHOOT:
					if distance_squared > (data.preferred_range + 30.0) * (data.preferred_range + 30.0):
						global_position += direction * chase_speed * delta
					elif data.preferred_range > 50.0 and distance_squared < (data.preferred_range - 50.0) * (data.preferred_range - 50.0):
						global_position -= direction * chase_speed * 0.7 * delta
					else:
						global_position += direction.orthogonal() * chase_speed * 0.4 * delta
				else:
					global_position += direction * chase_speed * (1.25 if is_enraged else 1.0) * delta
		SpecialPhase.WARNING:
			var activates_after := maxf(special_timer, 0.0)
			special_timer -= delta
			if spatial_index == null:
				queue_redraw()
			if special_timer <= 0.0:
				_activate_special(activates_after)
		SpecialPhase.ACTIVE:
			var impact_after := minf(maxf(special_timer, 0), delta)
			if active_special_attack == EnemyData.SpecialAttack.BOSS:
				global_position = global_position.move_toward(boss_dash_end, data.attack_speed * difficulty.boss_movement_multiplier * overtime_speed_factor() * delta)
			else:
				global_position += special_direction * data.attack_speed * overtime_speed_factor() * delta
				var margin := DentiArena.WALL_WIDTH + data.radius + 6.0
				global_position = global_position.clamp(Vector2.ONE * margin, target.arena.arena_size - Vector2.ONE * margin)
			special_timer -= delta
			# The local trail of an ordinary dash is constant; moving the node
			# already moves it. Boss trails have a fixed world origin.
			if active_special_attack == EnemyData.SpecialAttack.BOSS and spatial_index == null:
				queue_redraw()
			if special_timer <= 0.0 or active_special_attack == EnemyData.SpecialAttack.BOSS and global_position.distance_squared_to(boss_dash_end) < 1.0:
				if active_special_attack == EnemyData.SpecialAttack.BOSS:
					_fire_boss_fan()
				elif active_special_attack == EnemyData.SpecialAttack.DASH and data.dash_impact_radius > 0.0:
					_dash_impact(impact_after)
				_reset_special()


# Overtime is independent of the existing half-health rage phase.
func start_overtime() -> void:
	BossAttackController.start_overtime(self)


func _tick_overtime(delta: float) -> void:
	BossAttackController.tick_overtime(self, delta)


func advance_overtime(seconds: int) -> void:
	BossAttackController.advance_overtime(self, seconds)


func sync_inflammation_aura(delta: float = 0.0, death_progress: float = 0.0) -> void:
	if inflammation_aura != null:
		inflammation_aura.sync(overtime_active, overtime_seconds, sprite.position, delta, death_progress)


func overtime_speed_factor() -> float:
	return 1.0 + data.overtime_speed_per_second * overtime_seconds


func overtime_attack_factor() -> float:
	return 1.0 + data.overtime_attack_rate_per_second * overtime_seconds


func overtime_defense_factor() -> float:
	return 1.0 + data.overtime_defense_per_second * overtime_seconds


func _movement_speed() -> float:
	var wet_factor := status_speed_factor()
	return move_speed * overtime_speed_factor() * (1.0 + haste_bonus if haste_time > 0.0 else 1.0) * wet_factor


func status_speed_factor() -> float:
	var wet_factor: float = WET_STATUS.speed_factor(data) if wet_time > 0.0 else 1.0
	var ice := WeaponAffixes.by_id(&"ice")
	var resistance := 0.25 if data.is_boss else (0.5 if data.is_elite else 1.0)
	return minf(wet_factor, 1.0 - ice.slow_fraction * resistance if chill_time > 0.0 else 1.0)


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
	for ally in EnemySpatialIndex.circle(get_tree(), spatial_index, global_position, data.aura_radius, false):
		if ally == null or ally == self or ally.data.is_boss or ally.data.is_elite:
			continue
		if global_position.distance_squared_to(ally.global_position) <= radius_squared:
			ally.apply_haste(data.aura_move_bonus, AURA_HASTE_DURATION)


func _boss_dash_target(direction: Vector2) -> Vector2:
	return BossAttackController.boss_dash_target(self, direction)


func _activate_special(seconds_into_frame: float = -1.0) -> void:
	if active_special_attack == EnemyData.SpecialAttack.BOSS:
		if boss_move == BossMove.CHARGE:
			special_phase = SpecialPhase.ACTIVE
			special_timer = data.attack_duration
			boss_dash_origin = global_position
			contact_timer = 0.0
			attack_performed.emit(&"boss_charge")
		else:
			if target.damage_circle_at(global_position, data.attack_radius, seconds_into_frame):
				target.take_hit(attack_damage, inflicted_statuses)
			pulse_flash_time = PULSE_FLASH_DURATION
			attack_performed.emit(&"boss_pulse")
			_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.DASH:
		special_phase = SpecialPhase.ACTIVE
		special_timer = data.attack_duration
	elif active_special_attack == EnemyData.SpecialAttack.SHOOT:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_aimed_fan(root, global_position, special_direction, _aimed_projectile_count(), data.attack_speed, attack_damage, target, data.projectile_color, 2.2, inflicted_statuses)
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.RADIAL:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_radial(root, global_position, data.radial_count, special_direction.angle() + PI, data.attack_speed, attack_damage, target, EnemyProjectilePatterns.RADIAL_COLOR, inflicted_statuses)
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.LANE:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_lane(root, global_position, special_direction, data.lane_projectile_count, data.lane_projectile_spacing, data.attack_speed, attack_damage, target, data.projectile_color, inflicted_statuses)
		attack_performed.emit(&"acid")
		_reset_special()
	elif active_special_attack == EnemyData.SpecialAttack.SPACE_ORB:
		var root := _projectile_root()
		if root != null:
			EnemyProjectilePatterns.fire_space_orb(root, global_position, special_direction, data.attack_speed, attack_damage, data.space_orb_radius, target, inflicted_statuses)
		attack_performed.emit(&"acid")
		_reset_special()
	else:
		if target.damage_circle_at(global_position, data.attack_radius, seconds_into_frame):
			target.take_hit(attack_damage, inflicted_statuses)
		pulse_flash_time = PULSE_FLASH_DURATION
		_reset_special()
	queue_redraw()


func _aimed_projectile_count() -> int:
	return data.aimed_projectile_count if data.aimed_projectile_count > 0 else WaveController.acid_volley_count(spawn_wave)


func _reset_special() -> void:
	special_phase = SpecialPhase.COOLDOWN
	special_timer = data.special_interval * (0.72 if is_enraged else (WaveController.ranged_interval_multiplier(spawn_wave) * difficulty.ranged_interval_multiplier if active_special_attack == EnemyData.SpecialAttack.SHOOT else 1.0))
	if data.is_boss: special_timer *= difficulty.boss_recovery_multiplier
	queue_redraw()


func _dash_impact(seconds_into_frame: float = -1.0) -> void:
	if target.damage_circle_at(global_position, data.dash_impact_radius, seconds_into_frame):
		target.take_hit(attack_damage, inflicted_statuses)
	pulse_flash_time = PULSE_FLASH_DURATION
	queue_redraw()


func _fire_phase_burst() -> void:
	BossAttackController.fire_phase_burst(self)


func _fire_next_boss_radial_volley() -> void:
	BossAttackController.fire_next_boss_radial_volley(self)


func _fire_boss_fan() -> void:
	BossAttackController.fire_boss_fan(self)


func _fire_boss_signature(charge_direction: Vector2) -> void:
	BossAttackController.fire_boss_signature(self, charge_direction)


func _projectile_root() -> Node2D:
	var scene := get_tree().current_scene
	return scene.get_node_or_null("EnemyProjectiles") as Node2D if scene != null else get_parent() as Node2D


func apply_bleed(dps: float, duration: float, stack_cap: int = 3) -> void:
	var previous_stacks := bleed_stacks
	bleed_stacks = mini(bleed_stacks + 1, clampi(stack_cap, 1, MAX_BLEED_STACKS))
	bleed_dps = maxf(bleed_dps, dps)
	bleed_time = maxf(bleed_time, duration)
	if bleed_stacks != previous_stacks:
		queue_redraw()


func apply_wet(duration: float) -> void:
	var was_wet := wet_time > 0.0
	wet_time = maxf(wet_time, duration)
	if not was_wet and wet_time > 0.0:
		queue_redraw()


func apply_enamel_exposure(bonus: float, duration: float) -> void:
	var was_exposed := exposure_time > 0.0
	enamel_exposure = maxf(enamel_exposure, clampf(bonus, 0.0, 0.30))
	exposure_time = maxf(exposure_time, duration)
	if not was_exposed and exposure_time > 0.0:
		queue_redraw()


func has_bleeding() -> bool:
	return bleed_stacks > 0 or affix_effects.pending.has("bleed")


func take_damage(amount: float, weapon: WeaponData = null, critical: bool = false, proc_id: StringName = &"", additions: Array[Dictionary] = [], incoming_direction: Vector2 = Vector2.ZERO) -> float:
	if health <= 0.0:
		return 0.0
	var direct: Array[Dictionary] = []
	var delayed: Array[Dictionary] = []
	var total := amount * (1.0 - data.affix_resistance(&"bleed")) if proc_id == &"bleed" else amount
	amount = total
	for addition in additions:
		var kind := StringName(addition.id)
		var definition := WeaponAffixes.by_id(kind)
		var tick := bool(addition.get("dot_tick", false))
		var value := float(addition.damage) * (1.0 if tick else 1.0 - data.affix_resistance(kind))
		if definition != null and definition.dot_duration > 0 and not tick:
			delayed.append({"id": kind, "damage": value, "can_spread": bool(addition.get("can_spread", true)), "duration": float(addition.get("duration", 0))})
		else:
			direct.append({"id": kind, "damage": value, "dot_tick": tick, "proc_id": str(addition.get("proc_id", "affix_" + str(kind)))})
			total += value
	# Pure DoT applications do not manufacture a minimum-damage direct hit.
	if total <= 0:
		if not (data.is_boss and boss_phase_timer > 0):
			for addition in delayed:
				affix_effects.apply(StringName(addition.id), addition.damage, addition.can_spread, addition.duration)
			if not delayed.is_empty():
				queue_redraw()
		return 0.0
	additions = direct
	var applied := maxf(total * (1.0 - damage_reduction) / overtime_defense_factor(), 1.0 if amount > 0 else 0.0)
	if acid_king_encounter != null: applied *= acid_king_encounter.damage_factor()
	if crown_court_encounter != null: applied *= crown_court_encounter.damage_factor(incoming_direction, proc_id.is_empty())
	if data.is_boss and data.boss_guard_recharge_seconds > 0.0:
		if boss_phase_timer > 0.0:
			_guard_boss_hit()
			return 0.0
		applied = minf(applied, boss_damage_budget)
		if boss_phase < 2:
			applied = minf(applied, maxf(health - _boss_phase_floor(), 0.0))
		if applied <= 0.0:
			_guard_boss_hit()
			return 0.0
		boss_damage_budget = maxf(boss_damage_budget - applied, 0.0)
	elif data.is_elite and data.elite_guard_recharge_seconds > 0.0:
		applied = minf(applied, elite_damage_budget)
		if applied <= 0.0:
			_guard_elite_hit()
			return 0.0
		elite_damage_budget = maxf(elite_damage_budget - applied, 0.0)
	var counted := minf(applied, health)
	health -= applied
	if health > 0:
		for addition in delayed:
			affix_effects.apply(StringName(addition.id), addition.damage, addition.can_spread, addition.duration)
		if not delayed.is_empty():
			queue_redraw()
	var normal_share := amount / total if not additions.is_empty() else 1.0
	var hit_at := global_position + Vector2(0.0, -data.radius)
	if proc_id == &"bleed":
		affix_damaged.emit(hit_at, applied, &"bleed")
	elif amount > 0:
		damaged.emit(hit_at, applied * normal_share)
	if amount > 0:
		damage_recorded.emit(counted * normal_share, weapon.id if weapon != null else &"", proc_id)
	for index in additions.size():
		var addition := additions[index]
		var share := float(addition.damage) / total
		var kind := StringName(addition.id)
		var side := -32.0 if bool(addition.get("dot_tick", false)) else 32.0
		affix_damaged.emit(hit_at + Vector2(side, -24.0 * (index + 1)), applied * share, kind)
		damage_recorded.emit(counted * share, &"", StringName(addition.proc_id))
		if kind == &"ice" and health > 0.0:
			chill_time = maxf(chill_time, WeaponAffixes.by_id(kind).slow_duration)
			affix_effects.ice_power = maxf(affix_effects.ice_power, float(addition.damage))
	if weapon != null:
		weapon_hit.emit(self, applied * normal_share, weapon, critical)
	# A synchronous on-hit effect can kill this enemy in a nested damage call.
	if death_resolved:
		return counted
	if data.is_boss and not is_enraged and health > 0.0 and health <= max_health * 0.5:
		is_enraged = true
		enraged.emit(global_position)
	if data.is_boss and boss_phase < 2 and health <= _boss_phase_floor() + 0.01:
		_start_boss_phase()
	if health <= 0.0:
		_finish_death(counted, delayed)
	else:
		# Ordinary enemies have no health/guard bar; hit flash uses modulate.
		if data.is_boss or data.is_elite:
			queue_redraw()
		if hit_flash_time < 0.12:
			modulate = Color(1.6, 1.6, 1.6)
		hit_flash_time = 0.12
	return counted


func _finish_death(amount: float, delayed: Array[Dictionary]) -> void:
	if death_resolved:
		return
	death_resolved = true
	health = 0.0
	if pillow_encounter != null:
		pillow_encounter.cancel()
	if cloak_encounter != null:
		cloak_encounter.cancel()
	if caramel_encounter != null:
		caramel_encounter.cancel()
	if acid_king_encounter != null:
		acid_king_encounter.cancel()
	if crown_court_encounter != null:
		crown_court_encounter.cancel()
	for addition in delayed:
		if addition.id == &"fire":
			affix_effects.remember_fire(addition.damage, addition.can_spread)
	died.emit(self, amount)
	remove_from_group("enemies")
	if data.is_boss:
		dying = true
		death_elapsed = 0.0
		death_started.emit(global_position)
		queue_redraw()
	else:
		defeated.emit(global_position, data)
		queue_free()


func _boss_phase_floor() -> float:
	return BossAttackController.boss_phase_floor(self)


func _start_boss_phase() -> void:
	BossAttackController.start_boss_phase(self)


func _guard_boss_hit() -> void:
	BossAttackController.guard_boss_hit(self)


func _guard_elite_hit() -> void:
	if boss_guard_feedback_time <= 0.0:
		elite_guarded.emit(global_position)
		boss_guard_feedback_time = 0.8
	queue_redraw()


func _draw() -> void:
	EnemyVisuals.draw(self)


func _warning_rays(mode: int, count: int) -> Array[Vector2]:
	return EnemyVisuals.warning_rays(self, mode, count)


func warning_lane_start() -> Vector2:
	return EnemyVisuals.warning_lane_start(self)


func warning_lane_end() -> Vector2:
	return EnemyVisuals.warning_lane_end(self)


func warning_lane_half_width() -> float:
	return EnemyVisuals.warning_lane_half_width(self)


func draw_warning_fill(canvas: CanvasItem, base: Transform2D = Transform2D.IDENTITY, fill_scales: PackedFloat32Array = PackedFloat32Array()) -> void:
	EnemyVisuals.draw_warning_fill(self, canvas, base, fill_scales)


func draw_attack_visuals(canvas: CanvasItem, base: Transform2D = Transform2D.IDENTITY, fill_scales: PackedFloat32Array = PackedFloat32Array(), draw_fill: bool = true) -> void:
	EnemyVisuals.draw_attack_visuals(self, canvas, base, fill_scales, draw_fill)


func save_state() -> Dictionary:
	return EnemySnapshot.capture(self)


func restore_state(saved: Dictionary, boss_pending: bool = false) -> void:
	EnemySnapshot.restore(self, saved, boss_pending)
