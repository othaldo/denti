class_name EmberSkills
extends ClassSkillModule

## Glutzahn: "Heiß gelaufen". Weapon hits and crowds around Denti build heat.
## At full heat Denti erupts: a fire nova that grows with the number of nearby
## enemies, followed by a short overheat with slower attacks.
## Skills: Glutkern (eruption leaves burning ground), Druckablass (dash vents
## heat early), Glühende Haut (high heat burns enemies touching Denti).

const MAX_HEAT := 100.0
const HIT_HEAT := 2.5
const HIT_HEAT_CAP := 25.0
const CROWD_HEAT := 8.0
const CROWD_RADIUS := 120.0
const CROWD_COUNT := 3
const ERUPTION_RADIUS := 140.0
const ERUPTION_BASE := 20.0
const ERUPTION_PER_ENEMY := 7.0
const ERUPTION_COUNT_CAP := 12
const ERUPTION_BURN := 0.5
const OVERHEAT_SECONDS := 2.0
const OVERHEAT_INTERVAL := 1.4
const RANGED_PENALTY := -20.0
const CORE_RADIUS := 110.0
const CORE_SECONDS := 3.0
const CORE_LINGER := 2.0
const CORE_TICK := 0.5
const CORE_BURN := 6.0
const CORE_HEAT := 4.0
const CORE_FORGE := 15.0
const SPARKS := 6
const SPARK_RANGE := 400.0
const SPARK_SHARE := 0.4
const VENT_HEAT := 50.0
const VENT_CHARGE := 50.0
const SKIN_HEAT := 60.0
const SKIN_ASBESTOS := 40.0
const SKIN_RADIUS := 48.0
const SKIN_TICK := 0.5
const SKIN_BURN := 8.0
const SKIN_HEAL_CAP := 3
const DASH_HEAT := 15.0
## Vulkanherz: heat kept per nova kill, capped so it never erupts on its own.
const VOLCANO_HEAT := 10.0
const VOLCANO_CAP := 60.0
## Glutzange: share of a weapon hit added as burn while overheated.
const TONGS_BURN := 0.4
const EMBER := Color(1.0, 0.5, 0.18)
const HOT := Color(1.0, 0.25, 0.15)
const CORE_STYLE: SkillCloudStyle = preload("res://data/vfx/skill_clouds/ember.tres")

var heat := 0.0
var overheat := 0.0
var hit_heat_window := 0.0
var cores: Array[Dictionary] = []
var skin_tick := 0.0
var clock := 0.0

func class_id() -> StringName:
	return &"ember"

func reset_wave() -> void:
	super.reset_wave()
	heat = 0.0
	overheat = 0.0
	hit_heat_window = 0.0
	cores.clear()
	skin_tick = 0.0

func gain_factor() -> float:
	var factor := 1.0 + 0.25 * power("ember_tinder")
	if power("ember_overpressure") > 0.0: factor *= 1.5
	if power("ember_lava") > 0.0: factor *= 0.8
	return factor

func add_heat(amount: float) -> void:
	if overheat > 0.0: return
	heat = minf(heat + amount * gain_factor(), MAX_HEAT)
	if heat >= MAX_HEAT: erupt(1.0, true)

func eruption_radius() -> float:
	return ERUPTION_RADIUS * (1.5 if power("ember_wildfire") > 0.0 else 1.0)

func overheat_seconds() -> float:
	var seconds := OVERHEAT_SECONDS + (1.5 if power("ember_wildfire") > 0.0 else 0.0) - power("ember_cooling")
	return maxf(seconds, 0.5)

## Fire nova around Denti; stronger the more enemies stand inside.
func erupt(strength: float, overheats: bool) -> void:
	var at := player.global_position
	var radius := eruption_radius()
	var targets: Array[Enemy] = []
	for enemy in player.nearby_enemies(at, radius):
		if enemy.is_targetable(): targets.append(enemy)
	var amount := scaled((ERUPTION_BASE + ERUPTION_PER_ENEMY * mini(targets.size(), ERUPTION_COUNT_CAP)) * strength * (1.0 + 0.25 * power("ember_accelerant")))
	for enemy in targets:
		var burn: Array[Dictionary] = [{"id": "fire", "damage": amount * ERUPTION_BURN, "proc_id": "class_ember"}]
		enemy.take_damage(amount, null, false, &"class_ember", burn)
	if power("skill_core") > 0.0:
		cores.append({"at": at, "time": CORE_SECONDS + (CORE_LINGER if power("core_linger") > 0.0 else 0.0), "tick": 0.0})
		while cores.size() > 3: cores.pop_front()
	if power("core_sparks") > 0.0: _sparks(amount * SPARK_SHARE)
	heat = 0.0
	if relic(&"ember_volcano_heart"):
		var kills := targets.filter(func(enemy: Enemy) -> bool: return enemy.health <= 0.0).size()
		heat = minf(kills * VOLCANO_HEAT, VOLCANO_CAP)
	if overheats: overheat = overheat_seconds()
	flash(at, radius, EMBER)
	ElementImpactBatch.emit_from(player, &"fire", at, Vector2.RIGHT, radius, true)
	support(&"class_ember_eruptions")

## Funkenflug: sparks fly to up to six enemies around Denti.
func _sparks(amount: float) -> void:
	var count := 0
	for enemy in player.nearby_enemies(player.global_position, SPARK_RANGE):
		if count >= SPARKS: return
		if not enemy.is_targetable(): continue
		enemy.take_damage(amount, null, false, &"class_ember")
		beam(player.global_position, enemy.global_position, EMBER, 2.5)
		count += 1

func on_weapon_hit(enemy: Enemy, _weapon: WeaponData, dealt: float) -> void:
	if not active() or dealt <= 0.0: return
	if overheat > 0.0 and relic(&"ember_tongs") and enemy.health > 0.0:
		var burn: Array[Dictionary] = [{"id": "fire", "damage": dealt * TONGS_BURN, "proc_id": "ember_tongs"}]
		enemy.take_damage(0, null, false, &"ember_tongs", burn)
	if hit_heat_window >= HIT_HEAT_CAP: return
	hit_heat_window += HIT_HEAT
	add_heat(HIT_HEAT)

## Druckablass: a dash at half heat or more vents an early eruption.
func on_dash_started() -> void:
	if not active(): return
	if power("ember_dash_heat") > 0.0: add_heat(DASH_HEAT * power("ember_dash_heat"))
	if power("skill_vent") <= 0.0 or heat < VENT_HEAT or overheat > 0.0: return
	erupt(1.0 if power("vent_whistle") > 0.0 else 0.5, power("vent_valve") <= 0.0)
	if power("vent_steam") > 0.0: player.dash.charge = minf(player.dash.capacity, player.dash.charge + VENT_CHARGE)
	support(&"class_ember_vents")

func damage_bonus(_enemy: Enemy, weapon: WeaponData) -> float:
	return RANGED_PENALTY if active() and not WeaponMotion.is_contact(weapon) else 0.0

func weapon_interval_factor(_weapon: WeaponInstance) -> float:
	return OVERHEAT_INTERVAL if active() and overheat > 0.0 else 1.0

func attack_speed_bonus() -> float:
	return CORE_FORGE if active() and power("core_forge") > 0.0 and _in_core() else 0.0

func _in_core() -> bool:
	for core in cores:
		if player.global_position.distance_squared_to(core.at) <= CORE_RADIUS * CORE_RADIUS: return true
	return false

func advance(delta: float) -> void:
	clock += delta
	if active():
		hit_heat_window = maxf(hit_heat_window - HIT_HEAT_CAP * delta, 0.0)
		if overheat > 0.0:
			overheat = maxf(overheat - delta, 0.0)
		else:
			var crowd := 0
			for enemy in player.nearby_enemies(player.global_position, CROWD_RADIUS):
				if enemy.is_targetable(): crowd += 1
			if crowd >= CROWD_COUNT: add_heat(CROWD_HEAT * delta)
			if _in_core(): add_heat(CORE_HEAT * delta)
		_tick_cores(delta)
		_tick_skin(delta)
	super.advance(delta)

func _tick_cores(delta: float) -> void:
	for index in range(cores.size() - 1, -1, -1):
		var core := cores[index]
		core.time -= delta
		core.tick -= delta
		if core.tick <= 0.0 and core.time > 0.0:
			core.tick = CORE_TICK
			for enemy in player.nearby_enemies(core.at, CORE_RADIUS):
				if not enemy.is_targetable(): continue
				var burn: Array[Dictionary] = [{"id": "fire", "damage": scaled(CORE_BURN), "proc_id": "class_ember"}]
				enemy.take_damage(0, null, false, &"class_ember", burn)
		if core.time <= 0.0: cores.remove_at(index)

## Glühende Haut: at high heat, enemies touching Denti catch fire.
func _tick_skin(delta: float) -> void:
	if power("skill_skin") <= 0.0: return
	var threshold := SKIN_ASBESTOS if power("skin_asbestos") > 0.0 else SKIN_HEAT
	if heat < threshold: return
	skin_tick -= delta
	if skin_tick > 0.0: return
	skin_tick = SKIN_TICK
	var burned := 0
	for enemy in player.nearby_enemies(player.global_position, SKIN_RADIUS):
		if not enemy.is_targetable(): continue
		var burn: Array[Dictionary] = [{"id": "fire", "damage": scaled(SKIN_BURN), "proc_id": "class_ember"}]
		enemy.take_damage(0, null, false, &"class_ember", burn)
		burned += 1
	if burned > 0 and power("skin_slag") > 0.0: player.stats.heal(float(mini(burned, SKIN_HEAL_CAP)))

func _draw() -> void:
	for core in cores:
		var fade := clampf(float(core.time), 0.0, 1.0)
		# Smoke with rising embers; the ring keeps the exact heat radius.
		var remaining := float(core.time)
		var total := CORE_SECONDS + (CORE_LINGER if power("core_linger") > 0.0 else 0.0)
		SkillPuffs.draw_cloud(self, to_local(core.at), CORE_RADIUS, CORE_STYLE, maxf(total - remaining, 0.0), remaining, SkillPuffs.seed_for(core.at))
		draw_arc(to_local(core.at), CORE_RADIUS, 0.0, TAU, 40, Color(EMBER, 0.55 * fade), 2.0, true)
	if active() and player != null:
		# Heat gauge as a ring around Denti: readable without a new HUD element.
		var centre := to_local(player.global_position)
		draw_arc(centre, 34.0, 0.0, TAU, 40, Color(0.2, 0.1, 0.1, 0.35), 4.0, true)
		if overheat > 0.0:
			var pulse := 0.5 + 0.5 * sin(clock * 14.0)
			draw_arc(centre, 34.0, 0.0, TAU, 40, Color(HOT, 0.5 + 0.4 * pulse), 4.0, true)
		elif heat > 0.0:
			draw_arc(centre, 34.0, -PI * 0.5, -PI * 0.5 + TAU * heat / MAX_HEAT, 40, EMBER.lerp(HOT, heat / MAX_HEAT), 4.0, true)
	draw_effects()

func save_data() -> Dictionary:
	var saved_cores: Array = []
	for core in cores: saved_cores.append({"at": SnapshotValues.vector_data(core.at), "time": float(core.time), "tick": float(core.tick)})
	return {"heat": heat, "overheat": overheat, "cores": saved_cores}

func restore(saved: Dictionary) -> void:
	reset_wave()
	heat = clampf(float(saved.get("heat", 0.0)), 0.0, MAX_HEAT)
	overheat = clampf(float(saved.get("overheat", 0.0)), 0.0, OVERHEAT_SECONDS + 1.5)
	for core in saved.get("cores", []):
		if core is Dictionary and SnapshotValues.is_vector(core.get("at")):
			cores.append({"at": SnapshotValues.read_vector(core.at), "time": clampf(float(core.get("time", 0)), 0.0, CORE_SECONDS + CORE_LINGER), "tick": clampf(float(core.get("tick", 0)), 0.0, CORE_TICK)})
