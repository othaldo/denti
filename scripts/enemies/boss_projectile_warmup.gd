class_name BossProjectileWarmup
extends SubViewport

class ChargePreview extends Node2D:
	func _draw() -> void:
		# Exercise the same built-in canvas draw paths as the lane warning/trail.
		draw_colored_polygon(PackedVector2Array([Vector2(1, 1), Vector2(7, 1), Vector2(7, 7), Vector2(1, 7)]), Color(0.95, 0.20, 0.29, 0.3))
		draw_line(Vector2(1, 4), Vector2(7, 4), Color(1.0, 0.72, 0.27, 0.7), 3.0)
		draw_circle(Vector2(6, 4), 1.0, Color(0.95, 0.20, 0.29, 0.3))
		draw_arc(Vector2(4, 4), 2.0, 0.0, TAU, 8, Color(1.0, 0.72, 0.27), 1.0)


func _ready() -> void:
	name = "BossProjectileWarmup"
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2i(8, 8)
	world_2d = World2D.new()
	disable_3d = true
	gui_disable_input = true
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	# Preparing the images alone leaves their first rendered use in combat.
	# Draw them once in an isolated tiny viewport during the initial menu load.
	var textures := EnemyProjectileVisuals.standard_textures()
	for texture in textures:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(4, 4)
		sprite.scale = Vector2.ONE * (6.0 / maxf(texture.get_width(), texture.get_height()))
		add_child(sprite)
	add_child(ChargePreview.new())
	_release_after_render()


func _release_after_render() -> void:
	# process_frame also works with the headless test renderer, which does not
	# emit frame_post_draw. The textures remain in the shared visual cache.
	await get_tree().process_frame
	await get_tree().process_frame
	queue_free()
