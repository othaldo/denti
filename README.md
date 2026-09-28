# Denti: Divine Dentistry

Ein kleines Godot-4-Projekt über einen göttlichen Zahn im Kampf gegen Plaque.

## Starten

Projekt in Godot 4 öffnen und **F5** drücken. Alternativ im Projektordner:

```bash
godot --path .
```

Mit **WASD** oder den Pfeiltasten bewegen. Die Zahnbürste schießt automatisch auf den nächsten Gegner. XP und Münzen durch Berühren einsammeln. Bei einem Levelaufstieg einen von drei Boni wählen.

## Stand

Der Prototyp enthält zehn 45-Sekunden-Wellen mit steigender Schwierigkeit, drei normale Gegnertypen und den Karies-König in Welle 10. Denti hat drei automatische Waffen, zehn Shop-Items und sieben Stats. Beute, Levelaufstiege, Shop, Sieg, Niederlage und Neustart sind spielbar. Das kompakte HUD zeigt Leben, XP und Münzen links oben sowie Welle und Countdown mittig. Der Countdown pausiert im Shop. Vor jeder neuen Welle werden übrige Gegner und Geschosse entfernt; liegengebliebene Beute wird am Wellenende gutgeschrieben.

Im Shop gibt es drei zufällige Angebote. Items verändern Denti-Stats, Zahnseide ergänzt einen Flächenangriff und der Bohrer trifft einen nahen Gegner hart. Angebote lassen sich mit Münzen neu würfeln. In Welle 10 erscheint der Boss; läuft der Timer vorher ab, endet die Welle erst mit seinem Sieg.

Plaque, Bakterium, Zuckerstück und Karies-König haben transparente Sprites unter `assets/enemies/`. Denti wippt im Leerlauf, neigt sich beim Laufen und reagiert sichtbar beim Angriff. Zahnpasta-Projektile pulsieren im Flug, ziehen eine Spur und platzen beim Treffer auf.

Ein kurzer Integrationstest läuft nach dem ersten Import des Projekts mit:

```bash
godot --headless --path . --script res://tests/smoke.gd
```

Die ursprünglichen Referenzbilder liegen unverändert unter `assets/denti/reference/`. `assets/denti/denti_gameplay.png` ist ein daraus abgeleiteter transparenter Spielsprite.

HUD, Levelaufstieg und Shop verwenden eine gemeinsame Creme-, Gold- und Mint-Palette mit Denti-Porträts. Die Schrift Fredoka und ihre Lizenz stehen in [CREDITS.md](CREDITS.md). Die Credits sind auch nach einem Spielende im Menü erreichbar.
