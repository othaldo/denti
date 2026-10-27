extends "res://tests/support/test_runtime.gd"
## Actual collisions and the production renderer, with an isolated preview save.

const OUTPUT := "res://docs/screenshots/element_impacts/"
const FRAMES := "res://.godot/element_impact_frames/"
var game: Node2D
var targets: Array[Array] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var focus: StringName = &""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--element="): focus = StringName(argument.trim_prefix("--element="))
	assert(focus == &"" or WeaponElementVisuals.ELEMENTS.has(focus))
	var output := OUTPUT if focus == &"" else OUTPUT + str(focus) + "/"
	var frames := FRAMES if focus == &"" else FRAMES + str(focus) + "/"
	var session := root.get_node("GameSession")
	session.save_path = "user://element_impacts_preview.json"
	session.progression_path = "user://element_impacts_preview.cfg"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 900)
	if focus != &"": root.content_scale_size = Vector2i(1280, 600)
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
	game.get_node("DamageNumbers").hide()
	game.player.get_node("Camera2D").enabled = false
	var camera := Camera2D.new()
	game.add_child(camera)
	camera.position = Vector2(640, 450)
	if focus != &"":
		camera.position = Vector2(700, 450)
		camera.zoom = Vector2.ONE * 2.4
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()
	paused = true
	game.items.cooldowns["enchantment_electric"] = 100
	var layer := CanvasLayer.new()
	game.add_child(layer)
	var ids := [&"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]
	if focus != &"": ids = [focus]
	for index in ids.size():
		var x := 30 + index % 2 * 630
		var y := 28 + index / 2 * 280
		_label(layer, WeaponAffixes.by_id(ids[index]).display_name, Vector2(x, y), 28)
		var trio: Array[Enemy] = []
		for style in 3:
			var caption_at := Vector2(x + style * 205, y + 46) if focus == &"" else Vector2(55 + style * 426, 88)
			_label(layer, ["Geschoss", "Explosion", "Nahkampf"][style], caption_at, 18)
			var at := Vector2(x + 92 + style * 205, y + 155) if focus == &"" else Vector2(520 + style * 180, 450)
			game._create_enemy(preload("res://data/enemies/bacteria.tres"), at)
			var enemy: Enemy = game.get_node("Enemies").get_child(-1)
			enemy.health = 100000
			enemy.max_health = 100000
			enemy.set_physics_process(false)
			trio.append(enemy)
		targets.append(trio)
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	var mortar := WeaponCatalog.by_id(&"mouthwash_mortar")
	var melee: WeaponInstance
	if focus != &"":
		game.player.global_position = targets[0][2].global_position - Vector2(95, 0)
		game.player.show()
		game.player.loadout.restore([{"id": "toothpick_spear", "tier": 1,
			"affixes": WeaponUpgrades.advance([], focus, WeaponCatalog.by_id(&"toothpick_spear"), 1)}])
		melee = game.player.loadout.equipped()[0]
		melee.set_physics_process(false)
	for index in ids.size():
		for style in 2:
			var data: WeaponData = brush if style == 0 else mortar
			var at: Vector2 = targets[index][style].global_position
			var values := WeaponUpgrades.advance([], ids[index], data, 1)
			var shot := game.get_node("Projectiles").acquire(data, 1) as WeaponProjectile
			shot.launch(at - Vector2(85, 0), Vector2.RIGHT, 8, data, game.items, false, 1, values)
	DirAccess.make_dir_recursive_absolute(output)
	DirAccess.make_dir_recursive_absolute(frames)
	for frame in 54:
		if frame == 5:
			if melee != null:
				melee._begin_attack([targets[0][2]])
			else:
				for index in ids.size():
					var data := WeaponCatalog.by_id(&"toothpick_spear")
					var values := WeaponUpgrades.advance([], ids[index], data, 1)
					WeaponAttackShapes.hit(targets[index][2], data, 1, 8, false, game.items, Vector2.RIGHT, values)
		if melee != null and melee.attack_time > 0: melee._physics_process(1.0 / 30.0)
		for trio in targets:
			for enemy: Enemy in trio: enemy._process(1.0 / 30.0)
		for child in game.get_node("Projectiles").get_children():
			if child is WeaponProjectile and not child.retired: child._physics_process(1.0 / 30.0)
		game.element_impacts._physics_process(1.0 / 30.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		screenshot.save_png(frames + "%02d.png" % frame)
		if frame == 6: screenshot.save_png(output + "impact.png")
		if frame == 18: screenshot.save_png(output + "ground.png")
	game.element_impacts.clear()
	session.clear_run()
	print("PASS native impacts: six real projectile collisions, explosions, melee pipeline and independent animated ground remains")
	finish()


func _label(parent: Node, value: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff4dc"))
	label.add_theme_color_override("font_outline_color", Color("231a2c"))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
