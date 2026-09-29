class_name GameHUD
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

@onready var health_label: Label = $Root/Vitals/HealthArea/Health
@onready var health_bar: ProgressBar = $Root/Vitals/HealthArea/HealthBar
@onready var xp_label: Label = $Root/Vitals/XPArea/XPLabel
@onready var xp_bar: ProgressBar = $Root/Vitals/XPArea/XP
@onready var coins_label: Label = $Root/Vitals/CoinArea/Coins
@onready var level_label: Label = $Root/Vitals/CoinArea/Level
@onready var wave_label: Label = $Root/WaveInfo/Wave
@onready var timer_label: Label = $Root/WaveInfo/Timer
@onready var wave_frame: Panel = $Root/WaveFrame
@onready var wave_info: VBoxContainer = $Root/WaveInfo
@onready var boss_area: Control = $Root/WaveInfo/BossArea
@onready var boss_label: Label = $Root/WaveInfo/BossArea/BossName
@onready var boss_bar: ProgressBar = $Root/WaveInfo/BossArea/BossHealth
@onready var fps_panel: Panel = $Root/FPSPanel
@onready var fps_label: Label = $Root/FPSPanel/FPS
@onready var session: Node = get_node("/root/GameSession")

var fps_refresh_time: float = 0.0


func _ready() -> void:
	$Root.theme = DentiUIStyle.make_theme()
	DentiUIStyle.style_hud_panel($Root/VitalsFrame)
	DentiUIStyle.style_hud_panel(wave_frame)
	DentiUIStyle.style_hud_panel(fps_panel)
	var light_outline := DentiUIStyle.CREAM
	DentiUIStyle.style_hud_text(health_label, DentiUIStyle.INK, 15, 3, light_outline)
	DentiUIStyle.style_hud_text(xp_label, DentiUIStyle.INK, 14, 3, light_outline)
	DentiUIStyle.style_hud_text(coins_label, DentiUIStyle.INK, 20, 2, light_outline)
	DentiUIStyle.style_hud_text(level_label, DentiUIStyle.INK, 17, 2, light_outline)
	DentiUIStyle.style_hud_text(wave_label, DentiUIStyle.INK, 16, 3, light_outline)
	DentiUIStyle.style_hud_text(timer_label, DentiUIStyle.INK, 30, 4, light_outline)
	DentiUIStyle.style_hud_text(boss_label, DentiUIStyle.INK, 15, 3, light_outline)
	DentiUIStyle.style_hud_text(fps_label, DentiUIStyle.INK, 15, 2, light_outline)
	DentiUIStyle.style_progress(health_bar, DentiUIStyle.CORAL)
	DentiUIStyle.style_progress(xp_bar, DentiUIStyle.MINT)
	DentiUIStyle.style_progress(boss_bar, DentiUIStyle.CORAL)
	$Root/Vitals/HealthArea/HealthIcon.texture = ICONS.hud(0)
	$Root/Vitals/XPArea/XPIcon.texture = ICONS.hud(1)
	$Root/Vitals/CoinArea/CoinIcon.texture = ICONS.hud(2)
	$Root/Vitals/CoinArea/LevelIcon.texture = ICONS.hud(3)
	$Root/WaveInfo/Wave/WaveIcon.texture = ICONS.hud(4)
	$Root/WaveInfo/Timer/ClockIcon.texture = ICONS.hud(5)
	session.fps_display_changed.connect(_set_fps_visible)
	_set_fps_visible(session.show_fps)


func _process(delta: float) -> void:
	if not fps_panel.visible:
		return
	fps_refresh_time -= delta
	if fps_refresh_time > 0.0:
		return
	fps_refresh_time = 0.25
	fps_label.text = "FPS %d" % Engine.get_frames_per_second()


func _set_fps_visible(enabled: bool) -> void:
	fps_panel.visible = enabled
	fps_refresh_time = 0.0


func update_status(stats: PlayerStats, xp: int, xp_goal: int, level: int, coins: int, wave_number: int, remaining: float, in_shop: bool, boss: Enemy, boss_pending: bool) -> void:
	health_label.text = "%d / %d · Schild %d" % [ceili(stats.health), ceili(stats.max_health), stats.shield_charges] if stats.shield_charges > 0 else "%d / %d" % [ceili(stats.health), ceili(stats.max_health)]
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	xp_label.text = "%d / %d" % [xp, xp_goal]
	coins_label.text = "%d" % coins
	level_label.text = "Lv. %d" % level
	wave_label.text = "WELLE %d" % wave_number
	var seconds := ceili(remaining)
	if boss_pending:
		timer_label.text = "Boss besiegen!"
	else:
		timer_label.text = "Shop-Pause" if in_shop else "%d" % seconds
	var timer_font_size := 20 if in_shop or boss_pending else 30
	if timer_label.get_theme_font_size("font_size") != timer_font_size:
		timer_label.add_theme_font_size_override("font_size", timer_font_size)
	timer_label.add_theme_color_override("font_color", DentiUIStyle.GOLD.darkened(0.35) if remaining <= 15.0 and not in_shop and not boss_pending else DentiUIStyle.INK)
	$Root/WaveInfo/Timer/ClockIcon.visible = not in_shop and not boss_pending
	xp_bar.max_value = xp_goal
	xp_bar.value = xp
	xp_bar.tooltip_text = "XP %d / %d" % [xp, xp_goal]
	var boss_visible := is_instance_valid(boss)
	boss_area.visible = boss_visible
	boss_label.visible = boss_visible
	boss_bar.visible = boss_visible
	wave_frame.offset_left = -130.0 if boss_visible else -82.0
	wave_frame.offset_right = 130.0 if boss_visible else 82.0
	wave_frame.offset_bottom = 116.0 if boss_visible else 86.0
	wave_info.offset_left = -118.0 if boss_visible else -74.0
	wave_info.offset_right = 118.0 if boss_visible else 74.0
	if boss_visible:
		boss_label.text = "%s · %d / %d" % [boss.data.display_name, ceili(boss.health), ceili(boss.max_health)]
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
