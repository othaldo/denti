class_name FairySkills
extends ClassSkillModule

## Zahnfee: "Für jeden Zahn eine Münze". Barely any loot magnet; every piece
## of loot collected during combat fires a light shard at the nearest enemy.
## Skills: Feenstaub (light rain every n pickups), Kopfgeld (elite/boss hits
## drop extra coins), Zahnkissen (pickups grant shields).

const SHARD_BASE := 8.0
const SHARD_PER_LUCK := 0.08
const SHARD_RANGE := 380.0
const SHARD_BOUNCE_RANGE := 160.0
const SHARD_RATE := 8.0
const MAGNET := 0.35
const GREED_MAGNET := 0.6
const STARDUST_EVERY := 20
const STARDUST_TARGETS := 12
const STARDUST_FACTOR := 3.0
const STARDUST_RADIUS := 900.0
const STARDUST_HEAL := 5.0
const BOUNTY_INTERVAL := 3.0
const BOUNTY_FAST := 2.0
const BOUNTY_CAP := 15
const BOUNTY_SHARDS := 3
const PILLOW_EVERY := 25
const PILLOW_FAST := 15
const PILLOW_PUSH := 60.0
const PILLOW_RADIUS := 120.0
const LIGHT := Color(1.0, 0.92, 0.55)

var tokens := SHARD_RATE
var pickups := 0
var pillow_pickups := 0
var bounty_time := 0.0
var bounty_paid := 0

func class_id() -> StringName:
	return &"tooth_fairy"

func reset_wave() -> void:
	super.reset_wave()
	tokens = SHARD_RATE
	pickups = 0
	pillow_pickups = 0
	bounty_time = 0.0
	bounty_paid = 0

func pickup_factor() -> float:
	if not active(): return 1.0
	return MAGNET * (GREED_MAGNET if power("fairy_greed") > 0.0 else 1.0)

func shard_damage() -> float:
	var base := SHARD_BASE + power("fairy_shard") + maxf(player.stats.luck, 0.0) * SHARD_PER_LUCK
	if power("fairy_glitter") > 0.0: base *= 1.5
	return scaled(base)

## One light shard at the nearest enemy; may crit like a weapon hit.
func shard(from: Vector2, factor: float = 1.0, guaranteed_crit: bool = false) -> bool:
	if tokens < 1.0: return false
	var target := nearest_enemy(from, SHARD_RANGE)
	if target == null: return false
	tokens -= 1.0
	_hit(target, from, factor, guaranteed_crit)
	if power("fairy_pierce") > 0.0:
		var next := nearest_enemy(target.global_position, SHARD_BOUNCE_RANGE, target)
		if next != null: _hit(next, target.global_position, factor * 0.6, false)
	return true

func _hit(target: Enemy, from: Vector2, factor: float, guaranteed_crit: bool) -> void:
	var amount := player.stats.roll_critical_damage(shard_damage() * factor, 0.0, 1.5, guaranteed_crit)
	target.take_damage(amount, null, player.stats.last_roll_critical, &"class_fairy")
	beam(from, target.global_position, LIGHT)
	ElementImpactBatch.emit_from(target, &"electric", target.global_position, from.direction_to(target.global_position), 22)
	support(&"class_fairy_shards")

func on_loot_collected(kind: StringName, _amount: int, drop: Loot) -> void:
	if not active() or not player.combat_active(): return
	var shots := 1
	if kind == &"coin" and power("fairy_coin_double") > 0.0: shots += 1
	var bounty := drop != null and str(drop.reward_data.get("source", "")) == "fairy_bounty"
	if bounty and power("bounty_gold") > 0.0: shots = BOUNTY_SHARDS
	for shot in shots: shard(player.global_position)
	pickups += 1
	if power("skill_stardust") > 0.0 and pickups >= stardust_every():
		pickups = 0
		stardust()
	if power("skill_pillow") > 0.0:
		pillow_pickups += 1
		if pillow_pickups >= (PILLOW_FAST if power("pillow_feather") > 0.0 else PILLOW_EVERY):
			pillow_pickups = 0
			pillow()

func stardust_every() -> int:
	return maxi(STARDUST_EVERY - roundi(power("stardust_every")), 5)

## Feenstaub: light rain on up to twelve enemies across the arena.
func stardust() -> void:
	var hits := 0
	for enemy in player.nearby_enemies(player.global_position, STARDUST_RADIUS):
		if hits >= STARDUST_TARGETS: break
		if not enemy.is_targetable(): continue
		_hit(enemy, enemy.global_position + Vector2(0, -160), STARDUST_FACTOR, power("stardust_crit") > 0.0)
		hits += 1
	if power("stardust_heal") > 0.0: player.stats.heal(STARDUST_HEAL)
	flash(player.global_position, 160.0, LIGHT)
	support(&"class_fairy_stardust")

## Zahnkissen: a shield from collected loot, Nachtwache shoves enemies away.
func pillow() -> void:
	player.stats.grant_shield(1)
	if power("pillow_guard") > 0.0: push_from(player.global_position, PILLOW_RADIUS, PILLOW_PUSH)
	flash(player.global_position, PILLOW_RADIUS, DentiUIStyle.CREAM)
	support(&"class_fairy_pillows")

## Kopfgeld: hits on elites and bosses drop a small extra coin.
func on_weapon_hit(enemy: Enemy, _weapon: WeaponData, dealt: float) -> void:
	if not active() or power("skill_bounty") <= 0.0 or dealt <= 0.0: return
	if not (enemy.data.is_elite or enemy.data.is_boss) or bounty_time > 0.0: return
	if bounty_paid >= BOUNTY_CAP + roundi(power("bounty_cap")): return
	bounty_time = BOUNTY_FAST if power("bounty_rate") > 0.0 else BOUNTY_INTERVAL
	bounty_paid += 1
	player.get_parent()._spawn_loot(enemy.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)), &"coin", 1, &"", {"source": "fairy_bounty"})
	support(&"class_fairy_bounty")

func advance(delta: float) -> void:
	tokens = minf(tokens + delta * SHARD_RATE, SHARD_RATE)
	bounty_time = maxf(bounty_time - delta, 0.0)
	super.advance(delta)

func save_data() -> Dictionary:
	return {"pickups": pickups, "pillow_pickups": pillow_pickups, "bounty_time": bounty_time, "bounty_paid": bounty_paid}

func restore(saved: Dictionary) -> void:
	reset_wave()
	pickups = clampi(int(saved.get("pickups", 0)), 0, STARDUST_EVERY)
	pillow_pickups = clampi(int(saved.get("pillow_pickups", 0)), 0, PILLOW_EVERY)
	bounty_time = clampf(float(saved.get("bounty_time", 0.0)), 0.0, BOUNTY_INTERVAL)
	bounty_paid = clampi(int(saved.get("bounty_paid", 0)), 0, 100)
