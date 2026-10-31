# Prinz und Imperator: kürzere Folgen, mehr Positionswechsel

Neuester Stand vom 31.10.: [Weniger Leben und aggressivere Bosse](BOSS_AGGRESSION.md). Dieser Bericht bleibt als frühere Vergleichsmessung erhalten.

Stand: 30.10.2026, Godot 4.7.2. Zweiter Balancing-Schritt nach dem
[Königsumbau](KING_PRESSURE_BALANCE.md). Graf und überarbeiteter König bleiben erhalten.
HP, Rüstung, Trefferschaden, Adds und übergreifender Boss-Schadensschutz sind unverändert.

## Prinz

Neue Bombenfolgen haben höchstens drei Würfe und wechseln ab der Kombophase nach
kurzem Nachsetzen direkt in höchstens zwei Fächersalven. Die Pfützen der letzten
Bomben sind dann noch vorhanden. Der separate Fächerblock im folgenden Zyklus
wird verbraucht, damit der Ablauf schneller zum Ansturm wechselt.

Selbstständige Fächerblöcke sind auf drei Salven begrenzt. Auf Hard/Hell schließt
der Prinz vor Fächern auf 260/220 px Zielabstand auf. Die Fächer zielen mit
0,25/0,50 s Vorhalt, begrenzt auf 90 px. Alle Richtungen werden beim Warnbeginn
fixiert. Vorwarnungen, Projektilverteilungen, Geschwindigkeiten und Budgets
behalten ihre bisherigen Werte; es werden keine Schüsse für Denti ausgespart.

Die Kombination beginnt auf Easy in Gesundheitsphase 3, Normal in Phase 2 und
Hard/Hell bereits in Phase 1. Die vorhandenen kurzen Warnungen bleiben jeweils
vollständig erhalten. Frühere Saves mit fünf Bomben oder vier Hell-Salven
behalten ihre bereits angekündigten längeren Folgen.

## Imperator

Aktualisierung vom 31.10.: Neue Hofurteile und die Urteil-/Nervenkombination
erfassen jetzt Denti bei Warnbeginn. Vorher nähert sich der Imperator auf
höchstens 300 px; bei großer Entfernung dauert seine Vorbereitung entsprechend
länger. Ursprung und Winkel bleiben während der Warnung anschließend fest.
Die Messwerte dieses Dokuments beziehen sich noch auf die vorherigen,
zyklusabhängigen Urteilwinkel; die aktuellen Regeln stehen in
[EMPEROR_COURT.md](EMPEROR_COURT.md).

Zwischen Salven sucht er 0,4 s lang eine neue Position. Danach fixiert er den
nächsten Ursprung und die nächste Warnung; während der Warnung bewegt er sich
nicht. Neue Urteil-, Portal- und Nervenfolgen sind auf je drei Wiederholungen
begrenzt, damit die Mechanik häufiger wechselt.

Das letzte Urteil einer Folge kann gleichzeitig eine Portalbahn ankündigen.
Beide sind für **1,4 s** sichtbar und werden erst anschließend gemeinsam
freigegeben. Darauf folgt nach Neupositionierung der Nerventakt. Die Kombination
beginnt nach derselben Staffelung wie beim Prinzen: Easy Phase 3, Normal Phase 2,
Hard/Hell Phase 1. Die bestehenden einzelnen Portalstiche und die spätere
Urteil-/Nerven-Kombination bleiben verfügbar. Es werden höchstens zwei
Hauptmechaniken gleichzeitig angekündigt.

Der neue Bewegungszustand ist an die Zustandsliste angehängt. Ein eigenes
gespeichertes Komboflag schützt alte Urteilwarnungen davor, nach dem Laden
eine niemals angekündigte Portalbahn zu erhalten. Die gemeinsame Vorwarnung
wird auch beim Zeichnen und Animieren verwendet.

## Messung

Vorher: [ursprünglicher Bossvergleich](boss_comparison.json), Wellen 10 und 20.
Nachher: [288 Druckproben und 40 Tötungszeitproben](royals_pressure_after.json).
Alle vier Schwierigkeiten, drei feste Gesundheitsphasen, drei Startwinkel
und vier Bewegungen. 45 s pro Druckprobe, 60 Hz, reguläre Treffer-Unverwundbarkeit
bei Maximalleben 100; großes aktuelles Leben nur als Messvorrat.

Keine Waffen, Items, Rüstung, Heilung, Dash, Adds oder normale Gegner. Die
Kreispiloten reagieren nicht auf Warnungen. Es sind kontrollierte Vergleiche,
keine menschlichen Siegraten und keine vollständigen Welle-10-/20-Builds.

**Treffer pro 45 Sekunden auf Hell**, jeweils Mittelwert aus neun Proben:

| Boss | Bewegung | Vorher | Nachher |
| --- | --- | ---: | ---: |
| Prinz | Nahes Umlaufen, Zielabstand 160 px | 12,9 | 15,3 |
| Prinz | Mittleres Umlaufen, Zielabstand 320 px | 15,6 | 13,1 |
| Prinz | Mittleres Umlaufen, +30 % Tempo | 9,0 | 17,0 |
| Imperator | Nahes Umlaufen | 13,7 | 15,4 |
| Imperator | Mittleres Umlaufen | 9,8 | 12,2 |
| Imperator | Mittleres Umlaufen, +30 % Tempo | 11,1 | 13,2 |

Beim Prinzen steigen die Treffer beim schnellen Umlaufen um rund **89 %**,
der aufsummierte HP-Verlust von 376 auf 862. Auf mittlere Distanz mit Grundtempo
sinken die Treffer dagegen um rund 16 %, der HP-Verlust von 725 auf 569.
Das ist eine Veränderung des Gefahrenprofils, keine Verstärkung aller Varianten.
Beim Imperator steigen die drei bewegten Hell-Varianten um rund **13–25 %**;
seine Bewegung bei mittlerem Umlaufen steigt von 1.311 auf 1.954 px / 45 s,
beim schnellen Umlaufen von 1.309 auf 3.085 px.

**Schwierigkeitsskalierung beim schnellen Umlaufen**, Treffer vorher → nachher:

| Boss | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Prinz | 2,7 → 2,6 | 2,6 → 5,1 | 6,1 → 8,4 | 9,0 → 17,0 |
| Imperator | 4,8 → 5,6 | 6,7 → 8,3 | 8,7 → 11,0 | 11,1 → 13,2 |

Auf Easy bleibt der Prinz in diesem Szenario weitgehend unverändert, auf den
höheren Stufen wächst der zusätzliche Druck. Die Imperatorwerte steigen hier
gleichmäßig über die vier Stufen. Andere Laufmuster haben andere Verhältnisse.

**Tötungszeit auf Hell**, stationär, unbegrenzte Angriffsreichweite,
zehn kontrollierte Treffer/s, native Rüstung und Gesundheitsphasen:

| Boss | Roh-DPS | Vorher | Nachher |
| --- | ---: | ---: | ---: |
| Prinz | 350 | 23,4 s | 23,4 s |
| Prinz | 1.000 | 23,4 s | 23,4 s |
| Imperator | 1.000 | 64,7 s | 60,3 s |
| Imperator | 3.000 | 46,9 s | 46,9 s |

Die minimalen Kampfzeiten bleiben erhalten. Häufigerer Nerventakt erzeugt
zusätzliche offene Kernzeit und kann bei mittlerem DPS die Imperatorzeit
verkürzen. Der Umbau erhöht seine Aktivität, nicht seinen HP-Vorrat.

## Prüfung

15 betroffene Tests (`boss_*`, `acid_king*`, `caramel*`, `prince*`, `crown*`,
`royal_boss_pressure`) bestanden. Der zusätzliche Test prüft insbesondere:

- Vollständige, feste Bomben-/Fächer- und Urteil-/Portalwarnungen; Freigabe erst
  danach und Weitergabe an den nächsten Bewegungs-/Angriffszustand.
- **144 langsame Pfützen-/Fächer-Eckfälle**: vier Stufen, drei Gesundheitsphasen,
  vier Ecken, Desktop und zwei mobile Formate. Die gesamte geprüfte Bewegung
  ist auf 72 % Grundtempo begrenzt, auch nach Verlassen der Pfütze.
- **216 langsame Urteil-/Portal-Eckfälle**: alle verfügbaren Kombophasen,
  vier Ecken, drei Formate und zwei Urteilzyklen. Beide angekündigten
  Mechaniken und ihre ausfliegenden Geschosse werden gemeinsam geprüft.
- Tatsächliche neue Kombofreigaben vor dem Boss-Tod auf Hard/Hell mit gesättigtem
  Spielerschaden und echten Gesundheitsphasen; keine alleinige Bewertung
  künstlich festgehaltener Gesundheitsphasen.
- In-Memory-Snapshots sowie drei echte Szenen-Neuladungen: ausstehender Fächer
  mit Pfützen, gemeinsame Portalwarnung und Neupositionierung mit fliegender Lanze.
- Längere bereits angekündigte Altfolgen und alte Urteilwarnungen ohne Komboflag.

Die Ecktests belegen erreichbare Wege für die konstruierten gewarnten Ereignisse.
Sie prüfen keine komplette Welle mit allen vorherigen Salven und normalen Gegnern.
Die bestehenden Tests für Projektilbudgets, gemeinsame Reservierungen, Pause,
Phasenabbrüche, Tod, alte Saves und langsame Einzelangriffe bleiben grün.

Native Sichtprüfung: Bomben-/Fächer-Übergang und gemeinsame Urteil-/Portalwarnung
bei 1280×720; Portalwarnung zusätzlich bei 320×568 und 568×320. Die gemalten
Grafiken bleiben erhalten. Ein menschlicher Hell-Run mit echtem Build und
Gegnerdichte bleibt für das abschließende Spielgefühl sinnvoll.

## Reproduzieren

Mit isoliertem `APPDATA`/`XDG_DATA_HOME` wie im [Bossvergleich](BOSS_COMPARISON.md):

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_boss_comparison.gd -- --royals-only
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter 'boss_*' --filter 'acid_king*' --filter 'caramel*' --filter 'prince*' --filter 'crown*' --filter 'royal_boss_pressure'
```

`--royals-only` schreibt ausschließlich `docs/royals_pressure_after.json`.
Mit zusätzlichem `--quick` entsteht `.godot/royals_pressure_quick.json`.
Der normale vollständige Lauf schreibt nach `docs/boss_comparison_current.json`;
die ursprüngliche Referenz und die Königsnachmessung werden nicht überschrieben.
