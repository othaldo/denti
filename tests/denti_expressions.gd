extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_denti_expressions.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.set_physics_process(false)
	var face: DentiExpressions = game.player.expressions
	face.set_process(false)
	var stats: PlayerStats = game.player.stats
	_check(face.face_sprite.get_parent() == face and face.get_parent() == game.player.sprite, "face does not inherit the existing body animation")
	var original_size := float((preload("res://assets/denti/denti_unarmed.png") as Texture2D).get_width()) * 0.067
	_check(is_equal_approx(game.player.sprite.scale.x * float(game.player.sprite.texture.get_width()), original_size), "layer split changed Denti's gameplay size: scale %s / base %s / texture %s" % [game.player.sprite.scale, game.player.sprite_base_scale, game.player.sprite.texture.get_size()])
	_check(face.current_face == DentiExpressions.Face.NORMAL and face.face_sprite.frame == 0, "default face is not normal")
	var atlas := DentiExpressions.ATLAS.get_image()
	_check(atlas.detect_alpha() and DentiExpressions.BODY.get_image().detect_alpha(), "new art lost transparency")
	var cell_size := Vector2i(atlas.get_width() / 4, atlas.get_height() / 3)
	for index in 12:
		var cell := atlas.get_region(Rect2i(Vector2i((index % 4) * cell_size.x, (index / 4) * cell_size.y), cell_size))
		var bounds := _visible_bounds(cell)
		_check(bounds.size.x > 100 and bounds.size.y > 50 and bounds.position.x > 2 and bounds.end.x < cell_size.x - 2 and bounds.end.y < cell_size.y - 2, "face artwork is empty or clipped at its frame edge: %s / %s" % [index, bounds])
	face.next_blink = 0.0
	face._process(0.01)
	_check(face.current_face == DentiExpressions.Face.BLINK, "idle did not blink")
	face._process(face.settings.blink_duration + 0.01)
	_check(face.current_face == DentiExpressions.Face.NORMAL, "blink did not return to normal")
	game.player.take_hit(10.0)
	_check(face.current_face == DentiExpressions.Face.HURT and stats.health == 90.0, "actual damage did not show hurt")
	stats.heal(1.0)
	_check(face.current_face == DentiExpressions.Face.HURT, "healing overrode a higher-priority hurt reaction")
	face._process(face.settings.hurt_duration + 0.01)
	stats.heal(1.0)
	_check(face.current_face == DentiExpressions.Face.HEAL, "actual healing did not show relief")
	face._process(face.settings.heal_duration + 0.01)
	stats.heal(1.0)
	_check(face.current_face == DentiExpressions.Face.NORMAL, "frequent healing restarted the face before its cooldown")
	face._process(face.settings.heal_cooldown)
	for tick in 4:
		stats.heal(0.15)
	_check(face.current_face == DentiExpressions.Face.HEAL, "small XP heals never accumulated a visible healing reaction")
	face._process(face.settings.heal_cooldown)
	stats.health = stats.max_health
	stats.heal(5.0)
	_check(face.current_face != DentiExpressions.Face.HEAL, "overheal with zero actual healing played relief")
	stats.health = 20.0
	stats.changed.emit()
	_check(face.current_face == DentiExpressions.Face.LOW_HEALTH, "low HP did not persistently show worry")
	face.set_status(DentiExpressions.Status.POISON)
	face.set_status(DentiExpressions.Status.BLEED, true, 5.0)
	_check(face.current_face == DentiExpressions.Face.POISON_BLEED and face.statuses.size() == 2, "simultaneous statuses lost a face or indicator")
	var health_before := stats.health
	face._process(0.5)
	_check(stats.health == health_before, "visual status hooks changed combat health")
	stats.damage_taken.emit(1.0)
	_check(face.current_face == DentiExpressions.Face.HURT and face.has_status(DentiExpressions.Status.POISON), "hit did not overlay status while preserving its indicator")
	face._process(face.settings.hurt_duration + 0.01)
	_check(face.current_face == DentiExpressions.Face.POISON_BLEED, "hit did not return to persistent status")
	var saved: Dictionary = RunSnapshot.capture(game)
	_check(saved.player.presentation.statuses.has("0") and saved.player.presentation.statuses.has("1"), "run snapshot omitted active presentation statuses")
	game.free()
	session.save_run(saved)
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.player.set_physics_process(false)
	face = game.player.expressions
	face.set_process(false)
	stats = game.player.stats
	_check(face.current_face == DentiExpressions.Face.POISON_BLEED and is_equal_approx(float(face.statuses[DentiExpressions.Status.BLEED]), float(saved.player.presentation.statuses["1"])), "resume lost status expression or remaining duration")
	face._process(6.0)
	_check(face.current_face == DentiExpressions.Face.POISON and not face.has_status(DentiExpressions.Status.BLEED), "timed status did not expire")
	face.set_status(DentiExpressions.Status.POISON, false)
	_check(face.current_face == DentiExpressions.Face.LOW_HEALTH, "cleared status did not reveal the underlying low-HP face")
	stats.grant_shield(1)
	game.player.hurt_time = 0.0
	game.player.take_hit(5.0)
	_check(face.current_face == DentiExpressions.Face.BLOCK and stats.health == 20.0, "blocked hit showed hurt or changed HP")
	face._process(face.settings.block_duration + 0.01)
	face.show_dodge()
	_check(face.current_face == DentiExpressions.Face.DODGE, "future dodge presentation hook is missing")
	face._process(face.settings.dodge_duration + 0.01)
	face.celebrate()
	_check(face.current_face == DentiExpressions.Face.CELEBRATE, "wave celebration hook is missing")
	# The state reacts synchronously: death can pause the tree in the same frame.
	stats.take_damage(1000.0)
	_check(paused and face.current_face == DentiExpressions.Face.DEAD and not face.react(DentiExpressions.Face.HEAL, 1.0), "death was overwritten or awaited an unpaused animation tick")
	face.restore({})
	_check(face.statuses.is_empty() and face.current_face == DentiExpressions.Face.DEAD, "legacy restore did not clear cosmetic statuses")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0:
		print("PASS denti_expressions")
	quit(0 if failures == 0 else 1)

func _visible_bounds(image: Image) -> Rect2i:
	# Ignore near-transparent generation/antialiasing dust, which is invisible at
	# gameplay size; check that the actual painted features fit their atlas cell.
	image.convert(Image.FORMAT_RGBA8)
	var bytes := image.get_data()
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if bytes[(y * image.get_width() + x) * 4 + 3] >= 128:
				minimum = Vector2i(mini(minimum.x, x), mini(minimum.y, y))
				maximum = Vector2i(maxi(maximum.x, x), maxi(maximum.y, y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
