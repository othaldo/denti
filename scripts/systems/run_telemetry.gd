class_name RunTelemetry
extends RefCounted

const WINDOW := 10.0

var elapsed: float = 0.0
var total_damage: float = 0.0
var damage_taken: float = 0.0
var dodges: int = 0
var wave_dodges: int = 0
var status_damage: Dictionary = {}
var status_applications: Dictionary = {}
var wave_status_damage: Dictionary = {}
var wave_status_applications: Dictionary = {}
var kills: int = 0
var bosses_defeated: int = 0
var coins_collected: int = 0
var xp_collected: int = 0
var chests_found: int = 0
var chests_kept: int = 0
var chests_scrapped: int = 0
var weapon_damage: Dictionary = {}
var proc_damage: Dictionary = {}
var other_damage: float = 0.0
var peak_dps: float = 0.0
var current_wave: int = 0
var current_profile_id: StringName = &""
var wave_started_at: float = 0.0
var wave_history: Array[Dictionary] = []
var wave_spawns: int = 0
var wave_spawns_blocked: int = 0
var wave_kills: int = 0
var wave_elites_spawned: int = 0
var wave_elites_killed: int = 0
var wave_coins: int = 0
var wave_xp: int = 0
var wave_gold_sources: Dictionary = {}
var wave_shop_spending: Dictionary = {}
var wave_chests_found: int = 0
var wave_chests_kept: int = 0
var wave_chests_scrapped: int = 0
var wave_damage: float = 0.0
var wave_taken: float = 0.0
var wave_peak_dps: float = 0.0
var wave_boss_ttk: float = 0.0
var wave_peak_enemies: int = 0
var wave_enemy_seconds: float = 0.0
var wave_peak_enemy_projectiles: int = 0
var boss_started_at: float = -1.0
var last_boss_ttk: float = 0.0
var damage_events: Array[Dictionary] = []
var kill_events: Array[float] = []
var taken_events: Array[Dictionary] = []
var recent_damage: float = 0.0
var recent_taken: float = 0.0
var damage_head: int = 0
var kill_head: int = 0
var taken_head: int = 0


func begin_wave(number: int, profile_id: StringName = &"") -> void:
	if current_wave > 0:
		wave_history.append(current_wave_summary())
	current_wave = number
	current_profile_id = profile_id
	wave_started_at = elapsed
	wave_spawns = 0
	wave_spawns_blocked = 0
	wave_kills = 0
	wave_elites_spawned = 0
	wave_elites_killed = 0
	wave_coins = 0
	wave_xp = 0
	wave_gold_sources.clear()
	wave_shop_spending.clear()
	wave_chests_found = 0
	wave_chests_kept = 0
	wave_chests_scrapped = 0
	wave_damage = 0.0
	wave_taken = 0.0
	wave_dodges = 0
	wave_status_damage.clear()
	wave_status_applications.clear()
	wave_peak_dps = 0.0
	wave_boss_ttk = 0.0
	wave_peak_enemies = 0
	wave_enemy_seconds = 0.0
	wave_peak_enemy_projectiles = 0
	damage_events.clear()
	kill_events.clear()
	taken_events.clear()
	recent_damage = 0.0
	recent_taken = 0.0
	damage_head = 0
	kill_head = 0
	taken_head = 0


func tick(delta: float, enemies_alive: int = 0, enemy_projectiles: int = 0) -> void:
	elapsed += delta
	wave_peak_enemies = maxi(wave_peak_enemies, enemies_alive)
	wave_enemy_seconds += float(enemies_alive) * delta
	wave_peak_enemy_projectiles = maxi(wave_peak_enemy_projectiles, enemy_projectiles)
	_prune_events()
	var dps := recent_dps()
	peak_dps = maxf(peak_dps, dps)
	wave_peak_dps = maxf(wave_peak_dps, dps)


func record_spawn(is_boss: bool, is_elite: bool = false) -> void:
	wave_spawns += 1
	if is_elite:
		wave_elites_spawned += 1
	if is_boss:
		boss_started_at = elapsed


func record_spawn_blocked(count: int = 1) -> void:
	wave_spawns_blocked += count


func record_damage(amount: float, weapon_id: StringName = &"", proc_id: StringName = &"") -> void:
	if amount <= 0.0:
		return
	total_damage += amount
	wave_damage += amount
	recent_damage += amount
	_append_amount(damage_events, amount)
	if weapon_id != &"":
		var key := str(weapon_id)
		weapon_damage[key] = float(weapon_damage.get(key, 0.0)) + amount
	elif proc_id != &"":
		var key := str(proc_id)
		proc_damage[key] = float(proc_damage.get(key, 0.0)) + amount
	else:
		other_damage += amount
	var dps := recent_dps()
	peak_dps = maxf(peak_dps, dps)
	wave_peak_dps = maxf(wave_peak_dps, dps)


func record_kill(is_boss: bool, is_elite: bool = false) -> void:
	kills += 1
	wave_kills += 1
	if is_elite:
		wave_elites_killed += 1
	kill_events.append(elapsed)
	if is_boss:
		bosses_defeated += 1


func record_boss_death() -> void:
	if boss_started_at >= 0.0:
		last_boss_ttk = elapsed - boss_started_at
		wave_boss_ttk = last_boss_ttk
		boss_started_at = -1.0


func record_dodge() -> void:
	dodges += 1
	wave_dodges += 1


func record_status_applied(kind: DentiStatus.Type) -> void:
	var key: String = DentiStatus.KEYS[kind]
	status_applications[key] = int(status_applications.get(key, 0)) + 1
	wave_status_applications[key] = int(wave_status_applications.get(key, 0)) + 1


func record_status_damage(kind: DentiStatus.Type, amount: float) -> void:
	var key: String = DentiStatus.KEYS[kind]
	status_damage[key] = float(status_damage.get(key, 0.0)) + amount
	wave_status_damage[key] = float(wave_status_damage.get(key, 0.0)) + amount


func record_taken(amount: float) -> void:
	if amount <= 0.0:
		return
	damage_taken += amount
	wave_taken += amount
	recent_taken += amount
	_append_amount(taken_events, amount)


func record_loot(kind: StringName, amount: int, source: StringName = &"drop") -> void:
	if kind == &"coin":
		coins_collected += amount
		wave_coins += amount
		if amount > 0:
			wave_gold_sources[str(source)] = int(wave_gold_sources.get(str(source), 0)) + amount
	elif kind == &"xp":
		xp_collected += amount
		wave_xp += amount


func record_shop_spending(kind: StringName, amount: int) -> void:
	if amount > 0:
		wave_shop_spending[str(kind)] = int(wave_shop_spending.get(str(kind), 0)) + amount


func record_chest_found() -> void:
	chests_found += 1
	wave_chests_found += 1


func record_chest_kept() -> void:
	chests_kept += 1
	wave_chests_kept += 1


func record_chest_scrapped() -> void:
	chests_scrapped += 1
	wave_chests_scrapped += 1


func recent_dps() -> float:
	return recent_damage / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func recent_kps() -> float:
	return float(kill_events.size() - kill_head) / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func spawns_per_minute() -> float:
	return float(wave_spawns) * 60.0 / maxf(elapsed - wave_started_at, 1.0)


func taken_per_minute() -> float:
	return recent_taken * 60.0 / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func current_wave_summary() -> Dictionary:
	var duration := maxf(elapsed - wave_started_at, 0.0)
	return {
		"wave": current_wave, "profile_id": str(current_profile_id), "combat_seconds": duration,
		"endless_factor": EndlessRules.factor(current_wave),
		"spawns": wave_spawns, "spawns_blocked": wave_spawns_blocked, "kills": wave_kills,
		"elites_spawned": wave_elites_spawned, "elites_killed": wave_elites_killed,
		"peak_enemies_alive": wave_peak_enemies, "average_enemies_alive": wave_enemy_seconds / maxf(duration, 1.0),
		"peak_enemy_projectiles": wave_peak_enemy_projectiles,
		"damage_dealt": wave_damage, "average_dps": wave_damage / maxf(duration, 1.0),
		"peak_dps": wave_peak_dps, "damage_taken": wave_taken,
		"dodges": wave_dodges,
		"status_damage": wave_status_damage.duplicate(), "status_applications": wave_status_applications.duplicate(),
		"coins_collected": wave_coins, "xp_collected": wave_xp,
		"gold_sources": wave_gold_sources.duplicate(), "shop_spending": wave_shop_spending.duplicate(),
		"chests_found": wave_chests_found, "chests_kept": wave_chests_kept, "chests_scrapped": wave_chests_scrapped,
		"boss_ttk": wave_boss_ttk,
	}


func wave_summaries() -> Array[Dictionary]:
	var result := wave_history.duplicate(true)
	if current_wave > 0:
		result.append(current_wave_summary())
	return result


func save_data() -> Dictionary:
	return {
		"elapsed": elapsed, "total_damage": total_damage, "damage_taken": damage_taken,
		"dodges": dodges, "wave_dodges": wave_dodges,
		"status_damage": status_damage.duplicate(), "status_applications": status_applications.duplicate(),
		"wave_status_damage": wave_status_damage.duplicate(), "wave_status_applications": wave_status_applications.duplicate(),
		"kills": kills, "bosses_defeated": bosses_defeated,
		"coins_collected": coins_collected, "xp_collected": xp_collected,
		"chests_found": chests_found, "chests_kept": chests_kept, "chests_scrapped": chests_scrapped,
		"weapon_damage": weapon_damage.duplicate(), "proc_damage": proc_damage.duplicate(),
		"other_damage": other_damage, "peak_dps": peak_dps,
		"current_wave": current_wave, "current_profile_id": str(current_profile_id), "wave_started_at": wave_started_at,
		"wave_history": wave_history.duplicate(true),
		"wave_spawns": wave_spawns, "wave_spawns_blocked": wave_spawns_blocked,
		"wave_kills": wave_kills, "wave_elites_spawned": wave_elites_spawned,
		"wave_elites_killed": wave_elites_killed,
		"wave_coins": wave_coins, "wave_xp": wave_xp,
		"wave_gold_sources": wave_gold_sources.duplicate(), "wave_shop_spending": wave_shop_spending.duplicate(),
		"wave_chests_found": wave_chests_found, "wave_chests_kept": wave_chests_kept,
		"wave_chests_scrapped": wave_chests_scrapped,
		"wave_damage": wave_damage, "wave_taken": wave_taken,
		"wave_peak_dps": wave_peak_dps, "wave_boss_ttk": wave_boss_ttk,
		"wave_peak_enemies": wave_peak_enemies, "wave_enemy_seconds": wave_enemy_seconds,
		"wave_peak_enemy_projectiles": wave_peak_enemy_projectiles,
		"boss_started_at": boss_started_at, "last_boss_ttk": last_boss_ttk,
		"damage_events": damage_events.slice(damage_head).duplicate(true), "kill_events": kill_events.slice(kill_head),
		"taken_events": taken_events.slice(taken_head).duplicate(true),
	}


func restore(saved: Dictionary, wave_number: int) -> void:
	elapsed = maxf(float(saved.get("elapsed", 0.0)), 0.0)
	total_damage = maxf(float(saved.get("total_damage", 0.0)), 0.0)
	damage_taken = maxf(float(saved.get("damage_taken", 0.0)), 0.0)
	dodges = maxi(int(saved.get("dodges", 0)), 0)
	wave_dodges = maxi(int(saved.get("wave_dodges", 0)), 0)
	status_damage = saved.get("status_damage", {}).duplicate()
	status_applications = saved.get("status_applications", {}).duplicate()
	wave_status_damage = saved.get("wave_status_damage", {}).duplicate()
	wave_status_applications = saved.get("wave_status_applications", {}).duplicate()
	kills = maxi(int(saved.get("kills", 0)), 0)
	bosses_defeated = maxi(int(saved.get("bosses_defeated", 0)), 0)
	coins_collected = maxi(int(saved.get("coins_collected", 0)), 0)
	xp_collected = maxi(int(saved.get("xp_collected", 0)), 0)
	chests_found = maxi(int(saved.get("chests_found", 0)), 0)
	chests_kept = maxi(int(saved.get("chests_kept", 0)), 0)
	chests_scrapped = maxi(int(saved.get("chests_scrapped", 0)), 0)
	weapon_damage = saved.get("weapon_damage", {}).duplicate()
	proc_damage = saved.get("proc_damage", {}).duplicate()
	other_damage = maxf(float(saved.get("other_damage", 0.0)), 0.0)
	peak_dps = maxf(float(saved.get("peak_dps", 0.0)), 0.0)
	current_wave = maxi(int(saved.get("current_wave", wave_number)), 0)
	current_profile_id = StringName(str(saved.get("current_profile_id", "")))
	wave_started_at = clampf(float(saved.get("wave_started_at", elapsed)), 0.0, elapsed)
	wave_history.assign(saved.get("wave_history", []))
	wave_spawns = maxi(int(saved.get("wave_spawns", 0)), 0)
	wave_spawns_blocked = maxi(int(saved.get("wave_spawns_blocked", 0)), 0)
	wave_kills = maxi(int(saved.get("wave_kills", 0)), 0)
	wave_elites_spawned = maxi(int(saved.get("wave_elites_spawned", 0)), 0)
	wave_elites_killed = maxi(int(saved.get("wave_elites_killed", 0)), 0)
	wave_coins = maxi(int(saved.get("wave_coins", 0)), 0)
	wave_xp = maxi(int(saved.get("wave_xp", 0)), 0)
	wave_gold_sources = saved.get("wave_gold_sources", {}).duplicate()
	wave_shop_spending = saved.get("wave_shop_spending", {}).duplicate()
	wave_chests_found = maxi(int(saved.get("wave_chests_found", 0)), 0)
	wave_chests_kept = maxi(int(saved.get("wave_chests_kept", 0)), 0)
	wave_chests_scrapped = maxi(int(saved.get("wave_chests_scrapped", 0)), 0)
	wave_damage = maxf(float(saved.get("wave_damage", 0.0)), 0.0)
	wave_taken = maxf(float(saved.get("wave_taken", 0.0)), 0.0)
	wave_peak_dps = maxf(float(saved.get("wave_peak_dps", 0.0)), 0.0)
	wave_boss_ttk = maxf(float(saved.get("wave_boss_ttk", 0.0)), 0.0)
	wave_peak_enemies = maxi(int(saved.get("wave_peak_enemies", 0)), 0)
	wave_enemy_seconds = maxf(float(saved.get("wave_enemy_seconds", 0.0)), 0.0)
	wave_peak_enemy_projectiles = maxi(int(saved.get("wave_peak_enemy_projectiles", 0)), 0)
	boss_started_at = float(saved.get("boss_started_at", -1.0))
	last_boss_ttk = maxf(float(saved.get("last_boss_ttk", 0.0)), 0.0)
	damage_events.assign(saved.get("damage_events", []))
	kill_events.assign(saved.get("kill_events", []))
	taken_events.assign(saved.get("taken_events", []))
	damage_head = 0
	kill_head = 0
	taken_head = 0
	recent_damage = 0.0
	recent_taken = 0.0
	for event in damage_events:
		recent_damage += float(event["amount"])
	for event in taken_events:
		recent_taken += float(event["amount"])
	_prune_events()


# Hits in one frame share a timestamp and expiration; keep one bucket per frame.
# Old saves with one entry per hit remain valid.
func _append_amount(events: Array[Dictionary], amount: float) -> void:
	if not events.is_empty() and float(events[-1]["at"]) == elapsed:
		events[-1]["amount"] = float(events[-1]["amount"]) + amount
	else:
		events.append({"at": elapsed, "amount": amount})


func _prune_events() -> void:
	while damage_head < damage_events.size() and elapsed - float(damage_events[damage_head]["at"]) >= WINDOW:
		recent_damage -= float(damage_events[damage_head]["amount"])
		damage_head += 1
	while kill_head < kill_events.size() and elapsed - kill_events[kill_head] >= WINDOW:
		kill_head += 1
	while taken_head < taken_events.size() and elapsed - float(taken_events[taken_head]["at"]) >= WINDOW:
		recent_taken -= float(taken_events[taken_head]["amount"])
		taken_head += 1
	# Amortized compaction instead of shifting the whole array per expired hit.
	if damage_head > 0 and damage_head * 2 >= damage_events.size():
		damage_events = damage_events.slice(damage_head)
		damage_head = 0
	if kill_head > 0 and kill_head * 2 >= kill_events.size():
		kill_events = kill_events.slice(kill_head)
		kill_head = 0
	if taken_head > 0 and taken_head * 2 >= taken_events.size():
		taken_events = taken_events.slice(taken_head)
		taken_head = 0
	recent_damage = maxf(recent_damage, 0.0)
	recent_taken = maxf(recent_taken, 0.0)
