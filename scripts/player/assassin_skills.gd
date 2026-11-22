class_name AssassinSkills
extends Node2D

## The Assassin's branch skills, built on top of the Giftschneise verb:
##
## * Giftblüte (Giftspur): enemies that die shortly after the lane poisoned
##   them burst into a poison cloud.
## * Rausch (Zuckerrausch): three dashes in quick succession start a sugar
##   rush with free dashes and wider lanes, followed by a sugar crash.
## * Durchflutschen (Zahnpflege): dashes shatter enemy projectiles on their
##   path; the first one per dash grants a shield.
##
## Powers come from ClassCombatEffects. Clouds only re-mark enemies with
## Kettenblüte, and their count is capped, so they cannot cascade endlessly.

const MARK_SECONDS := 6.0
const CLOUD_RADIUS := 60.0
const CLOUD_DENSE_RADIUS := 25.0
const CLOUD_SECONDS := 2.5
const CLOUD_DENSE_SECONDS := 1.5
const CLOUD_INTERVAL := 0.5
const CLOUD_SHARE := 0.25
const CLOUD_BURST_SHARE := 0.5
const CLOUD_LIMIT := 6
const RUSH_WINDOW := 4.0
const RUSH_DASHES := 3
const RUSH_SECONDS := 4.0
const RUSH_HYPER_SECONDS := 1.5
const RUSH_WIDTH := 1.4
const RUSH_GLAZE_DELAY := 0.05
const CRASH_SECONDS := 2.0
const CRASH_FACTOR := 0.75
const SLIP_RADIUS := 30.0
const SLIP_FEATHER := 1.6
const SLIP_SHIELD_COOLDOWN := 6.0
const SLIP_POLISH_COOLDOWN := 3.5
const SLIP_HEAL_CAP := 4
const SLIP_MIRROR_RANGE := 320.0
const SLIP_MIRROR_FACTOR := 0.5
const FLASH_SECONDS := 0.4
## Mitternachtsklinge: the first weapon hit after a dash spreads the target's poison.
const BLADE_WINDOW := 2.5
const BLADE_SHARE := 0.5
const BLADE_TARGETS := 4
const BLADE_RADIUS := 110.0
## Cap per neighbour, in snap-poison budgets, so huge depots cannot multiply.
const BLADE_CAP := 3.0
## Nachtschatten: weapon damage bonus on enemies inside a poison field.
const NIGHTSHADE_BONUS := 20.0
const RUSH_COLOR := Color(1.0, 0.55, 0.78)
const CLOUD_STYLE: SkillCloudStyle = preload("res://data/vfx/skill_clouds/poison.tres")

var player: Player
var marks: Dictionary = {}
var clouds: Array[Dictionary] = []
var dash_times: Array[float] = []
var clock := 0.0
var rush_time := 0.0
var crash_time := 0.0
var slip_cooldown := 0.0
var slip_heals := 0
var slip_shielded := false
var flashes: Array[Dictionary] = []
var blade_time := 0.0
## Enemy instance id -> remaining Nachtschatten seconds.
var nightshade: Dictionary = {}

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 2

func power(id: String) -> float:
	return player.class_combat.power(id) if player != null else 0.0

func reset_wave() -> void:
	marks.clear()
	clouds.clear()
	dash_times.clear()
	rush_time = 0.0
	crash_time = 0.0
	slip_cooldown = 0.0
	slip_heals = 0
	slip_shielded = false
	blade_time = 0.0
	nightshade.clear()
	flashes.clear()
	if player != null: player.dash.free_dashes = false
	queue_redraw()

# --- Giftblüte --------------------------------------------------------------

## The lane (or a chaining cloud) poisoned this enemy recently.
func mark(enemy: Enemy) -> void:
	if power("skill_bloom") > 0.0: marks[enemy.get_instance_id()] = MARK_SECONDS

func on_enemy_died(enemy: Enemy, _amount: float) -> void:
	var id := enemy.get_instance_id()
	if not marks.has(id): return
	marks.erase(id)
	if power("skill_bloom") <= 0.0: return
	_bloom(enemy.global_position)

func cloud_radius() -> float:
	return CLOUD_RADIUS + (CLOUD_DENSE_RADIUS if power("bloom_dense") > 0.0 else 0.0)

func cloud_seconds() -> float:
	return CLOUD_SECONDS + (CLOUD_DENSE_SECONDS if power("bloom_dense") > 0.0 else 0.0)

func _bloom(at: Vector2) -> void:
	clouds.append({"at": at, "time": cloud_seconds(), "tick": 0.0})
	while clouds.size() > CLOUD_LIMIT: clouds.pop_front()
	if power("bloom_burst") > 0.0:
		for enemy in player.nearby_enemies(at, cloud_radius()):
			if enemy.health > 0.0: enemy.take_damage(player.dash_cut.damage_for(enemy, CLOUD_BURST_SHARE), null, false, &"class_bloom")
	ElementImpactBatch.emit_from(player, &"poison", at, Vector2.RIGHT, cloud_radius(), true)
	player.items.enchantment_support.emit(&"class_blooms", 1)

func _cloud_tick(cloud: Dictionary) -> void:
	var chain := power("bloom_chain") > 0.0
	for enemy in player.nearby_enemies(cloud.at, cloud_radius()):
		if not enemy.is_targetable() or enemy.data.is_boss and enemy.boss_phase_timer > 0: continue
		var additions: Array[Dictionary] = [{"id": "poison", "damage": player.dash_cut.poison_for(enemy) * CLOUD_SHARE, "proc_id": "class_bloom"}]
		if chain: mark(enemy)
		enemy.take_damage(0, null, false, &"class_bloom", additions)

# --- Rausch ------------------------------------------------------------------

func on_dash() -> void:
	if power("skill_rush") <= 0.0 or rush_time > 0.0: return
	dash_times.append(clock)
	while not dash_times.is_empty() and clock - dash_times[0] > RUSH_WINDOW: dash_times.pop_front()
	var needed := RUSH_DASHES - (1 if power("rush_hyper") > 0.0 else 0)
	if dash_times.size() >= needed:
		dash_times.clear()
		rush_time = RUSH_SECONDS + (RUSH_HYPER_SECONDS if power("rush_hyper") > 0.0 else 0.0)
		crash_time = 0.0
		player.dash.free_dashes = true
		_flash(player.global_position, 90.0, RUSH_COLOR)
		player.items.enchantment_support.emit(&"class_rushes", 1)

func rushing() -> bool:
	return rush_time > 0.0

func width_factor() -> float:
	return RUSH_WIDTH if rushing() else 1.0

## Zuckerguss: lanes snap almost at once during the rush.
func snap_delay(base: float) -> float:
	return RUSH_GLAZE_DELAY if rushing() and power("rush_glaze") > 0.0 else base

## Sugar crash after the rush unless Kein Kater.
func move_factor() -> float:
	return CRASH_FACTOR if crash_time > 0.0 else 1.0

# --- Durchflutschen ------------------------------------------------------------

func slip_radius() -> float:
	return SLIP_RADIUS * (SLIP_FEATHER if power("slip_feather") > 0.0 else 1.0)

func on_dash_started() -> void:
	slip_heals = 0
	slip_shielded = false
	if relic(&"assassin_midnight_blade"): blade_time = BLADE_WINDOW

func relic(id: StringName) -> bool:
	return player.stats.class_data.id == &"assassin" and player.has_class_relic(id)

# --- Class relics ------------------------------------------------------------

func expose(enemy: Enemy, seconds: float) -> void:
	nightshade[enemy.get_instance_id()] = seconds

func damage_bonus(enemy: Enemy, _weapon: WeaponData) -> float:
	return NIGHTSHADE_BONUS if nightshade.has(enemy.get_instance_id()) and relic(&"assassin_nightshade") else 0.0

func on_weapon_hit(enemy: Enemy, weapon: WeaponData, dealt: float) -> void:
	if blade_time <= 0.0 or weapon == null or dealt <= 0.0: return
	blade_time = 0.0
	var poison := enemy.affix_effects.budget(&"poison") + enemy.affix_effects.depot.budget()
	if poison <= 0.0: return
	var spread := 0
	for other in player.nearby_enemies(enemy.global_position, BLADE_RADIUS):
		if spread >= BLADE_TARGETS: break
		if other == enemy or not other.is_targetable(): continue
		var amount := minf(poison * BLADE_SHARE, player.dash_cut.poison_for(other) * BLADE_CAP)
		var additions: Array[Dictionary] = [{"id": "poison", "damage": amount, "proc_id": "assassin_midnight_blade"}]
		other.take_damage(0, null, false, &"assassin_midnight_blade", additions)
		spread += 1
	if spread > 0:
		_flash(enemy.global_position, BLADE_RADIUS, DentiUIStyle.MINT)
		ElementImpactBatch.emit_from(player, &"poison", enemy.global_position, Vector2.RIGHT, BLADE_RADIUS, true)

## Called after each dash motion step with the swept segment.
func sweep(start: Vector2, end: Vector2) -> void:
	if power("skill_slip") <= 0.0: return
	var projectiles := player.get_parent().get_node_or_null("EnemyProjectiles")
	if projectiles == null: return
	var radius := slip_radius()
	for projectile in projectiles.get_children():
		if not projectile is AcidProjectile or not projectile.is_physics_processing(): continue
		var closest := Geometry2D.get_closest_point_to_segment(projectile.global_position, start, end)
		if closest.distance_squared_to(projectile.global_position) > radius * radius: continue
		var at: Vector2 = projectile.global_position
		projectile.shatter()
		_slipped(at)

func _slipped(at: Vector2) -> void:
	player.items.enchantment_support.emit(&"class_slips", 1)
	_flash(at, 26.0, DentiUIStyle.MINT)
	if not slip_shielded and slip_cooldown <= 0.0:
		slip_shielded = true
		slip_cooldown = SLIP_POLISH_COOLDOWN if power("slip_polish") > 0.0 else SLIP_SHIELD_COOLDOWN
		player.stats.grant_shield(1)
	if power("slip_heal") > 0.0 and slip_heals < SLIP_HEAL_CAP:
		slip_heals += 1
		player.stats.heal(1.0)
	if power("slip_mirror") > 0.0:
		var target := EnemySpatialIndex.nearest(get_tree(), player.enemy_index, at, SLIP_MIRROR_RANGE, true)
		if target != null:
			player.dash_cut._strike(target, SLIP_MIRROR_FACTOR, null)
			ElementImpactBatch.emit_from(target, &"poison", target.global_position, at.direction_to(target.global_position), 27)

# --- Shared --------------------------------------------------------------------

func advance(delta: float) -> void:
	clock += delta
	slip_cooldown = maxf(slip_cooldown - delta, 0.0)
	blade_time = maxf(blade_time - delta, 0.0)
	for id in nightshade.keys():
		nightshade[id] = float(nightshade[id]) - delta
		if nightshade[id] <= 0.0: nightshade.erase(id)
	for id in marks.keys():
		marks[id] = float(marks[id]) - delta
		if marks[id] <= 0.0: marks.erase(id)
	if rush_time > 0.0:
		rush_time = maxf(rush_time - delta, 0.0)
		if rush_time <= 0.0:
			player.dash.free_dashes = false
			if power("rush_nocrash") <= 0.0: crash_time = CRASH_SECONDS
	elif crash_time > 0.0:
		crash_time = maxf(crash_time - delta, 0.0)
	for index in range(clouds.size() - 1, -1, -1):
		var cloud := clouds[index]
		cloud.time -= delta
		cloud.tick -= delta
		if cloud.tick <= 0.0 and cloud.time > 0.0:
			cloud.tick = CLOUD_INTERVAL
			_cloud_tick(cloud)
		if cloud.time <= 0.0: clouds.remove_at(index)
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index].time -= delta
		if flashes[index].time <= 0.0: flashes.remove_at(index)
	queue_redraw()

func _flash(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"at": at, "radius": radius, "color": color, "time": FLASH_SECONDS})
	if flashes.size() > 16: flashes.pop_front()

func _draw() -> void:
	for cloud in clouds:
		# Age follows from the remaining time, so saved clouds resume seamlessly.
		var remaining := float(cloud.time)
		var age := maxf(cloud_seconds() - remaining, 0.0)
		SkillPuffs.draw_cloud(self, to_local(cloud.at), cloud_radius(), CLOUD_STYLE, age, remaining, SkillPuffs.seed_for(cloud.at))
	if rushing() and player != null:
		# A pink sugar halo around Denti while the rush lasts.
		var pulse := 0.5 + 0.5 * sin(clock * 10.0)
		draw_arc(to_local(player.global_position), 34.0 + pulse * 4.0, 0.0, TAU, 32, Color(RUSH_COLOR, 0.55 + pulse * 0.3), 3.0, true)
	for flash in flashes:
		var progress := 1.0 - float(flash.time) / FLASH_SECONDS
		draw_arc(to_local(flash.at), float(flash.radius) * (0.4 + 0.6 * progress), 0.0, TAU, 36, Color(flash.color, 0.85 * (1.0 - progress)), 4.0, true)

func save_data() -> Dictionary:
	var saved_clouds: Array = []
	for cloud in clouds: saved_clouds.append({"at": SnapshotValues.vector_data(cloud.at), "time": float(cloud.time), "tick": float(cloud.tick)})
	return {"rush_time": rush_time, "crash_time": crash_time, "slip_cooldown": slip_cooldown, "clouds": saved_clouds}

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["rush_time", "crash_time", "slip_cooldown"]:
		var value: Variant = saved.get(key, 0)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0: return false
	var saved_clouds: Variant = saved.get("clouds", [])
	if not saved_clouds is Array or saved_clouds.size() > CLOUD_LIMIT: return false
	for cloud in saved_clouds:
		if not cloud is Dictionary or not SnapshotValues.is_vector(cloud.get("at")): return false
		for key in ["time", "tick"]:
			var value: Variant = cloud.get(key, 0)
			if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0: return false
	return true

func restore(saved: Variant) -> void:
	reset_wave()
	if not valid(saved): return
	rush_time = clampf(float(saved.get("rush_time", 0)), 0.0, RUSH_SECONDS + RUSH_HYPER_SECONDS)
	crash_time = clampf(float(saved.get("crash_time", 0)), 0.0, CRASH_SECONDS)
	slip_cooldown = clampf(float(saved.get("slip_cooldown", 0)), 0.0, SLIP_SHIELD_COOLDOWN)
	player.dash.free_dashes = rush_time > 0.0
	for cloud in saved.get("clouds", []):
		clouds.append({"at": SnapshotValues.read_vector(cloud.at), "time": clampf(float(cloud.time), 0.0, CLOUD_SECONDS + CLOUD_DENSE_SECONDS), "tick": clampf(float(cloud.tick), 0.0, CLOUD_INTERVAL)})
