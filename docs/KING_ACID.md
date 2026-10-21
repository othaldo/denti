# Karies-König: der Säuresammler

Stand: 21.10.2026. Eigener Encounter im echten Welle-15-Gegnerprofil, damit auch
in Story und Endlos. Kein zusätzlicher HP-Multiplikator. Der alte generische
Charge-/Pulsablauf und seine Phasensalven werden für diesen König ersetzt.

[Native Vergleichsaufnahmen aller vier Stufen](concepts/king-acid/fight.html).
[Generierte Assets, vollständige Prompts und Herkunft](concepts/king-acid-art.md).

## Verhalten und Antworten

Der gepanzerte König trägt zwei Säurebehälter, eine Mineralienkrone und eine
schwere Steinfaust. Sechs Gelenke bewegen die gemalten Teile ohne Verformung.
Ein Shader zeigt den Flüssigkeitspegel in den Behältern. Ein gemeinsamer
Encounter-Timer steuert Haltung, Warnung, Flächen und Treffer.

Die Folge **Säurerinnen → Splitterstampf → Pegelwechsel** beginnt bereits in der
ersten Gesundheitsphase. Jeder Ablauf endet mit Sammlerzug und offener Brust.

| Mechanik | Umsetzung | Antwort |
| --- | --- | --- |
| Säurerinnen | 1 s feste Vorwarnung; 2,2 s Fluss; 48 px breite gemalte Ströme | Ufer früh wählen, die markierte Bahn verlassen |
| Pegelwechsel | Erster Fluss 1,25 s, dann neuer Rinnensatz mit eigener 1-s-Warnung; alter Boden versiegt nach 0,30 s | Den freien Übergang nutzen, bevor der nächste Strom aktiv wird |
| Splitterstampf | 1 s Vorwarnung für alle Reihen; Aufbruch alle 0,24 s, jeweils 0,16 s aktiv; jede Reihe schickt einen Splitterfächer nach außen | Seitlich aus der Folge oder rechtzeitig näher zum König wechseln |
| Sammlerzug | 0,95 s rückläufige Texturbewegung und wieder gefüllte Behälter; danach freie Flächen und 1,6 s offener Kern | Öffnung für einen Gegenangriff nutzen |

Geschlossener/offener Kern multipliziert eingehenden Schaden mit 0,85/1,25;
bestehende Rüstung, Schadensbudget und Phasenschutz bleiben zusätzlich wirksam.
Keine Immunität. Der Stampf beginnt fest 180 px vor dem König, ohne eine auf
Denti zugeschnittene Lücke auszulassen. Reihen liegen 105 px auseinander und
sind 320 px lang. Alle Treffer benutzen den normalen Schadenspfad; ein Dash
ist keine Unverwundbarkeit gegen die Säure.

Die zweite Gesundheitsphase ergänzt eine Stampfreihe. In der letzten Phase
kommen zwei Splitter je Reihe dazu; nach dem letzten Pegelwechsel folgt ein
angekündigter Stampf, während der letzte Rinnensatz noch aktiv ist. Erst danach
werden die Rinnen zurückgezogen. Höchstens diese zwei Mechaniken überlagern
sich im neuen eigenen Ablauf.

## Schwierigkeit

Die bestehenden gemeinsamen Schwierigkeitsdaten bleiben maßgeblich. Das
Königsprofil leitet daraus seine Werte ab und kopiert seine Projektilressource
explizit, damit mehrere Bosse oder Stufen keine gemeinsame Vorlage verändern.
Alle Warnzeiten bleiben gleich.

| Wert | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Gleichzeitige Rinnen | 1 | 2 | 2 | 2 |
| Pegelwechsel je Folge | 1 | 1 | 2 | 3 |
| Reihen, erste / zweite / letzte Phase | 2 / 3 / 3 | 3 / 4 / 4 | 4 / 5 / 5 | 5 / 6 / 6 |
| Splitter je Reihe, erste und zweite / letzte Phase | 3 / 5 | 5 / 7 | 7 / 9 | 9 / 11 |
| Splittergeschwindigkeit, px/s | 189 | 210 | 235,2 | 268,8 |
| Gemeinsamer Bewegungsfaktor | 0,90 | 1,00 | 1,12 | 1,35 |
| Bewegung während des Flusses, Anteil der eigenen Positionierung | 0,12 | 0,22 | 0,32 | 0,42 |
| Erholungs- und Positionierungszeit, Faktor | 1,20 | 1,00 | 0,80 | 0,55 |

Der König positioniert sich schwerfällig seitlich und bleibt im sichtbaren
Bereich. Er bewegt sich auch während aktiver Ströme; deren festgelegte Orte
bleiben dabei unverändert. Er läuft für die Positionierung nicht absichtlich
durch Dentis Körper.

## Bahnenden, Warnung und Darstellung

Eine neue Bahn wird beim Beginn ihrer Warnung in Weltkoordinaten festgelegt:
sichtbarer Bereich plus 80 px, begrenzt durch die Arena. Die Kamera verlängert
oder verkürzt eine bereits angekündigte/aktive Bahn nicht. Neue Pegelwechsel
bekommen eine neue, ebenfalls feste Warnung.

Die Bahn hat **runde Enden statt gerader Texturschnittkanten**. Das gemalte
Säurebild wird gespiegelt wiederholt und über eine zwischengespeicherte
Kapselform gelegt. Texturbewegung vermittelt Strömung und kehrt beim
Sammlerzug um. Treffer verwenden dieselben Mittellinien-Endpunkte und den
24-px-Radius, erweitert um Dentis Kollisionsradius. Unsichtbare rechteckige
Ecken am Ende verursachen keinen Schaden. Das Ende darf beim Nachlaufen
sichtbar werden und ist eine wirkliche Grenze der Fläche.

Die Vorwarnung benutzt die vorhandene weiche Charge-Textur samt weichen
Endkappen; keine Rechteckumrandung und kein zusätzlicher Umrisskreis. Die
Steinsplitter benutzen gemalte Atlasgrafik. Texturen, Konturen und Warnungen
werden wiederverwendet; pro fliegendem Splitter wird kein Node erzeugt.
Maximal 96 Splitter pro König, im geprüften Hell-Ablauf maximal 66 gleichzeitig.
Zwei Könige desselben Kampfes reservieren schwere Folgen und teilen das Limit
von zwei aktiven Säurerinnen. Reservierung gilt nur für denselben Spieler,
nicht für voneinander unabhängige Spielszenen.

## Speichern und Integration

`AcidKingData` / `data/encounters/king_acid.tres` enthalten die einstellbaren
Angriffswerte, `BossProjectileData` / `king_shards.tres` das wiederverwendbare
Projektilprofil. `AcidKingEncounter` koordiniert Zustände und Bewegung;
`AcidKingVisuals`, `KingAcidRig` und `BossPaintedVolley` halten Darstellung und
Geschossverwaltung getrennt. Die generierte Originalreferenz des alten Königs
bleibt erhalten.

Snapshots bewahren Zustand, Restzeiten, feste Warnungen, lebende Flächen,
Reihenfolge und bereits getroffene Stampfreihen sowie Splitterpositionen und
Geschwindigkeiten. Alte Saves ohne Königsprofil starten mit einer sicheren
neuen Vorbereitung. Pause friert die Uhr ein; Phasenwechsel und Tod räumen
alle eigenen Gefahren auf. Die Ressourcen samt Flüssigkeitsshader werden
über den vorhandenen Warmup vorbereitet.

## Messung und Prüfung

- Vollständiger Lauf: **129/129 Tests**, Logordner
  `.godot/test_runs/20261021-085457-e1f41520`.
- `acid_king_encounter`: feste Ziele, Warnzeiten, Tickabstand, Dash-Sweep,
  runde Endkollision einschließlich unsichtbarer Ecken, Kamerabewegung,
  lange Frames mit korrekten Geschossgeburtszeiten, echter Schadensunterschied
  am Kern, Pause, ungültige/alte Saves und tatsächliches Fortsetzen im Pegelwechsel.
- `acid_king_difficulty`: alle vier Stufen, getrennte Ressourcen,
  langsame Eckrouten bei 72 % Grundtempo für Rinnen und Stampf,
  Snapshots aller Abläufe, zwei Könige und begrenzte Gefahren.
- Native Sichtprüfung: Desktop, 320×568, 568×320, Kamera am Bahnende und
  Kombination in der letzten Phase. Vergleichsvideos zeigen je 28 s in der
  zweiten Phase, skriptgesteuert, ohne Waffen/normale Gegner und mit 1.000 HP.

[Rohmessung](king_acid_measurements.json): isolierte Welle 15, echte Phasen und
Schadensbudgets, 150 roher DPS nur innerhalb 168 px bzw. 600 px, keine Items,
Waffen, Adds oder Dash. 10.000 Spieler-HP dienen allein zum Aufsummieren von
Schaden. Stillstand, Kreisen und eine einfache Warnungsreaktion werden je
Stufe geprüft; das ist kein optimaler Ausweichalgorithmus.

[Separater Druckvergleich](king_acid_pressure_measurements.json), jeweils 60 s
ohne Bossbeschuss in der letzten Phase: Easy/Normal/Hard/Hell emittierten
75/140/225/264 Splitter. Die Bewegung stieg von 1.588 über 1.942 und 2.413 auf
3.350 px. Die Spitzen lagen bei 12/28/45/66 gleichzeitig lebenden Splittern.
Die höhere Aktionsmenge wird damit auch im tatsächlichen Ablauf gemessen.

Die Messung bestätigt, dass das Repertoire vor dem Tod sichtbar wird. Im
Fernkampfvergleich liegen besiegte Könige bei ca. 56–74 s; Hell ist bei diesem
Test-DPS nach 90 s noch nicht besiegt. Nahkampf verliert zusätzliche Angriffszeit
durch Positionierung. Gerade Hell verlangt deshalb menschliche Build-Tests,
bevor Kampfzeit und Schaden als abgenommen gelten. Dauerndes Kreisen bleibt
in dieser Messung besonders auf den oberen Stufen gefährlich.

Offen: menschliche Nah-/Fernkampfvergleiche mit echten Welle-15-Builds,
vollständige Wellen mit Adds, langsame Eckrouten während der kombinierten
letzten Phase und mobile Web-/GPU-Messung. Die vorhandenen Ecktests belegen
einzelne Fluchtwege, keine allgemeine Lösbarkeitsgarantie jeder Überlagerung.

Reproduzieren:

```powershell
python tools/run_tests.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --filter acid_king* --timeout 90
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/measure_acid_king.gd
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --max-fps 0 --disable-vsync --script res://tools/preview_acid_king.gd -- --difficulty=hell
```
