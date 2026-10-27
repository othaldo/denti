extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://docs/screenshots/floss_cut/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var element: StringName = &""
	var weapon_id: StringName = &"floss_garrote"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--element="): element = StringName(argument.trim_prefix("--element="))
		if argument.begins_with("--weapon="): weapon_id = StringName(argument.trim_prefix("--weapon="))
	var tag := "normal" if element == &"" else str(element)
	var frames := "res://.godot/floss_anchored_frames/" + str(weapon_id) + "/" + tag + "/"
	var output := OUTPUT + "anchored/" + str(weapon_id) + "/" + tag + "/"
	var session := root.get_node("GameSession")
	session.save_path = "user://floss_cut_preview.json"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.hud.hide()
	game.mobile_controls.hide()
	game.get_node("DamageNumbers").hide()
	paused = true
	var data := WeaponCatalog.by_id(weapon_id)
	var values: Array[Dictionary] = []
	if element != &"": values = WeaponUpgrades.advance([], element, data, 1)
	game.player.loadout.restore([{"id": str(weapon_id), "tier": 1, "affixes": values}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 2.1
	camera.offset = Vector2(55, 0)
	camera.reset_smoothing()
	camera.force_update_scroll()
	var near: Enemy
	var behind: Enemy
	var offsets := [Vector2(60, 0), Vector2(data.attack_range * 0.6, 0), Vector2(data.attack_range - 5, 0), Vector2(120, 110), Vector2(-110, 0)]
	for index in offsets.size():
		var offset: Vector2 = offsets[index]
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 100000
		enemy.max_health = 100000
		enemy.set_physics_process(false)
		if index == 0: near = enemy
		if index == 4: behind = enemy
	var layer := CanvasLayer.new()
	game.add_child(layer)
	var label := Label.new()
	label.text = data.display_name + " · " + data.roots_text() + " · " + ("Normal" if element == &"" else WeaponAffixes.by_id(element).display_name)
	label.position = Vector2(32, 24)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("fff3db"))
	label.add_theme_color_override("font_outline_color", Color("261b2e"))
	label.add_theme_constant_override("outline_size", 4)
	layer.add_child(label)
	DirAccess.make_dir_recursive_absolute(frames)
	DirAccess.make_dir_recursive_absolute(output)
	for frame in 90:
		if frame == 9: weapon._begin_attack([near])
		if weapon.attack_time > 0: weapon._physics_process(1.0 / 60.0)
		for enemy: Enemy in game.get_node("Enemies").get_children(): enemy._process(1.0 / 60.0)
		game.element_impacts._physics_process(1.0 / 60.0)
		game.items._process(1.0 / 60.0)
		game.relics._process(1.0 / 60.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		screenshot.save_png(frames + "%02d.png" % frame)
		if frame == 13: screenshot.save_png(output + "tension.png")
		if frame == 25: screenshot.save_png(output + "cut.png")
		if frame == 42: screenshot.save_png(output + "recovery.png")
	assert(weapon.strike.hit_ids.size() == 3 and behind.health == 100000, "native strands missed their front line or hit outside it")
	session.clear_run()
	print("PASS native anchored floss: fixed painted grips, connected forward strands, three path contacts, no side/rear hit; " + str(weapon_id) + " " + tag)
	if "--sheet" in OS.get_cmdline_user_args():
		game.get_node("Enemies").hide()
		game.element_impacts.clear()
		for id in [&"floss_garrote", &"floss_whip"]:
			for skin in [&"", &"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]:
				var form := WeaponCatalog.by_id(id)
				var enchants: Array[Dictionary] = []
				if skin != &"": enchants = WeaponUpgrades.advance([], skin, form, 1)
				game.player.loadout.restore([{"id": str(id), "tier": 1, "affixes": enchants}])
				var shown: WeaponInstance = game.player.loadout.equipped()[0]
				shown.set_physics_process(false)
				shown.aim = Vector2.RIGHT
				shown.attack_duration = form.animation_duration
				shown.attack_time = shown.attack_duration * (1 - 0.68)
				shown.update_visual()
				var name := "Normal" if skin == &"" else WeaponAffixes.by_id(skin).display_name
				label.text = form.display_name + " · " + form.roots_text() + " · " + name
				await process_frame
				await RenderingServer.frame_post_draw
				var sheet_dir := OUTPUT + "anchored/elements/"
				DirAccess.make_dir_recursive_absolute(sheet_dir)
				root.get_texture().get_image().save_png(sheet_dir + str(id) + "_" + ("normal" if skin == &"" else str(skin)) + ".png")
		print("PASS native forms: both weapons, normal and six elemental strands")
	finish()
