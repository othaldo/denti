# Wurzelsprung und Wurzelkraft

Der erste Dash-Prototyp ist spielbar: **Shift** am Desktop oder der eigene
**Dash-Button unten rechts** auf Touchscreens. Die Richtung ist die aktuelle
Bewegungsrichtung, sonst die zuletzt verwendete; vor der ersten Bewegung nach
unten. Gedrückthalten wiederholt den Dash nicht. Waffen und Mausziel ändern
seine Richtung nicht.

## Regeln und Startwerte

- 150 Welteinheiten in 0,16 s, unabhängig von Bewegungstempo und Diagonale.
- Anfangsvorrat: 100 Wurzelkraft, durch Punkte bis auf 500 ausbaubar. Jeder Start kostet genau 100; ein teilgefüllter Vorrat genügt, solange mindestens 100 übrig sind.
- Nach dem Ende 0,35 s Erholungspause, danach maximaler Vorrat / 4 pro Sekunde. Der gesamte Vorrat lädt immer in 4 s auf: 100 → 25/s, 200 → 50/s.
- Separater Cooldown von 1,5 s ab Start. Mindestens 100 Wurzelkraft **und** freier Cooldown
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

## Wurzelkraft und Anzeige

Das zwölfte Attribut **Wurzelkraft** erhöht den maximalen Ausdauervorrat in
festen Punkten. Der kompakte Stat zeigt nur eine Zahl, anfangs **100**; ein
Levelaufstieg zeigt etwa **+25 Wurzelkraft**. Die bisherigen Zahlen-IDs und der
interne Ressourcen-/Save-Key `dash_recovery_bonus` bleiben kompatibel: bisherige
Bonuswerte werden als zusätzliche Punkte über dem Basisvorrat 100 übernommen.

| Maximaler Vorrat | Nachladerate | Dashes aus vollem Vorrat ohne Nachladen |
| --- | --- | --- |
| 100 | 25/s | 1 |
| 200 | 50/s | 2 |
| 500 | 125/s | 5 |

Die reine Auffüllzeit von leer auf voll bleibt immer 4 s, zusätzlich zu Dashdauer
und Erholungspause. Der separate Cooldown von 1,5 s begrenzt auch gespeicherte
Dashes. Nach einem Dash aus 200 bleiben 100 übrig; nach dem Cooldown darf ein
weiterer Dash starten, ohne auf 200 warten zu müssen.

Level-Boni bieten +25/40/60/90 Punkte je Seltenheit und geben kurz vor dem
Limit nur den noch nutzbaren Rest. Am Limit 500 wird der Bonus nicht mehr
angeboten. Minz-Essenz liefert +10, Kariesbonbon +15 Wurzelkraft je Exemplar;
ihre bisherigen Nachteile bleiben bestehen. Kapazitätsgewinne schenken keine
aktuelle Ausdauer, Kapazitätsverluste begrenzen den aktuellen Vorrat sofort.

Desktop-Anzeige und Touchfläche lesen denselben Zustand. **Leben links und
Wurzelkraft rechts sind zusammengehörige gemalte Zahngefäße.** Der neue,
generierte Gold-/Elfenbeinrahmen enthält eine animierte türkisfarbene Füllung
mit Oberfläche, Schimmer und kleinen Blasen. Die komplette Füllung folgt der
Zahnkontur bis unter den Rand, ohne Verformung oder schwarze Zwischenräume.
Zahlen stehen wie beim Lebenszahn in der Krone: aktueller Wert, darunter der aktuelle Maximalvorrat, etwa `/ 200`.
Nur bei mindestens 100 Wurzelkraft und laufender Sperre steht in der zweiten Zeile stattdessen
deren Restzeit. Es gibt keinen freien Titel, kein „lädt“ und keinen Tastaturtext
im Kampfbild. Eingabehilfe und Detailwerte stehen im Tooltip sowie in Stats.

Das Wurzelkraft-Gefäß ist die mobile Dash-Touchfläche (80, 88 bzw. 100 Pixel
Kantenlänge je Layout). Es ist gegenüber dem Lebenszahn etwas kleiner; auf
schmalen Displays bleiben Münzen/Kapseln zwischen den Gefäßen, direkt rechts
vom Leben und mit Abstand zur Schildhülle. Ein zweiter Finger kann dashen,
während der erste seine Bewegungsgeste behält. Ein kurzer mintfarbener Schweif
begleitet die Bewegung. Wurzelkraft hat auch auf Stat-/Aufstiegskarten
ein eigenes generiertes Icon. [Assets, Werkzeug und vollständige Prompts](STAMINA_ART.md).

## Speichern und Messung

Der Run-Snapshot bewahrt Ladung, Cooldown, Erholungspause, Restdauer und beide
Richtungen. Ein fortgesetzter Dash prüft seine verbleibende Strecke erneut.
Alte Saves ohne Dash-Daten erhalten 100 Wurzelkraft ohne Bonus. Bestehende Saves bewahren auch Restvorräte über 100 und während eines aktiven Dashs.
Gespeicherte Aufstiegsangebote begrenzen ihre angebotenen Punkte erneut anhand der
wiederhergestellten Stats. F3-Telemetrie und Run-Daten erfassen Dashanzahl,
Kontaktabbrüche und tatsächlich erlittenen Schaden während Dash-Bewegungsframes.

Die automatischen Prüfungen decken Zeitgrenzen, lange Frames, Richtungen,
gehaltenes Shift, Gegner/Wände/Ränder, Schilde/Dodge/Trefferpausen, Geschosse,
Pulse/Telegraphe, Pause/Resume, Alt-Saves, Mehrfingereingabe und sechs
Bildschirmformate ab. Nach der Umstellung auf den ausbaubaren Vorrat und das
vereinfachte Icon bestand der vollständige Testlauf mit **118/118 Tests**
(`.godot/test_runs/20261019-203516-f31b1f29`, 110,88 s). Neue Fälle prüfen
feste Kosten aus größerem Vorrat, Nachladerate, Teilfüllung, Kapazitätswechsel,
HUD-Maximum und Save/Resume mit gespeichertem Restvorrat während eines Dashs.
Native Aufnahmen: [Mobile](screenshots/dash/mobile.png),
[Desktop](screenshots/dash/desktop.png), [Animation](screenshots/dash/flow.gif).
Die Aufnahmen oben zeigen den ursprünglichen Basisvorrat. Die vereinfachte
Wurzelkraft-Anzeige und das neue Stat-Icon sind auf den aktuellen
[Aufstiegskarten](screenshots/dash/stamina_cards.png) und im
[mobilen Stat-Menü](screenshots/dash/stamina_stats.png) zu sehen.
Die Zahlen bleiben Prototypwerte: menschliche Druck-/Balance-Playtests mit
schwachen und starken Builds sind noch offen; die Aufnahmen belegen keine Winrate.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter player_dash --filter mobile_controls --filter combat_hud
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_dash.gd
```

Das Vorschauwerkzeug benutzt einen eigenen Spielstand. Einzelbilder und die
Frames für die Animation liegen unter `.godot/dash_preview/`.
