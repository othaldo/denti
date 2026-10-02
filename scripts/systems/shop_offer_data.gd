class_name ShopOfferData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 5) var rarity_tier: int = 1
@export_range(1, 4) var weapon_tier: int = 1
@export var price: int = 3
@export_range(0, 90) var icon_index: int = 0
@export var stat_changes: Dictionary = {}
@export var weapon_data: WeaponData
@export var icon_texture: Texture2D
@export var effect_kind: StringName = &""
@export var effect_value: float = 0.0
@export_range(0, 9) var max_stacks: int = 0
@export var tags: Array[StringName] = []
@export var family_id: StringName = &""
@export_range(0, 9) var family_limit: int = 0


func effect_text() -> String:
	return DentiAttributes.resolve_text(description)


func card_effect_text() -> String:
	# Icon values already explain unconditional stats. Keep the first additional
	# mechanic on the purchase card; the full description stays in hover/details.
	var stat_clauses: PackedStringArray = []
	for key: StringName in stat_changes:
		var type := DentiAttributes.from_key(key)
		if type >= 0:
			stat_clauses.append(DentiAttributes.bonus_text(type, float(stat_changes[key])))
	if effect_kind == &"" and not stat_changes.is_empty() and stat_clauses.size() == stat_changes.size():
		return ""
	# Decimal values, ordinal hits ("3.") and "max." belong to their sentence.
	var source := effect_text()
	var sentence_break := RegEx.new()
	sentence_break.compile("(?<!\\d)(?<!max)(?<!bzw)(?<!ca)\\.\\s+")
	var sentences: PackedStringArray = []
	var start := 0
	for found in sentence_break.search_all(source):
		sentences.append(source.substr(start, found.get_start() - start))
		start = found.get_end()
	sentences.append(source.substr(start))
	for sentence in sentences:
		var remaining: PackedStringArray = []
		for clause in sentence.split(", "):
			var plain := clause.strip_edges().trim_suffix(".")
			if not stat_clauses.has(plain.trim_suffix(" und Heilung").trim_suffix(" (HP)")):
				remaining.append(plain)
		if not remaining.is_empty():
			var result := ", ".join(remaining)
			if result.begins_with("+") and result.contains(" % gegen Bosse"):
				result = result.replace(" % gegen Bosse", " % Schaden gegen Bosse")
			return result
	return ""


func limit_text() -> String:
	if rarity_tier == 5:
		return "Einmalig pro Run"
	if family_id != &"" and family_limit > 0:
		return "Familienlimit: %d · alle Seltenheiten zusammen" % family_limit
	return "Stapellimit: %d" % max_stacks if max_stacks > 0 else "Unbegrenzt stapelbar"
