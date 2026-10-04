# Performance bei voller Arena · 4. Oktober 2026

Auslöser war ein Bericht über teilweise 7 FPS in Welle 17 auf Chrome/Snapdragon 888 bei voller Auflösung und Zahnbürsten/Dreifaltigkeitsbürste. Ohne Geräteprofil ist die genaue Ursache nicht bewiesen. Diese Änderung reduziert messbare CPU-Arbeit und Zeichenaufrufe unabhängig von der Grafikoption; die Auflösungsautomatik bleibt unverändert.

## Änderungen

- Bodenbeute liegt in einem räumlichen Raster. Ein gemeinsamer Physics-Tick prüft nur Zellen in Dentis Magnet-/Aufhebereich. Entfernte Drops haben keine eigenen Physics-Callbacks. Beim Beutesammeln nach der Welle werden weiterhin alle Drops animiert und vollständig eingesammelt. Position, Menge, Truhen-ID und Speicherformat bleiben erhalten.
- Die Zielsuche findet direkt den nächsten gültigen Gegner. Sie erzeugt und sortiert keine vollständige Trefferliste mehr. Wurzellage, Kolliderradius, Reichweite und Spawnreihenfolge bei gleich entfernten Zielen bleiben maßgeblich.
- Kreis-/Segmentabfragen prüfen direkt die Rasterzellen, ohne zusätzliche Kandidatenlisten. Bereits getroffene Gegner werden vor der Segmentgeometrie ausgeschlossen. Geschosse sortieren ihre tatsächlichen Treffer nur einmal entlang der Flugrichtung; doppelte Geometrieprüfungen entfallen.
- Unveränderliche Reichweiten und Darstellungsradien werden beim Abschuss ermittelt. Laufende Item-Cooldowns verhindern unnötige Zielsuche für Krit-Strahlen und Blutungsübertragung.
- Gegnerschatten werden in einem gemeinsamen MultiMesh unter den Gegnern gezeichnet. Es entstehen keine zusätzlichen Kinder im Gegnercontainer; Spawning, Bosslisten, Save/Resume und Gegnerlimits bleiben kompatibel. Standalone-Gegner behalten ihren bisherigen Schatten. Grundlage: [Godot MultiMesh](https://docs.godotengine.org/en/stable/classes/class_multimesh.html) und [CanvasItem.draw_multimesh](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-multimesh).

## CPU-Messung

`tools/dense_combat_cpu_probe.gd` ruft definierte Arbeitsschritte direkt auf, bei pausiertem Baum und ohne Rendering. Sieben Messblöcke mit je 300 Schritten; angegeben ist der Median pro Schritt. 400 stationäre Gegner, 360 stationäre, stark durchschlagende Testgeschosse beziehungsweise 1800 entfernte Drops. Das isoliert Abfragekosten; es sind keine FPS-Werte und keine reale Waffenbalance.

| Arbeit pro Schritt | Vorher | Nachher | Verringerung |
| --- | ---: | ---: | ---: |
| Sechs Suchen nach dem nächsten Gegner | 1,990 ms | 0,451 ms | 77 % |
| 360 Geschoss-Ticks bei 400 Gegnern | 4,406 ms | 2,827 ms | 36 % |
| 1800 entfernte Beutestücke | 0,891 ms | 0,0022 ms | über 99 % |

Rohdaten: [vorher](dense_combat_cpu_before.json), [nachher](dense_combat_cpu_after.json).

## Gerenderte Belastungstests

`tools/combat_performance_probe.gd`, natives Godot 4.7.2, Compatibility/OpenGL, RTX 4070, 1280×720, VSync aus. Je Szenario 0,5 Sekunden Aufwärmen und vier Sekunden Messung. Gleiche lokale Waffen-/Statusdaten vor und nach den Performanceänderungen. Gemessen wird echte verstrichene Zeit zwischen Renderframes; interne Godot-Zeitmonitore im JSON sind ergänzende, geglättete Monitore und nicht direkt als Kosten eines einzelnen Frames zu interpretieren.

| Szene | Mittlere Framezeit vorher → nachher | P95 vorher → nachher | Zeichenaufrufe vorher → nachher |
| --- | ---: | ---: | ---: |
| 400 Gegner + 360 bewegte Geschosse | 5,84 → 4,23 ms | 10,21 → 7,86 ms | 880 → 532 |
| 200 bewegte Gegner + sechs Kontaktwaffen | 3,77 → 2,89 ms | 5,83 → 4,90 ms | 825 → 526 |
| 1800 Boden-Drops | 0,94 → 0,93 ms | 1,80 → 1,46 ms | 35 → 35 |

Die mittlere Framezeit verbessert sich in den beiden Kampfszenarien um rund 28 beziehungsweise 23 Prozent. Bei Bodenbeute sinkt die CPU-Arbeit stark; der Desktop-Renderdurchsatz war dort schon vorher schnell. Einzelne Spitzen und kleine Unterschiede sind systemabhängig.

Rohdaten: [vorher](combat_performance_dense_before.json), [nachher](combat_performance_dense_after.json).

Zusätzlich läuft mit `--sustained --trinity` ein 20-sekündiger Test bei 2400×1080 und voller Auflösung: eine Dreifaltigkeitsbürste plus drei Tier-IV-Zahnbürsten, On-hit-Items, 110 Gegner mit künstlich hoher Lebensenergie und anfangs 1200 Drops. Gegner bleiben dadurch im Bild; es wird keine bereits leere Welle gemessen. Ergebnis: 2,55 ms mittlere Framezeit, 4,56 ms P95, 22,64 ms Maximum. Der abschließende Save mit 110 Gegnern und 1035 Drops dauert 11,48 ms. [Rohdaten](combat_performance_dense_trinity_after.json). Für dieses neue Szenario gibt es keine Vorhermessung.

Die Desktopwerte sind nicht auf das Handy übertragbar. Ob der gemeldete 7-FPS-Einbruch damit ausreichend behoben ist, braucht einen erneuten Test auf dem Gerät bei voller Auflösung.

## Prüfen und reproduzieren

Die erweiterten Kampf-Abfragetests vergleichen Kreis, Segment, nächste Ziele und Fallbacks mit vollständigen Referenzscans. Der neue Beutetest vergleicht 800 Drops über 100 Schritte mit der bisherigen Bewegung einschließlich Magnetwechsel, Teleports, Arena-Transformation, Sammelreihenfolge und Truhenbelohnung. Die bestehenden Post-wave-/Save-/Resume-Tests prüfen den kompletten Übergang zum Shop. Der Schattentest prüft Lebenszyklus und zusätzlich mit echtem Renderer Transform und Farbe; eine gerenderte Vorschau wurde visuell kontrolliert.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/dense_combat_cpu_probe.gd -- --label=local
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/combat_performance_probe.gd -- --label=local
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/combat_performance_probe.gd -- --sustained --trinity --label=trinity_local
```

Die Probes verwenden separate Spielstände. Die gerenderte Probe überschreibt ihren eigenen Teststand; die normalen gespeicherten Läufe bleiben erhalten. Keine Gegneranzahl, Angriffshäufigkeit, Schadenswerte, XP- oder Münzdrops werden durch die Optimierung reduziert.
