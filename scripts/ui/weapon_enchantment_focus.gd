class_name WeaponEnchantmentFocus
extends RefCounted
## Controller-only focus policy; desktop controls retain their native graph.

var panel: CanvasLayer

func _init(view: CanvasLayer) -> void:
	panel = view

func targets() -> Array[Control]:
	var result: Array[Control] = []
	if panel.picking_slot >= 0:
		for button: Button in panel.effect_buttons:
			if ControllerFocus.available(button): result.append(button)
	else:
		if ControllerFocus.available(panel.ascension_button): result.append(panel.ascension_button)
		for row: Button in panel.focus_rows:
			if ControllerFocus.available(row): result.append(row)
	return result

func neighbor(source: Control, side: Side) -> Control:
	var choices := targets()
	if choices.is_empty(): return null
	if panel.picking_slot >= 0:
		var target := ControllerFocus.spatial_neighbor(source, side, choices)
		return target if target != null else source
	if side in [SIDE_LEFT, SIDE_RIGHT]: return source
	var index := choices.find(source)
	return choices[clampi(index + (-1 if side == SIDE_TOP else 1), 0, choices.size() - 1)]

func resolve(goal: String) -> Control:
	if goal.begins_with("upgrade:") or goal.begins_with("slot:"): goal = "row:" + goal.get_slice(":", 1)
	for control in targets():
		if str(control.get_meta("controller_focus_key", "")) == goal: return control
	if panel.picking_slot < 0 and not panel.focus_rows.is_empty(): return panel.focus_rows[0]
	var choices := targets()
	return choices[0] if not choices.is_empty() else null
