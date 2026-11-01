class_name EnchantmentExitDialog
extends Control

signal decided(choice: StringName)
var panel: PanelContainer
var buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.65)
	add_child(shade)
	panel = PanelContainer.new()
	DentiUIStyle.style_dialog(panel)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	panel.add_child(rows)
	var title := Label.new()
	title.text = "Änderungen übernehmen?"
	title.add_theme_font_size_override("font_size", 19)
	rows.add_child(title)
	for entry in [[&"continue", "Weiterbearbeiten"], [&"discard", "Verwerfen"], [&"finish", "Fertig"]]:
		var button := Button.new()
		MenuStyle.action(button, entry[0] == &"finish")
		button.text = entry[1]
		button.pressed.connect(func() -> void: decided.emit(entry[0]))
		rows.add_child(button)
		buttons.append(button)
	ControllerFocus.register(self, func() -> Control: return buttons[0], 500)
	set_meta("controller_back", "Zurück")
	get_viewport().size_changed.connect(_layout)
	get_node("/root/GameInput").changed.connect(_layout.call_deferred)
	hide()

func present() -> void:
	show()
	_layout()
	buttons[0].grab_focus()

func _layout() -> void:
	if panel == null or not visible: return
	var factor := MenuLayout.ui_scale(get_viewport())
	var safe := ControllerActionBar.content_rect(self, HUDLayout.safe_rect(size))
	panel.scale = Vector2.ONE * factor
	for button in buttons:
		button.custom_minimum_size.y = 40 if safe.size.y / factor < 300 else 48
		MenuStyle.focus(button, get_node("/root/GameInput").navigation_active)
	panel.size = Vector2(minf(420, safe.size.x / factor - 24), 0)
	panel.size.y = panel.get_combined_minimum_size().y
	panel.position = safe.position + (safe.size - panel.size * factor) * 0.5

func _input(event: InputEvent) -> void:
	if not visible or not ControllerFocus.active(self): return
	if event.is_action_pressed("ui_cancel"):
		decided.emit(&"continue")
		get_viewport().set_input_as_handled()
