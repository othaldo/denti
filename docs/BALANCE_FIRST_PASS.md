# Erster spielbarer Balancepass

01.11.2026 · Normal · Godot 4.7.2 · bestehender Checkout, keine neue Version.

Ausgangspunkt: Zwei UV-Lampen und eine Zahnseiden-Schneide mit maximalem Element
und Lebensraub erlaubten einen sehr verzeihenden Sieg. Der [Ausgangsvergleich](BUILD_COMPARISON.md)
isolierte vor allem die Heilung als Ursache. Dieser Pass verbessert zuerst eine
weniger attraktive Alternative und prüft zusätzlichen lesbaren Gegnerdruck.
Erst danach begrenzt er gezielt den Heilertrag hoher Lebensraub-Ränge.

## Änderungen und Spielgefühl

### Interdental-Bürste: Platz schaffen

| Wert | Vorher | Jetzt, Mk I–IV |
| --- | --- | --- |
| Reichweite | 62 / 65 / 70 / 75 | 82 / 88 / 94 / 102 |
| Rückstoß | 0 | 4 / 5 / 6 / 7, radial von Denti weg |

Grundschaden, Angriffstakt, Skalierung, Blutung und Preis bleiben erhalten.
Die tatsächliche animierte Klinge prüft weiterhin den Kontakt; es gibt keinen
unsichtbaren Soforttreffer im ganzen Kreis. Pro Angriff wird jedes Ziel höchstens
einmal getroffen. Der Rückstoß schafft kurze Lücken, statt Gegner hinter Denti
in die gemeinsame Zielrichtung zu schieben.

Die Rolle wird dadurch verständlicher: kurzer Rundumkampf hält Gruppen auf
Abstand. Der Nutzen entsteht durch mehr sichere Angriffszeit und Raumgewinn,
ohne alle Waffen auf ähnliche Schadenswerte zu bringen.

### Imperator: vorhersehbare Routen bedrohen

Auf Normal, Hard und Hell hält der Imperator beim Festlegen eines Hofurteils
0,55 Sekunden in Dentis Bewegungsrichtung vor, begrenzt auf 125 Pixel.
Die Warnung zeigt diese Richtung von Beginn an; sie verfolgt Denti danach nicht.
Warnzeiten, Schadenswerte, Lebenspunkte und Wiederholungszahlen bleiben gleich.
Easy zielt weiterhin direkt. Eine bereits gespeicherte Warnung behält ihren
gespeicherten Winkel; alte Angriffssequenzen erhalten keine neue Vorhersage.

Das verlangt gelegentlich einen Richtungswechsel. Es erhöht nicht pauschal die
Belastung aller schwächeren Builds. Eine konkrete Route mit 72 % Grundtempo
wird bei sturem Weiterlaufen getroffen und kann durch Umkehren schadlos entkommen.
Die bestehenden Ausweichprüfungen bleiben zusätzlich aktiv.

### Lebensraub: weiter lohnend, weniger vollständiges Wegheilen

Der Versuch nur mit zusätzlichem Boss-Vorhalten ließ den UV-Mix mit Lebensraub 10
weiterhin alle drei Endbossproben bei median 100 % Restleben bestehen. Mehr
Warnflächen allein löst den Sustain-Ausreißer hier nicht.

Das bisherige Heilbudget `x = 0,25 + Effektstärke × 0,04` pro Wurzel erhält nun
oberhalb von 0,75 den Wert `0,75 + (x − 0,75) × 0,4`. Erst anschließend gelten
die bestehende harte Obergrenze und die Wurzelzahl.

| Rang | Vorher, HP je Wurzel/Impuls | Jetzt |
| ---: | ---: | ---: |
| 1 | 0,37 | 0,37 |
| 4 | 0,65 | 0,65 |
| 5 | 0,81 | 0,774 |
| 7 | 1,13 | 0,902 |
| 10 | 1,65 | 1,11 |

Rang 1–4 bleibt unverändert. Jeder weitere Rang verbessert die Heilung; es gibt
keine wertlosen letzten Ränge. Rang 10 verliert etwa 33 % seines Heilbudgets.
Sechs belegte Wurzeln erreichen theoretisch höchstens 11,1 statt 16,5 HP/s aus
Lebensraub. Das setzt wirksame Treffer im passenden Takt und genügend fehlendes
Leben voraus, es ist keine Garantie für tatsächliche Heilung.

Die 5-%-Grenze des tatsächlichen Trefferschadens, 0,6 Sekunden je Waffenexemplar,
gemeinsame Salven-/Splash-Sperren, Wurzelgleichheit und Ausschluss von DoT-Heilung
bleiben erhalten. Anzeige und Treffer verwenden dieselbe Berechnung. Bestehende
Verzauberungsränge und Investitionen bleiben gespeichert; ihr Heilwert folgt beim
Fortsetzen der aktuellen Kurve. UV-Schaden und sämtliche Elementeffekte bleiben
erhalten. Weder Gegner-HP noch Einkommen oder Kapselpreise werden erhöht.
Die Heilkurve und der Bürsten-Buff gelten für alle Schwierigkeitsgrade; nur das
zusätzliche Vorhalten nimmt Easy ausdrücklich aus.

Das ist ein gezielter Nerf trotz „Buffs zuerst“: Der Ausgangsvergleich zeigte,
dass Heilung wiederholte Fehler fast vollständig ausgleicht. Noch mehr allgemeiner
Gegnerschaden würde besonders Builds ohne Lebensraub treffen. Die frühe Investition
bleibt attraktiv; maximaler Lebensraub ersetzt bewusste Bewegung seltener.

## Kontrollierte Ergebnisse

Drei identische Seeds je Gruppe, endliche HP, echte Angriffe/Spielerphysik,
unveränderte Spawnpläne, unabhängige Checkpoints. Mediane; **keine Run-Winrates**.
Erfolgreiche Boss-TTKs beziehen sich nur auf tatsächlich besiegte Bosse.

**Bürste, gleicher allgemeiner Shop-Ausbau, einfache Kreisbewegung:**

| Welle | Bestanden vorher → jetzt | Schaden erhalten vorher → jetzt | Kills vorher → jetzt |
| ---: | ---: | ---: | ---: |
| 4 | 3/3 → 3/3 | 26,6 → 12,1 | 24 → 26 |
| 9 | 3/3 → 3/3 | 163,4 → 24,4 | 43 → 41 |
| 14 | 1/3 → 3/3 | 308,9 → 21,9 | 95 → 76 |
| 19 | 0/3 → 3/3 | 364,9 → 0,0 | 113 → 115 |

Der starke Sicherheitsgewinn ist beabsichtigt und muss im Spiel auf Dauerkontrolle
geprüft werden: Sechs Bürsten nehmen im getesteten späten Kreisaufbau teilweise
keinen Schaden mehr. Weniger Kills können auch eine bessere Verdrängung bedeuten.
Der Buff erhöht deshalb nicht zusätzlich den Grundschaden. Stillstehen scheitert
mit sechs Bürsten in den Shop-Proben der Wellen 9/14/19 weiterhin jeweils 3/3.

Beim korrigierten gezielten Nachsetzen besteht die Bürste den ersten Boss vor
und nach dem Patch 3/3: median 24,8 → 24,2 Sekunden. Beim Endboss verbessert sie
sich 0/3 → 3/3 mit median 37,2 Sekunden. Frühe Boss-TTKs anderer Rollen bleiben
bei unverändertem Ausbau identisch. Der Nachsetzpilot weicht Warnungen nicht
bewusst aus; seine Ergebnisse bilden keine vollständige Rangliste der Waffen.

**UV-Mix, maximaler Feuer-/Lebensraub-Ausbau, einfache Kreisbewegung:**

| Welle / Effekte | Bestanden vorher → jetzt | Restleben % vorher → jetzt | Tiefster HP-Stand % vorher → jetzt |
| --- | ---: | ---: | ---: |
| 19, nur Lebensraub 10 | 3/3 → 2/3 | 96,5 → 90,4 | 55,1 → 39,3 |
| 19, Feuer 10 + Lebensraub 10 | 3/3 → 2/3 | 96,2 → 87,2 | 57,2 → 41,4 |
| 20, nur Lebensraub 10 | 3/3 → 3/3 | 100,0 → 46,0 | 77,5 → 43,8 |
| 20, Feuer 10 + Lebensraub 10 | 3/3 → 3/3 | 100,0 → 100,0 | 79,1 → 74,7 |

Der komplette Maximalbuild bleibt mächtig und besiegt den Endboss weiterhin.
Mehr Eingriffe werden nicht daran ausgerichtet, einen solchen Build zwingend
scheitern zu lassen. Der isolierte Lebensraub-Aufbau verzeiht spürbar weniger;
die Hordenprobe zeigt nun auch beim vollständigen Build Konsequenzen derselben
unaufmerksamen Route. Ob das Normal über einen ganzen Run passend anspruchsvoll
macht, ist noch durch menschliche Spieltests zu prüfen.

Die Zusatzkontrolle der anderen Rollen zeigt auch den Preis des Eingriffs:
Sechs Bohrer und sechs Bürsten bestehen den Endboss mit maximalem Feuer und
Lebensraub beim bloßen Arenakreisen jetzt 0/3 statt zuvor 3/3. Sechs Spiegel
bestehen ihn weiter 3/3. Bei der Bürste kehrt sich das Ergebnis mit aktivem
Nachsetzen um: Der normale Shop-Ausbau besteht nach dem Patch 3/3. Die Gefahr
eines Nachteils für ungeschickt gespielten Nahkampf ist damit sichtbar und gehört
in die menschliche Abnahme. Diese Probe rechtfertigt keinen weiteren allgemeinen
Lebensraub-Nerf und keine Rangliste allein nach Endboss-Erfolgen.

## Daten, Reproduktion und Prüfungen

Abgeschlossen: **162/162 Kerntests**, außerdem **3/3 Zusatzprüfungen**
(`run_telemetry`, `max_enchantment_comparison`, `emperor_final_routes`) einschließlich
144 vollständiger verlangsamter Boss-Ausweichsequenzen über alle vier Grade und
drei Ansichtsgrößen. Zwei Python-Prüfungen der Ergebnisaggregation bestehen.
207 neue Kontrollkämpfe und die native Ansicht sind ausgewertet. Menschliches
Spielgefühl und ein vollständiger 20-Wellen-Run wurden dadurch nicht geprüft.

- Historische Grundlage: [576 Basisproben](balance_build_comparison.json),
  [186 Maximalproben](balance_build_max_enchantments.json).
- Korrigierter Bossabstand vor dem Patch: [48 Kämpfe](balance_patch_pursuit_before.json).
  Der ursprüngliche Pilot ignorierte den Bossradius und wird nicht als Beleg verwendet.
- Isolierter Bürsten-Buff: [48 Kämpfe](balance_patch_brush_after.json),
  [Gruppenmediane](balance_patch_brush_after.md).
- Nur zusätzliches Vorhalten, UV ohne Bürsten: [9 Kämpfe](balance_patch_pressure_only.json).
- Vollständiger Patch, UV: [18 Kämpfe](balance_patch_max_after.json),
  [Gruppenmediane](balance_patch_max_after.md).
- Vollständiger Patch, gezieltes Nachsetzen aller vier Rollen:
  [48 Kämpfe](balance_patch_pursuit_after.json), [Gruppenmediane](balance_patch_pursuit_after.md).
- Zusätzliche Kontrolle hoher Lebensraub-Ränge bei den anderen drei Rollen:
  [36 Kämpfe](balance_patch_roles_after.json), [Gruppenmediane](balance_patch_roles_after.md).

Jeder Bericht enthält einen Hash der tatsächlich gemessenen Spielquellen. Die
einzelnen Zwischenstände haben absichtlich andere Hashes. Neue Messungen mit
dem aktuellen Code erzeugen den vollständigen Patch; historische Zwischenstände
werden nicht durch erneutes Ausführen desselben Dateinamens rekonstruiert.

```powershell
python tools/run_build_comparison.py --godot Godot_v4.7.2-stable_win64_console.exe --controller max --waves 19,20 --builds uv_floss --modes element10,leech10,both10 --elements fire --movements orbit --output .godot/balance_uv_current.json
python tools/run_build_comparison.py --godot Godot_v4.7.2-stable_win64_console.exe --controller pursuit --output .godot/balance_pursuit_current.json
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter balance_first_pass --filter sustain_balance --filter weapon_upgrade_economy --filter crown_court_routes --filter royal_boss_pressure
```

`balance_first_pass` prüft animierten Kontakt, Windup, radialen Rückstoß,
Einmaltreffer, wachsende Lebensraub-Ränge, unveränderte frühe Ränge, Wurzelgleichheit,
Anzeigen, JSON, begrenztes Vorhalten, feste Warnungen, Easy/Legacy-Verhalten und
eine verlangsamte erfolgreiche Richtungswechselroute.

`tools/preview_balance_first_pass.gd` rendert fünf echte Bürstenphasen und zwei
Warnansichten nach `.godot/balance_first_pass/`. Mit isoliertem APPDATA und ohne
`--headless` ausführen. Die native Prüfung kontrolliert sichtbaren Klingenkontakt
und die vor dem Richtungswechsel fest angezeigte Gefahr.

Menschliche Abnahme: je einen vollständigen Normal-Run mit UV/Schneide und mit
Bürsten-Mix spielen, Lebensraub bewusst mit einer anderen Investition vergleichen.
Prüfen, ob Richtungswechsel lesbar sind, Raumgewinn Freude macht und sechs Bürsten
zu viel Sicherheit erzeugen. Run-Berichte mit Wellen-Startbuild, Heilung,
Überheilung, Schaden und Boss-TTK zur nächsten Iteration heranziehen. Weitere
Waffen, Klassen und pauschale Gegnerverstärkungen folgen aus diesem Pass nicht.
