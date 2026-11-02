# Testpiloten und Zeitraffer

Die Diagnose kann jetzt Spielstärke, Kampfstrategie und Buildentscheidungen
getrennt vergleichen. Es sind regelbasierte, reproduzierbare Testpiloten, keine
an menschlichen Spielern kalibrierten Leistungsstufen. Der erste Ausbau prüft
den verdienten Einstieg **von Welle 1 bis höchstens Welle 5**.

## Einen Lauf ansehen

Im Projektordner unter Windows, mit Python und Godot im PATH:

```powershell
python tools/run_bot_comparison.py --visible --weapons turbo_drill --skills expert --strategies aggressive --build-policies synergy --speed 8
```

`--visible` allein startet einen einzelnen geübten Distanzpiloten mit Bohrer.
In der Leiste unten wechseln **1× / 4× / 8× / 16×** das gewünschte Tempo.
**Pause / Weiter** und **Leertaste** halten den Lauf an derselben Stelle an.
**Esc**, das Schließsymbol oder das Schließen des Fensters brechen ab und
speichern den begonnenen Lauf als `aborted` im Bericht.

Die zweite Tempozahl in der Leiste ist das tatsächlich erreichte mittlere
Tempo. Hohe Dichte, Darstellung oder andere laufende Programme können das
gewünschte Tempo begrenzen. Pause und Tempo ändern nur die Wartezeit zwischen
Schritten; alle Physikschritte werden weiter berechnet.

`--capture` legt zusätzlich nach fünf simulierten Sekunden ein natives PNG
im Arbeitsverzeichnis des Laufs ab. Für einen kurzen Funktionstest:

```powershell
python tools/run_bot_comparison.py --visible --last-wave 1 --speed 8 --capture
```

Unter Linux `--godot godot` ergänzen; auf Windows ist
`Godot_v4.7.2-stable_win64_console.exe` voreingestellt.

## Eine Vergleichsmatrix berechnen

```powershell
python tools/run_bot_comparison.py --weapons turbo_drill,uv_lamp --skills novice,regular,expert --strategies aggressive,kite --build-policies simple,synergy --difficulties normal,hell --seeds 13579,24680,112233 --jobs 4
```

Jede Kombination wird mit jedem Seed ausgeführt. Die Voreinstellung ohne
Argumente ist kleiner: zwei Waffen, drei Piloten, Distanzstrategie, einfache
Buildregel, Normal und drei Seeds. Das sind 18 Läufe. Alle 18 regulären Waffen
stehen als Starter zur Verfügung; geheime Evolutionen sind keine Startoptionen.

Ohne `--visible` arbeitet Godot headless ohne Echtzeitbegrenzung. Bis zu vier
Worker besitzen getrennte Benutzerdaten. Auch viele Seeds einer einzigen
Konfiguration werden auf freie Worker verteilt. Bei Fehlern, Timeout oder
Strg+C beendet der Runner seine eigenen verbleibenden Kindprozesse.

## Drei unabhängige Achsen

Die Profilressourcen liegen in `tools/balance/bots/`. Sie geben Denti keine
anderen Lebens-, Schadens-, Geschwindigkeits- oder Ausdauerwerte.

| `--skills` | Wahrnehmungsverzögerung | Entscheidung alle | Bewegungspatzer | Warnungen / Dash |
| --- | ---: | ---: | ---: | --- |
| `novice` – Anfänger | 400 ms | 200 ms | 18 % der Entscheidungen | keine bewusste Warnungsreaktion, kein Dash |
| `regular` – Geübt | etwa 167 ms | 100 ms | 5 % | Warnungen und vorsichtiger Dash |
| `expert` – Erfahren | etwa 67 ms | 50 ms | keine zusätzlichen Patzer | längere Vorhersage, Warnungen und Dash |

Die Wahrnehmung wartet tatsächlich in einer Tick-Queue, bevor eine Entscheidung
sie benutzen darf. Zufällige Richtungspatzer haben einen eigenen Seed und
verbrauchen keine Kampf-/Shop-Zufallswürfe. Eingaben bleiben bis zur nächsten
Entscheidung stehen.

| `--strategies` | Ziel |
| --- | --- |
| `aggressive` | Näher herangehen und Angriffe ausspielen. |
| `kite` | Abstand an Waffenreichweite ausrichten und seitlich bewegen. |
| `collector` | Sichtbare Beute priorisieren; Gefahren trotzdem nach Profil bewerten. |
| `boss` | Einen sichtbaren Boss gegenüber näheren normalen Gegnern bevorzugen. |

Eine Strategie gibt das Ziel vor; das Pilotenprofil bestimmt, wann und wie
zuverlässig der Bot darauf reagiert. Deshalb kann auch ein langsamer Anfänger
die gleiche Grundstrategie wie ein erfahrener Pilot fahren.

| `--build-policies` | Entscheidungen |
| --- | --- |
| `simple` | Bisherige Levelprioritäten, Feuer-Upgrades, passende Exemplare der Startwaffe und höchstens ein Standarditem je Shop. |
| `synergy` | Wertet tatsächlich angebotene Stats, passende Itemtags, Lebenszustand und Waffenmechanik heuristisch aus. Etwa Eis/Crit-Schaden beim Polierer, Elektrizität bei einer Nasswaffe oder Blutung bei Schnittwaffen. |

Beide Regeln kaufen reguläre Angebote, bezahlen Rerolls und nutzen nur verdiente
Waffenpunkte. Beide bleiben beim gleichen Waffenstarter, höchstens einem
Shopitem und maximal vier bezahlten Rerolls je Shop. Ein Hybrid, der den
Starter still durch UV ersetzt, würde die Starterdiagnose verdecken und ist
deshalb kein Teil dieser beiden Regeln. Normale Itemtruhen werden behalten;
zufällige Waffen-Verzauberungskapseln werden wie in der Referenz verschrottet.
Die Synergieregel ist eine nachvollziehbare Heuristik, keine optimale Buildsuche.

## Wahrnehmung und Grenzen

Alle Profile erhalten dasselbe virtuelle **1280×720-Sichtfenster**, zentriert
auf Denti wie die Kamera, auch an Arenarändern. Darin sieht
der Sensor höchstens die 32 nächsten lebenden Gegner und 64 nächsten normalen
Säureprojektile sowie sichtbare Beute. Gegnergeschwindigkeit wird aus vergangenen
Beobachtungen geschätzt. Künftige Spawns, nächste zufällige Angriffe und noch
nicht sichtbare Zielpunkte werden nicht übergeben.

Der Ausweichplaner bewertet Körperkontakt, aktuelle Projektilbahnen, sichtbare
Puls-/Sturmwarnungen und die gerade angekündigten Mantelsektoren des Grafen.
Beim Dash werden Gegner, Projektile und aktive Warnflächen auch **auf dem Weg**
geprüft. Ausgeführt wird der echte `PlayerDash` mit Kosten, Cooldown und den
normalen Kollisions-/Schadensregeln.

Die Spezialfelder der späteren Bosse sind noch keine vollständige
Sensorimplementierung. Darum ist dieser Runner ausdrücklich auf W1–5 begrenzt.
Die alten Checkpoint-Vergleiche für späte Wellen bleiben separat vorhanden.
„Erfahren“ ist außerdem kein Beweis dafür, dass der Pilot in jeder Waffen- und
Strategiesituation besser spielt. Mehr Ausweichen kann Angriffszeit kosten;
die Profile benötigen weitere Kalibrierung und menschliche Gegenproben.

## Zeit, Ergebnisse und Reproduktion

Simulation und Physik bleiben bei **60 Schritten pro Spielsekunde**,
`Engine.time_scale = 1`. Im sichtbaren Modus werden Darstellung und Wandzeit
gesondert getaktet; zwischen zwei Bildern dürfen mehrere vollständige
Simulationsschritte liegen. Lange Renderpausen erzeugen keine gröberen
Kollisionsschritte. Die verwendete API ist Godots
[Renderloop mit manuellem Zeichnen](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-property-render-loop-enabled).

Standardmäßig entsteht ein neues Verzeichnis unter
`.godot/bot_runs/<Zeitstempel-ID>/`. Der Runner gibt den Pfad des zusammengeführten
JSON-Berichts aus; daneben liegt eine Markdown-Tabelle. Die Unterverzeichnisse
enthalten Workerberichte, Engine-Logs und gegebenenfalls `viewer.png`. Ein
explizites `--output .godot/mein_vergleich.json` legt den Gesamtbericht fest.
Bestehende historische Balanceberichte werden nicht automatisch überschrieben.

Im Bericht stehen alle Achsen, Seeds, verdiente Ausrüstung, Wellenzustände,
Bot-Entscheidungszähler, Patzer, Dash-Anfragen und tatsächliche Kampftelemetrie.
Warnungs-/Projektilzähler zählen Beobachtungen einschließlich Wiederholungen,
nicht eindeutige Angriffe. Die Telemetrie zählt zusätzlich die tatsächlich
ausgeführten Dashs; eine verzögerte Anfrage kann am echten Cooldown scheitern.
Der Aktions-Digest erkennt unterschiedliche Eingabefolgen. Engineversion,
Quellhash einschließlich der Profilressourcen, Git-Basis, offene Änderungen,
Physikrate und Wandzeit machen den Messstand nachvollziehbar. Native
Tempo-/Pause-/Abbruchaktionen werden zusätzlich mit ihrem Tick gespeichert.

```powershell
python tools/run_bot_comparison.py --summarize .godot/mein_vergleich.json
```

Die Zusammenfassung vermischt keine Profile/Strategien/Buildregeln. Gold, XP und
HP vor dem Boss werden nur unter tatsächlich bis W5 gelangten Läufen gemittelt;
Boss-TTK nur unter erfolgreichen Kills. Abbrüche bleiben sichtbar und zählen
nicht als verlorene vollständige Runs. Für kurze Proben vor W5 wird keine
Boss-Erfolgsquote erfunden. Vollständig beendete W1 hat eine eigene Tabelle.

## Prüfung dieses Ausbaus

- Kontrolliertes Projektil: Anfänger erhält den Treffer; erfahrener Pilot weicht
  mit einem echten Dash und echtem Ausdauerverbrauch aus.
- Identische Seeds erzeugen wieder dieselben Eingaben und verdienten Zustände.
- Die alte `hunt`-Referenz stimmt weiter mit ihrem vorherigen Messstand überein.
- Headless, 1× und 8× liefern im geprüften Einstiegsfall dieselben Eingaben,
  Kills, Gold, XP, Level und Stats. Ein voller nativer Hell-Lauf bis zum ersten
  Boss stimmt ebenfalls mit seinem Headless-Gegenstück überein.
- Alle 48 Kombinationen aus zwei Waffen, drei Profilen, vier Strategien und
  zwei Buildregeln wurden über zwei Wellen ausgeführt; zusätzlich 36
  Normal-/Hell-Einstiege mit drei Seeds und acht weitere Polierer-/Turbinenläufe.
- In der abschließenden 36er-Probe wurden insgesamt rund 102 Minuten Kampfzeit in rund
  80 Sekunden Wandzeit auf drei Workern berechnet. Das ist der aggregierte
  Durchsatz dieser Maschine, keine zugesicherte Beschleunigung eines Einzellaufs.
- Der native 8×-Kontrolllauf berechnete rund 181 Sekunden Kampfzeit in rund
  23 Sekunden Wandzeit und behielt dieselben Kampfergebnisse wie Headless.
- Abgeschlossen: 165/165 Kerntests, die beiden gezielten Zusatzprüfungen für
  Bot-/Referenzläufe und 39/39 Python-Tests. Die nach der Sichtprüfung ergänzten
  Rand-Sichtfeld- und Starttempo-Prüfungen bestehen ebenfalls.

Gezielte Prüfungen:

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter bot_pilot
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --suite extended --filter bot_comparison --filter earned_progression
python -m unittest discover -s tools/tests -p test_bot_comparison.py
```

Die Werkzeuge sind durch die bestehenden Exportfilter vom normalen Web- und
Windows-Spiel ausgeschlossen. Native Läufe erhalten isolierte Benutzerdaten;
Spielstände und Freischaltungen des Nutzers werden nicht benutzt.
