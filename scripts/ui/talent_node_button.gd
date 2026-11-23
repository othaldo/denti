class_name TalentNodeButton
extends Button

## One painted grid cell of the talent tree. Each node kind has its own shape:
## attribute = circle, free root = circle with "+" (bound: attribute icon plus a
## small root mark), talent = rounded tile, skill = large diamond,
## modifier = small diamond, keystone = octagon. Native Button keeps mouse,
## touch and controller focus behaviour.

enum State { LOCKED, OPEN, AVAILABLE, INVESTED, MAXED }

var node: TalentNodeData
var texture: Texture2D
var rank := 0
var state := State.LOCKED
var selected := false
## Free root already bound to an attribute; `texture` then shows that attribute.
var bound := false

func _init() -> void:
	flat = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	queue_redraw()

func set_binding(icon_texture: Texture2D) -> void:
	bound = icon_texture != null
	texture = icon_texture
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
	var quiet := locked and not (selected or has_focus() or is_hovered())
	var fill := DentiUIStyle.RAISED if not quiet else DentiUIStyle.BACKGROUND
	if is_hovered() and not locked: fill = fill.lightened(0.08)
	var edge := _edge()
	var width := 3.0 if state in [State.INVESTED, State.MAXED, State.AVAILABLE] else 2.0
	if selected:
		_shape(centre, extent * 0.5 + 5.0, Color.TRANSPARENT, DentiUIStyle.GOLD, 2.5)
	_shape(centre, extent * 0.5, fill, edge.darkened(0.24) if quiet else edge, width)
	var ink := DentiUIStyle.LINE.darkened(0.24) if quiet else (DentiUIStyle.MUTED if locked else DentiUIStyle.GOLD)
	if texture != null:
		var icon_extent := extent * _icon_share()
		var tint := Color(0.66, 0.61, 0.70, 0.58) if quiet else Color.WHITE
		draw_texture_rect(texture, Rect2(centre - Vector2.ONE * icon_extent * 0.5, Vector2.ONE * icon_extent), false, tint)
		if bound: _root_mark(centre, extent, ink)
	elif node.free_attribute:
		# Free root: a plus socket, the first point binds the attribute.
		var arm := extent * 0.2
		draw_line(centre - Vector2(arm, 0), centre + Vector2(arm, 0), ink, 3.0, true)
		draw_line(centre - Vector2(0, arm), centre + Vector2(0, arm), ink, 3.0, true)
	elif node.has_placeholder_icon() or not node.is_attribute():
		# No painted icon yet (unassigned or atlas file still missing).
		_placeholder(centre, extent, locked)
	_badge(extent)

func _icon_share() -> float:
	if node.is_attribute(): return 0.62
	if node.is_skill() or node.is_modifier(): return 0.56
	if node.is_keystone(): return 0.64
	return 0.74

## Three small roots under a bound free node.
func _root_mark(centre: Vector2, extent: float, ink: Color) -> void:
	var top := centre + Vector2(0, extent * 0.5 - 2.0)
	var length := extent * 0.22
	for angle in [-0.55, 0.0, 0.55]:
		draw_line(top, top + Vector2.DOWN.rotated(angle) * length, ink, 3.5, true)
	draw_circle(top, 4.5, ink)

## No painted icon yet: dashed inner frame and the first letter of the name.
func _placeholder(centre: Vector2, extent: float, locked: bool) -> void:
	var half := extent * 0.24
	var color := DentiUIStyle.LINE if locked else DentiUIStyle.MUTED
	var corners := [centre + Vector2(-half, -half), centre + Vector2(half, -half), centre + Vector2(half, half), centre + Vector2(-half, half)]
	for index in 4:
		draw_dashed_line(corners[index], corners[(index + 1) % 4], color, 1.5, 4.0)
	var font := DentiUIStyle.FONT
	var font_size := int(clampf(extent * 0.3, 12.0, 30.0))
	var letter := node.display_name.substr(0, 1).to_upper()
	var width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := centre.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(font, Vector2(centre.x - width * 0.5, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _shape(centre: Vector2, radius: float, fill: Color, edge: Color, width: float) -> void:
	if node.is_attribute():
		if fill.a > 0.0: draw_circle(centre, radius, fill)
		draw_arc(centre, radius - width * 0.5, 0.0, TAU, 40, edge, width, true)
		return
	if node.is_skill() or node.is_modifier():
		_polygon(_ring(centre, radius, 4, 0.0), fill, edge, width)
		if node.is_skill():
			# Skills get an inner second outline: the goal of the branch.
			_polygon(_ring(centre, radius * 0.8, 4, 0.0), Color(0, 0, 0, 0), Color(edge, 0.55), 1.5)
		return
	if node.is_keystone():
		_polygon(_ring(centre, radius, 8, PI / 8.0), fill, edge.darkened(0.1), width + 1.0)
		return
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.draw_center = fill.a > 0.0
	box.border_color = edge
	box.set_border_width_all(int(round(width)))
	box.set_corner_radius_all(int(radius * 0.32))
	box.anti_aliasing = true
	draw_style_box(box, Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0))

func _ring(centre: Vector2, radius: float, sides: int, offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		var angle := offset + TAU * index / sides - PI * 0.5
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _polygon(points: PackedVector2Array, fill: Color, edge: Color, width: float) -> void:
	if fill.a > 0.0: draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, edge, width, true)

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
