extends "res://tests/support/test_runtime.gd"
## Same real loadout, camera and poses for old art / packed art / corrected scale.

const OUTPUT := "res://docs/screenshots/weapon_scale/"
const REFERENCE := "res://docs/art/weapon_elements/size_reference.json"
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://weapon_scale_preview.json"
	session.progression_path = "user://weapon_scale_preview.cfg"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.hud.hide()
	game.mobile_controls.hide()
	game.player.set_physics_process(false)
	game.player.expressions.set_process(false)
	paused = true
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 3.0
	camera.offset = Vector2(32, -12)
	camera.reset_smoothing()
	camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for state in ["legacy", "before", "after"]:
		game.player.loadout.restore([{"id": "magic_toothbrush"}, {"id": "enamel_mirror"}, {"id": "mouthwash_mortar"}])
		for weapon: WeaponInstance in game.player.loadout.equipped():
			weapon.set_physics_process(false)
			weapon.data = weapon.data.duplicate() as WeaponData
			if state == "legacy":
				var old: Dictionary = reference[str(weapon.data.id)]
				var texture: Texture2D = load("res://" + str(old.texture))
				if old.region != null:
					var atlas := AtlasTexture.new()
					atlas.atlas = texture
					atlas.region = Rect2(old.region[0], old.region[1], old.region[2], old.region[3])
					texture = atlas
				weapon.data.held_sprite = texture
				weapon.data.grip_anchor = Vector2(old.grip_anchor[0], old.grip_anchor[1])
				weapon.data.tip_anchor = Vector2(old.tip_anchor[0], old.tip_anchor[1])
			if state != "after": weapon.data.held_scale = 1.0
			weapon.refresh_skin()
			weapon.aim = Vector2(1, 1).normalized() if weapon.data.id == &"mouthwash_mortar" else Vector2.RIGHT
			weapon.update_visual()
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + state + ".png")
	session.clear_run()
	print("PASS native weapon size comparison: identical Denti, equipment, poses and camera")
	finish()
