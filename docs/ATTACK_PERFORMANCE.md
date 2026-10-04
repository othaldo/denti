# Angriffe vorbereiten und bündeln · 4. Oktober 2026

Handy-Rückmeldung nach dem Geschossatlas: 30–60 FPS auch in `debug enemies`; „Sparsam“ ändert wenig. Das spricht für weitere CPU-/Zeichenkosten. Durchgehend 60 FPS benötigen unter etwa 16,7 ms pro Frame auf dem Gerät. Desktopmessungen sind keine Handygarantie. Die Auflösungsautomatik wurde nicht geändert.

## Angriffspfade geprüft

| Pfad | Vorbereitung / laufende Arbeit |
| --- | --- |
| Bakterien, Beißer, Zucker-/Elite-Ansturm | Linien und Endmarkierungen teilen einen vorbereiteten Atlas. Vier übliche Warnringe sind mit unveränderten Radien/Strichbreiten in 65 Zuständen vorbereitet. Warnungen/Spuren werden gemeinsam unter den Gegnersprites ausgegeben. |
| Puls / Flächenangriff | Vorbereitete Kreisfüllung und wiederverwendete Ringgeometrie; Schaden und Reichweite bleiben erhalten. |
| Fächer / Radial | Warnrichtungen werden bei Änderung von Richtung, Muster oder Anzahl berechnet. Die bisher fehlende orange Radialgeschossfarbe ist ergänzt: jetzt 30 vorbereitete Gegnergeschossvarianten. |
| Lane / Raumorb | Gemeinsame Warnlinien/-markierungen; andere/große Ringe verwenden vorbereitete Einheitsgeometrie. Salvenparameter bleiben erhalten. |
| Boss-Charge / Signaturen / Phasen | Gleiche gemeinsame Ausgabe für Charge, Fan, rückwärtigen Fan, Lane und Orb. Gesundheits-/Schutzanzeigen bleiben erhalten. |
| Spielerprojektile / Raketen / Explosionen | 29 vorbereitete Atlasregionen aus den aktuellen Waffen/Stufen und Evolutionen, einschließlich Beute/Schatten. Keine Bilderzeugung beim ersten Standardabschuss. Explosionsringe verwenden wiederkehrende Geometrie. |
| Status / Items / Relikte / Evolutionen | Wiederverwendete Kreisgeometrie; Position, Farbe und Größe bleiben dynamisch. |
| Art / Schrift / Schatten | Isoliertes 8×8-Warmup verwendet Gegner-, Waffen-, Denti- und Aura-Bilder, Schadensziffern mit Outline, additive Aura und instanzierte Schatten einmal vor dem Kampf. Keine abgespielten Angriffe oder Sounds. |

Unveränderliche Bilder/Geometrie lassen sich vorbereiten. GPU-Zeichenpfade müssen einmal auf dem jeweiligen Gerät verwendet werden; fertige PNGs allein verhindern nicht jede erste Shader-/Upload-Spitze. Positionen, Schaden und echte Trefferprüfungen bleiben dynamisch. Es werden keine kompletten Kampfanimationen oder alle Positionen in Bilder gerastert.

`CombatDrawCache` bereitet acht Punktzahlen und 65 Fortschrittszustände vor. Nur die visuelle Ringöffnung wird auf 1/64 des Vollkreises gerundet; Angriffstimer und Schadensfenster bleiben exakt. Ganze Kreise behalten ihre Punktzahl. Andere Radien/Varianten haben weiterhin einen Geometrie-/Bild-Fallback.

Neue Atlanten: `combat_glyphs.png` 2048×1992 (15,6 MiB RGBA), `combat_textures.png` 1024×560 (2,2 MiB RGBA). Das ist vorbereiteter Texturspeicher zugunsten weniger laufender Zeichenarbeit. Beide Generatoren liegen unter `tools/`; neue Standarddaten erfordern Regeneration und Import.

## Allokationen und Prüfungen

- Gegnersalven verwenden 384 vor dem Kampf vorbereitete Geschosse samt Körper-/Halo-Sprites. Getroffene/abgelaufene Geschosse verlassen den Szenenbaum und werden wiederverwendet. Reserveobjekte haben keine Callbacks/Zeichnungen und werden nicht gespeichert. Halo, Animation, Laufzeit, Ziel, Farbe, Schaden und Statusdaten werden zurückgesetzt. Größerer Bedarf wächst ohne Geschosslimit; höchstens 768 ungenutzte Objekte bleiben als Reserve. Arena-Ausgang gibt die Reserve frei. Headless-Tests sparen die große Grafikreserve und prüfen denselben Pfad mit gezielt vorbereiteten Objekten.
- Kontakt-Cooldown überspringt Kontaktgeometrie. Eine Bounding-Box-Prüfung weist entfernte Segmente vor der exakten Prüfung ab. Schnelle Anstürme prüfen weiterhin die gesamte zurückgelegte Strecke.
- Gesperrte Warn-/Ansturmrichtungen werden nicht erneut auf Denti normalisiert; Reichweitenvergleiche verwenden quadrierte Distanzen. Der normale Angriff verursacht keine zusätzlichen eigenen Zeichenupdates neben der gemeinsamen Ausgabe.
- Volle unveränderte Elite-Schutzanzeigen werden nicht bei jedem Physics-Tick neu aufgebaut. Boss-Schutzmarkierungen aktualisieren sich beim Wechsel ihrer sichtbaren Schwelle.

## Messung und Prüfung

`tools/enemy_attack_performance_probe.gd`, natives Godot 4.7.2 Compatibility/OpenGL, RTX 4070, 1280×720, VSync aus. 110 Bakterien ohne Waffen, Beute oder Statusänderungen. Zustand mit Delta 0 stabil gehalten und vor jedem Renderframe aktualisiert: bewusst synchroner Zeichentest, keine normale Welle. Je 3,5 Sekunden Laufzeit, erste 0,5 Sekunden ausgeschlossen.

| Szene | Mittel vorher → nachher | P95 vorher → nachher | Zeichenaufrufe vorher → nachher |
| --- | ---: | ---: | ---: |
| 110 gleichzeitige Warnungen | 4,83 → 1,59 ms | 5,40 → 1,92 ms | 474 → 36 |
| 110 Ansturmspuren | 1,97 → 1,48 ms | 2,62 → 1,77 ms | 254 → 36 |

Der Warntest spart rund 67 % mittlere Framezeit und 92 % Zeichenaufrufe. Die reine Geometrie-Zwischenspeicherung half viel weniger als gemeinsame Texturen und Ausgabe. [Vorher](enemy_attack_before.json), [nachher](enemy_attack_after.json).

Innerhalb der Nachherfassung: je 250 Neun-Geschoss-Salven einschließlich Ablauf/Freigabe und einem Renderframe pro Salve, 320 ms mit Neuerzeugung gegenüber 303 ms mit Wiederverwendung. Das sind Durchlaufzeiten, keine isolierten CPU-Callbacks.

89 Spieltests bestanden. Neue Prüfungen vergleichen alle 29 Spieler-/Beutebilder bytegenau gegen das bisherige Raster, Ringradien, 50 Salven ohne neue Objekte, Status-/Schadensübertragung, Rückgabe, Bereinigung und Pool-Save/Resume. 120 Kontaktbewegungen werden gegen die vorherige Segmentberechnung geprüft, einschließlich schneller Kreuzung, Tangente und Stillstand. Weitere Prüfungen zählen Zeichenupdates und vergleichen Warnrichtungen. Die bestehenden Angriff-/Boss-/Waffen-/Effekt-/Save-Tests bleiben grün. Das erweiterte Warmup wurde zusätzlich gezielt geprüft.

Ansturm, Einschlag, Giftfächer, Lane, Radial, Orb, Boss-Charge und Puls wurden gerendert mit der bisherigen Ausgabe verglichen; Radien und Endpunkte bleiben erhalten. Die gemeinsame Ebene liegt unter den Gegnersprites und behält Transformation, Trefferfarbe und Transparenz.

## Handyvergleich

Seite neu laden, dann `debug enemies` und `bacteria charge` testen. Der neue Code enthält 60 Bakterien ohne Waffen, Items oder Beute. Testarenen zeigen jetzt auch längste einzelne Framezeit und Anzahl der Frames über 25 ms. Pause/Fokuswechsel setzen die Messung zurück. [Testcodes](TEST_ARENAS.md).

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_combat_textures.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/bake_combat_glyphs.gd
Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/enemy_attack_performance_probe.gd -- --label=local
```

Die Warnsymbole brauchen beim Backen einen echten Renderer. Die Probe verwendet einen eigenen Spielstand unter `.godot/` und schreibt ihren Bericht unter `docs/`; normale Spielstände bleiben erhalten.
