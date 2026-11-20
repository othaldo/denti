class_name FrostSkills
extends ClassSkillModule

## Frostwächter: "Bis hierhin und nicht weiter". Every dash leaves an ice wall
## along its path. Ordinary enemies cannot cross it: they pile up in front,
## get chilled and, after a moment, brittle. Bosses break walls on contact.
## Skills: Zerschmettern (hits shatter brittle enemies into splinters),
## Frostwelle (expiring walls burst), Eispanzer (a new wall grants a shield).

const WALL_SECONDS := 3.0
const WALL_LIMIT := 3
const WALL_HALF := 18.0
const WALL_MIN_LENGTH := 12.0
const CHILL_SECONDS := 0.6
const BRITTLE_AFTER := 1.0
const BRITTLE_FAST := 0.6
const BRITTLE_SECONDS := 3.0
const SPIKE_TICK := 0.5
const SPIKE_DAMAGE := 4.0
const SLIDE_PUSH := 30.0
const SHATTER_SHARE := 0.6
const SPLINTERS := 2
const SPLINTER_RANGE := 120.0
const SPLINTER_SHARE := 0.4
const WAVE_BASE := 18.0
const WAVE_MELEE := 0.8
const WAVE_RADIUS := 40.0
const ARMOR_COOLDOWN := 8.0
const ARMOR_FAST := 5.0
const BREATH_RADIUS := 150.0
const STARE_RADIUS := 120.0
const STARE_PUSH := 60.0
const ICE := Color(0.7, 0.92, 1.0)

var walls: Array[Dictionary] = []
var dash_start := Vector2.ZERO
var contact: Dictionary = {}
var brittle: Dictionary = {}
var armor_cooldown := 0.0
var spike_tick := 0.0

func class_id() -> StringName:
	return &"frost_warden"

func reset_wave() -> void:
	super.reset_wave()
	walls.clear()
	contact.clear()
	brittle.clear()
	armor_cooldown = 0.0
	spike_tick = 0.0

func wall_seconds() -> float:
	var seconds := WALL_SECONDS + power("frost_thick") + (1.5 if power("wall_lasting") > 0.0 else 0.0)
	return seconds * (2.0 if power("frost_permafrost") > 0.0 else 1.0)

func on_dash_started() -> void:
	dash_start = player.global_position

func on_dash_ended(_start: Vector2, end: Vector2) -> void:
	if not active() or dash_start.distance_to(end) < WALL_MIN_LENGTH: return
	walls.append({"a": dash_start, "b": end, "time": wall_seconds()})
	while walls.size() > WALL_LIMIT: walls.pop_front()
	support(&"class_frost_walls")
	if power("skill_icearmor") > 0.0 and armor_cooldown <= 0.0:
		armor_cooldown = ARMOR_FAST if power("armor_rime") > 0.0 else ARMOR_COOLDOWN
		player.stats.grant_shield(1)

## Keeps ordinary enemies on their side of every wall; bosses break it.
func _hold(delta: float) -> void:
	var touching := {}
	for wall in walls:
		var reach := WALL_HALF + 40.0
		for enemy in player.enemies_on_segment(wall.a, wall.b, reach):
			if not enemy.is_targetable(): continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, wall.a, wall.b)
			var offset: Vector2 = enemy.global_position - closest
			var limit := WALL_HALF + enemy.data.radius
			if offset.length() >= limit: continue
			if enemy.data.is_boss:
				wall.time = 0.0
				break
			var side: Vector2 = offset.normalized() if not offset.is_zero_approx() else (wall.b - wall.a).orthogonal().normalized()
			var push := limit + (SLIDE_PUSH * delta * 4.0 if power("wall_slide") > 0.0 else 0.0)
			enemy.global_position = closest + side * push
			enemy.chill_time = maxf(enemy.chill_time, CHILL_SECONDS)
			touching[enemy.get_instance_id()] = enemy
	var after := BRITTLE_FAST if power("frost_bite") > 0.0 else BRITTLE_AFTER
	for id in contact.keys():
		if not touching.has(id): contact.erase(id)
	for id in touching:
		contact[id] = float(contact.get(id, 0.0)) + delta
		if float(contact[id]) >= after: brittle[id] = BRITTLE_SECONDS
	if power("wall_spikes") > 0.0 and not touching.is_empty():
		spike_tick -= delta
		if spike_tick <= 0.0:
			spike_tick = SPIKE_TICK
			for id in touching: touching[id].take_damage(scaled(SPIKE_DAMAGE), null, false, &"class_frost")

## Zerschmettern: a hit on a brittle enemy shatters it into splinters.
func on_weapon_hit(enemy: Enemy, _weapon: WeaponData, dealt: float) -> void:
	if not active() or power("skill_shatter") <= 0.0 or dealt <= 0.0: return
	_shatter(enemy, dealt, true)

func _shatter(enemy: Enemy, dealt: float, chain: bool) -> void:
	var id := enemy.get_instance_id()
	if not brittle.has(id): return
	brittle.erase(id)
	var amount := dealt * (SHATTER_SHARE + 0.2 * power("frost_hammer"))
	if power("shatter_shock") > 0.0: amount *= 1.5
	var at := enemy.global_position
	if enemy.health > 0.0: enemy.take_damage(amount, null, power("shatter_shock") > 0.0, &"class_frost")
	var splinters := SPLINTERS + (2 if power("shatter_icicles") > 0.0 else 0)
	for other in player.nearby_enemies(at, SPLINTER_RANGE):
		if splinters <= 0: break
		if other == enemy or not other.is_targetable(): continue
		other.take_damage(dealt * SPLINTER_SHARE, null, false, &"class_frost")
		beam(at, other.global_position, ICE, 2.0)
		splinters -= 1
		if chain and power("shatter_chain") > 0.0: _shatter(other, dealt * SPLINTER_SHARE, false)
	ElementImpactBatch.emit_from(player, &"ice", at, Vector2.RIGHT, 50.0, true)
	support(&"class_frost_shatters")

## Frostwelle: an expiring wall bursts and hits everything beside it.
func _wave(wall: Dictionary) -> void:
	var amount := scaled(WAVE_BASE + maxf(player.stats.melee_damage, 0.0) * WAVE_MELEE) * (1.5 if power("wave_avalanche") > 0.0 else 1.0)
	for enemy in player.enemies_on_segment(wall.a, wall.b, WAVE_RADIUS + 30.0):
		if not enemy.is_targetable(): continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, wall.a, wall.b)
		if closest.distance_to(enemy.global_position) <= WAVE_RADIUS + enemy.data.radius:
			enemy.take_damage(amount, null, false, &"class_frost")
	flash(wall.a.lerp(wall.b, 0.5), wall.a.distance_to(wall.b) * 0.5 + WAVE_RADIUS, ICE)
	support(&"class_frost_waves")

func on_shield_blocked() -> void:
	if not active(): return
	if power("armor_breath") > 0.0:
		for enemy in player.nearby_enemies(player.global_position, BREATH_RADIUS):
			enemy.chill_time = maxf(enemy.chill_time, CHILL_SECONDS * 3.0)
		flash(player.global_position, BREATH_RADIUS, ICE)
	if power("armor_stare") > 0.0: push_from(player.global_position, STARE_RADIUS, STARE_PUSH)

func advance(delta: float) -> void:
	if active():
		armor_cooldown = maxf(armor_cooldown - delta, 0.0)
		for id in brittle.keys():
			brittle[id] = float(brittle[id]) - delta
			if brittle[id] <= 0.0 or not is_instance_valid(instance_from_id(id)): brittle.erase(id)
		_hold(delta)
		for index in range(walls.size() - 1, -1, -1):
			walls[index].time -= delta
			if walls[index].time <= 0.0:
				if power("skill_frostwave") > 0.0: _wave(walls[index])
				walls.remove_at(index)
	super.advance(delta)

func _draw() -> void:
	for wall in walls:
		var fade := clampf(float(wall.time), 0.0, 1.0)
		var a := to_local(wall.a)
		var b := to_local(wall.b)
		draw_line(a, b, Color(ICE.darkened(0.2), 0.45 * fade), WALL_HALF * 2.0, true)
		draw_line(a, b, Color(ICE.lightened(0.3), 0.9 * fade), 4.0, true)
		draw_circle(a, WALL_HALF, Color(ICE.darkened(0.2), 0.45 * fade))
		draw_circle(b, WALL_HALF, Color(ICE.darkened(0.2), 0.45 * fade))
	for id in brittle:
		var enemy := instance_from_id(id) as Enemy
		if is_instance_valid(enemy): draw_arc(to_local(enemy.global_position), enemy.data.radius + 6.0, 0.0, TAU, 20, Color(ICE, 0.85), 2.5, true)
	draw_effects()

func save_data() -> Dictionary:
	var saved_walls: Array = []
	for wall in walls: saved_walls.append({"a": SnapshotValues.vector_data(wall.a), "b": SnapshotValues.vector_data(wall.b), "time": float(wall.time)})
	return {"walls": saved_walls, "armor_cooldown": armor_cooldown}

func restore(saved: Dictionary) -> void:
	reset_wave()
	for wall in saved.get("walls", []):
		if wall is Dictionary and SnapshotValues.is_vector(wall.get("a")) and SnapshotValues.is_vector(wall.get("b")) and walls.size() < WALL_LIMIT:
			walls.append({"a": SnapshotValues.read_vector(wall.a), "b": SnapshotValues.read_vector(wall.b), "time": clampf(float(wall.get("time", 0)), 0.0, WALL_SECONDS * 3.0)})
	armor_cooldown = clampf(float(saved.get("armor_cooldown", 0.0)), 0.0, ARMOR_COOLDOWN)
