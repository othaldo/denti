class_name CaramelHeartVolley
extends Node2D
## Bounded projectiles owned by one boss, using the common swept-hit geometry.

var encounter: CaramelEncounter
var entries: Array[Dictionary] = []

func _ready() -> void:
	z_index = 10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func fire(at: Vector2, rays: Array[Vector2], source: StringName) -> void:
	var profile := encounter.profile
	for ray in rays:
		if entries.size() >= profile.max_hearts: entries.pop_front()
		entries.append({"at": at + ray * (encounter.enemy.data.radius + 12), "velocity": ray * profile.heart_speed, "life": profile.heart_lifetime, "damage": encounter.enemy.attack_damage * profile.heart_damage_factor, "source": source})
	queue_redraw()

func advance(delta: float, seconds_in_frame: float) -> void:
	var player := encounter.enemy.target
	for index in range(entries.size() - 1, -1, -1):
		var entry := entries[index]
		var step := minf(delta, entry.life)
		var before: Vector2 = entry.at
		var after: Vector2 = before + entry.velocity * step
		entry.at = after
		entry.life -= delta
		if HazardGeometry.moving_circle(player, before, after, encounter.profile.heart_radius, seconds_in_frame, seconds_in_frame + step):
			player.take_hit(entry.damage, encounter.enemy.inflicted_statuses)
			entries.remove_at(index)
		elif entry.life <= 0:
			entries.remove_at(index)
	if not entries.is_empty() or delta > 0: queue_redraw()

func clear() -> void:
	entries.clear()
	queue_redraw()

func save_data() -> Array:
	var result: Array = []
	for entry in entries:
		result.append({"position": SnapshotValues.vector_data(entry.at), "velocity": SnapshotValues.vector_data(entry.velocity), "life": entry.life, "damage": entry.damage, "source": str(entry.source)})
	return result

func restore(saved: Array) -> void:
	clear()
	for raw: Dictionary in saved:
		if entries.size() >= encounter.profile.max_hearts: break
		var life := clampf(float(raw.get("life", 0)), 0, encounter.profile.heart_lifetime)
		if life <= 0: continue
		var velocity := SnapshotValues.read_vector(raw.get("velocity", [0, 0]))
		# Preserve legitimate floating-point directions exactly across repeated saves.
		if velocity.length() > encounter.profile.heart_speed and not is_equal_approx(velocity.length(), encounter.profile.heart_speed):
			velocity = velocity.limit_length(encounter.profile.heart_speed)
		entries.append({"at": SnapshotValues.read_vector(raw.get("position", [0, 0])), "velocity": velocity, "life": life, "damage": maxf(float(raw.get("damage", 0)), 0), "source": StringName(str(raw.get("source", "heart_fan")))})
	queue_redraw()

func _draw() -> void:
	if encounter.enemy.dying: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	var texture := PrinceCaramelArt.texture(8)
	var size := texture.get_size() * encounter.profile.heart_visual_width / texture.get_width()
	for entry in entries:
		var opacity := clampf(entry.life / 0.18, 0.55, 1)
		draw_texture_rect(texture, Rect2(entry.at - size * 0.5, size), false, Color(1, 1, 1, opacity))
