class_name PlayerDash
extends RefCounted

signal started
signal contact_stopped

const DEFAULT: DashData = preload("res://data/player/dash.tres")
var config: DashData = DEFAULT
var charge: float = 100.0
var cooldown: float = 0.0
var recovery: float = 0.0
var remaining: float = 0.0
var direction := Vector2.DOWN
var last_direction := Vector2.DOWN
var active: bool:
	get: return remaining > 0.0

func ready_to_dash() -> bool:
	return not active and charge >= config.capacity - 0.00001 and cooldown <= 0.00001

func request(movement: Vector2, in_combat: bool) -> bool:
	if not in_combat or not ready_to_dash():
		return false
	direction = movement.normalized() if not movement.is_zero_approx() else last_direction
	last_direction = direction
	charge = 0.0
	cooldown = config.cooldown
	remaining = config.duration
	recovery = config.recovery_delay
	started.emit()
	return true

func reset_wave() -> void:
	charge = config.capacity
	cooldown = 0.0
	recovery = 0.0
	remaining = 0.0

func finish() -> void:
	if active:
		remaining = 0.0
		recovery = config.recovery_delay

# Returns the time occupied by motion. Recovery can consume the rest of a
# long frame, but never overlaps the actual dash or its recovery delay.
func advance(player: Player, delta: float) -> void:
	var time := maxf(delta, 0.0)
	if time <= 0.0: return
	cooldown = maxf(cooldown - time, 0.0)
	if active:
		var used := minf(time, remaining)
		var before := player.global_position
		var stopped := DashCollision.move(player, direction * config.distance / config.duration * used, used)
		if stopped:
			used *= clampf(before.distance_to(player.global_position) / (config.distance / config.duration * used), 0, 1)
		player.dash_motion_seconds = used
		remaining = maxf(remaining - used, 0.0)
		time -= used
		if stopped:
			finish()
			contact_stopped.emit()
		if active:
			return
	var delay := minf(recovery, time)
	recovery -= delay
	time -= delay
	charge = minf(config.capacity, charge + time * config.recharge_per_second * (1.0 + player.stats.effective_dash_recovery() / 100.0))

func save_data() -> Dictionary:
	return {"charge": charge, "cooldown": cooldown, "recovery": recovery, "remaining": remaining,
		"direction": SnapshotValues.vector_data(direction), "last_direction": SnapshotValues.vector_data(last_direction)}

func restore(saved: Dictionary) -> void:
	charge = clampf(float(saved.get("charge", config.capacity)), 0.0, config.capacity)
	cooldown = clampf(float(saved.get("cooldown", 0.0)), 0.0, config.cooldown)
	recovery = clampf(float(saved.get("recovery", 0.0)), 0.0, config.recovery_delay)
	remaining = clampf(float(saved.get("remaining", 0.0)), 0.0, config.duration)
	direction = SnapshotValues.read_vector(saved.get("direction", [0.0, 1.0])).normalized()
	last_direction = SnapshotValues.read_vector(saved.get("last_direction", [0.0, 1.0])).normalized()
	if direction.is_zero_approx(): direction = Vector2.DOWN
	if last_direction.is_zero_approx(): last_direction = Vector2.DOWN
	if active: charge = 0.0
