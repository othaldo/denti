class_name UnlockBadge
extends RefCounted
## Small "Neu" tag on a selection tile for an unlock the player has not tried yet.

const NAME := "NewBadge"


static func attach(tile: Control) -> Label:
	var badge := tile.get_node_or_null(NAME) as Label
	if badge != null: return badge
	badge = Label.new()
	badge.name = NAME
	badge.text = "Neu"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", DentiUIStyle.GOLD_INK)
	var box := MenuStyle.box(DentiUIStyle.GOLD, Color.TRANSPARENT, 6, 0)
	box.content_margin_left = 5
	box.content_margin_right = 5
	badge.add_theme_stylebox_override("normal", box)
	tile.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	badge.position = Vector2(6, 6)
	return badge


static func fresh(key: String) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var session := tree.root.get_node_or_null("GameSession") if tree != null else null
	return session != null and session.is_fresh(key)
