extends SceneTree

var failures: Array[String] = []
var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func fixture(recipe: WeaponEvolutionRecipe) -> void:
	game.player.loadout.restore([])
	game.items.restore({})
	game.player.stats.load_save_data(PlayerStats.new().to_save_data())
	game.player.loadout.acquire(WeaponCatalog.by_id(recipe.base_weapon), 4, 80)
	if recipe.partner_weapon != &"":
		game.player.loadout.acquire(WeaponCatalog.by_id(recipe.partner_weapon), 4, 70)
	for family in recipe.families:
		for item in ShopController.CATALOG:
			if item.family_id == family and item.rarity_tier == 4:
				game.items.acquire(item)
				break
	for id in recipe.items:
		game.items.acquire(ShopController.by_id(id))

func enemy(at: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, at)
	var result: Enemy = game.get_node("Enemies").get_child(-1)
	result.health = 10000
	result.max_health = 10000
	result.set_physics_process(false)
	return result

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.progression_path = "user://test_weapon_evolution_progression.cfg"
	session.discovered_fusions.clear()
	session.save_path = "user://test_weapon_evolutions.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	game.wave.active = false
	game._open_shop()
	paused = true
	check(WeaponEvolutions.ALL.size() == 6, "six recipes missing")
	for recipe in WeaponEvolutions.ALL:
		fixture(recipe)
		check(game.player.loadout.evolution_ready(0, recipe, game.items), "complete rare-variant recipe not accepted: " + str(recipe.id))
		if recipe.partner_weapon != &"":
			check(game.player.loadout.evolution_ready(1, recipe, game.items), "partner selection cannot initiate fusion")
		game.player.loadout.equipped()[0].tier = 3
		check(not game.player.loadout.evolution_ready(0, recipe, game.items), "recipe accepted MK III")
		game.player.loadout.equipped()[0].tier = 4
		var owned: Dictionary = game.items.owned.duplicate()
		game._update_shop_panel()
		game.shop_panel._select("equipment", 0)
		check(game.shop_panel.details.evolution_options.get_child_count() == 3, "fulfilled recipe not revealed")
		var button: Button = game.shop_panel.details.evolution_options.get_child(2)
		check(button.text.contains(recipe.result.display_name), "evolution button does not identify outcome")
		for extent in [Vector2i(1280, 720), Vector2i(720, 1280), Vector2i(568, 320)]:
			root.content_scale_size = extent
			root.size = extent
			for frame in 12:
				await process_frame
			check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.shop_panel.detail_popup.get_global_rect()), "evolution preview escaped viewport")
			if "--capture" in OS.get_cmdline_user_args() and extent == Vector2i(1280, 720):
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/evolution-preview"))
				root.get_texture().get_image().save_png("res://.godot/evolution-preview/" + str(recipe.id) + ".png")
		button.pressed.emit()
		check(game.player.loadout.equipped().size() == 1 and game.player.loadout.equipped()[0].data.id == recipe.result.id, "evolution failed or left ingredient weapon: " + str(recipe.id))
		check(game.player.loadout.used_slots() == recipe.result.hands and game.items.owned == owned, "evolution changed items or root cost")
		check(game.player.loadout.refund_for(0) == (75 if recipe.partner_weapon != &"" else 40), "evolution lost invested coin value")
		var saved: Dictionary = RunSnapshot.capture(game)
		RunSnapshot.restore(game, saved)
		check(game.player.loadout.equipped()[0].data.id == recipe.result.id, "resume lost evolved weapon")
		game.player.loadout.sell(0)
		game.player.loadout.acquire(WeaponCatalog.by_id(recipe.base_weapon), 4)
		if recipe.partner_weapon != &"":
			game.player.loadout.acquire(WeaponCatalog.by_id(recipe.partner_weapon), 4)
		check(game.player.loadout.evolution_ready(0, recipe, game.items), "sale blocked another evolution")
		saved = RunSnapshot.capture(game)
		RunSnapshot.restore(game, saved)
		check(game.player.loadout.evolve(0, recipe, game.items), "resume blocked another evolution")
	# Multiple copies may evolve and survive a resume; legacy limit flags are ignored.
	var repeat_recipe: WeaponEvolutionRecipe = WeaponEvolutions.ALL[0]
	fixture(repeat_recipe)
	check(game.player.loadout.evolve(0, repeat_recipe, game.items), "first repeated evolution failed")
	check(game.player.loadout.acquire(WeaponCatalog.by_id(repeat_recipe.base_weapon), 4), "second ingredient could not be equipped")
	check(game.player.loadout.evolve(1, repeat_recipe, game.items), "second simultaneous evolution blocked")
	var multi_saved: Dictionary = RunSnapshot.capture(game)
	multi_saved["evolution_used"] = true
	RunSnapshot.restore(game, multi_saved)
	check(game.player.loadout.equipped().size() == 2, "resume discarded duplicate special weapon")
	for equipped_weapon in game.player.loadout.equipped():
		check(equipped_weapon.data.id == repeat_recipe.result.id, "resume changed duplicate evolution")
	check(game.player.loadout.acquire(WeaponCatalog.by_id(repeat_recipe.base_weapon), 4), "legacy save blocked ingredient")
	check(game.player.loadout.evolve(2, repeat_recipe, game.items), "legacy run limit still blocks evolution")
	# No spoilers for MK I or IV without complete ingredients.
	for recipe in WeaponEvolutions.ALL:
		game.player.loadout.restore([])
		game.items.restore({})
		game.player.loadout.acquire(WeaponCatalog.by_id(recipe.base_weapon), 4)
		game._update_shop_panel()
		game.shop_panel._select("equipment", 0)
		check(game.shop_panel.details.evolution_options.get_child_count() == 0, "incomplete recipe leaked a hint")
		check(not game.player.loadout.evolve(0, recipe, game.items), "incomplete recipe evolved")
	# Combat mechanics are exercised using actual enemies and damage.
	for recipe in WeaponEvolutions.ALL:
		game._clear_arena(false)
		await process_frame
		fixture(recipe)
		check(game.player.loadout.evolve(0, recipe, game.items), "combat fixture failed")
		var weapon: WeaponInstance = game.player.loadout.equipped()[0]
		weapon.set_physics_process(false)
		var effects: WeaponEvolutionEffects = weapon.evolution
		var a := enemy(game.player.global_position + Vector2(65, 0))
		var b := enemy(a.global_position + Vector2(45, 0))
		var targets: Array[Enemy] = [a, b]
		match recipe.result.evolution_kind:
			&"storm":
				effects.on_hit(a, 100, false)
				effects._physics_process(0.01)
				check(effects.pools.size() == 1 and a.wet_time > 0 and b.health < 10000, "storm pool did not wet and damage neighbors")
			&"thread":
				effects.on_hit(a, 100, false)
				check(effects.threads.size() == 1, "thread was not created")
				game.player.global_position += Vector2(0, 65)
				effects._physics_process(0.01)
				check(effects.threads.is_empty() and b.health < 10000 and b.bleed_stacks > 0, "movement did not snap thread and cause bleed")
			&"drill":
				for hit in 4:
					effects.on_attack(targets, 100, false)
					effects.on_hit(a, 100, false)
				check(b.health < 10000 and effects.drill_charge == 0, "drill did not pierce a target line")
			&"halo":
				var projectile: WeaponProjectile = WeaponInstance.PROJECTILE_SCENE.instantiate()
				game.get_node("Projectiles").add_child(projectile)
				projectile.launch(a.global_position, Vector2.RIGHT, 100, recipe.result, game.items, false, 4)
				check(is_equal_approx(projectile.return_factor, 1.5) and projectile.pierces_left == 0, "halo did not orbit first target or lost stacked return bonus")
				projectile._start_return()
				check(projectile.orbit_time > 0 and not projectile.returning, "halo skipped orbit")
				projectile._physics_process(0.01)
				check(b.health < 10000, "halo orbit did not damage neighbors")
				var saved_orbit := projectile.save_state({a.get_instance_id(): 0, b.get_instance_id(): 1})
				var resumed_projectile: WeaponProjectile = WeaponInstance.PROJECTILE_SCENE.instantiate()
				game.get_node("Projectiles").add_child(resumed_projectile)
				var enemy_nodes: Array[Node] = [a, b]
				resumed_projectile.restore_state(saved_orbit, game.items, enemy_nodes)
				check(resumed_projectile.orbit_time == projectile.orbit_time and resumed_projectile.orbit_hits.size() == projectile.orbit_hits.size(), "halo resume reset orbit or repeated hits")
				projectile._physics_process(recipe.result.evolution_duration)
				check(projectile.returning, "halo did not return after orbit")
			&"trinity":
				effects.on_hit(a, 100, false)
				check(effects.marks.has(a.get_instance_id()) and b.health == 10000, "first paste hit did not mark")
				effects.on_hit(a, 100, false)
				check(not effects.marks.has(a.get_instance_id()) and b.health < 10000, "second paste hit did not detonate")
			&"revelation":
				weapon.aim = Vector2.RIGHT
				check(effects.on_attack(targets, 100, true) and a.health == 10000, "beam fired before charging")
				effects._physics_process(recipe.result.evolution_duration)
				check(a.health < 10000 and b.health < 10000 and effects.flashes.size() == 3, "charged crit beam did not fire three lines")
		var indices := {a.get_instance_id(): 0, b.get_instance_id(): 1}
		var state := effects.save_state(indices)
		var nodes: Array[Node] = [a, b]
		effects.restore_state(state, nodes)
		check(effects.save_state(indices) == state, "evolution runtime changed on restore: " + str(recipe.id))
		if "--capture" in OS.get_cmdline_user_args():
			root.content_scale_size = Vector2i(1280, 720)
			root.size = Vector2i(1280, 720)
			game.shop_panel.close_details()
			game.shop_panel.visible = false
			weapon.update_visual()
			for frame in 12:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.godot/evolution-preview/combat_" + str(recipe.id) + ".png")
			game.shop_panel.visible = true
		if recipe.id == &"storm_shower":
			# Actual weapon-hit routing must reach the component, not just unit calls.
			effects.proc_wait = 0
			var count_before := effects.pools.size()
			WeaponAttackShapes.hit(a, weapon.data, 4, 100, false, game.items, Vector2.RIGHT)
			check(effects.pools.size() == count_before + 1, "real weapon hit bypassed evolution component")
		var active_save: Dictionary = RunSnapshot.capture(game)
		game._clear_arena(false)
		await process_frame
		RunSnapshot.restore(game, active_save)
		var resumed: WeaponInstance = game.player.loadout.equipped()[0]
		var new_indices: Dictionary = {}
		for index in game.get_node("Enemies").get_child_count():
			var restored_enemy: Enemy = game.get_node("Enemies").get_child(index)
			new_indices[restored_enemy.get_instance_id()] = index
		check(resumed.evolution.save_state(new_indices) == active_save.weapon_runtime[0].motion.evolution, "full snapshot changed evolution runtime")
		var projectile_index := 0
		for projectile in game.get_node("Projectiles").get_children():
			if projectile is WeaponProjectile and not projectile.is_queued_for_deletion():
				check(projectile_index < active_save.player_projectiles.size(), "restore duplicated player projectiles")
				if projectile_index < active_save.player_projectiles.size():
					check(projectile.save_state(new_indices) == active_save.player_projectiles[projectile_index], "full snapshot changed projectile orbit/hit state")
				projectile_index += 1
		check(projectile_index == active_save.player_projectiles.size(), "full snapshot lost player projectiles")
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Denti weapon evolutions test passed")
	quit(0 if failures.is_empty() else 1)
