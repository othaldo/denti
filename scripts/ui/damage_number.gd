class_name DamageNumber
extends Label

const LIFETIME := 0.58


func show_amount(at: Vector2, amount: float, player_hit: bool = false) -> void:
	text = "-%d" % maxi(roundi(amount), 1) if player_hit else "%d" % maxi(roundi(amount), 1)
	add_theme_color_override("font_color", Color(1.0, 0.40, 0.35) if player_hit else Color(1.0, 0.88, 0.37))
	_animate(at)


func show_message(at: Vector2, message: String, color: Color) -> void:
	text = message
	add_theme_color_override("font_color", color)
	_animate(at)


func _animate(at: Vector2) -> void:
	global_position = at + Vector2(randf_range(-12.0, 12.0) - size.x / 2.0, -size.y / 2.0)
	scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(randf_range(-14.0, 14.0), -48.0), LIFETIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_delay(0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(queue_free)
