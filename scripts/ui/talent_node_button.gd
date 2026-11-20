class_name TalentNodeButton
extends Button

## One painted grid cell of the talent tree. Talents are rounded tiles,
## attribute path nodes are smaller round sockets. Native Button keeps mouse,
## touch and controller focus behaviour.

enum State { LOCKED, OPEN, AVAILABLE, INVESTED, MAXED }

var node: TalentNodeData
var texture: Texture2D
var rank := 0
var state := State.LOCKED
var selected := false

func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	for style in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(style, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func configure(data: TalentNodeData, icon_texture: Texture2D) -> void:
	node = data
	texture = icon_texture
	tooltip_text = data.display_name
	queue_redraw()

func set_state(new_rank: int, new_state: State, is_selected: bool) -> void:
	rank = new_rank
	state = new_state
	selected = is_selected
	queue_redraw()

func _edge() -> Color:
	match state:
		State.MAXED: return DentiUIStyle.GOLD
		State.INVESTED: return DentiUIStyle.GOLD.lerp(DentiUIStyle.INK, 0.25)
		State.AVAILABLE: return DentiUIStyle.MINT
		State.OPEN: return DentiUIStyle.MUTED.darkened(0.25)
	return DentiUIStyle.LINE

func _draw() -> void:
	if node == null: return
	var extent := minf(size.x, size.y)
	var centre := size * 0.5
	var locked := state == State.LOCKED
	var fill := DentiUIStyle.RAISED if not locked else DentiUIStyle.PANEL
	if is_hovered() and not locked: fill = fill.lightened(0.08)
	var edge := _edge()
	var width := 3.0 if state in [State.INVESTED, State.MAXED, State.AVAILABLE] else 2.0
	if selected:
		_shape(centre, extent * 0.5 + 5.0, Color(DentiUIStyle.INK, 0.0), DentiUIStyle.INK, 2.5)
	_shape(centre, extent * 0.5, fill, edge, width)
	if texture != null:
		var icon_extent := extent * (0.62 if node.is_attribute() else 0.74)
		var tint := Color(0.42, 0.40, 0.46, 0.75) if locked else Color.WHITE
		draw_texture_rect(texture, Rect2(centre - Vector2.ONE * icon_extent * 0.5, Vector2.ONE * icon_extent), false, tint)
	elif node.free_attribute:
		# Free root: a plus socket, the attribute is chosen when spending.
		var arm := extent * 0.2
		var ink := DentiUIStyle.LINE if locked else DentiUIStyle.GOLD
		draw_line(centre - Vector2(arm, 0), centre + Vector2(arm, 0), ink, 3.0, true)
		draw_line(centre - Vector2(0, arm), centre + Vector2(0, arm), ink, 3.0, true)
	_badge(extent)

func _shape(centre: Vector2, radius: float, fill: Color, edge: Color, width: float) -> void:
	if node.is_attribute():
		if fill.a > 0.0: draw_circle(centre, radius, fill)
		draw_arc(centre, radius - width * 0.5, 0.0, TAU, 40, edge, width, true)
		return
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.draw_center = fill.a > 0.0
	box.border_color = edge
	box.set_border_width_all(int(round(width)))
	box.set_corner_radius_all(int(radius * 0.32))
	box.anti_aliasing = true
	draw_style_box(box, Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))

func _badge(extent: float) -> void:
	if state == State.LOCKED and rank == 0: return
	var font := DentiUIStyle.FONT
	var font_size := int(clampf(extent * 0.22, 11.0, 18.0))
	var text := ("%d/%d" % [rank, node.max_ranks]) if not node.is_attribute() else str(rank)
	if node.is_attribute() and rank == 0: return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pad := Vector2(5, 1)
	var box_size := text_size + pad * 2.0
	var corner := Vector2(size.x - box_size.x * 0.75, size.y - box_size.y * 0.8)
	var box := StyleBoxFlat.new()
	box.bg_color = DentiUIStyle.BACKGROUND
	box.border_color = _edge()
	box.set_border_width_all(1)
	box.set_corner_radius_all(int(box_size.y * 0.5))
	draw_style_box(box, Rect2(corner, box_size))
	var ink := DentiUIStyle.GOLD if state == State.MAXED else DentiUIStyle.INK
	draw_string(font, corner + Vector2(pad.x, pad.y + font.get_ascent(font_size)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
