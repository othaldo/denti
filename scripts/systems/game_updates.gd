class_name GameUpdateService
extends Node

signal changed

enum State { IDLE, CHECKING, CURRENT, AVAILABLE, DOWNLOADING, VERIFYING, READY, INSTALLING, ERROR }

const API := "https://api.github.com/repos/othaldo/denti/releases"
const HELPER := "res://scripts/platform/windows_updater.ps1"
const CHECK_INTERVAL := 6 * 60 * 60

var state: State = State.IDLE
var channel := "stable"
var message := ""
var available: Dictionary = {}
var progress := 0.0
var current_version := str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
var settings_path := "user://updates.cfg"
var work_dir := ""
var checked_at := -CHECK_INTERVAL
var request_node: HTTPRequest
var generation := 0
var last_job := ""
var restored_update := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	channel = "beta" if "-" in current_version and not "-dev." in current_version else "stable"
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var saved := str(config.get_value("updates", "channel", channel))
		if saved in ["stable", "beta"]: channel = saved
		last_job = str(config.get_value("updates", "last_job", ""))
	if can_update() and _is_cached_job(last_job) and FileAccess.file_exists(last_job.get_base_dir().path_join("status.json")):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(last_job.get_base_dir().path_join("status.json")))
		if previous is Dictionary and str(previous.get("state")) == "failed":
			restored_update = true
			checked_at = int(Time.get_unix_time_from_system())
			_fail("Das Update wurde nicht installiert. Deine bisherige Version ist wieder aktiv.")
	set_process(false)


func can_update() -> bool:
	return OS.has_feature("windows") and not OS.has_feature("editor") and not OS.has_feature("web") and OS.get_executable_path().get_file() == "Denti.exe"


func busy() -> bool:
	return state in [State.CHECKING, State.DOWNLOADING, State.VERIFYING, State.INSTALLING]


func set_channel(value: String) -> void:
	if value not in ["stable", "beta"] or busy() or value == channel: return
	cancel_download()
	channel = value
	_save_preferences()
	available = {}
	state = State.IDLE
	checked_at = -CHECK_INTERVAL
	check_for_updates(true)


func check_for_updates(force: bool = false) -> void:
	if not can_update() or busy() or state == State.READY: return
	var now := int(Time.get_unix_time_from_system())
	if not force and now - checked_at < CHECK_INTERVAL: return
	_remove_archive()
	checked_at = now
	if restored_update and force:
		last_job = ""
		_save_preferences()
	restored_update = false
	available = {}
	_set_state(State.CHECKING)
	var url := API + ("/latest" if channel == "stable" else "?per_page=30")
	var reply := await _fetch_json(url)
	if reply.get("code") == 404:
		_set_state(State.CURRENT)
		return
	if not reply.get("ok", false):
		_fail("Updates konnten nicht geprüft werden. Später erneut versuchen.")
		return
	var releases: Array = []
	if channel == "stable" and reply.data is Dictionary: releases = [reply.data]
	elif channel == "beta" and reply.data is Array: releases = reply.data
	else:
		_fail("Die Antwort des Updateservers ist ungültig.")
		return
	var release := UpdateRelease.candidate(releases, channel)
	if release.is_empty() or ReleaseVersion.compare(str(release.tag_name).substr(1), current_version) <= 0:
		_set_state(State.CURRENT)
		return
	var manifest_url := UpdateRelease.manifest_url(release)
	if manifest_url.is_empty():
		_fail("Diese Veröffentlichung enthält kein Updatepaket.")
		return
	reply = await _fetch_json(manifest_url)
	if not reply.get("ok", false) or not reply.get("data") is Dictionary:
		_fail("Die Updatedaten konnten nicht geladen werden.")
		return
	var error := UpdateRelease.validate(reply.data, release, RunStore.VERSION)
	if not error.is_empty():
		_fail(error)
		return
	available = reply.data
	_set_state(State.AVAILABLE)


func _fetch_json(url: String) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 20
	request.body_size_limit = 1024 * 1024
	request.use_threads = true
	add_child(request)
	var error := request.request(url, ["User-Agent: Denti-Updater", "Accept: application/json"])
	if error != OK:
		request.queue_free()
		return {"ok": false}
	var response: Array = await request.request_completed
	request.queue_free()
	return {"ok": response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200, "code": response[1], "data": JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())}


func download_update() -> void:
	if not can_update() or state != State.AVAILABLE: return
	var nonce := Crypto.new().generate_random_bytes(8).hex_encode()
	work_dir = ProjectSettings.globalize_path("user://updates/" + nonce)
	if DirAccess.make_dir_recursive_absolute(work_dir) != OK:
		_fail("Der Downloadordner konnte nicht angelegt werden.")
		return
	var package: Dictionary = available.assets["windows-x86_64"]
	request_node = HTTPRequest.new()
	request_node.download_file = work_dir.path_join("package.zip")
	request_node.body_size_limit = int(package.size)
	request_node.accept_gzip = false
	request_node.use_threads = true
	request_node.timeout = 20 * 60
	add_child(request_node)
	progress = 0
	generation += 1
	var token := generation
	_set_state(State.DOWNLOADING)
	set_process(true)
	var error := request_node.request(package.url, ["User-Agent: Denti-Updater"])
	if error != OK:
		cancel_download()
		_fail("Der Download konnte nicht gestartet werden.")
		return
	var response: Array = await request_node.request_completed
	if token != generation: return
	request_node.queue_free()
	request_node = null
	set_process(false)
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		_remove_archive()
		_fail("Download unterbrochen. Bitte erneut versuchen.")
		return
	_set_state(State.VERIFYING)
	var verified := await _verify_archive(token)
	if token != generation: return
	if not verified:
		_remove_archive()
		_fail("Das Updatepaket ist beschädigt. Bitte erneut herunterladen.")
		return
	_set_state(State.READY)


func _process(_delta: float) -> void:
	if request_node == null: return
	var bytes: int = request_node.get_downloaded_bytes()
	var size: int = int(available.assets["windows-x86_64"].size)
	var amount := floorf(100.0 * bytes / maxi(1, size))
	if amount != progress:
		progress = amount
		changed.emit()


func _verify_archive(token: int) -> bool:
	var file := FileAccess.open(work_dir.path_join("package.zip"), FileAccess.READ)
	var package: Dictionary = available.assets["windows-x86_64"]
	if file == null or file.get_length() != int(package.size): return false
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	while file.get_position() < file.get_length():
		var chunk := file.get_buffer(4 * 1024 * 1024)
		if chunk.is_empty():
			file.close()
			return false
		hash.update(chunk)
		await get_tree().process_frame
		if token != generation:
			file.close()
			_remove_archive()
			return false
	file.close()
	if hash.finish().hex_encode() != package.sha256: return false
	var zip := ZIPReader.new()
	if zip.open(work_dir.path_join("package.zip")) != OK: return false
	var files := zip.get_files()
	if files.size() != UpdateRelease.PACKAGE_FILES.size():
		zip.close()
		return false
	for name in UpdateRelease.PACKAGE_FILES:
		if not files.has(name):
			zip.close()
			return false
	var info: Variant = JSON.parse_string(zip.read_file("build-info.json").get_string_from_utf8())
	zip.close()
	if not info is Dictionary: return false
	if not UpdateRelease._integer(info.get("save_schema")) or int(info.save_schema) != int(available.save_schema): return false
	for key in ["version", "commit", "channel", "repository"]:
		if not info.get(key) is String or info.get(key) != available.get(key): return false
	return true


func cancel_download() -> void:
	if state == State.INSTALLING: return
	generation += 1
	if request_node != null:
		request_node.cancel_request()
		request_node.request_completed.emit(HTTPRequest.RESULT_REQUEST_FAILED, 0, PackedStringArray(), PackedByteArray())
		request_node.queue_free()
		request_node = null
	set_process(false)
	_remove_archive()
	if not available.is_empty(): _set_state(State.AVAILABLE)


func _remove_archive() -> void:
	if not work_dir.is_empty():
		DirAccess.remove_absolute(work_dir.path_join("package.zip"))


func install_update() -> void:
	if not can_update() or state != State.READY: return
	# Only the main-menu view calls this. No combat or save state is touched.
	var executable := OS.get_executable_path()
	var package: Dictionary = available.assets["windows-x86_64"]
	var job := {"schema_version": 1, "install_dir": executable.get_base_dir(), "parent_pid": OS.get_process_id(),
		"archive": work_dir.path_join("package.zip"), "size": package.size, "sha256": package.sha256,
		"version": available.version, "commit": available.commit, "channel": available.channel,
		"save_schema": available.save_schema, "current_version": current_version,
		"current_build": str(ProjectSettings.get_setting("denti/build", "dev"))}
	var helper_path := work_dir.path_join("installer.ps1")
	var job_path := work_dir.path_join("job.json")
	var script := FileAccess.get_file_as_string(HELPER)
	if script.is_empty() or not _write(helper_path, script) or not _write(job_path, JSON.stringify(job)):
		_fail("Der Updater konnte nicht vorbereitet werden.")
		return
	last_job = job_path
	_save_preferences()
	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	var pid := OS.create_process(powershell, installer_arguments(helper_path, job_path))
	if pid <= 0:
		_fail("Der Updater konnte nicht gestartet werden.")
		return
	_set_state(State.INSTALLING)
	for attempt in 300:
		await get_tree().create_timer(0.2).timeout
		var status: Variant = JSON.parse_string(FileAccess.get_file_as_string(work_dir.path_join("status.json"))) if FileAccess.file_exists(work_dir.path_join("status.json")) else null
		if status is Dictionary and status.get("state") == "ready":
			get_tree().quit()
			return
		if status is Dictionary and status.get("state") == "failed":
			_fail("Installation nicht möglich. Die bisherige Version bleibt erhalten.")
			return
		if not OS.is_process_running(pid): break
	if OS.is_process_running(pid): OS.kill(pid)
	_fail("Der Updater antwortet nicht. Die bisherige Version bleibt erhalten.")


static func installer_arguments(helper_path: String, job_path: String) -> PackedStringArray:
	# Pass complete paths as individual arguments; Godot handles Windows quoting.
	return ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", helper_path, "-JobPath", job_path]


func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("updates", "channel", channel)
	config.set_value("updates", "last_job", last_job)
	config.save(settings_path)


func _is_cached_job(path: String) -> bool:
	var cache := ProjectSettings.globalize_path("user://updates/").replace("\\", "/")
	return not path.is_empty() and path.replace("\\", "/").simplify_path().begins_with(cache) and path.get_file() == "job.json"


func confirm_startup() -> void:
	if not can_update(): return
	var arguments := OS.get_cmdline_user_args()
	var index := arguments.find("--denti-update-job")
	if index < 0 or index + 1 >= arguments.size(): return
	var job_path := arguments[index + 1]
	# A helper may only ask us to acknowledge a job in this game's update cache.
	if not _is_cached_job(job_path): return
	var job: Variant = JSON.parse_string(FileAccess.get_file_as_string(job_path))
	if not job is Dictionary or str(job.get("version")) != current_version: return
	if str(job.get("commit", "")).left(7) != str(ProjectSettings.get_setting("denti/build", "dev")): return
	_write(job_path.get_base_dir().path_join("status.json"), JSON.stringify({"state": "started", "version": current_version}))


func _write(path: String, value: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(value)
	file.close()
	return true


func _set_state(value: State) -> void:
	state = value
	message = ""
	changed.emit()


func _fail(value: String) -> void:
	state = State.ERROR
	message = value
	changed.emit()
