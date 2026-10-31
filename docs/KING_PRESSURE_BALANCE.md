# König: mehr Druck beim Pegelwechsel

Neuester Stand vom 31.10.: [Weniger Leben und aggressivere Bosse](BOSS_AGGRESSION.md). Dieser Bericht bleibt als frühere Vergleichsmessung erhalten.

Stand: 30.10.2026, Godot 4.7.2. Erster Balancing-Schritt ausschließlich am König.
Graf, Prinz und Imperator blieben für diese Messung unverändert. Die danach
erfolgte [Überarbeitung von Prinz und Imperator](ROYAL_PRESSURE_BALANCE.md)
bewahrt diesen Königsstand.

## Änderung

Die bisherigen Pegelwechsel hielten an einem alten Zielanker fest. Ein umlaufender
Spieler konnte sich im Verlauf der Folge von den weiteren Rinnen entfernen.

Jetzt versiegt der alte Boden wie bisher nach 0,30 s. In einer zusätzlichen
0,45-s-Bewegung setzt der König nach, mit Zielabstand 190 px und einer nach
Schwierigkeit skalierten Geschwindigkeit. Erst danach zielt die nächste Rinne
auf Dentis aktuelle Position mit begrenztem Vorhalt: 0,30 s, höchstens 80 px.
Ab Normal wechselt beim Pegelwechsel die Rinnenachse.

Die neue Warnung dauert weiterhin volle 1,0 s. Ihre Geometrie wird beim Beginn
festgelegt; der König bewegt sich währenddessen nicht und verfolgt Denti mit
der angekündigten Bahn nicht weiter. Auch aktive Rinnen und Stampfreihen bleiben
an ihren angekündigten Weltpositionen.

Die vorhandene Rinnen-/Stampf-Kombination folgt ab der zweiten Gesundheitsphase
auf reguläre Rinnen und auf den letzten Pegelwechsel. Durch die kurze reguläre
Rinnenfolge kommt sie auch dann zum Einsatz, wenn ein starker Build lange
Pegelwechsel durch Gesundheitsphasen abbricht. Easy behält die Kombination erst in der letzten
Phase und die bisherige Rinnenachse. Einzelne Stampfer warnen weiterhin 1,0 s;
bei der Kombination sind es 1,4 s. Diese zusätzliche Zeit ermöglicht langsamen
Spielern auch am schmalen Arenarand den längeren Weg über das freie Ufer.
Die Warnungsdarstellung und gespeicherten Restzeiten verwenden dieselbe Dauer.
Es bleiben höchstens zwei Rinnen aktiv;
Projektilbudget, HP, Schadenswerte, Rüstung, Schadensschutz und Kern-Verwundbarkeit
sind unverändert.

## Vergleich unter gleichen Bedingungen

Vorher: Welle 15 aus [ursprünglichem Bossvergleich](boss_comparison.json).
Nachher: [144 Druckproben und 20 Tötungszeitproben](king_pressure_after.json),
mit denselben Schwierigkeiten, Gesundheitsphasen, Startwinkeln und Bewegungen.

45 Sekunden je Druckprobe, keine Spielerangriffe, Waffen, Items, Rüstung, Heilung,
Dash, Adds oder normalen Gegner. Spieler-Maximalleben 100 für reguläre
Treffer-Unverwundbarkeit; großes aktuelles Leben nur als Messvorrat. Feste
Gesundheitsphase 0/1/2 und drei Startwinkel, je neun Proben pro Tabellenzelle.
Die Kreispiloten reagieren nicht auf Warnungen. Der Zielabstand wird durch
Bewegungssteuerung angestrebt; es handelt sich nicht um einen festgehaltenen Boss.

Mittleres Umlaufen: Zielabstand 320 px, Bewegung 230 px/s.

| Schwierigkeit | Treffer vorher / 45 s | Treffer nachher / 45 s | Aufsummierter HP-Verlust vorher → nachher |
| --- | ---: | ---: | ---: |
| Easy | 3,3 | 2,9 | 74 → 64 |
| Normal | 5,3 | 5,8 | 147 → 159 |
| Hard | 6,0 | 9,1 | 250 → 387 |
| Hell | 9,7 | 13,7 | 533 → 729 |

Auf Hell steigt die Trefferhäufigkeit in diesem Szenario um rund **41 %**;
der Graf lag in derselben Ausgangsmessung bei 23,3 Treffern. Der zusätzliche
Druck wächst hier deutlich von Normal über Hard nach Hell. Die Zahlen sind
keine menschlichen Siegraten und kein Beweis gleichmäßiger Schwierigkeit für
alle Bewegungsarten.

Weitere Bewegungsvarianten auf Hell:

| Bewegung | Treffer vorher → nachher / 45 s | HP-Verlust vorher → nachher |
| --- | ---: | ---: |
| Stillstand | 30,3 → 36,0 | 1.672 → 1.988 |
| Nahes Umlaufen, Zielabstand 160 px | 11,0 → 13,7 | 646 → 924 |
| Mittleres Umlaufen, Zielabstand 320 px | 9,7 → 13,7 | 533 → 729 |
| Mittleres Umlaufen, +30 % Tempo | 6,6 → 17,1 | 365 → 935 |

Auf Hell wächst der Druck bei allen vier getesteten Bewegungen. Besonders
deutlich ist der Effekt beim schnellen Umlaufen: **rund 161 % mehr Treffer**.
Zusätzliches Tempo allein löst die neue Angriffsfolge für diesen Kreispiloten
nicht; Warnungen und Laufwege müssen berücksichtigt werden. Auf Hard steigt
die schnelle Variante von 8,0 auf 10,3 Treffer. Diese Zahlen bewerten den festen
Piloten, nicht die allgemeine Nützlichkeit von Bewegungstempo im echten Spiel.

## Kampfdauer

Stationärer Spieler mit unbegrenzter Angriffsreichweite, zehn kontrollierte
Treffer/s. Der native Schadensschutz, Rüstung, Gesundheitsphasen und Kernzustand
bleiben aktiv. Keine Aussage über die Reichweite realer Waffenbuilds.

| Roh-DPS auf Hell | Vorher | Nachher |
| --- | ---: | ---: |
| 120 | nach 90 s nicht besiegt | nach 90 s nicht besiegt |
| 350 | 42,0 s | 44,1 s |
| 1.000 | 28,8 s | 28,8 s |
| 3.000 | 28,8 s | 28,8 s |

Die zusätzliche Gefahr kommt aus der veränderten Zielwahl und Angriffskette.
Die minimale Kampfdauer bleibt auf allen vier Stufen bei rund 29 Sekunden.
Die längeren Fälle verschieben sich nur geringfügig durch das Timing offener
Kernfenster (auf Normal bei 120 DPS 67,7 → 68,8 s; auf Hell bei 350 DPS +2,1 s).

## Prüfung und Grenzen

- Alle zehn `acid_king*`-/`boss_*`-Tests bestanden. Der neue Test
  `acid_king_pressure` prüft erneutes Zielen, Stillstand während voller Warnung,
  angekündigte Treffergeometrie, den früheren Kombobeginn und tatsächliches
  Speichern/Laden mitten im Nachsetzen.
- Ein kompletter Kampf mit gesättigtem Spielerschaden auf allen vier Stufen
  bestätigt mindestens einen tatsächlichen kombinierten Stampf-Einschlag vor
  dem Tod. Es werden die echten Gesundheitsphasen und deren Abbrüche durchlaufen.
- **168 kombinierte Eck-/Uferkonstellationen**: alle vier Schwierigkeiten,
  verfügbare Kombophasen, vier Arenaecken, beide Rinnenausrichtungen und
  1280×720, 320×568 sowie 568×320.
  Von einem bereits sicheren Ufer existiert jeweils ein schadensfreier Weg
  bei 72 % Grundtempo, ohne Dash, ohne Körperdurchquerung, einschließlich der
  anschließend fliegenden Splitter. Dies belegt diese Konstellationen, nicht
  beliebige Überlagerungen einer vollständigen Welle.
- Die bisherigen Tests für langsame Eckrouten einzelner Angriffe, begrenzte
  Gefahren bei zwei Königen, Warnungs-/Projektil-Snapshots, Pause und alte Saves
  bleiben grün. Der neue Zustand wurde angehängt; bestehende Zustandsnummern
  behalten ihre Bedeutung.
- Native Sichtprüfung der kombinierten Warnung und des Pegelwechsels bei
  1280×720 sowie der Darstellung bei 320×568 und 568×320. Die ursprünglichen
  gemalten Grafiken werden weiterverwendet.

Noch offen bleibt ein menschlicher Hell-Test mit echtem Welle-15-Build und
normalen Gegnern. Insbesondere Heilung und Rüstung können die wahrgenommene
Gefahr weiter verändern. Die kontrollierte Messung zeigt einen deutlichen Effekt
auf den zuvor schwachen Bewegungsfall, ersetzt aber diesen Spieltest nicht.

## Reproduzieren

Mit isoliertem `APPDATA`/`XDG_DATA_HOME` wie im [Bossvergleich](BOSS_COMPARISON.md):

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_boss_comparison.gd -- --king-only
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter 'acid_king*' --filter 'boss_*'
```

`--king-only` schreibt ausschließlich `docs/king_pressure_after.json`; die
ursprünglichen Vergleichsdaten bleiben erhalten. Mit zusätzlichem `--quick`
entsteht ein kurzer Kontrolllauf in `.godot/king_pressure_quick.json`.
