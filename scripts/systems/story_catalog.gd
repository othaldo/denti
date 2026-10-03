class_name StoryCatalog
extends RefCounted

const CHAPTERS: Array[StoryChapter] = [
	preload("res://data/story/pillow.tres"),
	preload("res://data/story/sugar.tres"),
	preload("res://data/story/acid.tres"),
	preload("res://data/story/palace.tres"),
]
const CARDS: Texture2D = preload("res://assets/story/chapter_cards.png")
static var _chapter_art: Array[AtlasTexture] = []


static func chapter_art(index: int) -> Texture2D:
	if _chapter_art.is_empty():
		for region_index in 4:
			var texture := AtlasTexture.new()
			texture.atlas = CARDS
			var width := CARDS.get_width() / 4.0
			texture.region = Rect2(width * region_index, 0, width, CARDS.get_height())
			texture.filter_clip = true
			_chapter_art.append(texture)
	return _chapter_art[clampi(index, 0, 3)]


const INTRO: Array[Dictionary] = [
	{"speaker": "Denti", "text": "Eben noch im Mund. Jetzt unter einem Kissen. War ich nicht fest verwurzelt?"},
	{"speaker": "Zahnfee", "text": "Mein Hilferuf sollte einen göttlichen Wächter holen. Er hat offenbar einen Backenzahn erwischt."},
	{"speaker": "Denti", "text": "Wir sind also beide überrascht."},
	{"speaker": "Denti", "text": "Gestern noch Kaffee, Kekse, Kameraden. Ohne mich müssen die anderen die Brotkrusten übernehmen."},
	{"speaker": "Zahnfee", "text": "Der Karies-Imperator hält mich gefangen. Er und seine drei Herrscher haben meine Portalmagie. Hol sie zurück, dann bringe ich dich nach Hause."},
	{"speaker": "Denti", "text": "Gut. Erst ein Werkzeug. Dann eine sehr gründliche Reinigung."},
]
const FINALE: Array[Dictionary] = [
	{"speaker": "Zahnfee", "text": "Alle vier Fragmente! Das Portal gehört wieder mir. Du hast mich befreit, Denti."},
	{"speaker": "Denti", "text": "Danke, dass du mich nach Hause bringst."},
	{"speaker": "Zahnfee", "text": "Natürlich. Und die Krone des Imperators hat jetzt selbst Karies."},
	{"speaker": "Denti", "text": "Nicht mein sauberstes Werk."},
	{"speaker": "Zahnfee", "text": "Zurück an deinen Platz, göttlicher Wächter."},
	{"speaker": "Denti", "text": "Backenzahn reicht. Und bitte kein Karamell zum Frühstück.", "action": "Nach Hause"},
]

static func chapter(index: int) -> StoryChapter:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)]

static func dialogue(id: StringName) -> Array[Dictionary]:
	if id == &"intro":
		return INTRO
	if id == &"finale":
		return FINALE
	for index in CHAPTERS.size():
		if id == StringName("boss_%d" % index):
			return CHAPTERS[index].boss_dialogue
		if id == StringName("arrival_%d" % index):
			return CHAPTERS[index].arrival_dialogue
	return []


static func before_boss(wave: int) -> StringName:
	if wave in [5, 10, 15, 20]:
		return StringName("boss_%d" % (wave / 5 - 1))
	return &""


static func boss_portrait(speaker: String) -> Texture2D:
	for entry in CHAPTERS:
		if entry.boss != null and entry.boss.display_name == speaker:
			return entry.boss.sprite
	return null

static func after_boss(wave: int) -> StringName:
	if wave == 20:
		return &"finale"
	if wave in [5, 10, 15]:
		return StringName("arrival_%d" % (wave / 5))
	return &""
