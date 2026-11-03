class_name KingPressureFraming
extends RefCounted
## Keep the complete positioning puzzle visible; HUD remains at native scale.

var camera: Camera2D
var previous_zoom := Vector2.ONE
var previous_position := Vector2.ZERO

func begin(next: Camera2D, viewport: Vector2) -> void:
	if is_instance_valid(camera): return
	# Desktop already fits the puzzle. Keep Denti's ordinary follow camera so
	# entering/leaving a shield cannot look like teleporting the player.
	if viewport.x >= 1000 and viewport.y >= 650: return
	camera = next
	previous_zoom = camera.zoom
	previous_position = camera.position
	camera.zoom = Vector2.ONE * minf(1.0, minf(viewport.x / 1000.0, viewport.y / 650.0))
	camera.force_update_scroll()

func follow(center: Vector2) -> void:
	if not is_instance_valid(camera): return
	camera.global_position = center
	camera.force_update_scroll()

func release() -> void:
	if is_instance_valid(camera):
		camera.zoom = previous_zoom
		camera.position = previous_position
		camera.force_update_scroll()
	camera = null
