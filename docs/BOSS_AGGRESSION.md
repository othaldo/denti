# Kürzere und aktivere Bosskämpfe

Neuester Königsstand: [Säurefächer und Stampfketten](KING_ASSAULT.md). Die Königsmessungen unten liegen vor diesem Ausbau.

Neuester Prinzenstand: [Bombenfrequenz nach Schwierigkeit](PRINCE_BOMB_FREQUENCY.md) – Hell mit doppeltem Wurftakt innerhalb der Serie, weiterhin 1,1 s Vorwarnung je Bombe. Die älteren Messungen unten liegen vor dieser Taktänderung.

Stand: 31.10.2026. Prinz, König und Imperator; der Graf dient als unveränderte Referenz.

[Vorher](boss_aggression_before.json) · [Nachher](boss_aggression_after.json).

## Leben und Kampfdauer

| Boss | Basisleben vorher → nachher | Änderung | Schadensbudget-Zeitraum vorher → nachher | Gesundheitspause vorher → nachher |
| --- | ---: | ---: | ---: | ---: |
| Prinz | 900 → 750 | −16,7 % | 26 → 23 s | 1,9 → 1,6 s |
| König | 1.100 → 900 | −18,2 % | 32 → 28 s | 2,0 → 1,7 s |
| Imperator | 2.500 → 2.000 | −20,0 % | 52 → 40 s | 3,6 → 2,4 s |

Die gemeinsame Wellen-, Schwierigkeits- und Endlosskalierung multipliziert weiterhin diese Grundwerte. Die relative HP-Skalierung zwischen den vier Schwierigkeiten bleibt erhalten. Rüstung und Trefferschaden werden durch diese Änderung nicht erhöht.

Nur HP zu reduzieren würde die Mindestdauer bei sehr hohem DPS kaum ändern: Das Schadensbudget wächst proportional zum Maximalleben. Deshalb werden zusätzlich sein Zeitraum und die stillen Gesundheitsphasen verkürzt. Der Schutz besteht weiter; die Mechaniken bleiben auch gegen starke Builds relevant.

| Kontrollierte Hell-Messung | Vorher | Nachher |
| --- | ---: | ---: |
| Prinz, gesättigter Schaden | 23,4 s | 20,7 s |
| König, gesättigter Schaden | 28,8 s | 25,3 s |
| Imperator, gesättigter Schaden | 46,9 s | 36,1 s |
| König, 350 rohe DPS | 44,1 s | 36,5 s |
| Imperator, 1.000 rohe DPS | 58,4 s | 42,3 s |

Unbegrenzte Angriffsreichweite und zehn Treffer/s; keine echten Waffenbuilds. Nicht besiegte Proben nach 90 Sekunden sind ausdrücklich als zensiert markiert.

## Aktivität und Nachsetzen

- **Prinz:** schnelleres Aufschließen, Zielabstand 260 px, kürzere Erholung und Wurfpausen. Ab Normal bewegt er sich bereits während des Bombenfluges. Die Bombe behält ihren eigenen Startpunkt und ihr festgelegtes Ziel. Vor Fächern beträgt der Zielabstand 260/260/250/220 px auf Easy/Normal/Hard/Hell. Easy behält die ruhigeren einzelnen Wurfphasen.
- **König:** kürzere Fluss-, Rückruf- und Kernöffnungszeiten; weniger Warten zwischen Angriffen. Mehr Bewegung während des Flusses und erneutes Aufschließen nach 0,20 s Kernpause sowie in der Erholung. Die bereits angekündigten Rinnen und Stampfreihen bleiben ortsfest. Reguläre Warnungen dauern weiter 1,0 s, kombinierte Stampfer 1,4 s.
- **Imperator:** schnelleres Annähern, kürzere Positionierung, Erholung und Kernöffnung. Nach 0,25 s offenem Kern setzt er wieder nach. Er weicht einem nahen Denti nicht mehr gezielt auf 320 px aus. Die bestehende 300-px-Prüfung vor AoE, ihre Zielerfassung und die feste Warnfläche gelten weiter. Die Wachendrehung bleibt vollständig angekündigt.

| Erholung | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Prinz | 1,08 s | 0,90 s | 0,72 s | 0,495 s |
| König | 0,54 s | 0,45 s | 0,36 s | 0,2475 s |
| Imperator | 0,48 s | 0,40 s | 0,32 s | 0,22 s |

Die vorhandenen gemeinsamen Bewegungsfaktoren und profilspezifischen Mengen-/Kombostufen wirken zusätzlich. Prinzenfächer, Ansturm und Bombenlandung sowie sämtliche Hofurteile und Kombowarnungen behalten ihre vollständigen Reaktionszeiten. Während ihrer festgelegten Warnungen steht der jeweilige Boss weiterhin still. Offene Kerne bleiben verwundbar, auch wenn der Boss nach seiner kurzen Atempause wieder schwebt bzw. läuft.

## Vorher/Nachher unter denselben Bedingungen

Je Messstand 576 Druckproben und 80 Tötungszeitproben, alle vier Bosse und Schwierigkeiten. Druckproben: 45 s, drei feste Gesundheitsphasen, drei Startwinkel und vier Bewegungen. Kein Angriff auf den Boss, keine Adds, normalen Gegner, Rüstung, Heilung oder Dash. Normale Treffer-Unverwundbarkeit bleibt erhalten. Der Kreispilot liest keine Warnungen. Die Ergebnisse beschreiben die Reaktion auf diesen Piloten und keine menschlichen Siegraten.

**Warnungen je 45 s**, beim Umlaufen mit 230 px/s und angestrebten 320 px Abstand; Mittel über neun Proben:

| Boss | Easy vorher → nachher | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Prinz | 19.0 → 22.3 | 24.0 → 27.0 | 27.0 → 30.0 | 30.0 → 32.0 |
| König | 9.0 → 11.3 | 10.3 → 12.3 | 10.7 → 13.3 | 11.0 → 13.7 |
| Imperator | 18.3 → 22.3 | 21.0 → 24.3 | 23.0 → 25.0 | 24.0 → 27.0 |

Auf Hell steigen die Warnungen hier beim Prinzen um 7 %, beim König um 24 % und beim Imperator um 13 %. Prinz und König verkürzen zusätzlich die längsten gemessenen Abstände zwischen Freigaben: 2,32 → 2,03 s bzw. 5,14 → 3,93 s. Freigabeabstände sind für den Imperator nicht erfasst; er verwendet andere Ereigniszähler. Seine Warnungen und Geschosszahlen sind direkt gemessen.

| Hell: Treffer je 45 s | Prinz vorher → nachher | König | Imperator |
| --- | ---: | ---: | ---: |
| Nahes Umlaufen, Ziel 160 px | 15,3 → 16,0 | 13,7 → 17,9 | 9,0 → 12,2 |
| Mittleres Umlaufen, Ziel 320 px | 13,1 → 15,7 | 13,7 → 19,8 | 5,8 → 15,2 |
| Mittleres Umlaufen, +30 % Tempo | 17,0 → 15,1 | 17,1 → 22,3 | 12,0 → 10,1 |

Mehr Aktivität macht nicht jede Laufweise pauschal gefährlicher: Schnelles Umlaufen entschärft manche Prinzen- und Imperatormuster; auf Normal sinkt die Prinzen-Trefferzahl beim mittleren Umlaufen trotz mehr Bewegung/Warnungen von 7,1 auf 5,4. In der mittleren Laufprobe steigen die Treffer nach dem Umbau dennoch bei jedem der drei Bosse von Easy über Normal und Hard bis Hell. Der Graf bleibt in Ressourcen und sämtlichen gemessenen Referenzproben exakt gleich.

Der Imperator legt auf Hell bei mittlerem Umlaufen weniger Strecke zurück (2.964 → 2.183 px), weil er nähere Positionen hält. Beim nahen Umlaufen wächst die Zeit innerhalb von 160 px dagegen von 0 auf 59 %. Bewegung allein ist daher kein ausreichendes Maß für Aggressivität.

## Prüfung und native Ansicht

17 betroffene Boss-Testskripte sowie die beiden Endlos-Regel-/Ablauftests bestanden, einschließlich der neuen Bewegungsprüfung, aller vier Schwierigkeiten, Kampfdauer-Untergrenzen, tatsächlicher Kombotreffer bei Maximal-DPS, Belohnungsfluss, Ressourcenisolation, Warnungs-/Projektil-Snapshots und Fortsetzen. Die bestehenden 168 Königs-Komborouten und 216 Urteil-/Portalrouten bei 72 % Bewegungstempo bleiben erreichbar. Der einzelne Rinnen-Routentest endet nun an der nächsten vollständigen Stampfwarnung; deren Freigabe folgt durch den kürzeren Fluss inzwischen vor der früheren festen Vier-Sekunden-Grenze. Ganze Kombinationen werden weiterhin separat geprüft.

Die neue Prüfung boss_aggression deckt insbesondere Flugbewegung mit fester Bombenflugbahn, Erholungs-Atempause, zunehmendes Nachsetzen über alle vier Stufen und das Ende der Imperator-Flucht vor Nahkämpfern ab. Gefahrenbudgets bleiben begrenzt.

Native Hell-Ansichten: [Prinz](screenshots/boss_aggression/prince.png), [König](screenshots/boss_aggression/king.png), [Imperator](screenshots/boss_aggression/emperor.png). Auch Hoch- und Querformat der vorhandenen Vorschauwerkzeuge wurden neu erzeugt und auf Enginefehler geprüft.

Reproduzieren, mit isoliertem APPDATA unter .godot:

~~~powershell
godot --headless --path . --script tools/benchmark_boss_comparison.gd -- --output=res://.godot/boss_aggression_current.json
python tools/run_tests.py --godot GODOT_BINARY --filter 'boss_*' --filter 'acid_king*' --filter 'caramel*' --filter 'prince*' --filter 'crown_court*' --filter royal_boss_pressure
~~~

Die früheren Berichte BOSS_COMPARISON, KING_PRESSURE_BALANCE und ROYAL_PRESSURE_BALANCE bleiben als vorherige Entwicklungsstände erhalten. Echte Welle-10-/15-/20-Builds mit Adds und Dichte müssen weiterhin im Spiel beurteilt werden.
