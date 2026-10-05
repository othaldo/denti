class_name EnemyMotion
extends RefCounted

# One fixed-step owner, with contiguous positions for ordinary pursuit. Enemy
# remains the authoritative combat/save state; complex steps use its full path.
var enemies: Array[Enemy] = []
var positions := PackedVector2Array()
var cell_bounds: Array[Rect2] = []
var vacant: int = 0
var applying: bool = false
var stepping: bool = false

func register(enemy: Enemy, cell: Vector2i) -> void:
	enemy.motion_slot = enemies.size()
	enemies.append(enemy)
	positions.append(enemy.position)
	cell_bounds.append(Rect2(Vector2(cell) * EnemySpatialIndex.CELL_SIZE, Vector2.ONE * EnemySpatialIndex.CELL_SIZE))

func track(enemy: Enemy, cell: Vector2i) -> void:
	var slot := enemy.motion_slot
	if slot < 0:
		return
	positions[slot] = enemy.position
	cell_bounds[slot] = Rect2(Vector2(cell) * EnemySpatialIndex.CELL_SIZE, Vector2.ONE * EnemySpatialIndex.CELL_SIZE)

func unregister(enemy: Enemy) -> void:
	var slot := enemy.motion_slot
	if slot < 0:
		return
	enemies[slot] = null
	enemy.motion_slot = -1
	vacant += 1
	if vacant == enemies.size() and not stepping:
		enemies.clear()
		positions.clear()
		cell_bounds.clear()
		vacant = 0

func _compact() -> void:
	var live: Array[Enemy] = []
	var live_positions := PackedVector2Array()
	var live_bounds: Array[Rect2] = []
	for slot in enemies.size():
		var enemy := enemies[slot]
		if enemy == null:
			continue
		enemy.motion_slot = live.size()
		live.append(enemy)
		live_positions.append(positions[slot])
		live_bounds.append(cell_bounds[slot])
	enemies = live
	positions = live_positions
	cell_bounds = live_bounds
	vacant = 0

func step(index: EnemySpatialIndex, delta: float) -> void:
	if vacant > 0 and (vacant == enemies.size() or vacant > 32 and vacant * 2 > enemies.size()):
		_compact()
	stepping = true
	# The ordinary arena has an identity transform. Transformed arenas keep the
	# full world-space path, including nonuniform scale and swept charge contact.
	var ordinary_space := index.global_transform == Transform2D.IDENTITY
	var player: Player
	var player_at := Vector2.ZERO
	for slot in enemies.size():
		var enemy := enemies[slot]
		if enemy == null or not enemy.simulation_enabled:
			continue
		if player == null and enemy.target != null:
			player = enemy.target
			player_at = player.global_position
		var data := enemy.data
		if not ordinary_space or enemy.target != player or player == null or data.is_boss or data.is_elite or data.aura_radius > 0.0 or enemy.overtime_active or enemy.bleed_time > 0.0 or enemy.special_phase != Enemy.SpecialPhase.COOLDOWN:
			enemy._physics_process(delta)
			if player != null:
				player_at = player.global_position
			continue
		if enemy.health <= 0.0 or player.stats.health <= 0.0:
			# Status clocks still expire when movement/contact is disabled by death.
			if enemy.wet_time > 0.0 or enemy.exposure_time > 0.0 or enemy.haste_time > 0.0:
				enemy._physics_process(delta)
			continue
		var before := positions[slot]
		var direction := before.direction_to(player_at)
		var attack := enemy.active_special_attack
		var timer := enemy.special_timer
		if attack != EnemyData.SpecialAttack.NONE:
			timer = maxf(timer - delta, 0.0)
			# Let the existing attack code choose, announce and activate attacks.
			# It owns the timer decrement on this step as well.
			if timer <= 0.0 and before.distance_squared_to(player_at) <= enemy.active_trigger_range * enemy.active_trigger_range:
				enemy._physics_process(delta)
				player_at = player.global_position
				continue
			enemy.special_timer = timer
		# Wet/exposure/haste alone do not require the general per-enemy path.
		# Tick after attack admission so a warning-start step is handled exactly
		# once by Enemy._physics_process. Expiry precedes this step's movement.
		if enemy.exposure_time > 0.0:
			enemy.exposure_time = maxf(enemy.exposure_time - delta, 0.0)
			if enemy.exposure_time <= 0.0:
				enemy.enamel_exposure = 0.0
				enemy.queue_redraw()
		if enemy.haste_time > 0.0:
			enemy.haste_time = maxf(enemy.haste_time - delta, 0.0)
			if enemy.haste_time <= 0.0:
				enemy.haste_bonus = 0.0
				enemy.queue_redraw()
		if enemy.wet_time > 0.0:
			enemy.wet_time = maxf(enemy.wet_time - delta, 0.0)
			if enemy.wet_time <= 0.0:
				enemy.queue_redraw()
		var speed := enemy.move_speed
		if enemy.haste_time > 0.0:
			speed *= 1.0 + enemy.haste_bonus
		if enemy.wet_time > 0.0:
			speed *= Enemy.WET_STATUS.speed_factor(data)
		var movement := direction * speed * delta
		if attack == EnemyData.SpecialAttack.SHOOT:
			var distance := before.distance_squared_to(player_at)
			if distance > (data.preferred_range + 30.0) * (data.preferred_range + 30.0):
				pass
			elif data.preferred_range > 50.0 and distance < (data.preferred_range - 50.0) * (data.preferred_range - 50.0):
				movement = -direction * speed * 0.7 * delta
			else:
				movement = direction.orthogonal() * speed * 0.4 * delta
		elif attack != EnemyData.SpecialAttack.NONE and enemy.is_enraged:
			movement = direction * speed * 1.25 * delta
		var after := before + movement
		positions[slot] = after
		# The index is updated explicitly only when movement crosses a cell.
		applying = true
		enemy.position = after
		applying = false
		if not cell_bounds[slot].has_point(after):
			index.update(enemy)
		# Facing uses actual displacement, including float rounding at rest.
		if data.sprite_facing != EnemyData.SpriteFacing.FRONT:
			var dx := after.x - before.x
			if absf(dx) > 0.01:
				enemy.sprite.flip_h = dx < 0.0 if data.sprite_facing == EnemyData.SpriteFacing.RIGHT else dx > 0.0
		else:
			enemy.sprite.flip_h = false
		enemy.contact_timer = maxf(enemy.contact_timer - delta, 0.0)
		if enemy.contact_timer > 0.0:
			continue
		var radius := data.radius + 20.0
		if player_at.x < minf(before.x, after.x) - radius or player_at.x > maxf(before.x, after.x) + radius or player_at.y < minf(before.y, after.y) - radius or player_at.y > maxf(before.y, after.y) + radius:
			continue
		var closest := Geometry2D.get_closest_point_to_segment(player_at, before, after)
		if closest.distance_squared_to(player_at) < radius * radius:
			enemy.contact_timer = 0.8
			player.take_hit(enemy.contact_damage, enemy.inflicted_statuses)
			# Hurt/item callbacks can change the player's location or state.
			player_at = player.global_position
	stepping = false
