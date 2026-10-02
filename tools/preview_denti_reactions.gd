extends SceneTree

const FPS := 30.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(900, 460)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(900, 460)
	DisplayServer.window_set_size(root.size)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://denti_reaction_preview.json"
	session.report_dir = "user://denti_reaction_preview_reports"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.player.set_physics_process(false)
	game.player.get_node("Camera2D").enabled = false
	root.canvas_transform = Transform2D.IDENTITY
	game.player.position = Vector2(240, 265)
	for child in game.get_children():
		if child != game.player and child is CanvasItem:
			child.visible = false
		elif child is CanvasLayer:
			child.visible = false
	game.player.loadout.visible = false
	paused = false
	var background := ColorRect.new()
	background.color = Color("fff7e5")
	background.size = Vector2(root.size)
	root.add_child(background)
	root.move_child(background, 0)
	_label("Denti · Reaktionen", Vector2(64, 15), 28)
	var caption := _label("Normal / Blinzeln", Vector2(64, 67), 24)
	_label("Spielgröße", Vector2(190, 350), 19)
	_label("Doppelte Größe", Vector2(545, 350), 19)
	var large := Sprite2D.new()
	large.texture = preload("res://assets/denti/denti_unarmed.png")
	large.scale = game.player.sprite_base_scale * 2.0
	large.position = Vector2(620, 265)
	var other := DentiExpressions.new()
	large.add_child(other)
	root.add_child(large)
	other.configure(game.player.stats)
	game.player.expressions.next_blink = 0.3
	other.next_blink = 0.3
	var faces: Array[DentiExpressions] = [game.player.expressions, other]
	for frame in 420:
		match frame:
			30:
				caption.text = "Treffer · Autsch!"
				game.player.take_hit(12.0)
			54:
				caption.text = "Heilung · Erleichterung"
				game.player.stats.heal(5.0)
			90:
				caption.text = "Vergiftet · Anzeige vorbereitet"
				for face in faces: face.set_status(DentiExpressions.Status.POISON)
			120:
				caption.text = "Treffer überlagert Gift · Bläschen bleiben"
				game.player.take_hit(12.0)
			150:
				caption.text = "Gift + Blutung · Beide Hinweise sichtbar"
				for face in faces: face.set_status(DentiExpressions.Status.BLEED)
			180:
				caption.text = "Heilung überlagert Status · Hinweise bleiben"
				game.player.stats.heal(10.0)
			210:
				caption.text = "Blutend · Anzeige vorbereitet"
				for face in faces: face.set_status(DentiExpressions.Status.POISON, false)
			240:
				caption.text = "Wenig HP · Besorgt"
				for face in faces: face.set_status(DentiExpressions.Status.BLEED, false)
				game.player.stats.health = 20.0
				game.player.stats.changed.emit()
			270:
				caption.text = "Schildblock · Selbstbewusst"
				game.player.stats.grant_shield(1)
				game.player.take_hit(8.0)
			300:
				caption.text = "Welle geschafft · Jubel"
				game.player.stats.health = 80.0
				game.player.stats.changed.emit()
				for face in faces: face.celebrate()
			348:
				caption.text = "Ausweichen · Zwinkern für später vorbereitet"
				for face in faces: face.show_dodge()
			372:
				caption.text = "Tod · Hat Vorrang vor allen Reaktionen"
				game.player.stats.take_damage(1000.0)
				game.choice_panel.visible = false
		if game.player.stats.health > 0.0:
			game.player._animate_sprite(Vector2.ZERO, 1.0 / FPS)
			game.player.hurt_time = maxf(game.player.hurt_time - 1.0 / FPS, 0.0)
			game.player.sprite.modulate = Color(1.0, 0.55, 0.55) if game.player.hurt_time > 0.0 else Color.WHITE
		large.position = Vector2(620, 265) + game.player.sprite.position * 2.0
		large.rotation = game.player.sprite.rotation
		large.scale = game.player.sprite.scale * 2.0
		large.modulate = game.player.sprite.modulate
		await process_frame
	session.clear_run()
	paused = false
	quit()

func _label(text: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override("font", DentiUIStyle.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	root.add_child(label)
	return label
