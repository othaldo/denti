class_name HerbSkills
extends ClassSkillModule

## Kräuterzahn: "Erst säen, dann ernten". The planting staff does not attack:
## in its attack rhythm it plants a herb where Denti stands. Herbs grow,
## fight and wilt after their lifetime, so the garden size follows the
## planting speed (lifetime / interval) up to a cap. Sage sprouts shoot with
## the staff's damage, enchantments and crits. Skills add herbs to the
## planting rotation: Salbeistrauch (salvo bush), Kamillentotem (aura) and
## Nelkenknospe (numbing debuff). Enemies wear herbs down on contact, bosses
## trample them. Herb art: assets/classes/herb_druid_plants.png (4 x 2), drawn
## procedurally until it exists.

enum Kind { SAGE, SHRUB, TOTEM, CLOVE }

const STAFF_ID := &"planting_staff"
const PLANTS_PATH := "res://assets/classes/herb_druid_plants.png"
const GROW_SECONDS := 0.6
const LIFETIME := 12.0
const LIFETIME_PER_TIER := 1.5
const CAPS: Array[int] = [10, 12, 14, 16]
const MONOCULTURE_CAP := 1.5
const SHOT_INTERVAL := 0.9
const SHRUB_INTERVAL := 1.6
const SHRUB_SHOTS := 3
const SHRUB_EVERY := 5
const SHRUB_WILD_EVERY := 4
const SHRUB_SHARE := 0.8
const PLANT_HEALTH := 40.0
const PLANT_HEALTH_PER_TIER := 12.0
const PLANT_RADIUS := 16.0
const CONTACT_INTERVAL := 0.5
const SOOTHE_RADIUS := 130.0
const SOOTHE_HEAL := 0.25
const SOOTHE_CAP := 4
const TOTEM_RADIUS := 110.0
const TOTEM_WREATH := 1.5
const TOTEM_HASTE := 20.0
const TOTEM_HEAL := 1.0
const TOTEM_SHOT_FACTOR := 0.75
const TOTEM_TEA := 8.0
const CEREMONY_SLOW := 0.8
const CLOVE_RADIUS := 95.0
const CLOVE_BONUS := 15.0
const CLOVE_OIL_BONUS := 25.0
const CLOVE_POISON := 4.0
const CLOVE_TICK := 0.5
const CLOVE_BURST := 20.0
const CLOVE_BURST_RANGED := 0.8
const SNARE_SECONDS := 0.8
const NUMB_SECONDS := 0.6
const MAX_SAVED := 24
const SAGE := Color(0.55, 0.78, 0.48)
const CHAMOMILE := Color(1.0, 0.93, 0.55)
const CLOVE := Color(0.62, 0.32, 0.22)
const STEM := Color(0.27, 0.45, 0.22)
## Drawn herb size relative to the base shapes; readable next to Denti.
const DRAW_SCALE := 1.7

var plants: Array[Dictionary] = []
var plantings := 0
var sage_plantings := 0
var clove_tick := 0.0
var tea_cooldown := 0.0
## Enemy instance id -> seconds of clove numbing left (refreshed every tick).
var numbed: Dictionary = {}
## Enemy instance id -> [position, seconds] while a Würgeranke holds it.
var snared: Dictionary = {}
var snared_once: Dictionary = {}
var pierce_data: WeaponData
var pierce_source: WeaponData
var plant_art: Texture2D

func class_id() -> StringName:
	return &"herb_druid"

func _ready() -> void:
	super._ready()
	if ResourceLoader.exists(PLANTS_PATH): plant_art = load(PLANTS_PATH)

func reset_wave() -> void:
	super.reset_wave()
	plants.clear()
	plantings = 0
	sage_plantings = 0
	clove_tick = 0.0
	tea_cooldown = 0.0
	numbed.clear()
	snared.clear()
	snared_once.clear()

static func for_player(denti: Player) -> HerbSkills:
	return denti.skill_module(&"herb_druid") as HerbSkills if denti != null else null

func staff() -> WeaponInstance:
	for weapon in player.loadout.equipped():
		if weapon.data.attack_mode == &"plant": return weapon
	return null

# --- Garden size --------------------------------------------------------------

func capacity() -> int:
	var weapon := staff()
	var tier := weapon.tier if weapon != null else 1
	var cap := CAPS[clampi(tier, 1, CAPS.size()) - 1] + roundi(power("herb_cap"))
	return roundi(cap * MONOCULTURE_CAP) if power("herb_monoculture") > 0.0 else cap

func lifetime(kind: int) -> float:
	var weapon := staff()
	var seconds := LIFETIME + LIFETIME_PER_TIER * float((weapon.tier if weapon != null else 1) - 1) + power("herb_life")
	if kind == Kind.SHRUB and power("shrub_roots") > 0.0: seconds *= 2.0
	return seconds

func plant_health() -> float:
	var weapon := staff()
	return (PLANT_HEALTH + PLANT_HEALTH_PER_TIER * float((weapon.tier if weapon != null else 1) - 1)) * (1.0 + power("herb_hedge"))

## Next herb in the planting rotation.
func next_kind() -> int:
	if power("herb_monoculture") > 0.0: return _sage_kind()
	var slot := plantings % 4
	if slot == 1 and power("skill_totem") > 0.0: return Kind.TOTEM
	if slot == 3 and power("skill_clove") > 0.0: return Kind.CLOVE
	return _sage_kind()

func _sage_kind() -> int:
	if power("skill_shrub") <= 0.0: return Kind.SAGE
	var every := SHRUB_WILD_EVERY if power("shrub_wild") > 0.0 else SHRUB_EVERY
	return Kind.SHRUB if (sage_plantings + 1) % every == 0 else Kind.SAGE

## Called by the planting staff in its attack rhythm.
func plant(at: Vector2 = Vector2.INF) -> void:
	if not active(): return
	var kind := next_kind()
	plantings += 1
	if kind in [Kind.SAGE, Kind.SHRUB]: sage_plantings += 1
	_add_plant(kind, player.global_position if at == Vector2.INF else at)

func _add_plant(kind: int, at: Vector2) -> void:
	# A full garden replaces its oldest herb, so it follows Denti.
	while plants.size() >= capacity(): plants.pop_front()
	plants.append({"kind": kind, "at": at, "grow": GROW_SECONDS, "life": lifetime(kind), "health": plant_health(),
		"shot": randf_range(0.0, SHOT_INTERVAL), "contact": 0.0})
	support(&"class_herb_plantings")

func grown(plant_entry: Dictionary) -> bool:
	return float(plant_entry.grow) <= 0.0

# --- Hooks ----------------------------------------------------------------------

## Ranken: a dash leaves a sage sprout at its start.
func on_dash_started() -> void:
	if active() and power("herb_tendril") > 0.0: _add_plant(Kind.SAGE, player.global_position)

func attack_speed_bonus() -> float:
	return TOTEM_HASTE * _ceremony() if active() and _in_aura(player.global_position) else 0.0

func move_factor() -> float:
	return CEREMONY_SLOW if active() and power("herb_ceremony") > 0.0 and _in_aura(player.global_position) else 1.0

## Nelkenknospe: numbed enemies take more weapon damage.
func damage_bonus(enemy: Enemy, _weapon: WeaponData) -> float:
	if not active() or not numbed.has(enemy.get_instance_id()): return 0.0
	return CLOVE_OIL_BONUS if power("clove_oil") > 0.0 else CLOVE_BONUS

func advance(delta: float) -> void:
	if active():
		tea_cooldown = maxf(tea_cooldown - delta, 0.0)
		_tick_numbing(delta)
		_hold_snared(delta)
		var weapon := staff()
		var soothing := 0
		for index in range(plants.size() - 1, -1, -1):
			var entry := plants[index]
			entry.grow = maxf(float(entry.grow) - delta, 0.0)
			entry.life = float(entry.life) - delta
			if entry.life <= 0.0 or entry.health <= 0.0:
				_wilt(entry, entry.life <= 0.0)
				plants.remove_at(index)
				continue
			if not grown(entry): continue
			_contact(entry, delta)
			if weapon != null and entry.kind in [Kind.SAGE, Kind.SHRUB]: _shoot(entry, weapon, delta)
			if power("herb_soothe") > 0.0 and entry.at.distance_squared_to(player.global_position) <= SOOTHE_RADIUS * SOOTHE_RADIUS: soothing += 1
		if soothing > 0: player.stats.heal(SOOTHE_HEAL * mini(soothing, SOOTHE_CAP) * delta)
		if _in_aura(player.global_position):
			player.stats.heal(TOTEM_HEAL * _ceremony() * delta)
			if power("totem_tea") > 0.0 and tea_cooldown <= 0.0:
				tea_cooldown = TOTEM_TEA
				player.stats.grant_shield(1)
	super.advance(delta)

# --- Plants in combat -----------------------------------------------------------

func _shoot(entry: Dictionary, weapon: WeaponInstance, delta: float) -> void:
	var interval := (SHRUB_INTERVAL if entry.kind == Kind.SHRUB else SHOT_INTERVAL) * (TOTEM_SHOT_FACTOR if _in_aura(entry.at) else 1.0)
	entry.shot = float(entry.shot) - delta
	if entry.shot > 0.0: return
	var reach := weapon.data.range_at_tier(weapon.tier)
	var targets: Array[Enemy] = []
	var shots := 1 if entry.kind == Kind.SAGE else SHRUB_SHOTS + roundi(power("shrub_seeds"))
	for enemy in player.nearby_enemies(entry.at, reach):
		if not enemy.is_targetable(): continue
		targets.append(enemy)
		if targets.size() >= shots: break
	if targets.is_empty():
		entry.shot = 0.15
		return
	entry.shot = interval
	var data := _shot_data(weapon.data)
	var pool := player.get_parent().get_node_or_null("Projectiles") as PlayerProjectilePool
	if pool == null: return
	for index in shots:
		var target: Enemy = targets[index % targets.size()]
		var base := data.raw_damage_with_stats(weapon.tier, player.stats) + scaled(power("herb_damage"))
		if entry.kind == Kind.SHRUB: base *= SHRUB_SHARE
		var damage := player.stats.roll_critical_damage(base, data.crit_bonus, data.crit_multiplier)
		var critical := player.stats.last_roll_critical
		var muzzle: Vector2 = entry.at + Vector2(0, -14)
		var projectile := pool.acquire(data, weapon.tier)
		projectile.launch(muzzle, muzzle.direction_to(target.global_position), damage, data, player.items, critical, weapon.tier, weapon.affixes, 1.0, weapon.instance_uid)
	if power("herb_numb") > 0.0:
		for target in targets: _numb_slow(target, NUMB_SECONDS)

## Dornen: a copy of the staff data with one more pierce.
func _shot_data(source: WeaponData) -> WeaponData:
	if power("herb_pierce") <= 0.0: return source
	if pierce_source != source:
		pierce_source = source
		pierce_data = source.duplicate() as WeaponData
		pierce_data.pierce = source.pierce + 1
		var tiers := PackedInt32Array()
		for value in source.pierce_tiers: tiers.append(value + 1)
		pierce_data.pierce_tiers = tiers
	return pierce_data

func _contact(entry: Dictionary, delta: float) -> void:
	entry.contact = maxf(float(entry.contact) - delta, 0.0)
	if entry.contact > 0.0: return
	var damage := 0.0
	for enemy in player.nearby_enemies(entry.at, PLANT_RADIUS):
		if not enemy.is_targetable(): continue
		if enemy.data.is_boss:
			entry.health = 0.0 # Bosses trample herbs.
			return
		damage = maxf(damage, enemy.contact_damage)
	if damage <= 0.0: return
	entry.contact = CONTACT_INTERVAL
	entry.health = maxf(float(entry.health) - damage, 0.0)

func _wilt(entry: Dictionary, natural: bool) -> void:
	if entry.kind == Kind.TOTEM and natural and power("totem_cutting") > 0.0:
		plants.append({"kind": Kind.SAGE, "at": entry.at, "grow": GROW_SECONDS, "life": lifetime(Kind.SAGE), "health": plant_health(),
			"shot": SHOT_INTERVAL, "contact": 0.0})
	if entry.kind == Kind.CLOVE and power("clove_burst") > 0.0:
		var amount := scaled(CLOVE_BURST + maxf(player.stats.ranged_damage, 0.0) * CLOVE_BURST_RANGED)
		for enemy in player.nearby_enemies(entry.at, CLOVE_RADIUS):
			if enemy.is_targetable(): enemy.take_damage(amount, null, false, &"class_herb")
		flash(entry.at, CLOVE_RADIUS, CLOVE)

# --- Auras ------------------------------------------------------------------------

func _ceremony() -> float:
	return 2.0 if power("herb_ceremony") > 0.0 else 1.0

func totem_radius() -> float:
	return TOTEM_RADIUS * (TOTEM_WREATH if power("totem_wreath") > 0.0 else 1.0)

func _in_aura(at: Vector2) -> bool:
	var radius := totem_radius()
	for entry in plants:
		if entry.kind == Kind.TOTEM and grown(entry) and entry.at.distance_squared_to(at) <= radius * radius: return true
	return false

func _tick_numbing(delta: float) -> void:
	for id in numbed.keys():
		numbed[id] = float(numbed[id]) - delta
		if numbed[id] <= 0.0: numbed.erase(id)
	clove_tick -= delta
	if clove_tick > 0.0: return
	clove_tick = CLOVE_TICK
	var poison := power("herb_poison_garden") > 0.0
	for entry in plants:
		if entry.kind != Kind.CLOVE or not grown(entry): continue
		for enemy in player.nearby_enemies(entry.at, CLOVE_RADIUS):
			if not enemy.is_targetable(): continue
			var id := enemy.get_instance_id()
			numbed[id] = CLOVE_TICK + 0.1
			if poison:
				var additions: Array[Dictionary] = [{"id": "poison", "damage": scaled(CLOVE_POISON), "proc_id": "class_herb"}]
				enemy.take_damage(0, null, false, &"class_herb", additions)
			else:
				_numb_slow(enemy, CLOVE_TICK + 0.1)
			if power("clove_snare") > 0.0 and not enemy.data.is_boss and not snared_once.has(id):
				snared_once[id] = true
				snared[id] = [enemy.global_position, SNARE_SECONDS]

func _numb_slow(enemy: Enemy, seconds: float) -> void:
	if enemy.affix_effects.depot.nerve_lock > 0: return
	enemy.affix_effects.depot.nerve_time = maxf(enemy.affix_effects.depot.nerve_time, minf(seconds, PoisonDepotState.RULES.nerve_duration))
	enemy.queue_redraw()

func _hold_snared(delta: float) -> void:
	for id in snared.keys():
		var enemy := instance_from_id(id) as Enemy
		var hold: Array = snared[id]
		hold[1] = float(hold[1]) - delta
		if not is_instance_valid(enemy) or not enemy.is_targetable() or hold[1] <= 0.0:
			snared.erase(id)
			continue
		enemy.global_position = hold[0]

# --- Drawing ----------------------------------------------------------------------

func _draw() -> void:
	if not active(): return
	var radius := totem_radius()
	var glow := element_color()
	for entry in plants:
		var at := to_local(entry.at)
		var growth := 1.0 - float(entry.grow) / GROW_SECONDS
		var fade := clampf(float(entry.life), 0.0, 1.0)
		if entry.kind == Kind.TOTEM and grown(entry):
			draw_circle(at, radius, Color(CHAMOMILE, 0.07 * fade))
			draw_arc(at, radius, 0.0, TAU, 48, Color(CHAMOMILE, 0.45 * fade), 2.0, true)
		elif entry.kind == Kind.CLOVE and grown(entry):
			draw_arc(at, CLOVE_RADIUS, 0.0, TAU, 40, Color(CLOVE.lightened(0.3), 0.45 * fade), 2.0, true)
		# The staff's element shows on every herb as a soft ground glow.
		if glow.a > 0.0 and grown(entry):
			draw_circle(at + Vector2(0, -4), 13.0 * DRAW_SCALE, Color(glow, 0.22 * fade))
		_draw_plant(at, int(entry.kind), growth, fade)
	draw_effects()

## Element color of the staff's enchantment, transparent without one.
func element_color() -> Color:
	var weapon := staff()
	if weapon == null: return Color.TRANSPARENT
	var element: StringName = WeaponAffixes.element(weapon.affixes)
	var definition := WeaponAffixes.by_id(element) if element != &"" else null
	if definition == null or not definition.elemental: return Color.TRANSPARENT
	return WeaponSkins.STAFF_WATER_COLOR if element == &"wet" else definition.color

func _draw_plant(at: Vector2, kind: int, growth: float, fade: float) -> void:
	if plant_art != null:
		var cell := Vector2(plant_art.get_size()) / Vector2(4, 2)
		var row := 0 if growth >= 1.0 else 1
		var size := Vector2.ONE * (44.0 if kind == Kind.SHRUB else 36.0) * DRAW_SCALE * lerpf(0.6, 1.0, growth)
		draw_texture_rect_region(plant_art, Rect2(at - Vector2(size.x * 0.5, size.y * 0.85), size), Rect2(Vector2(kind, row) * cell, cell), Color(1, 1, 1, fade))
		return
	# Procedural stand-in until the painted sheet exists.
	var scale := lerpf(0.4, 1.0, growth) * DRAW_SCALE
	var color: Color = [SAGE, SAGE.darkened(0.15), CHAMOMILE, CLOVE][kind]
	draw_line(at, at + Vector2(0, -16) * scale, Color(STEM, fade), 4.0, true)
	match kind:
		Kind.SAGE:
			draw_circle(at + Vector2(-5, -12) * scale, 5.0 * scale, Color(color, fade))
			draw_circle(at + Vector2(5, -14) * scale, 5.0 * scale, Color(color, fade))
			draw_circle(at + Vector2(0, -20) * scale, 4.0 * scale, Color(color.lightened(0.2), fade))
		Kind.SHRUB:
			draw_circle(at + Vector2(0, -16) * scale, 13.0 * scale, Color(color, fade))
			draw_circle(at + Vector2(-7, -22) * scale, 6.0 * scale, Color(color.lightened(0.2), fade))
			draw_circle(at + Vector2(7, -22) * scale, 6.0 * scale, Color(color.lightened(0.2), fade))
		Kind.TOTEM:
			draw_rect(Rect2(at + Vector2(-4, -22) * scale, Vector2(8, 22) * scale), Color(0.82, 0.68, 0.48, fade))
			for petal in 8:
				draw_circle(at + (Vector2(0, -26) + Vector2.RIGHT.rotated(TAU * petal / 8.0) * 6.0) * scale, 3.5 * scale, Color(1, 1, 1, fade))
			draw_circle(at + Vector2(0, -26) * scale, 4.0 * scale, Color(color, fade))
		Kind.CLOVE:
			draw_circle(at + Vector2(0, -20) * scale, 7.0 * scale, Color(color, fade))
			for point in 4:
				draw_circle(at + (Vector2(0, -20) + Vector2.UP.rotated(TAU * point / 4.0) * 7.0) * scale, 3.0 * scale, Color(color.darkened(0.2), fade))
	draw_arc(at + Vector2(0, -14) * scale, 14.0 * scale, 0.0, TAU, 20, Color(0.17, 0.12, 0.08, 0.5 * fade), 1.5, true)

# --- Save ---------------------------------------------------------------------------

func save_data() -> Dictionary:
	if not active(): return {}
	var saved: Array = []
	for entry in plants.slice(maxi(plants.size() - MAX_SAVED, 0)):
		saved.append({"kind": int(entry.kind), "at": SnapshotValues.vector_data(entry.at), "grow": float(entry.grow),
			"life": float(entry.life), "health": float(entry.health), "shot": float(entry.shot)})
	return {"plants": saved, "plantings": plantings, "sage": sage_plantings, "tea": tea_cooldown}

func restore(saved: Dictionary) -> void:
	reset_wave()
	if not active(): return
	plantings = clampi(int(saved.get("plantings", 0)), 0, 100000)
	sage_plantings = clampi(int(saved.get("sage", 0)), 0, 100000)
	tea_cooldown = clampf(float(saved.get("tea", 0.0)), 0.0, TOTEM_TEA)
	var entries: Variant = saved.get("plants", [])
	if not entries is Array: return
	for entry in entries:
		if not entry is Dictionary or not SnapshotValues.is_vector(entry.get("at")): continue
		var kind := clampi(int(entry.get("kind", 0)), Kind.SAGE, Kind.CLOVE)
		plants.append({"kind": kind, "at": SnapshotValues.read_vector(entry.at), "grow": clampf(float(entry.get("grow", 0)), 0.0, GROW_SECONDS),
			"life": clampf(float(entry.get("life", 0)), 0.0, lifetime(kind)), "health": clampf(float(entry.get("health", 1)), 0.0, plant_health()),
			"shot": clampf(float(entry.get("shot", 0)), 0.0, SHRUB_INTERVAL), "contact": 0.0})
		if plants.size() >= MAX_SAVED: break
	queue_redraw()
