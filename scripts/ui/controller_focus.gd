class_name ControllerFocus
extends RefCounted

static func register(scope: Control, preferred: Callable = Callable(), priority: int = 0) -> void:
	_follow_focus(scope)
	scope.get_node("/root/GameInput").navigation.register_scope(scope, preferred, priority)

static func _follow_focus(node: Node) -> void:
	if node is ScrollContainer: node.follow_focus = true
	for child in node.get_children(): _follow_focus(child)

static func tag(control: Control, id: String) -> void:
	control.set_meta("controller_focus_key", id)

static func active(scope: Control) -> bool:
	var navigation: ControllerNavigation = scope.get_node("/root/GameInput").navigation
	if navigation.popup_open(): return false
	var entry: Dictionary = navigation.top_scope()
	return not entry.is_empty() and contains(scope, entry.scope.get_ref())

static func visible(control: Control) -> bool:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.is_queued_for_deletion(): return false
	var parent: Node = control
	while parent != null:
		if parent is CanvasLayer and not parent.visible: return false
		if parent is CanvasItem and not parent.visible: return false
		parent = parent.get_parent()
	return true

static func available(control: Control) -> bool:
	return visible(control) and control.focus_mode == Control.FOCUS_ALL and not control is ScrollBar and not (control is BaseButton and control.disabled)

static func controls(scope: Control) -> Array[Control]:
	var result: Array[Control] = []
	if scope.has_meta("controller_focus_targets"):
		var provider: Callable = scope.get_meta("controller_focus_targets")
		for control: Control in provider.call():
			if contains(scope, control) and available(control): result.append(control)
		return result
	_collect(scope, result)
	return result

static func accepts(scope: Control, control: Control) -> bool:
	return contains(scope, control) and available(control) and (not scope.has_meta("controller_focus_targets") or control in controls(scope))

static func _collect(node: Node, result: Array[Control]) -> void:
	if node is Control:
		if not visible(node): return
		if available(node): result.append(node)
	for child in node.get_children():
		if not child is Window: _collect(child, result)

static func contains(scope: Control, control: Control) -> bool:
	return is_instance_valid(control) and (scope == control or scope.is_ancestor_of(control))

static func key(scope: Control, control: Control) -> String:
	return str(control.get_meta("controller_focus_key", scope.get_path_to(control)))

static func reveal(control: Control) -> void:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			# A shop card can be taller than the compact viewport. Preserve its
			# identity/art at the top instead of exposing only its lower actions.
			var scale_y: float = parent.get_global_transform().get_scale().y
			if control.get_global_rect().size.y > parent.get_global_rect().size.y and parent.get_child_count() > 0:
				var content: Control = parent.get_child(0) as Control
				if content != null:
					parent.scroll_vertical = roundi((control.get_global_rect().position.y - content.get_global_rect().position.y) / maxf(scale_y, 0.001))
			else:
				parent.ensure_control_visible(control)
		parent = parent.get_parent()

static func layout_rect(control: Control) -> Rect2:
	# Remove scroll offsets so manual scrolling does not look like a reflow.
	var rect := control.get_global_rect()
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			rect.position += Vector2(parent.scroll_horizontal, parent.scroll_vertical) * parent.get_global_transform().get_scale()
		parent = parent.get_parent()
	return rect

static func neighbor(scope: Control, source: Control, side: Side) -> Control:
	if scope.has_meta("controller_focus_neighbor"):
		var provider: Callable = scope.get_meta("controller_focus_neighbor")
		var target: Control = provider.call(source, side)
		return target if accepts(scope, target) else null
	var native := source.find_valid_focus_neighbor(side)
	if contains(scope, native) and native != source and available(native): return native
	return spatial_neighbor(source, side, controls(scope))

static func spatial_neighbor(source: Control, side: Side, candidates: Array[Control]) -> Control:
	var direction: Vector2 = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN][side]
	var centre := source.get_global_rect().get_center()
	var best: Control
	var best_score := INF
	for candidate in candidates:
		if candidate == source: continue
		var offset := candidate.get_global_rect().get_center() - centre
		var forward := offset.dot(direction)
		if forward <= 1.0: continue
		var transverse := absf(offset.cross(direction))
		var score := forward + transverse * 3.0
		if score < best_score:
			best = candidate
			best_score = score
	return best
