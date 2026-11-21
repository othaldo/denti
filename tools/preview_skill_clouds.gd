extends "res://tests/support/test_runtime.gd"
## Contact sheet of every animated skill effect over the real arena. Rows:
## poison cloud, ember core, frost wall, assassin poison lane, rinser foam
## trail. Columns: the same effect at four moments of its life.
##   Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 --path . --script res://tools/preview_skill_clouds.gd

const OUTPUT := "res://docs/screenshots/skill_clouds.png"
const CELL := Vector2(240, 190)
## [age, remaining] for each column: billowing, settled, later, dissolving.
const MOMENTS := [[0.15, 2.3], [0.8, 1.7], [1.6, 0.9], [2.2, 0.25]]
const ROWS := ["poison", "ember", "frost", "poison_lane", "foam"]

class Sheet extends Node2D:
	func _draw() -> void:
		for row in ROWS.size():
			var style: SkillCloudStyle = load("res://data/vfx/skill_clouds/%s.tres" % ROWS[row])
			for column in MOMENTS.size():
				var center := Vector2(CELL.x * (column + 0.5), CELL.y * (row + 0.5))
				var age: float = MOMENTS[column][0]
				var remaining: float = MOMENTS[column][1]
				match ROWS[row]:
					"poison":
						SkillPuffs.draw_cloud(self, center, 60.0, style, age, remaining, 11)
					"ember":
						# Core radius 110 is wider than a cell; shown at 0.75 scale.
						SkillPuffs.draw_cloud(self, center, 82.0, style, age, remaining, 12)
						draw_arc(center, 82.0, 0.0, TAU, 40, Color(EmberSkills.EMBER, 0.55), 2.0, true)
					"frost":
						var a := center + Vector2(-85, 25)
						var b := center + Vector2(85, -25)
						SkillPuffs.draw_lane(self, a, b, FrostSkills.WALL_HALF * 2.0, style, age, remaining, 13)
						draw_line(a, b, Color(FrostSkills.ICE.lightened(0.3), 0.9), 4.0, true)
					"poison_lane":
						SkillPuffs.draw_lane(self, center + Vector2(-90, 0), center + Vector2(90, 0), 44.0, style, age, remaining, 14)
					"foam":
						var points := PackedVector2Array()
						for index in 9:
							points.append(center + Vector2(-90 + index * 22, sin(index * 0.8) * 28))
						draw_polyline(points, Color(RinserSkills.WATER, 0.16), RinserSkills.TRAIL_RADIUS * 1.4, true)
						draw_polyline(points, Color(RinserSkills.WATER, 0.55), 3.0, true)
						for index in points.size():
							# Older segments sit at the start of the trail.
							var segment_age := age + (points.size() - index) * 0.25
							SkillPuffs.draw_cloud(self, points[index], RinserSkills.TRAIL_RADIUS, style, segment_age, remaining + index * 0.25, 20 + index)

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://skill_clouds_preview.json"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(int(CELL.x) * MOMENTS.size(), int(CELL.y) * ROWS.size())
	root.size = root.content_scale_size
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.hide()
	game.hud.hide()
	game.mobile_controls.hide()
	game.player.get_node("Camera2D").enabled = false
	var camera := Camera2D.new()
	game.add_child(camera)
	camera.position = Vector2(root.size) * 0.5 + Vector2(40, 40)
	camera.make_current()
	var sheet := Sheet.new()
	sheet.position = Vector2(40, 40)
	sheet.z_index = 2
	game.add_child(sheet)
	paused = true
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.save_png(OUTPUT)
	print("Saved ", ProjectSettings.globalize_path(OUTPUT))
	session.clear_run()
	finish(0)
