extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://docs/screenshots/element_icons/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var supports := "--supports" in OS.get_cmdline_user_args()
	var output := "res://docs/screenshots/support_icons/" if supports else OUTPUT
	var session := root.get_node("GameSession")
	session.save_path = "user://element_icons_preview.json"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = root.content_scale_size
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}])
	game.rewards.weapon_upgrades.points = 4
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	for frame in 8: await process_frame
	panel.open_picker(0)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	var screenshot := root.get_texture().get_image()
	screenshot.save_png(output + "picker.png")
	var bounds := Rect2()
	for button in panel.effect_buttons:
		var elemental: bool = WeaponAffixes.by_id(button.get_meta("effect_id")).elemental
		if elemental == supports: continue
		bounds = button.get_global_rect() if bounds.size == Vector2.ZERO else bounds.merge(button.get_global_rect())
	for child in panel.body.get_children():
		if child is Label and child.text.begins_with("Verstärkung" if supports else "Element"):
			bounds = bounds.merge(child.get_global_rect())
	screenshot.get_region(Rect2i(bounds.grow(8))).save_png(output + ("supports.png" if supports else "elements.png"))
	panel.hide()
	# Native sampling at the smallest used size and the larger decision-card sizes.
	var layer := CanvasLayer.new()
	root.add_child(layer)
	layer.layer = 30
	var board := Control.new()
	layer.add_child(board)
	board.size = Vector2(1920, 1080)
	board.theme = MenuStyle.make_theme()
	MenuStyle.backdrop(board)
	var ids := [&"fire", &"ice", &"poison", &"bleed", &"electric", &"wet"]
	if supports: ids = [&"range", &"tempo", &"leech", &"crit", &"crit_damage", &"knockback"]
	for column in ids.size():
		var definition := WeaponAffixes.by_id(ids[column])
		var caption := Label.new()
		caption.text = definition.display_name
		caption.position = Vector2(60 + column * 300, 60)
		caption.add_theme_font_size_override("font_size", 32)
		board.add_child(caption)
		for row in 4:
			var size_px: int = [16, 24, 32, 48][row]
			var art := TextureRect.new()
			art.texture = DentiUIIcons.item(definition.icon_index)
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.position = Vector2(60 + column * 300, 160 + row * 120)
			art.size = Vector2.ONE * size_px
			board.add_child(art)
			var label := Label.new()
			label.text = "%d px" % size_px
			label.position = art.position + Vector2(74, 0)
			board.add_child(label)
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "native_sizes.png")
	session.clear_run()
	print("PASS %s icons: production picker, six dedicated motifs, 16/24/32/48px native sampling" % ("support" if supports else "element"))
	finish()
