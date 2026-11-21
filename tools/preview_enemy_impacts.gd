extends "res://tests/support/test_runtime.gd"
## Contact sheet of the production hit punch (upper enemies) and death pop
## (lower enemies), rendered frame by frame at 60 Hz.
##   Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 --path . --script res://tools/preview_enemy_impacts.gd

const OUTPUT := "res://docs/screenshots/enemy_impacts_closeup.png"
const KINDS := ["plaque", "bacteria", "sugar", "acid_spitter", "gum_biter"]
const FRAMES := [0, 2, 4, 7, 10, 14]
const ROW_HEIGHT := 150
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://enemy_impacts_preview.json"
	session.progression_path = "user://enemy_impacts_preview.cfg"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1000, 360)
	root.size = root.content_scale_size
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.hide()
	game.player.set_process(false)
	game.player.set_physics_process(false)
	game.hud.hide()
	game.mobile_controls.hide()
	game.get_node("DamageNumbers").hide()
	game.player.get_node("Camera2D").enabled = false
	var camera := Camera2D.new()
	game.add_child(camera)
	camera.position = Vector2(500, 180)
	camera.make_current()
	var hit_row: Array[Enemy] = []
	var death_row: Array[Enemy] = []
	for index in KINDS.size():
		for row in 2:
			game._create_enemy(load("res://data/enemies/%s.tres" % KINDS[index]), Vector2(110 + index * 195, 95 + row * 175))
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.max_health = 1000.0
			enemy.health = 1000.0 if row == 0 else 1.0
			enemy.simulation_enabled = false
			enemy.set_physics_process(false)
			(hit_row if row == 0 else death_row).append(enemy)
	game.player.global_position = Vector2(-400, 180)
	for i in 4: await process_frame
	for enemy in hit_row: enemy.take_damage(200.0, null, false, &"", [], Vector2.RIGHT)
	for enemy in death_row: enemy.take_damage(50.0, null, false, &"", [], Vector2.RIGHT)
	var strips: Array[Image] = []
	var frame := 0
	for target in FRAMES:
		while frame < target:
			await process_frame
			frame += 1
		await RenderingServer.frame_post_draw
		strips.append(root.get_texture().get_image())
		frame += 1
	# Plaque, bacteria and sugar; frames left to right, then the second row.
	var crop := Rect2i(40, 20, 540, 330)
	var sheet := Image.create(crop.size.x * 3, crop.size.y * 2, false, Image.FORMAT_RGB8)
	for index in strips.size():
		strips[index].convert(Image.FORMAT_RGB8)
		sheet.blit_rect(strips[index], crop, Vector2i(index % 3 * crop.size.x, index / 3 * crop.size.y))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	sheet.save_png(OUTPUT)
	print("Saved ", ProjectSettings.globalize_path(OUTPUT), " frames ", FRAMES)
	session.clear_run()
	finish(0)
