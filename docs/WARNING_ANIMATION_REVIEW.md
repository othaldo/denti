# Bodenwarnungen: Bestand, Animation und Performance

**Inzwischen umgesetzt:** [Gemeinsame animierte Texturwarnungen](TEXTURED_WARNINGS.md).
Der folgende Text hält die Untersuchung vor dieser Umsetzung fest.

Untersuchung vom 20.10.2026. Keine Kampfwerte, Grafiken oder Renderpfade im
Spiel durch diese Untersuchung geändert.

## Was bereits vorhanden ist

- `GroundEffects` zeichnet die älteren Kreisflächen aus einem vorbereiteten
  1152×384-Atlas, ein Texturrechteck pro Fläche.
- `CombatGlyphs` enthält unter anderem vorbereitete Fortschrittsringe mit
  65 Ständen; `CombatDrawCache` verwendet diese bei passenden Radien und
  wechselt für andere Konturen auf wiederverwendete Geometrie.
- `AttackEffects` verwendet bereits einen gemeinsamen 1024×1680-Atlas.
  Charge-/Lane-Bodenflächen haben vier Bilder. Der Bildindex wird mit
  `floor(seconds * 12) % 4` gewählt; bei Warnungen kommt `seconds` aus
  `progress * 0.6`, nicht aus einer unabhängigen Echtzeituhr.
- Die Lane-Grafik stammt aus `charge_ground_source.png`: gemalte Risse,
  Steine und Rauch. Der Offline-Baker macht daraus eine neutrale, tintbare
  240×112-Zelle. Im Spiel wird sie auf die gesamte Länge und Breite der
  jeweiligen Bahn skaliert. Die vier Phasen verändern vor allem die Helligkeit.
  Eine gestreckte, kontrastreiche Riss-/Rauchfläche ist deshalb ein plausibler
  Grund für den als unpassend empfundenen Stil; das ist eine gestalterische
  Einschätzung, kein gemessener technischer Fehler.
- Warnungen werden unter den Figuren gemeinsam ausgegeben. Überlagerte
  Lane-Füllungen erhalten die vorhandene, räumlich abgestufte Transparenz.
- Die drei Graf-Formen gehen noch über `CloakStrikeArea`: pro Fan entstehen
  Punkte und Linien, der Ring erzeugt 64 einzelne Füllsegmente plus Konturen
  und Fortschrittsanzeige. Dieser Pfad nutzt die vorbereiteten Warnatlanten
  noch nicht. Anzahl der Zeichenbefehle ist nicht gleich Anzahl GPU-Drawcalls.

## Frischer nativer Vergleich

`tools/benchmark_warning_lanes.gd`, Godot 4.7.2, Compatibility, RTX 4070,
60 gleichzeitige Lanes, VSync aus; zweimal abwechselnd je 600 Messframes.
Der historische Polygonpfad und der aktuelle Atlaspfad haben bewusst
unterschiedliche Grafik. Dies ist keine Messung des neuen Graf-Rings.

| Pfad | GPU-Drawcalls | GDScript-Zeichenzeit | Gesamte Framezeit |
| --- | ---: | ---: | ---: |
| historische Polygone, Lauf 1 | 120 | 0,511 ms | 1,257 ms |
| aktueller Atlas, Lauf 1 | 1 | 0,494 ms | 0,769 ms |
| historische Polygone, Lauf 2 | 120 | 0,513 ms | 1,270 ms |
| aktueller Atlas, Lauf 2 | 1 | 0,520 ms | 0,801 ms |

Die GDScript-Zeit ist hier praktisch gleich; der Gewinn liegt in diesem
isolierten Aufbau bei der Renderausgabe. Die Werte sind keine Vorhersage
für FPS auf einem Telefon oder im vollständigen Kampf. Überlappende transparente
Flächen kosten auch als Atlas Pixelarbeit. Der dichte Pfad mit acht
Transparenzstreifen wurde in diesem Lauf nicht separat gemessen.

## Empfohlene Darstellung

Die klare Sprache der älteren Kreise als Grundlage verwenden: gut erkennbare
Gefahrengrenze, ruhige durchscheinende Füllung, dezenter heller Fortschritt.
Kein rauchender, aufgerissener Boden als allgemeine Charge-Ankündigung.

1. Kreis, Ring, Fächer und Bahn aus derselben Gestaltung und einem gemeinsamen
   Atlas ableiten. Den angekündigten gesamten Bereich von Beginn an sichtbar
   halten; eine Animation darf ihn nicht scheinbar verkleinern.
2. Die Grundfläche und ihre genaue Grenze bleiben fest. Licht wandert innen
   zur Grenze, verdichtet sich zum Angriff und erhält einen kurzen Schlagimpuls.
   Beim Grafen kann die Füllung eine dezente Stoff-/Saum-Anmutung haben.
3. Animation bevorzugt über kleine vorbereitete Lichtphasen und die bestehenden
   Fortschrittsringe. Farbe und Deckkraft können zusätzlich weich überblendet
   werden. Keine Bildgenerierung, Pixelbearbeitung, neuen Viewports oder
   Materialkopien während eines Angriffs.
4. Eine Bahn aus festen Endstücken und einer wiederholbaren Mitte zusammensetzen,
   falls die Grafik Strukturen enthält. Eine einzelne gemalte Rissfläche nicht
   über jede Bahnlänge ziehen. Fächer und Ring in ihren passenden Proportionen
   vorbereiten; Bemaßung weiter aus den bestehenden Angriffsressourcen beziehen.
5. Die bestehende Überlagerungsdämpfung für Lanes und klare Priorität von
   Bosswarnungen erhalten. Überlagerung nicht durch immer stärkeres Glühen lösen.

Ein einfacher gemeinsamer 2D-Shader ist eine mögliche Alternative für weiches
Schimmern und Fortschritt. Er ist nicht automatisch schneller als kleine
Atlasphasen: gleiche Textur/Material und wenig transparente Überlagerung bleiben
wichtig. Godots `TIME` läuft bei Pause weiter; für kampfsynchrone Effekte muss
stattdessen der vorhandene Angriffstimer beziehungsweise eine pausierbare
Spieluhr verwendet werden.

Keine vollständigen hochauflösenden 60-FPS-Bildfolgen pro Warnform anlegen.
Schon acht 512×512-RGBA-Bilder brauchen ohne Mipmaps 8 MiB. Bestehende Atlanten
enthalten derzeit ungefähr 18,97 MiB (`combat_glyphs`), 1,69 MiB (`ground_effects`)
und 6,56 MiB (`attack_effects`) reine RGBA-Pixel; PNG-Dateigröße und tatsächlich
gemeldeter Texturspeicher sind davon zu unterscheiden.

## Sinnvoller nächster Vergleich

Eine überarbeitete Charge-Bahn und den Graf-Ring mit gemeinsamer Textur zuerst
als getrennte Vorschau gegen den Bestand stellen. Prüfen: Anfang/Mitte/Ende der
Warnung, Pause/Fortsetzen, schmale und lange Bahnen, mobile Größe und viele
Überlagerungen. Danach Renderzeit, Drawcalls und Texturspeicher nativ messen;
für die Freigabe zusätzlich denselben dichten Web-Aufbau auf dem Telefon.
Die exakten Trefferflächen bleiben ausschließlich Sache der bestehenden
Geometrie-/Kampflogik.

Quellen: [Godot GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html),
[CanvasItem shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html).
