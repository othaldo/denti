extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

class FakeUpdates extends GameUpdateService:
	var replies: Array[Dictionary] = []
	var calls := 0
	func can_update() -> bool: return true
	func _fetch_json(_url: String) -> Dictionary:
		calls += 1
		await get_tree().process_frame
		return replies.pop_front()

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, text: String) -> void:
	if not value:
		failures.append(text)
		push_error(text)

func _release(version: String, draft := false) -> Dictionary:
	var name := "Denti-%s-windows-x86_64.zip" % version
	var base := UpdateRelease.DOWNLOAD_ROOT + "v" + version + "/"
	return {"tag_name": "v" + version, "draft": draft, "prerelease": "-" in version, "published_at": "2026-10-22T00:00:00Z", "assets": [
		{"name": "release.json", "browser_download_url": base + "release.json"},
		{"name": name, "browser_download_url": base + name, "size": 300, "digest": "sha256:" + "b".repeat(64)}]}

func _manifest(version := "0.6.0") -> Dictionary:
	var name := "Denti-%s-windows-x86_64.zip" % version
	return {"schema_version": 1, "repository": "othaldo/denti", "version": version, "tag": "v" + version,
		"channel": "beta" if "-" in version else "stable", "commit": "a".repeat(40), "save_schema": RunStore.VERSION,
		"assets": {"windows-x86_64": {"name": name, "url": UpdateRelease.DOWNLOAD_ROOT + "v" + version + "/" + name, "size": 300, "sha256": "b".repeat(64)}}}

func _run() -> void:
	for pair in [["1.0.0-beta.10", "1.0.0-beta.2"], ["1.0.0", "1.0.0-beta.10"], ["1.0.0-beta.1", "1.0.0-1"], ["1.10.0", "1.9.9"], ["0.6.0", "0.5.0-dev.99"]]:
		_check(ReleaseVersion.compare(pair[0], pair[1]) > 0, "version order: %s" % str(pair))
		_check(ReleaseVersion.compare(pair[1], pair[0]) < 0, "reversed version order")
	_check(ReleaseVersion.compare("1.0.0", "1.0.0") == 0, "same release differs")
	for invalid in ["1.0", "01.0.0", "1.0.0-beta.01", "1.0.0/../bad", "", "1.0.0-"]:
		_check(ReleaseVersion.parse(invalid).is_empty(), "invalid version accepted: " + invalid)
	var choices := [_release("0.6.0-beta.2"), _release("0.6.0-beta.10"), _release("0.5.1"), _release("0.9.0", true)]
	_check(UpdateRelease.candidate(choices, "stable").tag_name == "v0.5.1", "stable selected beta/draft")
	_check(UpdateRelease.candidate(choices, "beta").tag_name == "v0.6.0-beta.10", "beta order is lexical or includes draft")
	_check(UpdateRelease.validate(_manifest(), _release("0.6.0"), RunStore.VERSION).is_empty(), "valid release rejected")
	for field in ["repository", "tag", "commit", "channel", "save_schema", "schema_version"]:
		var bad := _manifest()
		bad[field] = "invalid"
		_check(not UpdateRelease.validate(bad, _release("0.6.0"), RunStore.VERSION).is_empty(), "invalid manifest " + field)
	for field in ["name", "url", "size", "sha256"]:
		var bad := _manifest()
		bad.assets["windows-x86_64"][field] = "https://other.example/unsafe" if field != "size" else -1
		_check(not UpdateRelease.validate(bad, _release("0.6.0"), RunStore.VERSION).is_empty(), "invalid package " + field)
	var service := FakeUpdates.new()
	service.settings_path = "user://updater_test.cfg"
	root.add_child(service)
	service.current_version = "0.5.0"
	service.replies = [{"ok": true, "code": 200, "data": _release("0.6.0")}, {"ok": true, "code": 200, "data": _manifest()}]
	await service.check_for_updates()
	_check(service.state == service.State.AVAILABLE and service.calls == 2, "new release not offered")
	await service.check_for_updates()
	_check(service.calls == 2, "background check ignored cache")
	service.replies = [{"ok": true, "code": 200, "data": _release("0.4.0")}]
	await service.check_for_updates(true)
	_check(service.state == service.State.CURRENT, "downgrade offered")
	service.replies = [{"ok": false, "code": 404}]
	await service.check_for_updates(true)
	_check(service.state == service.State.CURRENT, "first release absence is an error")
	service.replies = [{"ok": false, "code": 403}]
	await service.check_for_updates(true)
	_check(service.state == service.State.ERROR, "rate limit not handled")
	service.replies = [{"ok": true, "code": 200, "data": [_release("0.7.0-beta.2")]}, {"ok": true, "code": 200, "data": _manifest("0.7.0-beta.2")}]
	service.channel = "beta"
	await service.check_for_updates(true)
	_check(service.available.version == "0.7.0-beta.2", "beta channel did not resolve manifest")
	await _archive(service)
	var cache_job := ProjectSettings.globalize_path("user://updates/failed-fixture/job.json")
	DirAccess.make_dir_recursive_absolute(cache_job.get_base_dir())
	var status := FileAccess.open(cache_job.get_base_dir().path_join("status.json"), FileAccess.WRITE)
	status.store_string('{"state":"failed"}')
	status.close()
	service.last_job = cache_job
	service._save_preferences()
	var restored := FakeUpdates.new()
	root.add_child(restored)
	restored.settings_path = service.settings_path
	restored._ready()
	_check(restored.restored_update and restored.state == restored.State.ERROR, "rollback result is hidden on old-version restart")
	await restored.check_for_updates()
	_check(restored.calls == 0, "background check erased rollback feedback")
	restored.queue_free()
	service.queue_free()
	await process_frame
	_check(not root.get_node("GameUpdates").can_update(), "source checkout enables installer")
	finish(0 if failures.is_empty() else 1)

func _archive(service: GameUpdateService) -> void:
	service.work_dir = ProjectSettings.globalize_path("user://updater-fixture")
	DirAccess.make_dir_recursive_absolute(service.work_dir)
	var path := service.work_dir.path_join("package.zip")
	for broken in [false, true]:
		var zip := ZIPPacker.new()
		zip.open(path)
		for name in UpdateRelease.PACKAGE_FILES:
			zip.start_file(name)
			zip.write_file(JSON.stringify(service.available).to_utf8_buffer() if name == "build-info.json" else "fixture".to_utf8_buffer())
			zip.close_file()
		if broken:
			zip.start_file("../outside.txt")
			zip.write_file("unsafe".to_utf8_buffer())
			zip.close_file()
		zip.close()
		service.available.assets["windows-x86_64"].size = FileAccess.open(path, FileAccess.READ).get_length()
		service.available.assets["windows-x86_64"].sha256 = FileAccess.get_sha256(path)
		_check(await service._verify_archive(service.generation) == not broken, "archive allowlist failed")
	service.cancel_download()
	_check(not FileAccess.file_exists(path), "cancel retained downloaded archive")
