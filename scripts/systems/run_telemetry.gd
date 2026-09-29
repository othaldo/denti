class_name RunTelemetry
extends RefCounted

const WINDOW := 10.0

var elapsed: float = 0.0
var total_damage: float = 0.0
var damage_taken: float = 0.0
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
	wave_chests_found = 0
	wave_chests_kept = 0
	wave_chests_scrapped = 0
	wave_damage = 0.0
	wave_taken = 0.0
	wave_peak_dps = 0.0
	wave_boss_ttk = 0.0
	wave_peak_enemies = 0
	wave_enemy_seconds = 0.0
	wave_peak_enemy_projectiles = 0
	damage_events.clear()
	kill_events.clear()
	taken_events.clear()


func tick(delta: float, enemies_alive: int = 0, enemy_projectiles: int = 0) -> void:
	elapsed += delta
	wave_peak_enemies = maxi(wave_peak_enemies, enemies_alive)
	wave_enemy_seconds += float(enemies_alive) * delta
	wave_peak_enemy_projectiles = maxi(wave_peak_enemy_projectiles, enemy_projectiles)
	_prune_events()
	peak_dps = maxf(peak_dps, recent_dps())
	wave_peak_dps = maxf(wave_peak_dps, recent_dps())


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
	damage_events.append({"at": elapsed, "amount": amount})
	if weapon_id != &"":
		var key := str(weapon_id)
		weapon_damage[key] = float(weapon_damage.get(key, 0.0)) + amount
	elif proc_id != &"":
		var key := str(proc_id)
		proc_damage[key] = float(proc_damage.get(key, 0.0)) + amount
	else:
		other_damage += amount
	peak_dps = maxf(peak_dps, recent_dps())
	wave_peak_dps = maxf(wave_peak_dps, recent_dps())


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


func record_taken(amount: float) -> void:
	if amount <= 0.0:
		return
	damage_taken += amount
	wave_taken += amount
	taken_events.append({"at": elapsed, "amount": amount})


func record_loot(kind: StringName, amount: int) -> void:
	if kind == &"coin":
		coins_collected += amount
		wave_coins += amount
	elif kind == &"xp":
		xp_collected += amount
		wave_xp += amount


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
	var damage := 0.0
	for event in damage_events:
		damage += float(event["amount"])
	return damage / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func recent_kps() -> float:
	return float(kill_events.size()) / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func spawns_per_minute() -> float:
	return float(wave_spawns) * 60.0 / maxf(elapsed - wave_started_at, 1.0)


func taken_per_minute() -> float:
	var amount := 0.0
	for event in taken_events:
		amount += float(event["amount"])
	return amount * 60.0 / maxf(minf(elapsed - wave_started_at, WINDOW), 1.0)


func current_wave_summary() -> Dictionary:
	var duration := maxf(elapsed - wave_started_at, 0.0)
	return {
		"wave": current_wave, "profile_id": str(current_profile_id), "combat_seconds": duration,
		"spawns": wave_spawns, "spawns_blocked": wave_spawns_blocked, "kills": wave_kills,
		"elites_spawned": wave_elites_spawned, "elites_killed": wave_elites_killed,
		"peak_enemies_alive": wave_peak_enemies, "average_enemies_alive": wave_enemy_seconds / maxf(duration, 1.0),
		"peak_enemy_projectiles": wave_peak_enemy_projectiles,
		"damage_dealt": wave_damage, "average_dps": wave_damage / maxf(duration, 1.0),
		"peak_dps": wave_peak_dps, "damage_taken": wave_taken,
		"coins_collected": wave_coins, "xp_collected": wave_xp,
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
		"wave_chests_found": wave_chests_found, "wave_chests_kept": wave_chests_kept,
		"wave_chests_scrapped": wave_chests_scrapped,
		"wave_damage": wave_damage, "wave_taken": wave_taken,
		"wave_peak_dps": wave_peak_dps, "wave_boss_ttk": wave_boss_ttk,
		"wave_peak_enemies": wave_peak_enemies, "wave_enemy_seconds": wave_enemy_seconds,
		"wave_peak_enemy_projectiles": wave_peak_enemy_projectiles,
		"boss_started_at": boss_started_at, "last_boss_ttk": last_boss_ttk,
		"damage_events": damage_events.duplicate(true), "kill_events": kill_events.duplicate(),
		"taken_events": taken_events.duplicate(true),
	}


func restore(saved: Dictionary, wave_number: int) -> void:
	elapsed = maxf(float(saved.get("elapsed", 0.0)), 0.0)
	total_damage = maxf(float(saved.get("total_damage", 0.0)), 0.0)
	damage_taken = maxf(float(saved.get("damage_taken", 0.0)), 0.0)
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
	_prune_events()


func _prune_events() -> void:
	while not damage_events.is_empty() and elapsed - float(damage_events[0]["at"]) >= WINDOW:
		damage_events.pop_front()
	while not kill_events.is_empty() and elapsed - kill_events[0] >= WINDOW:
		kill_events.pop_front()
	while not taken_events.is_empty() and elapsed - float(taken_events[0]["at"]) >= WINDOW:
		taken_events.pop_front()
