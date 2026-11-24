extends "res://tools/benchmark_earned_progression.gd"
## Earned Kräuterzahn runs on Normal (W1-20): real HP, drops, XP, talents and a
## paid shop that buys planting staffs (new staffs and fusions) plus staples.
## Talent policies follow one branch each; Good Old Molar with the drill is the
## baseline. Diagnostic only, not a win rate.
## Usage: godot --headless --path . --script res://tools/benchmark_herb_druid.gd
##   -- --output=res://.godot/herb_druid_earned.json [--policies=sage,totem] [--seeds=1,2]

const POLICIES := {
	"sage": [&"herb_thorns", &"herb_dense", &"herb_staff_two", &"herb_shrub", &"shrub_wild", &"herb_staff_three", &"shrub_seeds"],
	"totem": [&"herb_staff_two", &"herb_soothe", &"herb_can", &"herb_pollen", &"herb_totem", &"totem_tea", &"totem_wreath", &"herb_staff_three"],
	"clove": [&"herb_staff_two", &"herb_numb", &"herb_hedge", &"herb_clove", &"clove_oil", &"clove_snare", &"herb_staff_three"],
}
var path := "sage"


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var policies: Array = _arguments("policies", ["sage", "totem", "clove", "molar"])
	var seeds: Array = _arguments("seeds", ["13579", "24680"])
	var movement := str(_arguments("movement", ["hunt"])[0])
	var report := {"schema_version": 1, "method": "Earned Normal runs W1-20, hunt movement, staffs bought when offered.", "samples": []}
	for policy in policies:
		path = str(policy)
		for value in seeds:
			var sample_seed := int(value)
			var build := "turbo_drill" if path == "molar" else "planting_staff"
			var sample: Dictionary = await sample_run(build, &"normal", movement, sample_seed, 20)
			sample["policy"] = path
			report.samples.append(sample)
			var staffs := 0
			for weapon in sample.final.get("equipment", []):
				if str(weapon.get("id", "")) == "planting_staff": staffs += 1
			print("herb %s seed %d: %s wave %d, level %d, kills %d, staffs %d, talents %s" % [path, sample_seed, sample.outcome, sample.wave, sample.level, sample.kills, staffs, JSON.stringify(sample.final.get("talents", {}).get("ranks", {}))])
	var output := str(_arguments("output", ["res://.godot/herb_druid_earned.json"])[0])
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	finish_checks()


func make_run(build: String, difficulty: StringName, sample_seed: int):
	var session: Node = root.get_node("GameSession")
	session.pending_start_class_id = &"good_old_molar" if path == "molar" else &"herb_druid"
	session.pending_talent_run = true
	return super.make_run(build, difficulty, sample_seed)


func spend_talent_points(game) -> void:
	var order: Array = POLICIES.get(path, [&"versatile", &"molar_opener", &"molar_stride"])
	for point in 100:
		if game.talents.used(game.player.stats.class_data.talent_tree) >= game.rewards.pending_levels: break
		var planned := false
		for id in order:
			if game.talents.plan_talent(id, game.player.stats, game.UPGRADES, game.rewards.pending_levels):
				planned = true
				break
		if not planned:
			var key := fallback_talent_stat(game)
			planned = key != &"" and game.talents.plan_stat(key, game.player.stats, game.UPGRADES, game.rewards.pending_levels)
		if not planned:
			check(false, "Herb policy cannot allocate an earned level point")
			return
	game._on_talents_completed()


func before_combat_step(game, _frame: int) -> bool:
	if game.player.dash.ready_to_dash(): game.player.try_dash()
	return true
