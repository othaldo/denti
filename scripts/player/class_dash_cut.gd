class_name ClassDashCut
extends Node2D

## Assassin verb "Giftschneise": every dash drags a poison lane behind Denti.
## Shortly after the dash it snaps (one hit + poison on every enemy on the
## line) and then stays as a visible poison field that keeps poisoning
## everything walking into it. Trail kills return capped root power.
## Trail damage is secondary damage without a weapon, so it never triggers
## weapon on-hit procs recursively; boss guards still apply via take_damage.

enum State { DRAW, ARMED, FIELD }

const PROC_ID := &"class_trail"
const SNAP_FLASH := 0.2
const MAX_SAVED := 8
const POISON := Color(0.43, 1.0, 0.3)
const THREAD_COLOR := Color(0.78, 1.0, 0.7, 0.9)
const FIELD_STYLE: SkillCloudStyle = preload("res://data/vfx/skill_clouds/poison_lane.tres")

var player: Player
var trails: Array[Dictionary] = []
var current: Dictionary = {}
var seconds := 0.0

func _ready() -> void:
	global_position = Vector2.ZERO
	# Enemy bodies use z 3: the poison lane is ground, readable but beneath them.
	z_index = 2

func rules() -> ClassCombatData:
	return player.class_combat.rules()

func enabled() -> bool:
	return player != null and rules().trail_enabled

func power(id: String) -> float:
	return player.class_combat.power(id)

func limit() -> int:
	return maxi(rules().trail_limit + roundi(power("trail_limit")), 1)

func width() -> float:
	return (rules().trail_width + power("trail_width")) * player.assassin_skills.width_factor()

func field_duration() -> float:
	# Blumentopf lengthens placed fields.
	return (rules().trail_field + power("trail_field")) * (1.0 + player.items.power(&"placed_duration"))

func refund_cap() -> float:
	return rules().trail_refund_cap + power("trail_refund_cap")

func refund_per_kill() -> float:
	return rules().trail_refund + power("trail_refund")

func reset_wave() -> void:
	trails.clear()
	current = {}
	queue_redraw()

func on_dash_started() -> void:
	if not enabled(): return
	release()
	current = {"a": player.global_position, "b": player.global_position, "state": State.DRAW, "time": 0.0, "tick": 0.0, "refund": 0.0, "hit": {}}
	trails.append(current)
	_trim()

func extend(end: Vector2) -> void:
	if current.is_empty(): return
	current.b = end
	queue_redraw()

func release() -> void:
	if current.is_empty(): return
	var trail := current
	current = {}
	if trail.a.distance_squared_to(trail.b) < 4.0:
		_remove(trail)
		return
	trail.state = State.ARMED
	trail.time = player.assassin_skills.snap_delay(rules().trail_delay)

func _remove(trail: Dictionary) -> void:
	for index in trails.size():
		if is_same(trails[index], trail):
			trails.remove_at(index)
			return

func _trim() -> void:
	while trails.size() > limit():
		var oldest := trails[0]
		if is_same(oldest, current): return
		trails.remove_at(0)

func advance(delta: float) -> void:
	if trails.is_empty(): return
	seconds += delta
	for index in range(trails.size() - 1, -1, -1):
		var trail := trails[index]
		if trail.state == State.ARMED:
			trail.time -= delta
			if trail.time <= 0.0:
				trail.state = State.FIELD
				trail.time = field_duration()
				trail.tick = rules().trail_field_interval
				_snap(trail)
		elif trail.state == State.FIELD:
			trail.time -= delta
			trail.tick -= delta
			if trail.tick <= 0.0 and trail.time > 0.0:
				trail.tick = rules().trail_field_interval
				_field_tick(trail)
			if trail.time <= 0.0:
				trails.remove_at(index)
	queue_redraw()

func _snap(trail: Dictionary) -> void:
	var cross := power("trail_cross")
	if cross > 0.0:
		for other in trails:
			if is_same(other, trail) or other.state == State.DRAW: continue
			var point: Variant = Geometry2D.segment_intersects_segment(trail.a, trail.b, other.a, other.b)
			if point == null: continue
			_cross_burst(point, cross)
			break
	var hits := 0
	for enemy in _enemies_in(trail):
		trail.hit[enemy.get_instance_id()] = true
		if _strike(enemy, 1.0, trail) > 0.0:
			hits += 1
			ElementImpactBatch.emit_from(enemy, &"poison", enemy.global_position, trail.a.direction_to(trail.b), 27)
			_pull(enemy, Geometry2D.get_closest_point_to_segment(enemy.global_position, trail.a, trail.b))
	if hits > 0:
		player.items.enchantment_support.emit(&"class_trail_hits", hits)

func _enemies_in(trail: Dictionary) -> Array[Enemy]:
	var result: Array[Enemy] = []
	var half := width() * 0.5
	for enemy in player.enemies_on_segment(trail.a, trail.b, half):
		if enemy.health <= 0.0: continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, trail.a, trail.b)
		if closest.distance_to(enemy.global_position) <= half + enemy.data.radius: result.append(enemy)
	return result

## Poison field: every enemy inside receives a share of the snap poison and,
## with Lähmende Schneise or a Nervensonde, the existing nerve slow.
func _field_tick(trail: Dictionary) -> void:
	var share := rules().trail_field_share
	var slows := power("trail_nerve") > 0.0 or player.items.power(&"poison_nerve") > 0.0
	var touched := 0
	for enemy in _enemies_in(trail):
		if not enemy.is_targetable() or enemy.data.is_boss and enemy.boss_phase_timer > 0: continue
		var additions: Array[Dictionary] = [{"id": "poison", "damage": poison_for(enemy) * share, "proc_id": str(PROC_ID)}]
		player.assassin_skills.mark(enemy)
		enemy.take_damage(0, null, false, PROC_ID, additions)
		touched += 1
		if slows and enemy.affix_effects.depot.nerve_lock <= 0:
			enemy.affix_effects.depot.nerve_time = PoisonDepotState.RULES.nerve_duration
			enemy.queue_redraw()
	if touched > 0:
		player.items.enchantment_support.emit(&"class_trail_field_ticks", touched)

func _cross_burst(at: Vector2, factor: float) -> void:
	for enemy in player.nearby_enemies(at, rules().trail_cross_radius):
		if enemy.health > 0.0:
			_strike(enemy, factor, null)
	ElementImpactBatch.emit_from(player, &"poison", at, Vector2.RIGHT, rules().trail_cross_radius, true)
	player.items.enchantment_support.emit(&"class_trail_crosses", 1)

func damage_for(enemy: Enemy, factor: float = 1.0) -> float:
	var r := rules()
	var items := player.items
	var base := (r.trail_damage + power("trail_damage") + maxf(player.stats.melee_damage, 0.0) * r.trail_melee_scaling) * factor * direct_factor()
	var bonus := items.base_weapon_damage_bonus() + items.power(&"moving_damage") * 100.0 * r.trail_sugar_factor
	if enemy.data.is_boss: bonus += items.power(&"boss_bonus") * 100.0
	return player.stats.scale_damage(base, bonus)

## Poison budget of one snap hit. Depotfüllung strengthens it (item lens).
func poison_for(_enemy: Enemy) -> float:
	var r := rules()
	var base := r.trail_poison + power("trail_poison") + maxf(player.stats.melee_damage, 0.0) * r.trail_poison_scaling
	base *= 1.0 + player.items.power(&"poison_depot") * r.trail_depot_factor
	return base * poison_factor() * player.stats.damage_factor()

## Keystone trade-offs: Giftschneise moves trail value from the hit into
## poison, Sprintfaden trades direct trail damage for cheaper dashes.
func direct_factor() -> float:
	var value := 1.0 - clampf(power("trail_weakness"), 0.0, 0.9)
	if power("trail_poison_focus") > 0.0: value *= 0.35
	return value

func poison_factor() -> float:
	return 2.5 if power("trail_poison_focus") > 0.0 else 1.0

func _strike(enemy: Enemy, factor: float, trail: Variant) -> float:
	var additions: Array[Dictionary] = [{"id": "poison", "damage": poison_for(enemy) * factor, "proc_id": str(PROC_ID)}]
	# Mark before the hit: a kill by this very strike already counts for Giftblüte.
	player.assassin_skills.mark(enemy)
	var dealt := enemy.take_damage(damage_for(enemy, factor), null, false, PROC_ID, additions)
	if dealt <= 0.0: return 0.0
	if enemy.health <= 0.0:
		player.items.enchantment_support.emit(&"class_trail_kills", 1)
		if trail is Dictionary: _refund(trail)
	return dealt

## Zuschnüren: survivors are drawn onto the line, bunching the horde for the next cut.
func _pull(enemy: Enemy, toward: Vector2) -> void:
	var pull := power("trail_pull")
	if pull <= 0.0 or enemy.health <= 0.0: return
	var offset := (toward - enemy.global_position).limit_length(pull)
	enemy.global_position += offset * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))

func _refund(trail: Dictionary) -> void:
	if power("trail_kill_reset") > 0.0: player.dash.cooldown = 0.0
	var gain := minf(refund_per_kill(), refund_cap() - float(trail.refund))
	if gain <= 0.0: return
	var before := player.dash.charge
	player.dash.charge = minf(player.dash.capacity, before + gain)
	trail.refund += gain
	if player.dash.charge > before:
		player.items.enchantment_support.emit(&"class_trail_refund", player.dash.charge - before)

func _draw() -> void:
	for trail in trails:
		var a := to_local(trail.a)
		var b := to_local(trail.b)
		if trail.state == State.DRAW:
			_lane(a, b, width() * 0.6, Color(POISON, 0.22), Color(POISON, 0.5))
			AttackEffects.strip(self, AttackEffects.Shape.THREAD, a, b, 8.0, THREAD_COLOR, seconds)
		elif trail.state == State.ARMED:
			var tension := 1.0 - clampf(float(trail.time) / maxf(rules().trail_delay, 0.001), 0.0, 1.0)
			_lane(a, b, width() * (0.6 + tension * 0.4), Color(POISON, 0.22 + tension * 0.12), Color(POISON, 0.6 + tension * 0.3))
			AttackEffects.strip(self, AttackEffects.Shape.THREAD, a, b, 8.0 + tension * 6.0, THREAD_COLOR, seconds)
		else:
			var total := maxf(field_duration(), 0.001)
			var age := total - float(trail.time)
			if age < SNAP_FLASH:
				AttackEffects.strip(self, AttackEffects.Shape.SLASH, a, b, width() * 1.2, Color(POISON.lightened(0.4), 1.0 - age / SNAP_FLASH), age)
			# The lane stays readable for its whole life and fades in the last second.
			# Kept translucent so enemy telegraphs and projectiles remain on top.
			var fade := clampf(float(trail.time), 0.0, 1.0)
			# A light fill and the rim keep the exact lane; gas billows on top.
			_lane(a, b, width(), Color(POISON.darkened(0.15), 0.16 * fade), Color(POISON, 0.75 * fade))
			SkillPuffs.draw_lane(self, a, b, width(), FIELD_STYLE, age, float(trail.time), SkillPuffs.seed_for(trail.a))

## Capsule-shaped lane: translucent fill plus a clear rim, readable on the floor.
func _lane(a: Vector2, b: Vector2, lane_width: float, fill: Color, rim: Color) -> void:
	var axis := b - a
	if axis.length_squared() < 1.0: return
	var radius := lane_width * 0.5
	var angle := axis.angle()
	var points := PackedVector2Array()
	for step in 9:
		points.append(b + Vector2.from_angle(angle - PI * 0.5 + PI * step / 8.0) * radius)
	for step in 9:
		points.append(a + Vector2.from_angle(angle + PI * 0.5 + PI * step / 8.0) * radius)
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, rim, 2.5, true)

func save_data(indices: Dictionary) -> Array:
	var result: Array = []
	for trail in trails:
		var hit: Array = []
		for id in trail.hit:
			if indices.has(id): hit.append(indices[id])
		result.append({"a": SnapshotValues.vector_data(trail.a), "b": SnapshotValues.vector_data(trail.b), "state": int(trail.state),
			"time": float(trail.time), "tick": float(trail.tick), "refund": float(trail.refund), "drawing": int(is_same(trail, current)), "hit": hit})
	return result

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() > MAX_SAVED: return false
	for entry in value:
		if not entry is Dictionary: return false
		for key in ["a", "b"]:
			var point: Variant = entry.get(key)
			if not point is Array or point.size() != 2: return false
			for axis in point:
				if not (axis is int or axis is float) or not is_finite(float(axis)): return false
		for key in ["state", "time", "tick", "refund", "drawing"]:
			var number: Variant = entry.get(key, 0)
			if not (number is int or number is float) or not is_finite(float(number)) or float(number) < 0: return false
		if int(entry.get("state", 0)) not in [State.DRAW, State.ARMED, State.FIELD]: return false
		if not entry.get("hit", []) is Array: return false
		for index in entry.get("hit", []):
			if not (index is int or index is float) or float(index) < 0: return false
	return true

func restore(saved: Variant, enemies: Array[Node]) -> void:
	reset_wave()
	if not enabled() or not valid(saved): return
	for entry in saved:
		var state := int(entry.get("state", State.ARMED))
		var trail := {"a": SnapshotValues.read_vector(entry.a), "b": SnapshotValues.read_vector(entry.b), "state": state,
			"time": clampf(float(entry.get("time", 0)), 0.0, maxf(rules().trail_delay, field_duration())),
			"tick": clampf(float(entry.get("tick", 0)), 0.0, rules().trail_field_interval),
			"refund": clampf(float(entry.get("refund", 0)), 0.0, refund_cap()), "hit": {}}
		for index_value in entry.get("hit", []):
			var index := int(index_value)
			if index < enemies.size() and is_instance_valid(enemies[index]): trail.hit[enemies[index].get_instance_id()] = true
		trails.append(trail)
		if state == State.DRAW:
			if bool(entry.get("drawing", 0)) and player.dash.active: current = trail
			else:
				trail.state = State.ARMED
				trail.time = rules().trail_delay
	_trim()
	queue_redraw()
