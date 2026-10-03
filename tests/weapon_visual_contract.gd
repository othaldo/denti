extends SceneTree

var game: Node2D
var failures: Array[String] = []
var audit_sheet: Image
var audit_index: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func target(at: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 100000
	enemy.set_physics_process(false)
	return enemy

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_visual_contract.json"
	session.progression_path = "user://test_weapon_visual_contract.cfg"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.choice_panel.hide()
	game.wave.active = false
	paused = true
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	game.player.stats.crit_chance = 0
	audit_sheet = Image.create(1920, 1920, false, Image.FORMAT_RGBA8)
	var caption := Label.new()
	caption.text = ""
	caption.position = Vector2(430, 210)
	caption.add_theme_font_size_override("font_size", 20)
	game.get_node("HUD").add_child(caption)
	var catalog: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		catalog.append(recipe.result)
	for data in catalog:
		for density in [1.0, 0.85]:
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
				game._clear_arena(false)
				for number in game.get_node("DamageNumbers").get_children():
					number.queue_free()
				await process_frame
				game.player.global_position = Vector2(600, 400)
				game.player.loadout.restore([{"id": str(data.id), "tier": 4}])
				var weapon: WeaponInstance = game.player.loadout.equipped()[0]
				weapon.set_physics_process(false)
				weapon.visual_density = density
				var enemy := target(game.player.global_position + direction * minf(210, data.range_at_tier(4)))
				var targets: Array[Enemy] = [enemy]
				weapon.aim = direction
				weapon.update_visual()
				var idle := weapon.sprite.transform
				weapon._begin_attack(targets)
				var health := enemy.health
				if data.attack_mode == &"projectile":
					var projectiles := game.get_node("Projectiles").get_children()
					check(projectiles.size() == data.projectile_count_at_tier(4), "%s: missing salve" % data.id)
					for shot in projectiles:
						check(shot.global_position.distance_to(weapon.muzzle_position()) < 0.01, "%s: projectile detached from muzzle" % data.id)
					var shot: WeaponProjectile = projectiles[0]
					check(shot.direction.dot(shot.global_position.direction_to(enemy.global_position)) > 0.999, "%s: emission misses aim" % data.id)
					var released := shot.global_position
					game.player.global_position += Vector2(15, -10)
					weapon.update_visual()
					check(shot.global_position == released, "%s: released projectile follows player" % data.id)
				if not WeaponMotion.is_contact(data) and data.held_style == "aimed":
					var axis := weapon.sprite.global_position.direction_to(weapon.muzzle_position())
					check(axis.dot(weapon.aim) > 0.998, "%s: painted axis does not align with emission" % data.id)
				if data.attack_mode in [&"beam", &"beam_line"]:
					game.player.global_position += Vector2(-55, 38)
					enemy.global_position += Vector2(20, 30)
					weapon._physics_process(0.02)
					var segment := weapon.beam_segment()
					check(segment[0].distance_to(weapon.muzzle_position()) < 0.01, "%s: moved beam origin stale" % data.id)
					var nearest := Geometry2D.get_closest_point_to_segment(enemy.global_position, segment[0], segment[1])
					check(nearest.distance_to(enemy.global_position) < 0.1, "%s: moving target left visible beam" % data.id)
					check(enemy.health == health, "%s: visual tracking inflicted extra damage" % data.id)
					var saved := weapon.save_motion({enemy.get_instance_id(): 0})
					var enemies: Array[Node] = [enemy]
					weapon.restore_motion(saved, enemies)
					check(weapon.beam_target_id == enemy.get_instance_id(), "%s: resume lost beam target" % data.id)
					if weapon.evolution != null:
						check(weapon.attack_time > weapon.evolution.charge_time, "charged weapon returns to rest before emission")
						weapon.evolution._physics_process(0.02)
						check(weapon.evolution.charge_origin.distance_to(weapon.muzzle_position()) < 0.01, "charge origin is not the current tip")
						weapon.evolution._physics_process(weapon.evolution.charge_time)
						check(enemy.health < health, "charged beam misses tracked target")
						var flash: Dictionary = weapon.evolution.flashes[0]
						game.player.global_position += Vector2(12, 17)
						weapon._physics_process(0.01)
						check(weapon.evolution.flash_segment(flash)[0].distance_to(weapon.muzzle_position()) < 0.01, "released laser detached from moving weapon")
						var effects_saved := weapon.evolution.save_state({enemy.get_instance_id(): 0})
						weapon.evolution.restore_state(effects_saved, enemies)
						check(weapon.evolution.flashes.size() > 0 and weapon.evolution.flashes[0].mounted, "resume discarded active laser")
					else:
						enemy.queue_free()
						await process_frame
						var endpoint := weapon.beam_hit_world
						weapon.restore_motion(weapon.save_motion({}), [])
						game.player.global_position += Vector2(15, 0)
						weapon._physics_process(0.01)
						check(weapon.beam_hit_world == endpoint, "dead target endpoint follows Denti")
						var ended_segment := weapon.beam_segment()
						check(Geometry2D.get_closest_point_to_segment(endpoint, ended_segment[0], ended_segment[1]).distance_to(endpoint) < 0.1, "resume lost final beam contact after target vanished")
				weapon._physics_process(weapon.attack_duration * 0.5)
				check(not weapon.sprite.transform.is_equal_approx(idle), "%s: attack has no motion" % data.id)
				if WeaponMotion.is_contact(data):
					weapon._physics_process(weapon.attack_time)
					check(enemy.health < health, "%s: animated contact misses target" % data.id)
				if "--capture" in OS.get_cmdline_user_args() and density == 1.0 and direction == Vector2.RIGHT:
					weapon.attack_time = weapon.attack_duration * 0.5
					weapon.aim_distance = 100
					weapon.update_visual()
					weapon.queue_redraw()
					var camera: Camera2D = game.player.get_node("Camera2D")
					camera.zoom = Vector2(1.5, 1.5)
					camera.reset_smoothing()
					camera.force_update_scroll()
					caption.text = data.display_name
					await process_frame
					await RenderingServer.frame_post_draw
					DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/weapon-audit"))
					var image := root.get_texture().get_image().get_region(Rect2i(400, 200, 480, 320))
					image.convert(Image.FORMAT_RGBA8)
					image.save_png("res://.godot/weapon-audit/%s.png" % data.id)
					audit_sheet.blit_rect(image, Rect2i(0, 0, 480, 320), Vector2i(audit_index % 4 * 480, audit_index / 4 * 320))
					audit_index += 1
	# Orbit begins at the first physical collision, even across a large frame step.
	game._clear_arena(false)
	await process_frame
	var halo_target := target(game.player.global_position + Vector2(130, 0))
	var halo: WeaponProjectile = WeaponInstance.PROJECTILE_SCENE.instantiate()
	game.get_node("Projectiles").add_child(halo)
	halo.launch(game.player.global_position, Vector2.RIGHT, 20, WeaponCatalog.by_id(&"halo"), game.items, false, 4)
	halo._physics_process(0.8)
	check(halo.orbit_center.distance_to(halo_target.global_position) < 0.01, "halo orbit overshoots first target")
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	paused = false
	if "--capture" in OS.get_cmdline_user_args():
		audit_sheet.save_png("res://.godot/weapon-audit/all-weapons.png")
	if failures.is_empty():
		print("PASS weapon_visual_contract: 24 weapons, 5 directions, 2 densities; tracking, resume and impact")
	quit(0 if failures.is_empty() else 1)
