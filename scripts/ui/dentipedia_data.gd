class_name DentipediaData
extends RefCounted

const CATEGORIES := ["Waffen", "Items", "Relikte", "Werte", "Mechaniken", "Verzauberungen"]
const ENCHANTMENT_OVERVIEW := "Upgrade-Kapseln verbessern eine gewählte Waffeninstanz. Die Auswahl folgt nach der Welle und dem Einsammeln der Beute. Wähle eine Verzauberung oder zerlege die Kapsel für Münzen.\n\nJede Waffe beginnt mit einem Platz für Verzauberungen. Platzfunde öffnen bis zu vier Plätze. Ein neuer Effekt belegt einen Platz; ist alles belegt, wählst du bewusst einen Ersatz. Alle belegten Effekte wirken gleichzeitig. Wurzeln bestimmen dagegen, wie viele Waffen Denti tragen kann.\n\nGleiche Verzauberungen werden stärker. Sie steigen von I bis III und danach in der Seltenheit auf. Schwächere gleiche Funde bringen anteiligen Fortschritt, höhere Seltenheiten erlauben Sprünge. Legendäre Verzauberungen wachsen auch nach III weiter; Nässe und Lebensraub haben feste Wirkungsgrenzen. Der Namenszusatz folgt der am weitesten entwickelten Verzauberung.\n\nWähle nach deinem Build: Feuer hilft gegen Gruppen, Gift gegen langlebige Ziele, Eis schafft Kontrolle und Elektro verbindet sich mit Nässe. Blutungsitems unterstützen Blutung, Weihe belohnt Krits und Lebensraub heilt begrenzt. Reichweite und Angriffstempo verändern die gewählte Waffe. Die Karten zeigen passende Build-Teile sowie Vorher-/Nachher-Werte; der Tooltip erklärt weitere Regeln. Jeder Effekt hat hier einen eigenen Eintrag."
const ENCHANTMENT_SYNERGIES := {
	&"fire": "Flächenwaffen und Explosionen können mehrere brennende Gegner besiegen und Glut freisetzen.",
	&"ice": "Glanz und Krit-Items lösen Eissplitter häufiger aus. Weihe belohnt dieselben kritischen Treffer.",
	&"poison": "Angriffstempo baut Gift auf. Reichweite hilft, robuste Ziele beim Ausweichen weiter zu vergiften.",
	&"bleed": "Zahnseide-Spule, Blutungsuhr und Skalpellwachs verstärken den Blutungsbuild. Ansteckende Zahnseide und Blutmond-Zahn verteilen Blutung beim Tod.",
	&"electric": "Wasserflosser oder die Verzauberung Nässe bereiten Gegner vor. Funkensonde und andere Kettenitems erlauben einen weiteren, stärkeren Sprung; Leitlack verstärkt Elektro gegen nasse Ziele.",
	&"wet": "Elektro erhält gegen nasse Startziele mehr Sprünge und Reichweite. Leitlack verlängert Nässe; mit Spülventil können die Treffer Spülpfützen erzeugen.",
	&"holy": "Glanz, Krit-Items und schnelle Treffer helfen, die Markierungen auszulösen. Eis erzeugt bei Krits zusätzlich Splitter.",
	&"leech": "Ergänzt Heilungs- und Schutzbuilds. Speichelkelch kann überschüssige Heilung in Schildfortschritt umwandeln. Mehr Waffen verkürzen das gemeinsame Heilintervall nicht.",
	&"range": "Ergänzt Gift und andere Fernkampf-Builds: mehr Abstand halten und trotzdem weiter treffen.",
	&"tempo": "Hilft Gift beim Aufbau, Blutung bei wiederholten Treffern und Weihe beim Sammeln von Krits. Gemeinsame Effektintervalle bleiben bestehen.",
}
const TOPICS := {
	"Verzauberungen": ENCHANTMENT_OVERVIEW,
	"Strom & Nass": "Wasser- und Lichttreffer springen mit einem passenden Kettenitem auf einen nahen Gegner über. Die Verzauberung Elektro erzeugt eigene Kettenblitze auch ohne dieses Item.\n\nWasserwaffen und die Verzauberung Nässe durchnässen Gegner. Ein nasses Startziel erlaubt Elektro einen weiteren Sprung und erhöht die Sprungreichweite. Kettenitems ergänzen einen weiteren, stärkeren Elektrosprung. Leitlack verstärkt Wasser-, Licht- und Elektro-Verzauberungsschaden gegen nasse Ziele.\n\nNutze dichte Gruppen: Nässe vorbereiten, dann mit Elektro entladen. Gemeinsame Intervalle und Zielgrenzen verhindern endlose Ketten. Die einzelnen Regeln stehen unter Verzauberungen bei Elektro und Nässe.",
	"Blutung": "Schnittwaffen mit Blutungswert verursachen zusätzlich Schaden über Zeit. Mehrere Treffer stapeln Blutung bis zur Grenze der Quelle. Der Waffeneintrag zeigt Stärke und Dauer. Die Blutungsverzauberung ist ebenfalls eine Blutungsquelle und profitiert von Blutungsitems und Blutmond-Zahn.\n\nBlutungsitems können Stärke, Dauer, Stapelzahl oder Schaden gegen blutende Gegner erhöhen. Andere übertragen Blutung nach einem Kill auf ein nahes Ziel. Halte robuste Gegner unter Blutung und bleibe in Bewegung, während der Effekt weiterarbeitet.\n\nBlutung an Denti wird durch Härte reduziert; Gift ignoriert Härte. Laufende Statusschäden an Denti enden nach dem Kampf.",
	"Kritische Treffer & Fokus": "Glanz erhöht die Chance auf kritische Waffentreffer. Der Krit-Multiplikator gehört zur Waffe. Manche Waffen erhalten garantierte kritische Treffer nach mehreren Angriffen auf dasselbe Ziel.\n\nFokus belohnt wiederholte Angriffe auf dasselbe Ziel. Die Waffe gibt den maximalen Bonus vor. Zielwechsel unterbricht solche zielgebundenen Serien. Krit-Items können zusätzliche Splitter, Strahlen oder Flächentreffer auslösen.\n\nKrits gegen gekühlte Ziele können Eissplitter auslösen. Weihe sammelt Krit-Markierungen und löst einen Lichtstoß aus; auch andere Waffen können ein bereits markiertes Ziel auslösen. Beide Verzauberungen haben eigene Einträge mit ihren Grenzen.",
	"Schmelzbruch": "Schmelz ist Dentis maximales Leben. Schmelzbruch ist dagegen eine Schadensart. Waffen können Gegner zeitweise für Schmelzbruch anfälliger machen; die Stärke und Dauer stehen bei der Waffe. Diese Verwundbarkeit stapelt sich nicht unbegrenzt.",
	"Geschosse & Flächenschaden": "Durchschlag lässt ein Geschoss weitere Gegner treffen. Zusätzliche Geschosse verbreitern eine Salve. Explosionsradius bestimmt, wie weit ein Flächentreffer reicht.\n\nItem-Folgeeffekte haben teilweise eigene Abklingzeiten. Ihr Schaden wird aus dem auslösenden Treffer berechnet; sie starten keine rekursiven Proc-Ketten. Mehr Geschosse bedeuten daher nicht automatisch für jedes Geschoss eine zusätzliche Explosion.",
	"Heilung, Schild & Ausweichen": "Speichel regeneriert Leben. Heilungsitems können weitere Heilungen oder Vorteile durch Überheilung erzeugen. Lebensraub heilt durch wirksame Waffentreffer mit einer gemeinsamen Abklingzeit und fester Obergrenze. Schaden über Zeit und Folgeeffekte lösen keinen Lebensraub aus. Härte reduziert erlittenen Schaden.\n\nSchildladungen fangen Treffer ab. Zahnflutsch gibt eine Ausweichchance bis maximal 60 %; ein ausgewichener Treffer verbraucht keine Schildladung. Hoher Schmelz ersetzt keine Bewegung: Telegraphe und gefährliche Geschosse bleiben wichtig.",
	"Wurzeln & Fusionieren": "Die Anzahl deiner Wurzeln bestimmt, wie viele Waffen du ausrüsten kannst. Den aktuellen Vorrat siehst du unter Stats und im Shop. Jede Waffe belegt eine oder zwei. Zwei gleiche Waffen derselben Stufe lassen sich bis Mk IV fusionieren; die neue Waffe übernimmt die investierten Münzen. Fusionen behalten bei Schaden, Angriffspause, Reichweite und Crit jeweils den besseren Wert beider Waffen. Bei mehreren passenden Exemplaren wird das Ergebnis mit der höchsten erwarteten Grund-DPS gewählt, bei Gleichstand mit der größten Reichweite. Verzauberungen bleiben erhalten. Die Details zeigen das Ergebnis vorab; auch der direkte Kauf nutzt diese Regel bei vollen Wurzeln. Ein grüner Pfeil auf der ausgerüsteten Waffe zeigt, dass du sie im Shop fusionieren oder weiterentwickeln kannst.\n\nManche Mk-IV-Waffen können mit einem passenden Build zu einer Spezialwaffe weiterentwickeln. Mk V und höhere Stufen gibt es ausschließlich als seltene Kapselfunde. Du kannst bis zu vier Plätze für Verzauberungen öffnen und Reichweite oder Angriffstempo verbessern. Das Spiel verrät das Rezept erst, wenn alle Voraussetzungen erfüllt sind. Nach deiner ersten erfolgreichen Fusion erklärt die Dentipedia diese Spezialwaffe und zeigt die Zutaten. Items bleiben erhalten. Mehrere Spezialwaffen pro Run sind möglich.",
	"Shop & Münzen": "Der Preisbutton kauft ein Angebot; die Karte öffnet Details. Fehlen Münzen oder Wurzelplätze oder ist ein Stapellimit erreicht, bleibt der Kauf gesperrt.\n\nDer Pin merkt ein Angebot kostenlos und bindet seinen Preis über Rerolls und Wellen. Neuwürfeln kostet Münzen. Verkauf erstattet einen Teil der investierten Münzen. Die nächsten Angebote können zu deinem Build passen, garantieren aber keine bestimmte Kombination.",
	"Seltenheiten & Stapeln": "Rahmen und Hintergrund zeigen die Seltenheit. Items einer Familie teilen sich ihr Familienlimit, auch über verschiedene Seltenheiten. Seltenere Itemvarianten ersetzen deine bisherigen Exemplare nicht. Die konkrete Grenze steht im Itemeintrag.\n\nNormale Waffenstufen reichen von I bis IV; Mk V und höhere Stufen kommen ausschließlich aus Upgrade-Kapseln. Waffen-Evolutionen verändern die Waffenform unabhängig von der Mk-Stufe. Zahnglück verbessert Beute- und Seltenheitschancen innerhalb fester Grenzen. Mythische Items sind einmalig pro Run.",
	"Wellen & Belohnungen": "Kämpfe laufen ohne Level-up-Unterbrechung. XP merkt verdiente Level vor; eingesammelte Upgrade-Kapseln werden ebenfalls vorgemerkt.\n\nAm Wellenende wird erst die übrige Beute eingesammelt. Danach folgen Level-up-Auswahl, Upgrade-Kapseln behalten oder zerlegen und gegebenenfalls Bossrelikte. Erst dann öffnet die Zahnklinik. Nach dem Sieg ist eine endlose Fortsetzung möglich.",
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
			for item in ItemCatalog.ALL:
				result.append({"title": item.display_name, "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index), "body": item.effect_text() + "\n\n" + item.limit_text()})
		2:
			for relic in RelicCatalog.CATALOG:
				result.append({"title": relic.display_name, "icon": DentiUIIcons.relic(relic.icon_index), "body": DentiAttributes.resolve_text(relic.description)})
		3:
			for type in DentiAttributes.ACTIVE:
				result.append({"title": DentiAttributes.name_for(type), "icon": DentiUIIcons.stat(DentiAttributes.ICONS[type]), "body": DentiAttributes.meaning_for(type)})
		4:
			for title in TOPICS:
				result.append({"title": title, "body": enchantment_overview() if title == "Verzauberungen" else TOPICS[title]})
		5:
			result.append({"title": "Verzauberungen", "body": enchantment_overview()})
			for data in WeaponAffixes.ALL:
				result.append(_enchantment(data))
	return result

static func enchantment_overview() -> String:
	var names: PackedStringArray = []
	for data in WeaponAffixes.ALL:
		names.append(data.display_name)
	return ENCHANTMENT_OVERVIEW + "\n\nAlle Verzauberungen: " + ", ".join(names) + "."

static func _enchantment(data: WeaponAffixData) -> Dictionary:
	var body := AffixPresentation.effect_description(data.id)
	if data.dot_duration > 0:
		body += "\n\nJeder Treffer verursacht zusätzlichen Schaden über %.0f Sekunden. Weitere Treffer addieren ihren eigenen Schaden, ohne den bereits laufenden Schaden erneut zu multiplizieren." % data.dot_duration
	if data.slow_fraction > 0:
		body += "\n\nVerlangsamt normale Gegner um %.0f %% für %.1f Sekunden. Gegen Eliten und Bosse ist die Verlangsamung schwächer. Angekündigte Anstürme werden nicht verlangsamt." % [data.slow_fraction * 100, data.slow_duration]
	var mechanics := AffixPresentation.mechanics_text(data.id).replace("eines Trefferbudgets", "des Feuerschadens eines Treffers")
	if not mechanics.is_empty():
		body += "\n\n" + mechanics
	if data.stat_key != &"":
		body += "\n\nGilt nur für die gewählte Waffe und belegt einen ihrer Verzauberungsplätze. Andere ausgerüstete Waffen behalten ihre bisherigen Werte."
	body += "\n\nPasst zu deinem Build:\n" + str(ENCHANTMENT_SYNERGIES.get(data.id, ""))
	body += "\n\nDie konkreten Werte hängen von Ausbau, Waffe und Build ab. Kapselkarten und Waffendetails zeigen die Werte für deine Waffe."
	return {"title": data.display_name, "enchantment_id": str(data.id), "icon": DentiUIIcons.item(data.icon_index), "body": body}

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
		for item in ItemCatalog.ALL:
			if item.family_id == family:
				var family_name: String = {&"chain": "Ketten", &"bleed": "Blutung", &"damage": "Bisskraft", &"return": "Rückflug"}.get(family, str(family))
				result.append({"title": family_name + "-Familie\nJede Seltenheit", "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)})
				break
	for id in recipe.items:
		var item := ItemCatalog.by_id(id)
		result.append({"title": item.display_name, "icon": item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)})
	return result
