# Testpilot gegen den ersten Boss

Stand: 02.11.2026. Der Bot überlebt den Karies-Grafen deutlich zuverlässiger.
Geändert wurden seine Beobachtungs- und Bewegungsregeln. Waffen, Gegner,
Spielerwerte, Shopregeln und Verzauberungsprioritäten wurden dafür nicht verstärkt.

## Ursache und Änderung

Die alte Gefahrenbewertung zählte den Startpunkt einer Bewegung mit, obwohl
eine Warnfläche dort noch keinen Schaden verursacht. Stand Denti bereits im
angekündigten Sektor, sahen deshalb selbst gute Fluchtwege ähnlich schlecht
aus wie Stehenbleiben. Außerdem waren Warnungen nach der Reaktionsverzögerung
älter, als ihre übergebene Restzeit angab.

Der Pilot bewertet jetzt die voraussichtliche Position **im Trefferfenster**.
Beobachtete Bewegungen und sichtbare Warnzeiten werden um das Alter der
verzögerten Beobachtung fortgeschrieben. Auch wenn keine Route sofort ganz
herausführt, wird ein kürzerer Weg zur Sicherheit bevorzugt. Abgelaufene
Trefferfenster bleiben nicht bis zum Ende der Animation gefährlich.

Bei sichtbaren Warnungen prüft der Bot zusätzlich 65 % und 35 % Bewegungstempo.
Das sind reguläre analoge Bewegungseingaben. So kann er etwa in die sichere
Mitte eines Rings laufen und abbremsen, statt dort einen späteren Zusammenstoß
mit dem Boss vorauszusehen und jeden Weg nach innen abzulehnen. Dashes behalten
auch aus einem langsamen Schritt ihre echte volle Strecke; deren Bewertung
normalisiert die Richtung wie `PlayerDash`.

Die bisherigen Reaktionszeiten, Fehlerprofile, Sichtgrenzen und realen
Dashkosten bleiben bestehen. Es werden keine künftigen Spawns, versteckten
Boss-Cooldowns oder noch nicht angekündigten Ziele übergeben.

## Ergebnisse und Grenzen

Alle Zahlen betreffen W1–5, den regelbasierten **Erfahren**-Piloten und die
unveränderte **Feuer-Referenz**. Das sind Diagnosemessungen, keine menschlichen
Siegraten und kein abgeschlossener Waffenbalancepass.

| Prüfung | Ergebnis |
| --- | --- |
| Gleiche gespeicherte Boss-Startwerte: Bohrer, UV, Peitsche × Distanz/Bossfokus × drei Seeds | Alter Pilot **6/18**, neuer Pilot **17/18** Bosskills |
| Vollständige Entwicklungsläufe: Bohrer, UV, Peitsche, Polierer, Turbine × sechs weitere Seeds, Hell/Bossfokus | **30/30** Bosskills |
| Abschließende, vorher unbenutzte Seeds: Bohrer, UV, Peitsche × sechs Seeds, Hell/Bossfokus | **16/18** Bosskills; Peitsche stirbt einmal in W4 und einmal am Boss |
| Alle 18 Startwaffen, Seed 13579, Bossfokus | **18/18 auf Normal**, **17/18 auf Hell**; Zahnseiden-Schneide verliert auf Hell |
| Nativer 8×-Lauf: Peitsche, Hell, Bossfokus, Seed 13579 | Boss nach **33,45 s** besiegt; Eingaben und Kampfergebnisse stimmen mit Headless überein |

Die ersten drei Seeds waren 13579, 24680 und 112233. Die zusätzliche
Entwicklungsgruppe verwendete 101, 202, 303, 404, 505 und 606 und wurde beim
Feinabstimmen berücksichtigt. Erst nach dem Festlegen der Regeln wurden
7, 19, 73, 997, 2027 und 8191 als letzte Kontrollgruppe ausgewertet.

Der Vergleich mit gleichem Build trennt den Kampfgewinn vom besseren Farmen:
Beide Varianten erhalten dieselben gespeicherten HP, Stats, Waffen, Items und
denselben Spawnplan. Waffenlaufzeiten, Statuszustand und Pilot-RNG beginnen
**in beiden Varianten frisch**. Das ist eine kontrollierte Rekonstruktion,
kein exaktes Fortsetzen des ursprünglichen Spielstands. Jede Startkonfiguration
wird vor dem Vergleich auf Gleichheit geprüft.

Eine Gegenprobe mit wenigen Seeds garantiert keine fehlerfreie KI. Insbesondere
Peitsche und Schneide bleiben problematische reine Waffenbuilds auf Hell. Die
Buildregel plant weiterhin nach festen Prioritäten; menschliches Boss-Timing,
geschickte defensive Builds und spätere Bossmechaniken sind damit nicht abgedeckt.

## Selbst ansehen und reproduzieren

Im Launcher **Erfahren → Boss fokussieren → Hell** wählen, etwa mit Bohrer,
UV-Lampe oder Peitsche und Seed 13579. Bestehende Launcher müssen für neue
Kampflogik lediglich einen neuen Lauf starten.

```powershell
python tools/bot_launcher.py
python tools/run_bot_comparison.py --visible --weapons floss_whip --skills expert --strategies boss --difficulties hell --speed 8
```

[Kompakte Messdaten und gespeicherte Startbuilds](balance_boss_pilot.json)
enthalten Ergebnisse pro Lauf, Hashes und die Basisrevision `b748f4d`.
Die Gegenprobe mit gleichem Build lässt sich daraus erneut berechnen:

```powershell
python tools/run_boss_pilot_replay.py --input docs/balance_boss_pilot.json --baseline-ref b748f4d
```

Der Runner liest alte Pilot-/Sensor-/Profilquellen aus Git, legt sie ausschließlich
unter `.godot/boss_replays/` ab und führt beide Varianten mit isolierten
Benutzerdaten aus. Er wechselt weder Branch noch Checkout. Für die angegebene
Basisrevision muss deren Commit lokal in der Git-Historie vorhanden sein.
Der Bericht erfasst zusätzlich echte Treffer samt Kontakt-/Mantelquelle.

Sechs gezielte Godot-Prüfungen und 47 Python-Prüfungen bestehen. Tests decken
seitliches Verlassen einer Warnung, Fortschritt bei knapper Restzeit,
abgelaufene Trefferfenster, sichere Ringmitten, verlangsamte Bewegung,
normalisierte Dashstrecken und unveränderte verzögerte Beobachtungen ab.
