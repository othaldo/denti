class_name DentiSceneTransition
extends CanvasLayer

signal completed

const DURATION := 0.6
const REVEAL: Shader = preload("res://scripts/ui/scene_tooth_reveal.gdshader")
const TOOTH_DISTANCE: Texture2D = preload("res://assets/ui/tooth_transition_distance.res")
# Keep run resources ready before the menu becomes interactive. Loading this
# large dependency tree on a Start/Continue click stalls the main thread,
# especially in the single-threaded Web export.
const RUN_SCENE_PATH := "res://scenes/game/game.tscn"
const RUN_SCENE: PackedScene = preload("res://scenes/game/game.tscn")
var enabled := true
var active := false
var screen_key: StringName = &""
var blocks_input := false
var elapsed := 0.0
var snapshot: TextureRect
var _has_rendered := false
var _hold_frames := 0
var _scene_pending := false
var _scene_epoch := 0
var _captured_extent := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1000
	snapshot = TextureRect.new()
	snapshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snapshot.stretch_mode = TextureRect.STRETCH_SCALE
	snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var reveal := ShaderMaterial.new()
	reveal.shader = REVEAL
	reveal.set_shader_parameter("tooth_distance", TOOTH_DISTANCE)
	snapshot.material = reveal
	add_child(snapshot)
	visible = false
	RenderingServer.frame_post_draw.connect(_mark_rendered, CONNECT_ONE_SHOT)
	get_viewport().size_changed.connect(_on_viewport_resized)
	get_tree().scene_changed.connect(_on_scene_changed)


func _mark_rendered() -> void:
	_has_rendered = true


# Pure presentation: the calling coordinator changes screens immediately.
# No gameplay state, pause flag, reward, save or wave timer is owned here.
func present(key: StringName, block_input: bool = true) -> void:
	if screen_key == key:
		return
	screen_key = key
	if _scene_pending:
		blocks_input = active and block_input
		_sync_input()
		return
	if not _can_capture():
		cancel()
		return
	if active:
		# Rapid programmatic changes keep the current blend; never queue stale
		# screens or delay the authoritative game/reward coordinator.
		blocks_input = block_input
		_sync_input()
		return
	_capture(block_input)


func _can_capture() -> bool:
	return enabled and _has_rendered and DisplayServer.get_name() != "headless" and DentiUIMotion.enabled(self)


func _capture(block_input: bool) -> void:
	var frame := get_viewport().get_texture().get_image()
	if frame == null or frame.is_empty():
		return
	play_snapshot(ImageTexture.create_from_image(frame), block_input)


func play_snapshot(texture: Texture2D, block_input: bool = true) -> void:
	if texture == null or not enabled or not DentiUIMotion.enabled(self):
		cancel()
		return
	snapshot.texture = texture
	snapshot.modulate = Color.WHITE
	snapshot.material.set_shader_parameter("progress", 0.0)
	snapshot.material.set_shader_parameter("departure", 0.0)
	_captured_extent = get_viewport().get_visible_rect().size
	snapshot.material.set_shader_parameter("viewport_size", _captured_extent)
	active = true
	visible = true
	blocks_input = block_input
	elapsed = 0
	_hold_frames = 1
	_sync_input()


func _sync_input() -> void:
	snapshot.mouse_filter = Control.MOUSE_FILTER_STOP if active and blocks_input else Control.MOUSE_FILTER_IGNORE


func _on_viewport_resized() -> void:
	# Graphics setup can notify size_changed without changing dimensions when
	# a scene enters. Keep the effect in that case; cancel actual aspect changes.
	if active and not get_viewport().get_visible_rect().size.is_equal_approx(_captured_extent):
		cancel()


func _input(_event: InputEvent) -> void:
	if active and blocks_input:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active:
		return
	if not enabled or not DentiUIMotion.enabled(self):
		cancel()
		return
	if _scene_pending:
		return
	if _hold_frames > 0:
		_hold_frames -= 1
		return
	advance(delta)


func advance(delta: float) -> void:
	if not active:
		return
	elapsed = minf(DURATION, elapsed + maxf(0, delta))
	snapshot.material.set_shader_parameter("progress", elapsed / DURATION)
	if elapsed >= DURATION:
		cancel()


func cancel() -> void:
	var was_active := active
	active = false
	visible = false
	blocks_input = false
	elapsed = 0
	_hold_frames = 0
	if snapshot != null:
		snapshot.texture = null
		snapshot.modulate = Color.WHITE
		_sync_input()
	if was_active:
		completed.emit()


func change_scene(path: String) -> Error:
	if _scene_pending:
		return ERR_BUSY
	if not ResourceLoader.exists(path, "PackedScene"):
		return ERR_FILE_NOT_FOUND
	if _can_capture() and not active:
		_capture(true)
	blocks_input = active
	_sync_input()
	_scene_pending = true
	_scene_epoch += 1
	var previous_key := screen_key
	screen_key = &""
	if active and DisplayServer.get_name() != "headless":
		# Acknowledge the click on a real rendered frame before scene _ready()
		# does its remaining work. This adds no timed loading/animation wait.
		snapshot.material.set_shader_parameter("departure", 1.0)
		_replace_after_feedback(path, _scene_epoch, previous_key)
		return OK
	return _replace_scene(path, previous_key)


func _replace_after_feedback(path: String, epoch: int, previous_key: StringName) -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	if epoch == _scene_epoch:
		var result := _replace_scene(path, previous_key)
		if result != OK:
			push_error("Scene replacement failed: %s (%s)" % [path, error_string(result)])


func _replace_scene(path: String, previous_key: StringName) -> Error:
	var result := get_tree().change_scene_to_packed(RUN_SCENE) if path == RUN_SCENE_PATH else get_tree().change_scene_to_file(path)
	if result != OK:
		_scene_pending = false
		screen_key = previous_key
		cancel()
	return result


func _on_scene_changed() -> void:
	if not _scene_pending:
		return
	if not active:
		_scene_pending = false
		return
	_release_scene.call_deferred(_scene_epoch)


func _release_scene(epoch: int) -> void:
	# Keep the outgoing image intact until the new scene's containers/layout
	# have settled; the autoload survives removal of the old scene.
	await get_tree().process_frame
	await get_tree().process_frame
	if epoch != _scene_epoch:
		return
	_scene_pending = false
	_hold_frames = 0
