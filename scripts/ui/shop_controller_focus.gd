class_name ShopControllerFocus
extends RefCounted

enum Area { BUILD, OFFERS }
var view: CanvasLayer
var area := Area.OFFERS
var positions: Array[String] = ["", ""]
var was_active := false
var empty: ControllerPassiveTarget

func _init(panel: CanvasLayer) -> void:
	view = panel
	empty = ControllerPassiveTarget.new()
	MenuStyle.action(empty)
	empty.custom_minimum_size.y = 72
	ControllerFocus.tag(empty, "shop:empty")
	view.offer_column.add_child(empty)
	view.get_viewport().gui_focus_changed.connect(_remember)

func active() -> bool:
	return view.get_node("/root/GameInput").controller_active

func sync() -> void:
	var controller := active()
	if controller and not was_active:
		var focus: Control = view.get_viewport().gui_get_focus_owner()
		if view.expanded:
			area = Area.OFFERS if view.selected_kind == "offer" else Area.BUILD
		elif ControllerFocus.contains(view.build_column, focus): area = Area.BUILD
		elif ControllerFocus.contains(view.offer_scroll, focus): area = Area.OFFERS
	was_active = controller
	var root: Control = view.get_node("Root")
	if controller:
		root.set_meta("controller_focus_targets", targets)
		root.set_meta("controller_focus_neighbor", neighbor)
	else:
		for key in ["controller_focus_targets", "controller_focus_neighbor"]:
			if root.has_meta(key): root.remove_meta(key)
	var sold_out := true
	for card: OfferCard in view.offer_buttons:
		if not card.disabled: sold_out = false
	empty.visible = controller and sold_out
	empty.text = "Alle Angebote verkauft"

func targets() -> Array[Control]:
	var result: Array[Control] = []
	match area:
		Area.OFFERS:
			for card: OfferCard in view.offer_buttons:
				if ControllerFocus.available(card): result.append(card)
			if result.is_empty() and ControllerFocus.available(empty): result.append(empty)
		Area.BUILD:
			for holder: Control in view.inventory_row.get_children():
				if holder.get_child_count() > 0 and ControllerFocus.available(holder.get_child(0)): result.append(holder.get_child(0))
			for chip: Button in view.stat_chips:
				if ControllerFocus.available(chip): result.append(chip)
			if ControllerFocus.available(view.amalgam_chip): result.append(view.amalgam_chip)
			for item: Control in view.items_row.get_children():
				if ControllerFocus.available(item): result.append(item)
	return result

func preferred() -> Control:
	var choices := targets()
	if choices.is_empty(): return null
	for control in choices:
		if str(control.get_meta("controller_focus_key", "")) == positions[area]: return control
	if area == Area.OFFERS and positions[area].begins_with("offer:"):
		var previous := positions[area].get_slice(":", 1).to_int()
		for index in range(previous + 1, view.offer_buttons.size()):
			if ControllerFocus.available(view.offer_buttons[index]): return view.offer_buttons[index]
		for index in range(previous - 1, -1, -1):
			if ControllerFocus.available(view.offer_buttons[index]): return view.offer_buttons[index]
	return choices[0]

func _remember(control: Control) -> void:
	if not view.visible or view.expanded: return
	if not active():
		if ControllerFocus.contains(view.build_column, control): area = Area.BUILD
		elif ControllerFocus.contains(view.offer_scroll, control): area = Area.OFFERS
		else: return
	if control in targets(): positions[area] = str(control.get_meta("controller_focus_key", ""))

func change(direction: int) -> void:
	if view.expanded: return
	var next := clampi(area + direction, Area.BUILD, Area.OFFERS)
	if next == area: return
	area = next as Area
	sync()
	view._queue_layout()
	restore.call_deferred()

func restore() -> void:
	var control := preferred()
	if control != null:
		control.grab_focus()
		ControllerFocus.reveal(control)

func neighbor(source: Control, side: Side) -> Control:
	if area == Area.OFFERS and view.offers_grid.columns == 1 and side in [SIDE_LEFT, SIDE_RIGHT]: return source
	var target := ControllerFocus.spatial_neighbor(source, side, targets())
	return target if target != null else source

func details() -> void:
	var focus: Control = view.get_viewport().gui_get_focus_owner()
	if focus is OfferCard:
		view._select("offer", view.offer_buttons.find(focus))
	elif focus is Button and focus in view.stat_chips:
		focus.pressed.emit()
	elif focus == view.amalgam_chip:
		focus.pressed.emit()
	else:
		for index in view.inventory_row.get_child_count():
			if view.inventory_row.get_child(index).get_child(0) == focus:
				view._select("equipment", index, true)
		for index in view.items_row.get_child_count():
			if view.items_row.get_child(index) == focus: view._select("item", index)
