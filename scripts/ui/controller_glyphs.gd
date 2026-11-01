class_name ControllerGlyphs
extends RefCounted

const TEXTURES := {
	"xbox": {
		&"ui_accept": preload("res://assets/ui/controller/xbox_a.svg"),
		&"ui_cancel": preload("res://assets/ui/controller/xbox_b.svg"),
		&"ui_reroll": preload("res://assets/ui/controller/xbox_x.svg"),
		&"ui_details": preload("res://assets/ui/controller/xbox_rs.svg"),
		&"ui_pin": preload("res://assets/ui/controller/xbox_y.svg"),
		&"ui_undo": preload("res://assets/ui/controller/xbox_y.svg"),
		&"ui_previous": preload("res://assets/ui/controller/xbox_lb.svg"),
		&"ui_next": preload("res://assets/ui/controller/xbox_rb.svg"),
		&"ui_confirm": preload("res://assets/ui/controller/xbox_rt.svg"),
		&"dash": preload("res://assets/ui/controller/xbox_rb.svg"),
		&"pause": preload("res://assets/ui/controller/xbox_menu.svg"),
	},
	"playstation": {
		&"ui_accept": preload("res://assets/ui/controller/ps_cross.svg"),
		&"ui_cancel": preload("res://assets/ui/controller/ps_circle.svg"),
		&"ui_reroll": preload("res://assets/ui/controller/ps_square.svg"),
		&"ui_details": preload("res://assets/ui/controller/ps_r3.svg"),
		&"ui_pin": preload("res://assets/ui/controller/ps_triangle.svg"),
		&"ui_undo": preload("res://assets/ui/controller/ps_triangle.svg"),
		&"ui_previous": preload("res://assets/ui/controller/ps_l1.svg"),
		&"ui_next": preload("res://assets/ui/controller/ps_r1.svg"),
		&"ui_confirm": preload("res://assets/ui/controller/ps_r2.svg"),
		&"dash": preload("res://assets/ui/controller/ps_r1.svg"),
		&"pause": preload("res://assets/ui/controller/ps_options.svg"),
	},
}

static func texture(action: StringName, family: String) -> Texture2D:
	return TEXTURES.get(family, TEXTURES.xbox).get(action)
