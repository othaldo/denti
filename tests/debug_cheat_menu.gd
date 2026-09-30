extends SceneTree

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DebugRunControls.allowed(false, false, "Windows") or DebugRunControls.allowed(true, true, "Linux") or DebugRunControls.allowed(true, false, "Android"):
		_fail("cheats enabled outside local desktop debug builds")
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_debug_cheat_menu.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	var cheats: DebugRunControls = menu.controls
	if cheats.start_wave(5):
		_fail("started a test wave without a weapon")
		return
	_key(menu, KEY_F4)
	if not menu.visible or not paused:
		_fail("F4 did not open during starter selection")
		return
	_key(menu, KEY_ESCAPE)
	if menu.visible or not paused:
		_fail("closing cheats dismissed the underlying starter pause")
		return
	cheats.add_weapon(&"water_jet", 4)
	cheats.add_weapon(&"toothpick_spear", 2)
	cheats.set_weapon_tier(1, 3)
	if game.player.loadout.equipped()[0].tier != 4 or game.player.loadout.equipped()[1].tier != 3:
		_fail("weapon selection or tier editing failed")
		return
	cheats.remove_weapon(1)
	if game.player.loadout.equipped().size() != 1 or game.coins != 0:
		_fail("removing a test weapon paid a refund")
		return
	cheats.add_weapon(&"toothpick_spear", 1)
	menu.refresh()
	var equipped_row: HBoxContainer = menu.equipped_rows.get_child(2)
	var tier_input: SpinBox = equipped_row.get_child(1)
	tier_input.value = 3
	if game.player.loadout.equipped()[1].tier != 3:
		_fail("tier control changed the wrong equipped weapon")
		return
	var remove_button: Button = equipped_row.get_child(2)
	remove_button.pressed.emit()
	await process_frame
	if game.player.loadout.equipped().size() != 1:
		_fail("remove button did not update the loadout")
		return
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}, {"id": "magic_toothbrush", "tier": 1}])
	if cheats.add_weapon(&"magic_toothbrush", 1) or game.player.loadout.equipped()[0].tier != 1:
		_fail("full test loadout silently fused weapons")
		return
	var item := ShopController.by_id(&"fluoride_gel")
	var health_before: float = game.player.stats.max_health
	var added := cheats.add_item(item.id, 99)
	if added != item.max_stacks or game.items.count(item.id) != item.max_stacks or game.player.stats.max_health != health_before + float(item.stat_changes["max_health"]) * added:
		_fail("item stacks or their stat effects differ from real acquisitions")
		return
	cheats.set_stats({"max_health": 500, "health": 999, "damage": 300, "crit_chance": 0.5, "attack_interval": 0.01})
	if game.player.stats.health != 500 or game.player.stats.damage != 300 or game.player.stats.attack_interval != 0.18:
		_fail("stats did not use the authoritative model and limits")
		return
	cheats.set_coins(1234)
	game._open_shop()
	menu.open_menu()
	menu.close_menu()
	if not paused or not game.shop_panel.visible:
		_fail("closing cheats resumed a paused shop")
		return
	game.rewards.earn_level()
	game.rewards.queue_chest(item.id, 5)
	menu.open_menu()
	menu.wave_number.value = 20
	menu._start_wave()
	if paused or menu.visible or game.in_shop or game.starter_pending or not game.wave.active or game.wave.current_wave != 20 or not is_instance_valid(game.boss):
		_fail("wave jump did not leave intermission or create its boss")
		return
	if game.rewards.pending_levels != 0 or not game.rewards.pending_chests.is_empty() or game.coins != 1234 or game.items.count(item.id) != added:
		_fail("wave jump left stale rewards or lost the configured build")
		return
	_key(menu, KEY_F4)
	_key(menu, KEY_ESCAPE)
	if paused or menu.visible:
		_fail("closing cheats failed to resume previously active combat")
		return
	paused = true
	game.boss.start_overtime()
	game.boss_pending = true
	game.collecting_wave_loot = true
	game.wave_loot_remaining = 1
	var drop: Loot = game.LOOT_SCENE.instantiate()
	game.get_node("Loot").add_child(drop)
	cheats.start_wave(7)
	if game.boss != null or game.boss_pending or game.collecting_wave_loot or game.wave_loot_remaining != 0 or game.get_node("Loot").get_child_count() != 0:
		_fail("wave jump retained boss overtime or loot sweep state")
		return
	game.ended = true
	game.player.stats.health = 0
	cheats.start_wave(5)
	if game.ended or game.player.stats.health != 500 or game.wave.current_wave != 5 or game.boss.data != WaveController.CAVITY_COUNT:
		_fail("wave jump could not revive and restart a boss encounter")
		return
	var saved: Dictionary = game.RUN_SNAPSHOT.capture(game)
	game.free()
	await process_frame
	session.save_run(saved)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	if not game.has_node("DebugCheatMenu") or game.coins != 1234 or game.wave.current_wave != 5 or game.items.count(item.id) != added or game.player.stats.damage != 300:
		_fail("modified build or cheat access was lost on resume")
		return
	session.clear_run()
	game.free()
	paused = false
	print("PASS debug_cheat_menu")
	quit()


func _key(menu: DebugCheatMenu, key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	root.push_input(event, true)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
