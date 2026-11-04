class_name BossCompanion
extends Node
## One owned, difficulty-limited companion. The encounter advances its clock.

var owner_enemy: Enemy
var definition: EnemyData
var behavior: StringName
var bounds_for_spawn: Callable
var challenge_active: Callable
var profile: Resource
var minion: Enemy
var remaining := 4.0
var spawned := 0
var legacy := false

func setup(owner: Enemy, data: EnemyData, actor_behavior: StringName, bounds: Callable, suspended: Callable) -> void:
	owner_enemy = owner
	definition = data
	behavior = actor_behavior
	bounds_for_spawn = bounds
	challenge_active = suspended
	profile = data.get(str(behavior) + "_profile").for_difficulty(owner.difficulty)
	remaining = float(profile.get("summon_delay"))

func _exit_tree() -> void: clear()

func live_minions() -> Array[Enemy]:
	var result: Array[Enemy] = []
	if is_instance_valid(minion) and not minion.is_queued_for_deletion() and minion.health > 0: result.append(minion)
	return result

func bind(actor: Enemy) -> void:
	minion = actor
	actor.boss_objective_owner = owner_enemy
	actor.boss_objective_slot = 0

func advance(delta: float) -> void:
	if not live_minions().is_empty():
		minion.get(behavior).advance(delta)
		return
	if legacy or spawned >= int(profile.get("max_summons")) or challenge_active.call(): return
	remaining = maxf(remaining - delta, 0)
	if remaining > 0: return
	var bounds: Rect2 = bounds_for_spawn.call()
	bounds = bounds.intersection(Rect2(Vector2.ONE * 60, owner_enemy.target.arena.arena_size - Vector2.ONE * 120))
	var at := owner_enemy.target.global_position
	var away := owner_enemy.global_position.direction_to(at).orthogonal()
	if away.is_zero_approx(): away = Vector2.RIGHT
	at = (at + away * float(profile.get("spawn_distance"))).clamp(bounds.position, bounds.end)
	get_tree().current_scene._create_enemy(definition, at)
	bind(get_tree().current_scene.get_node("Enemies").get_child(-1))
	spawned += 1
	remaining = float(profile.get("reinforcement_delay"))
	owner_enemy.attack_performed.emit(&"boss_warning")

func pause_attack() -> void:
	if not live_minions().is_empty(): minion.get(behavior).pause_attack()

func clear() -> void:
	if is_instance_valid(minion) and not minion.is_queued_for_deletion(): minion.queue_free()
	minion = null

func save_data() -> Dictionary:
	return {"remaining": remaining, "spawned": spawned, "legacy": legacy}

func restore(saved: Dictionary) -> void:
	remaining = clampf(float(saved.get("remaining", profile.get("summon_delay"))), 0, float(profile.get("reinforcement_delay")))
	spawned = clampi(int(saved.get("spawned", 0)), 0, int(profile.get("max_summons")))
	legacy = bool(saved.get("legacy", false))

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["remaining", "spawned"]:
		if saved.has(key) and not SnapshotValues.is_number(saved[key]): return false
	return not saved.has("legacy") or saved.legacy is bool
