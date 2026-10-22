extends "res://tests/support/test_runtime.gd"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var expected := [2, 3, 5, 8, 12, 17, 23, 30, 38, 47]
	var total := 0
	var shop := ShopController.new()
	root.add_child(shop)
	var loadout := WeaponLoadout.new()
	shop.open_shop(12, 0, loadout)
	for index in expected.size():
		if shop.reroll_cost != expected[index]:
			push_error("shop reroll price curve failed at purchase %d" % index)
			finish(1); return
		total += shop.reroll_cost
		shop.reroll(12, 0, loadout)
	if total != 185 or EconomyRules.level_reroll_cost(10, 4) != 15:
		push_error("repeated rerolls do not drain gold progressively")
		finish(1); return
	var resumed := ShopController.new()
	root.add_child(resumed)
	resumed.restore_state(shop.save_state(), 12)
	if resumed.rerolls != shop.rerolls or resumed.reroll_cost != shop.reroll_cost:
		push_error("new reroll count / quote changed on resume")
		finish(1); return
	var legacy := shop.save_state()
	legacy.erase("shop_rerolls")
	legacy.reroll_cost = 7
	resumed.restore_state(legacy, 12)
	if resumed.reroll_cost != 7:
		push_error("legacy reroll quote changed while resuming")
		finish(1); return
	resumed.reroll(12, 0, loadout)
	if resumed.reroll_cost <= 8:
		push_error("legacy save bypasses escalating reroll prices")
		finish(1); return
	resumed.open_shop(13, 0, loadout)
	if resumed.rerolls != 0 or resumed.reroll_cost != 2:
		push_error("new shop did not reset reroll prices")
		finish(1); return
	for wave in range(1, 5): assert(EconomyRules.gold_drop_factor(wave) == 1)
	assert(is_equal_approx(EconomyRules.gold_drop_factor(20), 0.55))
	assert(is_equal_approx(EconomyRules.gold_drop_factor(100), 0.40))
	print("Denti bounded gold and progressive reroll economy test passed: ten rolls cost 185 rather than 65")
	shop.free(); resumed.free(); loadout.free()
	finish(0)
