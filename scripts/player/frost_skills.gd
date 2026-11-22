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
## Frostwelle splinters: the expiring wall bursts into ice shards flying out
## to both sides. Each shard pierces once, chills and makes its targets brittle.
const SHARD_SPACING := 28.0
const SHARD_MIN := 6
const SHARD_MAX := 14
const SHARD_SPEED := 380.0
const SHARD_RANGE := 170.0
const SHARD_HITS := 2
const SHARD_RADIUS := 8.0
const SHARD_SPREAD := 0.45
const SHARD_LIMIT := 64
const ARMOR_COOLDOWN := 8.0
const ARMOR_FAST := 5.0
const BREATH_RADIUS := 150.0
const STARE_RADIUS := 120.0
const STARE_PUSH := 60.0
## Gletscherherz: a boss breaking a wall is slowed and takes more damage.
const GLACIER_SECONDS := 3.0
const GLACIER_BONUS := 20.0
const GLACIER_COOLDOWN := 6.0
## Eisblume: a brittle enemy dying passes brittleness to its neighbours.
const FLOWER_RADIUS := 100.0
const FLOWER_TARGETS := 4
const ICE := Color(0.7, 0.92, 1.0)
const WALL_STYLE: SkillCloudStyle = preload("res://data/vfx/skill_clouds/frost.tres")

var walls: Array[Dictionary] = []
var dash_start := Vector2.ZERO
var contact: Dictionary = {}
var brittle: Dictionary = {}
var armor_cooldown := 0.0
var spike_tick := 0.0
var shards: Array[Dictionary] = []
var glacier_cooldown := 0.0
## Boss instance id -> remaining Gletscherherz seconds.
var glacier: Dictionary = {}

func class_id() -> StringName:
	return &"frost_warden"

func reset_wave() -> void:
	super.reset_wave()
	walls.clear()
	contact.clear()
	brittle.clear()
	armor_cooldown = 0.0
	spike_tick = 0.0
	shards.clear()
	glacier_cooldown = 0.0
	glacier.clear()

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
				_glacier(enemy)
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

func _glacier(boss: Enemy) -> void:
	if not relic(&"frost_glacier_heart") or glacier_cooldown > 0.0: return
	glacier_cooldown = GLACIER_COOLDOWN
	boss.chill_time = maxf(boss.chill_time, GLACIER_SECONDS)
	glacier[boss.get_instance_id()] = GLACIER_SECONDS
	flash(boss.global_position, boss.data.radius + 40.0, ICE)
	ElementImpactBatch.emit_from(player, &"ice", boss.global_position, Vector2.RIGHT, boss.data.radius + 30.0, true)

func damage_bonus(enemy: Enemy, _weapon: WeaponData) -> float:
	return GLACIER_BONUS if active() and glacier.has(enemy.get_instance_id()) else 0.0

func on_enemy_died(enemy: Enemy) -> void:
	if not active() or not relic(&"frost_ice_flower"): return
	var id := enemy.get_instance_id()
	if not brittle.has(id): return
	brittle.erase(id)
	var spread := 0
	for other in player.nearby_enemies(enemy.global_position, FLOWER_RADIUS):
		if spread >= FLOWER_TARGETS: break
		if other == enemy or not other.is_targetable() or other.data.is_boss or brittle.has(other.get_instance_id()): continue
		brittle[other.get_instance_id()] = BRITTLE_SECONDS
		other.chill_time = maxf(other.chill_time, CHILL_SECONDS)
		beam(enemy.global_position, other.global_position, ICE, 2.0)
		spread += 1
	if spread > 0: flash(enemy.global_position, FLOWER_RADIUS * 0.6, ICE)

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

## Frostwelle: an expiring wall bursts into ice shards on both sides.
func _wave(wall: Dictionary) -> void:
	var amount := scaled(WAVE_BASE + maxf(player.stats.melee_damage, 0.0) * WAVE_MELEE)
	var a: Vector2 = wall.a
	var b: Vector2 = wall.b
	var count := clampi(roundi(a.distance_to(b) / SHARD_SPACING), SHARD_MIN, SHARD_MAX)
	if power("wave_avalanche") > 0.0: count *= 2
	var normal := (b - a).orthogonal().normalized()
	if normal.is_zero_approx(): normal = Vector2.UP
	for index in count:
		var side := 1.0 if index % 2 == 0 else -1.0
		var at := a.lerp(b, (float(index) + 0.5) / float(count))
		var direction := (normal * side).rotated(randf_range(-SHARD_SPREAD, SHARD_SPREAD))
		shards.append({"at": at, "dir": direction, "left": SHARD_RANGE, "damage": amount, "hits": SHARD_HITS, "hit": {}})
	while shards.size() > SHARD_LIMIT: shards.pop_front()
	flash(a.lerp(b, 0.5), a.distance_to(b) * 0.25 + 20.0, ICE)
	support(&"class_frost_waves")

func _advance_shards(delta: float) -> void:
	var after := BRITTLE_FAST if power("frost_bite") > 0.0 else BRITTLE_AFTER
	for index in range(shards.size() - 1, -1, -1):
		var shard := shards[index]
		var step := minf(SHARD_SPEED * delta, float(shard.left))
		var from: Vector2 = shard.at
		shard.at = from + shard.dir * step
		shard.left = float(shard.left) - step
		for enemy in player.enemies_on_segment(from, shard.at, SHARD_RADIUS):
			if int(shard.hits) <= 0: break
			var id := enemy.get_instance_id()
			if shard.hit.has(id) or not enemy.is_targetable(): continue
			shard.hit[id] = true
			shard.hits = int(shard.hits) - 1
			enemy.take_damage(float(shard.damage), null, false, &"class_frost")
			enemy.chill_time = maxf(enemy.chill_time, CHILL_SECONDS * 2.0)
			if enemy.health > 0.0 and not enemy.data.is_boss: brittle[id] = BRITTLE_SECONDS
			contact[id] = maxf(float(contact.get(id, 0.0)), after)
		if int(shard.hits) <= 0 or float(shard.left) <= 0.0:
			if int(shard.hits) <= 0: ElementImpactBatch.emit_from(player, &"ice", shard.at, shard.dir, 18.0, false)
			shards.remove_at(index)

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
		glacier_cooldown = maxf(glacier_cooldown - delta, 0.0)
		for id in glacier.keys():
			glacier[id] = float(glacier[id]) - delta
			if glacier[id] <= 0.0: glacier.erase(id)
		for id in brittle.keys():
			brittle[id] = float(brittle[id]) - delta
			if brittle[id] <= 0.0 or not is_instance_valid(instance_from_id(id)): brittle.erase(id)
		_hold(delta)
		for index in range(walls.size() - 1, -1, -1):
			walls[index].time -= delta
			if walls[index].time <= 0.0:
				if power("skill_frostwave") > 0.0: _wave(walls[index])
				walls.remove_at(index)
		_advance_shards(delta)
	super.advance(delta)

func _draw() -> void:
	for wall in walls:
		var fade := clampf(float(wall.time), 0.0, 1.0)
		var a := to_local(wall.a)
		var b := to_local(wall.b)
		# Icy mist on the wall; the crisp line keeps its exact position readable.
		var remaining := float(wall.time)
		SkillPuffs.draw_lane(self, a, b, WALL_HALF * 2.0, WALL_STYLE, maxf(wall_seconds() - remaining, 0.0), remaining, SkillPuffs.seed_for(wall.a))
		draw_line(a, b, Color(ICE.lightened(0.3), 0.9 * fade), 4.0, true)
	for id in brittle:
		var enemy := instance_from_id(id) as Enemy
		if is_instance_valid(enemy): draw_arc(to_local(enemy.global_position), enemy.data.radius + 6.0, 0.0, TAU, 20, Color(ICE, 0.85), 2.5, true)
	for shard in shards:
		var tip := to_local(shard.at)
		var dir: Vector2 = shard.dir
		var side := dir.orthogonal() * 3.5
		var fade := clampf(float(shard.left) / 40.0, 0.0, 1.0)
		draw_line(tip - dir * 22.0, tip - dir * 6.0, Color(ICE, 0.35 * fade), 3.0, true)
		draw_colored_polygon(PackedVector2Array([tip + dir * 7.0, tip + side, tip - dir * 9.0, tip - side]), Color(ICE.lightened(0.35), 0.95 * fade))
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
