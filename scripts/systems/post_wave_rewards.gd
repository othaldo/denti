class_name PostWaveRewards
extends RefCounted

enum Step { COMBAT, COLLECTING, LEVELS, CHESTS, SHOP, END }

var step: Step = Step.COMBAT
var pending_levels: int = 0
var pending_chests: Array[Dictionary] = []
var chest_spawned: bool = false
var final_wave: bool = false


func begin_wave() -> void:
	step = Step.COMBAT
	pending_levels = 0
	pending_chests.clear()
	chest_spawned = false
	final_wave = false


func earn_level() -> void:
	pending_levels += 1


func mark_chest_spawned() -> void:
	chest_spawned = true


func queue_chest(item_id: StringName, scrap_coins: int) -> void:
	var item := ShopController.by_id(item_id)
	if item == null or item.weapon_data != null:
		return
	pending_chests.append({"item_id": str(item_id), "scrap_coins": maxi(scrap_coins, 1)})


func begin_collection() -> void:
	step = Step.COLLECTING


func finish_collection(is_final: bool) -> void:
	final_wave = is_final
	_advance()


func resolve_level() -> void:
	if step != Step.LEVELS or pending_levels <= 0:
		return
	pending_levels -= 1
	_advance()


func resolve_chest() -> void:
	if step != Step.CHESTS or pending_chests.is_empty():
		return
	pending_chests.pop_front()
	_advance()


func current_chest() -> Dictionary:
	return pending_chests[0] if not pending_chests.is_empty() else {}


func save_data() -> Dictionary:
	return {"step": step, "pending_levels": pending_levels, "pending_chests": pending_chests.duplicate(true),
		"chest_spawned": chest_spawned, "final_wave": final_wave}


func restore(saved: Dictionary) -> void:
	step = clampi(int(saved.get("step", Step.COMBAT)), Step.COMBAT, Step.END) as Step
	pending_levels = maxi(int(saved.get("pending_levels", 0)), 0)
	pending_chests.clear()
	for entry in saved.get("pending_chests", []):
		if not entry is Dictionary:
			continue
		var item := ShopController.by_id(StringName(str(entry.get("item_id", ""))))
		if item != null and item.weapon_data == null:
			pending_chests.append({"item_id": str(item.id), "scrap_coins": maxi(int(entry.get("scrap_coins", 1)), 1)})
	chest_spawned = bool(saved.get("chest_spawned", false))
	final_wave = bool(saved.get("final_wave", false))
	if step == Step.LEVELS and pending_levels == 0 or step == Step.CHESTS and pending_chests.is_empty():
		_advance()


func _advance() -> void:
	if pending_levels > 0:
		step = Step.LEVELS
	elif not pending_chests.is_empty():
		step = Step.CHESTS
	else:
		step = Step.END if final_wave else Step.SHOP
