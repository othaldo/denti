# Umsetzung: Klassenregeln und unterschiedliche Synergien

Arbeitsplan vom **05.11.2026**, auf Basis des aktuellen Checkouts.
**P1 ist umgesetzt:** [Klassenfundament und Prüfungen](CLASS_FOUNDATION.md).
**P2 ist spielbar implementiert:** [Giftpaket, Messungen und offene Balancepunkte](POISON_PACKAGE.md).
**P3 ist spielbar implementiert:** [Assassine und gemeinsame Levelpunkte](ASSASSIN_AND_TALENTS.md).
Menschliche Spielstilabnahme und vollständige Klassenbalance bleiben offen. Dieser Plan bündelt die bisherigen Entwürfe; bei abweichenden
Reihenfolgen oder Beispielwerten ist er die aktuelle Arbeitsgrundlage.

## Ziel und Umfang

Zwei zusammenhängende, getrennt nutzbare Systeme:

1. **Klassenprofile** legen Ausgangswerte, Wurzeln, Attributregeln, Waffenfreigaben
   und eine erkennbare besondere Spielweise fest.
2. **Synergiefamilien** bieten passende Mechaniken, Items und Relikte. Sie bleiben
   grundsätzlich auch für Good Old Molar und andere geeignete Klassen spielbar.

Der Skilltree vertieft eine Klasse im Run. Er ersetzt weder ein funktionierendes
Klassenprofil noch fehlende Unterstützung für Feuer, Eis und Gift.

Feststehende Leitplanken aus dem Nutzerfeedback:

- **Good Old Molar** bleibt der klassische, vollwertige Basis-Denti.
- Klassen dürfen Wurzelanzahl, Startattribute, Attributgrenzen und Waffenwahl
  unterscheiden. Nicht jede Klasse muss in jedem Bereich abweichen.
- Spielstile müssen andere Entscheidungen über Bewegung, Abstand, Ziele oder
  Angriffsfenster belohnen. Andere Schadensfarben reichen nicht.
- Blutung und vorhandene befriedigende Builds bleiben erhalten. Schwächere
  Synergiefamilien werden gezielt erweitert.
- Aktiver Kampf bleibt ununterbrochen. Alle Entscheidungen folgen dem Loot-Sweep.
- Keine verpflichtende dauerhafte Statsteigerung zum Freischalten einer brauchbaren
  Klasse. Klassen und Talentvarianten sind horizontale Erweiterungen.

Vorläufig: erste Auswahl aus Good Old Molar, Assassine, Hüter und Spültechniker.
Die Namen der Spezialklassen, konkrete Profilwerte, Baumgrößen und Ranggrenzen
sind Entwurfswerte. Sie werden pro Umsetzungsschnitt geprüft.

## Geprüfter Iststand

| Bereich | Bereits vorhanden | Konkreter nächster Bedarf |
| --- | --- | --- |
| Wurzeln | `PlayerStats.root_capacity`, Kapazitätsprüfung, variable UI und Save/Resume | Mit Klassenprofil verbinden; Waffenfreigabe zusätzlich zur Kapazität prüfen |
| Stats | Gemeinsamer `PlayerStats`, zwölf Attribute, mehrere feste Grenzen | Klassenregeln und eine konsistente Trennung von Rohwert und wirksamem Wert |
| Waffen | 18 Standardwaffen, sechs Evolutionen, individuelle Wurzelkosten | Verlässliche Rollen-/Eignungstags; Skalierungsstat ist keine Waffenfreigabe |
| Blutung | Native Schnittwaffen, Affix, Itemfamilie, Blutungsuhr, Skalpellwachs, Übertragung und Blutmond-Zahn | Vergleichsbuild und Regression, kein Neubau |
| Wasser / Elektro | Nass, Slow, Leitlack, Pfützen, Ketten, Gezeiten-Siegel und passende Evolution | Unterschiede zwischen Flächenvorbereitung und Kettenführung gezielt vertiefen |
| Feuer | DoT und begrenzte Glutübertragung beim Tod | Eigene mechanische Itemverbindungen und ein passendes Relikt |
| Eis | Slow, kritbasierte Eissplitter | Kontrolle und vorbereiteter schwerer Treffer als zusätzliche Spielweise, Items und Relikt |
| Gift | Zeitlich verteilte Budgets und begrenzter Wiederholungsaufbau | Alternative Anwendung über Depots/Zielwechsel, passende Items und Relikt |
| Licht / Krit | Krititems, Strahlen, Sonnenmal, native Lichtwaffen | Eigenständigen Bestand erhalten; Weihe ist nicht mehr neu als Element wählbar |
| Reaktionen | `ElementReactions` und drei Reaktionsressourcen sind inzwischen eingebunden | Wirkung unterscheiden; derzeit verwenden alle drei denselben Umgebungsschadensablauf |
| Shop | Gewichtung anhand vorhandener Build-Tags, Waffen-/Itemangebote | Eignung und Erwerbbarkeit trennen; präzisere Element-Tags und Klassenpräferenzen |
| Relikte | Fünf Ressourcen, zufällige Auswahl von bis zu drei unbesessenen Relikten | Relevanz und Zugänglichkeit vor Vergrößern des Pools berücksichtigen |
| Belohnungen / Saves | Gemeinsame Queue, ausstehende Level, Waffenpunkte und Run-Snapshot | Klassen-/Talentversion und neue Effektzustände sauber integrieren |

Wasser/Elektro und Licht besitzen also bereits Unterstützung. Die größte
Inhaltslücke liegt bei Feuer, Eis und Gift. Der zuletzt gelesene Code enthält
bereits die früher angefangenen Reaktionen; ältere Forschungsnotizen über einen
unvollständigen Arbeitsstand sind historisch zu lesen.

Wichtige Einstiegspunkte:
[Stats](../scripts/player/player_stats.gd),
[Loadout](../scripts/weapons/weapon_loadout.gd),
[Itemeffekte](../scripts/systems/item_inventory.gd),
[Elementeffekte](../scripts/weapons/weapon_enchantment_effects.gd),
[Reaktionen](../scripts/weapons/element_reactions.gd),
[Shop](../scripts/systems/shop_controller.gd),
[Reliktauswahl](../scripts/systems/relic_catalog.gd),
[Belohnungsqueue](../scripts/systems/post_wave_rewards.gd),
[Snapshot](../scripts/systems/run_snapshot.gd).

## Klassenprofil: ein gemeinsamer Datenvertrag

Vorgeschlagene Resources, keine bereits implementierten Typen:

- `ClassData`: stabile ID und Version, Darstellung, Startwerte/-abweichungen,
  Wurzelkapazität, Waffenregeln, Statregeln, Dashregeln, Kernfähigkeit,
  Talentbaum und bevorzugte Build-Tags.
- `ClassStatRuleData`: Attributschlüssel und Einheit, Startbeitrag, Faktor für
  Zugewinne/Nachteile, wirksames Minimum/Maximum sowie der Geltungsbereich.
- `TalentNodeData`: ID, Voraussetzungen, Ränge, Kosten, Wirkung und gegebenenfalls
  exklusive Abschlussgruppe.

Ein Profil muss nicht alle Felder verändern. Fehlende Regeln übernehmen das
normale Denti-Verhalten. Good Old Molar ist das Referenzprofil mit sechs Wurzeln,
freiem regulärem Waffenpool und den bisherigen Grundregeln.

### Attributregeln zuerst korrekt definieren

Startwert, Zuwachs und Grenze sind verschiedene Dinge. Beispiele:

- Ein Assassine kann mehr Dashvorrat besitzen; schnelleres Nachladen ist eine
  eigene Regel und wird nicht aus der Kapazität abgeleitet.
- Ein Hüter kann aus wirksamer Härte einen zusätzlichen Angriffsnutzen ziehen.
  Das ist eine gezielte Umrechnung, kein globaler Multiplikator für alle Procs.
- Eine Klasse kann ein niedrigeres wirksames Maximum für ein Attribut besitzen,
  ohne bereits gekaufte Rohbeiträge zu löschen.

Der heutige Code begrenzt einige Werte bereits beim Erwerb oder Laden, andere
erst bei der Nutzung. Daher nicht einfach zusätzliche `clamp`-Aufrufe verteilen.
Der erste Schnitt muss für alle betroffenen Quellen dieselbe Semantik herstellen:

1. Rohbeiträge von Grundlage, Klasse, verdienten Verbesserungen, Items, Talenten
   und temporären Effekten erfassen. Eine Quelle wird genau einmal angewandt.
2. Definierte Zugewinn-/Nachteilfaktoren an der Quelle anwenden, nicht bei jedem
   Wiederberechnen erneut. Negative Itembeiträge bleiben echte Nachteile.
3. Wirksame Quellattribute bestimmen; gerichtete Statumrechnungen daraus ableiten.
   Zirkuläre Umrechnungen werden als ungültige Daten abgewiesen.
4. Wirksame Zielwerte zentral bestimmen. Dieselben Werte lesen Kampf, Karten,
   Upgradevorschau, Shop und Telemetrie.

Technische Schutzgrenzen für HP, Intervalle und endliche Werte bleiben vorhanden.
Spielerische Klassenlimits haben einen expliziten Geltungsbereich: Ein Maximum
für den Glanz-Stat ist nicht automatisch ein Gesamtlimit einschließlich
Waffenkrit und garantierter kritischer Angriffe. Wenn ein Profil ein Gesamtlimit
verspricht, muss es auch am endgültigen Treffer berücksichtigt werden. Good Old
Molar behält die heutigen Unterschiede zwischen Grundwert und Waffen-Sonderregel.

Ein bereits erreichtes Limit unterdrückt reine unbrauchbare Attributangebote.
Gemischte Items dürfen weiter nützliche andere Wirkungen besitzen; Vorschauen
zeigen den tatsächlich wirksamen Zugewinn. Kein automatisches Umwandeln des
überschüssigen Werts in Geld oder andere Stats.

HP, aktuelle Wurzelkraft und Schilde sind Ressourcen, keine neu zu berechnenden
Grundwerte. Vorschau, Umskillen und Laden erzeugen keine kostenlose Heilung oder
neue Dashladung. Frühere gespeicherte Gesamtwerte werden nicht zusätzlich nochmals
aus ihren alten Items aufgebaut.

### Wurzeln und Waffen gehören in dieselbe Eignungsprüfung

`WeaponEligibility` als vorgeschlagene gemeinsame Schnittstelle trennt:

- **erlaubt:** passt die Waffenrolle zur Klasse?
- **erwerbbar:** reichen Wurzeln oder ist ein zulässiger Fusionskauf möglich?

Startauswahl, Shop einschließlich Fallback-Angeboten, direkter Kauf, Fusion,
Evolution und Wiederaufnahme verwenden dieselbe Regel. Der aktuelle Shop darf
im Fallback nur die Kapazität umgehen, um ein Angebot für später zu zeigen;
ein Klassenverbot darf dadurch nicht umgangen werden.

Für den Assassinen genügt `damage_stat == "melee"` nicht. Lange Fadenwaffen und
kurze Kontaktwaffen werden anhand ihrer tatsächlichen Rolle eingeordnet. Alle
18 Waffen und sechs Evolutionen erhalten vor Freigabe eine überprüfte Zuordnung.
Jede Klasse braucht mindestens zwei sinnvolle Starts; ein ungültiges Profil
startet keinen Run ohne brauchbare Waffe.

Weniger Wurzeln beeinflussen auch Käufe, Fusion, Verzauberungskosten,
Angriffsquellen und Lebensraub. Ein kleineres Limit wird deshalb zusammen mit
einer vollständigen verdienten Progression geprüft, nicht durch einen pauschalen
Schadensbonus als ausgeglichen erklärt. Zuerst keine Talente, die beim Umskillen
die Kapazität unter die vorhandene Ausrüstung senken.

## Synergiefamilien als vollständige kleine Pakete

Für jede schwächer unterstützte Familie zunächst:

- ein erkennbarer Kampfablauf mit Stärke und Schwäche;
- **zwei unterschiedliche Mechanik-Items** mit mehreren sinnvollen Anschlüssen;
- **ein passendes Relikt**, das einen Höhepunkt liefert;
- ein funktionierender Einstieg ohne dieses Relikt;
- Zugriff für Good Old Molar und geeignete Spezialklassen;
- eindeutige Effektgrenzen, Save/Resume und Messwerte.

Feuer, Eis und Gift ergeben damit zunächst sechs neue Items und drei Relikte,
**nacheinander in einzelnen Paketen**. Vor einer Neuanlage wird geprüft, ob ein
vorhandenes Item die Aufgabe schon erfüllt. Wasser/Elektro werden danach anhand
der verbleibenden konkreten Lücken ergänzt; kein identischer Neubau aller Familien.

### Vorgeschlagene Wirkung der ersten Pakete

Alle neuen Namen und Mechaniken in dieser Tabelle sind Arbeitsvorschläge.

| Familie | Gewünschtes Spiel | Zwei Itemrollen | Reliktrolle | Grenze |
| --- | --- | --- | --- | --- |
| Gift | Ziele mit einem Depot belegen, Abstand gewinnen und rechtzeitig wechseln; vorhandener Fokusaufbau bleibt eine Alternative | **Depotfüllung:** begrenztes Depot auf neuem Ziel. **Nervensonde:** kontrollierte Verlangsamung durch geeignete Giftanwendung | **Giftzahn:** verstärkt einen begrenzten Wechsel zwischen unterschiedlichen vergifteten Zielen | Verzögerte Kills, wenige Depots, kein erneutes Gratisdepot durch dieselben Giftticks |
| Eis | Verfolger kontrollieren und einen vorbereiteten Gegner mit einer schweren Waffe öffnen | **Kälteschiene:** begrenzte Sprödigkeit. **Bruchkeil:** ein geeigneter echter Waffentreffer verbraucht sie für einen gerichteten Durchbruch | **Frostkrone:** kurzes Folgefenster nach einem erfolgreichen Bruch | Vorbereitung wird verbraucht; keine dauerhafte Bossstarre und keine zweite universelle Krit-Explosion |
| Feuer | Gegner in einem vorbereiteten heißen Bereich halten und beim Verlassen der Stellung Ertrag aufgeben | **Brennpaste:** wenige zeitlich begrenzte Glutflecken. **Ofenspange:** längeres Verweilen im heißen Bereich verstärkt begrenzt dessen Wirkung | **Ofenherz:** entwickelt eine gehaltene Feuerstellung weiter | Aufbau und Ortsbindung; mobile Ziele und Ortswechsel verlieren Ertrag |
| Wasser / Elektro | Wenige nasse Flächen oder Zielgruppen günstig verbinden | Vorhandene Pfützen-, Leitlack- und Kettenitems zuerst verwenden; bei Bedarf eine echte Leitstrecke ergänzen | Gezeiten-Siegel erhalten; zusätzliche Elektrooption nur bei nachgewiesener Lücke | Wenige Verbindungen, begrenzte Entladungen, elektrische Builds funktionieren auch ohne zwingendes Wasserpflichtteil |

Gift profitiert von Zielwechseln, Eis von Vorbereitung und einem anderen Treffer,
Feuer von Aufenthaltszeit an einem Ort, Elektro von Geometrie und Verbindungen.
Blutung behält ihre vorhandenen Schnitt-, Stapel- und Todesverbreitungsmechaniken.
Die bisherigen Basis-Effekte werden nicht stillschweigend ersetzt.

Die Depot-Zielregel muss über nahe erreichbare Ziele funktionieren. Der Spieler
beeinflusst sie durch seinen Laufweg; keine globale optimale Zielsuche über die
Arena. Schwere Treffer erhalten eine ausdrückliche Waffenrolle, statt anhand
einer durch Stats beliebig überschreitbaren Schadenszahl erraten zu werden.

### Reaktionen erst nach den Familien gezielt weiterentwickeln

Die drei vorhandenen Reaktionen werden nicht zu einer vollständigen Matrix aller
Elementpaare erweitert. Pro überprüfter Reaktion zuerst festlegen, welche
Entscheidung sie ergänzt:

- Eis/Nass kann begrenzte Kontrolle übertragen.
- Gift/Feuer kann einen Teil bestehenden Giftbudgets in frühere Wirkung umwandeln.
  Dieser Anteil wird wirklich aus dem Restbudget entfernt.
- Feuer/Nass benötigt einen eigenen sinnvollen Nutzen und eindeutige Kosten,
  bevor zusätzliche Stärke oder weitere Varianten ergänzt werden.

Bestehende Werte werden nicht ohne Vergleich pauschal entfernt. Der Nachweis
„zusätzlicher Umgebungsschaden funktioniert“ genügt aber nicht als Abnahme für
unterschiedliche Spielstile.

## Zugang, Belohnungen und Darstellung sind Teil des Pakets

- Präzise Tags für Gift, Feuer, Eis, Wasser, Elektro, Kontrolle, Kontakt,
  Vorbereitung und Flächen ergänzen die heutigen groben Tags. Beispielsweise
  darf Giftunterstützung nicht ausschließlich an `ranged` hängen.
- Klassenpräferenzen ergänzen Besitz- und Waffentags. Sie schränken den Shop
  nicht auf ausschließlich optimale Angebote ein.
- Das frühe mechanische Kernitem muss in realen Runs erreichbar sein; kein
  legendäres Pflichtteil für die Klassenfähigkeit. Seltenheit und Preis werden
  anhand echter Shopverläufe geprüft.
- Vor Erweiterung des Reliktpools die Auswahl anpassen: Wenn sinnvolle
  Kandidaten existieren, enthält eine Bossauswahl mindestens eine zum aktuellen
  Build passende Option und weiterhin freie Alternativen. Kein garantiertes
  bestimmtes Endbuild; gespeicherte Auswahl verhindert Neuwürfeln durch Fortsetzen.
- Gegen isolierte Bosse funktionieren alle Pakete ohne erforderliche Killserien.
  Kontrollwirkungen unterbrechen keine verbindlichen Bossphasen.
- Neue Effekte haben Herkunfts-IDs, begrenzte Ziele, Zustände und Intervalle.
  DoTs und Folgeeffekte lösen keine rekursiven Waffentreffer, Heilungen oder
  kostenlosen neuen Ressourcen aus.
- Aktive Flächen und Verbindungen sind begrenzt; räumliche Abfragen nutzen die
  vorhandenen Nachbarschaftsfunktionen. Keine vollständige Gegnerpaarprüfung pro
  Frame. Warnungen und gegnerische Projektile behalten visuell Vorrang.
- Neue Itemgrafiken werden als kleine gemalte Atlascharge mit den vorhandenen
  Atlanten als Referenz erstellt und bei Kartengröße geprüft. Keine flachen
  Ersatz-SVGs. Klassen-, Relikt- und Itemkunst bekommt eine eigene visuelle Abnahme.

## Reihenfolge mit überprüfbaren Ergebnissen

### P0 — Vergleichsbasis und Datenregeln

**Ergebnis:** Referenzzustände für Good Old Molar, Roh-/Effektivwert-Semantik,
Waffenrollen und eine Liste bestehender Synergien. Die Code-/Bestandsprüfung ist
für diesen Plan erfolgt; neue Kampfvergleichsläufe wurden noch nicht ausgeführt.

Vor dem ersten Gameplaypatch feste Seeds und gespeicherte Profile verwenden:
frühe Wellen bis zum ersten Boss, eine späte Hordenwelle und ein isolierter Boss.
Blutung, Wasser/Elektro und ein einfacher neutraler Build dienen als Kontrollen.

**Abnahme:** heutige Werte und Effekte sind reproduzierbar; verbleibende
Unterschiede der automatischen Piloten werden kenntlich gemacht.

### P1 — Klassenfundament und Good Old Molar

**Ergebnis:** `ClassData`, zentrale Statregeln, Waffenrollen/Eignung,
Klassenvorschau und Klassen-/Regelversion im Save. Good Old Molar bleibt spielbar
und verhält sich zunächst wie der heutige Denti. Noch kein großer Baumumbau.

Diagnoseprofile mit anderen Wurzeln und Grenzen prüfen das Modell, sind aber
keine zusätzlichen sichtbaren Klassen. Startregeln werden nur beim neuen Run
angewandt; Laden gibt sie nicht ein zweites Mal.

**Abnahme:** neutrale Regression; Min/Max über Kauf, Nachteile, temporäre Effekte
und Fortsetzen; 4/6/8 Wurzeln als Prüfprofile; erlaubte und gesperrte Starts,
Fallback-Shop, volle Wurzeln mit Fusionskauf sowie Evolutionsresultate.

### P2 — Vollständiges Giftpaket für den vorhandenen Denti

**Ergebnis:** Depotmechanik, zwei passende Items, Giftrelikt, Tags,
Reliktauswahl, Telemetrie und gemalte Icons. Der Giftläufer funktioniert zunächst
mit Good Old Molar; der vorhandene konzentrierte Giftaufbau bleibt erhalten.

**Abnahme:** tatsächlicher Nutzen von Zielwechseln; zwei passende Waffen;
normaler Wellenstart ohne Relikt; Bossfähigkeit; begrenzte Depots und keine
Tick-Rekursion; Wiederaufnahme aktiver Effekte; kein Verlust der Blut-/Wasserkontrollen.

### P3 — Assassine und erster gemeinsamer Skilltree

**Ergebnis:** sichtbare Klassenauswahl aus Good Old Molar und Assassine,
Nahkampfregel, Dash-/Antrittskern und gemeinsame Talentgrundlage. Zunächst zwei
ausgearbeitete, gegensätzliche Wege: Gift-Zielwechsel und längeres Nachsetzen.
Der dritte Schattenlauf-Ast folgt nach Prüfung dieser beiden.

Ein gemeinsames Levelpunktebudget für Attribut- oder Talentknoten ersetzt in
neuen Klassen-Runs die bisherigen Statkarten; keine unveränderte doppelte
Belohnung. Mehrere Punkte werden nach dem Loot-Sweep gemeinsam verteilt.
Waffenpunkte aus Kapseln bleiben getrennt. Good Old Molar bekommt seine flexible
Entwicklung im selben System. Konkrete Baumgrenzen folgen aus P0/P1-Messungen.

**Abnahme:** zwei unterschiedliche Assassinenwege in echten verdienten Runs;
keine automatische Gift-Pflicht; Spielstil vor dem ersten seltenen Fund erkennbar;
keine Endlos-Dash-/Heilungsschleife; gemeinsame Queue, UI und Save/Resume funktionieren.

### P4 — Eis und Feuer jeweils als eigener Inhaltsschnitt

**Ergebnis je Paket:** zwei Mechanik-Items, ein Relikt, genaue Herkunfts- und
Budgetregeln, Tags, Grafik, Details und kontrollierte Vergleichsdaten. Erst Eis
für den Kontrast zum Giftläufer, danach Feuer mit Stellung und Aufenthaltszeit.

**Abnahme:** Vorbereitung/Verbrauch beim Eis und Stellung/Ortswechsel beim Feuer
sind im Spiel erkennbar. Beide funktionieren mit Good Old Molar und mehreren
Waffen. Die passenden Spielweisen werden mit falschem dauerhaften Nachsetzen
oder einfachem Kreisen verglichen. Bosskontrolle, Projektillesbarkeit und
Performance unter hoher Dichte bleiben brauchbar.

### P5 — Hüter und Spültechniker auf denselben Bausteinen

**Ergebnis in zwei getrennten Schnitten:** Hüter mit Schutz/Gegenangriff und
Spültechniker mit vorbereiteten Flächen. Gemeinsame Klassen-, Talent-, Save- und
Statregeln wiederverwenden. Wasser/Elektro nur an konkreten Lücken ergänzen.

Hüter wird nicht zur Pflicht-Eisklasse und Assassine nicht zur exklusiven
Giftklasse. Elemente und Items bleiben kombinierbar. Ein Klassentausch im
laufenden Run wird zunächst nicht eingeführt.

**Abnahme:** erste vier Profile sind als Entscheidungen unterscheidbar; je
Spezialklasse mindestens zwei brauchbare Wege und Starts. Höhere Grenzwerte,
Wurzeln und Sustain erzeugen keine universell überlegene Kombination.

### P6 — Gesamtbalance und Veröffentlichung

**Ergebnis:** vergleichbare frühe, späte und vollständige Runs; geprüfte
Touch-/Desktopansichten; aktualisierte Waffen-, Item-, Relikt- und Klassendetails.

Untersuchen: verdiente statt nur frei vergebene Ausrüstung, Kosten pro Wurzel,
Starttempo, Heilung, Gold, Boss-TTK und nutzbare Angriffszeit. Verschiedene
Klassen brauchen vergleichbare Erfolgschancen, nicht identische DPS oder gleiche
Schadensquellen. Automatische Proben sind Diagnose; menschliche Runs bewerten
Verständlichkeit und Spielfreude.

## Prüfungen pro Schnitt

Gezielte Tests für neue Regeln und ihre Integrationswege; nach bestandenem
Schnitt die erforderliche Regression laut [README](../README.md) ausführen.
Nicht alle Vergleichsmatrizen nach jeder reinen Text- oder Iconkorrektur wiederholen.

Besonders wichtig:

- Kein Wert verschwindet durch wiederholtes Begrenzen, Laden oder Neuberechnen.
- Item-/Talentboni und Profilstartwerte werden nicht doppelt vergeben.
- Klassenverbote gelten auch bei Shop-Fallback, Kauf-Fusion und Evolution.
- Ein neues Paket wird durch Items/Relikt nicht unbegrenzt auf mehrere Quellen
  multipliziert. Tatsächlicher Schaden, Heilung und verlorene Budgets sind messbar.
- XP, Kapseln und Drops pausieren keinen Kampf; Loot-Sweep vor Punkten, komplette
  Belohnungen vor Shop. Save/Resume bewahrt offene Punkte, Auswahlen und Effekte.
- Alte Saves bleiben mit bisherigen Stats und ausstehenden alten Belohnungen
  spielbar. Kein nachträgliches Aufzwingen einer Klasse oder kostenloser Talente.
- Karten, Limits, Sperrgründe und Talentdetails lesen denselben wirksamen Zustand.

Zusätzliche Diagnosewerte: Depotwechsel und Kills nach Verlassen der Reichweite,
verbrauchte Sprödigkeit, Wirkung während/außerhalb heißer Flächen, kurze
Angriffsfenster, Dashschaden und Rückzüge. Sie ergänzen vorhandene DPS-, Sustain-,
Dichte-, Boss- und Wirtschaftswerte.

## Nächster konkreter Arbeitsschnitt

**P1 und die technische Umsetzung von P2/P3 sind vorhanden.** Vor der Balancefreigabe
des Giftläufers gezielt mit Depotfüllung/Nervensonde spielen: wenige Treffer,
Zielwechsel, Rückzug; anschließend isolierter Boss und späte Horden. Die erste
Fernkampf-Wechselroute des Diagnosepiloten verliert zu viel Angriffszeit.
Das ist keine bestätigte Verbesserung gegenüber Fokussieren.

Die Assassinenwege sind mit verdienten Punkten bis zum ersten Boss geprüft.
Nächste Abnahme: menschlicher Spielstilvergleich und späte Klassen-/Wurzelbalance.
Nächster Inhaltsschnitt: **P4: Eis** mit Vorbereitung und Verbrauch eines schweren
Treffers; Feuer folgt separat. Kein paralleler Neubau aller Klassen.
