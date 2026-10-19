extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in 4:
		await process_frame


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://combat_hud_test.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	var hud: GameHUD = game.hud
	var stats: PlayerStats = game.player.stats
	game._spawn_enemy(EnemyCatalog.CAVITY_COUNT)
	game._spawn_enemy(EnemyCatalog.CAVITY_EMPEROR)
	var bosses := BossEncounter.remaining(game.get_node("Enemies"))
	_check(bosses.size() == 2, "test setup did not spawn two bosses")
	bosses[0].data = bosses[0].data.duplicate()
	bosses[0].data.display_name = "Karies-Graf mit einem besonders langen Herrschertitel"
	bosses[0].overtime_active = true
	bosses[0].overtime_seconds = 123
	var attacks: Array[Dictionary] = [
		{"kind": DentiStatus.Type.POISON, "damage": 1.0, "duration": 99.0},
		{"kind": DentiStatus.Type.BLEED, "damage": 1.0, "duration": 99.0},
	]
	game.player.status_effects.apply_attacks(attacks)
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		for touch in [false, true]:
			game.mobile_controls.visible = touch
			game.mobile_controls.set_combat_active(touch)
			hud._set_fps_visible(touch)
			stats.max_health = 100
			stats.health = 100
			stats.shield_charges = 0
			hud.update_status(stats, 0, 5, 1, 0, 12, 27, false, null, false)
			hud.chests_label.text = "0"
			hud.update_ailments(game.player.status_effects)
			await _settle()
			_check(not hud.health_vessel.shield_aura.visible, "no-charge state retained the shield shell")
			var progression_geometry := [hud.level_medallion.get_rect(), hud.pending_badge.position]
			for count in [0, 1, 3, 5, 12, 99, 100, 12345]:
				hud.update_status(stats, 0, 5, 18, 0, 12, 27, false, null, false, false, count)
				await _settle()
				_check([hud.level_medallion.get_rect(), hud.pending_badge.position] == progression_geometry, "pending count moved the progression anchor")
				_check(hud.pending_badge.visible == (count > 0), "pending pill visibility does not follow its real count")
				_check(hud.pending_label.text == ("99+" if count >= 100 else str(count)), "pending pill is not capped at 99+")
			var geometry := _geometry(hud)
			_check(hud.timer_label.text == "0:27", "timer is not formatted as minutes:seconds")
			for state in ["large", "boss", "two_bosses", "loot", "shop", "normal"]:
				stats.max_health = 9876543
				stats.health = 8765432
				stats.shield_charges = 999
				hud.update_status(stats, 123456, 987654, 999, 12345678, 30, 0 if state == "boss" else 27, state == "shop", bosses[0] if state in ["boss", "two_bosses"] else null, state == "boss", state == "loot", 123, true)
				hud.chests_label.text = "99"
				if state == "two_bosses":
					hud.update_bosses(bosses)
				await _settle()
				_check(hud.health_vessel.shield_aura.charges == 5 and hud.health_vessel.shield_aura.visible, "HUD did not read actual shield reserves")
				_check(geometry == _geometry(hud), "HUD geometry changed at %s / %s / touch=%s" % [extent, state, touch])
				_check_layout(hud, game.mobile_controls, Vector2(extent), "%s / %s" % [extent, state])
				if state == "two_bosses":
					_check(hud.boss_rows[0].visible and hud.boss_rows[1].visible, "double encounter lost a boss bar")
					_check(hud.boss_bars[1].max_value == bosses[1].max_health and hud.boss_bars[0].value == bosses[0].health, "boss bars combine or mix encounter health")
					_check(hud.boss_labels[0].tooltip_text.contains(bosses[0].data.display_name), "long boss name lost its full detail")
				elif state == "normal":
					_check(not hud.boss_area.visible, "boss bars remain after encounter")
	# Verify the actual game integration, including independent bars and pause details.
	stats.health = 100
	stats.shield_charges = 5
	game._refresh_hud()
	for remaining in range(4, -1, -1):
		stats.take_damage(10, false)
		# The game polls HUD state every 0.1s; advance that normal update while
		# the fixture's combat remains paused.
		game._process(0.11)
		_check(hud.health_vessel.shield_aura.charges == remaining, "blocked hit did not consume the outer HUD shield contour")
		_check(stats.health == 100, "shield display changed block gameplay")
	_check(not hud.health_vessel.shield_aura.visible, "last blocked hit retained a shell")
	game._refresh_hud()
	_check(hud.boss_rows[1].visible, "game refresh did not supply both bosses")
	game.game_menu.visible = true
	game.rewards.pending_levels = 123
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		game.game_menu._show_stats()
		_check((game.game_menu.rows.get_child(1) as Label).text.contains("Offene Aufstiege: 123"), "pause stats do not show the uncapped pending count")
		var wallet: HBoxContainer = game.game_menu.rows.get_child(2)
		var details_link := wallet.get_child(wallet.get_child_count() - 1) as LinkButton
		_check(details_link != null, "pause stats lack the boss details action")
		details_link.pressed.emit()
		await _settle()
		var full_name_found := false
		for label in game.game_menu.build_scroll.get_child(0).get_children():
			if label is Label and label.text.contains(bosses[0].data.display_name):
				full_name_found = true
		_check(full_name_found, "boss details do not expose the full boss name without hover")
		_check(Rect2(Vector2.ZERO, Vector2(extent)).encloses(game.game_menu.build_panel.get_global_rect()), "boss details exceed viewport at %s" % extent)
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Combat HUD: six resolutions, state stability, touch/FPS and two bosses passed")
	finish(0 if failures.is_empty() else 1)


func _geometry(hud: GameHUD) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for control: Control in [hud.get_node("Root/Vitals"), hud.health_vessel, hud.health_label, hud.health_vessel.maximum_label, hud.xp_bar, hud.wave_frame, hud.wave_info, hud.boss_area, hud.level_medallion, hud.pending_badge, hud.coins_label, hud.chests_label]:
		result.append(control.get_global_rect())
	return result


func _check_layout(hud: GameHUD, mobile: MobileControls, extent: Vector2, context: String) -> void:
	_check(hud.wave_frame.size.y <= 44, "timer exceeds 44 pixels")
	_check(hud.xp_bar.size.y <= 6, "XP is not a quiet edge line")
	_check(hud.xp_bar.get_global_rect().position.y >= extent.y - 12, "XP moved away from the bottom edge at " + context)
	_check(is_equal_approx(hud.level_medallion.get_global_rect().get_center().x, extent.x * 0.5), "level is not centred on the XP edge at " + context)
	_check(is_equal_approx(hud.level_medallion.get_global_rect().end.y, extent.y - 2), "level has a different bottom anchor at " + context)
	_check(is_equal_approx(hud.economy.get_global_rect().position.x, hud.get_node("Root/Vitals").get_global_rect().end.x + 16), "coins and capsules are detached from the right of the tooth at " + context)
	_check(is_equal_approx(hud.get_node("Root/Vitals").get_global_rect().end.y, extent.y - 48), "resource group lost its bottom anchor at " + context)
	_check(is_equal_approx(hud.get_node("Root/Statuses").get_global_rect().end.y, hud.get_node("Root/Vitals").get_global_rect().position.y - 20), "status icons do not reserve room for the shield shell at " + context)
	_check(hud.health_vessel.glass.get_rect().encloses(hud.health_label.get_rect()) and hud.health_vessel.glass.get_rect().encloses(hud.health_vessel.maximum_label.get_rect()), "life numbers are not inside the tooth")
	_check(hud.health_label.get_theme_font_size("font_size") == 18, "current life is not the dominant resource number")
	_check(not hud.health_label.get_global_rect().intersects(hud.health_vessel.maximum_label.get_global_rect()), "current and maximum life overlap")
	_check(hud.pending_badge.get_global_rect().intersects(hud.level_medallion.get_global_rect()), "pending levels float away from their medallion")
	var bead := Rect2(hud.level_medallion.global_position + Vector2(40, 15), Vector2(8, 14))
	_check(not hud.pending_badge.get_global_rect().intersects(bead), "pending pill obscures the right enamel bead")
	_check(hud.pending_badge.size.y == 18 and hud.pending_badge.size.x <= 50, "pending pill exceeds its compact footprint")
	_check(hud.pending_label.get_theme_font("font").get_string_size(hud.pending_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= hud.pending_label.size.x, "pending count is clipped")
	_check(Rect2(Vector2.ZERO, extent).encloses(hud.pending_badge.get_global_rect()), "pending level badge extends beyond viewport at " + context)
	for label: Label in [hud.wave_label, hud.timer_label]:
		_check(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x, "wave/timer text is clipped at " + context)
	var timer_group := hud.timer_label.get_global_rect()
	if hud.clock_icon.visible:
		timer_group = timer_group.merge(hud.clock_icon.get_global_rect())
		_check(is_equal_approx(hud.timer_label.position.x - hud.clock_icon.get_rect().end.x, 6), "flame and timer have a disconnected gap")
		_check(hud.clock_icon.size.y == hud.timer_label.get_theme_font_size("font_size"), "flame is not scaled to the timer")
	_check(is_equal_approx(timer_group.get_center().x, hud.wave_info.get_global_rect().get_center().x), "timer and flame are not centred as one group")
	_check(hud.wave_label.get_theme_font_size("font_size") == 13 and hud.fps_label.get_theme_font_size("font_size") >= 12, "secondary combat text is below its reading size")
	if extent.x == 1280:
		_check(hud.boss_area.size.x >= 420 and hud.boss_area.size.x <= 460 and hud.boss_area.size.y <= 48, "desktop boss bars exceed the requested compact footprint")
	if hud.boss_count > 1:
		if extent.x >= 1800:
			_check(hud.boss_rows[0].position.y == hud.boss_rows[1].position.y and hud.boss_rows[1].position.x > hud.boss_rows[0].get_rect().end.x, "wide desktop does not put two bosses side by side")
		else:
			_check(hud.boss_rows[1].position.y - hud.boss_rows[0].get_rect().end.y == 4, "stacked bosses lost their four-pixel gap")
	if mobile.is_visible_in_tree() and mobile.pause_button.visible:
		var pause_style := mobile.pause_button.get_theme_stylebox("normal") as StyleBoxFlat
		_check(pause_style.border_color == DentiUIStyle.GOLD and pause_style.border_width_left >= 2, "pause button lacks the shared gold rim")
	var regions: Array[Control] = [hud.get_node("Root/Vitals"), hud.wave_frame, hud.get_node("Root/Statuses"), hud.economy, hud.level_medallion]
	if hud.boss_area.visible:
		regions.append(hud.boss_area)
	if hud.fps_panel.visible:
		regions.append(hud.fps_panel)
	if mobile.is_visible_in_tree() and mobile.pause_button.visible:
		regions.append(mobile.pause_button)
		regions.append(mobile.dash_button)
		_check(mobile.dash_button.size.x >= 56 and mobile.dash_button.size.y >= 56, "dash touch target is too small")
	elif hud.dash_indicator.visible:
		regions.append(hud.dash_indicator)
	for index in regions.size():
		var rect := regions[index].get_global_rect()
		_check(Rect2(Vector2.ZERO, extent).encloses(rect), "%s outside viewport at %s: %s" % [regions[index].name, context, rect])
		for other in range(index + 1, regions.size()):
			_check(not rect.intersects(regions[other].get_global_rect()), "%s overlaps %s at %s" % [regions[index].name, regions[other].name, context])
	for index in 2:
		if hud.boss_rows[index].visible:
			_check(hud.boss_rows[index].size.y <= 22, "boss frame is too tall")
			_check(hud.boss_labels[index].horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT and hud.boss_percentages[index].get_theme_font_size("font_size") >= 13, "boss name or percentage lacks the requested reading hierarchy")
			_check(not hud.boss_labels[index].get_global_rect().intersects(hud.boss_percentages[index].get_global_rect()), "boss name overlaps percentage")
			_check(hud.boss_bars[index].size.y >= hud.boss_rows[index].size.y * 0.6, "boss resource is a thin strip instead of the filled frame")
			_check(hud.boss_bars[index].get_global_rect().encloses(hud.boss_labels[index].get_global_rect()), "boss name is not overlaid on its health resource")
			_check(hud.boss_bars[index].get_index() < hud.boss_frames[index].get_index() and hud.boss_frames[index].get_index() < hud.boss_labels[index].get_index(), "boss fill does not sit behind the frame and its name")
	_check(hud.health_vessel.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.health_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "tooth HUD captures movement gestures")
	for badge: HUDStatusBadge in hud.status_badges:
		_check(badge.icon.texture != null and badge.icon.size == Vector2(24, 24), "painted status icon is missing or exceeds its reserved slot")
		_check(not badge.icon.get_global_rect().intersects(badge.label.get_global_rect()), "painted status icon overlaps its count or duration")
	var aura := hud.health_vessel.shield_aura
	if aura.visible:
		var aura_rect: Rect2 = aura.get_global_transform() * aura.visual_rect()
		_check(Rect2(Vector2.ZERO, extent).encloses(aura_rect), "shield shell exceeds the viewport at " + context)
		_check(not aura_rect.intersects(hud.get_node("Root/Statuses").get_global_rect()) and not aura_rect.intersects(hud.economy.get_global_rect()), "shield shell overlaps status text or counters at " + context)
		_check(aura.get_index() < hud.health_label.get_index(), "shield veil obscures the life labels")
