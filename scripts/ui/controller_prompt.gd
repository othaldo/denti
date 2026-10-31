class_name ControllerPrompt
extends TextureRect

var target: Control
var action: StringName = &"ui_accept"
var focused_only := true
var input: Node

static func bind(control: Control, input_action: StringName = &"ui_accept", only_on_focus: bool = true) -> ControllerPrompt:
	var existing := control.get_node_or_null("ControllerPrompt") as ControllerPrompt
	if existing != null:
		# Explicit shortcuts take precedence over the generic focused-button cue.
		if input_action != &"ui_accept" or not only_on_focus:
			existing.action = input_action
			existing.focused_only = only_on_focus
			existing.refresh()
		return existing
	var prompt := ControllerPrompt.new()
	prompt.name = "ControllerPrompt"
	prompt.target = control
	prompt.action = input_action
	prompt.focused_only = only_on_focus
	control.add_child(prompt)
	return prompt

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_to_group("controller_prompts")
	input = get_node("/root/GameInput")
	input.changed.connect(refresh)
	target.focus_entered.connect(refresh)
	target.focus_exited.connect(refresh)
	target.resized.connect(_layout)
	refresh()

func refresh() -> void:
	if not is_instance_valid(input) or not is_instance_valid(target) or target.is_queued_for_deletion(): return
	var shown: bool = input.using_controller and (not focused_only or target.has_focus())
	texture = ControllerGlyphs.texture(action, input.family())
	# Menu bindings are read by the shared action bar. Cards and buttons keep
	# their own art and focus outline, without key badges attached to corners.
	visible = shown and target is DashButton
	_layout()

func _layout() -> void:
	if not is_instance_valid(target): return
	size = Vector2(28, 28)
	position = Vector2((target.size.x - size.x) * 0.5, target.size.y + 2)
