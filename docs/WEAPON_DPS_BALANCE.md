# Waffen-DPS und Nahkampf-Balance

Gemessen am 4. Oktober 2026 mit Godot 4.7.2. Alle 18 Waffen wurden auf allen vier Stufen vor und nach dem Pass mit echten Angriffen geprüft: 392 Fälle pro Stand. [Vorher](balance_weapon_dps_before.json), [nachher](balance_weapon_dps_after.json), [Bosskontrolle](balance_weapon_dps_bosses.json).

Anschließend wurde [Nass um Verlangsamung ergänzt](WET_STATUS.md). Der stationäre Durchsatz bleibt gleich; eine zusätzliche Bosskontrolle prüft die Auswirkung auf Bewegung und Begegnungen.

## Befund und Änderungen

Die Zauberbürste gewann durch zwei beziehungsweise drei Geschosse auf III/IV deutlich mehr als Waffen mit reiner Schadensfusion. Nahkampf verlor zusätzlich Reichweite und Angriffszeit beim Ausweichen, ohne durchgehend genug Schaden als Gegenleistung zu erhalten. Ein Vergleich nur pro Waffe übersieht allerdings die Wurzelkosten: ein Bohrer belegt eine, eine Zauberbürste zwei Wurzeln.

Der Pass verstärkt alle acht Nahwaffen mit Basis, Takt und/oder Stufenkurve. Einzelziel-Nahwaffen bekommen im stationären Test auf jeder Stufe mindestens 25 % mehr nachhaltigen Schaden pro Wurzel als die Zauberbürste. Rundum- und Frontbogenwaffen erhalten ihren Mehrwert vor allem durch Gruppenschaden. Dieses Minimum ist eine Regression-Grenze, keine gemessene Ausweichzeit oder garantierte Balance in jedem Run.

Karies-Fräse: 75 statt 55 % Schaden gegen normale Gegner, 12 statt 8 Basis und bessere Fusion; der Fokus bleibt auf +50 % begrenzt. Polierer und Fräse skalieren mit 45 statt 35 % Nahschaden, Interdental-Bürste mit 25 statt 20 %, Garotte mit 150 statt 120 %. Schnelle Flächenwaffen skalieren weiterhin vorsichtiger als schwere Schläge.

Die neun übrigen Fernwaffen erhalten Verbesserungen passend zu Reichweite, Fläche und Unterstützung. Wasser/Nass, Fluorid-Markierung, Durchschlag, Crit und Rückstoß behalten ihre Rollen. Zauberbürste, Reichweiten, Wurzelkosten, Preise und Gegnerwerte bleiben unverändert. Fünf vorhandene Evolutionen übernehmen die neuen Basiswerte, damit ihre normale Angriffsleistung beim Entwickeln erhalten bleibt.

## Einzelziel-DPS nach Waffenstufe

**Jede Zelle: vorher → nachher.** DPS pro Waffe, gegen einen normalen Gegner; Werte enthalten direkte Treffer, natürliche Waffen-Crits, Fokusaufbau und tatsächlich getickte Blutung. Gruppenschaden und Bossbonus stehen separat. Wurzeln müssen für faire Buildvergleiche berücksichtigt werden.

| Waffe | Wurzeln | I | II | III | IV |
| --- | ---: | ---: | ---: | ---: | ---: |
| Zauberbürste | 2 | 31,3 → 31,3 | 42,5 → 42,5 | 82,2 → 82,2 | 141,1 → 141,1 |
| Turbo-Bohrer | 1 | 30,8 → 44,8 | 44,2 → 66,6 | 62,7 → 100,1 | 85,8 → 145,9 |
| Zahnseidenpeitsche | 1 | 17,2 → 25,0 | 22,0 → 34,6 | 27,4 → 47,3 | 34,7 → 63,7 |
| Wasserflosser | 1 | 19,2 → 25,3 | 24,8 → 36,6 | 33,0 → 52,2 | 43,9 → 80,1 |
| Kronenwerfer | 2 | 24,2 → 32,0 | 32,4 → 46,7 | 45,1 → 72,0 | 60,1 → 112,1 |
| Schmelzspiegel | 1 | 22,0 → 28,6 | 30,7 → 42,5 | 44,9 → 64,1 | 60,3 → 94,6 |
| Zahnsteinkratzer | 1 | 26,5 → 38,6 | 35,6 → 55,9 | 48,5 → 77,9 | 64,0 → 109,6 |
| Mundspülungs-Mörser | 2 | 19,5 → 26,4 | 26,0 → 37,3 | 35,6 → 54,7 | 49,2 → 84,2 |
| Zahnstocher-Speer | 1 | 24,2 → 34,5 | 33,4 → 51,0 | 45,6 → 70,9 | 60,1 → 100,3 |
| Karies-Fräse | 2 | 31,0 → 63,5 | 41,8 → 95,8 | 56,6 → 145,7 | 76,3 → 217,7 |
| Interdental-Bürste | 1 | 19,9 → 28,2 | 25,6 → 39,3 | 32,1 → 55,0 | 40,4 → 77,4 |
| Fluorid-Sprüher | 2 | 19,4 → 27,2 | 25,7 → 38,9 | 34,2 → 55,6 | 45,3 → 80,1 |
| Mundduschen-Turbine | 2 | 9,9 → 19,6 | 13,0 → 27,7 | 16,2 → 38,6 | 20,9 → 57,4 |
| UV-Lampe | 2 | 23,8 → 32,2 | 33,9 → 51,0 | 46,7 → 75,6 | 61,9 → 113,7 |
| Amalgam-Schleuder | 1 | 19,2 → 25,2 | 26,0 → 37,9 | 35,6 → 56,4 | 48,7 → 80,6 |
| Zahnseiden-Garotte | 2 | 31,0 → 47,1 | 38,4 → 66,5 | 49,0 → 91,9 | 61,0 → 129,4 |
| Prophylaxe-Polierer | 1 | 25,4 → 42,5 | 34,2 → 63,2 | 47,6 → 91,2 | 63,2 → 128,8 |
| Fluorid-Rakete | 2 | 24,2 → 31,5 | 31,4 → 44,1 | 43,1 → 67,7 | 57,5 → 104,9 |

## Stufe IV: Rolle und Wurzelkosten

Alle Werte nach dem Pass und **pro Wurzel**. Gruppe = fünf Gegner im Frontfächer; Linie = fünf hintereinander auf der von Denti ausgehenden Linie. Der tatsächliche Laufwinkel von Geschossen und Strahlen kann sich von dieser Linie unterscheiden; Durchschlag ist deshalb kein garantierter Fünffach-Multiplikator. Rundumwaffen können mehr Richtungen abdecken, als diese Frontgruppe zeigt.

| Waffe | Einzelziel | Frontgruppe | Linie | Boss ohne Schutz |
| --- | ---: | ---: | ---: | ---: | ---: |
| Zauberbürste | 70,6 | 69,3 | 70,6 | 71,2 |
| Turbo-Bohrer | 145,9 | 143,5 | 143,5 | 202,6 |
| Zahnseidenpeitsche | 63,7 | 318,3 | 318,3 | 62,9 |
| Wasserflosser | 80,1 | 80,6 | 80,6 | 80,1 |
| Kronenwerfer | 56,1 | 56,1 | 56,1 | 55,1 |
| Schmelzspiegel | 94,6 | 94,6 | 94,6 | 93,4 |
| Zahnsteinkratzer | 109,6 | 109,6 | 110,9 | 110,2 |
| Mundspülungs-Mörser | 42,1 | 168,5 | 84,2 | 41,3 |
| Zahnstocher-Speer | 100,3 | 100,3 | 501,7 | 101,5 |
| Karies-Fräse | 108,8 | 108,3 | 108,3 | 217,2 |
| Interdental-Bürste | 77,4 | 385,8 | 385,8 | 77,2 |
| Fluorid-Sprüher | 40,0 | 159,0 | 79,5 | 39,9 |
| Mundduschen-Turbine | 28,7 | 86,1 | 57,4 | 28,8 |
| UV-Lampe | 56,8 | 54,8 | 109,6 | 50,8 |
| Amalgam-Schleuder | 80,6 | 241,9 | 127,3 | 79,4 |
| Zahnseiden-Garotte | 64,7 | 323,6 | 194,2 | 63,8 |
| Prophylaxe-Polierer | 128,8 | 128,3 | 128,3 | 127,9 |
| Fluorid-Rakete | 52,4 | 203,0 | 101,5 | 52,4 |

## Messmethode und Grenzen

- 30 simulierte Sekunden bei 60 Hz, Seed 13579 je Fall, eine Waffe und frische Zielzustände. Startstats mit 5 % Crit, keine Items oder Relikte.
- Normales Einzelziel bei 65 % der jeweiligen Waffenreichweite; zusätzlich Nahdistanz 45 px, Frontgruppe, Linie und Boss. Kontaktwaffen außerdem an ihrer vollen Reichweite.
- Unsterbliche Ziele beginnen bei 50 % HP. Dadurch wird der +15-%-Schnittbonus gegen frische Gegner nicht als dauerhafter Bonus gezählt.
- Echte Kontaktbewegung, Projektilflug, natürliche Crits, Fokus und Blutung. Direkter Schaden und Blutung stehen getrennt in JSON. Jeder Treffer läuft durch die bestehenden Item-Signale.
- Ziele stehen fest und werden nach Rückstoß wieder an ihre Ausgangspunkte gesetzt. Gegner-KI, Rüstung und Boss-Schutz sind in diesen Durchsatzmessungen abgeschaltet. Schadensverlust beim Ausweichen, bewegte Trefferziele, Killrate und Winrate werden hier nicht gemessen.
- Die bisherige Shop-DPS bleibt eine direkte Schätzung: Blutung, Fokus, Flächentreffer und situative Synergien kommen zusätzlich dazu. Die drei Bürstengeschosse treffen dieses Einzelziel auf IV, können bei kleineren oder weiter entfernten Zielen aber vorbeifliegen.

Reproduktion der aktuellen Matrix:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_weapon_dps.gd
```

Die Vorher-Datei wurde vor dem Ressourcenumbau aufgenommen; `-- --before` schreibt einen neuen Snapshot des jeweils ausgecheckten Standes unter diesem Namen.

## Bosskontrolle

Zusätzlich wurde der vorhandene gemischte Sechs-Wurzel-Build gegen echte Bosse geprüft. Spieler steht still mit 1.000.000 HP, Boss-KI, Adds und Schutzphasen laufen. Profile wie im historischen [Schadensbericht](DAMAGE_DEFENSE_BALANCE.md). Dies ist ein kontrollierter Beispielbuild, keine allgemeine TTK-Prognose.

| Welle | Zeit bis null Boss-HP | Phasenwechsel |
| ---: | ---: | ---: |
| 5 | 18,2 s | 2 |
| 10 | 23,6 s | 2 |
| 20 | 47,5 s | 2 |

Die Bossmechaniken bleiben in diesen Durchläufen wirksam; es entstehen keine 2–5-Sekunden-Kills. Schutzphasen begrenzen Spitzen, während zusätzlicher Waffenschaden auch Adds beseitigt. Daraus folgt keine Garantie für extreme spezialisierte Builds.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_damage_defense.gd -- --output=res://docs/balance_weapon_dps_bosses.json
```

## Automatisierte Prüfungen

`tests/weapon_dps_balance.gd` benutzt dieselbe echte Angriffssimulation: alle vier Stufen, Einzelziel-Nahkampfvorteil pro Wurzel, Gruppenleistung von Flächenwaffen, spürbare Fusionsschritte und kompatible Evolutions-Grundwerte. `weapon_motion` deckt jetzt auch die Interdental-Bürste in allen Richtungen/Stufen und mit sechs Waffen ab. Bestehende Prüfungen für Schadensmodell, Waffen, Items, Stats, Evolutionen, Shop, Save/Resume und Bosskampf ergänzen die Messung.

Dichte Wellen und spezialisierte Builds auf Hard/Hell benötigen weiter Spieltests; dieser Pass liefert den reproduzierbaren Ausgangspunkt.
