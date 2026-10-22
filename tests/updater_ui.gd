extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

class FakeUpdates extends GameUpdateService:
	var downloads := 0
	var installs := 0
	func can_update() -> bool: return true
	func check_for_updates(_force := false) -> void: pass
	func download_update() -> void: downloads += 1
	func install_update() -> void: installs += 1

func _initialize() -> void: call_deferred("_run")

func _check(condition: bool, detail: String) -> void:
	if not condition:
		failures.append(detail)
		push_error(detail)

func _run() -> void:
	var original := root.get_node("GameUpdates")
	root.remove_child(original)
	var service := FakeUpdates.new()
	service.name = "GameUpdates"
	service.settings_path = "user://updates-ui.cfg"
	root.add_child(service)
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for frame in 6: await process_frame
	_check(menu.actions.has(&"updates"), "Windows update entry is missing")
	for extent in [Vector2i(1280, 720), Vector2i(800, 600), Vector2i(360, 640), Vector2i(568, 320)]:
		root.size = extent
		root.content_scale_size = root.get_node("GameSession").mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
		menu._show_home()
		menu._show_updates()
		service.available = {"version": "0.6.0-beta.12", "assets": {"windows-x86_64": {"size": 170000000}}}
		for state in [service.State.AVAILABLE, service.State.DOWNLOADING, service.State.VERIFYING, service.State.READY, service.State.ERROR]:
			service.state = state
			service.progress = 62
			service.message = "Download unterbrochen. Bitte erneut versuchen."
			service.changed.emit()
			for frame in 5: await process_frame
			var view := menu.updates_view
			_check(not view.action.disabled, "download cannot be cancelled or idle action is disabled")
			_check(view.action.size.y >= 48, "update action is too small")
			_check(not menu.stage.body_scroll.get_h_scroll_bar().visible, "updater has horizontal overflow at " + str(extent))
			_check(view.version.size.x <= menu.stage.body_scroll.size.x + 1, "release version overflows")
		service.state = service.State.INSTALLING
		service.changed.emit()
		menu._return_home()
		_check(menu.page == &"updates" and menu.stage.back_button.disabled, "install handoff can be navigated away from")
		service.state = service.State.READY
		service.changed.emit()
		menu.updates_view.action.pressed.emit()
		_check(service.installs > 0, "ready action did not request install")
		menu._return_home()
		_check(menu.page == &"home", "updater cannot return home")
	var overlay := GameMenu.new()
	overlay.overlay = true
	root.add_child(overlay)
	overlay._show_updates()
	_check(overlay.page != &"updates", "pause overlay offers install during a run")
	overlay.free()
	menu.free()
	root.remove_child(service)
	service.free()
	root.add_child(original)
	finish(0 if failures.is_empty() else 1)
