class_name RelicInventory
extends Node2D

signal feedback(message: String, at: Vector2, color: Color)

const BLOOD_RADIUS := 112.0
const TIDE_RADIUS := 138.0
const SUN_RADIUS := 86.0
const COMPASS_RANGE := 210.0
const HALO_DURATION := 4.0

@onready var player: Player = get_node("../Player")

var owned: Array[String] = []
var water_hits: int = 0
var critical_hits: int = 0
var moving_hits: int = 0
var halo_time: float = 0.0
var flashes: Array[Dictionary] = []


func _process(delta: float) -> void:
	halo_time = maxf(halo_time - delta, 0.0)
	var had_flashes := not flashes.is_empty()
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index]["life"] = float(flashes[index]["life"]) - delta
		if float(flashes[index]["life"]) <= 0.0:
			flashes.remove_at(index)
	if had_flashes:
		queue_redraw()


func _draw() -> void:
	for flash in flashes:
		var alpha := clampf(float(flash["life"]) / 0.3, 0.0, 1.0)
		if flash["kind"] == &"line":
			draw_line(flash["from"], flash["at"], Color(flash["color"] as Color, alpha), 4.0)
		else:
			CombatDrawCache.arc(self, flash["at"], float(flash["radius"]) * (1.0 - alpha * 0.2), 0.0, TAU, 36, Color(flash["color"] as Color, alpha), 4.0)


func has_relic(id: StringName) -> bool:
	return owned.has(str(id))


func acquire(id: StringName) -> bool:
	if RelicCatalog.by_id(id) == null or has_relic(id):
		return false
	owned.append(str(id))
	return true


func damage_factor() -> float:
	return 1.3 if has_relic(&"shattered_halo") and halo_time > 0.0 else 1.0


func on_wave_start() -> void:
	halo_time = 0.0


func on_shield_blocked() -> void:
	if not has_relic(&"shattered_halo"):
		return
	halo_time = HALO_DURATION
	_ring(player.global_position, 58.0, Color(1.0, 0.84, 0.35))
	feedback.emit("Heiligenschein!", player.global_position + Vector2(0.0, -35.0), Color(1.0, 0.84, 0.35))


func on_weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool) -> void:
	if has_relic(&"blood_moon_tooth") and enemy.health <= 0.0 and enemy.bleed_stacks > 0:
		_blood_burst(enemy, amount)
	if has_relic(&"tidal_seal") and weapon.damage_type == "Wasser":
		water_hits += 1
		if water_hits >= 5:
			water_hits = 0
			_tidal_wave(enemy, amount)
	if has_relic(&"sun_mark") and critical:
		critical_hits += 1
		if critical_hits >= 3:
			critical_hits = 0
			_area_damage(enemy.global_position, SUN_RADIUS, minf(amount * 0.45, 70.0), enemy, &"sun_mark")
			_ring(enemy.global_position, SUN_RADIUS, Color(1.0, 0.83, 0.35))
	if has_relic(&"pilgrim_compass") and player.is_moving:
		moving_hits += 1
		if moving_hits >= 6:
			moving_hits = 0
			var next := _nearest_other(enemy.global_position, enemy, COMPASS_RANGE)
			if next != null:
				next.take_damage(minf(amount * 0.55, 80.0), null, false, &"pilgrim_compass")
				_line(enemy.global_position, next.global_position, Color(0.27, 0.95, 0.98))


func _blood_burst(enemy: Enemy, amount: float) -> void:
	var at := enemy.global_position
	for other in player.nearby_enemies(at, BLOOD_RADIUS):
		if other == null or other == enemy or other.health <= 0.0 or at.distance_squared_to(other.global_position) > (BLOOD_RADIUS + other.data.radius) * (BLOOD_RADIUS + other.data.radius):
			continue
		other.apply_bleed(enemy.bleed_dps, 2.5, 3)
		other.take_damage(minf(amount * 0.5, 75.0), null, false, &"blood_moon_tooth")
	_ring(at, BLOOD_RADIUS, Color(0.95, 0.25, 0.39))


func _tidal_wave(enemy: Enemy, amount: float) -> void:
	var at := enemy.global_position
	for other in player.nearby_enemies(at, TIDE_RADIUS):
		if other == null or other == enemy or other.health <= 0.0 or at.distance_squared_to(other.global_position) > (TIDE_RADIUS + other.data.radius) * (TIDE_RADIUS + other.data.radius):
			continue
		other.apply_wet(3.0)
		other.take_damage(minf(amount * 0.55, 75.0), null, false, &"tidal_seal")
	_ring(at, TIDE_RADIUS, Color(0.28, 0.94, 1.0))


func _area_damage(at: Vector2, radius: float, amount: float, excluded: Enemy, proc_id: StringName) -> void:
	for other in player.nearby_enemies(at, radius):
		if other != null and other != excluded and other.health > 0.0 and at.distance_squared_to(other.global_position) <= (radius + other.data.radius) * (radius + other.data.radius):
			other.take_damage(amount, null, false, proc_id)


func _nearest_other(at: Vector2, excluded: Enemy, radius: float) -> Enemy:
	var nearest: Enemy = null
	var distance := radius * radius
	for other in player.nearby_enemies(at, radius, false):
		if other == null or other == excluded or other.health <= 0.0:
			continue
		var candidate := at.distance_squared_to(other.global_position)
		if candidate < distance:
			distance = candidate
			nearest = other
	return nearest


func _ring(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"kind": &"ring", "at": at, "radius": radius, "color": color, "life": 0.3})
	queue_redraw()


func _line(from: Vector2, to: Vector2, color: Color) -> void:
	flashes.append({"kind": &"line", "from": from, "at": to, "color": color, "life": 0.3})
	queue_redraw()


func save_data() -> Dictionary:
	return {"owned": owned.duplicate(), "water_hits": water_hits, "critical_hits": critical_hits,
		"moving_hits": moving_hits, "halo_time": halo_time}


func restore(saved: Dictionary) -> void:
	owned.clear()
	for value in saved.get("owned", []):
		var id := StringName(str(value))
		if RelicCatalog.by_id(id) != null and not has_relic(id):
			owned.append(str(id))
	water_hits = clampi(int(saved.get("water_hits", 0)), 0, 4)
	critical_hits = clampi(int(saved.get("critical_hits", 0)), 0, 2)
	moving_hits = clampi(int(saved.get("moving_hits", 0)), 0, 5)
	halo_time = clampf(float(saved.get("halo_time", 0.0)), 0.0, HALO_DURATION)
	flashes.clear()
