# Gegnerwerte nach Schwierigkeit

Normal und Easy behalten ihre bisherigen HP-, Verteidigungs- und Tempokurven. Hard und Hell erhalten zusätzlich folgende Boni gegenüber Normal in derselben Welle (auch für Eliten und Bosse):

| Schwierigkeit | HP Welle 1 → 20 | Schadensreduktion zusätzlich | Bewegungstempo Welle 1 → 20 |
|---|---|---|---|
| Hard | +10 % → +35 % | +2 → +8 Prozentpunkte | +3 % → +10 % |
| Hell | +20 % → +70 % | +4 → +14 Prozentpunkte | +5 % → +18 % |

Mit `t = clamp((Welle - 1) / 19, 0, 1)` wird zwischen den Endpunkten über `(t + t²) / 2` interpoliert. Der zusätzliche Anstieg wird dadurch im Verlauf stärker. Die Endpunkte stehen in den DifficultyData-Ressourcen; HP und Bewegungstempo multiplizieren die vorhandenen gemeinsamen Wellenkurven. Verteidigung bedeutet allgemeine Schadensreduktion, keine zusätzliche Elementresistenz. Ihre Obergrenze beträgt mit den aktuellen Ressourcen 50 % auf Hard und 56 % auf Hell (Normal maximal 42 %).

Ab Welle 20 bleiben diese zusätzlichen Boni begrenzt. Die vorhandene Endlos-Skalierung läuft weiter. Dichte, Statusangriffe und Belohnungsfaktoren bleiben gegenüber dem vorherigen Stand unverändert. Die Zahlen sind ein erster Balanceansatz und benötigen Spieltests.

`tests/difficulty_levels.gd` prüft die tatsächlichen Gegnerwerte beim Konfigurieren, unverändertes Normal, die Rangfolge Normal < Hard < Hell, die Beschleunigung und Grenzen im Endlosmodus.

## Angriffsschaden

Kontakt- und Angriffsschaden verwenden ebenfalls die beschleunigende Kurve. Gegenüber Normal in derselben Welle steigt Hard von Faktor 1,08 auf 1,75 und Hell von 1,16 auf 2,50. Die ursprünglichen Startfaktoren bleiben erhalten; `enemy_damage_late_bonus` ergänzt bis Welle 20 zusätzlich 0,67 beziehungsweise 1,34. Normal und Easy behalten ihre bisherigen Schadenskurven. Gift-/Blutungsstatus behalten ihre separate Skalierung.

## Endlosmodus

Die Schwierigkeitsboni bleiben ab Welle 20 konstant, die gemeinsamen HP- und Schadenskurven wachsen jedoch unbegrenzt weiter. Für denselben Gegnertyp und Schwierigkeitsgrad, jeweils gegenüber Welle 20:

| Welle | HP-Faktor | Schadensfaktor |
|---|---|---|
| 30 | 3,475 | 2,10 |
| 40 | 15,175 | 7,30 |
| 50 | 53,3125 | 24,25 |

Bewegungstempo ist im Endlosmodus auf das 2,75-Fache des Welle-20-Tempos begrenzt, Spawn-Dichte auf Faktor 2. Verteidigung wächst nach Welle 20 nicht weiter. Diese Grenzen schützen Ausweichbarkeit und Performance; HP und Schaden sorgen weiterhin für steigende Schwierigkeit. Ab Welle 30 erscheinen alle zehn Wellen zwei Bosse.
