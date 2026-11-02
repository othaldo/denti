# Testpiloten und Zeitraffer

Die Diagnose kann jetzt Spielstärke, Kampfstrategie und Buildentscheidungen
getrennt vergleichen. Es sind regelbasierte, reproduzierbare Testpiloten, keine
an menschlichen Spielern kalibrierten Leistungsstufen. Der erste Ausbau prüft
den verdienten Einstieg **von Welle 1 bis höchstens Welle 5**.

## Einen Lauf ansehen

Der lokale Launcher öffnet Auswahlfelder statt langer Konsolenbefehle:

```powershell
python tools/bot_launcher.py
```

**Zuschauen** startet genau einen konfigurierten Bot. **Vergleich berechnen**
kann auch alle Waffen, Profile, Strategien oder Schwierigkeiten mit mehreren
Seeds prüfen und zeigt vorher die Anzahl der Läufe. Einstellungen bleiben
lokal gespeichert. Der Launcher erkennt Godot im PATH; sonst lässt sich die
Anwendung auswählen. Ergebnisordner und Bericht öffnen sich über die Buttons.
Abbrechen beendet nur den gestarteten Test samt seinen Workern. Im sichtbaren
Spielfenster speichert Esc dagegen einen regulären Teilbericht.

Die bisherigen direkten Aufrufe funktionieren ebenfalls:

Im Projektordner unter Windows, mit Python und Godot im PATH:

```powershell
python tools/run_bot_comparison.py --visible --weapons turbo_drill --skills expert --strategies aggressive --build-policies synergy --speed 8
```

`--visible` allein startet einen einzelnen geübten Distanzpiloten mit Bohrer.
In der Leiste unten wechseln **1× / 4× / 8× / 16×** das gewünschte Tempo.
**Pause / Weiter** und **Leertaste** halten den Lauf an derselben Stelle an.
Nach jeder Welle bleiben die echten Statangebote, der Verzauberungsplan und
die Shopangebote sichtbar. Vor jeder Auswahl, jedem Kauf und jedem Reroll
wartet der Bot bei 1× zwei Sekunden; neue Angebote und der fertige Einkauf
werden ebenfalls gezeigt. **1× / 4× / 8× / 16× gelten auch im Shop und bei
Belohnungen**: Bei 16× dauert ein Schritt etwa 0,125 Sekunden. Tempoänderungen
wirken sofort auf den laufenden Countdown. Mit Pause hält auch dieser an.
Die normalen Karten lassen sich mit
der Maus ansehen, Entscheidungen und Käufe führt weiterhin der Bot aus.
Verzauberungen werden Punkt für Punkt geplant: Der Bot zeigt erst das Budget,
dann jeweils das betroffene Waffenexemplar und den neuen Effekt-Rang samt
verbleibenden Punkten. Erst nach einer eigenen Abschlussanzeige wird der Plan
übernommen. Für jeden dieser Schritte gelten Tempo und Pause ebenfalls.
**Esc**, das Schließsymbol oder das Schließen des Fensters brechen ab und
speichern den begonnenen Lauf als `aborted` im Bericht.

Die zweite Tempozahl in der Leiste ist das tatsächlich erreichte mittlere
Tempo. Hohe Dichte, Darstellung oder andere laufende Programme können das
gewünschte Tempo begrenzen. Pause und Tempo ändern nur die Wartezeit zwischen
Schritten; alle Physikschritte werden weiter berechnet.

`--capture` legt nach fünf simulierten Sekunden ein natives PNG sowie je eine
Aufnahme der sichtbaren Aufstiegs-, Verzauberungs-, Truhen- und Shopansichten
im Arbeitsverzeichnis des Laufs ab, sofern diese im Lauf vorkommen.
Für einen kurzen Funktionstest:

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
| `simple` – Feuer-Referenz | Bisherige Levelprioritäten, ausschließlich Feuer-Upgrades, passende Exemplare der Startwaffe und höchstens ein Standarditem je Shop. |
| `synergy` – Synergie-Heuristik | Wertet tatsächlich angebotene Stats, passende Itemtags, Lebenszustand und Waffenmechanik heuristisch aus. Etwa Eis/Crit-Schaden beim Polierer, Elektrizität bei einer Nasswaffe oder Blutung bei Schnittwaffen. |

Beide Regeln kaufen reguläre Angebote, bezahlen Rerolls und nutzen nur verdiente
Waffenpunkte. Beide bleiben beim gleichen Waffenstarter, höchstens einem
Shopitem und maximal vier bezahlten Rerolls je Shop. Ein Hybrid, der den
Starter still durch UV ersetzt, würde die Starterdiagnose verdecken und ist
deshalb kein Teil dieser beiden Regeln. Normale Itemtruhen werden behalten;
zufällige Waffen-Verzauberungskapseln werden wie in der Referenz verschrottet.
Die Synergieregel ist eine nachvollziehbare Heuristik, keine optimale Buildsuche.
Ihre Verzauberungen folgen einer festen Priorität je Waffenmechanik. Identische
Waffenexemplare erhalten deshalb oft denselben ersten Effekt. Der Bot würfelt
keine Abwechslung zur Schau und bewertet noch nicht den Zusatznutzen eines
anderen Elements, Lebensraubs oder einer Kontrollrolle im gesamten Build.
Das Reaktionsprofil „Erfahren“ verändert diese Kauf-/Verzauberungsregel nicht.

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
- Der ursprüngliche native 8×-Kontrolllauf ohne Lesepausen berechnete rund 181 Sekunden Kampfzeit in rund
  23 Sekunden Wandzeit und behielt dieselben Kampfergebnisse wie Headless.
- Abgeschlossen: 165/165 Kerntests, die beiden gezielten Zusatzprüfungen für
  Bot-/Referenzläufe und 39/39 Python-Tests. Die nach der Sichtprüfung ergänzten
  Rand-Sichtfeld- und Starttempo-Prüfungen bestehen ebenfalls.
- Launcher und sichtbare Entscheidungen: 45/45 Python-Prüfungen sowie die drei
  gezielten Godot-Prüfungen für Bot, verdiente Progression und Viewer bestehen.
  Echte pausierte Aufstiegs-/Shopansichten verändern weder verdiente Zustände
  noch Bot-Eingaben. Lesen, Pause und ein Tempowechsel mitten im Shop sind
  geprüft. Neue Waffeninstanz-IDs werden beim Zustandsvergleich ausgenommen,
  weil diese bewusst Uhrzeit und Objektidentität enthalten.

Gezielte Prüfungen:

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter bot_pilot
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --suite extended --filter bot_comparison --filter earned_progression
python -m unittest discover -s tools/tests -p "test_bot*.py"
```

Die Werkzeuge sind durch die bestehenden Exportfilter vom normalen Web- und
Windows-Spiel ausgeschlossen. Native Läufe erhalten isolierte Benutzerdaten;
Spielstände und Freischaltungen des Nutzers werden nicht benutzt.
