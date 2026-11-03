class_name ImperialRetinue
extends Node2D
## Unique lieutenants protect a bounded regeneration/charged-judgment phase.

signal court_broken(at: Vector2)

enum State { IDLE, INTRODUCTION, CHANNEL, FAILURE, OPEN, FINISHED }
var encounter: CrownCourtEncounter
var profile: ImperialRetinueData
var state := State.IDLE
var used := false
var completed_mask := 0
var trial_index := 0
var remaining := 0.0
var elapsed := 0.0
var regeneration_left := 0.0
var opening_left := 0.0
var pulse_remaining := 0.0
var pulse_warned := false
var pulse_aim := Vector2.DOWN
var anchor := Vector2.ZERO
var arrival := Vector2.ZERO
var frame_center := Vector2.ZERO
var framing := KingPressureFraming.new()
var minions: Array[Enemy] = []
var shots: BossPaintedVolley

func _ready() -> void:
	z_index = 3
	shots = BossPaintedVolley.new()
	shots.enemy = encounter.enemy
	shots.profile = encounter.profile.shots
	shots.texture = EmperorCourtArt.texture(7)
	shots.orient_to_velocity = true
	add_child(shots)

func _process(_delta: float) -> void:
	if busy(): framing.follow(frame_center)

func _exit_tree() -> void:
	framing.release()

func busy() -> bool:
	return state not in [State.IDLE, State.FINISHED]

func next_trial() -> int:
	if profile == null or used or busy(): return -1
	for index in profile.thresholds.size():
		if not completed_mask & (1 << index) and encounter.enemy.health <= encounter.enemy.max_health * profile.thresholds[index] + 0.01: return index
	return -1

func blocks_damage() -> bool:
	return next_trial() >= 0 or busy() and state != State.OPEN

func damage_limit() -> float:
	var enemy := encounter.enemy
	var result := minf(enemy.health, opening_left) if state == State.OPEN else enemy.health
	if profile == null or used: return result
	for index in profile.thresholds.size():
		if not completed_mask & (1 << index): result = minf(result, maxf(enemy.health - enemy.max_health * profile.thresholds[index], 0))
	return result

func live_minions() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for minion in minions:
		if is_instance_valid(minion) and not minion.is_queued_for_deletion() and minion.health > 0: result.append(minion)
	return result

func keeper_alive() -> bool:
	for minion in live_minions():
		if minion.imperial_vassal.profile.role == ImperialVassalData.Role.KEEPER: return true
	return false

func bind(minion: Enemy) -> void:
	minion.boss_objective_owner = encounter.enemy
	minion.inflicted_statuses.clear()
	if minion.boss_objective_slot < 0: minion.boss_objective_slot = minions.size()
	if not minions.has(minion): minions.append(minion)

func begin() -> void:
	trial_index = next_trial()
	if trial_index < 0: return
	encounter.cancel()
	completed_mask |= 1 << trial_index
	used = completed_mask == (1 << profile.thresholds.size()) - 1
	state = State.INTRODUCTION
	remaining = profile.introduction_seconds
	elapsed = 0
	regeneration_left = encounter.enemy.max_health * profile.regeneration_fraction
	pulse_remaining = profile.pulse_cooldown
	pulse_warned = false
	var enemy := encounter.enemy
	var player := enemy.target
	framing.begin(player.get_node("Camera2D"), enemy.get_viewport_rect().size)
	frame_center = player.global_position
	framing.follow(frame_center)
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var margin := Vector2(minf(130, visible.size.x * 0.25), minf(160, visible.size.y * 0.28))
	var bounds := Rect2(visible.position + margin, visible.size - margin * 2).intersection(Rect2(Vector2.ONE * 90, player.arena.arena_size - Vector2.ONE * 180))
	anchor = (player.global_position - Vector2(0, minf(140, bounds.size.y * 0.3))).clamp(bounds.position, bounds.end)
	arrival = enemy.global_position
	var extent := profile.spawn_extent.min(bounds.size * 0.42)
	var positions: Array[Vector2] = [anchor + Vector2(-extent.x, extent.y * 0.4), anchor + Vector2(extent.x, extent.y * 0.4), anchor + Vector2(0, extent.y)]
	var game := get_tree().current_scene
	for index in profile.count:
		game._create_enemy(profile.minions[index], positions[index].clamp(bounds.position, bounds.end))
		var minion: Enemy = game.get_node("Enemies").get_child(-1)
		bind(minion)
		minion.imperial_vassal.remaining = 0.8 + index * 0.45
	enemy.attack_performed.emit(&"boss_warning")
	queue_redraw()

func advance(delta: float) -> bool:
	for minion in live_minions(): minion.imperial_vassal.advance(delta)
	if state == State.OPEN and damage_limit() <= 0.01: _finish_opening()
	if next_trial() >= 0 and encounter.enemy.boss_phase_timer <= 0:
		for other: CrownCourtEncounter in get_tree().get_nodes_in_group("crown_court_encounters"):
			if other != encounter and other.retinue != null and other.retinue.busy(): return true
		begin()
	if not busy():
		shots.advance(delta, 0)
		return false
	var left := delta
	var spent := 0.0
	while left > 0.000001 and busy():
		if state == State.CHANNEL and live_minions().is_empty(): _success()
		var step := minf(left, maxf(remaining, 0))
		if state == State.CHANNEL: step = minf(step, maxf(pulse_remaining, 0))
		shots.advance(step, spent)
		if state == State.INTRODUCTION: encounter.enemy.global_position = arrival.lerp(anchor, clampf(1 - (remaining - step) / profile.introduction_seconds, 0, 1))
		elif state == State.CHANNEL:
			_regenerate(step)
			_pulse(step)
		remaining = maxf(remaining - step, 0)
		elapsed += step
		spent += step
		left -= step
		if remaining <= 0.000001:
			match state:
				State.INTRODUCTION:
					state = State.CHANNEL
					remaining = profile.channel_seconds
				State.CHANNEL:
					state = State.FAILURE
					remaining = profile.failure_warning
					pulse_warned = false
					encounter.enemy.attack_performed.emit(&"boss_warning")
				State.FAILURE:
					shots.fire(anchor, EnemyProjectilePatterns.circle_directions(8 + live_minions().size() * 4, 0), &"imperial_charged_verdict")
					state = State.FINISHED
					framing.release()
					encounter.state = CrownCourtEncounter.State.RECOVERY
					encounter.remaining = encounter.profile.recovery_seconds
				State.OPEN: _finish_opening()
	queue_redraw()
	return true

func _regenerate(delta: float) -> void:
	if regeneration_left <= 0 or not keeper_alive(): return
	var enemy := encounter.enemy
	var amount := minf(regeneration_left, enemy.max_health * profile.regeneration_fraction * delta / profile.regeneration_seconds)
	amount = minf(amount, maxf(enemy.max_health - enemy.health, 0))
	enemy.health += amount
	regeneration_left = maxf(regeneration_left - amount, 0)

func _pulse(delta: float) -> void:
	pulse_remaining -= delta
	if pulse_remaining > 0: return
	if not pulse_warned:
		pulse_warned = true
		pulse_aim = anchor.direction_to(encounter.enemy.target.global_position)
		if pulse_aim.is_zero_approx(): pulse_aim = Vector2.DOWN
		pulse_remaining = profile.pulse_warning
		encounter.enemy.attack_performed.emit(&"boss_warning")
	else:
		shots.fire(anchor, EnemyProjectilePatterns.fan_directions(pulse_aim, 5, 0.22), &"imperial_charge_fan")
		pulse_warned = false
		pulse_remaining = profile.pulse_cooldown

func _success() -> void:
	state = State.OPEN
	remaining = profile.opening_seconds
	opening_left = encounter.enemy.max_health * profile.opening_damage_fraction
	encounter.enemy.boss_damage_budget = 0
	pulse_warned = false
	shots.clear()
	court_broken.emit(encounter.enemy.global_position)

func _finish_opening() -> void:
	state = State.FINISHED
	framing.release()
	encounter.enemy.boss_damage_budget = 0
	encounter.state = CrownCourtEncounter.State.RECOVERY
	encounter.remaining = encounter.profile.recovery_seconds

func cancel() -> void:
	framing.release()
	state = State.FINISHED if completed_mask > 0 or used else State.IDLE
	for minion in minions:
		if is_instance_valid(minion) and not minion.is_queued_for_deletion():
			minion.imperial_vassal.shots.clear()
			minion.queue_free()
	minions.clear()
	if shots != null: shots.clear()
	pulse_warned = false
	queue_redraw()

func save_data() -> Dictionary:
	return {"version": 1, "state": int(state), "used": used, "completed_mask": completed_mask, "trial_index": trial_index, "remaining": remaining, "elapsed": elapsed, "regeneration_left": regeneration_left, "opening_left": opening_left, "pulse_remaining": pulse_remaining, "pulse_warned": pulse_warned, "pulse_aim": SnapshotValues.vector_data(pulse_aim), "anchor": SnapshotValues.vector_data(anchor), "arrival": SnapshotValues.vector_data(arrival), "frame_center": SnapshotValues.vector_data(frame_center), "shots": shots.save_data()}

func restore(saved: Dictionary) -> void:
	state = clampi(int(saved.get("state", 0)), 0, State.FINISHED) as State
	used = bool(saved.get("used", false))
	completed_mask = int(saved.get("completed_mask", 0)) & ((1 << profile.thresholds.size()) - 1)
	trial_index = clampi(int(saved.get("trial_index", 0)), 0, profile.thresholds.size() - 1)
	remaining = clampf(float(saved.get("remaining", 0)), 0, profile.channel_seconds)
	elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	regeneration_left = clampf(float(saved.get("regeneration_left", 0)), 0, encounter.enemy.max_health * profile.regeneration_fraction)
	opening_left = clampf(float(saved.get("opening_left", 0)), 0, encounter.enemy.max_health * profile.opening_damage_fraction)
	pulse_remaining = clampf(float(saved.get("pulse_remaining", 0)), 0, profile.pulse_cooldown)
	pulse_warned = bool(saved.get("pulse_warned", false))
	for key in ["pulse_aim", "anchor", "arrival", "frame_center"]: set(key, SnapshotValues.read_vector(saved.get(key, [0, 0])))
	if busy():
		framing.begin(encounter.enemy.target.get_node("Camera2D"), encounter.enemy.get_viewport_rect().size)
		framing.follow(frame_center)
	else: framing.release()
	shots.restore(saved.get("shots", []))
	queue_redraw()

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["version", "state", "completed_mask", "trial_index", "remaining", "elapsed", "regeneration_left", "opening_left", "pulse_remaining"]:
		if saved.has(key) and not CrownCourtSnapshot._number(saved[key]): return false
	for key in ["used", "pulse_warned"]:
		if saved.has(key) and not saved[key] is bool: return false
	for key in ["pulse_aim", "anchor", "arrival", "frame_center"]:
		if saved.has(key) and not CrownCourtSnapshot._vector(saved[key]): return false
	return ImperialVassal.valid({"shots": saved.get("shots", [])})

func _draw() -> void:
	if busy() and not encounter.enemy.dying: ImperialRetinueVisuals.draw(self)
