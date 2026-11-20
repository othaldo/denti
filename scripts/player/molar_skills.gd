class_name MolarSkills
extends Node2D

## Good Old Molar's branch skills. All three are automatic and visible:
##
## * Generalprobe (Werkzeugkasten): every few seconds all equipped weapons
##   attack at once with a damage bonus. Rewards mixed loadouts.
## * Gleichtakt (Fachpraxis): copies of one weapon count their attacks; every
##   n-th attack opens a synchronized salvo of all copies, guaranteed critical.
## * Schmelzwall (Standfest): a blocked shield hit, or standing still, releases
##   a ring that shoves enemies and shatters enemy projectiles.
##
## Talent powers come from ClassCombatEffects. Forced skill attacks never count
## toward skill triggers, so the skills cannot chain into themselves.

const REHEARSAL_INTERVAL := 8.0
const REHEARSAL_BOOST := 0.5
const ENCORE_EVERY := 3
const ENCORE_DELAY := 0.35
const QUICKDRAW_SECONDS := 3.0
const QUICKDRAW_BONUS := 25.0
const FIREWORK_RADIUS := 70.0
const FIREWORK_SHARE := 0.35
const UNISON_EVERY := 5
const UNISON_BOOST := 0.6
const UNISON_SHOCK_RADIUS := 80.0
const UNISON_SHOCK_SHARE := 0.5
const UNISON_HASTE_SECONDS := 3.0
const UNISON_HASTE := 20.0
const WALL_RADIUS := 130.0
const WALL_ECHO_RADIUS := 30.0
const WALL_PUSH := 70.0
const WALL_STILL_SECONDS := 1.0
const WALL_COOLDOWN := 10.0
const WALL_ECHO_COOLDOWN := 6.0
const WALL_SHIELD_GAP := 1.0
const WALL_SHARD_BASE := 12.0
const WALL_SHARD_PER_ARMOR := 4.0
const WALL_HEAL_CAP := 6
const FLASH_SECONDS := 0.45

var player: Player
var rehearsal_time := REHEARSAL_INTERVAL
var rehearsal_count := 0
var encore_time := 0.0
var quickdraw_time := 0.0
var unison_counts: Dictionary = {}
var unison_haste: Dictionary = {}
var wall_cooldown := 0.0
var still_time := 0.0
var flashes: Array[Dictionary] = []

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = -1

func power(id: String) -> float:
	return player.class_combat.power(id) if player != null else 0.0

func reset_wave() -> void:
	rehearsal_time = rehearsal_interval()
	rehearsal_count = 0
	encore_time = 0.0
	quickdraw_time = 0.0
	unison_counts.clear()
	unison_haste.clear()
	wall_cooldown = 0.0
	still_time = 0.0
	flashes.clear()
	queue_redraw()

# --- Generalprobe -----------------------------------------------------------

## Lampenfieber shortens the interval by one second per rank.
func rehearsal_interval() -> float:
	return maxf(REHEARSAL_INTERVAL - power("rehearsal_speed"), 4.0)

func attack_speed_bonus() -> float:
	return QUICKDRAW_BONUS * power("rehearsal_quickdraw") if quickdraw_time > 0.0 else 0.0

func _rehearse() -> bool:
	var fired := 0
	for weapon in player.loadout.equipped():
		if not weapon.force_attack(REHEARSAL_BOOST): continue
		fired += 1
		if power("rehearsal_fireworks") > 0.0: _firework(weapon)
	if fired == 0: return false
	rehearsal_count += 1
	if power("rehearsal_quickdraw") > 0.0: quickdraw_time = QUICKDRAW_SECONDS
	if power("rehearsal_encore") > 0.0 and rehearsal_count % ENCORE_EVERY == 0: encore_time = ENCORE_DELAY
	_flash(player.global_position, 150.0, DentiUIStyle.GOLD)
	player.items.enchantment_support.emit(&"class_rehearsals", 1)
	return true

## Elementfeuerwerk: enchanted weapons in the salvo burst with their element.
func _firework(weapon: WeaponInstance) -> void:
	var element := WeaponAffixes.element(weapon.affixes)
	if element == &"": return
	var at := weapon.to_global(weapon.hit_point)
	var amount := weapon.data.raw_damage_with_stats(weapon.tier, player.stats) * FIREWORK_SHARE * power("rehearsal_fireworks")
	for enemy in player.nearby_enemies(at, FIREWORK_RADIUS):
		if enemy.health > 0.0: enemy.take_damage(player.stats.scale_damage(amount), null, false, &"class_fireworks")
	ElementImpactBatch.emit_from(player, element, at, Vector2.RIGHT, FIREWORK_RADIUS, true)

# --- Gleichtakt -------------------------------------------------------------

func _copies(weapon: WeaponInstance) -> Array[WeaponInstance]:
	var result: Array[WeaponInstance] = []
	for other in player.loadout.equipped():
		if other.data.id == weapon.data.id: result.append(other)
	return result

func unison_every() -> int:
	return maxi(UNISON_EVERY - roundi(power("unison_rate")), 2)

## Called at the start of every regular attack. True when this attack opens a
## Gleichtakt salvo; the other copies are forced to attack with it.
func unison_trigger(weapon: WeaponInstance) -> bool:
	if power("skill_unison") <= 0.0: return false
	var copies := _copies(weapon)
	if copies.size() < 2: return false
	var key := str(weapon.data.id)
	unison_counts[key] = int(unison_counts.get(key, 0)) + 1
	if int(unison_counts[key]) < unison_every(): return false
	unison_counts[key] = 0
	for other in copies:
		if other != weapon: other.force_attack(UNISON_BOOST, true)
	if power("unison_haste") > 0.0: unison_haste[key] = UNISON_HASTE_SECONDS
	if power("unison_shock") > 0.0: _unison_shock(weapon)
	_flash(player.global_position, 110.0, DentiUIStyle.MINT)
	player.items.enchantment_support.emit(&"class_unisons", 1)
	return true

## Schockwelle: the salvo's target releases a burst around it.
func _unison_shock(weapon: WeaponInstance) -> void:
	var target := EnemySpatialIndex.nearest(get_tree(), player.enemy_index, player.global_position, weapon.data.range_at_tier(weapon.tier), true)
	if target == null: return
	var amount := weapon.data.raw_damage_with_stats(weapon.tier, player.stats) * UNISON_SHOCK_SHARE
	for enemy in player.nearby_enemies(target.global_position, UNISON_SHOCK_RADIUS):
		if enemy.health > 0.0: enemy.take_damage(player.stats.scale_damage(amount), null, false, &"class_unison_shock")
	_flash(target.global_position, UNISON_SHOCK_RADIUS, DentiUIStyle.MINT)

## Attack interval multiplier for one weapon (Taktgeber, Meisterhand).
func weapon_interval_factor(weapon: WeaponInstance) -> float:
	var bonus := 0.0
	if float(unison_haste.get(str(weapon.data.id), 0.0)) > 0.0: bonus += UNISON_HASTE
	if weapon.tier >= 3: bonus += power("spec_master")
	return 1.0 / (1.0 + bonus / 100.0)

# --- Schmelzwall ------------------------------------------------------------

func wall_radius() -> float:
	var radius := WALL_RADIUS + (WALL_ECHO_RADIUS if power("wall_echo") > 0.0 else 0.0)
	return radius * (1.5 if power("wall_anchor") > 0.0 else 1.0)

func wall_cooldown_seconds() -> float:
	return WALL_ECHO_COOLDOWN if power("wall_echo") > 0.0 else WALL_COOLDOWN

func on_shield_blocked() -> void:
	if power("skill_wall") <= 0.0 or not player.combat_active(): return
	if wall_cooldown > wall_cooldown_seconds() - WALL_SHIELD_GAP: return
	_wall()

func wall_damage() -> float:
	if power("wall_shards") <= 0.0: return 0.0
	var armor := maxf(player.stats.armor, 0.0) * (2.0 if power("wall_anchor") > 0.0 else 1.0)
	return player.stats.scale_damage((WALL_SHARD_BASE + WALL_SHARD_PER_ARMOR * armor) * power("wall_shards"))

func _wall() -> void:
	var at := player.global_position
	var radius := wall_radius()
	var damage := wall_damage()
	for enemy in player.nearby_enemies(at, radius):
		if not enemy.is_targetable(): continue
		var away := at.direction_to(enemy.global_position)
		if away.is_zero_approx(): away = Vector2.RIGHT
		enemy.global_position += away * WALL_PUSH * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))
		if damage > 0.0: enemy.take_damage(damage, null, false, &"class_wall")
	var shattered := 0
	var projectiles := player.get_parent().get_node_or_null("EnemyProjectiles")
	if projectiles != null:
		for projectile in projectiles.get_children():
			if projectile is AcidProjectile and projectile.is_physics_processing() and projectile.global_position.distance_squared_to(at) <= radius * radius:
				projectile.shatter()
				shattered += 1
	if power("wall_heal") > 0.0 and shattered > 0:
		player.stats.heal(float(mini(shattered, WALL_HEAL_CAP)) * power("wall_heal"))
	wall_cooldown = wall_cooldown_seconds()
	still_time = 0.0
	_flash(at, radius, DentiUIStyle.CREAM)
	player.items.enchantment_support.emit(&"class_walls", 1)
	if shattered > 0: player.items.enchantment_support.emit(&"class_wall_shatters", shattered)

# --- Shared -----------------------------------------------------------------

func advance(delta: float) -> void:
	quickdraw_time = maxf(quickdraw_time - delta, 0.0)
	wall_cooldown = maxf(wall_cooldown - delta, 0.0)
	for key in unison_haste.keys():
		unison_haste[key] = maxf(float(unison_haste[key]) - delta, 0.0)
		if unison_haste[key] <= 0.0: unison_haste.erase(key)
	if power("skill_rehearsal") > 0.0:
		rehearsal_time -= delta
		if rehearsal_time <= 0.0:
			# Without a target the salvo waits instead of being wasted.
			if _rehearse(): rehearsal_time = rehearsal_interval()
			else: rehearsal_time = 0.0
		if encore_time > 0.0:
			encore_time -= delta
			if encore_time <= 0.0:
				encore_time = 0.0
				for weapon in player.loadout.equipped(): weapon.force_attack(REHEARSAL_BOOST)
				_flash(player.global_position, 150.0, DentiUIStyle.GOLD)
	if power("skill_wall") > 0.0:
		still_time = 0.0 if player.is_moving or player.dash.active else still_time + delta
		if still_time >= WALL_STILL_SECONDS and wall_cooldown <= 0.0 and not player.nearby_enemies(player.global_position, wall_radius()).is_empty():
			_wall()
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index].time -= delta
		if flashes[index].time <= 0.0: flashes.remove_at(index)
	queue_redraw()

func _flash(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"at": at, "radius": radius, "color": color, "time": FLASH_SECONDS})
	if flashes.size() > 16: flashes.pop_front()

func _draw() -> void:
	for flash in flashes:
		var progress := 1.0 - float(flash.time) / FLASH_SECONDS
		var radius := float(flash.radius) * (0.35 + 0.65 * progress)
		var color: Color = flash.color
		draw_arc(to_local(flash.at), radius, 0.0, TAU, 48, Color(color, 0.85 * (1.0 - progress)), 5.0, true)
		draw_arc(to_local(flash.at), radius * 0.82, 0.0, TAU, 48, Color(color, 0.35 * (1.0 - progress)), 2.0, true)

func save_data() -> Dictionary:
	return {"rehearsal_time": rehearsal_time, "rehearsal_count": rehearsal_count, "encore_time": encore_time, "quickdraw_time": quickdraw_time,
		"wall_cooldown": wall_cooldown, "still_time": still_time, "unison_counts": unison_counts.duplicate(), "unison_haste": unison_haste.duplicate()}

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in saved:
		var value: Variant = saved[key]
		if key in ["unison_counts", "unison_haste"]:
			if not value is Dictionary: return false
			for inner in value.values():
				if not (inner is int or inner is float) or not is_finite(float(inner)) or float(inner) < 0: return false
		elif not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0:
			return false
	return true

func restore(saved: Variant) -> void:
	reset_wave()
	if not valid(saved): return
	rehearsal_time = clampf(float(saved.get("rehearsal_time", rehearsal_interval())), 0.0, rehearsal_interval())
	rehearsal_count = maxi(int(saved.get("rehearsal_count", 0)), 0)
	encore_time = clampf(float(saved.get("encore_time", 0.0)), 0.0, ENCORE_DELAY)
	quickdraw_time = clampf(float(saved.get("quickdraw_time", 0.0)), 0.0, QUICKDRAW_SECONDS)
	wall_cooldown = clampf(float(saved.get("wall_cooldown", 0.0)), 0.0, WALL_COOLDOWN)
	still_time = clampf(float(saved.get("still_time", 0.0)), 0.0, WALL_STILL_SECONDS)
	for key in saved.get("unison_counts", {}): unison_counts[str(key)] = clampi(int(saved.unison_counts[key]), 0, UNISON_EVERY)
	for key in saved.get("unison_haste", {}): unison_haste[str(key)] = clampf(float(saved.unison_haste[key]), 0.0, UNISON_HASTE_SECONDS)
