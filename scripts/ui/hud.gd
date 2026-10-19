class_name GameHUD
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")
const BOSS_ART := "res://assets/ui/boss_hud_frame.png"

@onready var wave_label: Label = $Root/WaveInfo/Wave
@onready var timer_label: Label = $Root/WaveInfo/Timer
@onready var clock_icon: TextureRect = $Root/WaveInfo/ClockIcon
@onready var wave_frame: Control = $Root/WaveFrame
@onready var wave_info: Control = $Root/WaveInfo
@onready var boss_area: Control = $Root/BossArea
@onready var fps_panel: Control = $Root/FPSPanel
@onready var fps_label: Label = $Root/FPSPanel/FPS
@onready var telemetry_panel: Panel = $Root/TelemetryPanel
@onready var telemetry_label: Label = $Root/TelemetryPanel/Telemetry
@onready var session: Node = get_node("/root/GameSession")

var health_vessel: HUDToothVessel
var health_bar: HUDToothVessel
var health_label: Label
var status_badges: Array[HUDStatusBadge] = []
var xp_bar: ProgressBar
var level_medallion: HUDProgressionFrame
var level_label: Label
var pending_badge: HUDPendingLevels
var pending_label: Label
var economy: Control
var coins_label: Label
var chests_label: Label
var boss_rows: Array[Control] = []
var boss_frames: Array[HUDPaintedFrame] = []
var boss_bars: Array[ProgressBar] = []
var boss_labels: Array[Label] = []
var boss_percentages: Array[Label] = []
var boss_count: int = 0
# First-boss aliases also used by the debug test arena.
var boss_label: Label
var boss_bar: ProgressBar
var fps_refresh_time: float = 0.0
var _pause_button: Button
var dash_indicator: DashButton
var _dash_touch_button: DashButton


func _ready() -> void:
	$Root.theme = DentiUIStyle.make_theme()
	health_vessel = HUDToothVessel.new()
	health_vessel.name = "ToothVessel"
	$Root/Vitals.add_child(health_vessel)
	health_bar = health_vessel
	health_label = health_vessel.label
	for kind in [HUDStatusBadge.Kind.POISON, HUDStatusBadge.Kind.BLEED]:
		var badge := HUDStatusBadge.new(kind)
		$Root/Statuses.add_child(badge)
		status_badges.append(badge)
		badge.show_amount(0)
	_build_progression()
	_build_economy()
	_build_bosses()
	dash_indicator = DashButton.new()
	dash_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Root.add_child(dash_indicator)
	DentiUIStyle.style_hud_panel(telemetry_panel)
	for caption: Label in [wave_label, timer_label, fps_label, telemetry_label]:
		DentiUIStyle.style_hud_text(caption, DentiUIStyle.INK, 12, 4, DentiUIStyle.BACKGROUND)
	clock_icon.texture = HUDStatusIcons.texture(&"inflammation")
	clock_icon.visible = false
	session.fps_display_changed.connect(_set_fps_visible)
	_set_fps_visible(session.show_fps)
	$Root.resized.connect(_layout)
	_layout()


func _label(parent: Node, id: String, font_size: int, color: Color = DentiUIStyle.INK) -> Label:
	var caption := Label.new()
	caption.name = id
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DentiUIStyle.style_hud_text(caption, color, font_size, 3, DentiUIStyle.BACKGROUND)
	parent.add_child(caption)
	return caption


func _build_progression() -> void:
	xp_bar = ProgressBar.new()
	xp_bar.name = "XP"
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.show_percentage = false
	$Root/Progression.add_child(xp_bar)
	DentiUIStyle.style_progress(xp_bar, DentiUIStyle.MINT)
	var track := xp_bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	track.bg_color = Color("493347")
	xp_bar.add_theme_stylebox_override("background", track)
	level_medallion = HUDProgressionFrame.new()
	level_medallion.name = "LevelMedallion"
	level_medallion.tooltip_text = "Aktuelles Level"
	$Root/Progression.add_child(level_medallion)
	level_label = _label(level_medallion, "Level", 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pending_badge = HUDPendingLevels.new()
	pending_badge.name = "PendingLevels"
	pending_badge.tooltip_text = "Offene Aufstiege nach der Welle"
	$Root/Progression.add_child(pending_badge)
	pending_label = pending_badge.label
	pending_badge.visible = false


func _build_economy() -> void:
	economy = $Root/Economy
	coins_label = _counter("Coins", ICONS.hud(2), DentiUIStyle.GOLD, 0, 76)
	chests_label = _counter("WaveChests", CombatSpriteTextures.loot(&"chest"), DentiUIStyle.MINT, 80, 48)


func _counter(id: String, texture: Texture2D, color: Color, x: float, width: float) -> Label:
	var cell := Control.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	economy.add_child(cell)
	cell.position = Vector2(x, 0)
	cell.size = Vector2(width, 24)
	var icon := TextureRect.new()
	icon.name = "ChestIcon" if id == "WaveChests" else "CoinIcon"
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)
	icon.position = Vector2(0, 3)
	icon.size = Vector2(18, 18)
	var caption := _label(cell, id, 13, color)
	caption.position = Vector2(22, 0)
	caption.size = Vector2(width - 22, 24)
	caption.text = "0"
	return caption


func _build_bosses() -> void:
	for index in 2:
		var row := Control.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_area.add_child(row)
		boss_rows.append(row)
		var frame := HUDPaintedFrame.new(BOSS_ART)
		frame.name = "PaintedFrame"
		row.add_child(frame)
		boss_frames.append(frame)
		var caption := _label(row, "Name", 13)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		caption.add_theme_color_override("font_color", DentiUIStyle.GOLD)
		boss_labels.append(caption)
		var percentage := _label(row, "Percentage", 13, DentiUIStyle.INK)
		percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		boss_percentages.append(percentage)
		var bar := ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.show_percentage = false
		row.add_child(bar)
		# Range owns the displayed value; the painted inset renders its ratio
		# directly so the fill follows both curved tooth ends without black gaps.
		bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
		bar.add_theme_stylebox_override("fill", StyleBoxEmpty.new())
		row.move_child(bar, 0)
		boss_bars.append(bar)
	boss_label = boss_labels[0]
	boss_bar = boss_bars[0]


func bind_mobile_controls(controls: MobileControls) -> void:
	_dash_touch_button = controls.dash_button
	dash_indicator.player = controls.player
	controls.dash_button.player = controls.player
	_pause_button = controls.pause_button
	_pause_button.text = ""
	_pause_button.icon = HUDStatusIcons.texture(&"pause")
	_pause_button.expand_icon = true
	_pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_button.add_theme_constant_override("icon_max_width", 22)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		_pause_button.add_theme_color_override(state, Color.WHITE)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := _pause_button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.set_corner_radius_all(24)
		style.border_color = DentiUIStyle.GOLD
		style.set_border_width_all(2)
		style.content_margin_left = 0
		style.content_margin_right = 0
		_pause_button.add_theme_stylebox_override(state, style)
	_pause_button.tooltip_text = "Pause"
	controls.visibility_changed.connect(_layout)
	_pause_button.visibility_changed.connect(_layout)
	_layout()


func _layout() -> void:
	if health_vessel == null:
		return
	dash_indicator.visible = _dash_touch_button == null or not _dash_touch_button.get_parent().visible
	HUDLayout.apply(self, $Root.size, _pause_button, _dash_touch_button)


func update_dash() -> void:
	dash_indicator.refresh()
	if _dash_touch_button != null:
		_dash_touch_button.refresh()


func _process(delta: float) -> void:
	if not fps_panel.visible:
		return
	fps_refresh_time -= delta
	if fps_refresh_time > 0:
		return
	fps_refresh_time = 0.25
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _set_fps_visible(enabled: bool) -> void:
	fps_panel.visible = enabled
	fps_refresh_time = 0.0


func toggle_telemetry() -> void:
	telemetry_panel.visible = not telemetry_panel.visible


func update_telemetry(stats: RunTelemetry, enemies_alive: int, projectiles_alive: int) -> void:
	if not telemetry_panel.visible:
		return
	telemetry_label.text = "DEBUG · WELLE %d · %s\nDPS 10 s: %.1f  ·  Peak: %.1f\nKills/s: %.1f  ·  Kills: %d\nGegner: %d  ·  Spawns: %d (%.0f/min)\nAm Limit geblockt: %d\nProjektile: %d\nSchaden/min: %.1f  ·  Total: %.0f\nBoss-TTK: %.1f s\nMünzen/XP: %d / %d\nRun-Schaden: %.0f" % [
		stats.current_wave, _profile_label(stats.current_profile_id, stats.current_wave), stats.recent_dps(), stats.peak_dps,
		stats.recent_kps(), stats.kills, enemies_alive, stats.wave_spawns, stats.spawns_per_minute(),
		stats.wave_spawns_blocked, projectiles_alive, stats.taken_per_minute(), stats.damage_taken,
		stats.last_boss_ttk, stats.wave_coins, stats.wave_xp, stats.total_damage,
	]
	telemetry_label.text += "\nZahnflutsch: %d Welle · %d Run" % [stats.wave_dodges, stats.dodges]
	telemetry_label.text += "\nDash: %d · Kontaktstopps: %d · HP: %.1f" % [stats.dashes, stats.dash_contacts, stats.dash_damage]
	telemetry_label.text += "\nGift/Blutung HP: %.1f / %.1f" % [stats.status_damage.get("poison", 0.0), stats.status_damage.get("bleed", 0.0)]
	telemetry_label.text += "\nKette %.0f · Eis %.0f · Weihe %.0f" % [stats.proc_damage.get("affix_electric_chain", 0.0), stats.proc_damage.get("affix_ice_shatter", 0.0), stats.proc_damage.get("affix_holy", 0.0)]
	telemetry_label.text += "\nLebensraub %.1f HP · Nässe %.0f" % [stats.enchantment_support.get("leech_healing", 0.0), stats.enchantment_support.get("wet_hits", 0.0)]
	telemetry_panel.offset_bottom = telemetry_panel.offset_top + ceilf(telemetry_label.get_theme_font("font").get_height(telemetry_label.get_theme_font_size("font_size")) * telemetry_label.text.split("\n").size()) + 16


func update_ailments(effects: PlayerStatusEffects) -> void:
	for kind in 2:
		var state: Dictionary = effects.active.get(kind, {})
		status_badges[kind].show_amount(float(state.get("remaining", 0)))


func _profile_label(id: StringName, wave_number: int) -> String:
	var profile := WaveProfileCatalog.by_id(id)
	if profile != null:
		return profile.display_name
	return "Bosswelle" if WaveController.is_boss_wave(wave_number) else "Standard"


func update_status(stats: PlayerStats, xp: int, xp_goal: int, level: int, coins: int, wave_number: int, remaining: float, in_shop: bool, boss: Enemy, boss_pending: bool, collecting_loot: bool = false, pending_levels: int = 0, endless: bool = false) -> void:
	health_vessel.show_value(stats.health, stats.max_health, "%s / %s" % [compact_number(ceili(stats.health)), compact_number(ceili(stats.max_health))])
	xp_bar.max_value = xp_goal
	xp_bar.value = xp
	coins_label.text = compact_number(coins)
	level_label.text = compact_number(level)
	pending_badge.show_count(pending_levels)
	health_vessel.show_shield(stats.shield_charges)
	wave_label.text = "%s %d" % ["Endlos" if endless else "Welle", wave_number]
	var seconds := maxi(ceili(remaining), 0)
	var inflamed := boss_pending and is_instance_valid(boss) and boss.overtime_active
	if boss_pending:
		timer_label.text = "+%d s" % boss.overtime_seconds if inflamed else "Boss besiegen!"
	elif collecting_loot:
		timer_label.text = "Beute sammeln"
	else:
		timer_label.text = "Shop-Pause" if in_shop else "%d:%02d" % [seconds / 60, seconds % 60]
	timer_label.tooltip_text = "Entzündet " + timer_label.text if inflamed else timer_label.text
	clock_icon.visible = inflamed
	var timer_color := Color("ffad66") if boss_pending else DentiUIStyle.GOLD if remaining <= 15 and not in_shop and not collecting_loot else DentiUIStyle.INK
	timer_label.add_theme_color_override("font_color", timer_color)
	clock_icon.modulate = Color.WHITE
	fit_timer_text()
	var bosses: Array[Enemy] = []
	if is_instance_valid(boss):
		bosses.append(boss)
	update_bosses(bosses)


func set_reward_focus(enabled: bool) -> void:
	pending_badge.set_reward_focus(enabled)


func fit_timer_text() -> void:
	var preferred := 24 if wave_info.size.x >= 160 else 22
	var font_size := preferred
	var font := timer_label.get_theme_font("font")
	while font_size > 12 and font.get_string_size(timer_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + (font_size + 6 if clock_icon.visible else 0) > wave_info.size.x:
		font_size -= 1
	if timer_label.get_theme_font_size("font_size") != font_size:
		timer_label.add_theme_font_size_override("font_size", font_size)
	var text_width := ceilf(font.get_string_size(timer_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var icon_space := float(font_size + 6) if clock_icon.visible else 0.0
	var left := (wave_info.size.x - text_width - icon_space) * 0.5
	timer_label.position = Vector2(left + icon_space, 16)
	timer_label.size = Vector2(text_width, 28)
	clock_icon.position = Vector2(left, 16 + (28 - font_size) * 0.5)
	clock_icon.size = Vector2.ONE * font_size


func update_bosses(bosses: Array[Enemy]) -> void:
	var count := mini(bosses.size(), 2)
	boss_area.visible = count > 0
	if count != boss_count:
		boss_count = count
		_layout()
	for index in 2:
		var active := index < count and is_instance_valid(bosses[index])
		boss_rows[index].visible = active
		boss_bars[index].visible = active
		boss_labels[index].visible = active
		if active:
			var boss := bosses[index]
			boss_bars[index].max_value = boss.max_health
			boss_bars[index].value = boss.health
			boss_frames[index].show_health(boss_bars[index].ratio)
			boss_labels[index].text = boss.data.display_name
			boss_percentages[index].text = "%d %%" % ceili(100.0 * boss.health / maxf(boss.max_health, 1))
			boss_labels[index].tooltip_text = "%s · %d / %d" % [boss.data.display_name, ceili(boss.health), ceili(boss.max_health)]


static func compact_number(value: int) -> String:
	if absi(value) >= 1000000:
		return ("%.1fM" % (value / 1000000.0)).replace(".", ",")
	if absi(value) >= 10000:
		return ("%.1fk" % (value / 1000.0)).replace(".", ",")
	return str(value)
