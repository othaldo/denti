# Projektil-Performance, 30.09.2026

## Befund und Änderung

Gegnergeschosse zeichneten pro Physikschritt fünf Kreise neu; große Raumkugeln
zeichneten zusätzlich einen Ring. Schon 200 sichtbare Geschosse erzeugten zusammen
mit der restlichen Szene 1.032 Zeichenaufrufe. Bei hoher Last musste Godot mehrere
Physikschritte nachholen, wodurch die wiederholte Geometriearbeit weiter anstieg.

`EnemyProjectileVisuals` erzeugt jetzt einmal pro Farbe/Größe ein gemeinsames,
geglättetes Bild. `AcidProjectile` verwendet damit bündelbare Sprites und animiert
deren Skalierung. Der Warnring großer Kugeln bleibt fest. Der Treffertest vergleicht
quadrierte Abstände und spart die Quadratwurzel.

Schaden, Geschosszahl, Geschwindigkeit, Lebensdauer, Trefferflächen, sichere Lücken
und Bossmuster bleiben erhalten. Keine Geschosse werden für die Optimierung entfernt.

## Messung

Godot 4.7.2, Windows, RTX 4070, Compatibility-Renderer, 1280 × 720,
VSync/FPS-Limit aus, Physik weiterhin 60 Hz. Gleicher Zufalls-Seed und Szenenaufbau.
Jeweils 0,4 s Aufwärmen, danach 2,5 s Messung für die isolierten Geschosse und
4,5 s für den Boss. Gemessen wurden tatsächliche Abstände zwischen gerenderten
Bildern. P95 bedeutet, dass 95 % der Bilder höchstens diese Zeit benötigen.

| Szenario | Mittel vorher → nachher | P95 vorher → nachher |
| --- | ---: | ---: |
| Keine Gegnergeschosse | 0,58 → 0,58 ms | 0,74 → 0,72 ms |
| 200 sichtbare Geschosse | 10,96 → 0,64 ms | 15,47 → 0,84 ms |
| 600 Geschosse | 281,11 → 0,73 ms | 285,79 → 1,07 ms |
| 1.000 Geschosse | 466,68 → 0,83 ms | 467,29 → 1,29 ms |
| Kaiser, neun Salven, 200 Gegner, sechs Wasserstrahlen IV | 4,79 → 2,48 ms | 16,24 → 3,39 ms |

Im Boss-Test erreichten beide Versionen **211 gleichzeitig aktive Gegnergeschosse**.
Die langsamste gemessene Bildzeit sank von **36,22 auf 12,46 ms**. Bei 200 isolierten
Geschossen sank die Gesamtzahl der Zeichenaufrufe von **1.032 auf 33**.

Die extremen alten Werte bei 600/1.000 Geschossen zeigen den Einbruch unter
Überlast; dort entstanden nur neun bzw. sechs Messbilder. Diese kurzen Stresstests
sind keine Aussage über die typische FPS eines gesamten Runs. Die eigene
20-FPS-Situation und mobile/Web-Geräte sind damit noch nicht direkt nachgemessen.

Rohdaten: [vorher](projectile_performance_baseline.json),
[nachher](projectile_performance_optimized.json).
Die Baseline wurde mit der ursprünglichen Projektilzeichnung gemessen.

## Wiederholen

```powershell
& Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/projectile_performance_probe.gd -- --label=local
```

Das Werkzeug nutzt einen getrennten Testspielstand und schreibt
`docs/projectile_performance_local.json`. `--label` benennt lediglich die Ausgabedatei;
es schaltet keine ältere Implementierung ein. Für einen Vergleich beide Revisionen
mit demselben Werkzeug und denselben Einstellungen messen. Das sichtbare Rendering
ist erforderlich; `--headless` eignet sich hier nicht zur Performance-Messung.

## Prüfung und nächste Kandidaten

Alle **36 automatisierten Tests** bestehen. Der neue Projektil-Test prüft gemeinsame
Texturen, Bewegung, Ablauf, Trefferschaden, feste Orb-Warnringe und Save/Resume.
Der [Bildvergleich](screenshots/projectile_rendering_comparison.png) zeigt die
bisherige Zeichnung links und die gemeinsame Textur rechts, jeweils dreifach vergrößert.

Bei künftig schwereren Builds sind die pro Spielerprojektil wiederholten vollständigen
Gegnerabfragen und Sortierungen ein weiterer Kandidat. Sie wurden hier nicht separat
profiliert. Als nächstes lohnt eine längere Messung des tatsächlich langsamen Builds
im Web/Mobil-Export, einschließlich mehrerer Salven und automatischer Speicherungen.
