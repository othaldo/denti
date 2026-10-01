extends SceneTree

# Actual player/weapon scenes, identical camera scale, isolated preview save.
const CELL_SIZE := Vector2i(384, 320)
const BOARD_SIZE := Vector2i(2304, 1080)
const OUTPUT := "res://docs/screenshots/weapon_sizes"

var games: Array[Node2D] = []
var views: Array[SubViewport] = []
var title: Label


func _initialize() -> void:
	call_deferred("_run")


func _label(parent: Node, text: String, at: Vector2, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff9e9"))
	label.add_theme_color_override("font_outline_color", Color("302833"))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_sizes_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var board_view := SubViewport.new()
	board_view.size = BOARD_SIZE
	board_view.world_2d = World2D.new()
	board_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(board_view)
	var board := Node2D.new()
	board_view.add_child(board)
	title = _label(board, "Denti + alle 18 Waffen · Ruhehaltung", Vector2(24, 10), 32)
	_label(board, "Stufe I · gleiche Spielgröße, Kamera ×1,5 · Werte ohne Items/Statboni · Waffenlänge = Texturmaß im Spiel", Vector2(24, 53), 19)
	for index in WeaponCatalog.ALL.size():
		var data: WeaponData = WeaponCatalog.ALL[index]
		var container := SubViewportContainer.new()
		container.position = Vector2(index % 6 * CELL_SIZE.x, 90 + index / 6 * CELL_SIZE.y)
		board.add_child(container)
		var view := SubViewport.new()
		view.size = CELL_SIZE
		view.world_2d = World2D.new()
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		container.add_child(view)
		views.append(view)
		var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
		view.add_child(game)
		game.choice_panel._on_choice_pressed(0)
		game.wave.active = false
		game.player.loadout.restore([{"id": str(data.id), "tier": 1}])
		game.hud.get_node("Root").visible = false
		game.mobile_controls.visible = false
		game.get_node("DamageNumbers").visible = false
		var camera: Camera2D = game.player.get_node("Camera2D")
		camera.zoom = Vector2.ONE * 1.5
		camera.offset = Vector2(42, -12)
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		camera.reset_smoothing()
		games.append(game)
		var captions := CanvasLayer.new()
		view.add_child(captions)
		_label(captions, data.display_name, Vector2(12, 10), 21)
		_label(captions, "%s · %.0f px · %.0f / %.2f s" % [data.roots_text(), WeaponLayout.visual_size(data), data.base_damage, data.interval], Vector2(12, 283), 18)
	paused = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex/weapon_sizes"))
	var suffix := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	for active in [false, true]:
		title.text = "Denti + alle 18 Waffen · %s" % ("Angriffsbewegung" if active else "Ruhehaltung")
		for game in games:
			var camera: Camera2D = game.player.get_node("Camera2D")
			camera.offset = Vector2(78 if active else 42, -12)
			camera.reset_smoothing()
			var weapon: WeaponInstance = game.player.loadout.equipped()[0]
			weapon.aim_distance = weapon.data.range_at_tier(1) * 0.72
			weapon.attack_duration = weapon.data.animation_duration
			weapon.attack_time = weapon.attack_duration * 0.53 if active else 0.0
			weapon.update_visual()
			weapon.queue_redraw()
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var pose := "attack" if active else "idle"
		var image := board_view.get_texture().get_image()
		var path := OUTPUT + "/all_%s_%s.png" % [pose, suffix]
		if image.save_png(path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		for index in views.size():
			views[index].get_texture().get_image().save_png("res://.codex/weapon_sizes/%s_%s_%s.png" % [WeaponCatalog.ALL[index].id, pose, suffix])
		print("Weapon size preview: " + ProjectSettings.globalize_path(path))
	session.clear_run()
	board_view.free()
	paused = false
	quit(0)
