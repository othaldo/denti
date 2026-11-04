# Interdental-Bürste: verlässlicher Rundumschnitt auf Hell

04.11.2026 · Reaktion auf das Feedback, mit der Bürste auf Hell kaum kämpfen
zu können. Der ältere Vergleich mit fertig ausgebauten Builds beantwortete den
tatsächlich verdienten Weg durch die Wellen nicht ausreichend.

## Änderungen

| Wert | Vorher | Jetzt |
| --- | --- | --- |
| Grundschaden Mk I | 6 | 8 |
| Nahkampfskalierung | 25 % | 35 % |
| Reichweite Mk I–IV | 82 / 88 / 94 / 102 | 100 / 110 / 120 / 130 |

Grundschaden steigt um 33 %, der Beitrag von Nahschaden um 40 %. Die bisherigen
Mk-Schadensfaktoren bleiben erhalten. Pause, Preis, Wurzelkosten, Rückstoß,
Blutung und Verzauberungsregeln ändern sich nicht. Die Verbesserung gilt auf
allen Schwierigkeitsgraden.

Hinzu kommt ein echter Kontaktfehler: Ein sehr naher Gegner zog bisher den
gesamten Schwung nach innen. Eine Mk-IV-Bürste konnte dadurch ein Ziel in ihrer
angegebenen Reichweite verfehlen, sobald ein weiteres Ziel 35 Pixel entfernt war.
Das war besonders bei mehreren unterschiedlich nahen Gegnern unzuverlässig.

Die Bürste schwingt jetzt von einem festen inneren Griffradius von 12 Pixeln
bis zur tatsächlichen Reichweite. Die gemalte Waffe wächst während des
Ausholens proportional; Darstellung und Kollisionssegment stimmen überein.
Nahe und äußere Gegner können im selben Schwung getroffen werden. Es bleibt
bei sichtbarem Klingenkontakt nach dem Windup und höchstens einem Treffer je
Ziel und Angriff. Andere Waffen behalten ihre bisherige Bewegung.

Zusätzliche Reichweite aus Waffenrollen oder Verzauberungen darf ebenfalls
keine Lücken zwischen Kollisionsproben erzeugen. Der Bürstenschwung passt seine
Winkelschritte deshalb an Reichweite und Zielgröße an. Das ist auch bei einem
großen Simulationsschritt und bei normalen 60-Hz-Schritten geprüft.

## Verdienter Hell-Einstieg

Neun identische Seeds je Waffe vor und nach dem Patch, W1–5 mit einem echten
Starter, endlichen HP, gesammelter Beute, bezahlten Angeboten und getragenem
Lebensverlust. Der `hunt`-Pilot sucht Gegner aktiv auf, verwendet aber weder
Dash noch bewusste Warnreaktionen. Drei zusätzliche Normal-Seeds und die
kleine reine Reichweitenkorrektur wurden zuvor separat untersucht.

| Hell, neun Seeds | Boss erreicht vorher → jetzt | Boss besiegt vorher → jetzt |
| --- | ---: | ---: |
| Interdental-Bürste | 5/9 → 9/9 | 2/9 → 2/9 |
| UV-Lampe als unveränderte Kontrolle | 8/9 → 8/9 | 6/9 → 6/9 |

Die Bürste bringt den einfachen Pilot damit zuverlässiger durch die normalen
Wellen, ersetzt aber kein Ausweichen im Bosskampf. Die Zahl seiner Boss-Siege
steigt in diesen neun Seeds nicht. Auf Normal besiegt die neue Bürste den
ersten Boss in 9/9 Proben.

Über die **fünf gleichen Seeds**, die vor und nach dem Patch den Boss erreichen,
steigt das mediane Startleben von **43,5 auf 82,8 %**. Der Vergleich aller
Bossankünfte hätte unterschiedliche Nenner: fünf alte und neun neue Läufe.
Über **32 paarweise vollständig überstandene W1–4-Fenster**:

| Summe über gleiche vollständige Wellen | Vorher | Jetzt |
| --- | ---: | ---: |
| Erlittener Schaden | 688,8 | 337,6 |
| Kills | 2.442 | 2.490 |
| Gold | 2.093 | 2.091 |
| XP | 1.952 | 2.023 |

Weniger Schaden und mehr sichere Angriffszeit sind der wesentliche Gewinn.
Die Änderung erzeugt in diesem Vergleich keinen zusätzlichen Goldschub.
Die neun Hell-UV-Kontrollen behalten exakt dieselben Endpunkte für Ausgang,
Welle, Kills, Gold, XP, Level und Kapseln.

## Bots mit Warnreaktionen

Je drei gleiche Hell-Seeds pro Pilot und Waffe, echte Dash-Kosten und die
bezahlte `synergy`-Buildregel. Diese kleinen Proben erlauben bereits vor dem
Patch Bürsten-Siege; das widerlegt das menschliche Feedback zur Nutzbarkeit
nicht. Sie prüfen insbesondere, ob die neue Stärke beim aktiven Ausweichen
ankommt und die Bossmechanik weiter stattfindet.

| Bürste | Boss besiegt vorher → jetzt | Boss-TTK vorher → jetzt | Start-HP vorher → jetzt |
| --- | ---: | ---: | ---: |
| `regular` | 3/3 → 3/3 | 25,18 → 20,55 s | 73,1 → 68,2 % |
| `expert` | 3/3 → 3/3 | 22,12 → 19,58 s | 95,5 → 93,4 % |

Die Kämpfe werden kürzer, die HP bei Ankunft steigen bei diesen Piloten nicht.
Beide UV-Pilotkontrollen bleiben bei 3/3 Siegen und unveränderten Messwerten.
Es entstehen keine 2–5-Sekunden-Bosskills.

78 Vorher-/Nachher-Proben und sechs zusätzliche Proben nur mit dem Kontaktfix
sind im [Messbericht](interdental_hell_buff_measurements.json) dokumentiert:
Einzelresultate, Wellenwerte, Boss-Startausrüstung, Methoden und Hashes der
vollständigen lokalen Rohberichte bleiben nachvollziehbar. Die ältere
18-Proben-Untersuchung des vorherigen Chats und der erste Buff-Kandidat sind
keine zusätzlichen Ergebnisse des finalen Patches.

## Prüfung und Anspielen

`tests/interdental_brush.gd` prüft nahe und äußere kleine Ziele gleichzeitig,
alle Mk-Stufen und vier Richtungen, sechs-Waffen-Verkleinerung, sechs
Elementformen, +50 % Reichweite, sichtbare Klingenlänge, Windup, Reichweitenlimit,
Einmaltreffer und JSON-Save/Resume während des laufenden Schwungs.

Abschlussprüfung: **178/178 Kernprüfungen** in 303,12 Sekunden, **3/3 zusätzliche
Waffen-/Botprüfungen** (`weapon_roster`, `weapon_roster_dps`, `bot_comparison`)
und **50/50 Python-Tests** bestanden. Testberichte liegen unter
`.godot/test_runs/20261104-064105-681d5a7f/results.json` und
`.godot/test_runs/20261104-064528-402fcad6/results.json`.

Die native Vorschau zeigt Mk I, Mk IV und sechs Mk-IV-Bürsten in fünf echten
Angriffsphasen. Die Kontur und Dentis Gesicht bleiben lesbar; die größeren
Werkzeuge bewegen sich hinter dem Körper. Aufnahmen entstehen unter
`.godot/interdental_brush_preview/` mit isoliertem APPDATA:

```powershell
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tools/preview_interdental_brush.gd
python tools/run_tests.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --filter interdental_brush --filter weapon_motion --filter balance_first_pass
```

Für neue Einstiegsmessungen `tools/run_earned_progression.py` mit
`--builds interdental_brush,uv_lamp --difficulties normal,hell --movements hunt`
und den Seeds `13579,24680,112233,31415,27182,42424,77777,88888,99999` verwenden.
`tools/run_bot_comparison.py` ergänzt mit `--skills regular,expert
--strategies kite --build-policies synergy --difficulties hell` die reaktiven
Kontrollen. Historische Vorher-Messungen stammen aus Commit `5585cb0`;
erneutes Starten auf dem aktuellen Stand misst die neue Fassung.

Die Proben prüfen den Einstieg bis zum ersten Boss, keine vollständigen
Hell-Runs und keine menschlichen Siegchancen. Als nächster Spieltest zählt,
ob die Bürste auch beim manuellen Sammeln und Ausweichen zuverlässig wirkt
und wie sie sich mit späteren Eliten und Bossaufgaben spielt.
