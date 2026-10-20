extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(384, 384)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig: CountCloakRig = load("res://scenes/enemies/count_cloak_rig.tscn").instantiate()
	rig.position = Vector2(192, 335)
	rig.scale = Vector2.ONE * 2.1
	viewport.add_child(rig)
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://assets/enemies/count_rig/portrait.png")
	finish()
