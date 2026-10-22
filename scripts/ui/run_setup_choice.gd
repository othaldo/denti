class_name RunSetupChoice
extends Button

var selected := false
var keyboard_focus := false
var mark: TextureRect
var artwork: TextureRect
var rarity_tier := 0
var rarity_color := Color.TRANSPARENT

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mark = TextureRect.new()
	mark.texture = preload("res://assets/ui/setup_check.svg")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mark.offset_left = -25
	mark.offset_right = -7
	mark.offset_top = 7
	mark.offset_bottom = 25
	resized.connect(_layout_artwork)
	refresh()

func show_artwork(texture: Texture2D) -> void:
	if artwork == null:
		artwork = TextureRect.new()
		artwork.name = "Artwork"
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(artwork)
		move_child(artwork, 0)
	artwork.texture = texture
	_layout_artwork()

func _layout_artwork() -> void:
	if artwork == null: return
	# A symmetric image area, independent of Button's icon alignment, border
	# thickness and selection marker. Tall and wide art share the same inset.
	var inset := ceilf(minf(size.x, size.y) * 0.13)
	artwork.position = Vector2.ONE * inset
	artwork.size = (size - Vector2.ONE * inset * 2).max(Vector2.ZERO)
	var marker_size := clampf(floorf(minf(size.x, size.y) * 0.16), 10, 18)
	mark.offset_left = -6 - marker_size
	mark.offset_right = -6
	mark.offset_top = 0
	mark.offset_bottom = marker_size

func refresh() -> void:
	if rarity_tier > 0:
		DentiUIStyle.style_card(self, rarity_tier, rarity_color)
		DentiUIStyle.mark_card(self, DentiUIStyle.INK if selected else Color.TRANSPARENT)
		RunSetupStyle.focus(self, keyboard_focus)
	else:
		RunSetupStyle.choice(self, selected, keyboard_focus)
	if mark != null: mark.visible = selected
