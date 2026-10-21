class_name BossPaintedVolley
extends Node2D
## Reusable bounded painted projectile batch, independent of the boss state machine.

var enemy: Enemy
var profile: BossProjectileData
var texture: Texture2D
var orient_to_velocity := false
var entries: Array[Dictionary] = []
var fired := 0
var damage_dealt := 0.0

func _ready() -> void:
	z_index = 10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func fire(at: Vector2, rays: Array[Vector2], source: StringName) -> void:
	for ray in rays:
		if entries.size() >= profile.maximum: break
		entries.append({"at": at, "velocity": ray * profile.speed, "life": profile.lifetime, "damage": enemy.attack_damage * profile.damage_factor, "source": source})
		fired += 1
	queue_redraw()

func advance(delta: float, first: float) -> void:
	for index in range(entries.size() - 1, -1, -1):
		var entry := entries[index]
		var step := minf(delta, entry.life)
		var before: Vector2 = entry.at
		entry.at += entry.velocity * step
		entry.life -= delta
		if HazardGeometry.moving_circle(enemy.target, before, entry.at, profile.radius, first, first + step):
			var health := enemy.target.stats.health
			enemy.target.take_hit(entry.damage, enemy.inflicted_statuses)
			damage_dealt += maxf(health - enemy.target.stats.health, 0)
			entries.remove_at(index)
		elif entry.life <= 0: entries.remove_at(index)
	queue_redraw()

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
		if entries.size() >= profile.maximum: break
		var life := clampf(float(raw.get("life", 0)), 0, profile.lifetime)
		if life <= 0: continue
		var velocity := SnapshotValues.read_vector(raw.get("velocity", [0, 0]))
		if velocity.length() > profile.speed and not is_equal_approx(velocity.length(), profile.speed): velocity = velocity.limit_length(profile.speed)
		entries.append({"at": SnapshotValues.read_vector(raw.get("position", [0, 0])), "velocity": velocity, "life": life, "damage": maxf(float(raw.get("damage", 0)), 0), "source": StringName(str(raw.get("source", "shard")))})
	queue_redraw()

func _draw() -> void:
	if enemy.dying: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	var size := texture.get_size() * profile.width / maxf(texture.get_width(), texture.get_height())
	for entry in entries:
		var at: Vector2 = entry.at
		if orient_to_velocity:
			draw_set_transform_matrix(global_transform.affine_inverse() * Transform2D(entry.velocity.angle(), entry.at))
			at = Vector2.ZERO
		draw_texture_rect(texture, Rect2(at - size * 0.5, size), false, Color(1, 1, 1, clampf(entry.life / 0.15, 0.65, 1)))
