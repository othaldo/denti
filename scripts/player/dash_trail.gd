class_name DashTrail
extends Node2D

var samples: Array[Dictionary] = []

func add_segment(start: Vector2, end: Vector2) -> void:
	if start.distance_squared_to(end) > 1:
		samples.append({"start": start, "end": end, "life": 0.14})
		queue_redraw()

func _process(delta: float) -> void:
	if samples.is_empty(): return
	for index in range(samples.size() - 1, -1, -1):
		samples[index].life -= delta
		if samples[index].life <= 0: samples.remove_at(index)
	queue_redraw()

func _draw() -> void:
	if samples.is_empty(): return
	var latest: Dictionary = samples[-1]
	AttackEffects.strip(self, AttackEffects.Shape.TRAIL, to_local(samples[0].start), to_local(latest.end), 28, Color(0.35, 1.0, 0.85, latest.life / 0.14 * 0.65), latest.life)
