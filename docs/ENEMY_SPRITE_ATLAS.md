# Gemeinsame Gegnertextur

Die Handyberichte für `c1b0053` liegen bei 35,9 FPS stehend und 35,2 FPS bewegt. Gegenüber `739cf8b` ist damit kein Gewinn des Spielerprojektil-Pools nachgewiesen; auch P95/P99 sind nicht besser. Die Angriffszustände und Testdauer unterscheiden sich, weshalb diese Einzelvergleiche keine sichere Regression belegen. Die Rendering-Arbeit bleibt ein Ansatzpunkt.

## Umsetzung

Plaque, Bakterium, Zucker, Säurespucker, Giftkeim und Zahnfleischbeißer teilen nun eine vorbereitete Textur. Säurekrone und Jagdkeim verwenden dieselben Zellen mit ihren bisherigen Farbtönen. Die acht EnemyData-Resources verweisen auf `AtlasTexture`-Zellen unter `assets/enemies/packed/`.

Der Atlas enthält die vollständigen importierten Originalpixel ohne Größenänderung oder Beschnitt. Sein Format ist 2520 × 3572 Pixel; vier transparente Pixel trennen die Zellen, und `filter_clip` schützt vor dem Anschnitt benachbarter Grafiken. Die virtuelle Texturgröße jeder Zelle entspricht dem bisherigen Einzelbild. Sprite-Skalierung, Animation, Spiegelung, Trefferfarbe, Zeichenreihenfolge und Statusanzeigen verwenden dadurch weiterhin den bestehenden Sprite2D-Pfad. Es gibt keine zusätzlichen Kampfcallbacks oder Positionsspeicher.

Die Original-PNGs bleiben zur Bearbeitung und zum Prüfen im Repository. Der Web-Export schließt die sechs ersetzten Einzelbilder aus; die Arena lädt ausschließlich den gemeinsamen Atlas. Das bisherige Hauptmenü-Warmup zeichnet die EnemyData-Grafiken bereits vor dem Kampf und verwendet damit auch den Atlas.

Godots [AtlasTexture-Dokumentation](https://docs.godotengine.org/en/stable/classes/class_atlastexture.html) beschreibt gemeinsame Texturen als Mittel zur Reduktion von Renderaufrufen. Die [GPU-Optimierungshinweise](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html) erklären den Aufwand von API-/Texturwechseln und 2D-Bündelung, insbesondere bei OpenGL ES und WebGL. In unserem Vergleich greifen diese Vorteile bereits mit gewöhnlichen Sprite2D-Nodes.

## Vergleich

Native RTX 4070, VSync aus, fester Simulationsschritt 1/60 s, volle `debug map` mit stehender Figur, 300 Aufwärmframes und 1800 Messframes:

| Messwert | Einzelbilder | gemeinsamer Atlas |
| --- | ---: | ---: |
| FPS Ø | 307,77 | 336,76 |
| Minimum (1 s) | 298,09 | 329,56 |
| maximale Framezeit | 15,357 ms | 15,259 ms |
| Zeichenaufrufe, Momentaufnahme | 206 | 112 |
| Texturspeicher, Momentaufnahme | 467.037.057 Bytes | 473.121.125 Bytes |

Dieser kurze Vergleich zeigt ungefähr 9 % mehr Durchschnitts-FPS und 46 % weniger Zeichenaufrufe. Gegner, gegnerische/eigene Geschosse und Beute waren identisch (110 / 74 / 9 / 1115). Die maximale Framezeit ist praktisch unverändert. Die freie Fläche zwischen den Originalbildern kostet im gemeldeten Texturspeicher etwa 6,1 MB zusätzlich; die Gesamttexturen steigen um ungefähr 1,3 %. Die Hardware und der Browser können anders reagieren, und konstante 60 FPS auf Android sind damit nicht belegt.

Ein zusätzlich geprüfter MultiMesh-Prototyp bündelte auch verschieden gefärbte Körper vollständig, benötigte aber eine eigene Transformation-/Farbaktualisierung pro Frame. Im nativen instrumentierten Gegenvergleich war der gewöhnliche Sprite-Pfad mit gemeinsamem Atlas schneller (etwa 318 gegenüber 301 FPS). Der ausgelieferte Stand enthält deshalb den Atlas ohne diesen zusätzlichen Renderer. Die CPU-Instrumentierung bleibt unverändert, sodass der nächste Handybericht keine Umstellung der Messcallbacks enthält.

## Erzeugung und Prüfung

Nach Änderungen an den Originalbildern neu erzeugen und importieren:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_enemy_sprites.gd --log-file .godot/bake_enemy_sprites.log
Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import --quit
```

`tests/enemy_sprite_atlas.gd` vergleicht alle gepackten RGBA-Pixel und Abmessungen exakt mit den importierten Originalbildern. Außerdem prüft er die Zellverweise und vollständigen Bildgrößen aller acht Gegner-Resources. Die vorhandenen Tests decken unter anderem Blickrichtung, Statusanzeigen, Bossdarstellung, Save/Resume und Kampfabläufe ab.

Der native Bildvergleich rendert dieselben 110 eingefrorenen Gegner mit separaten Originaltexturen und anschließend mit Atlas-Zellen. Er prüft auch Überlappung, Spiegelung, gedrehte/skalierte Eltern, Sprite-Offsets, Trefferfarben und Transparenz. Bei drei Szenarien beträgt die größte GPU-Pixeldifferenz ein Byte pro Farbkanal; der Mittelwert liegt unter 0,002 Bytes. Bei gemeinsamen Farben fallen die gesamten Zeichenaufrufe von 112 auf 3 (einschließlich Schatten und Vorschaubild), bei gemischten Farben auf 76. Unterschiedliche Farbzustände begrenzen also weiterhin die automatische Bündelung.

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script res://tools/benchmark_enemy_sprites.gd --log-file .godot/benchmark_enemy_sprites.log -- --capture
```

Screenshots liegen unter `.godot/enemy-sprite-compare/`. Headless kann diesen GPU-Vergleich nicht ausführen. Zusätzlich wurde das exportierte Web-Datenpaket aus einem leeren Arbeitsverzeichnis geladen: 110 Gegner wurden mit gültigen Atlas-Zellen erstellt, während die ausgeschlossenen Originaltexturen nicht verfügbar waren. Der eigentliche Web-Binary-Export wird von der GitHub-Pipeline geprüft.
