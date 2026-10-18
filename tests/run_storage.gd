extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var original := {"version": RunStore.VERSION, "wave": 3, "player": {"stats": {"health": 80.0}}, "coins": 42}
	_check(not RunSaveData.normalize(original).is_empty(), "minimal compatible save rejected")
	for invalid in [[], {"wave": 1, "player": []}, {"wave": [], "player": {}}, {"wave": 1, "player": {"stats": {"health": []}}}, {"wave": 1, "player": {}, "items": {"cooldowns": []}}, {"wave": 1, "player": {}, "rewards": {"pending_chests": {}}}, {"wave": 1, "player": {}, "weapons": [{"rolls": []}]}, {"wave": 1, "player": {}, "loot": [{"position": [{}, 1]}]}, {"wave": 1, "player": {}, "player_projectiles": [{"id": "water_jet"}]}, {"wave": 1, "player": {}, "coins": INF}]:
		_check(RunSaveData.normalize(invalid).is_empty(), "invalid save accepted: " + str(invalid))
	var legacy := original.duplicate(true)
	legacy.offers = [{"id": "floss"}]
	legacy.upgrades = [{"stat": "move_speed"}]
	var migrated := RunSaveData.normalize(legacy)
	_check(migrated.offers[0].id == "floss_whip" and migrated.upgrades[0].stat == "speed_bonus", "legacy identifiers not migrated")
	_check(legacy.offers[0].id == "floss", "normalization mutated caller state")
	var path := "user://atomic_run_test.json"
	_check(RunStore.save_run(path, original) == OK, "initial atomic save failed")
	_check(int(RunStore.load_run(path).get("coins", -1)) == 42, "atomic save did not round-trip")
	var temporary := "%s.%d.tmp" % [path, OS.get_process_id()]
	_check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(temporary)) == OK, "failed to arrange write failure")
	var changed := original.duplicate(true)
	changed.coins = 99
	_check(RunStore.save_run(path, changed) != OK, "expected write failure did not occur")
	_check(int(RunStore.load_run(path).get("coins", -1)) == 42, "failed write destroyed last valid save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	_check(RunStore.save_run(path, changed) == OK and int(RunStore.load_run(path).get("coins", -1)) == 99, "replacement save failed")
	RunStore.clear(path)
	print("Denti save validation and atomic storage test passed" if failures.is_empty() else str(failures))
	finish(0 if failures.is_empty() else 1)
