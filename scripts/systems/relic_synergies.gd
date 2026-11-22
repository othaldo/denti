class_name RelicSynergies
extends RefCounted

## Effects of the synergy relics. Each one builds on a general mechanic
## (dash, loot, poison, fire, slow, wet, shields, crowds, weapon mix) rather
## than on a class skill, so every class can use it and some profit most.
## RelicInventory owns this object and forwards its combat hooks.

# Zahnspange: two different weapons on one enemy within the window.
const BRACE_WINDOW := 0.8
const BRACE_SHARE := 0.4
const BRACE_COOLDOWN := 0.1
const BRACE_TRACKED := 96
# Glockenkrone: a blocked hit makes every weapon attack.
const BELL_COOLDOWN := 3.0
# Schattenseide: the first weapon hit after a dash spreads the target's poison.
const FLOSS_WINDOW := 2.5
const FLOSS_SHARE := 0.5
const FLOSS_TARGETS := 4
const FLOSS_RADIUS := 110.0
const FLOSS_HIT_CAP := 3.0
# Tollkirsche: poisoned enemies close to Denti take more weapon damage.
const BELLADONNA_RADIUS := 160.0
const BELLADONNA_BONUS := 20.0
# Milchzahndose: loot flies to Denti while dashing.
const TIN_RADIUS := 320.0
# Glückspfennig: collected coins may fire a light shard; luck raises the chance.
const PENNY_CHANCE := 0.15
const PENNY_PER_LUCK := 0.005
const PENNY_MAX := 0.6
const PENNY_DAMAGE := 8.0
const PENNY_PER_LUCK_DAMAGE := 0.08
const PENNY_RANGE := 380.0
const PENNY_RATE := 8.0
# Zunderzahn: burning enemies set their neighbours alight on death.
const TINDER_RADIUS := 100.0
const TINDER_TARGETS := 4
const TINDER_SHARE := 0.5
const TINDER_MINIMUM := 4.0
# Hitzestein: weapon damage per enemy around Denti, capped.
const HEAT_RADIUS := 140.0
const HEAT_PER_ENEMY := 3.0
const HEAT_CAP := 24.0
const HEAT_REFRESH := 0.2
# Kupferkrone: a hit on a wet enemy arcs to another wet enemy.
const COPPER_RANGE := 220.0
const COPPER_SHARE := 0.35
const COPPER_COOLDOWN := 0.25
# Mundspülstrudel: a dash draws nearby enemies towards Denti.
const WHIRL_RADIUS := 240.0
const WHIRL_PULL := 70.0
# Eisblume: a slowed enemy dying slows its neighbours.
const FLOWER_RADIUS := 100.0
const FLOWER_TARGETS := 4
const FLOWER_SECONDS := 1.5
# Gletscherherz: slowed elites and bosses take more weapon damage.
const GLACIER_BONUS := 20.0

const GOLD := Color(1.0, 0.84, 0.35)
const POISON := Color(0.43, 1.0, 0.3)
const FIRE := Color(1.0, 0.5, 0.18)
const SPARK := Color(1.0, 0.95, 0.45)
const WATER := Color(0.35, 0.75, 1.0)
const ICE := Color(0.7, 0.92, 1.0)
const LIGHT := Color(1.0, 0.92, 0.55)

var relics: RelicInventory
var clock := 0.0
var brace_hits: Dictionary = {}
var brace_cooldown := 0.0
var bell_cooldown := 0.0
var floss_time := 0.0
var penny_tokens := PENNY_RATE
var heat_count := 0
var heat_refresh := 0.0
var copper_cooldown := 0.0
var tinder_busy := false


func _init(owner: RelicInventory) -> void:
	relics = owner


func player() -> Player:
	return relics.player


func has(id: StringName) -> bool:
	return relics.has_relic(id)


func reset_wave() -> void:
	brace_hits.clear()
	brace_cooldown = 0.0
	bell_cooldown = 0.0
	floss_time = 0.0
	penny_tokens = PENNY_RATE
	heat_count = 0
	heat_refresh = 0.0
	copper_cooldown = 0.0


func advance(delta: float) -> void:
	clock += delta
	brace_cooldown = maxf(brace_cooldown - delta, 0.0)
	bell_cooldown = maxf(bell_cooldown - delta, 0.0)
	floss_time = maxf(floss_time - delta, 0.0)
	copper_cooldown = maxf(copper_cooldown - delta, 0.0)
	penny_tokens = minf(penny_tokens + delta * PENNY_RATE, PENNY_RATE)
	if relics.owned.is_empty() or player() == null: return
	if has(&"heat_stone"):
		heat_refresh -= delta
		if heat_refresh <= 0.0:
			heat_refresh = HEAT_REFRESH
			heat_count = _count_near(player().global_position, HEAT_RADIUS)
	if has(&"milk_tooth_tin") and player().dash.active: _collect_loot()


# --- Hooks -------------------------------------------------------------------

func on_weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, _critical: bool) -> void:
	if amount <= 0.0 or weapon == null: return
	if has(&"dental_brace"): _brace(enemy, amount, weapon)
	if has(&"shadow_floss") and floss_time > 0.0: _floss(enemy, amount)
	if has(&"copper_crown") and copper_cooldown <= 0.0 and enemy.wet_time > 0.0: _copper(enemy, amount)


func on_enemy_died(enemy: Enemy) -> void:
	if has(&"tinder_tooth") and not tinder_busy and enemy.affix_effects.budget(&"fire") > 0.0:
		tinder_busy = true
		_tinder(enemy)
		tinder_busy = false
	if has(&"ice_flower") and enemy.chill_time > 0.0: _flower(enemy)


func on_shield_blocked() -> void:
	if not has(&"bell_crown") or bell_cooldown > 0.0 or not player().combat_active(): return
	var attacked := false
	for weapon in player().loadout.equipped(): attacked = weapon.force_attack(0.0) or attacked
	if attacked:
		bell_cooldown = BELL_COOLDOWN
		relics._ring(player().global_position, 110.0, GOLD)


func on_dash_started() -> void:
	if has(&"shadow_floss"): floss_time = FLOSS_WINDOW
	if has(&"rinse_whirl"): _whirl()


func on_loot_collected(kind: StringName) -> void:
	if kind != &"coin" or not has(&"lucky_penny") or not player().combat_active() or penny_tokens < 1.0: return
	var luck := maxf(player().stats.luck, 0.0)
	if randf() >= clampf(PENNY_CHANCE + luck * PENNY_PER_LUCK, PENNY_CHANCE, PENNY_MAX): return
	var at := player().global_position
	var target := EnemySpatialIndex.nearest(relics.get_tree(), player().enemy_index, at, PENNY_RANGE, true)
	if target == null or target.global_position.distance_squared_to(at) > PENNY_RANGE * PENNY_RANGE: return
	penny_tokens -= 1.0
	var amount := player().stats.roll_critical_damage(player().stats.scale_damage(PENNY_DAMAGE + luck * PENNY_PER_LUCK_DAMAGE), 0.0, 1.5)
	target.take_damage(amount, null, player().stats.last_roll_critical, &"lucky_penny")
	relics._line(at, target.global_position, LIGHT)


## Extra weapon damage in percent points against this enemy.
func weapon_damage_bonus(enemy: Enemy) -> float:
	if relics.owned.is_empty(): return 0.0
	var bonus := 0.0
	if has(&"heat_stone"): bonus += minf(heat_count * HEAT_PER_ENEMY, HEAT_CAP)
	if has(&"belladonna") and _poisoned(enemy) and enemy.global_position.distance_squared_to(player().global_position) <= BELLADONNA_RADIUS * BELLADONNA_RADIUS:
		bonus += BELLADONNA_BONUS
	if has(&"glacier_heart") and (enemy.data.is_elite or enemy.data.is_boss) and _slowed(enemy): bonus += GLACIER_BONUS
	return bonus


# --- Effects -----------------------------------------------------------------

func _brace(enemy: Enemy, amount: float, weapon: WeaponData) -> void:
	var id := enemy.get_instance_id()
	var last: Dictionary = brace_hits.get(id, {})
	if not last.is_empty() and last.weapon != weapon.id and clock - float(last.time) <= BRACE_WINDOW and brace_cooldown <= 0.0 and enemy.health > 0.0:
		brace_cooldown = BRACE_COOLDOWN
		brace_hits.erase(id)
		enemy.take_damage(amount * BRACE_SHARE, null, false, &"dental_brace")
		relics._ring(enemy.global_position, enemy.data.radius + 18.0, GOLD)
		return
	if brace_hits.size() >= BRACE_TRACKED and not brace_hits.has(id): brace_hits.clear()
	brace_hits[id] = {"weapon": weapon.id, "time": clock}


func _floss(enemy: Enemy, amount: float) -> void:
	floss_time = 0.0
	var poison := _poison(enemy)
	if poison <= 0.0: return
	var share := minf(poison * FLOSS_SHARE, amount * FLOSS_HIT_CAP)
	var spread := 0
	for other in player().nearby_enemies(enemy.global_position, FLOSS_RADIUS):
		if spread >= FLOSS_TARGETS: break
		if other == enemy or not other.is_targetable(): continue
		var additions: Array[Dictionary] = [{"id": "poison", "damage": share, "proc_id": "shadow_floss"}]
		other.take_damage(0, null, false, &"shadow_floss", additions)
		relics._line(enemy.global_position, other.global_position, POISON)
		spread += 1


func _copper(enemy: Enemy, amount: float) -> void:
	var at := enemy.global_position
	var target: Enemy = null
	var best := COPPER_RANGE * COPPER_RANGE
	for other in player().nearby_enemies(at, COPPER_RANGE):
		if other == enemy or not other.is_targetable() or other.wet_time <= 0.0: continue
		var distance := at.distance_squared_to(other.global_position)
		if distance < best:
			best = distance
			target = other
	if target == null: return
	copper_cooldown = COPPER_COOLDOWN
	target.take_damage(amount * COPPER_SHARE, null, false, &"copper_crown")
	relics._line(at, target.global_position, SPARK)


func _tinder(enemy: Enemy) -> void:
	var burn := maxf(enemy.affix_effects.budget(&"fire") * TINDER_SHARE, player().stats.scale_damage(TINDER_MINIMUM))
	var lit := 0
	for other in player().nearby_enemies(enemy.global_position, TINDER_RADIUS):
		if lit >= TINDER_TARGETS: break
		if other == enemy or not other.is_targetable(): continue
		var additions: Array[Dictionary] = [{"id": "fire", "damage": burn, "proc_id": "tinder_tooth"}]
		other.take_damage(0, null, false, &"tinder_tooth", additions)
		lit += 1
	if lit > 0: relics._ring(enemy.global_position, TINDER_RADIUS, FIRE)


func _flower(enemy: Enemy) -> void:
	var slowed := 0
	for other in player().nearby_enemies(enemy.global_position, FLOWER_RADIUS):
		if slowed >= FLOWER_TARGETS: break
		if other == enemy or not other.is_targetable(): continue
		other.chill_time = maxf(other.chill_time, FLOWER_SECONDS)
		relics._line(enemy.global_position, other.global_position, ICE)
		slowed += 1


func _whirl() -> void:
	var at := player().global_position
	var moved := 0
	for enemy in player().nearby_enemies(at, WHIRL_RADIUS):
		if not enemy.is_targetable(): continue
		var offset := (at - enemy.global_position).limit_length(WHIRL_PULL)
		enemy.global_position += offset * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))
		moved += 1
	if moved > 0: relics._ring(at, WHIRL_RADIUS, WATER)


func _collect_loot() -> void:
	var index := relics.get_node_or_null("../Loot") as LootSpatialIndex
	if index == null: return
	for drop in index.in_circle(player().global_position, TIN_RADIUS):
		if not drop.wave_collecting: drop.begin_wave_collection()


# --- Helpers -----------------------------------------------------------------

func _poison(enemy: Enemy) -> float:
	return enemy.affix_effects.budget(&"poison") + enemy.affix_effects.depot.budget()


func _poisoned(enemy: Enemy) -> bool:
	return _poison(enemy) > 0.0


func _slowed(enemy: Enemy) -> bool:
	return enemy.chill_time > 0.0 or enemy.affix_effects.depot.nerve_time > 0.0


func _count_near(at: Vector2, radius: float) -> int:
	var count := 0
	for enemy in player().nearby_enemies(at, radius):
		if enemy.is_targetable(): count += 1
	return count
