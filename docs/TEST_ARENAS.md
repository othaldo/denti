# Testarenen im Web-Build

Die Testarenen sind Bestandteil des normalen Web-Releases. Im Hauptmenü **siebenmal Einstellungen öffnen und jeweils zurückgehen**. Danach erscheint **Code eingeben**. Der Eintrag bleibt nach dem Neuladen freigeschaltet. Ein Besuch einer anderen Hauptmenüseite unterbricht die noch nicht abgeschlossene Siebenerfolge; Besuche der Pause-Einstellungen zählen nicht.

| Code | Test |
| --- | --- |
| `debug map` | Volle Welle-17-Arena: 110 Gegner, anfangs 1200 XP-/Münzdrops, eine Dreifaltigkeitsbürste und zwei magische Zahnbürsten auf Tier IV, On-hit-Items |
| `debug enemies` | Gleiche 110 Gegnerarten und Welle 17, aber ohne eigene Waffen, Items oder Beute; Gegner bewegen sich und greifen weiterhin an |
| `bacteria charge` | 60 Bakterien in Welle 17 ohne eigene Waffen, Items oder Beute; isolierter Ansturmtest |
| `boss charge` | Ein Karieskönig in Welle 15 mit einer Tier-IV-Zahnbürste; zum Prüfen des ersten Charge und späterer Attacken |

Groß-/Kleinschreibung und zusätzliche Leerzeichen zwischen den Wörtern sind egal. Unbekannte Codes zeigen eine Meldung und starten keinen Run.

Der Web-Export aktiviert Godots [virtuelle Tastatur](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformweb.html#class-editorexportplatformweb-property-html-experimental-virtual-keyboard), damit das Codefeld auf Touch-Geräten die Bildschirmtastatur öffnen kann.

Die Gegner erhalten sehr viel Lebensenergie, damit die Arena für wiederholbare Performancevergleiche gefüllt bleibt. Denti erhält ebenfalls hohe Lebensenergie. Angriffe, Bewegung, Geschosse, Item-Procs und Markierungsdetonationen laufen über die normalen Spielsysteme. Der normale Wellen-Timer ist ausgesetzt: keine automatische Folgewelle, kein Shop und keine Level-up-Unterbrechung. Denti kann auch per Touch normal bewegt werden.

Die Testanzeige zeigt Gegner, Geschosse, Beute, durchschnittliche FPS und das niedrigste gemessene Einsekunden-FPS-Fenster. Zusätzlich zeigt sie die längste einzelne Framezeit und die Zahl der Frames über 25 ms. Die Messung verwendet echte verstrichene Zeit. Pause/Fokuswechsel setzen die Messung zurück. Die Build-ID steht daneben, damit Handy-Ergebnisse einem Deployment zugeordnet werden können. Die normale FPS-Anzeige ist während des Tests ebenfalls sichtbar; gespeicherte FPS- und Grafikoptionen werden dafür nicht geändert.

**Pause → Test neu starten** setzt die Arena auf das feste Preset zurück. **Pause → Hauptmenü** verlässt den Test. Die Testarenen speichern ausschließlich in `user://test_arena_run.json`; dieser temporäre Stand wird beim Verlassen entfernt. Der normale Run bleibt unverändert und kann danach mit **Fortsetzen** gespielt werden. Testläufe schreiben keine normalen Run-Berichte, schalten keine Schwierigkeit frei und entdecken keine normalen Fusionen.

Für einen Kaltstart-Test von `boss charge` zuerst die Seite neu laden. Ein Neustart der Testarena setzt den Boss zurück, behält aber bereits geladene GPU-Ressourcen.

Für den Performancevergleich auf dem Handy zunächst `debug map`, anschließend `debug enemies` jeweils mindestens 20 Sekunden spielen. Gleiche Grafikoption und ähnliche Position verwenden; FPS Ø/Minimum und Build-ID vergleichen. Der zweite Code isoliert Gegnerarbeit und gegnerische Geschosse, während der erste auch Waffen, Trefferprüfungen, Statuseffekte und Item-Procs enthält. Die Angriffstimer können sich unterscheiden. Die FPS der Testarenen mit dauerhaft 110 nahezu unsterblichen Gegnern sind keine Aussage über die durchschnittliche FPS eines normalen Runs.

## Weitere Presets

Die Presets liegen unter `data/test_arenas/`, als `TestArenaData`-Resources. Sie definieren Code, Welle, Gegner-/Beutezahl, Boss, Waffen, Tier und Items. Neue Resources in `TestArenaCatalog.ALL` eintragen; der zentrale Controller `scripts/systems/test_arena.gd` verwendet die bestehenden Kampfsysteme. Es gibt keine Eingabe beliebiger Befehle oder separaten Editor-Cheat-Menüs im Testlauf.

`tests/test_arenas.gd` deckt die Freischaltung über echte Menübuttons, Persistenz, unbekannte Codes, Desktop-/Handy-Layouts, alle Presets, Test-Neustart, Autosave-Isolation, Progressionsschutz und die Rückkehr zum ursprünglichen Run ab.
