# Lane-Warnungen mit dem vorhandenen Atlas zeichnen

## Anlass

Chrome/Snapdragon 888, volle Auflösung, Build `7a17af9`:

| Variante | FPS Ø | Minimum (1 s) | P95 / P99 |
| --- | ---: | ---: | ---: |
| volle Diagnosearena | 28,23 | 21,41 | 62 / 86 ms |
| zusätzliche Effektzeichnungen aus | 36,83 | 29,85 | 48 / 77 ms |

Gegenüber dem vorherigen Volltest mit 26,52 FPS ist der Schnitt etwas höher. Die unterschiedlichen Laufzeiten, Geschosszahlen, Angriffstimer und Gerätezustände erlauben keine genaue Zuordnung dieses kleinen Unterschieds zu einer einzelnen Änderung. Der Effektvergleich entfernt CPU-Zeichenarbeit und GPU-Arbeit; er misst keine reine GPU-Zeit.

Die volle Arena enthält 37 Säurespucker. Ab Welle 13 verwenden diese **Lane-Angriffe**, nicht mehr ihren früheren Schussfächer. Die Warnfläche wurde als einfarbiges Polygon gezeichnet, ihre Begrenzungen und Fortschrittsringe mit dem vorbereiteten Atlas. Dieser Wechsel verhinderte die gemeinsame Ausgabe vieler gleichzeitiger Warnungen.

## Änderung

Die rechteckige Lane-Fläche verwendet jetzt ebenfalls den vorhandenen weißen Atlasbereich. Eine um ein Pixel nach innen versetzte 2×2-Region bleibt beim Strecken vollständig weiß; dadurch entstehen keine weichen Ränder durch die transparenten Nachbarpixel. Es werden keine Bilder erzeugt oder zusätzlichen Bilddaten geladen. Der normale App-Warmup bereitet den Atlas bereits vor.

Warnfläche, Breite, Richtung, Transparenz und Fortschrittsring bleiben erhalten. Gegner- und Angriffslogik, Schüsse, Statusregeln und Physiktakt bleiben unverändert. Andere Warnformen verwenden weiter ihre vorhandenen Zeichenpfade.

## Vergleich

`tools/benchmark_warning_lanes.gd` vergleicht die historische Polygonfläche mit dem neuen Pfad im selben nativen Fenster. 60 gleichzeitig angekündigte Lanes, VSync aus, abwechselnd 600 Frames je Pfad auf einer RTX 4070:

| Pfad | Zeichenaufrufe | GDScript-Zeichenzeit | gesamte Framezeit |
| --- | ---: | ---: | ---: |
| Polygonfläche | 120 | etwa 0,63 ms | etwa 1,35 ms |
| Atlasfläche | 1 | etwa 0,44 ms | etwa 0,67 ms |

Das ist eine isolierte Zeichenmessung, keine Aussage über die gesamte Handy-Arena. Eine einzelne vollständige Desktop-Diagnose sank von 278 auf 223 Zeichenaufrufe; FPS Ø lag bei rund 240 vorher und 243 danach. Der gemeldete Texturspeicher blieb gleich. Die Gesamtverbesserung ist auf dem Handy zu prüfen.

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --verify
```

Der zweite Aufruf vergleicht gerenderte Bilder gegen den alten Polygonpfad: 60 Richtungen, drei Fortschrittsstände, Drehung, nicht einheitliche Skalierung, Scherung, Spiegelung und Farbmodulation. Die neun nativen Bildvergleiche waren pixelgleich. `tests/prepared_combat_textures.gd` prüft zusätzlich die Wiederverwendung der Atlasregion und ihre vollständig weißen, opaken Pixel. Die vorhandenen Kampf-/Warnungstests prüfen weiterhin Angriffe, Kollisionsbahnen und Speicherzustände.

Für den nächsten Handyvergleich die Seite neu laden, Build-ID prüfen, `debug profile` frisch starten und mit derselben Grafikoption/Ausrichtung rund 30 Sekunden stehen bleiben. Der kopierte Bericht ermöglicht den Vergleich mit den obigen Werten.
