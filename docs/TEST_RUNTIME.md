# Schnellere Testausführung

`tools/run_tests.py` startet die vorhandenen Godot-Tests mit bis zu vier parallelen Prozessen. Es werden weiterhin alle Tests ausgeführt. Der Simulationsschritt bleibt `--fixed-fps 60`; weder Zeitbeschleunigung noch weniger Testfälle sind nötig.

## Gemessener Vergleich

Am 4. Oktober 2026, Godot 4.7.2, headless, dieselbe Windows-Arbeitsstation und dieselben 84 Tests mit den aktuellen Waffen-/Nassdaten:

| Lauf | Zeit | Ergebnis |
| --- | ---: | --- |
| Seriell, ein Prozess gleichzeitig | 324,72 s | 84/84 bestanden |
| Vier Prozesse gleichzeitig | 96,09 s | 84/84 bestanden |

Das entspricht etwa 70 % weniger Laufzeit beziehungsweise dem 3,38-fachen Durchsatz. [Serielle Messung](test_runtime_serial.json), [parallele Messung](test_runtime_parallel.json). Einzelne Tests können parallel länger brauchen, weil sie sich CPU und I/O teilen; entscheidend ist die Laufzeit der gesamten Suite. CI-Laufzeiten hängen zusätzlich von Runner, Containerstart und Asset-Import ab.

Der vorherige GitHub-Lauf [1d6fc9c](https://github.com/othaldo/denti/actions/runs/37213104733) brauchte allein für seine damals 82 Tests 232 Sekunden. Diese CI-Zeit ist kein direkter Vergleich mit der lokalen Windows-Messung.

Die größten lokalen Einzeltests sind die 52 echten JSON-/Scene-Save/Resume-Fälle in `upgrade_resume` und die mehrstufigen Reward-/Resume-Batches in `queued_level_rarity`. Ihr Umfang bleibt erhalten. Neue Tests wachsen damit zunächst in die parallele Ausführung hinein, statt die Wartezeit sofort um ihre gesamte Laufzeit zu verlängern.

## Isolation und Diagnose

Jeder Test erhält ein frisches, eigenes Godot-Benutzerdatenverzeichnis unter `.godot/test_runs/<Lauf>/userdata/<Test>/`. Der Runner setzt dafür nur die Umgebung des Kindprozesses: `APPDATA` auf Windows, `XDG_DATA_HOME` auf Linux. Godot verwendet auf Windows [APPDATA als Datenpfad](https://github.com/godotengine/godot/blob/ed1daf0bf/platform/windows/os_windows.cpp); unter Linux gilt der [XDG-Datenpfad](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html). Die Elternumgebung und die normalen Spielstände/Einstellungen werden nicht verändert. Der Runner unterstützt Windows und Linux.

Assets müssen zuvor einmal importiert sein. Während der Tests wird kein Editor-Import gestartet; alle Prozesse lesen denselben Import-Cache. Jeder Test behält eine eigene SceneTree-/Autoload-Instanz und einen festen Simulationsschritt.

Nicht-null Exit-Code, `SCRIPT ERROR:` auch bei Exit-Code null und ein Timeout von standardmäßig 180 Sekunden lassen den Testlauf fehlschlagen. Beim Timeout wird der gestartete Prozess einschließlich seiner Kinder beendet. Die anderen Tests liefern weiterhin ihre Ergebnisse. Vier Python-Integrationstests prüfen Parallel-Isolation, beide Fehlerwege, Prozess-Timeouts und Filter einschließlich einer versehentlich leeren Auswahl.

Pro Test bleiben Ausgabe- und Engine-Logs erhalten. `.godot/test_results.json` enthält den letzten Lauf einschließlich Einzelzeiten; jeder Lauf erhält zusätzlich seine eigene `results.json`. Die zehn langsamsten Tests erscheinen im Terminal und in der GitHub-Jobzusammenfassung. CI lädt Logs und Zeiten auch bei einem fehlgeschlagenen Test als `godot-test-results` hoch (sieben Tage Aufbewahrung). Die längsten Tests werden zuerst gestartet: frische CI-Jobs verwenden die eingecheckte Zeitmessung, lokale Läufe bevorzugen ihre letzten Einzelzeiten. Dadurch warten am Ende weniger Prozesse ungenutzt auf einen langen Test.

## Befehle

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --jobs 1
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter 'weapon_*'
python -m unittest discover -s tools/tests -v
```

Unter Linux entsprechend `python3` und `--godot godot`. Python 3.10+ genügt; keine zusätzlichen Python-Pakete. `--filter` ist wiederholbar. Gefilterte lokale Läufe ersetzen nicht die vollständige CI-Suite.
