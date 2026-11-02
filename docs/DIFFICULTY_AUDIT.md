# Schwierigkeitsprüfung mit verdienten Vollruns

Stand: 02.11.2026. Geprüft wird der Stand nach den bisherigen Waffenbuffs,
Lebensraub- und Bossänderungen. Dieser Ausbau ändert **keine Waffen-, Gegner-,
Loot- oder Schwierigkeitswerte**. Er ergänzt durchgehende Messungen und korrigiert
die Erfassung der gemalten Bossprojektile. Die Bohrer-Gegenprobe deckte außerdem
einen echten Callback-Fehler auf: Gegenschaden kann den Prinzen während eines
Herztreffers töten und dessen Projektilarray während der Iteration löschen.
Herzen und allgemeine Bossbatches beenden eine so abgebrochene Verarbeitung nun
sicher. Ein Regressionstest deckt beide Batches ab; die vorher fehlerhafte
Bohrerprobe wird erst nach diesem Fix als gültige Messung übernommen.

Die bisherigen Ergebnisse rechtfertigen keinen pauschalen Gegneraufschlag auf
Easy oder Normal. Easy darf zugänglich bleiben. Auf Normal sollen Bewegung und
Buildentscheidungen zählen; ein gezielt gebauter starker Run darf Fehler
verzeihen. Das Alter eines Spielers ist dafür kein brauchbares Kriterium.

## Was tatsächlich simuliert wird

- W1–20 mit einer kostenlosen Mk-I-Startwaffe, endlichen HP, tatsächlichen
  Gegneranfragen, verdienten Leveln, Waffenpunkten und Gold.
- Der UV-/Schneide-Plan kauft zwei UV-Lampen und eine Zahnseiden-Schneide aus
  echten Angeboten für sechs Wurzeln. Fusionen kosten reguläres Gold. Er erhält
  weder freie Vollausrüstung noch garantierte Maximalränge.
- Nach Bosskills läuft der echte Wellentimer weiter. Anschließend folgen
  Beutesammlung, Aufstiege, Waffenverbesserungen, gegebenenfalls weitere
  Belohnungen, eine der tatsächlich angebotenen Relikte und der nächste Shop.
  W20 zählt erst nach dem wirklichen Abschluss als Sieg.
- Hordenplan und folgende Wellenprofile werden durch den Run getragen. Die
  vorab erzeugten Anfragen verhindern, dass verschiedene Killzahlen die nächste
  Spawnauswahl verändern. Das ist eine kontrollierte Diagnose, kein bitgenaues
  Replay eines menschlichen Runs.
- Verzögerte 1280×720-Beobachtung; aktuelle Warnungen aller vier Bosse und deren
  tatsächliche Projektile. Keine zukünftigen Spawns oder versteckten Zielpläne.
  Karamell-Verlangsamung wirkt real, wird aber noch nicht als eigene Wegkosten
  geplant. Die Piloten sind regelbasiert und nicht an Menschen kalibriert.

Details zu Profilen, Kaufregeln, Bedienung und Ausgabe:
[Testpiloten und Zeitraffer](BOT_SIMULATION.md).

## Warum die Einkaufsregel wichtig ist

Die erste Matrix enthält 72 geplante Vollruns: UV-/Schneide-Ziel, Easy/Normal,
Anfänger/Erfahren, Bossfokus/blinder Kreis, Element+Lebensraub/Zufall/ohne
Shopkäufe und je drei Seeds `101,202,303`. Kein Lauf gewinnt. Die stärksten
Element-/Lebensraub-Piloten kommen auf Normal jeweils bis W17, auf Easy bis
W17–18.

Das ist **kein Beleg für ausreichende Schwierigkeit**: Die bisherigen
Einkaufsregeln kaufen höchstens ein Item je Shop. Die erfahrenen Normal-Piloten
sterben hier mit 1.057–1.208 ungenutztem Gold und überwiegend mittleren
Verzauberungsrängen. Auch ein kompletter Shopverzicht ist ein strengerer
Kontrollfall als „gelegentlich Angebote ignoriert“.

Deshalb ergänzt `full_build` eine weitere Regel: Element/Lebensraub,
heuristische Levelwahl sowie alle bezahlbaren, positiv bewerteten Itemangebote
je Reroll. Stacklimits und höchstens vier bezahlte Rerolls bleiben bestehen.
Die Regel verändert sowohl Levelwahl als auch Einkaufsumfang; ihr Vergleich
isoliert daher nicht allein den Effekt zusätzlicher Itemkäufe. Sie sucht keinen
optimalen Build und nutzt keine zusätzlichen Budgets.

Mit den ersten drei Seeds gewinnt dieser gezielte Ausbau auf Easy mit beiden
Profilen jeweils 3/3, auf Normal mit Erfahren 3/3 und Anfänger 1/3. Die
erfahrenen Normal-Piloten erreichen dabei 917–1.026 maximale HP. Ihre Siege
zeigen einen stark ausgebauten Build, keine Unverwundbarkeit der Startwaffe.
Der letzte Boss braucht in diesen drei Normal-Läufen 36,3–38,0 Sekunden.

Die zusätzliche Gegenprobe verwendet drei frische Seeds, die beim Einrichten
der Heuristik nicht benutzt wurden:

| Grad | Profil mit `full_build` | Erste Seeds | Frische Seeds | Insgesamt |
| --- | --- | ---: | ---: | ---: |
| Easy | Anfänger | 3/3 | 3/3 | 6/6 |
| Easy | Erfahren | 3/3 | 3/3 | 6/6 |
| Normal | Anfänger | 1/3 | 2/3 | 3/6 |
| Normal | Erfahren | 3/3 | 3/3 | 6/6 |

Das ist ein brauchbarer Unterschied zwischen diesen konkreten Testregeln:
Easy verzeiht mehr, Normal reagiert stärker auf die Steuerung, und bewusster
Ausbau hilft erheblich. Sechs Seeds je Zeile sind weiterhin eine kleine
Stichprobe und keine menschliche Gewinnquote. Die natürliche W20-Siegfolge ist
damit zusätzlich zum künstlich verstärkten, reinen Ablauf-Test ausgeführt.

Als Nahkampf-Gegenprobe gewinnt der erfahrene Pilot mit sechs regulär gekauften
Bohrern und derselben Ausbau-Regel auf den Seeds `997,2027` jeweils 2/2 auf Easy
und Normal. Die letzten Normal-Bosse benötigen 37,5 bzw. 39,5 Sekunden. Vier
Bohrerläufe ersetzen keinen vollständigen Waffenvergleich, zeigen aber, dass der
Erfolg dieser Regel nicht auf den UV-/Schneide-Mix beschränkt ist.

## Maximalrang als separate Belastungsprobe

36 synthetische Kontrollen prüfen W19/W20 auf Normal mit UV/Schneide,
Feuer 10, optional Lebensraub 10, mit/ohne festem Shop-Paket sowie Kreisfahrt
oder Stillstand. Diese Checkpoints gewähren vorab definierte Ausrüstung;
sie sind ausdrücklich keine verdienten Runs und keine Gewinnquoten.

| Setup | W19 Kreisfahrt | W20 Kreisfahrt | Stillstand W19/W20 |
| --- | ---: | ---: | ---: |
| Feuer 10 + Shop-Paket | 0/3 | 0/3 | 0/6 |
| Feuer 10 + Lebensraub 10 + Shop-Paket | 3/3 | 3/3 | 0/6 |
| Feuer 10 + Lebensraub 10, ohne Shop-Paket | 0/3 | 0/3 | 0/6 |

Das feste Paket umfasst 24 Itemkäufe aus dem dokumentierten Standardzyklus
sowie die Checkpoint-Stats. „Ohne Shop-Paket“ behält dieselben vorgegebenen
Grundstats, aber keine Items. Beide Varianten bezahlen in dieser Probe ihre
Ausrüstung nicht aus einem vorausgehenden Run.

Mit vollem Paket und beiden Maximalrängen endet W19 im Median bei 89,6 % HP,
W20 bei 100 % HP. Dort werden im Median 377,4 Schaden vollständig ausgeheilt;
der Boss benötigt 54,8 Sekunden. Lebensraub ist damit weiterhin ein erheblicher
Buildbaustein. Dass derselbe Build im Stillstand scheitert und der Boss seine
Mechaniken ausspielen kann, liefert hier noch keinen ausreichenden Grund für
einen weiteren pauschalen Nerf. Die Zuverlässigkeit der Heilung bei menschlichen
Ausweichfehlern bleibt ein konkreter Playtest-Punkt.

## Reproduktion und Grenzen

```powershell
python tools/run_bot_comparison.py --weapons uv_lamp --loadout-plan uv_floss --skills novice,expert --strategies boss --build-policies full_build --difficulties easy,normal --seeds 101,202,303 --last-wave 20 --jobs 4 --output .godot/difficulty_full_build.json
```

Die erste, bewusst schwächere Matrix nutzt zusätzlich `--strategies orbit,boss`
und `--build-policies element_leech,random,no_shop`. Die frischen Gegenproben
verwenden die Seeds `997,2027,8191`; der Bohrer-Kontrolllauf startet mit
`--weapons turbo_drill --loadout-plan single` und Seeds `997,2027`.

Die Maximalrang-Kontrolle:

```powershell
python tools/run_build_comparison.py --controller max --builds uv_floss --modes element10,both10,bare_both10 --elements fire --movements orbit,stationary --waves 19,20 --seeds 101,202,303 --jobs 2 --output .godot/difficulty_max_sustain_baseline.json
```

Die [kompakten Messdaten](balance_difficulty_audit.json) behalten Quell- und
Eingabehashes, Konfigurationen, tatsächliche Endbuilds sowie Wellenwerte für
Einnahmen, Schaden, Heilung, Gegner- und Projektilspitzen. Die vollständigen
Worker- und Gesamtberichte bleiben lokal unter `.godot/`. Die erste Matrix und
die zusätzliche Einkaufsregel stammen aus getrennt gehashten Werkzeugständen;
Waffen-, Gegner- und Wirtschaftswerte bleiben zwischen ihnen gleich.

Insgesamt sind 100 geplante verdiente W1–20-Versuche und 36 synthetische
Kontrollen enthalten. Die vier Bohrerläufe stammen aus dem Stand mit
Callback-Fix. Ein zusätzlicher nativer 16×-Lauf stimmt bis einschließlich W6
bei Spawnplan, Kampfergebnissen und verdienten Zuständen mit dem entsprechenden
Headless-Präfix überein; nur zeitabhängige Waffeninstanz-UIDs werden beim
Vergleich entfernt. Physikrate bleibt 60 Hz, `Engine.time_scale` bleibt 1.

Prüfung: 50 Python-Tests, 165/165 Kerntests vor dem Callback-Fix und danach
6/6 gezielte Boss-/Botprüfungen sowie 10/10 weitere Boss-/Item-/Schadensprüfungen.
Der Integrationstest deckt Boss-Timer, echte Reliktwahl, Folgeshop, mitgenommene
HP/Ausrüstung und den tatsächlichen W20-Abschluss ab. Legitime
Wellenstart-Schilde aus gekauften Items werden dabei berücksichtigt.

Es gibt keine Altersklassifikation und kein Ziel, das jeden unerfahrenen Sieg
verhindern soll. Die Stichproben beurteilen nur diese Steuerungs- und
Buildregeln. Eine vollständige W1–20-Abnahme aller 18 Waffen, andere Elemente,
Klassen, Evolutionsziele und menschliches Spielgefühl sind damit nicht erledigt.
Insbesondere ist ein mit Reaktionsprofil und Ausweichheuristik gewonnener Run
kein Beleg dafür, dass man menschlich alle Warnungen ignorieren kann.

Vor einer weiteren Erhöhung des Gegnerdrucks brauchen wir einen aktuellen
menschlichen Normal-Run mit Build und Wellen-Telemetrie. Falls sich dabei
wiederholte Positionierungsfehler ohne Konsequenzen ausheilen lassen, lässt sich
gezielt Sustain gegen gemischte, lesbare Gefahren prüfen. Zusätzliche Gegner
müssen dabei zusammen mit ihren Gold-/XP-Erträgen bewertet werden. Eine
flächige HP-Erhöhung würde den Vorteil der Fernkampfwaffen nicht lösen und
schwächere Nahkampfoptionen zusätzlich belasten.
