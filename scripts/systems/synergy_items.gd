class_name SynergyItems
extends Node2D
## Run-time effects of the synergy items (docs/ITEM_SYNERGY_EXPANSION.md) that
## need their own state: wild sage sprouts (Taschenbeet), dash traps
## (Zahnseidenfalle), dash volley and damage window (Nachhall-Krone,
## Rutschwachs), mint leaf drops and bursts (Minzbeet, Scharfe Zahnpasta,
## Kompost) and the summon proximity bonus (Wurzelnetz). Passive multipliers
## (Blumentopf, Dünger, Katalysator, Thermoskanne, Gewitterwolke) live where the
## affected mechanic is computed and read `items.power()` directly.

# Taschenbeet
const SPROUT_KILLS := 12
const SPROUT_KILLS_PER_COPY := 2
const SPROUT_MIN_KILLS := 4
const SPROUT_SECONDS := 6.0
const SPROUT_SHOT := 0.8
const SPROUT_RANGE := 240.0
const SPROUT_BASE := 8.0
const SPROUT_RANGED := 1.0
const SPROUT_LIMIT := 6
const SPROUT_SPREAD := 50.0
# Zahnseidenfalle
const TRAP_SECONDS := 8.0
const TRAP_TRIGGER := 34.0
const TRAP_RADIUS := 80.0
const TRAPS_PER_COPY := 3
# Nachhall-Krone and Rutschwachs
const VOLLEY_COOLDOWN := 4.0
const SLIDE_SECONDS := 0.5
# Minzblätter
const MINT_KILLS := 30
const MINT_KILLS_PER_COPY := 5
const MINT_MIN_KILLS := 10
const MINT_HEAL := 4
const MINT_BURST_RADIUS := 110.0
const MINT_BURST_BASE := 10.0
const MINT_BURST_HEALTH := 0.1
# Wurzelnetz
const NET_RADIUS := 220.0
const NET_CAP := 30.0
const NET_REFRESH := 0.25

const SAGE := Color(0.55, 0.85, 0.45)
const FLOSS := Color(0.95, 0.95, 1.0)
const MINT := Color(0.55, 1.0, 0.7)

@onready var items: ItemInventory = get_node("../Items")
@onready var player: Player = get_node("../Player")

var sprouts: Array[Dictionary] = []
var sprout_kills := 0
var traps: Array[Dictionary] = []
var volley_cooldown := 0.0
var slide_time := 0.0
var mint_kills := 0
var net_count := 0
var net_refresh := 0.0
var flashes: Array[Dictionary] = []
var plant_art: Texture2D


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 2
	if ResourceLoader.exists(HerbSkills.PLANTS_PATH): plant_art = load(HerbSkills.PLANTS_PATH)


func reset_wave() -> void:
	sprouts.clear()
	traps.clear()
	volley_cooldown = 0.0
	slide_time = 0.0
	sprout_kills = 0
	mint_kills = 0
	net_count = 0
	flashes.clear()
	queue_redraw()


# --- Hooks ----------------------------------------------------------------------

func on_kill(at: Vector2, data: EnemyData) -> void:
	if items.power(&"wild_sprout") > 0.0:
		sprout_kills += 1
		var needed := maxi(SPROUT_MIN_KILLS, SPROUT_KILLS - SPROUT_KILLS_PER_COPY * roundi(items.power(&"wild_sprout")))
		if sprout_kills >= needed:
			sprout_kills = 0
			_grow_sprout()
	if items.power(&"mint_drops") > 0.0 and not data.is_boss:
		mint_kills += 1
		var needed := maxi(MINT_MIN_KILLS, MINT_KILLS - MINT_KILLS_PER_COPY * roundi(items.power(&"mint_drops")))
		if data.is_elite or mint_kills >= needed:
			if not data.is_elite: mint_kills = 0
			drop_mint(at)


func on_dash_started() -> void:
	var damage := items.power(&"dash_trap")
	if damage <= 0.0: return
	traps.append({"at": player.global_position, "time": TRAP_SECONDS, "damage": damage})
	var limit := TRAPS_PER_COPY * roundi(damage / 14.0)
	while traps.size() > maxi(limit, TRAPS_PER_COPY): traps.pop_front()


func on_dash_ended() -> void:
	if items.power(&"dash_damage") > 0.0: slide_time = SLIDE_SECONDS
	if items.power(&"dash_volley") > 0.0 and volley_cooldown <= 0.0 and player.combat_active():
		var attacked := false
		for weapon in player.loadout.equipped(): attacked = weapon.force_attack(0.0) or attacked
		if attacked:
			volley_cooldown = VOLLEY_COOLDOWN
			_flash(player.global_position, 70.0, Color(1.0, 0.84, 0.35))


## Minzblatt picked up: heal, and Scharfe Zahnpasta bursts around Denti.
func on_mint_collected(amount: int) -> void:
	player.stats.heal(float(amount))
	var copies := items.power(&"mint_burst")
	if copies <= 0.0: return
	var damage := player.stats.scale_damage((MINT_BURST_BASE + MINT_BURST_HEALTH * player.stats.max_health) * copies)
	for enemy in player.nearby_enemies(player.global_position, MINT_BURST_RADIUS):
		if enemy.is_targetable(): enemy.take_damage(damage, null, false, &"spicy_paste")
	_flash(player.global_position, MINT_BURST_RADIUS, Color(1.0, 0.45, 0.3))


## Kompost: a wilting herb or fallen tooth may drop a mint leaf.
func on_summon_lost(at: Vector2) -> void:
	var chance := items.power(&"summon_mint")
	if chance > 0.0 and randf() < chance: drop_mint(at)


func drop_mint(at: Vector2) -> void:
	var game := get_parent()
	if game.has_method("_spawn_loot"): game._spawn_loot(at, &"mint", MINT_HEAL)


## Extra weapon damage in percent points (Rutschwachs, Wurzelnetz).
func weapon_damage_bonus() -> float:
	var bonus := 0.0
	if slide_time > 0.0: bonus += items.power(&"dash_damage") * 100.0
	var net := items.power(&"summon_proximity")
	if net > 0.0: bonus += minf(net_count * net * 100.0, NET_CAP)
	return bonus


## Dünger: summon damage and endurance factors.
func summon_damage_factor() -> float:
	return 1.0 + items.power(&"summon_power")

func summon_health_factor() -> float:
	return 1.0 + 2.0 * items.power(&"summon_power")


## Blumentopf: duration factor for placed things.
func placed_duration_factor() -> float:
	return 1.0 + items.power(&"placed_duration")


# --- Frame ------------------------------------------------------------------------

func _process(delta: float) -> void:
	volley_cooldown = maxf(volley_cooldown - delta, 0.0)
	slide_time = maxf(slide_time - delta, 0.0)
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index].time = float(flashes[index].time) - delta
		if flashes[index].time <= 0.0: flashes.remove_at(index)
	if player == null or not player.combat_active():
		if not flashes.is_empty() or not sprouts.is_empty() or not traps.is_empty(): queue_redraw()
		return
	_advance_sprouts(delta)
	_advance_traps(delta)
	if items.power(&"summon_proximity") > 0.0:
		net_refresh -= delta
		if net_refresh <= 0.0:
			net_refresh = NET_REFRESH
			net_count = _summons_near()
	queue_redraw()


func _grow_sprout() -> void:
	var at := player.global_position + Vector2.from_angle(randf() * TAU) * randf_range(SPROUT_SPREAD * 0.4, SPROUT_SPREAD)
	sprouts.append({"at": at, "time": SPROUT_SECONDS, "shot": 0.2})
	while sprouts.size() > SPROUT_LIMIT: sprouts.pop_front()
	_flash(at, 24.0, SAGE)


func _advance_sprouts(delta: float) -> void:
	for index in range(sprouts.size() - 1, -1, -1):
		var sprout := sprouts[index]
		sprout.time = float(sprout.time) - delta
		if sprout.time <= 0.0:
			sprouts.remove_at(index)
			on_summon_lost(sprout.at)
			continue
		sprout.shot = float(sprout.shot) - delta
		if sprout.shot > 0.0: continue
		var target := EnemySpatialIndex.nearest(get_tree(), player.enemy_index, sprout.at, SPROUT_RANGE, true, null, player.global_position)
		if target == null or target.global_position.distance_to(sprout.at) > SPROUT_RANGE + target.data.radius:
			sprout.shot = 0.15
			continue
		sprout.shot = SPROUT_SHOT
		var damage := player.stats.scale_damage((SPROUT_BASE + SPROUT_RANGED * maxf(player.stats.ranged_damage, 0.0)) * summon_damage_factor())
		target.take_damage(damage, null, false, &"pocket_bed")
		_beam(sprout.at + Vector2(0, -30), target.global_position)


func _advance_traps(delta: float) -> void:
	for index in range(traps.size() - 1, -1, -1):
		var trap := traps[index]
		trap.time = float(trap.time) - delta
		var sprung := false
		for enemy in player.nearby_enemies(trap.at, TRAP_TRIGGER):
			if enemy.is_targetable():
				sprung = true
				break
		if sprung:
			var damage := player.stats.scale_damage(float(trap.damage))
			for enemy in player.nearby_enemies(trap.at, TRAP_RADIUS):
				if enemy.is_targetable(): enemy.take_damage(damage, null, false, &"floss_trap")
			_flash(trap.at, TRAP_RADIUS, FLOSS)
			traps.remove_at(index)
		elif trap.time <= 0.0:
			traps.remove_at(index)


func _summons_near() -> int:
	var count := 0
	var at := player.global_position
	var herbs := HerbSkills.for_player(player)
	if herbs != null and herbs.active():
		for entry in herbs.plants:
			if herbs.grown(entry) and at.distance_squared_to(entry.at) <= NET_RADIUS * NET_RADIUS: count += 1
	var necro := NecrodentSkills.for_player(player)
	if necro != null and necro.active():
		count += necro.standing_near(at, NET_RADIUS)
	for sprout in sprouts:
		if at.distance_squared_to(sprout.at) <= NET_RADIUS * NET_RADIUS: count += 1
	return count


# --- Drawing ----------------------------------------------------------------------

func _flash(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"at": at, "radius": radius, "color": color, "time": 0.3, "kind": &"ring"})
	if flashes.size() > 16: flashes.pop_front()


func _beam(from: Vector2, to: Vector2) -> void:
	flashes.append({"at": from, "to": to, "color": SAGE, "time": 0.15, "kind": &"line"})
	if flashes.size() > 16: flashes.pop_front()


func _draw() -> void:
	for sprout in sprouts:
		var at := to_local(sprout.at)
		var fade := clampf(float(sprout.time), 0.0, 1.0)
		if plant_art != null:
			var cell := Vector2(plant_art.get_size()) / Vector2(4, 2)
			var size := Vector2.ONE * 46.0
			draw_texture_rect_region(plant_art, Rect2(at - Vector2(size.x * 0.5, size.y * 0.85), size), Rect2(Vector2.ZERO, cell), Color(1, 1, 1, fade))
		else:
			draw_circle(at + Vector2(0, -14), 9.0, Color(SAGE, fade))
	for trap in traps:
		var at := to_local(trap.at)
		draw_arc(at, 10.0, 0.0, TAU, 16, Color(FLOSS, 0.85), 2.0, true)
		draw_line(at + Vector2(-10, 0), at + Vector2(10, 0), Color(1.0, 0.35, 0.3, 0.9), 2.0, true)
	for flash in flashes:
		var alpha := clampf(float(flash.time) / 0.3, 0.0, 1.0)
		if flash.kind == &"line":
			draw_line(to_local(flash.at), to_local(flash.to), Color(flash.color, alpha), 2.5, true)
		else:
			draw_arc(to_local(flash.at), float(flash.radius) * (1.2 - alpha * 0.2), 0.0, TAU, 32, Color(flash.color, alpha), 3.0, true)
