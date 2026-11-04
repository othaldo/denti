# Bossdruck: Messung vom 3. November 2026

Diese Messung dokumentiert den Stand vor dem anschließenden
[Don-Umbau](DON_PRESSURE_REWORK.md). Dessen aktuelle Prüfungsfolge und neue
Vergleichswerte stehen im verlinkten Folgebericht.

**Nachbessern würde ich zuerst bei Don Karamellos Phasenrhythmus und bei
Korrodons Kampflänge auf Normal.** Pauschal mehr Leben oder Schaden sind durch
diese Messung nicht begründet. Der Imperator erzeugt bereits erheblichen Druck.

## Vergleich der vollständigen Kämpfe

144 Durchläufe: vier Bosse × Normal/Hell × Nah-/Fernkampf × drei Steuerungen
× drei Seeds. Die Tabellen zeigen jeweils den Median der drei **reaktiven**
Durchläufe. Alle Bossmechaniken, Minions und automatischen Waffen bleiben aktiv.

| Boss | Normal: Nah / Fern | Hell: Nah / Fern | Einschätzung |
| --- | ---: | ---: | --- |
| Plaquula | 18,4 / 18,2 s | 18,5 / 18,2 s | Gut lesbarer Lernboss; korrektes Ausweichen lohnt sich sehr. |
| Don Karamello | 21,6 / 20,9 s | 30,4 / 34,7 s | Eher milder Druck; vor allem zu wenig normales Bossverhalten zwischen Prüfungen. |
| Korrodon | 64,6 / 64,5 s | 70,2 / 73,8 s | Deutlicher Druck, besonders im Nahkampf; Normal dauert auffällig lange. |
| Karies-Imperator | 48,5 / 46,1 s | 54,5 / 59,9 s | Höchster gemessener Schadensdruck; zunächst menschlich testen. |

Der Gesamtschaden lässt sich auf die normalen Lebenspunkte des jeweiligen
Testbuilds beziehen. **Ein Wert von 2 bedeutet insgesamt Schaden in Höhe von
zwei vollen Lebensbalken**, während die Messreserve den Kampf fortsetzt.
Das ist keine Aussage über menschliche Siegraten oder einen normalen Run mit
Heilung, Items und Dash.

| Hell, Schaden in Lebensbalken | Reaktiv Nah / Fern | Einfach kreisen Nah / Fern |
| --- | ---: | ---: |
| Plaquula | 0,00 / 0,86 | 2,01 / 2,58 |
| Don Karamello | 1,23 / 0,61 | 2,98 / 3,09 |
| Korrodon | 4,22 / 2,24 | 6,87 / 3,77 |
| Karies-Imperator | 3,72 / 5,11 | 9,31 / 12,18 |

Die Kreiskontrolle reagiert außerhalb der Ventilaufgabe nicht auf Warnungen.
Sie nimmt auf Hell bei jedem Boss mehr als einen Lebensbalken Schaden. Alle
reaktiven Steuerungen nehmen weniger Schaden als ihre entsprechenden
Kreiskontrollen. Erfolgreiches Ausweichen bleibt damit wertvoll.

## Konkrete Baustellen

### 1. Don: zwischen Prüfungen wieder kämpfen lassen

In allen sechs reaktiven Hell-Durchläufen beträgt der Abstand zwischen dem
Ende der ersten Spezialroutine und dem Beginn der zweiten **0 Sekunden**.
Bis zur dritten Routine bleiben nur **1,62 Sekunden** normales Bossverhalten.
Das Schadensfenster am Ende einer Prüfung zählt dabei bereits zur
Spezialroutine. Es ersetzt keine normale Angriffsfolge.

Das ist ein messbarer Grund für den Eindruck, hauptsächlich Spezialaktionen
abzuarbeiten. Don ist im Nahkampf rund zur Hälfte des Duells nicht anvisierbar.
Brösel lebt während der Spezialroutinen im Median 6,8 Sekunden im Nahkampf und
7,0 Sekunden im Fernkampf. Er bleibt angreifbar und seine Uhr läuft weiter;
direkten Brösel-Schaden vermeidet die reaktive Steuerung in dieser Reihe.

**Vorschlag:** Das erfolgreiche Schadensfenster wie bei Korrodon/Imperator
begrenzen und anschließend das normale Schadensbudget kontrolliert neu
aufbauen. Ziel wären wieder erkennbare normale Angriffsfolgen zwischen den
Prüfungen. Danach gezielt prüfen, ob Brösel und Don sinnvoll gleichzeitig
Druck machen. Keine weitere pauschale HP-Erhöhung aus diesen Daten ableiten.

### 2. Korrodon: auf Normal kürzen, Hell gesondert beurteilen

Normal hat eine Schildprüfung, Hell drei. Trotzdem liegen die gesamten
Kampfdauern nur rund 6–9 Sekunden auseinander. Die Abwehr mit 60 Sekunden
Regenerationsbasis hält insbesondere die normale Version lange am Leben.

Eine **nur im Messwerkzeug aktivierte** Variante mit 45 Sekunden
Abwehr-Regeneration senkt Normal in zwölf zusätzlichen Durchläufen auf etwa
**52 Sekunden**. Die Schildprüfung bleibt erhalten. Der reaktive Gesamtschaden
beträgt im Median 1,36 Lebensbalken im Nahkampf und 0,52 im Fernkampf.
Die kürzere Variante macht nicht jeden Angriffsverlauf automatisch leichter;
die zeitlichen Überlagerungen ändern sich ebenfalls.

Auf Hell stammen die meisten reaktiven Nahkampftreffer aus Korrodons normalen
Angriffen und dem Schildstrahl. Schlacko lebt während der Spezialroutinen im
Median 25,7 Sekunden im Nahkampf und 14,5 Sekunden im Fernkampf. Er trägt dort
zusätzliche Warnflächen bei; direkte Miniontreffer allein erfassen seinen
Einfluss auf die Bewegung nicht vollständig.

**Vorschlag:** Die kürzere normale Variante testspielen. Hell zunächst gezielt
im Nahkampf prüfen; die hohe dortige Schadenslast rechtfertigt keinen weiteren
pauschalen Druckaufschlag.

### 3. Imperator: schon ausreichend gefährlich

Alle drei Hell-Gefolgschaftsprüfungen werden erreicht. Das Gefolge lebt im
Median rund 22 Sekunden während dieser Routinen. Die normalen Abschnitte
zwischen den Aufgaben sind deutlich länger als bei Don.

Auch die ausweichende Steuerung kassiert noch erheblichen Schaden. Beim
Nahkämpfer ist Kontaktschaden ein großer Anteil; das ist ein Hinweis für einen
gezielten Test der Positionierung und Anstürme, kein Beleg für unvermeidbare
Treffer. Beim Fernkämpfer dominieren die normalen Imperator-Angriffe.

**Vorschlag:** Vor weiteren Verstärkungen menschlich testen, besonders mit
Nahkampf und mit einem real erspielten Heilungs-/Itembuild.

### 4. Plaquula: funktionierender Einstieg

Die reaktive Nahkampfsteuerung vermeidet in allen drei Hell-Samples sämtliche
Treffer. Einfaches Kreisen nimmt dagegen deutlich Schaden. Die Vorwarnungen
haben somit eine klare Ausweichantwort. Rund 18 Sekunden Kampfdauer sind kein
One-Hit-Problem mehr. Für einen ersten Boss besteht daraus kein unmittelbarer
Bedarf an mehr Schaden oder Abwehr. Mehr Hell-Abwechslung wäre ein eigener
Designschritt.

## Bedingungen und Grenzen

- Godot 4.7.2, headless, feste 60 Hz, Zeitskalierung 1.
- Je sechs Turbo-Bohrer oder Schmelzspiegel, passend zur Welle Tier I–IV;
  gemeinsame Stufenprofile aus `build_comparison_profiles.gd`.
- 115/130/145/160 normale Lebenspunkte, 3/6/9/12 Rüstung. Keine Items,
  Verzauberungen, Evolutionen oder Heilung. Das sind synthetische Vergleichs-
  builds, keine erspielten Kaufhistorien.
- Gleicher Start im offenen Arenabereich, 280 Einheiten zwischen Denti und Boss.
  Nahkampf-Zielabstand mindestens 135, Fernkampf 250; kein absichtliches Stehen
  im Bosskörper. Ziele der Spezialaufgaben werden näher angelaufen.
- `seeker` verfolgt Boss/Aufgaben ohne allgemeines Ausweichen; `circle` kreist;
  `reactive` liest sichtbare Warnungen mit 10 Frames Reaktionsverzögerung und
  Entscheidungen alle 6 Frames. Alle laufen ohne Dash.
- Alle Steuerungen kennen die Aufgaben. Für Korrodons Ventilausrichtung nutzen
  sie denselben speziellen Routenpiloten. Das ist keine Untersuchung, ob ein
  neuer Spieler die Aufgabe ohne Erklärung versteht.
- Brösel/Schlacko werden außerhalb von Aufgaben nicht gezielt priorisiert;
  die echten automatischen Waffen wählen ihre Ziele. Beim Imperator wird der
  Siegelhüter zuerst verfolgt. Andere Prioritäten können die Ergebnisse ändern.
- 100.000 HP Messreserve, aber Treffer-Unverwundbarkeit anhand der normalen
  Maximal-HP. Die älteren 10.000-HP-Proben hatten diesen Unterschied noch nicht
  berücksichtigt; ihre Schadenssummen sind nicht direkt vergleichbar.
- SFX-Aufrufe sind nur im Messwerkzeug unterdrückt. Stummschalten reicht nicht:
  `SoundController.play_cue` verwendet eine Echtzeit-Drosselung und zieht für
  die Tonhöhe aus demselben globalen RNG wie kritische Treffer. Das erzeugte
  zuvor hardwareabhängige Streuung. Drei gleiche Imperator-Kontrollläufe mit
  isoliertem SFX ergeben identische Rohwerte.
- `threatened_fraction` in den Rohdaten ist nur das stehende Risikomodell des
  Bots, abgetastet mit 10 Hz. Es ist kein allgemeiner Schwierigkeitswert.
- Sämtliche vollständigen Messkämpfe erreichen das Bossende und lösen die
  vorgesehenen Prüfungen ohne Aufgabenfehlschlag. Wegen der HP-Reserve ist das
  kein Überlebensnachweis. Spaß, Lesbarkeit unter echten Builds und die
  Lebensfähigkeit anderer Waffen brauchen menschliche Tests.

## Nachmessen

Benutzerdaten bleiben isoliert; der Vergleichs-Game schreibt keinen normalen
Spielstand und keinen Abschlussbericht. Die spielbare Balance wurde für diese
Untersuchung nicht verändert.

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/boss_pressure_manual/userdata'
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script res://tools/measure_boss_pressure.gd -- --policies=seeker,circle,reactive --output=res://.godot/boss_pressure_manual.json
python tools/report_boss_pressure.py .godot/boss_pressure_manual.json --date 2026-11-03 --output .godot/boss_pressure_report.json
```

`--waves=15 --difficulties=normal --policies=seeker,reactive
--king-guard-seconds=45` misst die unveröffentlichte Normal-Variante.
Wellen, Schwierigkeiten, Builds, Steuerungen und Seeds lassen sich jeweils
als kommagetrennte Werte einschränken. Standard-Seeds: 13579, 24680, 112233.
Die Messung beendet einen einzelnen Durchlauf spätestens nach 150 Sekunden.

Die Abschlussreihe wurde auf zwei disjunkte Wellenblöcke verteilt und mit
`report_boss_pressure.py` zusammengeführt. Das Werkzeug verweigert doppelte
Samples oder inkompatible Messbedingungen und behält alle Rohdaten.

- [144 vollständige Vergleichskämpfe und Zusammenfassungen](boss_pressure_2026_11_03.json)
- [12 Korrodon-Normal-Kandidaten](boss_pressure_king_candidate_2026_11_03.json)
- [Drei identische Imperator-Kontrollläufe](boss_pressure_determinism_2026_11_03.json)
- `tests/extended/boss_pressure_probe.gd` prüft die echten Treffer-Schutzzeiten
  gegen die Messreserve, unveränderten RNG bei Mess-SFX sowie die Erfassung von
  Minionwarnungen und Fehlschlagsalven. Kontaktlose Minions zählen nicht als
  zusätzliche Körper-Kontaktgefahr.
