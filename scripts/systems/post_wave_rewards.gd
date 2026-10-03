class_name PostWaveRewards
extends RefCounted

# Keep old numeric values stable because saved runs store this enum as an integer.
enum Step { COMBAT, COLLECTING, LEVELS, CHESTS, SHOP, END, RELICS, STORY }

var step: Step = Step.COMBAT
var pending_levels: int = 0
var level_rerolls: int = 0
var pending_chests: Array[Dictionary] = []
var pending_relics: Array[String] = []
var chest_spawned: bool = false
var final_wave: bool = false
var pending_story: StringName = &""


func begin_wave() -> void:
	step = Step.COMBAT
	pending_levels = 0
	level_rerolls = 0
	pending_chests.clear()
	pending_relics.clear()
	chest_spawned = false
	final_wave = false
	pending_story = &""


func earn_level() -> void:
	pending_levels += 1


func mark_chest_spawned() -> void:
	chest_spawned = true


func queue_chest(item_id: StringName, scrap_coins: int) -> void:
	var item := ShopController.by_id(item_id)
	if item == null or item.weapon_data != null:
		return
	pending_chests.append({"item_id": str(item_id), "scrap_coins": maxi(scrap_coins, 1)})


func queue_relics(options: Array[String]) -> void:
	pending_relics.clear()
	for id in options:
		if RelicCatalog.by_id(StringName(id)) != null and not pending_relics.has(id):
			pending_relics.append(id)


func begin_collection() -> void:
	step = Step.COLLECTING


func finish_collection(is_final: bool) -> void:
	final_wave = is_final
	_advance()


func resolve_level() -> void:
	if step != Step.LEVELS or pending_levels <= 0:
		return
	pending_levels -= 1
	level_rerolls = 0
	_advance()


func resolve_chest() -> void:
	if step != Step.CHESTS or pending_chests.is_empty():
		return
	pending_chests.pop_front()
	_advance()


func resolve_relic() -> void:
	if step != Step.RELICS or pending_relics.is_empty():
		return
	pending_relics.clear()
	_advance()


func current_chest() -> Dictionary:
	return pending_chests[0] if not pending_chests.is_empty() else {}


func queue_story(id: StringName) -> void:
	if not StoryCatalog.dialogue(id).is_empty():
		pending_story = id


func resolve_story() -> void:
	if step != Step.STORY:
		return
	pending_story = &""
	_advance()


func save_data() -> Dictionary:
	return {"step": step, "pending_levels": pending_levels, "level_rerolls": level_rerolls, "pending_chests": pending_chests.duplicate(true),
		"pending_relics": pending_relics.duplicate(), "chest_spawned": chest_spawned, "final_wave": final_wave, "pending_story": str(pending_story)}


func restore(saved: Dictionary) -> void:
	step = clampi(int(saved.get("step", Step.COMBAT)), Step.COMBAT, Step.STORY) as Step
	pending_story = StringName(str(saved.get("pending_story", "")))
	if StoryCatalog.dialogue(pending_story).is_empty():
		pending_story = &""
	pending_levels = maxi(int(saved.get("pending_levels", 0)), 0)
	level_rerolls = maxi(int(saved.get("level_rerolls", 0)), 0) if step == Step.LEVELS and pending_levels > 0 else 0
	pending_chests.clear()
	for entry in saved.get("pending_chests", []):
		if not entry is Dictionary:
			continue
		var item := ShopController.by_id(StringName(str(entry.get("item_id", ""))))
		if item != null and item.weapon_data == null:
			pending_chests.append({"item_id": str(item.id), "scrap_coins": maxi(int(entry.get("scrap_coins", 1)), 1)})
	pending_relics.clear()
	for value in saved.get("pending_relics", []):
		var id := str(value)
		if RelicCatalog.by_id(StringName(id)) != null and not pending_relics.has(id):
			pending_relics.append(id)
	chest_spawned = bool(saved.get("chest_spawned", false))
	final_wave = bool(saved.get("final_wave", false))
	if step == Step.LEVELS and pending_levels == 0 or step == Step.CHESTS and pending_chests.is_empty() or step == Step.RELICS and pending_relics.is_empty() or step == Step.STORY and pending_story == &"":
		_advance()


func _advance() -> void:
	if pending_levels > 0:
		step = Step.LEVELS
	elif not pending_chests.is_empty():
		step = Step.CHESTS
	elif not pending_relics.is_empty():
		step = Step.RELICS
	elif pending_story != &"":
		step = Step.STORY
	else:
		step = Step.END if final_wave else Step.SHOP
