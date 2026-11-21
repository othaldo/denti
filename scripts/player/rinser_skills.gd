class_name RinserSkills
extends ClassSkillModule

## Spültechniker: "Erst wischen, dann zünden". Walking leaves a short rinse
## trail; enemies on it are wet. A weapon hit on an enemy standing on the trail
## arcs to other enemies on the trail, and every dash surges the whole trail.
## Skills: Kurzschluss (closing a loop pulses everything inside), Schwall (the
## dash shoves wet enemies), Notdusche (emergency wave at low health).

const SEGMENT_STEP := 26.0
const SEGMENTS := 14
const SEGMENT_SECONDS := 4.0
const TRAIL_RADIUS := 32.0
const WET_TICK := 0.25
const ARC_TARGETS := 3
const ARC_RANGE := 220.0
const ARC_SHARE := 0.35
const ARC_COOLDOWN := 0.25
const SURGE_BASE := 12.0
const SURGE_RANGED := 1.0
const LOOP_CLOSE := 40.0
const LOOP_AGE := 1.5
const LOOP_COOLDOWN := 3.0
const LOOP_PULSES := 2
const LOOP_INTERVAL := 2.0
const PULSE_BASE := 20.0
const PULSE_RANGED := 1.2
const GROUND_HITS := 5
const GROUND_COOLDOWN := 8.0
const SURGE_PUSH := 60.0
const SURGE_PUSH_RADIUS := 200.0
const SHOWER_RADIUS := 200.0
const SHOWER_PUSH := 100.0
const SHOWER_HEAL := 0.1
const SHOWER_COOLDOWN := 20.0
const SHOWER_FAST := 12.0
const SHOWER_THRESHOLD := 0.35
const SHOWER_STONE := 0.5
const WATER := Color(0.35, 0.75, 1.0)
const SPARK := Color(1.0, 0.95, 0.45)
const FOAM_STYLE: SkillCloudStyle = preload("res://data/vfx/skill_clouds/foam.tres")

var trail: Array[Dictionary] = []
var last_drop := Vector2.INF
var wet_tick := 0.0
var arc_cooldown := 0.0
var loop_cooldown := 0.0
var loop: Dictionary = {}
var ground_cooldown := 0.0
var shower_cooldown := 0.0
var on_trail: Dictionary = {}
var dash_direction := Vector2.RIGHT

func class_id() -> StringName:
	return &"rinser"

func reset_wave() -> void:
	super.reset_wave()
	trail.clear()
	last_drop = Vector2.INF
	wet_tick = 0.0
	arc_cooldown = 0.0
	loop_cooldown = 0.0
	loop = {}
	ground_cooldown = 0.0
	shower_cooldown = 0.0
	on_trail.clear()

func max_segments() -> int:
	return SEGMENTS + 4 * roundi(power("rinse_hose"))

func segment_seconds() -> float:
	return SEGMENT_SECONDS + 1.5 * power("rinse_drip")

func surge_factor() -> float:
	return 1.5 if power("rinse_pressure") > 0.0 else 1.0

func _drop(at: Vector2) -> void:
	trail.append({"at": at, "time": segment_seconds(), "age": 0.0})
	while trail.size() > max_segments(): trail.pop_front()
	last_drop = at
	if power("skill_short") > 0.0 and loop_cooldown <= 0.0: _check_loop(at)

## Kurzschluss: the new segment touches an old one, closing a loop.
func _check_loop(at: Vector2) -> void:
	for index in trail.size() - 1:
		var segment := trail[index]
		if float(segment.age) < LOOP_AGE or segment.at.distance_to(at) > LOOP_CLOSE: continue
		var centre := Vector2.ZERO
		var count := 0
		for inner in range(index, trail.size()):
			centre += trail[inner].at
			count += 1
		centre /= maxf(count, 1)
		var radius := 0.0
		for inner in range(index, trail.size()): radius = maxf(radius, centre.distance_to(trail[inner].at))
		loop = {"at": centre, "radius": radius + TRAIL_RADIUS, "pulses": LOOP_PULSES, "time": 0.0}
		loop_cooldown = LOOP_COOLDOWN
		support(&"class_rinse_loops")
		return

func _pulse() -> void:
	var amount := scaled((PULSE_BASE + maxf(player.stats.ranged_damage, 0.0) * PULSE_RANGED) * (1.5 if power("short_power") > 0.0 else 1.0))
	var hits := 0
	for enemy in player.nearby_enemies(loop.at, loop.radius):
		if not enemy.is_targetable(): continue
		enemy.take_damage(amount, null, false, &"class_rinse")
		hits += 1
	if power("short_rain") > 0.0: _surge(0.5)
	if power("short_ground") > 0.0 and hits >= GROUND_HITS and ground_cooldown <= 0.0:
		ground_cooldown = GROUND_COOLDOWN
		player.stats.grant_shield(1)
	flash(loop.at, loop.radius, SPARK)

func on_trail_enemy(enemy: Enemy) -> bool:
	return on_trail.has(enemy.get_instance_id())

## Strom: a hit on an enemy standing on the trail jumps to others on it.
func on_weapon_hit(enemy: Enemy, _weapon: WeaponData, dealt: float) -> void:
	if not active() or dealt <= 0.0 or arc_cooldown > 0.0 or not on_trail_enemy(enemy): return
	arc_cooldown = ARC_COOLDOWN
	var amount := dealt * (ARC_SHARE + 0.1 * power("rinse_copper"))
	var targets := 0
	for other in player.nearby_enemies(enemy.global_position, ARC_RANGE):
		if targets >= ARC_TARGETS + roundi(power("rinse_conductor")): break
		if other == enemy or not other.is_targetable() or not on_trail_enemy(other): continue
		other.take_damage(amount, null, false, &"class_rinse")
		beam(enemy.global_position, other.global_position, SPARK, 2.5)
		targets += 1
	if targets > 0: support(&"class_rinse_arcs", targets)

## Spülstoß: every dash surges all enemies on the trail.
func _surge(factor: float = 1.0) -> int:
	var amount := scaled((SURGE_BASE + maxf(player.stats.ranged_damage, 0.0) * SURGE_RANGED) * surge_factor() * factor)
	var hits := 0
	for id in on_trail.keys():
		var enemy := instance_from_id(id) as Enemy
		if not is_instance_valid(enemy) or not enemy.is_targetable(): continue
		enemy.take_damage(amount, null, false, &"class_rinse")
		hits += 1
	for segment in trail: flash(segment.at, TRAIL_RADIUS, SPARK)
	return hits

func on_dash_started() -> void:
	if not active(): return
	dash_direction = player.dash.direction
	if _surge() > 0: support(&"class_rinse_surges")
	if power("skill_flood") > 0.0: _flood()
	if power("flood_puddles") > 0.0:
		for index in range(maxi(trail.size() - 3, 0), trail.size()): player.items.create_puddle(trail[index].at)

## Schwall (Sog: pull instead): wet enemies near Denti are shoved.
func _flood() -> void:
	for enemy in player.nearby_enemies(player.global_position, SURGE_PUSH_RADIUS):
		if not enemy.is_targetable() or enemy.wet_time <= 0.0: continue
		var direction := dash_direction if power("flood_suction") <= 0.0 else enemy.global_position.direction_to(player.global_position)
		enemy.global_position += direction * SURGE_PUSH * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))

## Notdusche: one emergency wave at low health, then a cooldown.
func _shower() -> void:
	push_from(player.global_position, SHOWER_RADIUS, SHOWER_PUSH)
	shatter_projectiles(player.global_position, SHOWER_RADIUS)
	player.stats.heal(player.stats.max_health * SHOWER_HEAL)
	if power("shower_scale") > 0.0: player.stats.grant_shield(1)
	shower_cooldown = SHOWER_FAST if power("shower_rinse") > 0.0 else SHOWER_COOLDOWN
	flash(player.global_position, SHOWER_RADIUS, WATER)
	support(&"class_rinse_showers")

func advance(delta: float) -> void:
	if active():
		arc_cooldown = maxf(arc_cooldown - delta, 0.0)
		loop_cooldown = maxf(loop_cooldown - delta, 0.0)
		ground_cooldown = maxf(ground_cooldown - delta, 0.0)
		shower_cooldown = maxf(shower_cooldown - delta, 0.0)
		for index in range(trail.size() - 1, -1, -1):
			trail[index].time -= delta
			trail[index].age += delta
			if trail[index].time <= 0.0: trail.remove_at(index)
		if last_drop == Vector2.INF or player.global_position.distance_to(last_drop) >= SEGMENT_STEP: _drop(player.global_position)
		wet_tick -= delta
		if wet_tick <= 0.0:
			wet_tick = WET_TICK
			_soak()
		if not loop.is_empty():
			loop.time -= delta
			if loop.time <= 0.0:
				_pulse()
				loop.pulses -= 1
				loop.time = LOOP_INTERVAL
				if loop.pulses <= 0: loop = {}
		if power("skill_shower") > 0.0 and shower_cooldown <= 0.0:
			var threshold := SHOWER_STONE if power("shower_stone") > 0.0 else SHOWER_THRESHOLD
			if player.stats.health <= player.stats.max_health * threshold: _shower()
	super.advance(delta)

## Enemies on the trail get wet; with Schaumbad also slowed.
func _soak() -> void:
	on_trail.clear()
	var foam := power("flood_foam") > 0.0
	for segment in trail:
		for enemy in player.nearby_enemies(segment.at, TRAIL_RADIUS):
			var id := enemy.get_instance_id()
			if on_trail.has(id) or not enemy.is_targetable(): continue
			on_trail[id] = true
			enemy.apply_wet(1.0)
			if foam and enemy.affix_effects.depot.nerve_lock <= 0:
				enemy.affix_effects.depot.nerve_time = PoisonDepotState.RULES.nerve_duration

func _draw() -> void:
	if trail.size() > 1:
		var points := PackedVector2Array()
		for segment in trail: points.append(to_local(segment.at))
		draw_polyline(points, Color(WATER, 0.16), TRAIL_RADIUS * 1.4, true)
		draw_polyline(points, Color(WATER, 0.55), 3.0, true)
	# Foam flakes with bubbles on the wet trail.
	for segment in trail:
		SkillPuffs.draw_cloud(self, to_local(segment.at), TRAIL_RADIUS, FOAM_STYLE, float(segment.age), float(segment.time), SkillPuffs.seed_for(segment.at))
	if not loop.is_empty():
		draw_arc(to_local(loop.at), loop.radius, 0.0, TAU, 48, Color(SPARK, 0.6), 3.0, true)
	draw_effects()

func save_data() -> Dictionary:
	var saved_trail: Array = []
	for segment in trail: saved_trail.append({"at": SnapshotValues.vector_data(segment.at), "time": float(segment.time), "age": float(segment.age)})
	return {"trail": saved_trail, "shower_cooldown": shower_cooldown, "ground_cooldown": ground_cooldown}

func restore(saved: Dictionary) -> void:
	reset_wave()
	for segment in saved.get("trail", []):
		if segment is Dictionary and SnapshotValues.is_vector(segment.get("at")) and trail.size() < SEGMENTS + 8:
			trail.append({"at": SnapshotValues.read_vector(segment.at), "time": clampf(float(segment.get("time", 0)), 0.0, SEGMENT_SECONDS + 3.0), "age": maxf(float(segment.get("age", 0)), 0.0)})
	shower_cooldown = clampf(float(saved.get("shower_cooldown", 0.0)), 0.0, SHOWER_COOLDOWN)
	ground_cooldown = clampf(float(saved.get("ground_cooldown", 0.0)), 0.0, GROUND_COOLDOWN)
	if not trail.is_empty(): last_drop = trail[-1].at
