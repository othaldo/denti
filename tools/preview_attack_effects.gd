extends SceneTree

var weapons: Array[WeaponInstance] = []
var enemies: Array[Enemy] = []

class ThreadSample extends Node2D:
	var clock := 0.0
	func _draw() -> void:
		AttackEffects.strip(self, AttackEffects.Shape.THREAD, Vector2(60, 20), Vector2(350, -5), 18.0, Color(0.35, 0.9, 1), clock)
		AttackEffects.flash(self, Vector2(350, -5), 15, Color(0.6, 0.94, 1), clock)
		AttackEffects.strip(self, AttackEffects.Shape.SLASH, Vector2(60, 90), Vector2(200, 70), 38.0, Color(1, 0.82, 0.5), clock)

func _initialize() -> void:
	call_deferred("_run")

func _label(parent: Node, message: String, at: Vector2, size: int = 22) -> void:
	var label := Label.new()
	label.text = message
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)

func _weapon(parent: Node2D, id: StringName, at: Vector2) -> WeaponInstance:
	var holder := Node2D.new()
	parent.add_child(holder)
	var weapon := WeaponInstance.new()
	weapon.configure(WeaponCatalog.by_id(id))
	weapon.position = at
	weapon.process_mode = Node.PROCESS_MODE_DISABLED
	holder.add_child(weapon)
	weapon.attack_duration = weapon.data.animation_duration
	weapon.attack_time = weapon.attack_duration * 0.82
	weapon.idle_time = 0
	weapon.update_visual()
	weapon.beam_hit_world = weapon.muzzle_position() + Vector2(350, 0)
	weapons.append(weapon)
	return weapon

func _enemy(parent: Node, data: EnemyData, at: Vector2, kind: int) -> Enemy:
	var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.configure(data, null, 17)
	enemy.position = at
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(enemy)
	enemy.active_special_attack = kind
	enemy.special_phase = Enemy.SpecialPhase.WARNING
	enemy.special_direction = Vector2.RIGHT
	enemy.special_timer = data.warning_time * 0.3
	enemy.boss_move = Enemy.BossMove.CHARGE
	enemy.boss_dash_end = at + Vector2(430, 0)
	enemies.append(enemy)
	return enemy

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 1050)
	root.content_scale_size = root.size
	var scene := Node2D.new()
	root.add_child(scene)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = DentiArena.FLOOR
	floor_sprite.centered = false
	floor_sprite.scale = Vector2(root.size) / floor_sprite.texture.get_size()
	scene.add_child(floor_sprite)
	_label(scene, "DENTI · STRAHLEN, SPRÜHNEBEL UND ANGRIFFSWARNUNGEN", Vector2(35, 20), 27)
	_label(scene, "Schmelzspiegel · Lichtimpuls", Vector2(35, 85))
	_label(scene, "UV-Lampe · breiter Lichtstrom", Vector2(675, 85))
	_weapon(scene, &"enamel_mirror", Vector2(80, 180))
	_weapon(scene, &"uv_lamp", Vector2(685, 180))
	_label(scene, "Fluorid-Sprüher · Tröpfchen und Nebel", Vector2(35, 290))
	_label(scene, "Ketteneffekt und Nahkampf-Nachbild", Vector2(675, 290))
	_weapon(scene, &"fluoride_sprayer", Vector2(95, 420))
	var thread := ThreadSample.new()
	thread.position = Vector2(675, 380)
	scene.add_child(thread)
	_label(scene, "Boss-Charge · Bodendruck", Vector2(35, 535))
	_label(scene, "Geschosswand · Gefahrenfläche", Vector2(675, 535))
	_enemy(scene, WaveController.CAVITY_COUNT, Vector2(80, 670), EnemyData.SpecialAttack.BOSS)
	_enemy(scene, WaveController.ACID_SPITTER, Vector2(690, 670), EnemyData.SpecialAttack.LANE)
	_label(scene, "Gezielte Salve · Flugrichtungen", Vector2(35, 805))
	_label(scene, "Raumkugel · Bahn und Endbereich", Vector2(675, 805))
	_enemy(scene, WaveController.ACID_SPITTER, Vector2(95, 920), EnemyData.SpecialAttack.SHOOT)
	_enemy(scene, WaveController.CAVITY_EMPEROR, Vector2(690, 920), EnemyData.SpecialAttack.SPACE_ORB)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/attack_frames"))
	for frame in 8:
		var seconds := frame / 12.0
		for weapon in weapons:
			weapon.idle_time = seconds
			weapon.queue_redraw()
		for enemy in enemies:
			enemy.special_timer = enemy.data.warning_time * (0.9 - frame / 8.0 * 0.8)
			enemy.queue_redraw()
		thread.clock = seconds
		thread.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png("res://.godot/attack_frames/frame_%02d.png" % frame)
		shot.get_region(Rect2i(0, 520, 1280, 260)).save_png("res://.godot/attack_frames/ground_%02d.png" % frame)
		if frame == 4:
			shot.save_png("res://docs/screenshots/attack_effects.png")
	scene.free()
	quit()
