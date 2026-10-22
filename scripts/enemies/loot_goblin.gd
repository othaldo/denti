class_name LootGoblin
extends Node

signal stolen(amount: int, at: Vector2)
signal escaped(amount: int)
signal reward_ready(amount: int, capsule: Dictionary)

enum State { SCAVENGE, FLEE, SPRINT, BREATHER, GRAB, RESOLVED }

var enemy: Enemy
var profile: LootGoblinData
var state: State = State.SCAVENGE
var carried: int = 0
var capsule: Dictionary = {}
var destination := Vector2.ZERO
var plan_time := 0.0
var state_time := 0.0
var sprint_time := 0.0
var motion_time := 0.0
var walking := false
var facing := 1.0
var grab_time := 0.0
var grab_animation_time := 0.0
var loot_target: Loot
var rig: LootGoblinRig

func _ready() -> void:
	profile = enemy.data.loot_goblin_profile
	enemy.move_speed = enemy.data.move_speed * profile.speed_factor(enemy.difficulty.id) * EndlessRules.speed_factor(enemy.spawn_wave)
	enemy.sprite.texture = null
	rig = LootGoblinRig.new()
	enemy.sprite.add_child(rig)
	# Parent Sprite2D retains the existing hit flash and bobbing. Rig coordinates
	# use the same 512 px reference side as the EnemyData atlas region.
	rig.scale = Vector2.ONE * 512.0 / LootGoblinRig.REFERENCE_SIZE
	destination = enemy.global_position
	enemy.died.connect(_on_death)

func _process(delta: float) -> void:
	if not enemy.simulation_enabled: return
	motion_time += delta
	rig.sample(motion_time, walking, state == State.SPRINT, grab_animation_time > 0, float(carried) / profile.capacity, facing)

func advance(delta: float) -> void:
	if state == State.RESOLVED: return
	plan_time -= delta
	sprint_time = maxf(0, sprint_time - delta)
	state_time = maxf(0, state_time - delta)
	grab_time = maxf(0, grab_time - delta)
	grab_animation_time = maxf(0, grab_animation_time - delta)
	if grab_time <= 0 and carried < profile.capacity:
		grab_time = profile.grab_seconds
		_scoop_nearby()
	var danger := enemy.global_position.distance_to(enemy.target.global_position) < profile.panic_range
	if state == State.SPRINT and state_time <= 0:
		state = State.BREATHER
		state_time = profile.breather_seconds
	if state == State.BREATHER and state_time <= 0:
		state = State.FLEE if danger else State.SCAVENGE
	if state not in [State.SPRINT, State.BREATHER]:
		state = State.FLEE if danger or carried >= profile.capacity else State.SCAVENGE
		if danger and sprint_time <= 0:
			state = State.SPRINT
			state_time = profile.sprint_seconds
			sprint_time = profile.sprint_cooldown
			plan_time = 0
	if plan_time <= 0:
		plan_time = profile.planning_interval
		if state == State.SCAVENGE:
			_plan_loot()
		else:
			destination = choose_cover()
	var speed := enemy._movement_speed() * lerpf(1, profile.full_bag_speed_factor, float(carried) / profile.capacity)
	if state == State.SPRINT: speed *= profile.sprint_factor
	elif state == State.BREATHER: speed *= 0.42
	var before := enemy.global_position
	enemy.global_position = before.move_toward(destination, speed * delta)
	walking = enemy.global_position.distance_squared_to(before) > 0.001
	var dx := enemy.global_position.x - before.x
	if absf(dx) > 0.01: facing = signf(dx)

func _plan_loot() -> void:
	loot_target = null
	var index := enemy.get_node_or_null("../../Loot") as LootSpatialIndex
	var best := INF
	if index != null and carried < profile.capacity:
		for drop in index.in_circle(enemy.global_position, profile.loot_search_range):
			if not drop.stealable(): continue
			var distance := enemy.global_position.distance_squared_to(drop.global_position)
			if distance < best:
				best = distance
				loot_target = drop
	destination = loot_target.global_position if loot_target != null else choose_cover()

func _scoop_nearby() -> void:
	var index := enemy.get_node_or_null("../../Loot") as LootSpatialIndex
	if index == null: return
	var total := 0
	var first_at := enemy.global_position
	for drop in index.in_circle(enemy.global_position, profile.grab_radius):
		var taken := drop.take_for_goblin(profile.capacity - carried)
		if taken <= 0: continue
		if total == 0: first_at = drop.global_position
		carried += taken
		total += taken
		if carried >= profile.capacity: break
	if total > 0:
		# One visual/signal for the batch, including during flight. Moving and
		# collecting are independent; a nearby Denti never disables the theft.
		grab_animation_time = profile.grab_seconds
		plan_time = 0
		stolen.emit(total, first_at)

func choose_cover() -> Vector2:
	var at := enemy.global_position
	var player_at := enemy.target.global_position
	var away := player_at.direction_to(at)
	if away.is_zero_approx(): away = Vector2.RIGHT
	var candidates: Array[Vector2] = []
	for angle in [-1.15, -0.65, 0.0, 0.65, 1.15, PI * 0.5, -PI * 0.5]:
		candidates.append(at + away.rotated(angle) * 210)
	var neighbors: Array[Enemy] = []
	if enemy.spatial_index != null:
		neighbors = enemy.spatial_index.in_circle(at, profile.cover_search_range)
		neighbors.sort_custom(func(a: Enemy, b: Enemy) -> bool: return at.distance_squared_to(a.global_position) < at.distance_squared_to(b.global_position))
		if neighbors.size() > 24: neighbors.resize(24)
	for mob in neighbors:
		if mob == enemy or mob.health <= 0 or mob.data.loot_goblin_profile != null: continue
		var behind := player_at.direction_to(mob.global_position)
		candidates.append(mob.global_position + behind * (mob.data.radius + enemy.data.radius + 55))
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 18
	var lower := Vector2.ONE * margin
	var upper := enemy.target.arena.arena_size - lower
	var best := at
	var best_score := -INF
	for raw in candidates:
		var candidate := raw.clamp(lower, upper)
		# Crossing Denti to reach apparent cover is not a valid escape route.
		var crossing := Geometry2D.get_closest_point_to_segment(player_at, at, candidate)
		if crossing.distance_to(player_at) < minf(enemy.data.radius + 38, at.distance_to(player_at) - 2): continue
		var score := candidate.distance_to(player_at) - at.distance_to(candidate) * 0.35
		score -= raw.distance_to(candidate) * 2.0
		for mob in neighbors:
			if mob == enemy or mob.health <= 0: continue
			var projected := Geometry2D.get_closest_point_to_segment(mob.global_position, player_at, candidate)
			if projected.distance_to(mob.global_position) < mob.data.radius + 28 and mob.global_position.distance_to(player_at) < candidate.distance_to(player_at) - 35:
				score += 55
			if candidate.distance_to(mob.global_position) < mob.data.radius + enemy.data.radius:
				score -= 110
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _on_death(_victim: Enemy, _damage: float) -> void:
	if state == State.RESOLVED: return
	state = State.RESOLVED
	walking = false
	var recovered := carried
	carried = 0
	reward_ready.emit(recovered, capsule.duplicate(true))

func escape() -> void:
	if state == State.RESOLVED or enemy.health <= 0: return
	state = State.RESOLVED
	walking = false
	var lost := carried
	carried = 0
	escaped.emit(lost)

func save_data() -> Dictionary:
	return {"carried": carried, "capsule": capsule.duplicate(true), "state": state, "state_time": state_time,
		"sprint_time": sprint_time, "plan_time": plan_time, "destination": SnapshotValues.vector_data(destination),
		"motion_time": motion_time, "facing": facing, "grab_time": grab_time, "grab_animation_time": grab_animation_time}

func restore(saved: Dictionary) -> void:
	carried = clampi(int(saved.get("carried", 0)), 0, profile.capacity)
	capsule = WeaponAffixes.sanitize_chest(saved.get("capsule", {})) if not saved.get("capsule", {}).is_empty() else {}
	state = clampi(int(saved.get("state", 0)), 0, State.RESOLVED) as State
	# A grab target is transient; resume by seeking, never by stealing remotely.
	if state == State.GRAB: state = State.SCAVENGE
	grab_time = clampf(float(saved.get("grab_time", 0)), 0, profile.grab_seconds)
	grab_animation_time = clampf(float(saved.get("grab_animation_time", 0)), 0, profile.grab_seconds)
	state_time = clampf(float(saved.get("state_time", 0)), 0, profile.grab_seconds + profile.breather_seconds + profile.sprint_seconds)
	sprint_time = clampf(float(saved.get("sprint_time", 0)), 0, profile.sprint_cooldown)
	plan_time = 0
	destination = SnapshotValues.read_vector(saved.get("destination", [enemy.position.x, enemy.position.y]))
	motion_time = maxf(float(saved.get("motion_time", 0)), 0)
	facing = -1 if float(saved.get("facing", 1)) < 0 else 1
