# Schnellere Testausführung

`tools/run_tests.py` startet standardmäßig die 178 Kernprüfungen mit bis zu vier parallelen Prozessen. Spielfluss, Save/Resume und Migration, Schaden/Status, Waffen und Synergien, Belohnungen, Shop/Economy, Schwierigkeitsskalierung und bedienbare UI bleiben Bestandteil jedes normalen CI-Builds. Kurze Ausweichtests und die Verhaltens-/Speichertests aller Bosse bleiben ebenfalls enthalten. Der Simulationsschritt bleibt `--fixed-fps 60`.

## Auswahl nach Zweck

| Suite | Umfang | Einsatz |
| --- | --- | --- |
| `core` (Standard) | 178 Tests direkt unter `tests/` | Lokale Standardprüfung und Push-/PR-Builds |
| `extended` | 21 Tests unter `tests/extended/` | Gezielte Grafik-, Diagnose- oder umfangreiche Balanceprüfung |
| `all` | Beide Gruppen, 199 Tests | Release-Tags und manuell angeforderter vollständiger CI-Lauf |

Im GitHub-Workflow kann beim manuellen Start `test_suite: all` gewählt werden. Release-Tags verwenden immer `all`. Neue Tests direkt unter `tests/` sind automatisch Teil der Kernprüfung; Hilfsskripte unter `tests/support/` werden nie als eigene Tests gestartet. Filter gelten nur innerhalb der ausgewählten Suite. Eine leere Auswahl oder doppelte Testnamen über beide Gruppen hinweg sind Fehler.

Die zusätzlichen Prüfungen wurden nach ihrem tatsächlichen Inhalt ausgewählt:

- `emperor_final_routes`, `king_assault_routes`: vollständige Angriffsfolgen samt auslaufenden Geschossen, vier Schwierigkeitsgrade, vier Ecken und drei Bildschirmformate. Diese umfassende Suchmatrix bleibt für Bossänderungen erhalten; Warnzeiten, Zielverfolgung, kürzere Ausweichprüfungen, komplette Mechaniken und kompatibles Fortsetzen bleiben im Kern.
- `boss_pressure_probe`: identische Treffer-Schutzzeiten mit Messreserve, RNG-isolierte Mess-SFX und aktuelle Minion-/Aufgabenwarnungen.
- `debug_cheat_menu`, `test_arenas`, `combat_diagnostics`, `run_telemetry`: Entwicklerzugänge, Vergleichsarenen, Messberichte und Diagnoseinstrumentierung. Die Integritätsprüfungen für normale Spielstände sowie wirtschaftliche und kampfrelevante Telemetrie in den Gameplay-Tests bleiben im Kern.
- `prepared_combat_textures`, `prepared_projectile_atlas`, `enemy_sprite_atlas`, `item_icon_regions`, `stat_icons`, `attack_effects`: pixelgenaue Raster-/Atlasvergleiche, Rahmen und Quellbildzuschnitt. Nach Grafik- oder Bake-Änderungen gezielt ausführen.
- `count_rig`, `weapon_art_layers`, `denti_expressions`: detaillierte Animations-, Mesh- und Darstellungskontrollen. Angriffsgeometrie, Projektilausrichtung, Waffenverhalten und Spielerstatus bleiben im Kern.

Die Dateinamen allein waren kein Ausschlusskriterium: Beispielsweise prüft `atlas_item_batch` echte Item-Synergien und Fortsetzen; `arena_background` prüft Arena-Wände, Kamera und sichere Spawnpositionen. Auch `combat_performance` prüft echte Kollisions-/Zielabfragen und Lebenszyklen. Diese Tests bleiben regulär aktiv.

## Zusammengefasste und entfernte Einzelprüfungen

- `run_flow` ist in `post_wave_rewards` integriert: Phasenregeln und realer Belohnungsfluss teilen einen Prozess.
- Die Materialwiederverwendungs-/Besitzprüfungen aus `warning_antialias` sind in `warning_effects` integriert. Zwei starre Assertions auf alte Warnatlas-Zellmaße entfielen: Der aktuelle Warnrenderer verwendet analytische Geometrie; die feste alte Zellposition prüfte dessen Darstellung nicht.
- `ground_effects` ist in `extended/attack_effects` integriert: Boden- und Angriffsatlas werden zusammen geprüft.

Damit entfallen drei eigene Testprozesse. Die übrigen wichtigen Aussagen bleiben erhalten; die 15 Zusatzprüfungen sind ausdrücklich aufrufbar.

## Abschlussregression der Bossänderungen, 4. November 2026

Die vollständige Suite mit 198 Tests lief unter Windows/Godot 4.7.2 mit vier
Workern in 740,22 Sekunden. 195 Tests bestanden direkt, einschließlich der
vollständigen König-/Imperator-Routen. Drei Befunde wurden anschließend behoben:
Die Bossdruck-Prüfung verwendet die dokumentierten Folgefächer-Warnzeiten,
der Bot-Test erwartet den Bossabschluss statt des früheren Wellentimers, und
der neu gebaute Glyphenatlas enthält die fehlenden Markierungen für Karamellherz
und Reichsrichter. Der anschließende Lauf dieser drei Tests sowie
`weapon_evolutions` und `warning_effects` bestand mit **5/5 in 30,24 Sekunden**.
Damit sind alle 198 Tests einschließlich der korrigierten Nachläufe geprüft.
Zusätzlich bestanden **50/50 Python-Tests** für die Build- und Testwerkzeuge.

Die unveränderten Erstlauf- und Nachlaufberichte liegen unter
`.godot/test_runs/20261103-223342-6d32a0b5/results.json` und
`.godot/test_runs/20261104-060439-0ba8b13f/results.json`.

## Kernlauf vom 31. Oktober 2026

Am 31. Oktober 2026: **150/150 bestanden in 220,93 Sekunden**, Windows, Godot 4.7.2, vier parallele Prozesse. Zusätzlich bestanden alle zehn Runner-Tests und der zusammengefasste Boden-/Angriffsatlastest über den echten `extended`-Aufruf. Die lediglich verschobenen Tests behielten ihre Inhalte und UIDs; die umfangreichen Suchmatrizen wurden für die Umordnung nicht erneut ausgeführt.

Die [aktuelle Kernmessung](test_runtime_core.json) dient zugleich als Startreihenfolge für frische CI-Läufe: lange Kernprüfungen zuerst. Lokale Zeiten überschreiben diese Vorgabe, wenn vorhanden. Die Laufzeit misst den Godot-Testschritt; Import, Exporte und Deployment kommen im CI hinzu. Der aufgezeichnete Lauf entstand vor Verwendung dieser neuen Sortiervorgabe; eine zusätzliche Beschleunigung durch die Reihenfolge ist darin nicht gemessen.

## Historischer Vergleich der parallelen Ausführung

Am 4. Oktober 2026, Godot 4.7.2, headless, dieselbe Windows-Arbeitsstation und dieselben 84 Tests mit den aktuellen Waffen-/Nassdaten:

| Lauf | Zeit | Ergebnis |
| --- | ---: | --- |
| Seriell, ein Prozess gleichzeitig | 324,72 s | 84/84 bestanden |
| Vier Prozesse gleichzeitig | 96,09 s | 84/84 bestanden |

Das entspricht etwa 70 % weniger Laufzeit beziehungsweise dem 3,38-fachen Durchsatz. [Serielle Messung](test_runtime_serial.json), [parallele Messung](test_runtime_parallel.json). Einzelne Tests können parallel länger brauchen, weil sie sich CPU und I/O teilen; entscheidend ist die Laufzeit der gesamten Suite. CI-Laufzeiten hängen zusätzlich von Runner, Containerstart und Asset-Import ab.

Der vorherige GitHub-Lauf [1d6fc9c](https://github.com/othaldo/denti/actions/runs/37213104733) brauchte allein für seine damals 82 Tests 232 Sekunden. Diese CI-Zeit ist kein direkter Vergleich mit der lokalen Windows-Messung.

Die echten JSON-/Scene-Save/Resume-Fälle in `upgrade_resume` und die mehrstufigen Reward-/Resume-Batches in `queued_level_rarity` bleiben vollständig in der Kernprüfung.

## Isolation und Diagnose

Jeder Test erhält ein frisches, eigenes Godot-Benutzerdatenverzeichnis unter `.godot/test_runs/<Lauf>/userdata/<Test>/`. Der Runner setzt dafür nur die Umgebung des Kindprozesses: `APPDATA` auf Windows, `XDG_DATA_HOME` auf Linux. Godot verwendet auf Windows [APPDATA als Datenpfad](https://github.com/godotengine/godot/blob/ed1daf0bf/platform/windows/os_windows.cpp); unter Linux gilt der [XDG-Datenpfad](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html). Die Elternumgebung und die normalen Spielstände/Einstellungen werden nicht verändert. Der Runner unterstützt Windows und Linux.

Assets müssen zuvor einmal importiert sein. Nach dem Verschieben von Testdateien einmal neu importieren. Während der Tests wird kein Editor-Import gestartet; alle Prozesse lesen denselben Import-Cache. Jeder Test behält eine eigene SceneTree-/Autoload-Instanz und einen festen Simulationsschritt.

Nicht-null Exit-Code, `SCRIPT ERROR:`, Engine-`ERROR:` auch bei Exit-Code null, Leak-Warnungen und ein Timeout von lokal standardmäßig 180 Sekunden (CI: 300 Sekunden) lassen den Testlauf fehlschlagen. Normale Warnungen, etwa bekannte Atlas-Rundungshinweise, bleiben sichtbar und werden nicht pauschal als Fehler gewertet. Beim Timeout wird der gestartete Prozess einschließlich seiner Kinder beendet. Die anderen Tests liefern weiterhin ihre Ergebnisse. Zehn Python-Tests prüfen Parallel-Isolation, Exit-/Skript-/Engine-Fehler, Leak-Warnungen, Prozess-Timeouts, Filter sowie vollständige Suite-Auswahl, Unterverzeichnispfade und Berichte ohne versehentlich leere Auswahl.

Pro Test bleiben Ausgabe- und Engine-Logs erhalten. `.godot/test_results.json` enthält den letzten Lauf einschließlich Einzelzeiten; jeder Lauf erhält zusätzlich seine eigene `results.json`. Die zehn langsamsten Tests erscheinen im Terminal und in der GitHub-Jobzusammenfassung. CI lädt Logs und Zeiten auch bei einem fehlgeschlagenen Test als `godot-test-results` hoch (sieben Tage Aufbewahrung). Die längsten Tests werden zuerst gestartet: frische CI-Jobs verwenden die eingecheckte Zeitmessung, lokale Läufe bevorzugen ihre letzten Einzelzeiten. Dadurch warten am Ende weniger Prozesse ungenutzt auf einen langen Test.

## Gemeinsamer Testabschluss

`tests/support/test_runtime.gd` stellt `finish(exit_code)` und `new_stats()` bereit. Die Unterstützung liegt außerhalb des vom Runner entdeckten Musters `tests/*.gd`. `finish()` stoppt Audio, gibt losgelöste Test-Stats und Szenen frei und lässt die aufgeschobene Bereinigung und den Audiomixer abschließen. Das ist bei `--fixed-fps 60` nötig, weil Simulationsframes wesentlich schneller als die reale Audioverarbeitung laufen können. Tests verwenden auch bei Fehlern diesen Abschluss. Der Waffen-DPS-Benchmark nutzt denselben Ablauf, weil ein Verhaltenstest darauf aufbaut.

Szenen können während eines Resume-Tests weiterhin bewusst ersetzt werden. Der letzte noch aktive Szenenbaum wird vom gemeinsamen Abschluss bereinigt. Isolierte Regeltests wie `run_storage` und `catalogs` benötigen keine Spielszene. Die bisherigen Kampf-, Layout- und JSON-Roundtrip-Prüfungen bleiben erhalten.

Pull Requests gegen `main` durchlaufen Tests und Web-Export. Pushes auf `main` veröffentlichen `/dev/`; erfolgreiche Builds auf `feat`, `feat/...` und `feat-...` erhalten über den separaten Vorschau-Workflow auf `main` einen Branch-Testbuild. Beide Workflows lassen sich auch manuell starten; die Schreibrechte für Pages liegen in den Deployment-Jobs.

## Befehle

Der zusätzliche Test `prepared_combat_textures` vergleicht den eingecheckten Atlas mit den
neu berechneten Motiven. Bei CPU-skalierten, gemalten Projektilen sind einzelne
Rundungsabweichungen zwischen Windows und Linux zulässig: höchstens 1/255 je
Kanal und höchstens 0,5 % der Kanäle. Bildgröße und Pixelformat bleiben exakt;
Loot- und prozedurale Texturen werden weiterhin bytegenau verglichen. Eigene
Negativfälle prüfen, dass größere und flächige Abweichungen abgelehnt werden.
Bei Fehlern protokolliert der Test die Zahl abweichender Kanäle und den maximalen
Kanalfehler, damit eine veraltete Grafik nicht als Rundungsfehler durchgeht.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --jobs 1
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter 'weapon_*'
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --suite extended --filter '*routes'
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --suite all --timeout 300
python -m unittest discover -s tools/tests -v
```

Unter Linux entsprechend `python3` und `--godot godot`. Python 3.10+ genügt; keine zusätzlichen Python-Pakete. `--filter` ist wiederholbar. Gefilterte lokale Läufe ersetzen nicht die Kernprüfung im CI. Bei Boss-, Grafik- oder Diagnoseänderungen die passenden zusätzlichen Tests ausführen; für die komplette Regression `--suite all --timeout 300` verwenden.
