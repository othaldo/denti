# König: Säurefächer und Stampfketten

Stand: 31.10.2026. Aktueller Ausbau nach [BOSS_AGGRESSION.md](BOSS_AGGRESSION.md).
Ziel: Die Säurebahnen mit aktiven Angriffen verbinden und nach einem Ausweichmanöver nachsetzen.

## Ablauf

- Nach jeder Aktivierung der Säurebahnen erfasst der König Denti erneut. Ein grüner Säurefächer kündigt seine einzelnen Flugrichtungen 0,75 s lang an; danach fliegen gemalte Säuretropfen. Das gilt auch nach jedem Pegelwechsel.
- Vorhalt: 0,50 s, maximal 120 px. Ursprung und Richtungen bleiben während der Warnung fest. Ausweichen oder Richtungswechsel funktionieren; die Geschosse verfolgen Denti nicht.
- Die Warnung liegt innerhalb der bestehenden Flusszeit. Die Kombination wartet dadurch nicht länger auf ihren ersten Stampf.
- Auf Hard und Hell folgt auf eine Stampffolge ein kurzes Nachsetzen von 0,32 s. Danach erfasst der König Denti neu und kündigt die zweite Folge vollständig an: 1,0 s beim Einzelstampf, 1,4 s beim Stampf mit Säurebahnen.
- Vor dem zweiten Stampf läuft die zusätzliche Parallelbahn innerhalb von 0,30 s ab. Eine Bahn bleibt bis zum Rückruf aktiv. Das öffnet ein Ufer, während alte Splitter und der neue Stampf weiter Druck machen.
- Neue automatische Angriffszyklen beginnen erst innerhalb von 330 px Abstand und im sichtbaren Bereich. Der König nähert sich vorher an.

Basisleben bleiben bei 900; Trefferstärke und Schutzmechanik ändern sich nicht.

## Schwierigkeit

| | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Tropfen je Fächer | 3 | 5 | 7 | 9 |
| Tropfentempo, px/s (gerundet) | 333 | 370 | 414 | 474 |
| Vorwarnung Fächer | 0,75 s | 0,75 s | 0,75 s | 0,75 s |
| Stampffolgen je Stampfangriff | 1 | 1 | 2 | 2 |

Die übrigen Schwierigkeitsregeln bleiben wirksam: Zahl der Reihen, Splitter, Pegelwechsel, Bewegung und Pausen. Zwischen benachbarten Fächerrichtungen liegen 0,18 rad. Tropfen leben höchstens 1,35 s, haben Radius 9 px und verursachen 40 % des Angriffsschadens. Vorhandene Unverwundbarkeitsfenster gelten weiter.

## Messung

[Vorher](king_assault_before.json) / [Nachher](king_assault_after.json): echter Welle-15-Encounter, alle vier Stufen, drei Gesundheitsphasen, drei Startwinkel, vier Bewegungsstrategien. Insgesamt 144 Druckproben à 45 s und 20 getrennte Kampfdauerproben je Stand. Gleiche Methode und Ausgangswerte wie im bestehenden Bossvergleich. Keine Waffen oder Adds, normale Treffer-Unverwundbarkeit, kein Dash und kein bewusstes Reagieren auf Warnungen.

Angriffsaktionen zählen Bahnenaktivierungen und Projektile/Stampfreihen-Freigaben; sie sind keine Treffer. Projektile zählen Tropfen und Steinsplitter zusammen. Werte über alle Phasen, Startwinkel und Bewegungsstrategien gemittelt.

| Stufe | Angriffsaktionen vorher → nachher / 45 s | Projektile vorher → nachher / 45 s | Höchstens gleichzeitig gemessen |
| --- | ---: | ---: | ---: |
| Easy | 18,0 → 24,7 | 45 → 65 | 15 |
| Normal | 26,3 → 32,7 | 111 → 143 | 28 |
| Hard | 29,0 → 47,3 | 161 → 316 | 45 |
| Hell | 32,3 → 53,3 | 230 → 446 | 66 |

| Hell: Strategie | Treffer vorher / 45 s | Treffer nachher / 45 s |
| --- | ---: | ---: |
| Stehen | 31,7 | 38,0 |
| Nah kreisen, 160 px | 17,9 | 17,1 |
| Auf Abstand kreisen, 320 px | 19,8 | 22,9 |
| Schnell kreisen, 320 px | 22,3 | 30,0 |

Der Ausbau erhöht auf Hell besonders den Druck gegen Kreisen auf Abstand. Er macht nicht jede Route schwerer: enges Kreisen bleibt ähnlich wirksam; auf Hard funktionieren mehrere Kreisbahnen besser als zuvor. Die zweite Stampfkette bindet den König länger an angekündigte Richtungen. Trefferzahlen sind keine menschlichen Siegquoten oder allgemeine Rangfolge der Schwierigkeit.

Bei gesättigtem Schaden bleibt die Mindestkampfdauer etwa 25,2–25,3 s. Die Schutzmechanik lässt die Angriffe weiter stattfinden. Niedrigere DPS können durch die längere Stampfkette etwas länger benötigen; die Rohdaten enthalten auch den bei 90 s abgebrochenen Hell-Versuch.

## Darstellung, Grenzen und Speichern

Warnungen verwenden denselben analytisch geglätteten Renderer wie andere Gegnerangriffe. Keine zusätzlichen Kreise an Bahnenden. Vorhandener gemalter Säuretropfen aus dem König-Atlas; kein neues Bitmap. Ein zusätzlicher begrenzter Projektilbatch pro König, keine Nodes pro Geschoss. Höchstens 24 Tropfen und 96 Steinsplitter, gemeinsame Begrenzung auf zwei Säurebahnen; im Vergleich bleiben maximal 66 Geschosse gleichzeitig sichtbar. Doppel-Könige reservieren auch den neuen Fächer gegeneinander.

Speicherversion 2 ergänzt Ursprung/Richtungen, fliegende Tropfen und Stampfindex. Version-1-Spielstände beenden ihre bereits angekündigte einzelne Stampffolge ohne zusätzliche Folge. Phasenwechsel und Tod räumen beide Projektilbatches und sämtliche Warnungen auf.

## Prüfung

- `king_assault`: alle Stufen, vollständige feste Warnungen, Vorhalt, Nachsetzen und erneutes Zielen, Geburt von Projektilen in langen Frames, Snapshot und echtes Fortsetzen, alte Spielstände, Abbruch bei Phase/Tod.
- `king_assault_routes`: 112 vollständige warnungsabhängige Ausweichrouten in allen vier Ecken und drei Ansichtsformaten bei 72 % Basistempo, einschließlich ganzer Pegelwechselketten. Reale Trefferprüfung einschließlich verbleibender Projektile und Körperabstand; neue Warnungen und Nachsetzphasen erlauben Richtungswechsel.
- Bestehende Königs-, Boss-, Endlos- und Bahnendenprüfungen bleiben relevant.
- `tools/preview_king_assault.gd`: native Hell-Aufnahmen von [Fächerwarnung](screenshots/king_assault/fan_warning.png), [Freigabe](screenshots/king_assault/fan_release.png) und [zweitem Stampf](screenshots/king_assault/second_stomp.png), inklusive eingefrorener Pausengeometrie.

Abschließender Lauf: 11/11 Testskripte bestanden, 133 s. Bericht unter `.godot/test_runs/20261031-133646-62c1e724/`. Godot-Import und native Vorschau ohne Skriptfehler. Die bestehende zusätzliche Königsprüfung deckt weiterhin 168 verlangsamte Ufer-/Stampfrouten ab.
