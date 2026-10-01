# Tempo und Regeneration

Putzeifer und Bewegung sind additive Prozentboni mit 0 % als Startwert. Speichel zählt Regenerationspunkte statt direkter HP pro Sekunde. Alle drei Werte kommen aus `PlayerStats`; Level-ups, Items, Waffenanzeigen und das Testmenü verwenden dasselbe Modell.

| Level-up | Weiß | Blau | Violett | Gold |
| --- | ---: | ---: | ---: | ---: |
| Putzeifer | +5 % | +10 % | +15 % | +20 % |
| Bewegung | +3 % | +6 % | +9 % | +12 % |
| Speichel | +1 | +2 | +3 | +4 |

## Putzeifer

Positive Boni teilen die Waffenpause durch `1 + Putzeifer / 100`: +50 % bedeutet 1,5-mal so viele Angriffe, +100 % doppelt so viele. Zwei Boni von +10 % ergeben +20 %. Die alten festen Sekundenabzüge erreichten dagegen nach wenigen Aufstiegen die Mindestpause und wurden bis dahin mit jedem Bonus stärker.

Für negative Werte verlängern wir die Basis-Waffenpause um `abs(Putzeifer) / 100`; -100 % verdoppelt sie. Das ist eine vereinfachte Denti-Regel, keine Kopie der waffenspezifischen negativen Brotato-Formel. Waffenstufen behalten ihre eigenen Basispausen. Die tatsächliche Pause kann nie unter 0,05 Sekunden sinken; Waffenanzeige und DPS-Schätzung berücksichtigen diese Grenze ebenfalls.

Zuckerschock addiert vorübergehend +30 % Angriffstempo pro Exemplar (höchstens +50 %) zum permanenten Putzeifer. Das anschließende Zuckertief zieht 25 Prozentpunkte ab. Dadurch multipliziert der Rausch einen schnellen Build nicht zusätzlich.

## Bewegung

Das Grundtempo bleibt bei 230 Pixeln pro Sekunde: `230 * (1 + Bewegung / 100)`. +10 % ergibt 253, +20 % ergibt 276. Ein weißer Aufstieg erhöht das Tempo um 6,9 statt früher 25 Pixel/s; Gold um 27,6 statt 80. Positive Boni haben keine feste Obergrenze. Das effektive Mindesttempo bleibt 80 Pixel/s; der zugrundeliegende negative Bonus bleibt erhalten, damit Stapeln und spätere positive Boni unabhängig von der Reihenfolge wirken.

Minz-Essenz gibt +5 % Bewegung und -5 % Putzeifer. Metallkrone kostet 8 % Bewegung, Amalgamkern 5 %, Mundspülung 4 % und die übrigen bisherigen Tempo-Nachteile 3 % pro Exemplar. Mundspülung gibt +10 % Putzeifer; Implantat kostet 6 %.

## Speichel

Bei positiven Regenerationspunkten gilt `Sekunden pro HP = 11,25 / (Speichel + 1,25)`. Null und negative Punkte heilen nicht. Die Heilung erfolgt in einzelnen HP-Ticks, unabhängig vom maximalen Leben.

| Speichel | Abstand pro HP | Durchschnitt HP/s | Heilung in 60 s bei genug fehlendem Leben |
| ---: | ---: | ---: | ---: |
| 1 | 5,00 s | 0,20 | 12 HP |
| 2 | 3,46 s | 0,29 | 17 HP |
| 4 | 2,14 s | 0,47 | 28 HP |
| 10 | 1,00 s | 1,00 | 60 HP |
| 20 | 0,53 s | 1,89 | 113 HP |

Ein weißer Aufstieg liefert damit zunächst 0,20 statt 0,50 HP/s; Gold allein 0,47 statt 2,20 HP/s. Speichelquelle gibt +2 Regeneration statt +0,8 HP/s. Ihre Heilung nach acht Kills und die XP-Heilung des Zahnfee-Pakts bleiben eigenständige Itemeffekte. Passive Regeneration erzeugt keine Überheilung für den Speichelkelch und sammelt bei vollem Leben keine Heil-Ticks an.

Die Startwerte bleiben 100 HP, 0 Speichel und 0 % Tempo. Eine Änderung der HP-Skala würde auch Gegnerschaden, Rüstung, Heilitems und HP-Boni betreffen und wird separat beurteilt. Für einen neuen Balance-Test sind besonders verlorene HP pro Welle und die Erholung zwischen Treffern interessant; diese Formel allein bewertet noch nicht die Stärke von Kill- und XP-Heilbuilds.

## Bestehende Spielstände

Die Tempo-Umstellung wurde mit Stat-Modell Version 2 eingeführt; das aktuelle Schadensmodell ist [Version 3](DAMAGE_DEFENSE_BALANCE.md). Alte absolute Laufgeschwindigkeit und Angriffspause werden einmalig in entsprechende Prozentboni umgerechnet; ihr bestehendes Tempo bleibt erhalten. Alte HP/s werden mit Faktor 2 in Speichelpunkte umgewandelt (z. B. 5 HP/s → 10 Punkte → 1 HP/s). Das folgt dem Wechsel des weißen Aufstiegs von 0,5 HP/s auf 1 Punkt und schwächt bestehende Heilbuilds ebenfalls ab. Der damalige Mix aus Item- und Level-up-Beiträgen lässt sich aus dem alten Gesamtwert nicht exakt rekonstruieren.

Neue Spielstände bewahren auch den Fortschritt zum nächsten Heil-Tick. Bereits offene Putzeifer- und Bewegungsauswahlen aus alten Spielständen werden auf die neuen Stat-Namen und Werte ihrer Seltenheitsstufe übertragen.

Referenzen: [Brotato Attack Speed](https://brotato.wiki.spellsandguns.com/Attack_Speed), [Speed](https://brotato.wiki.spellsandguns.com/Speed), [HP Regeneration](https://brotato.wiki.spellsandguns.com/HP_Regeneration).
