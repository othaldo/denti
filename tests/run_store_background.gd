extends "res://tests/support/test_runtime.gd"
## Background autosave: isolation from live state and ordering against every
## synchronous store access (save, load, clear).

const PATH := "user://test_run_store_background.json"
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	RunStore.clear(PATH)
	_check(RunStore.background_supported(), "Desktop builds should write autosaves in the background")

	# Mutating the caller's data after hand-off must not reach the file.
	var live := {"version": RunStore.VERSION, "coins": 7, "loot": [{"amount": 1}]}
	RunStore.save_run_background(PATH, live)
	live.coins = 99
	live.loot[0].amount = 50
	var loaded := _raw(PATH)
	_check(not RunStore.has_pending(), "Reading must complete the pending write")
	_check(int(loaded.get("coins", -1)) == 7, "Background save must write the hand-off snapshot")
	_check(int(loaded.get("loot", [{}])[0].get("amount", -1)) == 1, "Nested values must be deep copied")

	# A newer synchronous save always wins over an older background write.
	RunStore.save_run_background(PATH, {"version": RunStore.VERSION, "coins": 1})
	RunStore.save_run(PATH, {"version": RunStore.VERSION, "coins": 2})
	_check(int(_raw(PATH).get("coins", -1)) == 2, "Synchronous save must follow the pending background write")

	# Consecutive background saves keep their order.
	for value in [3, 4, 5]:
		RunStore.save_run_background(PATH, {"version": RunStore.VERSION, "coins": value})
	_check(int(_raw(PATH).get("coins", -1)) == 5, "Last background save must win")

	# Clearing waits so no late write recreates a deleted run.
	RunStore.save_run_background(PATH, {"version": RunStore.VERSION, "coins": 6})
	RunStore.clear(PATH)
	OS.delay_msec(50)
	_check(not FileAccess.file_exists(PATH), "Clear must not be undone by a pending write")
	_check(not FileAccess.file_exists("%s.%d.tmp" % [PATH, OS.get_process_id()]), "No temporary file may remain")

	# The session autosave path goes through the same store.
	var session: Node = root.get_node("GameSession")
	var previous_path: String = session.save_path
	session.save_path = PATH
	session.save_run({"coins": 8}, true)
	_check(int(_raw(PATH).get("coins", -1)) == 8, "Session background save must persist")
	_check(int(_raw(PATH).get("version", -1)) == RunStore.VERSION, "Session must stamp the save version")
	session.clear_run()
	session.save_path = previous_path
	finish(1 if failures else 0)


func _raw(path: String) -> Dictionary:
	# load_run() validates full run data; the raw file proves write ordering.
	RunStore.finish_pending()
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
