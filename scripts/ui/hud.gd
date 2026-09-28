class_name GameHUD
extends CanvasLayer

@onready var health_label: Label = $Root/Vitals/HealthArea/Health
@onready var health_bar: ProgressBar = $Root/Vitals/HealthArea/HealthBar
@onready var xp_label: Label = $Root/Vitals/XPArea/XPLabel
@onready var xp_bar: ProgressBar = $Root/Vitals/XPArea/XP
@onready var coins_label: Label = $Root/Vitals/Coins
@onready var wave_label: Label = $Root/WaveInfo/Wave
@onready var timer_label: Label = $Root/WaveInfo/Timer
@onready var boss_area: Control = $Root/WaveInfo/BossArea
@onready var boss_label: Label = $Root/WaveInfo/BossArea/BossName
@onready var boss_bar: ProgressBar = $Root/WaveInfo/BossArea/BossHealth


func _ready() -> void:
	$Root.theme = DentiUIStyle.make_theme()
	DentiUIStyle.style_hud_text(health_label, DentiUIStyle.CREAM, 17)
	DentiUIStyle.style_hud_text(xp_label, DentiUIStyle.CREAM, 15)
	DentiUIStyle.style_hud_text(coins_label, DentiUIStyle.GOLD, 23)
	DentiUIStyle.style_hud_text(wave_label, DentiUIStyle.CREAM, 22)
	DentiUIStyle.style_hud_text(timer_label, DentiUIStyle.CREAM, 42, 5)
	DentiUIStyle.style_hud_text(boss_label, DentiUIStyle.CREAM, 16)
	DentiUIStyle.style_progress(health_bar, DentiUIStyle.CORAL)
	DentiUIStyle.style_progress(xp_bar, DentiUIStyle.MINT)
	DentiUIStyle.style_progress(boss_bar, DentiUIStyle.CORAL)


func update_status(stats: PlayerStats, xp: int, xp_goal: int, level: int, coins: int, wave_number: int, remaining: float, in_shop: bool, boss: Enemy, boss_pending: bool) -> void:
	health_label.text = "Leben %d / %d" % [ceili(stats.health), ceili(stats.max_health)]
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	xp_label.text = "XP %d / %d  ·  Lv. %d" % [xp, xp_goal, level]
	coins_label.text = "Münzen %d" % coins
	wave_label.text = "Welle %d / %d" % [wave_number, WaveController.MAX_WAVES]
	var seconds := ceili(remaining)
	if boss_pending:
		timer_label.text = "Boss besiegen!"
	else:
		timer_label.text = "Shop-Pause" if in_shop else "%d:%02d" % [seconds / 60, seconds % 60]
	var timer_font_size := 28 if in_shop or boss_pending else 42
	if timer_label.get_theme_font_size("font_size") != timer_font_size:
		timer_label.add_theme_font_size_override("font_size", timer_font_size)
	xp_bar.max_value = xp_goal
	xp_bar.value = xp
	xp_bar.tooltip_text = "XP %d / %d" % [xp, xp_goal]
	var boss_visible := is_instance_valid(boss)
	boss_area.visible = boss_visible
	boss_label.visible = boss_visible
	boss_bar.visible = boss_visible
	if boss_visible:
		boss_label.text = "%s · %d / %d" % [boss.data.display_name, ceili(boss.health), ceili(boss.max_health)]
		boss_bar.max_value = boss.max_health
		boss_bar.value = boss.health
