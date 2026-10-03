# Ruckler beim ersten Boss-Charge, 03.10.2026

Auf dem Handy (Chrome, Snapdragon 888) läuft der Kampf laut Spielerbeobachtung
mit 60 FPS; beim ersten Boss-Charge fällt die Bildrate kurz ab. Ob dies nur nach
dem Neuladen oder bei jedem Boss auftritt, ist noch nicht geklärt.

Ein konkreter zusätzlicher Aufwand liegt am Ende des ersten Charge: Der erste
Fächer erzeugt seine prozedurale Geschosstextur, der Imperator zusätzlich den
größeren Kugelkörper und Warnring. Spätere Angriffe verwenden den Texturcache.
Die eigentliche Charge-Aktivierung war in der lokalen Messung klein.

`BossProjectileWarmup` bereitet die drei gemeinsamen Boss-Texturen beim Start vor
und rendert sie zusammen mit Polygon-, Linien-, Kreis- und Bogen-Zeichenpfaden
einmal in einem isolierten 8 × 8-Viewport. Dieser Viewport nimmt keine Eingaben
an, gehört nicht zur Spielwelt und entfernt sich nach zwei Frames, auch wenn das
Spiel im Menü pausiert ist. Die Texturen verbleiben im gemeinsamen Cache.

## Lokale Messung

Godot 4.7.2, Windows, RTX 4070, Compatibility/OpenGL. Gemessen wurde die CPU-Zeit
des direkten Methodenaufrufs für den Charge-Abschluss, einschließlich
Geschosserzeugung. `--cold` leert dafür den Texturcache vor jedem Bosstyp.
Der nächste Aufruf desselben Musters verwendet den Cache.

| Erster Charge-Abschluss | Leerer Texturcache | Beim Start vorbereitet |
| --- | ---: | ---: |
| Graf | 0,605 ms | 0,094 ms |
| Prinz | 0,720 ms | 0,135 ms |
| König | 0,696 ms | 0,089 ms |
| Imperator | 8,151 ms | 0,054 ms |

Die Aktivierung des Charge lag bei etwa 0,05–0,06 ms. Diese kleinen isolierten
Desktop-Messungen sind **keine Handy-FPS-Messung** und kein Nachweis, dass alle
Ursachen des gemeldeten Rucklers verschwunden sind. Insbesondere Browser-,
Treiber-, Audio- und Shaderkosten auf dem Gerät bleiben separat zu prüfen.

## Wiederholen und Prüfung

```powershell
& Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/boss_first_charge_probe.gd
& Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/boss_first_charge_probe.gd -- --cold
```

Der Probe-Spielstand liegt in `.godot/`, die normalen Einstellungen werden nicht
gespeichert. Ohne `--headless` lässt sich die Vorbereitung mit echtem Rendering
prüfen; `--cold` simuliert nur einen leeren prozeduralen Texturcache.

Der neue Test `tests/boss_projectile_warmup.gd` prüft Cache-Wiederverwendung schon
beim ersten Fächer und der ersten Imperator-Kugel, Trefferradien, Schaden,
Geschosszahl, Geschwindigkeit, isolierten Viewport und Freigabe während Pause.
Zusätzlich werden die vorhandenen Boss-, Rendering-, Grafik-, Menü- und
Save/Resume-Tests ausgeführt.

Auf dem Handy nach dem Deployment die Seite neu laden und den ersten Charge
beobachten. Falls der Einbruch bleibt, ist der nächste wichtige Unterschied:
Beginn der Warnung, Start des Ansturms oder Geschossausstoß am Ende; anschließend
kann ein Vergleich mit stummgeschalteten SFX Audio als Ursache eingrenzen.
