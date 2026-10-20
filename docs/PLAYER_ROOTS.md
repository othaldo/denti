# Wurzeln als Spielerparameter

`PlayerStats.root_capacity` bestimmt die verfügbaren Waffenplätze eines Spielers.
Der Standard liegt zentral in `PlayerStats.DEFAULT_ROOT_CAPACITY` bei **6**.
Der Wert ist am Stats-Knoten im Godot-Inspector einstellbar und wird als Teil
der Spielerwerte gespeichert. Er ist kein zusätzlicher Level-up-Stat.

Klassen oder Challenges können den Wert vor dem ersten Ausrüsten setzen:

```gdscript
var game := preload("res://scenes/game/game.tscn").instantiate()
game.get_node("Player/Stats").root_capacity = 4
add_child(game)
```

Am laufenden Spieler ist derselbe Wert über `player.stats.root_capacity`
erreichbar. `player.loadout.capacity` liest ihn direkt; es gibt keine zweite
Kapazitätskopie. Ohne gebundene Spielerwerte verwendet ein isoliertes Loadout
den Standardwert. Mindestwert ist **1**. Die Inspector-Spanne 1–64 ist nur eine
Eingabehilfe; größere Werte bleiben technisch zulässig. Ein eigener Klassen-
oder Challenge-Auswahlbildschirm gehört nicht zu dieser Änderung.

## Verhalten

- Jede Waffe verbraucht weiterhin ihre eigenen Wurzelkosten (`WeaponData.hands`).
- Startwaffen werden anhand des Spielers gefiltert. Ein ungültiger Startkauf
  startet keinen Lauf ohne Waffe.
- Shop-Käufe, automatische Kauf-Fusionen und Evolutionen prüfen denselben Wert.
- Shop, Pause-Stats, Debug-Anzeigen und Benchmark-Werkzeuge lesen den Spielerwert.
- Änderungen aktualisieren einen offenen Shop, die Pause-Stats und eine noch
  ausstehende Startauswahl unmittelbar.
- Das Ausrüstungsraster berechnet belegte und freie Zellen dynamisch. Ungerade
  Limits und breite Waffen erzeugen weder Überschneidungen noch Array-Zugriffe
  außerhalb des Rasters. Viele Wurzeln können im Shop gescrollt werden.
- Die Waffenreihe im Pausenmenü scrollt horizontal, statt die Stats über den
  Bildschirmrand zu schieben.
- Das Debug-Menü bietet „Wurzeln“ als Parameter zum Ausprobieren.
- Wird das Limit unter eine bereits vorhandene Ausrüstung gesenkt, werden
  gekaufte Waffen nicht automatisch gelöscht. Zusätzliche Waffen sind bis zum
  Freimachen ausreichender Wurzeln gesperrt. Verkauf und Fusion bleiben verfügbar.
  Der niedrigere Wert und die Ausrüstung bleiben auch beim Fortsetzen erhalten.

## Speichern und Prüfung

Neue Spielstände enthalten `player.stats.root_capacity`; der Wert wird vor der
Ausrüstung wiederhergestellt. Alte Spielstände ohne Feld erhalten **6**, auch
wenn im aktuell geladenen Objekt vorher ein anderer Wert eingestellt war.

`tests/root_capacity.gd` prüft 1, 2, 4, 5, 8 und 12 Wurzeln, gemischte Kosten,
Raster mit verschiedenen Spaltenzahlen, Kauf-Fusion, Evolution, Startauswahl,
Anzeigen und Shop-Grenzen auf vier Bildschirmformaten. Weitere Fälle prüfen
einen acht Wurzeln belegenden Run nach vollständigem Szenen-Neustart, ein
nachträglich abgesenktes Limit und kompatible alte Saves.

Prüfung am 20.10.2026: **119/119 Tests** im vollständigen Lauf bestanden
(`.godot/test_runs/20261020-110634-176ed042`, 106,51 s). Nach Ergänzung des
scrollbaren Pausen-Inventars und der unmittelbaren Aktualisierung offener
Ansichten bestanden die sechs gezielten Tests erneut
(`.godot/test_runs/20261020-111034-6872a6fc`). Native Aufnahmen mit 12 belegten
Wurzeln wurden bei 320×568 und 1280×720 geprüft; die temporären Prüfbilder
liegen ausschließlich unter `.godot/`.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter root_capacity --filter weapons --filter shop_grid_layout --filter build_overview --filter upgrade_resume
```
