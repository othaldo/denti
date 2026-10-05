# Weniger Arbeit in häufigen Kampfpfaden

Die Handyberichte für `af75977` zeigen 39,90 FPS im Stehen und 34,94 FPS in Bewegung. Die Draw-Call-Momentaufnahmen sinken gegenüber `c1b0053` von 229/222 auf 139/147. Der stehende Durchschnitt steigt um rund 11 %, der bewegte Durchschnitt bleibt praktisch gleich; P99 sinkt beim Bewegen von 71 auf 62 ms. Die Testdauern und Angriffszustände unterscheiden sich. Konstante 60 FPS sind damit weiterhin nicht erreicht.

## Änderungen

- **Statusbewegung:** Nass, Exposition und Tempo allein erzwingen nicht mehr den allgemeinen Einzelgegner-Pfad. Die zentrale Simulation aktualisiert ihre Uhren, entfernt abgelaufene Anzeigen und berechnet das bisherige Lauftempo. Angriffsbeginn, Warnung, Charge, Blutung, Eliten, Bosse und transformierte Arenen verwenden weiter den vollständigen Pfad. Eine Statusuhr wird beim Übergang in eine Warnung genau einmal aktualisiert.
- **Schadenszahl-Layout:** Gleiche Texte mit derselben Schrift und Größe teilen eine fertig geformte `TextLine`. Farbe, Umrandung, Bewegung und Transparenz bleiben pro Zahl unabhängig. Der Cache enthält höchstens 256 Layouts, wird bei Schriftänderungen invalidiert und beim Verlassen der Arena geleert. Die vorhandene gemeinsame Zeichenreihenfolge für Umrandungen und Schrift bleibt erhalten.
- **Warnzeichen:** Radius und Fortschritt wählen vorbereitete Atlas-Zellen über numerische Tabellen. Linien, Kreisflächen und Markierungen verwenden direkte Texturreferenzen. Formatierte Zeichenketten und wiederholte Textursuche entfallen während dieser Zeichenaufrufe; die Grafikdateien und Zeichenbefehle bleiben gleich.

Godots [TextLine](https://docs.godotengine.org/en/stable/classes/class_textline.html) enthält das geformte Schriftlayout. Wir teilen dieses fertige Layout, statt es für identische Schadenswerte erneut aufzubauen.

## Lokale Messungen

Godot 4.7.2, Windows, RTX 4070; isolierte Messungen zeigen CPU-Arbeit, keine Android-FPS-Prognose:

| Vergleich | vorher | nachher |
| --- | ---: | ---: |
| zentrale Bewegung, 110 nasse Gegner, ms/Tick | 0,6706 | 0,2926 |
| Vorbereitung einer wiederkehrenden Schadenszahl, µs | 30,03 | 26,01 |
| Zeichnen von 60 Warn-Lanes, ms/Frame | 0,464 | 0,328 |

Die Bewegung benötigt in diesem gezielten Fall etwa 56 % weniger CPU-Zeit. Textvorbereitung spart etwa 13 %, Warnzeichnung etwa 29 %. Die Positions-/Textbreiten-Prüfsummen sind gleich. Der native Warn-Lane-Vergleich prüft drei Fortschritte sowie Rotation, Spiegelung und nichtuniforme Skalierung; seine neun Vergleiche sind pixelgleich.

Die vollständige native Bürsten-Testarena liegt in einem kurzen Vergleich bei 330,71 bzw. 337,36 FPS (300 Aufwärmframes, 1800 Messframes, feste Simulation 1/60 s, VSync aus). Das sind ungefähr 2 %; einzelne kurze Durchläufe belegen keinen stabilen Gewinn dieser Größe. Insbesondere enthält dieses Preset keine Wasserwaffe und nutzt den verbesserten Nass-Pfad kaum. Texturspeicher und Gegner-/Geschoss-/Beutemengen bleiben in diesem Vergleich gleich. Die Handywirkung muss gesondert gemessen werden.

Ein verworfener Versuch speicherte die Zeichenbefehle jeder Schadenszahl in eigenen Canvas-Items. Er reduzierte die erneute Schriftarbeit, verhinderte aber bei unterschiedlichen Transparenzen die Bündelung: 120 Zahlen stiegen im isolierten Test von 2 auf über 210 Draw Calls. Dieser Renderer ist nicht Teil der Änderung.

## Prüfen

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_enemy_physics.gd -- --wet
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_damage_text_layout.gd
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script res://tools/benchmark_warning_lanes.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --verify
```

`central_enemy_motion` vergleicht pro Tick den vollständigen Gegnerzustand, Kontakt-Schaden und die Angriffsreihenfolge gegen die Einzelgegner-Simulation. Die Eingaben enthalten überlappende und ablaufende Statusuhren, Status-Auffrischung, Angriffsbeginn, Teleports, geändertes Tempo und transformierte Arenen. `damage_number_batch` prüft Layout-Teilung ohne gegenseitige Mutation, unterschiedliche Schriftgrößen, Invalidierung, Cachegrenze und Pool-Aufräumen; sein nativer Bildtest vergleicht die Darstellung gegen das ursprüngliche Label. `prepared_combat_textures` prüft alle numerisch ausgewählten Fortschrittszellen gegen die vorbereiteten Grafiken.

Der volle Testlauf deckte außerdem eine zufällige Fehlannahme in `enemy_behaviors` auf: Ein später Säurespucker kann eine Blutungs- oder Gift-Eigenschaft erhalten; seine Geschosse sind dann statusfarben. Der Test verlangt jetzt die tatsächlich zugehörige Farbe und prüft gewöhnliche, Gift- und Blutungsfächer explizit samt Status-Payload. Er verlangt weiterhin drei Geschosse, korrekte Streuung und den vorgesehenen Schaden.
