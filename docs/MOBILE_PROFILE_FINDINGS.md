# Mobile Messung und nächster Optimierungsschritt

Chrome auf einem Handy mit Snapdragon 888, volle Auflösung, Build `225cb45`. Die drei vom Spieler kopierten Berichte liefen 20–26 Sekunden mit 110 Gegnern und 1115 verbleibenden Beuteobjekten.

| Variante | FPS Ø | Minimum (1 s) | P95 / P99 | letzte Speicherung |
| --- | ---: | ---: | ---: | ---: |
| volle Diagnosearena | 26,52 | 17,58 | 69 / 92 ms | 22,7 ms |
| ohne Zeichnung der Spielwelt | 50,64 | 39,60 | 36 / 70 ms | 28,0 ms |
| ohne Trefferfolgen bei Gegnern | 36,53 | 26,22 | 40 / 49 ms | 18,9 ms |

Zeichnen und Trefferfolgen kosten beide deutlich Zeit. Auch ohne Zeichnung werden keine konstanten 60 FPS erreicht. Das ist keine reine GPU-Diagnose: Der Zeichenvergleich entfernt auch CPU-Arbeit für Zeichnungen und sichtbare Schatten; der Treffervergleich entfernt zusätzlich viele Effekte und Schadenszahlen. Die Varianten sind keine voneinander unabhängigen Zeitanteile. Geschosszahlen und Angriffstimer unterscheiden sich im Verlauf.

Die geschätzte Gegnerphysik beträgt 10,10 ms pro dargestelltem Frame im Volltest und 5,70 ms ohne Zeichnung. Bei niedrigen FPS fallen mehr 60-Hz-Physikschritte in einen dargestellten Frame: Multipliziert mit den jeweiligen FPS ergeben sich ungefähr 268 beziehungsweise 288 ms Gegnerphysik pro Sekunde. Der Zeichenvergleich halbiert also nicht nachweislich die Kosten eines einzelnen Physikschritts. Die inklusive Trefferzeit von 6,71 ms darf nicht zusätzlich auf Waffen- und Geschosszeiten addiert werden.

Die letzte Speicherung braucht 19–28 ms, also mehr als das 16,7-ms-Budget eines 60-FPS-Frames. Das kann einzelne Spitzen verursachen, erklärt aber nicht den gesamten niedrigen FPS-Schnitt. Gemeldeter Texturspeicher: 475.225.553 Bytes (etwa 453 MiB); aus dieser Momentaufnahme allein lässt sich kein Speicherengpass beweisen.

## Änderung

Die Dreifaltigkeitsbürste zeichnet für jedes markierte Ziel einen 16-Punkte-Ring. Diese Ringe werden jetzt beim Entwickeln mit Godot in den bestehenden Glyphenatlas gerendert. Elf Radiusvarianten decken die aktuellen Gegner ab; neue, nicht vorbereitete Radien verwenden weiter die vorhandene Geometrie. Durchmesser, Polygonorientierung, Farbe und Breite bleiben erhalten; die Texturfilterung glättet die Rasterkanten etwas anders. Der Atlas wird beim App-Warmup vorbereitet. Kampf und Markierungsdetonationen bleiben unverändert.

Treffer vermeiden außerdem String-Konvertierungen bei Item-Power-Abfragen, die temporären Waffenlisten beim Weiterreichen an Evolutionen, Reliktabfragen ohne Relikte sowie mehrfach identische Hit-Flash-Schreibzugriffe innerhalb desselben Frames. Keine Proc-Frequenzen, Treffer oder Physikschritte werden ausgelassen.

## Prüfung und Grenzen

Isolierter nativer Test mit 100 gleichzeitig neu gezeichneten Markierungsringen auf einer RTX 4070, ohne VSync, abwechselnd 600 Frames je Pfad:

| Pfad | Zeichenaufrufe | GDScript-Zeichenzeit | gesamte Framezeit |
| --- | ---: | ---: | ---: |
| Polygon | 100 | 0,745–0,752 ms | 1,328–1,338 ms |
| vorbereitete Textur | 1 | 0,210–0,213 ms | 0,427–0,437 ms |

In einer einzelnen vollen Desktop-Diagnosemessung sank die Momentaufnahme der Zeichenaufrufe von 271 auf 221. Der FPS-Schnitt verbesserte sich dort nicht (238 gegenüber 232 FPS); diese kurze Messung ist kein Beleg für eine Verbesserung der gesamten Arena. Der größere Atlas erhöhte den gemeldeten Desktop-Texturspeicher um etwa 4,5 MiB. Der isolierte Gewinn muss auf dem Handy anhand derselben Diagnosecodes erneut geprüft werden. Es gibt keine Zusage konstanter 60 FPS.

Die Ringdarstellung wurde mit nativen Grafikframes visuell geprüft. `tests/prepared_combat_textures.gd` prüft die gemeinsamen Atlasregionen, Radien und freien Ringmitten aller aktuellen Gegner; vorhandene Tests prüfen Evolutionen, Item-Synergien, Relikte und Hit-Flash-Verhalten.
