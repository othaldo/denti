# Wurzelsprung und Wurzelkraft

Der erste Dash-Prototyp ist spielbar: **Shift** am Desktop oder der eigene
**Dash-Button unten rechts** auf Touchscreens. Die Richtung ist die aktuelle
Bewegungsrichtung, sonst die zuletzt verwendete; vor der ersten Bewegung nach
unten. Gedrückthalten wiederholt den Dash nicht. Waffen und Mausziel ändern
seine Richtung nicht.

## Regeln und Startwerte

- 150 Welteinheiten in 0,16 s, unabhängig von Bewegungstempo und Diagonale.
- Eine Ladung: 100 Wurzelkraft. Jeder Start kostet die gesamte Ladung.
- Nach dem Ende 0,35 s Erholungspause, danach 25 Wurzelkraft/s.
- Separater Cooldown von 1,5 s ab Start. Volle Ladung **und** freier Cooldown
  sind erforderlich. Ungültige Eingaben werden nicht vorgemerkt.
- Neue Wellen starten voll. Pause, Shop und Fortsetzen schenken keine Ladung;
  Pausen- und Offlinezeit regenerieren nichts.

`data/player/dash.tres` enthält die gemeinsamen konfigurierbaren Werte.
`PlayerDash` besitzt Ladung, Zeitablauf und Richtung; `DashCollision` übernimmt
die Kollisionsstrecke. Der Spieler steuert Eingabe und Bewegung, der vorhandene
Run-Koordinator bestimmt weiterhin Kampf und Pause.

## Kontakt und Gefahr

Der erste lebende Gegner, eine Wand oder der Arenarand beendet den Dash ohne
Erstattung. Auch ein Start innerhalb einer Horde kann Gegner nicht durchqueren.
Schild, Zahnflutsch und bestehende Trefferpausen ändern diesen Stopp nicht.
Der Dash verursacht keinen Schaden und verleiht keine zusätzlichen Schutzframes.

Gegnerkörper werden entlang der Bewegung geprüft; bereits laufende gegnerische
Charges werden relativ zur eigenen Bewegung geprüft. Kontakt läuft über
denselben Trefferweg wie normale Berührung und erhält dessen Kontaktcooldown,
damit derselbe Kontakt nicht nochmals Schaden oder eine zweite Schildladung kostet.
Projektile prüfen die relative Bewegung; bei langen Frames wird am tatsächlichen
Dashende beziehungsweise Kontaktstopp geteilt. Neu danach erzeugte Geschosse
treffen keine vergangenen Spielerpositionen.

Die vorhandenen Flächenangriffe sind zeitlich ausgelöste Pulse. Ihr Treffer
prüft Dentis Position beim Auslösen innerhalb des Frames. So kann ein aktiver
Angriff auch während eines langen Bewegungsframes treffen, während ein erst
später endender Telegraph keine vergangene Position nachträglich bestraft.
Gift und Blutung laufen über ihren bisherigen Statuspfad weiter.

## Erholung und Anzeige

Das zwölfte Attribut **Wurzelkraft-Erholung** wurde an den Statkatalog angehängt;
die bisherigen Zahlen-IDs bleiben gleich. Es verbessert additiv die Nachladerate,
mit wirksamem Limit +400 %. Die Kapazität bleibt fest.

| Erholung | Reine Auffüllzeit | Frühester nächster Start |
| --- | --- | --- |
| +0 % | 4,00 s | 4,51 s |
| +100 % | 2,00 s | 2,51 s |
| +400 % | 0,80 s | 1,50 s |

Level-Boni bieten +25/40/60/90 % je Seltenheit, zeigen die resultierende
Auffüllzeit und geben kurz vor dem Limit nur den noch nutzbaren Rest.
Am Limit wird der Bonus nicht mehr angeboten. Minz-Essenz liefert zusätzlich
+10 %, Kariesbonbon +15 % Erholung je Exemplar; ihre bisherigen Nachteile
bleiben bestehen. Kapazitäts- und Cooldown-Items kommen erst nach Playtests.

Desktop-Anzeige und Touchfläche lesen denselben Zustand. **Leben links und
Wurzelkraft rechts sind zusammengehörige gemalte Zahngefäße.** Der neue,
generierte Gold-/Elfenbeinrahmen enthält eine animierte türkisfarbene Füllung
mit Oberfläche, Schimmer und kleinen Blasen. Die komplette Füllung folgt der
Zahnkontur bis unter den Rand, ohne Verformung oder schwarze Zwischenräume.
Zahlen stehen wie beim Lebenszahn in der Krone: aktueller Wert, darunter `/ 100`.
Nur bei voller Ladung und laufender Sperre steht in der zweiten Zeile stattdessen
deren Restzeit. Es gibt keinen freien Titel, kein „lädt“ und keinen Tastaturtext
im Kampfbild. Eingabehilfe und Detailwerte stehen im Tooltip sowie in Stats.

Das Wurzelkraft-Gefäß ist die mobile Dash-Touchfläche (80, 88 bzw. 100 Pixel
Kantenlänge je Layout). Es ist gegenüber dem Lebenszahn etwas kleiner; auf
schmalen Displays bleiben Münzen/Kapseln zwischen den Gefäßen, direkt rechts
vom Leben und mit Abstand zur Schildhülle. Ein zweiter Finger kann dashen,
während der erste seine Bewegungsgeste behält. Ein kurzer mintfarbener Schweif
begleitet die Bewegung. Der Erholungswert hat auch auf Stat-/Aufstiegskarten
ein eigenes generiertes Icon. [Assets, Werkzeug und vollständige Prompts](STAMINA_ART.md).

## Speichern und Messung

Der Run-Snapshot bewahrt Ladung, Cooldown, Erholungspause, Restdauer und beide
Richtungen. Ein fortgesetzter Dash prüft seine verbleibende Strecke erneut.
Alte Saves ohne Dash-Daten erhalten volle Basisladung und +0 % Erholung.
Gespeicherte Aufstiegsangebote berechnen ihre Erholungsanzeige erneut aus den
wiederhergestellten Stats. F3-Telemetrie und Run-Daten erfassen Dashanzahl,
Kontaktabbrüche und tatsächlich erlittenen Schaden während Dash-Bewegungsframes.

Die automatischen Prüfungen decken Zeitgrenzen, lange Frames, Richtungen,
gehaltenes Shift, Gegner/Wände/Ränder, Schilde/Dodge/Trefferpausen, Geschosse,
Pulse/Telegraphe, Pause/Resume, Alt-Saves, Mehrfingereingabe und sechs
Bildschirmformate ab. Der vollständige Testlauf bestand mit **118/118 Tests**;
nach der abschließenden Zahlen-Aktualisierung bestanden die gezielten HUD-,
Touch-, Dash-, Gefäß- und Iconprüfungen erneut.
Native Aufnahmen: [Mobile](screenshots/dash/mobile.png),
[Desktop](screenshots/dash/desktop.png), [Animation](screenshots/dash/flow.gif).
Die Zahlen bleiben Prototypwerte: menschliche Druck-/Balance-Playtests mit
schwachen und starken Builds sind noch offen; die Aufnahmen belegen keine Winrate.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter player_dash --filter mobile_controls --filter combat_hud
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_dash.gd
```

Das Vorschauwerkzeug benutzt einen eigenen Spielstand. Einzelbilder und die
Frames für die Animation liegen unter `.godot/dash_preview/`.
