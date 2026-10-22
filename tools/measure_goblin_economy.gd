extends SceneTree

const OUTPUT := "res://.godot/goblin_preview/economy.json"
const RUNS := 12
var wave: WaveController
var row: Dictionary
var difficulty: DifficultyData

func _initialize() -> void:
	var rows: Array[Dictionary] = []
	for selected in DifficultyCatalog.ALL:
		difficulty = selected
		for number in range(1, 21):
			rows.append({"difficulty": str(selected.id), "wave": number, "before": 0.0, "after": 0.0})
		for run in RUNS:
			seed(20261022 + run)
			wave = WaveController.new()
			wave.difficulty_id = selected.id
			wave.enemy_requested.connect(_enemy)
			wave.horde_requested.connect(_horde)
			wave.elite_requested.connect(_elite)
			for number in range(1, 21):
				row = rows[(rows.size() - 20) + number - 1]
				wave.start_next_wave()
				while wave.active: wave._process(1.0 / 60)
			wave.free()
	for entry in rows:
		entry.before /= RUNS
		entry.after /= RUNS
		entry["reduction_percent"] = 100 * (1 - entry.after / entry.before)
		if entry.wave in [1, 4, 10, 19]: print("%s wave %d: %.1f -> %.1f expected gold (-%.1f%%)" % [entry.difficulty, entry.wave, entry.before, entry.after, entry.reduction_percent])
	var report := {"method": "12 seeded spawn plans per difficulty. Same requested enemies for old/new expected coin chance; assumes every requested non-boss dies during combat. Includes guaranteed elite coins and escorts. Excludes caps, player builds, economy items, capsules, spending and goblin theft. This is an income forecast, not a balance playtest.", "rows": rows}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT).get_base_dir())
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	quit()

func _enemy(data: EnemyData) -> void:
	if data.is_boss: return
	var number := wave.current_wave
	var previous := 1.0 if number < 5 else maxf(1 - 0.015 * number, 0.5)
	var old_chance := 1.0 if data.is_elite else clampf(previous * data.coin_drop_chance * difficulty.reward_chance_multiplier, 0, 1)
	row.before += old_chance * data.coin_drop
	row.after += EconomyRules.coin_chance(data, number, difficulty.reward_chance_multiplier) * data.coin_drop

func _horde(data: EnemyData, count: int) -> void:
	for i in count: _enemy(data)

func _elite(data: EnemyData) -> void:
	_enemy(data)
	if data.escort_data != null: _horde(data.escort_data, data.escort_count)
