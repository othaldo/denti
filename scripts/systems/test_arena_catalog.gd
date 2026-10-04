class_name TestArenaCatalog
extends RefCounted

const ALL: Array[TestArenaData] = [
	preload("res://data/test_arenas/dense_combat.tres"),
	preload("res://data/test_arenas/enemies_only.tres"),
	preload("res://data/test_arenas/bacteria_charge.tres"),
	preload("res://data/test_arenas/boss_charge.tres"),
]

const DIAGNOSTICS := {
	"debug profile": ["profile_full", "Diagnose · volle Arena", TestArenaData.Diagnostic.FULL],
	"debug profile text": ["profile_text", "Diagnose · ohne Textzeichnung", TestArenaData.Diagnostic.NO_TEXT],
	"debug profile effects": ["profile_effects", "Diagnose · ohne Effektzeichnung", TestArenaData.Diagnostic.NO_EFFECTS],
	"debug profile weapons": ["profile_weapons", "Diagnose · ohne eigene Angriffe", TestArenaData.Diagnostic.NO_WEAPONS],
	"debug profile hits": ["profile_hits", "Diagnose · ohne Schadensauswertung", TestArenaData.Diagnostic.NO_HITS],
	"debug profile draw": ["profile_draw", "Diagnose · nur Simulation", TestArenaData.Diagnostic.NO_DRAW],
}

static func _diagnostic(code: String) -> TestArenaData:
	var preset := ALL[0].duplicate() as TestArenaData
	preset.id = StringName(DIAGNOSTICS[code][0])
	preset.code = code
	preset.display_name = DIAGNOSTICS[code][1]
	preset.diagnostic = DIAGNOSTICS[code][2]
	return preset

static func by_id(id: StringName) -> TestArenaData:
	for arena in ALL:
		if arena.id == id:
			return arena
	for code: String in DIAGNOSTICS:
		if StringName(DIAGNOSTICS[code][0]) == id:
			return _diagnostic(code)
	return null

static func by_code(code: String) -> TestArenaData:
	var normalized := " ".join(code.strip_edges().to_lower().split(" ", false))
	for arena in ALL:
		if arena.code == normalized:
			return arena
	if DIAGNOSTICS.has(normalized):
		return _diagnostic(normalized)
	return null
