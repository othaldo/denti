class_name HerbSkills
extends ClassSkillModule

## Kräuterzahn: "Erst säen, dann ernten". The planting staff does not attack:
## in its attack rhythm it plants a herb where Denti stands. Herbs grow,
## fight and wilt after their lifetime, so the garden size follows the
## planting speed (lifetime / interval) up to a cap. Talents open roots for a
## second and third staff; every staff tends its own garden with its own cap,
## element, Mk tier and enchantments. Sage sprouts shoot with the damage,
## enchantments and crits of the staff that planted them. Skills add herbs to the
## planting rotation: Salbeistrauch (salvo bush), Kamillentotem (aura) and
## Nelkenknospe (numbing debuff). Enemies wear herbs down on contact, bosses
## trample them. Herb art: assets/classes/herb_druid_plants.png (4 x 2), drawn
## procedurally until it exists.

enum Kind { SAGE, SHRUB, TOTEM, CLOVE }

const STAFF_ID := &"planting_staff"
const PLANTS_PATH := "res://assets/classes/herb_druid_plants.png"
const GROW_SECONDS := 0.6
## Garden size follows lifetime / planting interval; no gameplay cap.
const LIFETIME := 8.0
const LIFETIME_PER_TIER := 1.5
## Performance guard per staff, far above what planting speed normally reaches.
const SAFETY_CAP := 30
const MONOCULTURE_LIFE := 1.5
## Dichtes Beet: planting speed per rank.
const RATE_PER_RANK := 0.1
const SHOT_INTERVAL := 0.8
const SHRUB_INTERVAL := 1.6
const SHRUB_SHOTS := 3
const SHRUB_EVERY := 5
const SHRUB_WILD_EVERY := 4
const SHRUB_SHARE := 0.8
const SAGE_MUZZLE_HEIGHT := 44.0
const SHRUB_MUZZLE_HEIGHT := 51.0
const PLANT_HEALTH := 40.0
const PLANT_HEALTH_PER_TIER := 12.0
const PLANT_RADIUS := 16.0
const CONTACT_INTERVAL := 0.5
const BOSS_TRAMPLE := 3.0
## New herbs land in a ring around Denti, preferring free spots.
const SPREAD_MIN := 18.0
const SPREAD_MAX := 62.0
const SPREAD_TRIES := 6
## Ernte: loot near a grown herb flies to Denti, so kills at range still pay.
const HARVEST_RADIUS := 90.0
const HARVEST_TICK := 0.25
const SOOTHE_RADIUS := 130.0
const SOOTHE_HEAL := 0.25
const SOOTHE_CAP := 4
const TOTEM_RADIUS := 110.0
const TOTEM_WREATH := 1.5
const TOTEM_HASTE := 20.0
const TOTEM_HEAL := 1.0
const HEAL_FEEDBACK_SECONDS := 0.7
const HEAL_PULSE_SECONDS := 0.55
const HEAL_COLOR := Color(0.64, 1.0, 0.72)
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
const MAX_SAVED := 48
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
var heal_pending := 0.0
var heal_feedback_left := 0.0
var heal_pulse_left := 0.0
var heal_origin := Vector2.INF
## Enemy instance id -> seconds of clove numbing left (refreshed every tick).
var numbed: Dictionary = {}
## Enemy instance id -> [position, seconds] while a Würgeranke holds it.
var snared: Dictionary = {}
var snared_once: Dictionary = {}
var pierce_data: WeaponData
var pierce_source: WeaponData
var plant_art: Texture2D
## Staff uid -> remaining planting animation (HerbPlanting.CAST_SECONDS).
var casts: Dictionary = {}
var harvest_tick := 0.0

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
	heal_pending = 0.0
	heal_feedback_left = 0.0
	heal_pulse_left = 0.0
	heal_origin = Vector2.INF
	numbed.clear()
	snared.clear()
	snared_once.clear()
	casts.clear()

static func for_player(denti: Player) -> HerbSkills:
	return denti.skill_module(&"herb_druid") as HerbSkills if denti != null else null

## First planting staff (tests, previews, dash sprouts).
func staff() -> WeaponInstance:
	var all := staffs()
	return all[0] if not all.is_empty() else null

func staffs() -> Array[WeaponInstance]:
	var result: Array[WeaponInstance] = []
	for weapon in player.loadout.equipped():
		if weapon.data.attack_mode == &"plant": result.append(weapon)
	return result

## Staff that planted a herb; a sold or fused staff hands its herbs to the first.
func staff_of(entry: Dictionary) -> WeaponInstance:
	for weapon in staffs():
		if weapon.instance_uid == str(entry.get("staff", "")): return weapon
	return staff()

func _tier(weapon: WeaponInstance) -> int:
	return clampi(weapon.tier if weapon != null else 1, 1, WeaponLoadout.MAX_TIER)

# --- Garden size --------------------------------------------------------------

## Safety limit per staff; the garden normally stays far below it.
func capacity(_weapon: WeaponInstance = null) -> int:
	return SAFETY_CAP

## Herbs a staff keeps alive at its current planting speed.
func expected_garden(weapon: WeaponInstance = null) -> float:
	if weapon == null: weapon = staff()
	if weapon == null: return 0.0
	return lifetime(Kind.SAGE, weapon) / maxf(weapon.attack_interval(), 0.05)

## Dichtes Beet: staffs plant faster.
func weapon_interval_factor(weapon: WeaponInstance) -> float:
	if not active() or weapon.data.attack_mode != &"plant": return 1.0
	return 1.0 / (1.0 + RATE_PER_RANK * power("herb_rate"))

func garden_size(weapon: WeaponInstance) -> int:
	var uid := weapon.instance_uid if weapon != null else ""
	return plants.filter(func(entry: Dictionary) -> bool: return str(entry.get("staff", "")) == uid).size()

func lifetime(kind: int, weapon: WeaponInstance = null) -> float:
	if weapon == null: weapon = staff()
	var seconds := LIFETIME + LIFETIME_PER_TIER * float(_tier(weapon) - 1) + power("herb_life")
	if kind == Kind.SHRUB and power("shrub_roots") > 0.0: seconds *= 2.0
	if power("herb_monoculture") > 0.0: seconds *= MONOCULTURE_LIFE
	return seconds * (1.0 + items().power(&"placed_duration"))

func plant_health(weapon: WeaponInstance = null) -> float:
	if weapon == null: weapon = staff()
	return (PLANT_HEALTH + PLANT_HEALTH_PER_TIER * float(_tier(weapon) - 1)) * (1.0 + power("herb_hedge")) * (1.0 + 2.0 * items().power(&"summon_power"))

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

## Called by a planting staff in its attack rhythm.
func plant(at: Vector2 = Vector2.INF, source: WeaponInstance = null) -> void:
	if not active(): return
	var kind := next_kind()
	plantings += 1
	if kind in [Kind.SAGE, Kind.SHRUB]: sage_plantings += 1
	if source == null: source = staff()
	var ground := planting_spot() if at == Vector2.INF else at
	var tip := Vector2.INF
	if source != null:
		casts[source.instance_uid] = HerbPlanting.CAST_SECONDS
		tip = source.muzzle_position()
	_add_plant(kind, ground, source, tip)

## A spot in the ring around Denti, as far as possible from other herbs.
func planting_spot() -> Vector2:
	var centre := player.global_position
	var lower := Vector2.ONE * DentiArena.PLAYER_MARGIN
	var upper := player.arena.arena_size - lower
	var best := centre
	var best_gap := -1.0
	for attempt in SPREAD_TRIES:
		var offset := Vector2.from_angle(randf() * TAU) * randf_range(SPREAD_MIN, SPREAD_MAX)
		var spot := centre + offset
		# Reflect outward throws back into the arena without shortening the spread.
		if spot.x < lower.x or spot.x > upper.x: spot.x = centre.x - offset.x
		if spot.y < lower.y or spot.y > upper.y: spot.y = centre.y - offset.y
		var gap := INF
		for entry in plants: gap = minf(gap, spot.distance_squared_to(entry.at))
		if gap > best_gap:
			best_gap = gap
			best = spot
	return best

## Remaining planting animation of one staff, 0 when idle.
func cast_left(uid: String) -> float:
	return float(casts.get(uid, 0.0))

func _add_plant(kind: int, at: Vector2, source: WeaponInstance = null, tip: Vector2 = Vector2.INF) -> void:
	if source == null: source = staff()
	var uid := source.instance_uid if source != null else ""
	# A full garden replaces this staff's oldest herb, so it follows Denti.
	var cap := capacity(source)
	while garden_size(source) >= cap:
		for index in plants.size():
			if str(plants[index].get("staff", "")) == uid:
				plants.remove_at(index)
				break
	plants.append({"kind": kind, "at": at, "grow": GROW_SECONDS, "life": lifetime(kind, source), "health": plant_health(source),
		"shot": randf_range(0.0, SHOT_INTERVAL), "contact": 0.0, "staff": uid, "tip": tip, "seed": randi() % 7})
	support(&"class_herb_plantings")

func grown(plant_entry: Dictionary) -> bool:
	return float(plant_entry.grow) <= 0.0

func has_grown_plant_near(at: Vector2, radius: float) -> bool:
	if not active(): return false
	var radius_squared := radius * radius
	for entry in plants:
		if grown(entry) and entry.life > 0.0 and entry.health > 0.0 and at.distance_squared_to(entry.at) <= radius_squared:
			return true
	return false

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
	for uid in casts.keys():
		casts[uid] = float(casts[uid]) - delta
		if casts[uid] <= 0.0: casts.erase(uid)
	if active():
		tea_cooldown = maxf(tea_cooldown - delta, 0.0)
		harvest_tick -= delta
		if harvest_tick <= 0.0:
			harvest_tick = HARVEST_TICK
			_harvest()
		_tick_numbing(delta)
		_hold_snared(delta)
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
			var weapon := staff_of(entry)
			if weapon != null and entry.kind in [Kind.SAGE, Kind.SHRUB]: _shoot(entry, weapon, delta)
			if power("herb_soothe") > 0.0 and entry.at.distance_squared_to(player.global_position) <= SOOTHE_RADIUS * SOOTHE_RADIUS: soothing += 1
		var healed := 0.0
		if soothing > 0: healed = player.stats.heal(SOOTHE_HEAL * mini(soothing, SOOTHE_CAP) * delta)
		var totem := _aura_source(player.global_position)
		var healed_by_totem := 0.0
		if totem.is_finite():
			healed_by_totem = player.stats.heal(TOTEM_HEAL * _ceremony() * delta)
			if power("totem_tea") > 0.0 and tea_cooldown <= 0.0:
				tea_cooldown = TOTEM_TEA
				player.stats.grant_shield(1)
		_healing_feedback(healed + healed_by_totem, totem if healed_by_totem > 0.0 else Vector2.INF, delta)
	super.advance(delta)


func _healing_feedback(amount: float, source: Vector2, delta: float) -> void:
	heal_pulse_left = maxf(heal_pulse_left - delta, 0.0)
	if amount > 0.0:
		heal_pending += amount
		if heal_feedback_left <= 0.0:
			heal_feedback_left = HEAL_FEEDBACK_SECONDS
			heal_pulse_left = HEAL_PULSE_SECONDS
			heal_origin = source
	if heal_feedback_left <= 0.0: return
	heal_feedback_left = maxf(heal_feedback_left - delta, 0.0)
	if heal_feedback_left == 0.0:
		if heal_pending >= 0.05:
			var label := "+%s" % DentiAttributes.number(heal_pending).replace(".", ",")
			items().effect_context.announce(label, player.global_position, HEAL_COLOR)
		heal_pending = 0.0

## Herbs hand their harvest to Denti: loot beside a grown herb flies over.
func _harvest() -> void:
	if plants.is_empty() or not player.combat_active(): return
	var index := player.get_parent().get_node_or_null("Loot") as LootSpatialIndex
	if index == null: return
	for entry in plants:
		if not grown(entry): continue
		for drop in index.in_circle(entry.at, HARVEST_RADIUS):
			if not drop.wave_collecting and drop.kind != &"chest": drop.begin_wave_collection()

# --- Plants in combat -----------------------------------------------------------

func _shoot(entry: Dictionary, weapon: WeaponInstance, delta: float) -> void:
	var interval := (SHRUB_INTERVAL if entry.kind == Kind.SHRUB else SHOT_INTERVAL) * (TOTEM_SHOT_FACTOR if _in_aura(entry.at) else 1.0)
	entry.shot = float(entry.shot) - delta
	if entry.shot > 0.0: return
	var reach := weapon.data.range_at_tier(weapon.tier)
	var targets: Array[Enemy] = []
	var shots := 1 if entry.kind == Kind.SAGE else SHRUB_SHOTS + roundi(power("shrub_seeds"))
	# Focus fire: every herb shoots at the enemies closest to Denti, so threats
	# die instead of many enemies being scratched, and loot falls near Denti.
	var denti := player.global_position
	for enemy in player.nearby_enemies(entry.at, reach):
		if enemy.is_targetable(): targets.append(enemy)
	targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.distance_squared_to(denti) < b.global_position.distance_squared_to(denti))
	if targets.size() > shots: targets.resize(shots)
	if targets.is_empty():
		entry.shot = 0.15
		return
	entry.shot = interval
	var data := _shot_data(weapon.data)
	var pool := player.get_parent().get_node_or_null("Projectiles") as PlayerProjectilePool
	if pool == null: return
	var muzzle: Vector2 = entry.at - Vector2(0, SHRUB_MUZZLE_HEIGHT if entry.kind == Kind.SHRUB else SAGE_MUZZLE_HEIGHT)
	for index in shots:
		var target: Enemy = targets[index % targets.size()]
		var base := data.raw_damage_with_stats(weapon.tier, player.stats) + scaled(power("herb_damage"))
		if entry.kind == Kind.SHRUB: base *= SHRUB_SHARE
		base *= 1.0 + items().power(&"summon_power")
		var damage := player.stats.roll_critical_damage(base, data.crit_bonus, data.crit_multiplier)
		var critical := player.stats.last_roll_critical
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
		# Bosses trample herbs with heavy contact damage instead of instantly.
		damage = maxf(damage, enemy.contact_damage * (BOSS_TRAMPLE if enemy.data.is_boss else 1.0))
	if damage <= 0.0: return
	entry.contact = CONTACT_INTERVAL
	entry.health = maxf(float(entry.health) - damage, 0.0)

func _wilt(entry: Dictionary, natural: bool) -> void:
	var synergies := player.get_parent().get_node_or_null("Synergies") as SynergyItems
	if synergies != null: synergies.on_summon_lost(entry.at)
	if entry.kind == Kind.TOTEM and natural and power("totem_cutting") > 0.0:
		var source := staff_of(entry)
		plants.append({"kind": Kind.SAGE, "at": entry.at, "grow": GROW_SECONDS, "life": lifetime(Kind.SAGE, source), "health": plant_health(source),
			"shot": SHOT_INTERVAL, "contact": 0.0, "staff": str(entry.get("staff", ""))})
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
	return _aura_source(at).is_finite()

func _aura_source(at: Vector2) -> Vector2:
	var radius := totem_radius()
	for entry in plants:
		if entry.kind == Kind.TOTEM and grown(entry) and entry.at.distance_squared_to(at) <= radius * radius: return entry.at
	return Vector2.INF

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
	var glows := {}
	for weapon in staffs(): glows[weapon.instance_uid] = element_color(weapon)
	for entry in plants:
		var glow: Color = glows.get(str(entry.get("staff", "")), Color.TRANSPARENT)
		var at := to_local(entry.at)
		var growth := 1.0 - float(entry.grow) / GROW_SECONDS
		var fade := clampf(float(entry.life), 0.0, 1.0)
		if entry.kind == Kind.TOTEM and grown(entry):
			draw_circle(at, radius, Color(CHAMOMILE, 0.07 * fade))
			draw_arc(at, radius, 0.0, TAU, 48, Color(CHAMOMILE, 0.45 * fade), 2.0, true)
		elif entry.kind == Kind.CLOVE and grown(entry):
			draw_arc(at, CLOVE_RADIUS, 0.0, TAU, 40, Color(CLOVE.lightened(0.3), 0.45 * fade), 2.0, true)
		# Planting: the seed arcs from the staff head, then the soil bursts open.
		if not grown(entry):
			var elapsed := GROW_SECONDS - float(entry.grow)
			var tip: Vector2 = entry.get("tip", Vector2.INF)
			if tip.is_finite(): HerbPlanting.draw_seed(self, to_local(tip), at + Vector2(0, -6), elapsed / HerbPlanting.SEED_SECONDS, glow)
			HerbPlanting.draw_sprout(self, at, (elapsed - HerbPlanting.SEED_SECONDS * 0.5) / (GROW_SECONDS - HerbPlanting.SEED_SECONDS * 0.5), glow, int(entry.get("seed", 0)))
		# The staff's element shows on every herb as a soft ground glow.
		if glow.a > 0.0 and grown(entry):
			draw_circle(at + Vector2(0, -4), 13.0 * DRAW_SCALE, Color(glow, 0.22 * fade))
		# The sprout appears once the seed has landed.
		var in_flight: bool = Vector2(entry.get("tip", Vector2.INF)).is_finite() and GROW_SECONDS - float(entry.grow) < HerbPlanting.SEED_SECONDS * 0.8
		if not in_flight: _draw_plant(at, int(entry.kind), growth, fade)
	if heal_pulse_left > 0.0: _draw_heal_pulse()
	draw_effects()

func _draw_heal_pulse() -> void:
	var age := 1.0 - heal_pulse_left / HEAL_PULSE_SECONDS
	var center := to_local(player.global_position)
	var source := to_local(heal_origin) + Vector2(0, -34) if heal_origin.is_finite() else center + Vector2(0, 16)
	var wave := sin(age * PI)
	var ring_radius := lerpf(19, 36, age)
	draw_set_transform(center + Vector2(0, 28), 0.0, Vector2(1, 0.45))
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(0.2, 0.34, 0.25, wave * 0.6), 5.0, true)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, Color(HEAL_COLOR, wave * 0.92), 3.0, true)
	for index in 5:
		var step := clampf(age * 1.4 - index * 0.09, 0.0, 1.0)
		var fade := sin(step * PI)
		var spread := Vector2.from_angle(index * TAU / 5.0) * 12.0
		var at := source.lerp(center + Vector2(0, -24), step) + (spread + Vector2.UP * 12.0) * fade
		draw_set_transform(at, index * 1.26, Vector2(1.55, 0.85))
		draw_circle(Vector2.ZERO, 3.7, Color(0.41, 0.29, 0.18, fade * 0.85), true, -1.0, true)
		draw_circle(Vector2.ZERO, 2.9, Color(CHAMOMILE, fade), true, -1.0, true)
		draw_circle(Vector2(-0.7, -0.65), 1.25, Color(1, 0.99, 0.92, fade), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)

## Element color of a staff's enchantment, transparent without one.
func element_color(weapon: WeaponInstance = null) -> Color:
	if weapon == null: weapon = staff()
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
			"life": float(entry.life), "health": float(entry.health), "shot": float(entry.shot), "staff": str(entry.get("staff", ""))})
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
		var owner: String = entry.get("staff", "") if entry.get("staff", "") is String else ""
		var source := staff_of({"staff": owner})
		if source != null: owner = source.instance_uid
		plants.append({"kind": kind, "at": SnapshotValues.read_vector(entry.at), "grow": clampf(float(entry.get("grow", 0)), 0.0, GROW_SECONDS),
			"life": clampf(float(entry.get("life", 0)), 0.0, lifetime(kind, source)), "health": clampf(float(entry.get("health", 1)), 0.0, plant_health(source)),
			"shot": clampf(float(entry.get("shot", 0)), 0.0, SHRUB_INTERVAL), "contact": 0.0, "staff": owner})
		if plants.size() >= MAX_SAVED: break
	queue_redraw()
