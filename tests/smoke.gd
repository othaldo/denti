extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameSession").save_path = "user://test_smoke_run.json"
	var scene: PackedScene = load("res://scenes/game/game.tscn")
	var game: Node2D = scene.instantiate()
	root.add_child(game)
	current_scene = game
	game.get_node("WaveController").active = false
	await physics_frame

	var player: Player = game.get_node("Player")
	if player == null or player.stats.health != 100.0:
		_fail("player did not initialize")
		return
	if not paused or game.choice_panel.mode != &"starter" or not player.loadout.equipped().is_empty():
		_fail("new run did not start with an unarmed weapon choice")
		return
	game.choice_panel._on_choice_pressed(0)
	if paused or player.loadout.equipped().size() != 1 or player.loadout.equipped()[0].data.id != &"magic_toothbrush":
		_fail("starter weapon selection did not equip the toothbrush")
		return
	game._refresh_hud()
	for button: Button in [game.choice_panel.buttons[0], game.shop_panel.offer_buttons[0], game.shop_panel.continue_button]:
		if button.get_theme_color("font_focus_color") != DentiUIStyle.INK or button.get_theme_color("font_hover_pressed_color") != DentiUIStyle.INK or button.get_theme_color("font_disabled_color") != DentiUIStyle.INK:
			_fail("menu button text is not readable in every state")
			return
	var hud: GameHUD = game.get_node("HUD")
	var vitals: Control = hud.get_node("Root/Vitals")
	var wave_info: Control = hud.get_node("Root/WaveInfo")
	if vitals.size.x > 270.0 or vitals.size.y > 120.0 or wave_info.size.x > 160.0 or hud.wave_frame.size.x > 180.0:
		_fail("wave HUD takes too much arena space")
		return
	if hud.health_label.get_theme_constant("outline_size") < 3 or hud.timer_label.get_theme_constant("outline_size") < 4:
		_fail("wave HUD text has no readable outline")
		return
	if hud.health_bar.max_value != player.stats.max_health or hud.health_bar.value != player.stats.health:
		_fail("health bar did not show player health")
		return
	var start_position := player.position
	Input.action_press("move_right")
	for frame in 4:
		await physics_frame
	Input.action_release("move_right")
	if player.position.x <= start_position.x:
		_fail("movement input did not move Denti")
		return
	if player.sprite.position.y >= 0.0:
		_fail("Denti did not animate while moving")
		return
	player.position = start_position
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
	for path in [
		"res://data/enemies/plaque.tres",
		"res://data/enemies/bacteria.tres",
		"res://data/enemies/sugar.tres",
		"res://data/enemies/cavity_count.tres",
		"res://data/enemies/cavity_prince.tres",
		"res://data/enemies/cavity_king.tres",
		"res://data/enemies/cavity_emperor.tres",
	]:
		var enemy_data: EnemyData = load(path)
		var sprite_enemy: Enemy = enemy_scene.instantiate()
		sprite_enemy.configure(enemy_data, player)
		game.get_node("Enemies").add_child(sprite_enemy)
		if enemy_data.sprite == null or sprite_enemy.sprite.texture != enemy_data.sprite:
			_fail("enemy sprite was not loaded: " + path)
			return
		sprite_enemy.free()
	game.wave.active = true
	game.wave.spawn_cooldown = 999.0

	var guaranteed_coin_enemy: EnemyData = load("res://data/enemies/plaque.tres").duplicate()
	guaranteed_coin_enemy.coin_drop_chance = 1.0
	game._spawn_enemy(guaranteed_coin_enemy)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.position = player.position + Vector2(95.0, 0.0)
	var enemy_position := enemy.position
	enemy.health = 1.0
	for frame in 120:
		await physics_frame
		if not is_instance_valid(enemy):
			break
	if is_instance_valid(enemy):
		_fail("automatic weapon did not defeat the nearby enemy")
		return
	var impact_visible := false
	for node in game.get_node("Projectiles").get_children():
		if node.impact_time > 0.0:
			impact_visible = true
	if not impact_visible:
		_fail("projectile did not play its impact animation")
		return
	if game.get_node("Loot").get_child_count() != 2:
		_fail("defeated enemy did not drop XP and coin")
		return

	player.global_position = enemy_position
	await physics_frame
	if game.xp < 1 or game.coins < 1:
		_fail("player did not collect both drop types")
		return

	game._on_loot_collected(&"xp", game.xp_goal - game.xp)
	if paused or game.get_node("ChoicePanel").visible or game.rewards.pending_levels != 1:
		_fail("XP interrupted combat instead of queuing a level-up")
		return

	game._spawn_enemy(load("res://data/enemies/plaque.tres"))
	game._spawn_loot(player.position + Vector2(50.0, 0.0), &"coin", 2)
	var projectile: Node2D = load("res://scenes/game/weapon_projectile.tscn").instantiate()
	game.get_node("Projectiles").add_child(projectile)
	var coins_before_wave_end: int = game.coins
	game.get_node("WaveController").active = true
	game.wave._process(game.wave.remaining)
	if not game.collecting_wave_loot or game.get_node("ShopPanel").visible or game.coins != coins_before_wave_end:
		_fail("wave end skipped the visible loot collection")
		return
	if not await _complete_intermission(game):
		_fail("post-wave reward queue did not finish")
		return
	if not paused or not game.get_node("ShopPanel").visible or game.coins != coins_before_wave_end + 2:
		_fail("shop did not open after collecting remaining loot")
		return
	if game.get_node("Enemies").get_child_count() != 0 or game.get_node("Loot").get_child_count() != 0 or game.get_node("Projectiles").get_child_count() != 0:
		_fail("wave transition did not clear the arena")
		return
	if game.get_node("HUD").timer_label.text != "Shop-Pause":
		_fail("timer did not show shop pause")
		return

	game.coins = 100
	game.shop.offers[0] = load("res://data/weapons/shop_floss_whip.tres")
	game._on_shop_buy(0)
	if player.loadout.equipped().size() != 2 or player.loadout.equipped()[1].data.id != &"floss_whip" or game.coins != 93:
		_fail("buying floss did not equip it")
		return
	game.shop.offers[1] = load("res://data/items/metal_crown.tres")
	var armor_before: float = player.stats.armor
	var speed_before: float = player.stats.move_speed
	game._on_shop_buy(1)
	if player.stats.armor != armor_before + 3.0 or player.stats.move_speed != speed_before - 18.0:
		_fail("shop item did not apply both stat changes")
		return
	game.shop.offers[2] = load("res://data/weapons/shop_turbo_drill.tres")
	game._on_shop_buy(2)
	if player.loadout.equipped().size() != 3 or player.loadout.equipped()[2].data.id != &"turbo_drill":
		_fail("buying drill did not equip the third weapon")
		return
	game.shop.offers[2] = load("res://data/weapons/shop_magic_toothbrush.tres")
	game._on_shop_buy(2)
	if player.loadout.equipped().size() != 4 or player.loadout.equipped()[0].tier != 1 or player.loadout.equipped()[-1].data.id != &"magic_toothbrush":
		_fail("buying a matching weapon did not use the free slots")
		return
	player.stats.apply_upgrade(&"regen", 1.0)
	player.stats.health = 80.0
	player.stats._process(1.0)
	if player.stats.health <= 80.0:
		_fail("Speichel did not regenerate health")
		return
	var crit_before: float = player.stats.crit_chance
	player.stats.apply_upgrade(&"crit_chance", 0.08)
	if player.stats.crit_chance <= crit_before:
		_fail("Glanz did not raise critical chance")
		return
	var coins_before_reroll: int = game.coins
	game._on_shop_reroll()
	if game.coins != coins_before_reroll - 2 or game.shop.reroll_cost != 3:
		_fail("reroll cost was not charged")
		return
	if game.shop.offers.size() != 3:
		_fail("reroll did not produce three offers")
		return

	game._on_shop_continue()
	if paused or game.wave.current_wave != 2 or not game.wave.active or game.get_node("ShopPanel").visible:
		_fail("shop continue did not start wave two")
		return
	if game.get_node("HUD").wave_label.text != "WELLE 2" or game.get_node("HUD").timer_label.text != str(ceili(game.wave.duration)):
		_fail("HUD did not show wave number and countdown")
		return
	if game.get_node("Enemies").get_child_count() != 0:
		_fail("wave two did not start with a clean arena")
		return
	for frame in 3:
		await process_frame
	if game.get_node("Enemies").get_child_count() == 0:
		_fail("wave two did not spawn new enemies")
		return
	game._spawn_enemy(load("res://data/enemies/plaque.tres"))
	var wave_two_enemy: Enemy = game.get_node("Enemies").get_child(-1)
	if wave_two_enemy.health <= wave_two_enemy.data.max_health:
		_fail("enemy health did not scale in wave two")
		return
	game._spawn_loot(player.position + Vector2(50.0, 0.0), &"xp", game.xp_goal)
	game.wave._process(game.wave.remaining)
	if not await _complete_intermission(game):
		_fail("wave two rewards did not finish")
		return
	if not paused or game.get_node("Enemies").get_child_count() != 0:
		_fail("wave two did not clear remaining enemies")
		return
	if not game.get_node("ShopPanel").visible or not paused:
		_fail("shop did not open after end-of-wave level-up")
		return

	for expected_wave in range(3, WaveController.MAX_WAVES + 1):
		game._on_shop_continue()
		if game.wave.current_wave != expected_wave or paused:
			_fail("next wave did not start")
			return
		if WaveController.is_boss_wave(expected_wave):
			if not is_instance_valid(game.boss) or not game.get_node("HUD").boss_bar.visible:
				_fail("boss wave did not spawn a visible boss")
				return
			var expected_boss: EnemyData = WaveController.boss_for_wave(expected_wave)
			if game.boss.data != expected_boss:
				_fail("boss wave spawned the wrong boss")
				return
		game.wave._process(game.wave.remaining)
		if WaveController.is_boss_wave(expected_wave) and expected_wave < WaveController.MAX_WAVES:
			if not game.boss_pending or game.get_node("ShopPanel").visible:
				_fail("mini-boss wave ended before the boss was defeated")
				return
			game.boss.boss_phase = 2
			game.boss.boss_phase_timer = 0.0
			game.boss.boss_damage_budget = game.boss.health
			game.boss.take_damage(99999.0)
			if not await _complete_intermission(game):
				_fail("boss rewards did not finish")
				return
		if expected_wave < WaveController.MAX_WAVES and not game.get_node("ShopPanel").visible:
			_fail("shop missing between waves")
			return
	if game.ended or not game.boss_pending or game.get_node("HUD").timer_label.text != "Boss besiegen!":
		_fail("final timer ended the run before the boss was defeated")
		return
	var boss: Enemy = game.boss
	boss.boss_phase = 2
	boss.boss_phase_timer = 0.0
	boss.boss_damage_budget = boss.health
	boss.take_damage(99999.0)
	if not await _complete_intermission(game):
		_fail("final rewards did not finish")
		return
	if not game.ended or not game.get_node("ChoicePanel").visible or game.get_node("ShopPanel").visible:
		_fail("defeating the boss did not end in victory")
		return
	var end_panel: ChoicePanel = game.get_node("ChoicePanel")
	end_panel._on_choice_pressed(1)
	if end_panel.mode != &"credits" or end_panel.title_label.text != "Credits":
		_fail("credits did not open from the end screen")
		return
	end_panel._on_choice_pressed(0)
	if end_panel.mode != &"end" or not end_panel.visible or not end_panel.buttons[1].visible:
		_fail("returning from credits did not restore the end screen")
		return
	paused = false
	print("Denti smoke test passed")
	quit(0)


func _complete_intermission(game: Node2D) -> bool:
	for frame in 180:
		if game.choice_panel.visible and (game.choice_panel.mode == &"upgrade" or game.choice_panel.mode == &"chest" or game.choice_panel.mode == &"relic"):
			game.choice_panel._on_choice_pressed(0)
		if game.shop_panel.visible or game.ended:
			return true
		await physics_frame
	return false


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
