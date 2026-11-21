class_name RunStore
extends RefCounted

const VERSION := 1

# At most one background write. Every other access completes it first, so a
# later synchronous save, clear or load always sees the newest file state.
static var _pending_task := -1
static var _pending_path := ""
static var _pending_error := OK


static func load_run(path: String) -> Dictionary:
	finish_pending()
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary or value.get("version", -1) != VERSION:
		return {}
	return RunSaveData.normalize(value)


static func save_run(path: String, data: Dictionary) -> Error:
	finish_pending()
	return _write(path, data)


## Serializes and writes on a worker thread. The caller's dictionary is deep
## copied first, so live game state may change while the write runs. Builds
## without thread support write synchronously.
static func save_run_background(path: String, data: Dictionary) -> Error:
	if not background_supported():
		return save_run(path, data)
	var previous := finish_pending()
	var snapshot := data.duplicate(true)
	_pending_path = path
	_pending_error = OK
	_pending_task = WorkerThreadPool.add_task(func() -> void: _pending_error = _write(path, snapshot), false, "Run autosave")
	return previous


static func background_supported() -> bool:
	return OS.get_name() != "Web" or OS.has_feature("threads")


static func has_pending() -> bool:
	return _pending_task >= 0


## Waits for a running background write. Returns its error.
static func finish_pending() -> Error:
	if _pending_task < 0:
		return OK
	WorkerThreadPool.wait_for_task_completion(_pending_task)
	_pending_task = -1
	var error := _pending_error
	if error != OK:
		push_warning("Spielstand konnte nicht gespeichert werden: %s" % _pending_path)
	return error


static func clear(path: String) -> void:
	finish_pending()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _write(path: String, data: Dictionary) -> Error:
	var temporary := "%s.%d.tmp" % [path, OS.get_process_id()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	return error
