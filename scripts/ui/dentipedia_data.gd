class_name DentipediaData
extends RefCounted

const CATEGORIES := ["Waffen", "Items", "Relikte", "Werte", "Mechaniken"]
const TOPICS := {
	"Strom & Nass": "Strom ist eine Kettenreaktion: Ein passendes Ketten-Item lässt Wasser- und Lichttreffer auf einen nahen Gegner überspringen. Ohne dieses Item entstehen keine automatischen Ketten.\n\nWasserwaffen mit Nass-Effekt bereiten Gegner vor. Ein nasses Ziel vergrößert die Sprungreichweite um 85. Leitfähige Items verstärken Wasser- und Lichtschaden gegen nasse Gegner.\n\nNutze dichte Gruppen: Wasser zum Durchnässen, Licht oder Wasser für die Entladung. Die Sprünge haben eine gemeinsame kurze Abklingzeit und lösen keine endlosen Ketten aus.",
	"Blutung": "Schnittwaffen mit Blutungswert verursachen zusätzlich Schaden über Zeit. Mehrere Treffer stapeln Blutung bis zur Grenze der Quelle. Der Waffeneintrag zeigt Stärke und Dauer.\n\nBlutungsitems können Stärke, Dauer, Stapelzahl oder Schaden gegen blutende Gegner erhöhen. Andere übertragen Blutung nach einem Kill auf ein nahes Ziel. Halte robuste Gegner unter Blutung und bleibe in Bewegung, während der Effekt weiterarbeitet.\n\nBlutung an Denti wird durch Härte reduziert; Gift ignoriert Härte. Laufende Statusschäden an Denti enden nach dem Kampf.",
	"Kritische Treffer & Fokus": "Glanz erhöht die Chance auf kritische Waffentreffer. Der Krit-Multiplikator gehört zur Waffe. Manche Waffen erhalten garantierte kritische Treffer nach mehreren Angriffen auf dasselbe Ziel.\n\nFokus belohnt wiederholte Angriffe auf dasselbe Ziel. Die Waffe gibt den maximalen Bonus vor. Zielwechsel unterbricht solche zielgebundenen Serien. Krit-Items können zusätzliche Splitter, Strahlen oder Flächentreffer auslösen.",
	"Schmelzbruch": "Schmelz ist Dentis maximales Leben. Schmelzbruch ist dagegen eine Schadensart. Waffen können Gegner zeitweise für Schmelzbruch anfälliger machen; die Stärke und Dauer stehen bei der Waffe. Diese Verwundbarkeit stapelt sich nicht unbegrenzt.",
	"Geschosse & Flächenschaden": "Durchschlag lässt ein Geschoss weitere Gegner treffen. Zusätzliche Geschosse verbreitern eine Salve. Explosionsradius bestimmt, wie weit ein Flächentreffer reicht.\n\nItem-Folgeeffekte haben teilweise eigene Abklingzeiten. Ihr Schaden wird aus dem auslösenden Treffer berechnet; sie starten keine rekursiven Proc-Ketten. Mehr Geschosse bedeuten daher nicht automatisch für jedes Geschoss eine zusätzliche Explosion.",
	"Heilung, Schild & Ausweichen": "Speichel regeneriert Leben. Heilungsitems können weitere Heilungen oder Vorteile durch Überheilung erzeugen. Härte reduziert erlittenen Schaden.\n\nSchildladungen fangen Treffer ab. Zahnflutsch gibt eine Ausweichchance bis maximal 60 %; ein ausgewichener Treffer verbraucht keine Schildladung. Hoher Schmelz ersetzt keine Bewegung: Telegraphe und gefährliche Geschosse bleiben wichtig.",
	"Wurzeln & Fusionieren": "Denti hat sechs Wurzeln. Jede Waffe belegt eine oder zwei. Zwei gleiche Waffen derselben Stufe lassen sich bis Mk IV fusionieren; die neue Waffe übernimmt die investierten Münzen. Ein grüner Pfeil auf der ausgerüsteten Waffe zeigt, dass du sie im Shop fusionieren oder weiterentwickeln kannst.\n\nManche Mk-IV-Waffen können mit einem passenden Build zu einer knallroten Spezialwaffe auf Mk V fusionieren. Das Spiel verrät das Rezept erst, wenn alle Voraussetzungen erfüllt sind. Nach deiner ersten erfolgreichen Fusion erklärt die Dentipedia diese Spezialwaffe und zeigt die Zutaten. Items bleiben erhalten. Mehrere Spezialwaffen pro Run sind möglich.",
	"Shop & Münzen": "Der Preisbutton kauft ein Angebot; die Karte öffnet Details. Fehlen Münzen oder Wurzelplätze oder ist ein Stapellimit erreicht, bleibt der Kauf gesperrt.\n\nDer Pin merkt ein Angebot kostenlos und bindet seinen Preis über Rerolls und Wellen. Neuwürfeln kostet Münzen. Verkauf erstattet einen Teil der investierten Münzen. Die nächsten Angebote können zu deinem Build passen, garantieren aber keine bestimmte Kombination.",
	"Seltenheiten & Stapeln": "Rahmen und Hintergrund zeigen die Seltenheit. Items einer Familie teilen sich ihr Familienlimit, auch über verschiedene Seltenheiten. Seltenere Itemvarianten ersetzen deine bisherigen Exemplare nicht. Die konkrete Grenze steht im Itemeintrag.\n\nNormale Waffenstufen reichen von I bis IV; weiterentwickelte Spezialwaffen zeigen Mk V in Rot. Zahnglück verbessert Beute- und Seltenheitschancen innerhalb fester Grenzen. Mythische Items sind einmalig pro Run.",
	"Wellen & Belohnungen": "Kämpfe laufen ohne Level-up-Unterbrechung. XP merkt verdiente Level vor; eingesammelte Kisten werden ebenfalls vorgemerkt.\n\nAm Wellenende wird erst die übrige Beute eingesammelt. Danach folgen Level-up-Auswahl, Kisten behalten oder zerlegen und gegebenenfalls Bossrelikte. Erst dann öffnet die Zahnklinik. Nach dem Sieg ist eine endlose Fortsetzung möglich.",
	"Gegner, Eliten & Bosse": "Normale Gegner bedrängen dich durch Gruppen, schnelle Verfolger und Fernangriffe. Eliten haben stärkere Angriffe; Bosse kombinieren Geschossmuster, Flächenwarnungen und weitere Gegner.\n\nAchte auf angekündigte Angriffe und freie Ausweichwege. Kreise nicht nur direkt um den Boss: Geschosse und Horden können Fluchtwege schließen. Ab späteren Wellen erhöhen Dichte und gemischte Rollen den Druck. Gegnerwerte skalieren mit Welle und Schwierigkeitsgrad.",
}

static func entries(category: int, discovered: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match category:
		0:
			for weapon in WeaponCatalog.ALL:
				result.append(_weapon(weapon))
			for recipe in WeaponEvolutions.ALL:
				if discovered.has(str(recipe.id)):
					var entry := _weapon(recipe.result)
					entry["recipe"] = recipe
					result.append(entry)
				else:
					# No name, recipe, stats or search keywords until actually discovered.
					result.append({"title": "Unbekannte Spezialwaffe", "icon": recipe.result.sprite, "locked": true, "body": "Noch nicht fusioniert."})
		1:
			for item in ShopController.CATALOG:
				result.append({"title": item.display_name, "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index), "body": item.effect_text() + "\n\n" + item.limit_text()})
		2:
			for relic in RelicCatalog.CATALOG:
				result.append({"title": relic.display_name, "icon": DentiUIIcons.relic(relic.icon_index), "body": DentiAttributes.resolve_text(relic.description)})
		3:
			for type in DentiAttributes.ACTIVE:
				result.append({"title": DentiAttributes.name_for(type), "icon": DentiUIIcons.stat(DentiAttributes.ICONS[type]), "body": DentiAttributes.meaning_for(type)})
		4:
			for title in TOPICS:
				result.append({"title": title, "body": TOPICS[title]})
	return result

static func _weapon(data: WeaponData) -> Dictionary:
	var body := data.description + "\n\n" + data.roots_text() + " · " + data.combat_text()
	for tier in ([4] if data.evolution_kind != &"" else [1, 2, 3, 4]):
		body += "\n\n%s: %s" % [WeaponPresentation.tier_text(data, tier), data.stats_text(tier)]
	body += "\n\nBasiswerte ohne deinen Build. Bisskraft, Nah-/Fernschaden, Putzeifer und Items verändern die tatsächlichen Kampfwerte."
	return {"title": data.display_name, "icon": data.sprite, "body": body, "evolved": data.evolution_kind != &""}

static func ingredients(recipe: WeaponEvolutionRecipe) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in [recipe.base_weapon, recipe.partner_weapon]:
		if id != &"":
			var data := WeaponCatalog.by_id(id)
			result.append({"title": data.display_name + " IV", "icon": data.sprite})
	for family in recipe.families:
		for item in ShopController.CATALOG:
			if item.family_id == family:
				var family_name: String = {&"chain": "Ketten", &"bleed": "Blutung", &"damage": "Bisskraft", &"return": "Rückflug"}.get(family, str(family))
				result.append({"title": family_name + "-Familie\nJede Seltenheit", "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)})
				break
	for id in recipe.items:
		var item := ShopController.by_id(id)
		result.append({"title": item.display_name, "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)})
	return result
