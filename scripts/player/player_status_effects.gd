class_name PlayerStatusEffects
extends Node

signal ticked(kind: DentiStatus.Type, amount: float)
signal applied(kind: DentiStatus.Type)

var player: Player
var active: Dictionary = {}

func configure(source: Player) -> void:
	player = source

func _physics_process(delta: float) -> void:
	if player.is_physics_processing() and player.stats.health > 0.0:
		advance(delta)

func apply_attacks(payloads: Array[Dictionary]) -> void:
	if player.stats.health <= 0.0:
		return
	for raw: Dictionary in payloads:
		var payload := DentiStatus.sanitize(raw)
		if payload.is_empty():
			continue
		var kind: int = payload["kind"]
		if active.has(kind):
			var state: Dictionary = active[kind]
			state["remaining"] = maxf(state["remaining"], payload["duration"])
			state["damage"] = maxf(state["damage"], payload["damage"])
			# Refresh never adds stacks or delays the next scheduled tick.
		else:
			active[kind] = {"remaining": payload["duration"], "damage": payload["damage"], "tick": DentiStatus.TICK_INTERVAL}
			player.expressions.set_status(kind as DentiExpressions.Status)
			applied.emit(kind as DentiStatus.Type)

func advance(delta: float) -> void:
	# Advance both clocks in chronological order, including the terminal tick.
	# Death can synchronously clear active through the game coordinator.
	var left := maxf(delta, 0.0)
	while left > 0.000001 and not active.is_empty() and player.stats.health > 0.0:
		var step := left
		for state: Dictionary in active.values():
			step = minf(step, minf(state["remaining"], state["tick"]))
		left = maxf(left - step, 0.0)
		for state: Dictionary in active.values():
			state["remaining"] = maxf(state["remaining"] - step, 0.0)
			state["tick"] -= step
		for kind: int in active.keys():
			if not active.has(kind) or player.stats.health <= 0.0:
				break
			var state: Dictionary = active[kind]
			if state["tick"] <= 0.000001:
				state["tick"] += DentiStatus.TICK_INTERVAL
				var actual := player.stats.take_status_damage(state["damage"], kind as DentiStatus.Type)
				if actual > 0.0:
					ticked.emit(kind as DentiStatus.Type, actual)
			if active.has(kind) and state["remaining"] <= 0.000001:
				_remove(kind)

func _remove(kind: int) -> void:
	active.erase(kind)
	player.expressions.set_status(kind as DentiExpressions.Status, false)

func clear() -> void:
	for kind: int in active.keys():
		_remove(kind)

func hud_text() -> String:
	var parts: PackedStringArray = []
	for kind in [DentiStatus.Type.POISON, DentiStatus.Type.BLEED]:
		if active.has(kind):
			parts.append("%s %.1f s" % [DentiStatus.NAMES[kind], active[kind]["remaining"]])
	return " · ".join(parts)

func save_data() -> Dictionary:
	var result := {}
	for kind: int in active:
		result[DentiStatus.KEYS[kind]] = active[kind].duplicate()
	return result

func restore(saved: Dictionary) -> void:
	clear()
	for kind in [DentiStatus.Type.POISON, DentiStatus.Type.BLEED]:
		var state: Variant = saved.get(DentiStatus.KEYS[kind], {})
		if not state is Dictionary:
			continue
		var payload := DentiStatus.sanitize({"kind": kind, "damage": state.get("damage", 0.0), "duration": state.get("remaining", 0.0)})
		if payload.is_empty():
			continue
		active[kind] = {"remaining": payload["duration"], "damage": payload["damage"], "tick": clampf(float(state.get("tick", 1.0)), 0.000001, DentiStatus.TICK_INTERVAL)}
		player.expressions.set_status(kind as DentiExpressions.Status)
