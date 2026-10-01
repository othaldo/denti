# Schaden, Waffen und Rüstung

Gemessen am 1. Oktober 2026 mit Godot 4.7.2. Die vollständige Waffenmatrix und die Bossmessungen stehen in [den Messdaten](balance_damage_defense.json).

## Schadensmodell

`Trefferschaden = (Waffenbasis der Stufe + passender Nah-/Fernschaden * Waffenskalierung) * (1 + Schadensboni / 100)`.

Bisskraft gibt pro Aufstieg +4/8/12/16 %, Nahschaden +2/4/6/8 und Fernschaden +1/2/3/4. Alle drei starten bei null. Spezialwerte erscheinen in Level-up-Auswahlen, wenn eine ausgerüstete Waffe damit skaliert. Waffenkarte und Details nennen den verwendeten Stat und sein Gewicht. Bruchteile bleiben intern erhalten. Fusion erhöht die Waffenbasis, ohne zusätzlich den Beitrag der Nah-/Fernpunkte zu multiplizieren.

Bisskraft, Amalgamkern, Heiligenschein und die situativen Itemboni gegen Bosse, blutende oder nasse Ziele beziehungsweise beim Laufen werden in einem Prozentpool addiert. Crit, Ziel-Fokus und eigene Waffenmechaniken (Bohrer-Bossbonus, Fluorid-Markierung) bleiben getrennte Faktoren mit ihren bestehenden Grenzen. Trefferabhängige Folgeeffekte verwenden bereits berechneten Schaden und wenden Bisskraft nicht nochmals an. Keramiksplitter, Zahnblitze, Pfützen und Blutung erhalten Bisskraft einmal; Nah-/Fernschaden verstärken direkte Waffenangriffe. Ausgehender und eingehender Schaden bleiben auf mindestens 1 HP pro Treffer begrenzt.

Der bisherige Stat war bereits ein versteckter Multiplikator: `Waffenbasis * Bisskraft / 18`. Ein weißer Bonus von +5 entsprach +27,8 Prozentpunkten für alle Waffen. Prozentanzeigen allein hätten daran nichts geändert. Vergleich gleicher Anzahlen weißer Bisskraft-Aufstiege, ohne Items, Angriffstempo oder Spezialisierung:

| Weiße Aufstiege | Bisheriger Faktor | Neuer Faktor |
| ---: | ---: | ---: |
| 1 | 1,28 | 1,04 |
| 6 | 2,67 | 1,24 |
| 10 | 3,78 | 1,40 |

## Waffenskalierung

Die bisherigen Grundschäden und Stufenkurven aller 18 Waffen bleiben erhalten. Schwere Einzelangriffe erhalten stärkere Gewichte für rohe Punkte als schnelle Gruppenangriffe.

| Nahwaffe | Gewicht Nahschaden | Fernwaffe | Gewicht Fernschaden |
| --- | ---: | --- | ---: |
| Turbo-Bohrer | 150 % | Zauberbürste | 80 % |
| Zahnseidenpeitsche | 70 % | Wasserflosser | 35 % |
| Zahnsteinkratzer | 70 % | Kronenwerfer | 125 % |
| Zahnstocher-Speer | 100 % | Schmelzspiegel | 90 % |
| Karies-Fräse | 35 % | Mundspülungs-Mörser | 120 % |
| Interdental-Bürste | 20 % | Fluorid-Sprüher | 20 % |
| Zahnseiden-Garotte | 120 % | Mundduschen-Turbine | 15 % |
| Prophylaxe-Polierer | 35 % | UV-Lampe | 150 % |
| | | Amalgam-Schleuder | 100 % |
| | | Fluorid-Rakete | 160 % |

Beispiel: +2 Nahschaden ergänzt beim Bohrer 3 Basisschaden, bei der Interdental-Bürste 0,4. Bisskraft wirkt danach auf diesen gemeinsamen Grundwert. Ein Licht-Nahkämpfer wie der Polierer skaliert mit Nahschaden; ein kurzer Sprühkegel mit Fernschaden. Entscheidend ist die deklarierte Waffenfamilie, nicht die Schadensart oder Reichweite.

## Verteidigung

Positive Härte verwendet `Trefferfaktor = 1 / (1 + Rüstung / 15)`. Bei negativer Härte gilt `2 - 1 / (1 + abs(Rüstung) / 15)`. Die Level-up-Werte sind +1/2/3/4 Rüstung. Der 100-HP-Startwert bleibt bestehen. Schilde und Unverwundbarkeitsfenster verwenden weiterhin den tatsächlich erlittenen Schaden. Gegner-HP, Gegner-Rüstung und Bossphasen werden durch diese Änderung nicht erhöht.

| Rüstung | Schutz | Früher: 10-Schaden-Treffer | Jetzt: 10-Schaden-Treffer | Jetzt: 30-Schaden-Treffer |
| ---: | ---: | ---: | ---: | ---: |
| 0 | 0 % | 10 | 10 | 30 |
| 5 | 25 % | 5 | 7,5 | 22,5 |
| 10 | 40 % | 1 | 6 | 18 |
| 15 | 50 % | 1 | 5 | 15 |
| 30 | 66,7 % | 1 | 3,3 | 10 |
| -15 | 50 % mehr Schaden | 25 | 15 | 45 |

Die Prozentkurve verhindert, dass geringe Gegnerangriffe durch wenige Rüstungspunkte praktisch verschwinden. Sie bietet bei starken Einzelangriffen verlässlichen Schutz. Jeder positive Punkt erhöht die theoretischen effektiven HP um 6,67 %; 100 Leben mit 15 Rüstung entsprechen 200 effektiven HP, solange die Mindestschadensgrenze nicht greift.

## Gemessene Bosskämpfe

Reproduzierbar mit:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_damage_defense.gd
```

Die Simulation verwendet Zufallsstartwert 13579, 60 Physikschritte/s und sechs Hände: Zauberbürste, Turbo-Bohrer, Wasserflosser, Zahnstocher-Speer und Prophylaxe-Polierer. Denti steht still und hat zur Messung 1.000.000 HP. Items und Relikte fehlen; Bossbewegung, Angriffe, Adds und beide Phasenwechsel bleiben aktiv. Gemessen wird bis null Boss-HP, ohne Todesanimation. Dies sind Beispielbuilds, keine Schätzung eines durchschnittlichen Runs.

| Welle | Waffenstufe | Bisskraft | Nah / Fern | Putzeifer | Crit | Rüstung |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 | I | 12 % | 4 / 2 | 15 % | 10 % | 5 |
| 10 | II | 24 % | 8 / 4 | 25 % | 15 % | 10 |
| 20 | IV | 40 % | 12 / 6 | 40 % | 25 % | 15 |

| Welle | Boss-HP | Zeit bis null HP | Phasenwechsel | Erlittener Schaden ohne Ausweichen |
| ---: | ---: | ---: | ---: | ---: |
| 5 | 1560 | 18,2 s | 2 | 321 |
| 10 | 3087 | 23,6 s | 2 | 426 |
| 20 | 15325 | 46,9 s | 2 | 1385 |

Die Durchläufe dauern deutlich länger als 2–5 Sekunden, und beide Phasenwechsel kommen vor. Ohne Bewegung würde ein normaler 100-HP-Spieler in allen drei Messungen sterben. Die Waffenmatrix enthält direkten Einzelziel-DPS pro Hand, einschließlich Crit und der bisherigen Gewichtung zusätzlicher Geschosse; Blutung, Flächentreffer, Rückstoß, Nass-Synergien und voller Fokus sind zusätzliche Leistung. Sie ist daher keine Waffenrangliste.

Das prüft Schadensrechnung, Waffeninteraktion und Bossmechaniken. Dichte normale Wellen, reine Nah-/Fernbuilds, spezialisierte Itemkombinationen, Shopökonomie und Hard/Hell benötigen weitere Spieltests. Gewinnraten werden hier nicht gemessen.

## Spielstände und Tests

Stat-Modell Version 3 wandelt alte Bisskraft einmalig in `(alter Wert / 18 - 1) * 100` um: 42 entsprechen +133,3 %. Damit bleibt der vorhandene globale Waffen-Schadensfaktor erhalten. Nah-/Fernschaden starten in alten Spielständen bei null; gekaufte Itemstats werden nicht erneut vergeben. Alte offene Bisskraft-Auswahlen erhalten die neuen Prozentwerte ihrer bisherigen Seltenheitsstufe. Tempo-Version 2 behält Prozenttempo, Regenerationspunkte und Heil-Tick-Fortschritt. Rüstungspunkte behalten ihre Anzahl und verwenden die neue Schutzkurve.

Automatisierte Prüfungen decken additive Boni, negative Werte, Crit, alle Waffen und beide Spezialisierungen, Fusion, DPS-Schätzung und Anzeige, Rüstung, Schilde, Unverwundbarkeitsfenster, sinnvolle Level-up-Angebote und Migration einschließlich offener Auswahlen ab. F4-Wellenwechsel bewahren alle konfigurierten Stats.

Referenzen: [Damage](https://brotato.wiki.spellsandguns.com/Damage), [Melee Damage](https://brotato.wiki.spellsandguns.com/Melee_Damage), [Ranged Damage](https://brotato.wiki.spellsandguns.com/Ranged_Damage), [Armor](https://brotato.wiki.spellsandguns.com/Armor).
