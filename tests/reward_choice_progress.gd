extends "res://tests/support/test_runtime.gd"

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rewards := PostWaveRewards.new()
	_check(rewards.choice_progress() == Vector2i.ZERO, "an empty wave has no reward progress")
	rewards.earn_level()
	rewards.earn_level()
	rewards.queue_chest(&"metal_crown", 4)
	rewards.queue_relics([str(RelicCatalog.CATALOG[0].id), str(RelicCatalog.CATALOG[1].id), str(RelicCatalog.CATALOG[2].id)])
	rewards.queue_story(&"intro")
	rewards.begin_collection()
	rewards.resolve_level()
	rewards.resolve_chest()
	rewards.resolve_relic()
	_check(rewards.choices_resolved == 0, "choices cannot resolve while loot is being collected")
	# Loot collected during the sweep joins the same total before the first choice.
	rewards.queue_chest(&"fluoride_gel", 5)
	rewards.finish_collection(false)
	_check(rewards.choice_progress() == Vector2i(1, 5), "the total includes swept loot and one relic choice, excluding story")
	_check(rewards.step == PostWaveRewards.Step.LEVELS, "progress tracking preserves level-first ordering")
	rewards.resolve_chest()
	_check(rewards.choices_resolved == 0, "a chest cannot skip an unresolved level")
	rewards.resolve_level()
	_check(rewards.choice_progress() == Vector2i(2, 5), "the second level retains the complete queue total")
	var restored := PostWaveRewards.new()
	restored.restore(rewards.save_data())
	_check(restored.choice_progress() == Vector2i(2, 5) and restored.choices_resolved == 1, "saving during level choices preserves completed choices")
	restored.resolve_level()
	_check(restored.step == PostWaveRewards.Step.CHESTS and restored.choice_progress() == Vector2i(3, 5), "capsules follow levels without resetting progress")
	restored.resolve_chest()
	var resumed := PostWaveRewards.new()
	resumed.restore(restored.save_data())
	_check(resumed.choice_progress() == Vector2i(4, 5), "saving between capsule choices preserves overall progress")
	resumed.resolve_chest()
	_check(resumed.step == PostWaveRewards.Step.RELICS and resumed.choice_progress() == Vector2i(5, 5), "three relic options count as one choice")
	resumed.resolve_relic()
	_check(resumed.step == PostWaveRewards.Step.STORY and resumed.choice_progress() == Vector2i(5, 5), "story dialogue does not add another reward choice")
	resumed.resolve_relic()
	resumed.resolve_level()
	resumed.resolve_chest()
	_check(resumed.choices_resolved == 5, "duplicate or wrong-type resolutions do not inflate completed choices")
	resumed.resolve_story()
	_check(resumed.step == PostWaveRewards.Step.SHOP and resumed.choice_progress() == Vector2i(5, 5), "the completed queue remains complete in the shop")
	resumed.begin_wave()
	_check(resumed.choices_resolved == 0 and resumed.choices_total == 0 and resumed.choice_progress() == Vector2i.ZERO, "the next wave resets the complete reward progress")
	resumed.finish_collection(true)
	_check(resumed.step == PostWaveRewards.Step.END and resumed.choice_progress() == Vector2i.ZERO, "a final wave without choices has no phantom reward")

	var legacy := PostWaveRewards.new()
	legacy.restore({"step": PostWaveRewards.Step.CHESTS, "pending_chests": [{"item_id": "metal_crown", "scrap_coins": 4}, {"item_id": "fluoride_gel", "scrap_coins": 5}]})
	_check(legacy.choice_progress() == Vector2i(1, 2), "legacy saves start a remaining-choice counter without inventing completed choices")
	legacy.resolve_chest()
	_check(legacy.choice_progress() == Vector2i(2, 2), "legacy progress advances with the new schema")
	var legacy_resumed := PostWaveRewards.new()
	legacy_resumed.restore(legacy.save_data())
	_check(legacy_resumed.choice_progress() == Vector2i(2, 2), "a migrated save retains its progress on the next resume")
	legacy_resumed.resolve_chest()
	_check(legacy_resumed.choice_progress() == Vector2i(2, 2), "the migrated queue finishes normally")

	var expanded := PostWaveRewards.new()
	expanded.earn_level()
	expanded.finish_collection(false)
	expanded.queue_chest(&"metal_crown", 4)
	_check(expanded.choice_progress() == Vector2i(1, 2), "late queued rewards cannot produce a current index above the total")
	expanded.resolve_level()
	_check(expanded.choice_progress() == Vector2i(2, 2) and expanded.choices_total == 2, "late queued rewards are included before resolving a choice")
	var invalid := PostWaveRewards.new()
	invalid.restore({"step": PostWaveRewards.Step.LEVELS, "pending_levels": 2, "choices_resolved": -3, "choices_total": -5})
	_check(invalid.choice_progress() == Vector2i(1, 2), "negative saved progress is sanitized against pending rewards")
	invalid.restore({"step": PostWaveRewards.Step.LEVELS, "pending_levels": 2, "choices_resolved": 3, "choices_total": 1})
	_check(invalid.choice_progress() == Vector2i(4, 5), "undersized saved totals retain resolved and pending choices")
	if failures == 0:
		print("Denti reward choice progress test passed")
	finish(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
