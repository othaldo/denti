# Zahnblende mit Zoom zwischen Spielansichten

`SceneTransitions` öffnet die neue Ansicht in 0,6 Sekunden durch eine wachsende
Zahnsilhouette mit plastischer Goldkante, weichem Lichtschein und Glanzreflex.
Die vorherige Ansicht zoomt bis zu 5,5 % hinein und wird pflaumenfarben abgetönt.
Die neue Ansicht beginnt mit 7,5 % Vergrößerung und gleitet weich auf ihre
normale Größe zurück. Der ganze Effekt bleibt proportional, auch im Hochformat.
Es gibt keine feste zusätzliche Ladepause, kein Blinken und keinen dauerhaften Effekt.

Übergänge verbinden Hauptmenü, Waffenauswahl, Kampf, die Belohnungsphase, Shop,
Storydialog und Reise sowie Sieg/Niederlage. Ein Neustart und Fortsetzen verwenden
denselben Übergang wie ein Szenenwechsel. Einzelne Dialogzeilen, Shopkäufe,
Rerolls und weitere Auswahlkarten derselben Belohnungsphase starten keinen neuen
Bildschirmübergang. Während einer laufenden Welle löst ein Levelgewinn keinen aus.

Die Zahnblende funktioniert auch im pausierten Shop. Beim Eintritt in den
Kampf bleibt Bewegungsinput frei. Bei Menü- und Szenenwechseln werden Eingaben
kurz abgefangen, damit ein weiterer Klick nicht versehentlich die nächste Ansicht
aktiviert. Die Option für reduzierte UI-Animationen überspringt Blende und Zoom.
Eine tatsächliche Größenänderung entfernt das alte Bild sofort; reine Resize-
Benachrichtigungen bei unveränderten Maßen brechen den Szenenwechsel nicht ab.

Der Autoload überlebt echte Szenenwechsel und hält das ausgehende Bild fest,
bis die neue Szene und ihr Layout bereit sind. Pro Übergang wird höchstens ein
Viewport-Bild kopiert. `scene_tooth_reveal.gdshader` liest die neue, weiterhin
lebendige Ansicht direkt aus der GPU-Bildschirmtextur; die Spielkamera und die
UI-Geometrie werden nicht verändert. Das 2048×2048-Distanzfeld
`assets/ui/tooth_transition_distance.res` hält die vergrößerte Kontur glatt.
`tools/bake_shield_distance.gd -- --transition` erzeugt es aus dem bestehenden
Zahnrahmen. Die 512-Pixel-Schildfassung bleibt unverändert.
Am Ende werden das alte Bild und die Eingabesperre freigegeben. Schnelle programmatische
Wechsel reihen keine veralteten Ansichten ein.

Spielzustand, Pausenbesitz, Timer, Save/Resume und Belohnungsreihenfolge bleiben
beim bestehenden Spiel-/Belohnungskoordinator. Darstellung und Spiellogik ändern
sich sofort; die Blende verzögert keine Auswahl und öffnet keine Modals.
Auch beim Fortsetzen wird die aktuelle Ansicht als Darstellungsziel registriert.

## Starten und Fortsetzen

Die Run-Szene wird bereits beim Spielstart geladen und gehalten, bevor das
Hauptmenü bedienbar ist. Ihr großer Ressourcenbaum wird dadurch nicht erst
beim Klick auf Starten/Fortsetzen synchron geladen. Das gilt auch für den
Web-Export ohne Threads. Der vorhandene Grafik-Warmup bereitet zusätzlich
Lebenszahn, Schild, Level-Medaillon, Bossrahmen und Statusbilder vor.

Bei echten Szenenwechseln erscheint zunächst ein leichtes Hineinzoomen des
ausgehenden Bilds auf einem gerenderten Frame. Erst danach wird die neue Szene
eingehängt; die Zahnblende öffnet sie, sobald ihr Layout bereit ist. Es gibt
keine vorgeschaltete Warteanimation mit fester Dauer. Headless-Prüfungen und
reduzierte Bewegung benötigen keinen Render-Wartepunkt.

Das F4-Testmenü bleibt auf lokale Desktop-Debug-Builds beschränkt
(`OS.is_debug_build()`); Web und Release aktivieren es nicht. Sein Katalog
mit den verkleinerten Item-Bildern entsteht erst beim ersten Öffnen mit F4,
anschließend wird dieselbe Oberfläche wiederverwendet.

Native Messung bei 960×540 und 60 FPS auf RTX 4070, ohne feste Simulationszeit
oder Screenshot-Aufzeichnung: Vorher erschien der erste Frame nach rund
1.870 ms beim neuen Run und 970 ms beim Fortsetzen. Nach der Änderung erscheint
die Klick-Rückmeldung bei beiden nach rund 17 ms. Der verbleibende einzelne
Aufbau-Frame lag bei rund 65–80 ms bzw. 53–55 ms. Das sind lokale Messwerte, keine
Leistungsgarantie für andere Geräte; die Vorbereitung wandert in den Spielstart.

Reproduzierbar mit isoliertem Spielstand über
`Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/measure_run_startup.gd`.
Das Werkzeug gibt Klickverarbeitung, erste sichtbare Rückmeldung, ersten
Frame der Run-Szene und längsten Frame getrennt aus.

## Prüfung

Die gezielten Tests `scene_transitions`, `progression_menu`, `upgrade_resume`, `post_wave_rewards`,
`story_mode`, `story_travel`, `story_boss_dialogue`, `mobile_controls` und `smoke`
bestanden nach der Einbindung. Der Übergangstest prüft insbesondere Lebensdauer
über echte Szenenwechsel, doppelte Aktivierung, fehlerhafte Ziele, Freigabe der
Textur und Eingaben, pausierte Menüs, Resize und reduzierte Bewegung.
Der vollständige Lauf der Einbindung bestand mit 117/117 Tests; nach der
visuellen Verfeinerung bestanden die Übergangs-, Menü- und Touchprüfungen erneut.
Nach der Optimierung von Starten/Fortsetzen bestanden erneut alle 117 Tests,
einschließlich der Prüfungen für den verzögerten Aufbau des Debug-Menüs und
den erweiterten Grafik-Warmup.

Die [native Vorschau](screenshots/scene_transitions/flow.gif) zeigt Hauptmenü →
Waffenauswahl → Kampf → Aufstiege → Shop → Kampf → Hauptmenü. Sie verwendet
isolierte Spielstände, stummes Audio und feste 30 FPS; sie ist keine Leistungsmessung.
Zwischenbilder bleiben im ignorierten `.godot/`-Verzeichnis.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter scene_transitions --filter progression_menu --filter post_wave_rewards --filter story_travel
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_shield_distance.gd -- --transition
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_scene_transitions.gd
ffmpeg -framerate 30 -i .godot/scene_transition_frames/frame_%03d.png -vf "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a" -loop 0 docs/screenshots/scene_transitions/flow.gif
```
