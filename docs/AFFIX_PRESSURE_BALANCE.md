# Gegnerdruck nach Einführung der Affixe

Affixe liefern zusätzlichen Schaden neben den Shop-Rolls. Dieser Balanceschritt
hebt Haltbarkeit und Dichte moderat an und reduziert die Kistenchance pro Kill.

- Sechs normale Gegnertypen: Basis-HP +10 %, HP pro Welle und späte quadratische
  HP-Zuwächse jeweils +20 %. Die bisherigen unterschiedlichen Rollen bleiben erhalten.
- Der anfängliche HP-Faktor steigt von 0,35 auf 0,40 und läuft weiterhin weich
  bis Welle 10 auf 1,0 aus. Zusammen mit den Basis-HP sind das zu Beginn +25,7 %.
  Plaque startet mit 15,84 statt 12,6 HP; auf Welle 20 hat es 246,96 statt 208,8 HP.
- Normale Spawnintervalle ×0,84; auf Bosswellen ×0,92.
- Normale Bursts und geplante Horden ×1,15, auf ganze Gegner gerundet.
  Boss-Bursts und Elitegruppen behalten ihre bisherigen Größen.
- Normale Kistenchance: 2 % → 1,6 %. Mit 100 Glück: 5 % → 4 %.
- Elite-Kistenchance: 18 % → 16 %. Mit 100 Glück: 45 % → 40 %.
- Drei normale Kisten pro Welle bleiben das Limit. Goldene Träger behalten
  ihre Spawnchance und garantierte zusätzliche Kiste.

## Gemessene Spawn-Anfragen

60-Hz-Simulation mit Seed 9231 und identischen Hordenwellen 4/8/12/17. Enthalten
sind normaler Spawnstrom und Horden/Bursts, keine Elitegruppen/Begleiter. Das
Gegnerlimit und die tatsächliche Killrate können die realen Zahlen begrenzen.

| Welle | Vorher | Jetzt |
| --- | ---: | ---: |
| 1 | 44 | 53 |
| 4 | 80 | 94 |
| 8 | 116 | 136 |
| 12 | 199 | 233 |
| 19 | 255 | 294 |
| 20 | 188 | 204 |

Die Kombination aus Dichte und Dropchance ergibt auf normalen Wellen vor dem
Kistenlimit rechnerisch etwa 92–96 % der bisherigen Kistenausbeute, in Welle 1
etwa 96 %. Bei unverändertem Killtempo gilt diese Rechnung nicht: Kisten werden
pro tatsächlichem Kill gewürfelt. Glück und Affix-Auswahl bleiben relevant.

`tests/affix_pressure_balance.gd` prüft den Anstieg gegen die bisherigen Spawn-
und HP-Werte sowie die Kistenkompensation. `tests/mob_curve.gd` prüft zusätzlich
Rollenunterschiede, monotone Kurven, Startgegner und Boss-/Elite-Regeln.

Dieser Stand ist ein getesteter erster Balance-Schritt. Ein vollständiger
Spieltest mit starkem Affix-Build muss insbesondere Dichte, erlittenen Schaden,
Boss-TTK und Wirtschaft anhand der vorhandenen Run-Telemetrie bewerten.
