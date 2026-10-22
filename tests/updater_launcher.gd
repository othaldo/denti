extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if not OS.has_feature("windows"):
		finish()
		return
	var directory := ProjectSettings.globalize_path("user://updater launch ä's & spaces")
	DirAccess.make_dir_recursive_absolute(directory)
	var script_path := directory.path_join("installer.ps1")
	var job_path := directory.path_join("job.json")
	var receipt := job_path + ".receipt"
	var script := FileAccess.open(script_path, FileAccess.WRITE)
	script.store_string("param([string]$JobPath)\n[IO.File]::WriteAllText($JobPath + '.receipt', 'ok')\n")
	script.close()
	var powershell := OS.get_environment("SystemRoot").path_join("System32/WindowsPowerShell/v1.0/powershell.exe")
	var pid := OS.create_process(powershell, GameUpdateService.installer_arguments(script_path, job_path))
	for attempt in 100:
		# The suite uses --fixed-fps: an external process needs real wall-clock time.
		OS.delay_msec(50)
		await process_frame
		if FileAccess.file_exists(receipt): break
		if not OS.is_process_running(pid): break
	var passed := FileAccess.file_exists(receipt) and FileAccess.get_file_as_string(receipt) == "ok"
	if not passed: push_error("Windows helper launch did not preserve Unicode/space/apostrophe arguments")
	DirAccess.remove_absolute(script_path)
	DirAccess.remove_absolute(receipt)
	DirAccess.remove_absolute(directory)
	finish(0 if passed else 1)
