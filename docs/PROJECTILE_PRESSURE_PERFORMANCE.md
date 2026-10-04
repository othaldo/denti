# Geschosse und Trefferupdates · 4. Oktober 2026

Handy-Rückmeldung: 7–40 FPS in der Testarena, Einbrüche beim ersten Laden/Schießen von Giftgeschossen oder Anstürmen, später teilweise 19 FPS. Aufgesammelte Beute und „Sparsam“ helfen wenig. Das spricht für weitere CPU-/Zeichenkosten; eine genaue Geräteursache ist ohne Profil nicht bewiesen. Die Auflösungsautomatik wurde nicht geändert.

## Änderungen

- Säure-, Boss-, Gift- und Blutungsgeschosse sowie die Raumkontroll-Orbs teilen einen vorbereiteten Atlas. Alle 29 derzeit verwendeten Körper-/Ringvarianten liegen bereits als PNG vor. Ihre erstmalige Bilderzeugung mit einzelnen Pixeloperationen entfällt im Kampf. Unterschiedliche Farben können gemeinsam gezeichnet werden, weil sie dieselbe GPU-Textur verwenden.
- Das Menü-Warmup zeichnet jetzt alle Varianten einmal im bestehenden separaten 8×8-Viewport. Bisher wurden nur drei Bossbilder vorbereitet. Eigene Farben/Radien behalten einen gecachten prozeduralen Fallback; bei neuen Standardvarianten den Atlas neu erzeugen.
- Überlebende normale Gegner bauen nach einem Treffer ihre Zeichenbefehle nicht mehr neu auf. Das Trefferblinken verwendet weiterhin `modulate`; Schaden, Treffer-Signale und Tod bleiben erhalten. Boss-/Elite-Lebens- und Schutzanzeigen aktualisieren sich weiterhin.
- Nass-/Schmelzfreilegungsanzeigen werden bei Beginn und Ablauf aktualisiert. Erneutes Anwenden verlängert weiterhin den Effekt, ohne dieselben Kreise neu aufzubauen. Blutungsanzeigen aktualisieren sich bei veränderter Stapelzahl und Ablauf.
- `debug enemies` ergänzt die Handy-Testcodes: die gleiche Dichte von 110 Gegnern wie `debug map`, ohne eigene Waffen, Items und Beute. Damit lassen sich verbleibende Gegner-/Geschosskosten vom Bürsten-Build eingrenzen. [Verwendung](TEST_ARENAS.md).

Gegnerzahlen, Angriffe, Geschossgrößen, Kollisionsradien, Schaden und Laufzeiten bleiben erhalten. Der Atlas verwendet die ursprüngliche Rasterfunktion und ist 1024×908 Pixel groß, entsprechend etwa 3,55 MiB unkomprimiertem RGBA-Speicher.

## Gemessene Zeichenkosten

`tools/projectile_pressure_probe.gd`: 600 stationäre Geschosse, abwechselnd Säure/Gift/Blutung, kein Spielerziel, 1280×720, VSync aus. Natives Godot 4.7.2 Compatibility/OpenGL auf RTX 4070. Fünf Sekunden Laufzeit, erste 0,5 Sekunden nicht in den Framewerten. Vorher dieselben Sprite-/Physics-Pfade mit separaten Farbtexturen; nachher Atlasregionen. Die Nachhermessung lief ohne parallele Tests.

| Messwert | Vorher | Nachher |
| --- | ---: | ---: |
| Zeichenaufrufe pro Frame | 600 | 1 |
| Mittlere Framezeit | 1,774 ms | 0,304 ms |
| P95 Framezeit | 2,366 ms | 0,384 ms |

Die mittlere Framezeit sinkt in diesem isolierten Szenario um rund 83 %. Das ist keine Messung des kompletten Spiels oder des Snapdragon 888. Stationäre Geschosse isolieren wechselnde Texturen; ihre normalen Physics-Callbacks und Sprite-Pulse laufen weiter. GPU-Kaltstartspitzen sind nicht in den Framewerten enthalten. Erzeugen vieler Geschoss-Nodes kostet weiterhin Arbeit.

Rohdaten: [vorher](projectile_pressure_before.json), [nachher](projectile_pressure_after.json). Die Handywirkung muss nach dem Deployment erneut verglichen werden.

## Prüfen und reproduzieren

`tests/prepared_projectile_atlas.gd` vergleicht alle 29 Regionen bytegenau mit dem ursprünglichen Rasterbild und prüft gemeinsame Textur und Sonderfall-Fallback. `tests/enemy_render_updates.gd` zählt echte Draw-Callbacks bei Treffern, Statusbeginn/-refresh/-ablauf, Blutungsstapeln und Boss-/Elite-Treffern; Schaden und Trefferblinken werden mitgeprüft. Der erweiterte Warmup-Test prüft erste Gift-/Blutungsangriffe ohne neue Texturen sowie unveränderte Attackenparameter. Die Atlasdarstellung wurde visuell kontrolliert.

```powershell
# Atlas nach neuen Standardfarben/Radien aktualisieren, dann Godot importieren.
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_enemy_projectiles.gd
Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/projectile_pressure_probe.gd -- --label=local
```

Die Rendering-Probe speichert nur ihren Messbericht unter `docs/`; sie startet keinen normalen Run und schreibt keinen Spielstand.
