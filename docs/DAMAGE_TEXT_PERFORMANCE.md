# Schadenszahlen in voller Arena · 4. Oktober 2026

Handy-Rückmeldung nach den Angriffskorrekturen: `bacteria charge` etwa 60 FPS, `debug enemies` Minimum 47 / Durchschnitt 56, `debug map` Minimum 21,8 / Durchschnitt 29,5. Die volle Arena enthält zusätzlich den Trinity-/Zahnbürsten-Build, Item-Effekte und Beute. Die Auflösungsautomatik bleibt unverändert.

## Gefundene Kosten und Änderung

`tools/dense_arena_render_probe.gd` startet viermal die unveränderte `debug map` mit gleichem Seed. Ein Vergleich blendet nur Schadenszahlen aus: vorher sinken die Zeichenaufrufe von rund 408 auf 219 und die mittlere Framezeit von 2,61 auf 2,06 ms. Gegner-Overlays oder Item-/Evolutionsgrafiken auszublenden hilft in diesem kurzen Desktopvergleich wesentlich weniger. Die Ausblendungen sind ausschließlich Diagnose im Werkzeug, keine Gameplayoption oder Optimierung.

Jedes alte Label zeichnete Schriftumrandung und Schriftfüllung abwechselnd; jedes neue Label erzeugte zusätzlich einen Tween mit drei Animationen. `DamageNumberBatch` zeichnet jetzt zuerst alle Umrandungen, dann alle Füllungen. Text wird beim Erscheinen einmal vorbereitet und danach als [Godot TextLine](https://docs.godotengine.org/en/stable/classes/class_textline.html) wiederverwendet. Schrift, Farbe, Größe und Umrandung bleiben erhalten. Die gemeinsame Animation verwendet dieselben Cubic-/Back-Kurven, denselben Pivot, dieselben Zufallsbewegungen und die verzögerte Ausblendung. Verdeckte Labels erhalten keine laufenden Transform-/Layoutupdates.

Abgelaufene Labels werden außerhalb des Szenenbaums wiederverwendet; höchstens 128 ungenutzte bleiben als Reserve. Spieler-Schaden und wichtige Meldungen unterliegen weiterhin keinem kosmetischen Gegner-Schadensbudget. Lange Meldungen dürfen die Position einer später wiederverwendeten kurzen Zahl nicht verändern. Arena-Ausgang gibt die Reserve frei; externe Bereinigung löscht auch die zwischengespeicherten Zeichenbefehle.

## Messung und Grenzen

Natives Godot 4.7.2 Compatibility/OpenGL, RTX 4070, 1280×720, VSync aus. Pro Variante 4,5 Sekunden, erste 1,5 Sekunden ausgeschlossen; normale Physics-/Angriffe laufen weiter. Wandzeit zwischen Renderframes, keine isolierte Callbackmessung. Rendering-Abschaltungen verändern weder Schaden noch Item-Effekte. Das kurze Fenster und die Desktophardware erlauben keine Prognose für Handy-FPS.

| Volle `debug map` | Vorher | Nachher |
| --- | ---: | ---: |
| Mittlere Framezeit | 2,61 ms | 2,43 ms |
| P95 | 4,03 ms | 4,09 ms |
| Mittlere Zeichenaufrufe | 408 | 221 |

Das entspricht rund 7 % weniger mittlerer Framezeit und 46 % weniger Zeichenaufrufen. [Vorher](dense_arena_render_before.json), [nachher](dense_arena_render_after.json). Frühere Nachherläufe lagen bei 2,29 ms; die kurzen Desktopmessungen schwanken. Der letzte P95 ist praktisch unverändert. Nicht alle verbleibenden Kosten sind Schadenszahlen; auch die Messung ohne Texte bleibt teuer genug, dass weitere Geräte-Rückmeldung sinnvoll ist.

Die neue Prüfung deckt Bewegung, Pivot, Ausblendung, Farben, Wiederverwendung, Lebensdauer, Reservelimit und Bereinigung ab. Mit echtem Renderer wird die Ausgabe pixelweise gegen das bisherige Label verglichen. Bestehende Tests prüfen weiterhin Trefferfeedback, wichtige Meldungen und das kosmetische Budget.

```powershell
Godot_v4.7.2-stable_win64_console.exe --log-file .godot/dense_probe.log --path . --script res://tools/dense_arena_render_probe.gd -- --label=local
Godot_v4.7.2-stable_win64_console.exe --log-file .godot/damage_batch_test.log --path . --script res://tests/damage_number_batch.gd
```

Für den Handyvergleich die Seite frisch laden und `debug map` ähnlich lange wie vorher laufen lassen. Die Welle bleibt unverändert.
