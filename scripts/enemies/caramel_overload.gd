class_name CaramelOverload
extends Node2D
## One optional objective phase. The encounter owns hazards; normal Enemy nodes
## provide weapon/affix compatibility and are linked again after run restoration.

enum State { IDLE, WARNING, ACTIVE, BLAST, RECOVERY, FINISHED }
var encounter: CaramelEncounter
var profile: CaramelOverloadData
var state := State.IDLE
var used := false
var remaining := 0.0
var duration := 0.0
var opening_distance := 190.0
var elapsed := 0.0
var lane_state := 0
var lane_remaining := 0.0
var lane_angle := 0.0
var lane_index := 0
var missed := 0
var escaped := 0
var trial_index := 2
var completed_mask := 0
var opening_left := 0.0
var anchor := Vector2.ZERO
var pylons: Array[Enemy] = []
var pressure := CaramelRitualPressure.new()

func _ready() -> void:
	z_index = 3
	pressure.ritual = self

func trial() -> CaramelTrialData:
	return profile.trials[clampi(trial_index, 0, profile.trials.size() - 1)]

func next_trial() -> int:
	if profile == null or used or busy(): return -1
	var enemy := encounter.enemy
	for index in range(profile.trials.size() - 1, -1, -1):
		var definition := profile.trials[index]
		if not definition.enabled_for_rank(profile.rank) or completed_mask & (1 << index): continue
		if enemy.health <= enemy.max_health * definition.health_fraction + 0.01 or enemy.boss_phase >= 2:
			return index
		if definition.health_fraction >= 0.66 and enemy.boss_phase >= 1: return index
	return -1

func damage_limit() -> float:
	var enemy := encounter.enemy
	var limit := minf(enemy.health, opening_left) if state == State.RECOVERY else enemy.health
	if used or profile == null: return limit
	for index in profile.trials.size():
		if not profile.trials[index].enabled_for_rank(profile.rank) or completed_mask & (1 << index): continue
		limit = minf(limit, maxf(enemy.health - enemy.max_health * profile.trials[index].health_fraction, 0))
	return limit

func spend_opening_damage(amount: float) -> void:
	opening_left = maxf(opening_left - amount, 0)

func _finish_opening() -> void:
	state = State.FINISHED
	opening_left = 0
	encounter.enemy.boss_damage_budget = 0
	encounter._recover()

func pending() -> bool:
	return next_trial() >= 0

func busy() -> bool:
	return state in [State.WARNING, State.ACTIVE, State.BLAST, State.RECOVERY]

func blocks_damage() -> bool:
	return pending() or state in [State.WARNING, State.ACTIVE, State.BLAST]

func objective_open(pylon: Enemy) -> bool:
	return state == State.ACTIVE and (trial().kind == CaramelTrialData.Kind.COURIERS or pylon.global_position.distance_to(encounter.enemy.target.global_position) <= opening_distance)

func live_pylons() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for pylon in pylons:
		if is_instance_valid(pylon) and not pylon.is_queued_for_deletion() and pylon.health > 0: result.append(pylon)
	return result

func available() -> bool:
	# Two Princes do not start rituals together.
	for other: CaramelEncounter in get_tree().get_nodes_in_group("caramel_encounters"):
		if other != encounter and other.overload != null and other.overload.busy(): return false
	return true

func begin() -> void:
	if used or profile == null: return
	trial_index = next_trial()
	if trial_index < 0: return
	# Debug jumps to a late health phase do not replay earlier lessons.
	completed_mask |= (1 << trial_index) - 1
	encounter.cancel()
	state = State.WARNING
	remaining = profile.warning_seconds
	elapsed = 0
	escaped = 0
	missed = 0
	lane_state = 0
	lane_remaining = profile.lane_pause_seconds
	var enemy := encounter.enemy
	var player := enemy.target
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	# Keep objective silhouettes clear of the boss HUD and the bottom tooth HUD.
	var top := minf(135, visible.size.y * 0.28)
	var bottom := minf(190, visible.size.y * (0.47 if visible.size.y < 400 else 0.375))
	var safe := Rect2(visible.position + Vector2(60, top), visible.size - Vector2(120, top + bottom)).intersection(Rect2(Vector2.ONE * 70, player.arena.arena_size - Vector2.ONE * 140))
	var extent := profile.layout_extent.min(safe.size)
	if visible.size.y < 400: extent.x = minf(extent.x, visible.size.x * 0.46)
	opening_distance = minf(profile.opening_distance, extent.length() * 0.35)
	var center := player.global_position.clamp(safe.position + extent * 0.5, safe.end - extent * 0.5)
	var bounds := Rect2(center - extent * 0.5, extent)
	anchor = enemy.global_position
	# Full perimeter, four weak objectives and reaction margin, even at low speed.
	duration = clampf(2 * (extent.x + extent.y) / minf(player.stats.move_speed, PlayerStats.BASE_MOVE_SPEED) + trial().objectives * profile.objective.max_health / 16.0 + 3, profile.minimum_seconds * trial().objectives / 4.0, profile.maximum_seconds)
	var game := get_tree().current_scene
	var corners: Array[Vector2] = [bounds.position, bounds.position + Vector2(extent.x, 0), bounds.end, bounds.position + Vector2(0, extent.y)]
	for index in trial().objectives:
		var corner := corners[index * 2] if trial().objectives == 2 else corners[index]
		game._create_enemy(profile.objective, corner)
		var pylon: Enemy = game.get_node("Enemies").get_child(-1)
		bind_pylon(pylon)
	pressure.start()
	enemy.attack_performed.emit(&"boss_warning")
	queue_redraw()

func bind_pylon(pylon: Enemy) -> void:
	pylon.boss_objective_owner = encounter.enemy
	pylon.inflicted_statuses.clear()
	if not pylons.has(pylon):
		if pylon.boss_objective_slot < 0: pylon.boss_objective_slot = pylons.size()
		pylons.append(pylon)
	if pylon.get_node_or_null("HeartPylonVisual") == null:
		var visual := CaramelPylonVisual.new()
		visual.name = &"HeartPylonVisual"
		visual.pylon = pylon
		pylon.add_child(visual)

func advance(delta: float) -> bool:
	# Spend a bounded counterattack, then resume normal attacks immediately.
	# Resetting the guard makes room for combat between the two examinations.
	if state == State.RECOVERY and damage_limit() <= 0.01: _finish_opening()
	if pending() and encounter.enemy.boss_phase_timer <= 0:
		if not available(): return true
		begin()
	if not busy(): return false
	var left := delta
	var spent := 0.0
	while left > 0.000001 and busy():
		pressure.advance(0)
		if state == State.ACTIVE and live_pylons().is_empty():
			if escaped == 0: _success()
			else: _announce_blast(escaped)
			continue
		var step := minf(left, remaining)
		if state == State.ACTIVE:
			if trial().aimed_lanes: step = minf(step, lane_remaining)
			step = minf(step, pressure.next_event())
			if trial().aimed_lanes and lane_state == 2 and HazardGeometry.swept_capsule(encounter.enemy.target, lane_start(), lane_end(), profile.lane_half_width, spent, spent + step):
				encounter.enemy.target.take_hit(encounter.enemy.attack_damage * 0.65)
			if trial().aimed_lanes: lane_remaining = maxf(lane_remaining - step, 0)
			pressure.move_couriers(step)
		encounter.hearts.advance(step, spent)
		pressure.advance(step)
		remaining = maxf(remaining - step, 0)
		elapsed += step
		spent += step
		left -= step
		if state == State.ACTIVE and trial().aimed_lanes and lane_remaining <= 0.000001: _next_lane()
		if remaining <= 0.000001: _next()
	queue_redraw()
	return true

func _next_lane() -> void:
	lane_state = (lane_state + 1) % 3
	if lane_state == 1:
		# Aim once at the announced position; no tracking during the warning.
		lane_angle = anchor.angle_to_point(encounter.enemy.target.global_position)
		lane_index += 1
		lane_remaining = profile.lane_warning_seconds
	elif lane_state == 2: lane_remaining = profile.lane_active_seconds
	else: lane_remaining = profile.lane_pause_seconds

func lane_start() -> Vector2: return anchor - Vector2.RIGHT.rotated(lane_angle) * 800
func lane_end() -> Vector2: return anchor + Vector2.RIGHT.rotated(lane_angle) * 800

func _next() -> void:
	match state:
		State.WARNING:
			state = State.ACTIVE
			remaining = duration
		State.ACTIVE:
			_announce_blast(live_pylons().size() + escaped)
		State.BLAST:
			encounter.hearts.fire(anchor, EnemyProjectilePatterns.circle_directions(4 + missed * 4, 0), &"caramel_overload")
			state = State.FINISHED
			encounter._recover()
			encounter.enemy.attack_performed.emit(&"boss_pulse")
		State.RECOVERY:
			_finish_opening()

func _success() -> void:
	_complete_trial()
	_clear_pylons()
	pressure.clear(true)
	encounter.hearts.clear()
	state = State.RECOVERY
	remaining = profile.recovery_seconds
	opening_left = encounter.enemy.max_health * profile.opening_damage_fraction
	encounter.enemy.boss_damage_budget = 0
	encounter.enemy.attack_performed.emit(&"boss_break")

func _complete_trial() -> void:
	completed_mask |= 1 << trial_index
	used = (completed_mask & profile.enabled_mask()) == profile.enabled_mask()

func _announce_blast(amount: int) -> void:
	_complete_trial()
	missed = amount
	_clear_pylons()
	pressure.clear()
	encounter.hearts.clear()
	state = State.BLAST
	remaining = profile.blast_warning_seconds
	encounter.enemy.attack_performed.emit(&"boss_warning")

func _clear_pylons() -> void:
	for pylon in pylons:
		if is_instance_valid(pylon) and not pylon.is_queued_for_deletion(): pylon.queue_free()
	pylons.clear()

func cancel() -> void:
	_clear_pylons()
	pressure.clear()
	opening_left = 0
	state = State.FINISHED if used else State.IDLE
	queue_redraw()

func save_data() -> Dictionary:
	return {"version": 3, "state": int(state), "used": used, "remaining": remaining, "duration": duration, "opening_distance": opening_distance, "elapsed": elapsed, "lane_state": lane_state, "lane_remaining": lane_remaining, "lane_angle": lane_angle, "lane_index": lane_index, "missed": missed, "anchor": SnapshotValues.vector_data(anchor), "trial_index": trial_index, "completed_mask": completed_mask, "opening_left": opening_left, "escaped": escaped, "pressure": pressure.save_data()}

func restore(saved: Dictionary) -> void:
	_clear_pylons()
	state = clampi(int(saved.get("state", 0)), 0, State.FINISHED) as State
	used = bool(saved.get("used", false))
	trial_index = clampi(int(saved.get("trial_index", 2)), 0, maxi(profile.trials.size() - 1, 0))
	completed_mask = clampi(int(saved.get("completed_mask", 0)), 0, 7)
	opening_left = clampf(float(saved.get("opening_left", encounter.enemy.max_health * profile.opening_damage_fraction if state == State.RECOVERY else 0)), 0, encounter.enemy.max_health * profile.opening_damage_fraction)
	escaped = clampi(int(saved.get("escaped", 0)), 0, 4)
	duration = clampf(float(saved.get("duration", 0)), 0, profile.maximum_seconds)
	opening_distance = clampf(float(saved.get("opening_distance", profile.opening_distance)), 32, profile.opening_distance)
	remaining = clampf(float(saved.get("remaining", 0)), 0, profile.maximum_seconds)
	elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	lane_state = clampi(int(saved.get("lane_state", 0)), 0, 2)
	lane_remaining = clampf(float(saved.get("lane_remaining", 0)), 0, maxf(profile.lane_pause_seconds, profile.lane_warning_seconds))
	lane_angle = float(saved.get("lane_angle", 0))
	lane_index = maxi(int(saved.get("lane_index", 0)), 0)
	missed = clampi(int(saved.get("missed", 0)), 0, 4)
	anchor = SnapshotValues.read_vector(saved.get("anchor", [0, 0]))
	pressure.restore(saved.get("pressure", {}))
	if int(saved.get("version", 0)) < 2 and not saved.is_empty():
		# An announced old ritual keeps its original pressure. No new earlier
		# lesson is inserted into a resumed fight already past that threshold.
		completed_mask = (1 << trial_index) - 1
	queue_redraw()

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["version", "state", "remaining", "duration", "opening_distance", "elapsed", "lane_state", "lane_remaining", "lane_angle", "lane_index", "missed", "trial_index", "completed_mask", "escaped", "opening_left"]:
		if saved.has(key) and not (saved[key] is int or saved[key] is float): return false
		if saved.has(key) and not is_finite(float(saved[key])): return false
	if saved.has("used") and not saved.used is bool: return false
	if saved.has("anchor"):
		if not saved.anchor is Array or saved.anchor.size() != 2: return false
		for coordinate in saved.anchor:
			if not (coordinate is int or coordinate is float): return false
	return CaramelRitualPressure.valid(saved.get("pressure", {}))

func _draw() -> void:
	if not busy() or encounter.enemy.dying: return
	CaramelOverloadVisuals.draw(self)

