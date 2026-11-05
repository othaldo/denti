# Unterschiedliche Spielstile statt ausgetauschter Elemente

Aktueller gemeinsamer [Umsetzungsplan für Klassen und Synergien](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md)
vom 05.11.2026. Er berücksichtigt inzwischen integrierte Reaktionen und bündelt
die folgenden Forschungs- und Spielstilideen zu einzelnen Arbeitsschnitten.

Recherche und Designvorschlag vom 04.11.2026. **Nicht implementiert und nicht als
Balance nachgewiesen.** Ausgangspunkt ist das Nutzerfeedback: Ein Feuer-, Eis-
oder Giftbuild soll andere Entscheidungen im Kampf erzeugen als ein Blutbuild.
Mehr Schaden in einer anderen Farbe genügt nicht.

Weiterführung auf Nutzeranregung: [Klassen und Skilltrees](CLASSES_AND_SKILL_TREES.md)
arbeiten explizite Klassenregeln und eine Spezialisierung über Levelpunkte aus.
Die Klassenwahl ersetzt dort die zuvor angenommene rein freie Ausgangsstruktur;
unterschiedliche Wege innerhalb einer Klasse bleiben ein zentrales Ziel.

## Ergebnis

Ein Build braucht einen wiedererkennbaren Ablauf: **vorbereiten → günstige
Situation herstellen → Wirkung auslösen → neu positionieren**. Die Vorbereitung
kann räumlich, zeitlich oder an eine begrenzte Ressource gebunden sein. Nicht
jeder Build braucht jede dieser Dimensionen. Mindestens zwei sollten sich aber
gegenüber anderen Builds erkennbar unterscheiden: Laufweg, gewünschter Abstand,
Angriffsfenster, Umgang mit Gegnergruppen oder defensive Entscheidung.

Element und Spielstil sollten getrennte Achsen bleiben. Eine Eisverzauberung
kann einen Fernkämpfer beim Abstandhalten unterstützen oder einen Nahkämpfer
beim Vorbereiten eines schweren Treffers. Dadurch entstehen Mischbuilds, ohne
sechs starre Elementklassen vorzugeben.

## Was sich aus anderen Spielen ableiten lässt

Die beschriebenen Mechaniken sind recherchierte Beispiele. Die jeweilige
Übertragung auf Denti ist eine eigene Designhypothese. Es geht um das Prinzip,
nicht um aktuelle Meta-Ranglisten oder unverändertes Übernehmen ihrer Zahlen.

### Brotato: verändern, welches Verhalten sich lohnt

- **Streamer:** Stillstehen erzeugt Einkommen; Bewegung gewährt Kampfboni.
  Gehaltenes Geld bringt zugleich Nachteile. Daraus entsteht ein Wechsel zwischen
  Geldverdienen und notwendiger Bewegung. **Ableitung:** Ein Bonus wird
  interessanter, wenn der Spieler seine günstige Situation immer wieder aufgeben
  muss. [Mechanik im Brotato-Wiki](https://brotato.wiki.spellsandguns.com/Streamer).
- **Bull:** Waffen sind ausgeschlossen, erlittener Schaden löst Explosionen aus.
  Defensive Werte unterstützen damit eine andere Angriffsquelle. **Ableitung:**
  Ein Build kann ändern, wofür ein vorhandener Stat benutzt wird. Absichtliches
  Schadennehmen ist für Denti allerdings kein geeigneter erster Prototyp; die
  vorhandene Sustain-Frage muss dabei mitbetrachtet werden.
  [Mechanik im Brotato-Wiki](https://brotato.wiki.spellsandguns.com/Bull).
- **Pacifist:** Lebende Gegner am Wellenende liefern Ressourcen und XP, während
  der Schaden stark eingeschränkt ist. **Ableitung:** Geänderte Belohnungen
  verändern das Ziel im Kampf. Eine direkte Übernahme würde Dentis Boss- und
  Fortschrittsregeln berühren und ist deshalb eine spätere Challenge-Idee.
  [Mechanik im Brotato-Wiki](https://brotato.wiki.spellsandguns.com/Pacifist).

### Deep Rock Galactic: Survivor: Angriffsform und Positionierung

Die Entwickler beschreiben, wie rotierende Cryo-Strahlen das Positionierungsspiel
unterstützen. Unstable Overclocks können Waffen grundlegend verändern, etwa
Zhukov-Schüsse zu einem umlaufenden Angriff. **Ableitung:** Angriffswinkel,
Trefferbahn und zeitliche Abdeckung können einen größeren Unterschied erzeugen
als ein weiterer Schadensbonus.
[Entwicklerbeitrag zu Waffen und Overclocks](https://steamcommunity.com/games/2321470/announcements/detail/3971679674351840364).

### Nova Drift: alternative Angriffsquellen und echte Kosten

Die offizielle Beschreibung nennt unter anderem eine schädigende Schildaura,
Teleportation mit Explosionen beim Schildbruch, Schwarmkonstrukte und einen mit
seinem Körper angreifenden Leviathan. **Ableitung:** Bewegung, Schutz oder
Beschwörungen können zum Zentrum eines Builds werden. Das sind andere
Handlungsweisen als ein anders eingefärbtes Projektil.
[Offizielle Spielbeschreibung](https://store.steampowered.com/app/858210/Nova_Drift/).

Die Entwickler dokumentieren bei Siege Weaponry zudem die Verbindung zwischen
anhaltendem Feuern, zunehmender Angriffswirkung und Selbstschaden. **Ableitung:**
Eine starke Phase braucht eine spürbare Grenze. Für Dentis automatische Angriffe
müsste diese Grenze über Bewegung oder einen sichtbaren Ladezustand steuerbar
sein; eine manuelle Feuertaste wird dafür nicht vorausgesetzt.
[Entwickler-Patchnotes](https://blog.novadrift.io/patch-notes/).

### Noita: gemeinsame Regeln statt einzelner Kombinationsrezepte

Noita verbindet selbst kombinierte Zauber mit einer Welt, die sich verbrennen,
schmelzen oder einfrieren lässt. **Ableitung:** Wiederverwendbare Zustände und
Interaktionen bieten mehr Kombinationen als eine Sammlung voneinander
unabhängiger Bonusauslöser. Denti braucht dafür keine Materialsimulation.
Begrenzte Flächen, Zustände und Ladungen reichen als Ansatz.
[Offizielle Spielbeschreibung](https://store.steampowered.com/app/881100/Noita/).

## Dentis tatsächlicher Ausgangspunkt

Der aktuelle Bestand ist bereits umfangreich: 18 Standardwaffen, sechs
Evolutionen, 94 Items, fünf Relikte, Dash und gezielte Waffenverzauberung.
Ein zusätzliches großes Fortschrittsmenü wäre daher ein schlechter erster Schritt.

Wichtige vorhandene Bausteine:

- Fokusangriffe bei Fräse und Wurzelkanalbrecher; gespannte Fäden beim
  Schicksalsfaden; leitende Pfützen bei der Gewitterdusche; Orbit und Rückflug beim
  Heiligenschein. [Evolutionen](WEAPON_EVOLUTIONS.md), [Waffen](waffen.md).
- Bewegungsboni, Killserien, Blutungsübertragung, Schildreaktionen,
  Überheilung und Wasser-/Kettenitems existieren bereits. Sie müssen gezielt
  verbunden werden, statt dieselben Effekte nochmals einzuführen.
  [Items](items.md), [Relikte](RELICS.md).
- Pro Waffenexemplar ist ein Element auswählbar. Mischungen entstehen zwischen
  Waffen und durch native Waffeneffekte. Weihe ist im aktuellen System nicht mehr
  neu auswählbar; Licht-/Kritbuilds laufen über Waffen, Items und Relikte.
  [Aktuelle Verzauberungsregeln](WEAPON_UPGRADES.md).
- Waffen wählen weitgehend das nächste Ziel an ihrem Haltepunkt. Eine Regel wie
  „triff bewusst einen anderen Gegner“ braucht deshalb passende automatische
  Zielregeln und eine räumliche Einflussmöglichkeit. Sonst entscheidet der
  Algorithmus über die Synergie, ohne dass der Spieler sie steuern kann.
- Dash hat keine zusätzlichen Schutzframes und verstärkt Körperkontaktschaden.
  Ein Dashbuild muss sichere Wege belohnen. „Durch die Horde dashen“ ist ohne
  ausdrückliche Änderung dieser Regeln kein geeigneter Standardablauf.
  [Dashregeln](DASH.md).

Der unvollständige Reaktionsentwurf aus dem vorherigen Thread verwendet für
Dampfstoß, Giftbrand und Frostübertragung denselben Umgebungsschadensablauf.
Das erzeugt noch keine drei Spielstile. Er sollte vor seiner Fertigstellung an
den folgenden Zielen ausgerichtet werden.

## Vorgeschlagene Systeme

### 1. Frühe Mechanik-Items als Ausgangspunkt eines Builds

Einige nicht stapelbare, früh erhältliche Shop-Items ändern jeweils **eine
Kampfregel**. Weitere Items verbessern deren Einsatzmöglichkeiten. Ein Relikt
oder eine Evolution kann den Ablauf später erweitern; der Spielstil funktioniert
schon vorher.

Das nutzt Shop, Items und vorhandene Belohnungsphasen. Es erfordert weder eine
weitere Währung noch ein neues Pflichtmenü oder eine vorab festgelegte Klasse.
Die bestehenden geheimen Evolutionen bleiben eigene späte Entdeckungen.

Beispiele für neue Mechanik-Items:

- **Kälteschiene:** Eis baut begrenzte Sprödigkeit auf. Ein passender schwerer
  Treffer verbraucht sie für einen gezielten Durchbruch.
- **Depotfüllung:** Giftwaffen bevorzugen nahe Ziele ohne eigenes Giftdepot;
  ein einzelnes Depot arbeitet nach dem Weglaufen weiter.
- **Leitbrücke:** Vorhandene Spülpfützen können sich kurzzeitig zu einer
  leitenden Strecke verbinden, durch die Gegner gelockt werden.

Dies sind Vorschläge, keine vorhandenen Items. Der Zugang muss mitgeprüft werden:
Mit 94 bestehenden Items kann ein weiteres seltenes Pflichtteil einen Build
praktisch unsichtbar machen. Ein kleiner früher Angebotsschwerpunkt ist eher zu
prüfen als noch mehr benötigte Einzelteile. Angebote sollen Wahlmöglichkeiten
erhalten, statt einen einmal begonnenen Build vollständig festzuschreiben.

### 2. Vorbereitung und Verbrauch von Zuständen

Eine Synergie sollte gelegentlich etwas **umwandeln**, statt nur zusätzlichen
Schaden anzuhängen. Das schafft unterschiedliche Zeitpunkte für den Ertrag.

| Vorbereitung | Auslöser | Wirkung | Entscheidung / Kosten |
| --- | --- | --- | --- |
| Giftdepot auf einem Ziel | Weitere Ziele erreichen | Depot arbeitet selbstständig weiter | Wechsel und Laufweg statt endloser Fokus |
| Giftaufbau auf einem Ziel | Kontinuierliche eigene Treffer | Stärkeres konzentriertes Gift | Nähe und Zielkontakt müssen gehalten werden |
| Giftdepot | Geeigneter Feuertreffer mit Mechanik-Item | Ein Teil des Restbudgets wird sofort wirksam | Verbraucht zukünftigen Giftschaden; kein Gratis-Doppelschaden |
| Kälte / Sprödigkeit | Schwerer physischer Treffer | Kurzer Durchbruch mit Rückstoß oder Stagger | Vorbereitung wird verbraucht, anschließend erneuter Aufbau |
| Nasse Gegner in verbundenen Pfützen | Begrenzter Elektroimpuls | Entladung entlang der Verbindung | Gute Geometrie nötig; außerhalb davon wenig Zusatznutzen |

Die beiden Giftwege sind unterschiedliche Spezialisierungen, keine automatisch
gleichzeitig gewährten Vollboni. Einfache Elementtreffer dürfen weiterhin ohne
Mechanik-Item funktionieren. Die Spezialregel braucht erkennbare Investition.

Bei der Umsetzung gilt: Umgewandeltes DoT-Budget wird wirklich abgezogen.
Folgeeffekte starten keine rekursiven Trefferketten. Zielgrenzen, Intervalle,
Bossverteidigung und Save/Resume bleiben verbindlich. Ein Ereignis darf sein
eigenes Ergebnis nicht erneut als frische Vorbereitung verwenden.

### 3. Räumliche Beziehungen als wiederverwendbares Werkzeug

Pfützen, Fäden und Rückflugbahnen existieren bereits. Ihr gemeinsamer Nutzen
sollte sein, **durch Bewegung eine bessere Treffergeometrie herzustellen**.

- **Leitstrecken:** maximal wenige aktive Pfützen und begrenzte Verbindungen.
  Der Spieler lockt Gegner durch eine vorbereitete Strecke, statt überall gleich
  stark zu sein. Keine vollständige leitende Bodenabdeckung.
- **Rückflugfenster:** Ein Mechanik-Item verstärkt den Rückflug einer geeigneten
  Waffe, reduziert im Gegenzug den Hinweg. Seitliches Versetzen nach dem Schuss
  richtet die Rückflugbahn neu aus. Die aktuelle Rückflugimplementierung muss
  dabei auf tatsächlich steuerbare Geometrie geprüft werden.
- **Kontrollkorridor:** Kälte verlangsamt eine Flanke und schafft einen Fluchtweg.
  Es entstehen keine Wände, die Denti oder Bosse einsperren.

Eine gemeinsame Flächen-/Verbindungskomponente ist nur dann sinnvoll, wenn der
erste Prototyp ihren Bedarf bestätigt. Bestehende Pfützen und Fäden bleiben der
Ausgangspunkt. Warnungen und gegnerische Geschosse haben visuell Vorrang.

### 4. Sichtbare Angriffsfenster und defensive Gegenangriffe

Ein Bonus „während Bewegung“ belohnt oft weiterhin dieselbe dauerhafte Kreisroute.
Interessanter ist ein Wechsel zwischen zwei Situationen:

- **Anlauf → kurzer Nahkampfangriff → Rückzug:** Sichere Bewegung lädt genau
  einen schweren Folgetreffer. Er löst erst am nächsten gültigen Waffenkontakt
  automatisch aus. Aufladen braucht tatsächliche Strecke im aktiven Kampf,
  nicht Wackeln auf der Stelle. Vorrat und Ertrag sind begrenzt.
- **Schutz → Block → Gegenangriffsfenster:** Der vorhandene Schildblock eröffnet
  eine kurze gerichtete Gegenattacke. Der Spieler entscheidet, ob er in Reichweite
  bleibt oder sich zurückzieht. Eine Verbesserung von Splitter-Heiligenschein
  und Schilditems ist zuerst zu prüfen; es braucht kein zweites paralleles
  Vergeltungssystem.
- **Position finden → kurze Schussphase → versetzen:** Als späterer Versuch
  lädt kurzes ruhiges Zielen einen schmalen Präzisionsangriff. Bewegung beendet
  nur den Spezialbonus, nicht normale Angriffe. Gegnerische Vorwarnungen müssen
  einen sinnvollen Zeitpunkt zum Abbrechen erkennbar machen.

Nur der jeweils erworbene Mechanismus braucht eine kleine Ladeanzeige an Waffe
oder Denti. Kein dauerhaftes HUD mit mehreren neuen Ressourcenbalken. Die ersten
beiden Abläufe passen besser zum bestehenden Bewegungs- und Schildspiel als ein
sofortiger Umbau aller automatischen Angriffe.

### 5. Zielverhalten als Teil ausgewählter Mechaniken

Keine allgemeine Zielkonfigurationsseite einführen. Stattdessen besitzt eine
passende Mechanik eine einfache automatische Zielregel:

- Depotgift bevorzugt **nahe unbelegte Ziele** und hält eine kurze Zielbindung,
  damit die Auswahl nicht pro Frame springt.
- Konzentriertes Gift und Bohrfokus halten ein **erreichbares Ziel**, statt wegen
  kleiner Entfernungsänderungen ständig den Aufbau zu verlieren.
- Ein schwerer Frostbrecher bevorzugt ein **erreichbares vorbereitetes Ziel**.

„Nahe“ und „erreichbar“ bleiben wesentlich: Der Spieler beeinflusst die Auswahl
durch seinen Laufweg. Kein globales automatisches Finden des optimalen Gegners
über die ganze Arena. Auswahlgrund und Vorbereitung müssen kurz sichtbar sein.

## Konkrete Spielstile, die daraus entstehen könnten

| Spielstil | Ablauf im Kampf | Passender vorhandener Anschluss | Echte Schwäche |
| --- | --- | --- | --- |
| **Gluttreiber** | Horde verdichten, schwaches brennendes Ziel töten, durch die frei werdende Lücke wechseln | Feuer-Todesübertragung, Mörser / Rakete | Verstreute Gegner und isolierte robuste Ziele liefern weniger Verbreitung |
| **Giftläufer** | Eine Flanke mit Depots belegen, weiterziehen, überlebende Ziele später wieder erreichen | Giftbudgets, Fernwaffen, Bewegung | Verzögerte Kills; naher Druck bleibt zunächst bestehen |
| **Toxikologe** | Einen Elitegegner erreichen, Giftkontakt halten, dann rechtzeitig lösen | Giftaufbau, Fokuswaffen, Sustain | Zielwechsel und Kontaktunterbrechung kosten Aufbau; weniger sofortiger Flächendruck |
| **Frostbrecher** | Verfolger abkühlen, vorbereitetes Ziel mit schwerer Waffe erreichen, Durchbruch nutzen | Eis, Amalgam-Schleuder / Speer / Bohrer | Verbraucht Vorbereitung; schützt nicht dauerhaft gegen alles |
| **Wasserwerker** | Wenige Pfützen platzieren, Gegner durch die Verbindung locken, bei Gefahr die Stellung wechseln | Spülventil, Wasserflosser, Elektro, Gewitterdusche | Vorbereitung und Geometrie; Gegner außerhalb der Strecke |
| **Anlauf-Chirurg** | Sichere Strecke laufen, kurz in Waffenreichweite schneiden, wieder lösen | Kontaktwaffen, Bewegung, vorhandener Dash | Kleine sichere Angriffsfenster; Körperkontakt beim Dash bleibt gefährlich |
| **Rückflug-Geometer** | Erst schießen, dann seitlich versetzen, damit Rückflug andere Gegner oder erneut das Ziel kreuzt | Kronenwerfer, Rückflugitems, Heiligenschein | Hinweg wird schwächer; unpassende Laufwege verlieren Ertrag |
| **Vergeltungsmolar** | Schild für einen gefährlichen Moment behalten, Block nutzen, kurz offensiv werden | Schilde, Splitterkrone, Splitter-Heiligenschein | Verbrauchte Schilde und Angriffe ohne sichere Blockgelegenheit |

Diese Rollen sind keine Auswahlklassen. Beispielsweise kann Depotgift zusammen
mit einem Rückflugwerkzeug funktionieren. Ein vorbereitendes Wasserwerkzeug kann
einen Frostbrecher ergänzen. Mischungen sind erwünscht, solange nicht jede Rolle
die Vorbereitungskosten der anderen vollständig entfernt.

## Bossfähigkeit und Grenzen

- **Kein Build darf nur bei Trash funktionieren.** Feuer benötigt für einen
  isolierten Boss weiterhin ausreichenden eigenen Schaden; eine neue Regel darf
  ihn nicht ausschließlich von Todesketten abhängig machen. Mechanische Adds sind
  eine mögliche Ergänzung, kein erzwungener universeller Spawnteppich.
- **Keine dauerhafte Bosskontrolle.** Kälte kann bei Bossen begrenzte Sprödigkeit
  oder eine kleine Erleichterung erzeugen. Sie stoppt keine verbindlichen Phasen
  und lässt angekündigte Angriffe nicht unlesbar ausfallen.
- **Schild und Leben bleiben Entscheidungen.** Selbstschaden erzeugt keine
  Vergeltungsschleife; Folgeeffekte heilen nicht wieder ihre eigenen Kosten.
  Eine Blut-/Selbstschadensmechanik ist erst nach gesondertem Sustain-Test sinnvoll.
- **Spezialisierung bezahlt mit entgangenem Nutzen.** Ein veränderter Rückflug
  verliert Hinwegwirkung; eine sofortige Giftauslösung verbraucht Zukunftsschaden.
  Ein pauschaler kleiner Statnachteil allein erzeugt noch keinen Spielstil.
- **Kein Pflicht-Regenbogen.** Nicht jedes zusätzliche Element darf unabhängig
  eine volle neue Schadensquelle mitbringen. Mischungen teilen begrenzte
  Vorbereitung oder benötigen passende räumliche Bedingungen.
- **Keine Buildidentität erst durch Legendärglück.** Der Kern muss früh und mit
  wenigen Teilen spielbar sein. Seltene Funde liefern Varianten und Höhepunkte.

## Empfohlene Reihenfolge

1. **Drei kontrastierende Prototypen:** Giftläufer, Frostbrecher und
   Rückflug-Geometer. Sie prüfen unterschiedliche Zielregeln, Nah-/Fernabstand
   und Laufwege. Die vorhandene Blut-/Feuerwirkung dient als Vergleich.
   Pro Prototyp zunächst ein Mechanik-Item und höchstens zwei Ergänzungen.
2. **Gleiche Begegnungen mit verschiedenen Spielweisen prüfen:** normale
   Hordenwelle, robuste Elite und isolierter Boss. Erst mit vorhandenen
   Mechaniken und kontrollierten Ausbauständen, anschließend mit tatsächlich
   verdientem Gold, Shopangeboten und Upgradepunkten.
3. **Erst danach Raum und Ressourcen ausbauen:** Leitstrecken sowie ein
   gezielter Schild-Gegenangriff. Neue Beschwörungs-KI, Fallenklassen,
   Element-Reaktionsvollmatrix und weitere Fortschrittsmenüs haben zunächst
   ein ungünstigeres Verhältnis von Aufwand zu überprüfbarer Tiefe.

Die begonnenen drei Umgebungsschadensreaktionen sollten nicht unverändert als
erster Synergiepass fertiggestellt werden. Zuerst ist die Entscheidung festzulegen,
die jede Reaktion im Kampf ermöglicht; danach folgen Werte und Effekte.

## Woran wir Spieltiefe prüfen

Zusätzlich zu DPS, Boss-TTK, Heilung und Wirtschaft:

- Zeit in Nah-, Mittel- und Fernabstand; echte Angriffszeit innerhalb der Reichweite.
- Zielwechsel, erreichte Giftstufen und ungenutzte oder verbrauchte Vorbereitung.
- Kills nach dem Verlassen der Reichweite beim Giftläufer.
- Wirkung des Hin- und Rückwegs sowie Treffer durch neu ausgerichtete Bahnen.
- Aufenthaltsdauer von Gegnern in Leitstrecken, Stellungswechsel und Flächengrenzen.
- Schildverbrauch, Gegenangriffe und erlittene Folgetreffer im Angriffsfenster.
- Zeitpunkt, Kosten und tatsächliche Verfügbarkeit des ersten tragenden Bauteils.

**Die stärkste Kontrollprobe ist das Vertauschen der Spielweisen:** Spielt sich
der Giftläufer mit seiner eigenen Route erkennbar besser als mit dauerhaftem
Nachsetzen? Verliert der Rückflug-Geometer Nutzen, wenn er nie seitlich versetzt?
Lohnt sich die gezielte Vorbereitung des Frostbrechers gegenüber blindem Kreisen?

Solche Unterschiede sind Hypothesen, keine automatisch aus Telemetrie bewiesene
Spielfreude. Zunächst kontrollierte Vergleichsproben, dann menschliche Runs.
Ein Mensch sollte nach kurzer Spielzeit sagen können, was er wegen seines Builds
anders macht, ohne dafür Schadenszahlen lesen zu müssen.
