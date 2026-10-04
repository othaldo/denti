# Patchnote-Historie

Die Versionsnummer wird zentral in `project.godot` gepflegt und im Hauptmenü angezeigt. 0.1.0 wurde rückblickend anhand der Git-Historie dokumentiert; 0.2.0 bündelt die seitdem entstandenen Änderungen. Die Einträge beschreiben implementierte Funktionen. Weitere Pläne stehen in der [Roadmap](docs/ROADMAP.md).

## In Entwicklung

- **Schnellere Tests:** vollständige Suite mit bis zu vier parallelen Godot-Prozessen, getrennten Benutzerdaten, Zeitlimits und Einzelzeit-/Log-Berichten. Lokal 84 Tests in 96 statt 325 Sekunden; CI verwendet denselben Runner. [Laufzeitvergleich](docs/TEST_RUNTIME.md).

- **Testarenen im Web:** siebenmal Einstellungen → Zurück schaltet die Code-Eingabe frei. `debug map` startet eine volle Welle-17-Arena, `boss charge` den isolierten Karieskönig. FPS-/Objektanzeige und Neustart im Pausemenü; der normale Spielstand bleibt erhalten. Der Web-Export unterstützt die Bildschirmtastatur. [Testcodes](docs/TEST_ARENAS.md).

- **Performance bei vielen Objekten:** gezielte Rasterabfragen, weniger doppelte Trefferprüfungen, gemeinsame Verarbeitung entfernter Beute und gebündelte Gegnerschatten. Keine verringerte Gegnerdichte oder Kampfwerte. [Messungen](docs/DENSE_COMBAT_PERFORMANCE.md).

- **Nass verlangsamt:** Wasserwaffen, Pfützen und andere Nassquellen senken das Lauftempo um 20 %, bei Eliten um 10 % und bei Bossen um 5 %. Erneutes Durchnässen verlängert nur die Dauer; Verlangsamung stapelt sich nicht. Angekündigte Anstürme bleiben unverändert. Karten/Details erklären den Effekt, Save/Resume erhält die verbleibende Nassdauer. [Regeln und Tests](docs/WET_STATUS.md).

- **Waffenbalance:** mehr Nahkampfschaden als Ausgleich für Reichweite und verlorene Angriffszeit, stärkere Fusion bis IV und gezielte Buffs für schwache Fernwaffen. Die Zauberbürste bleibt unverändert. Karies-Fräse verursacht 75 statt 55 % Schaden gegen normale Gegner; bestehende Evolutionen übernehmen die verbesserten Grundwerte. Reproduzierbare echte DPS-Messungen für alle 18 Waffen und vier Stufen, getrennt nach Einzelziel, Gruppe, Linie und Boss. [Vergleich und Tests](docs/WEAPON_DPS_BALANCE.md).

- Bossgeschosse werden beim Laden als gemeinsame Texturen vorbereitet und zusammen mit Charge-Zeichenpfaden einmal in einem kleinen separaten Viewport gerendert. Dadurch entfällt ihre erstmalige Bilderzeugung am Ende des ersten Charge.

- Flaky Save/Resume-Test korrigiert: Die Prüfung berücksichtigt die Obergrenze von 65 % Krit-Chance, statt bei einer zufälligen Glanz-Karte einen höheren Wert zu erwarten. Neue gezielte Prüfungen decken alle elf Level-up-Typen und vier Seltenheiten sowie Glanz unter, nahe und an der Obergrenze ab.

- Mobiler Pause-Button sitzt unter der FPS-Anzeige, damit sich beide im Hochkant- und Querformat nicht überdecken.

- **Performance:** räumliche Gegnerabfragen für Waffen und Synergien, gemeinsame
  Projektil-/Beuteatlanten, laufende Telemetrie-Summen, weniger HUD-Arbeit und
  Treffer-Tweens sowie begrenzte kosmetische Schadenszahlen. Neue Grafikoptionen
  Automatisch / Sparsam / Voll; Automatisch startet in voller Auflösung und
  senkt sie bei anhaltend unter 20 FPS im Kampf für den Run ab.
  Kampfwerte und Gegnerdruck bleiben erhalten.
  [Messungen und Prüfungen](docs/PERFORMANCE_AUDIT.md).

- Gerichtete Gegnergrafiken folgen der tatsächlichen Laufrichtung, einschließlich Rückzug und Ansturm; Angriffswarnungen zeigen die angekündigte Richtung. Die Blickrichtung bleibt beim Fortsetzen eines Runs erhalten.

- **Gift und Blutung für Denti:** erfolgreiche Gegnerkontakte und Geschosse können zeitlich begrenzte Effekte übertragen. Gift ignoriert Härte, Blutung wird durch Härte reduziert. Dodge und Schild verhindern die Anwendung; gleiche Effekte stapeln keinen Schaden endlos. Gesichter und HUD zeigen echte Zustände, Save/Resume bewahrt Tickzeiten und Eigenschaften. Effekte enden vor der Beutesammlung. Neu: Giftkeim mit Giftschuss-Fächer und Zahnfleischbeißer mit Blutungsansturm, eigene gemalte Sprites; Einführung, Häufigkeit, Stärke und Dauer skalieren mit Schwierigkeit. Spätere gewöhnliche Gegner und Eliten können eine erkennbare Statuseigenschaft tragen. [Regeln, Messwerte und Vorschau](docs/PLAYER_STATUS_EFFECTS.md).

- **Zahnflutsch:** neues Ausweichattribut mit höchstens 60 % effektiver Chance, eigenem Icon und vier Level-up-Stufen. Erfolgreiches Ausweichen bewahrt Schilde und lässt Denti zwinkern. Gleitwachs, Seidenwurzel, Flutschspülung, Lotusschmelz und das einmalige Mythic Unfassbare Wurzel erweitern den Pool auf 93 Items; Heilungs- und Schildsynergien haben begrenzte Auslösefrequenzen. Shop, Stats, Testmenü, Telemetrie und Save/Resume unterstützen das Attribut. [Werte und Vorschau](docs/DODGE.md).
- **Gesichtsausdrücke:** Denti reagiert auf Schaden, Heilung, wenig HP, Schildblock, Wellenabschluss und Tod. Gift-/Blutungsanzeigen zeigen die laufenden Effekte einzeln und kombiniert. [Animation und Anschluss](docs/DENTI_EXPRESSIONS.md).

- Goldextraktor-Icon: Armführung überarbeitet, linker Griff zur oberen rechten Backe; keine Klinge zwischen den Münzen. Zwei äußere Backen und vollständige Griffe ohne abgeschnittene Atlasränder. Die Goldsonde bleibt unverändert.

- **Endlosmodus:** nach dem Sieg in Welle 20 mit dem bestehenden Build weiterspielen. Ab Welle 21 dauern Wellen 60 Sekunden; die Brotato-Endloskurve verstärkt Gegner und Shoppreise. Mehr Elite- und Gegnerdruck, Doppelbosse in Welle 30/40/... und vollständiges Save/Resume. Der ursprüngliche Sieg bleibt erhalten. [Kurve, Messungen und Vorschau](docs/ENDLESS_MODE.md).

- Normale Gegner haben auf Normal 100 % Basis-Münzchance, mit Wellenabschwächung ab Welle 5 auf 70 % in Welle 20. Die bisherige zusätzliche niedrige Grundchance entfällt; XP bleibt unabhängig.
- **32 Shop-Items:** Goldsonde kann Münz-Drops verdoppeln und profitiert begrenzt von Glück; Goldextraktor gibt mehr Münzen aus Zucker und Eliten. Beide haben Nachteile, Stapellimits und neue gemalte Icons.
- **Level-up-Rerolls:** vier neue Angebote gegen Münzen, steigende Kosten pro Auswahl und Zurücksetzen beim nächsten verdienten Level. Meilenstein-Seltenheit und Save/Resume bleiben erhalten. [Messungen und Vorschau](docs/ECONOMY_BALANCE.md).

- Dentis Ausrüstung belegt **Wurzeln**: Shop, Waffenbeschreibungen, Fusion und Pausemenü verwenden „1 Wurzel“ beziehungsweise „2 Wurzeln“. Im Shop-Tooltip steht „ca.“ statt des von der Schrift nicht unterstützten „≈“-Zeichens vor dem DPS-Wert.

- Acht überarbeitete Waffengrafiken mit klareren Formen: Kronenwerfer, Mörser, Wasserflosser, Fluorid-Sprüher, Turbine, Schleuder, Fräse und Polierer. Separate Arbeitsflächen drehen sich bei stabiler Perspektive; die Schleuder spannt Gummibänder und Beutel statt den Griff zu verformen. Fernkampfwaffen erhalten passendere Ruhepositionen, die Zauberbürste steht aufrecht. [Bilder, Animation und Prüfung](docs/WEAPON_ART_REFINEMENT.md).

- Größenvergleich mit Denti und allen 18 Waffen als Screenshots in Ruhe und im Angriff. Bohrer, Kratzer, Peitsche, Garotte und Speer erhalten passendere Proportionen.
- Turbo-Bohrer: 60 statt 100 Pixel, 0,72 statt 1,28 Sekunden Angriffspause, 22 statt 33 Basisschaden und 100 statt 150 % Nahschaden-Skalierung. Schnellerer Takt und moderat höherer dauerhafter Schaden; Reichweite und Bossbonus bleiben erhalten.
- Nahe Gegner werden bei kurzen Rundum- und Bogenschnitten zuverlässiger getroffen. Zusätzliche Kontaktprüfungen für alle Stufen und Richtungen sichern die Reichweite kleinerer Waffen ab. [Vorschau und Messungen](docs/WEAPON_SIZE_BALANCE.md).

## 0.2.0 · Pressure + Build Depth — 01.10.2026

### Mehr Builds und Belohnungen

- **18 statt 8 Waffen:** Zahnstocher-Speer, Karies-Fräse, Interdental-Bürste, Fluorid-Sprüher, Mundduschen-Turbine, UV-Lampe, Amalgam-Schleuder, Zahnseiden-Garotte, Prophylaxe-Polierer und Fluorid-Rakete erweitern das Arsenal. Neue Angriffe bieten unter anderem Stichlinien, Frontbögen, Sprühkegel und durchdringende Strahlen. [Waffenübersicht](docs/waffen.md).
- **30 statt 18 Shop-Items:** mehr Kombinationen für Blutung, Wasser, Crit, Schild, Heilung, Projektile und Economy sowie Zucker-Builds mit Vor- und Nachteilen. [Itemübersicht](docs/items.md).
- **Zehn statt acht Stats:** Nahschaden und Fernschaden ergänzen Bisskraft. Waffen nutzen eigene Koeffizienten für diese Schadensboni.
- **Ununterbrochene Wellen:** Levelaufstiege werden im Kampf vorgemerkt. Nach dem Einsammeln aller verbliebenen Beute folgen die Level-up-Auswahl, Kistenentscheidungen und gegebenenfalls Bossrelikte; danach öffnet der Shop.
- **Seltene Zahnfee-Kisten:** Item behalten oder gegen Münzen zerlegen. Glück beeinflusst die Chancen innerhalb fester Grenzen; gewöhnliche Zufallskisten sind auf einen Fund pro Welle begrenzt.
- **Fünf göttliche Relikte:** nach den Bossen in Welle 5, 10 und 15 jeweils eines von drei Angeboten wählen. Die Effekte unterstützen Blutung, Wasser, Schild, Crit und Bewegung. [Reliktübersicht](docs/relics.md).

### Kampf und Gegnerdruck

- Dichtere spätere Wellen, zeitlich variierende Gegnergruppen, zusätzliche Horden und wechselnde Gegnermischungen. Normale Wellen dauern je nach Fortschritt 35–50 Sekunden; Bosswellen bleiben bei 45 Sekunden.
- Zwei Elite-Gegnertypen: **Säurekrone** mit Projektilmustern und **Jagdkeim** mit Verstärkung und Tempo-Aura. Später erscheinen mehrere Elite-Gruppen; ein sichtbarer Schutz begrenzt extreme Schadensspitzen.
- Mehr angekündigte Angriffe: Zucker-Anstürme, Schussfächer, versetzte Projektilringe, parallele Bahnen und langsame Projektile zur Raumkontrolle.
- Eigene Bossränge und Grafiken: **Karies-Graf**, **Karies-Prinz**, **Karies-König** und **Karies-Imperator**. Schutzphasen, Verstärkung und zusätzliche Angriffe an Lebensschwellen geben ihren Mechaniken mehr Zeit und Gewicht.
- Überlebende Bosse werden nach Ablauf des Timers **Entzündet**. Eine animierte Aura passt sich der Bossgröße an und steigert Farbe und Intensität vom orangefarbenen Grafen bis zum violetten Imperator. Die Eskalation setzt sich beim Fortsetzen eines Runs korrekt fort. [Aura-Vorschau und Details](docs/BOSS_INFLAMMATION.md).
- Schwierigkeitsgrade **Easy, Normal und Hard**; **Hell** wird durch einen Sieg auf Hard freigeschaltet.
- Treffer-Unverwundbarkeit berücksichtigt die Höhe des erlittenen Schadens innerhalb begrenzter Werte. Waffen erhalten animierte Angriffe, Rückstoß und Treffereffekte.

### Stats und Economy

- **Bisskraft skaliert Schaden prozentual.** Nah- und Fernschaden erhöhen den gewichteten Basisschaden der jeweiligen Waffe. Härte reduziert eingehenden Schaden prozentual mit abnehmendem Zusatznutzen. Waffenwerte und Verteidigung wurden dazu neu abgestimmt. [Schaden und Verteidigung](docs/DAMAGE_DEFENSE_BALANCE.md).
- **Putzeifer und Bewegung verwenden additive Prozentboni.** Speichel zählt Regenerationspunkte und heilt einzelne HP in passenden Zeitabständen; die vorher sehr starke Regeneration wurde abgeschwächt. [Tempo und Regeneration](docs/STATS_BALANCE.md).
- Gold fällt unabhängig von XP und in frühen Wellen häufiger. Shoppreise steigen mit jeder Welle entlang der untersuchten Brotato-Kurve; gemerkte Angebote behalten ihren Preis. [Economy und Messungen](docs/ECONOMY_BALANCE.md).
- **Vier statt drei Angebote** im Shop und beim Levelaufstieg. Neue Nah-/Fernschaden-Boni berücksichtigen die passenden ausgerüsteten Waffen.
- Gleiche Waffen belegen bei freien Händen eigene Plätze. Manuelle Fusionen reichen bis Stufe IV; bei voller Ausrüstung kann ein passender Kauf direkt fusionieren. Verkäufe verlangen eine Bestätigung und erstatten einen Teil der ausgegebenen Münzen.

### Bedienung und Darstellung

- Kompakter, responsiver Shop: vier Angebote nebeneinander bei ausreichend Platz, angepasste Anordnung auf kleinen Bildschirmen und größere ausgerüstete Waffenplätze.
- Preis- und Merken-Buttons bleiben pro Ansicht an festen Positionen und haben einheitliche Größen. Ein Pin markiert gemerkte Angebote; Neu würfeln sitzt oben bei den Angeboten, der Startbutton unten rechts.
- Gesammelte Items und Relikte bleiben als Icons mit Anzahl sichtbar. Hover und Antippen zeigen Namen, Stats und Effekte.
- Der zusätzliche Wellenprofil-Text im Shopkopf entfällt; die Gegnermischungen bleiben aktiv.
- Touch-Joystick und angepasste Menüs für mobile Geräte, einschließlich kleiner Querformat-Ansichten.
- Eigene gemalte Icons für alle zehn Stats; Glanz und Zahnglück sind unterscheidbar. Level-up-Icons passen vollständig in ihre Karten.
- Waffenvergleiche zeigen die aktuellen Buildwerte. Mehrere Darstellungs- und Zeichensatzprobleme wurden behoben.

### Korrekturen, Spielstände und Entwicklung

- **Seltenheit bei mehreren vorgemerkten Levelaufstiegen korrigiert:** Ein Sprung von Level 8 auf 10 wertet die Auswahl für Level 9 und 10 getrennt aus. Der garantierte Bonus eines Meilensteins gilt nur für den jeweiligen Levelaufstieg.
- Speichern/Fortsetzen bewahrt unter anderem ausstehende Belohnungen, Relikte, Schwierigkeitsgrad, Wellenlänge, gemerkte Angebote und Boss-Eskalation. Alte Statwerte werden in das neue Modell umgerechnet; die Versionsanhebung erfordert keinen Spielstand-Reset.
- Kampf-Telemetrie im Debug-Build zeigt DPS, Kills pro Sekunde, Gegnerdruck, Schaden, Boss-Kampfzeit und Economy. Der Run-Rückblick fasst Sieg oder Niederlage zusammen; JSON-Berichte erleichtern Balance-Vergleiche.
- Lokales Debug-Menü zum gezielten Testen von Waffen, Items, Stats und Wellen. Die automatisierte Testsuite wurde auf 46 Tests für Gameplay, Belohnungsablauf, Spielstände und UI erweitert.

## 0.1.0 · Spielbare Grundlage — 29.09.2026

Rückblickend dokumentierter Stand beim Einführen der Versionsanzeige ([Commit 197b5d8](https://github.com/othaldo/denti/commit/197b5d8)).

- Manuelle Bewegung und automatische Angriffe in einer scrollenden Arena.
- 20 Wellen zu je 45 Sekunden, vier normale Gegnertypen und Bosskämpfe in Welle 5, 10, 15 und 20.
- Acht Waffen mit Handkosten und Fusionen bis Stufe IV, 18 stapelbare Shop-Items und acht Level-up-Stats.
- Drei Shopangebote und drei Level-up-Boni; Seltenheit, Glück, Neu würfeln, Waffenverkauf und buildabhängige Shopgewichtung.
- Beute wird am Wellenende eingesammelt. Level-up-Auswahlen unterbrechen zu diesem Zeitpunkt noch den Kampf.
- Hauptmenü, Pause, Optionen, automatische Spielstände und Fortsetzen.
- Musik, Kampfgeräusche, Lautstärkeregler und optionale FPS-Anzeige.
- Automatisierte Tests sowie Godot-Web-Export und Veröffentlichung auf GitHub Pages.
