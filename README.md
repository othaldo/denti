# Denti: Divine Dentistry

Ein kleines Godot-4-Projekt über einen göttlichen Zahn im Kampf gegen Plaque.

## Starten

Projekt in Godot 4 öffnen und **F5** drücken. Alternativ im Projektordner:

```bash
godot --path .
```

Im Hauptmenü ein neues Spiel beginnen oder einen gespeicherten Lauf fortsetzen. Mit **WASD** oder den Pfeiltasten bewegen. Die Zahnbürste schießt automatisch auf den nächsten Gegner. XP und Münzen durch Berühren einsammeln. Bei einem Levelaufstieg einen von drei Boni wählen. **Escape** öffnet im Kampf ein Pausenmenü mit Stats, Optionen und Rückkehr zum Hauptmenü.

## Stand

Der Prototyp enthält zehn 45-Sekunden-Wellen mit steigender Schwierigkeit, vier normale Gegnertypen und den Karies-König in Welle 10. Denti hat drei automatische Waffen, zehn Shop-Items und sieben Stats. Beute, Levelaufstiege, Shop, Sieg, Niederlage und Neustart sind spielbar. Das kompakte HUD zeigt Leben, XP und Münzen links oben sowie Welle und Countdown mittig. Der Countdown pausiert im Shop. Vor jeder neuen Welle werden übrige Gegner und Geschosse entfernt; liegengebliebene Beute wird am Wellenende gutgeschrieben.

Die Arena nutzt einen generierten, ruhigen Fliesenboden mit Zahnornamenten am Rand. Bei anderen Fensterformaten wird das Bild proportional zugeschnitten; die spielbare Fläche, Gegner-Spawns und Dentis Bewegungsgrenze passen sich an das sichtbare Format an.

Die Gegnertypen werden schrittweise eingeführt: Plaque ab Welle 1, Bakterien ab Welle 2, Zuckerstücke ab Welle 3 und Säurespucker ab Welle 4. In zwei zufällig bestimmten späteren Wellen erscheint jeweils eine Horde nur eines Gegnertyps. Der Shop kündigt neue Gegnertypen, Horden und den Boss der nächsten Welle an. Der Säurespucker hält Abstand, markiert seine Schussrichtung und feuert ein ausweichbares Säureprojektil.

Die Staffelung orientiert sich an den in der Community dokumentierten Brotato-Mechaniken für [Wellen](https://brotato.wiki.spellsandguns.com/Waves), [Gegnereinführungen](https://brotato.wiki.spellsandguns.com/Enemies) und [Horden](https://brotato.wiki.spellsandguns.com/Horde_Wave). Die konkreten Zahlen sind für Dentis zehn Wellen gewählt.

Ein Lauf wird nach dem Start, beim Wellenwechsel, bei Entscheidungen und während eines laufenden Kampfes regelmäßig unter Godots `user://run_save.json` gespeichert. **Fortsetzen** lädt den aktuellen Lauf auch nach einem Neustart der Anwendung. Nach Sieg oder Niederlage wird der Spielstand entfernt. Unter **Optionen** lassen sich Vollbild und Lautstärke einstellen.

Im Shop gibt es drei zufällige Angebote. Items verändern Denti-Stats, Zahnseide ergänzt einen Flächenangriff und der Bohrer trifft einen nahen Gegner hart. Angebote lassen sich mit Münzen neu würfeln. Normale Gegner lassen immer XP und gelegentlich Münzen fallen. In Welle 10 erscheint der Boss; läuft der Timer vorher ab, endet die Welle erst mit seinem Sieg.

Plaque, Bakterium, Zuckerstück, Säurespucker und Karies-König haben transparente Sprites unter `assets/enemies/`. Das Bakterium kündigt einen Sprint an; das Zuckerstück markiert vor einem Flächenangriff den gefährlichen Bereich. Denti wippt im Leerlauf, neigt sich beim Laufen und reagiert sichtbar beim Angriff. Zahnpasta-Projektile pulsieren im Flug, ziehen eine Spur und platzen beim Treffer auf.

Ein kurzer Integrationstest läuft nach dem ersten Import des Projekts mit:

```bash
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --script res://tests/enemy_behaviors.gd
godot --headless --path . --script res://tests/progression_menu.gd
godot --headless --path . --script res://tests/arena_background.gd
godot --headless --path . --script res://tests/options_menu.gd
```

Die ursprünglichen Referenzbilder liegen unverändert unter `assets/denti/reference/`. `assets/denti/denti_gameplay.png` ist ein daraus abgeleiteter transparenter Spielsprite.

HUD, Levelaufstieg und Shop verwenden eine gemeinsame Creme-, Gold- und Mint-Palette mit Denti-Porträts. Die Schrift Fredoka und ihre Lizenz stehen in [CREDITS.md](CREDITS.md). Die Credits sind auch nach einem Spielende im Menü erreichbar.
