class_name WeaponEnchantmentAction
extends Button
## A whole effect row is one focus stop, including its blocked state.

var action_label := ""
var blocked_reason := ""
var details_title := ""
var details_text := ""
var status_label: Label
var original_status := ""

func _ready() -> void:
	focus_entered.connect(_refresh_status)
	focus_exited.connect(_refresh_status)

func controller_actions() -> Dictionary:
	var result := {&"ui_details": "Details"}
	if blocked_reason.is_empty(): result[&"ui_accept"] = action_label
	return result

func _refresh_status() -> void:
	if not is_instance_valid(status_label): return
	var blocked := has_focus() and not blocked_reason.is_empty()
	status_label.text = blocked_reason if blocked else original_status
	status_label.add_theme_color_override("font_color", DentiUIStyle.GOLD if blocked else DentiUIStyle.MUTED)
