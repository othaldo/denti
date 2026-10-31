# Warnanzeigen: glatte Konturen und Renderkosten

Aktuell (31.10.2026): Alle gegnerischen Bodenwarnungen wurden inzwischen auf den [einheitlichen analytischen Renderer](UNIFIED_TELEGRAPHS.md) umgestellt. Dort stehen die aktuelle Anbindung, Vorschau und Messung.

Die folgenden Abschnitte dokumentieren die vorherige Glättungsstufe und ihre Messung vom 30.10.2026.

Die bestehenden Warn-Timer verwendeten 80 × 80 Pixel große Atlas-Kacheln, die bei großen Radien sichtbar wellig bzw. pixelig wurden. Die Charge-Front nutzt 64 × 64 Pixel. Der neue gemeinsame Shader rekonstruiert genau diese Masken pro Ausgabepixel; Bildschirmableitungen berücksichtigen Vergrößerung, Verkleinerung und gedrehte Flächen. Der Atlas und seine Zeichnungsbefehle bleiben erhalten.

[Vergleich bei doppelter Ausgabeauflösung](screenshots/neon_charge/edges_2x.png) · [Überlagerung im Spielfeld](screenshots/neon_charge/ingame_density.png) · [Rohmessungen](warning_quality_measurements.json).

## Damals im Spiel aktiv

- Geglättete Timer-Ringe und Charge-Füllung/Ladefront in AttackEffects/WarningEffects.
- Ein gemeinsam genutztes ShaderMaterial, keine zusätzlichen Nodes, Texturen oder Bildpuffer pro Warnung.
- Andere Atlas-Bereiche und gewöhnliche Zeichnungsprimitive laufen unverändert durch. Bereits vorhandene oder geerbte Materialien der Aufrufer werden respektiert.
- Vorhandene Warnzeiten, Trefferflächen, Zielbindung, Dichteabschwächung und Speicherstände bleiben maßgeblich. Die Fortschrittsringe behalten ihre 64 Zeitstufen; diese Änderung glättet ihre räumlichen Konturen.
- Keine globale Auflösungssteigerung, kein Vollbild-Bloom, keine Bildschirmkopie und kein zusätzliches globales MSAA.

Shader-Grundlage: [Godot CanvasItem COLOR, UV und TEXTURE_PIXEL_SIZE](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html). Die Zellkoordinaten sind an den bestehenden Atlas gekoppelt und werden im Test gegen dessen Maße geprüft.

## Neue Charge-Inszenierung als Studie

Die separate Godot-Szene zeigt oben die vorherige Darstellung und unten die neue Sequenz bei identischer Kurve und Warnzeit: Körperspannung, Kontakt-Schatten, später Helligkeitsanstieg, kurzer Freigabeimpuls, gestreckte Pose, gerichtete Spur und Abfedern. Licht, Körper und Spur besitzen getrennte Kurven, aber dieselbe explizite Uhr. Fünf kurze Start-Striche sind normale Zeichenbefehle; es gibt keine Partikel-Nodes. Fertige Bodenspuren werden ausgeblendet und nicht weiter gezeichnet.

[Animation](screenshots/neon_charge/preview.gif) · [MP4](screenshots/neon_charge/preview.mp4) · [Bedienung](NEON_CHARGE_STUDY.md). Die vollständige Inszenierung ist noch keine Umstellung aller Gegneranimationen.

## Messung

NVIDIA GeForce RTX 4070, nativer Compatibility-Renderer, VSync aus. 80 Aufwärmframes, anschließend 200 gemessene Frames pro Fall. Atlas/Glättung jeweils in umgekehrter Reihenfolge wiederholt. Gleiche logische 1280 × 720 Fläche bei beiden Ausgabeauflösungen. Werte: mittlere Frame-Wandzeit, bei den beiden Bestandsvarianten über zwei Durchläufe gemittelt.

| Auflösung | Anzeigen | Atlas vorher | Geglättet | Neue Charge-Bahnen |
| --- | ---: | ---: | ---: | ---: |
| (1280, 720) | 20 | 0.428 ms | 0.417 ms | 0.420 ms |
| (1280, 720) | 60 | 0.523 ms | 0.534 ms | 0.610 ms |
| (2560, 1440) | 20 | 0.411 ms | 0.400 ms | 0.430 ms |
| (2560, 1440) | 60 | 0.549 ms | 0.567 ms | 0.647 ms |

Die Bestandsvarianten benötigen bei allen Mengen jeweils **7 Zeichenaufrufe für die gesamte isolierte Szene**, einschließlich Boden. Die neue Studie verwendet ein Material pro Bahn und liegt bei 26 bzw. 66 Aufrufen mit 20 bzw. 60 Bahnen. Sie ist ein eigener Belastungsfall mit ausschließlich Charge-Bahnen, kein inhaltsgleicher Ersatz für die gemischte Ring-/Charge-Szene. Sie enthält keine animierten Figuren.

Die Glättung zeigt auf diesem Rechner keinen deutlichen Kostensprung; kleine Unterschiede schwanken zwischen den Durchläufen. Diese Werte sind **keine vollständigen Spiel-FPS, keine isolierten GPU-Zeiten und kein Browser-/Mobilgeräte-Benchmark**. Vor einer flächendeckenden Einführung der aufwendigeren Inszenierung ist deren Budget auf den Zielgeräten zu prüfen.

## Geprüft

- Acht automatisierte Tests: warning_antialias, warning_effects, charge_warning, warning_visual_density, enemy_attack_batch, enemy_shadow_batch, enemy_render_updates, cloak_encounter.
- Native Ausgabe bei 1120 × 800 und 2240 × 1600; große und kleine Kreise sowie schräge Ladefronten visuell geprüft.
- Native Pixel-Gleichheit für unangetastete Atlas-Grafik und getönte Primitive vor/nach Materialwechsel.
- Native lokale/gemeinsame Darstellung mit Dichteabschwächung, Drehung, Spiegelung und nicht einheitlicher Skalierung: Vergleich bestanden.
- Echte Spielfeldszene mit 10/20 Warnungen, 40 Gegnergeschossen und 24 Spielerprojektilen; darunter kreuzende Bahnen und zwei Boss-Charges. Hier zählt der Screenshot die komplette Szene, nicht nur den isolierten Warnungsrenderer.
- Capture-Prüfungen der Studie: Pose friert bei Pause ein, Freigabe bleibt synchron, abgeschlossene Spur wird unsichtbar, Neustart setzt Pose und Effekt zurück.

## Reproduzieren

Mit getrenntem APPDATA unter .godot (wie in NEON_CHARGE_STUDY.md) aus dem Checkout:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_quality.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_quality.gd -- --capture
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --verify-density
```
