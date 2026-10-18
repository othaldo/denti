class_name HUDLayout
extends RefCounted

const MARGIN := 12.0
const TIMER_HEIGHT := 44.0
const BOSS_HEIGHT := 22.0
const BOSS_TEXT_OPTICAL_OFFSET := 2.0


static func apply(hud: GameHUD, extent: Vector2, pause_button: Button = null) -> void:
	var safe := safe_rect(extent)
	var bounds := safe.grow(-MARGIN)
	var portrait := extent.y > extent.x
	var desktop := not portrait and extent.x >= 1100 and extent.y >= 600
	var timer_width := 200.0
	var timer_left := bounds.get_center().x - timer_width * 0.5
	var boss_width := minf(450, bounds.size.x)
	var wide := extent.x >= 1800
	var boss_area_width := 912.0 if wide else boss_width
	var boss_left := bounds.get_center().x - boss_area_width * 0.5
	var boss_top := bounds.position.y + (70 if extent.x < 800 else 50)
	# The two counter rows align with the tooth crown, clear of its numbers.
	var vital_height := 108.0 if desktop else 96.0
	var vitals_rect := Rect2(bounds.position.x, safe.end.y - 48 - vital_height, 128, vital_height)
	var statuses_rect := Rect2(bounds.position.x + 22, vitals_rect.position.y - 64, 84, 44)
	var economy_rect := Rect2(vitals_rect.end.x + 16, vitals_rect.position.y + (40 if desktop else 34), 116, 52)
	if portrait:
		timer_left = bounds.position.x + 58
		timer_width = bounds.size.x - 110
		boss_width = bounds.size.x
		boss_area_width = boss_width
		boss_left = bounds.position.x
	elif not desktop:
		if extent.y < 480:
			timer_left = bounds.position.x
			timer_width = 100
			boss_left = bounds.position.x + 116
			boss_width = bounds.end.x - 74 - boss_left
			boss_area_width = boss_width
			boss_top = bounds.position.y
	_place(hud.get_node("Root/Vitals"), vitals_rect)
	_place(hud.health_vessel, Rect2(Vector2.ZERO, vitals_rect.size))
	hud.health_vessel.set_compact(not desktop)
	_place(hud.get_node("Root/Statuses"), statuses_rect)
	for index in 2:
		_place(hud.status_badges[index], Rect2(index * statuses_rect.size.x * 0.5, 0, statuses_rect.size.x * 0.5, 44))
	_place(hud.economy, economy_rect)
	for index in 2:
		var cell := hud.economy.get_child(index) as Control
		var width := economy_rect.size.x
		_place(cell, Rect2(0, index * 28, width, 24))
		(cell.get_child(1) as Label).size.x = width - 22
	_place(hud.wave_frame, Rect2(timer_left, bounds.position.y, timer_width, TIMER_HEIGHT))
	_place(hud.wave_info, hud.wave_frame.get_rect())
	_place(hud.wave_label, Rect2(0, 0, timer_width, 16))
	_place(hud.timer_label, Rect2(0, 16, timer_width, 28))
	hud.wave_label.add_theme_font_size_override("font_size", 13)
	hud.fit_timer_text()
	_place(hud.boss_area, Rect2(boss_left, boss_top, boss_area_width, 48))
	var side_by_side := wide and hud.boss_count > 1
	for index in 2:
		var width := boss_width
		var left := index * (width + 12) if side_by_side else (boss_area_width - width) * 0.5
		_place(hud.boss_rows[index], Rect2(left, 0 if side_by_side else index * 26, width, BOSS_HEIGHT))
		_place(hud.boss_frames[index], Rect2(0, 0, width, BOSS_HEIGHT))
		var inset := hud.boss_frames[index].cap_width() + 2
		var fill_inset := hud.boss_frames[index].cap_width() * 0.68
		_place(hud.boss_bars[index], Rect2(fill_inset, 0, width - fill_inset * 2, BOSS_HEIGHT))
		# Fredoka's visible glyphs sit above the centre of its line box. Align
		# their ink with the painted track, applying the same offset to both.
		var text_top := (BOSS_HEIGHT - 18) * 0.5 + BOSS_TEXT_OPTICAL_OFFSET
		_place(hud.boss_labels[index], Rect2(inset + 2, text_top, width - inset * 2 - 52, 18))
		_place(hud.boss_percentages[index], Rect2(width - inset - 46, text_top, 42, 18))
		hud.boss_labels[index].add_theme_font_size_override("font_size", 13)
	_place(hud.get_node("Root/Progression"), Rect2(Vector2.ZERO, extent))
	_place(hud.xp_bar, Rect2(safe.position.x + 8, safe.end.y - 8, safe.size.x - 16, 5))
	var level_position := Vector2(safe.get_center().x - 24, safe.end.y - 44)
	_place(hud.level_medallion, Rect2(level_position, Vector2(48, 42)))
	# The left attachment stays fixed. Only the pill's right edge follows its
	# content; the centred level and the enamel bead remain unobstructed.
	_place(hud.pending_badge, Rect2(level_position + Vector2(34, -5), hud.pending_badge.content_size()))
	var touch := pause_button != null and pause_button.is_visible_in_tree()
	if pause_button != null:
		pause_button.custom_minimum_size = Vector2(44, 44)
		_place(pause_button, Rect2(bounds.end.x - 44, bounds.position.y, 44, 44))
	_place(hud.fps_panel, Rect2(bounds.end.x - 66, bounds.position.y + (48 if touch else 0), 66, 20))
	_place(hud.telemetry_panel, Rect2(maxf(bounds.position.x, bounds.end.x - 305), boss_top + 80, minf(305, bounds.size.x), hud.telemetry_panel.size.y))


static func safe_rect(extent: Vector2) -> Rect2:
	if OS.get_name() not in ["Android", "iOS"]:
		return Rect2(Vector2.ZERO, extent)
	var safe := DisplayServer.get_display_safe_area()
	var physical := Vector2(DisplayServer.window_get_size())
	if safe.size.x <= 0 or safe.size.y <= 0 or physical.x <= 0 or physical.y <= 0:
		return Rect2(Vector2.ZERO, extent)
	var scale := extent / physical
	return Rect2(Vector2(safe.position) * scale, Vector2(safe.size) * scale).intersection(Rect2(Vector2.ZERO, extent))


static func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
