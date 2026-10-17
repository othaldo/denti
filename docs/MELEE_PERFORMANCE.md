# Nahkampf-Performance, 06.10.2026

## Ergebnis

Einzelziel-Nahkampf ist im untersuchten CPU-Aufbau mit dem optimierten Fernkampf
vergleichbar. Mehrziel-Nahkampf ist deutlich teurer: Zahnstocher-Speer,
Zahnseidenpeitsche und Interdentalbürste skalieren mit der lokalen Gegnerdichte.
Die bisherigen Optimierungen gelten also bereits für Nahkampf, beseitigen aber
nicht dessen zusätzliche Prüfung des bewegten Waffenpfads.

Diese Prüfung ergänzt ausschließlich ein Messwerkzeug und Berichte. Kampfcode,
Schaden, Trefferformen, Animationen und Save-Format wurden nicht geändert.

## CPU-Vergleich

Godot 4.7.2, Windows; manuelle Physikschritte von 1/60 Sekunde in einer pausierten
Szene. Jeweils sechs belegte Wurzeln, Waffen IV und 110 nahezu unsterbliche
Plaque-Gegner in einem dichten Ring mit Radien von 45 bis 129 Pixeln. Das ergibt
sechs Waffen bei Ein-Wurzel-Waffen und drei bei Zwei-Wurzel-Waffen.

| Ausrüstung | Waffen | CPU ms/Schritt, +80 % Tempo | CPU ms/Schritt, +300 % Tempo |
| --- | ---: | ---: | ---: |
| Turbo-Bohrer | 6 | 0,11 | 0,18 |
| Plaque-Schaber | 6 | 0,14 | 0,27 |
| Karies-Fräse | 3 | 0,15 | 0,19 |
| Prophylaxe-Polierer | 6 | 0,19 | 0,31 |
| Zahnstocher-Speer | 6 | 1,15 | 1,47 |
| Zahnseidenpeitsche | 6 | 1,63 | 2,27 |
| Interdentalbürste | 6 | 1,91 | 2,82 |
| Wasserflosser, einschließlich aktiver Geschosse | 6 | 0,16 | 0,27 |
| Magische Zahnbürste, einschließlich aktiver Geschosse | 3 | 0,09 | 0,15 |

Die Zahlen sind Mittelwerte aus drei Wiederholungen mit je 600 Messschritten.
Jeder neue Waffenaufbau läuft zuerst 120 Aufwärmschritte; zusätzlich wird ein
vollständiger erster Durchlauf verworfen. Fernkampf enthält sowohl Waffenarbeit
einschließlich Geschosserzeugung aus dem Pool als auch Flug-, Treffer- und
Rückgabearbeit. In keiner gemessenen Wiederholung werden neue Geschoss-Nodes
angelegt. Rückstoßpositionen werden außerhalb der Zeitmessung zurückgesetzt,
damit nachfolgende Wiederholungen dieselbe Gegnerdichte behalten.

Rendering, Gegnerbewegung, Beute, Trefferfeedback, Telemetrie, Statusanwendung
und Item-Procs sind ausgeschaltet. Der normale Schadenspfad mit leerem Inventar
und ein einfacher Trefferzähler bleiben aktiv. Es handelt sich um einen Vergleich
der tatsächlichen Waffenpfade, nicht um gleiche Trefferzahl oder gleichen DPS:
Die Peitsche trifft in den 600 Schritten beispielsweise 12.977-mal, der
Wasserflosser 277-mal. Ein Teil der Mehrkosten ist zusätzliche geleistete Arbeit.
Diese CPU-Zahlen sind keine FPS-Werte und keine Handyprognose.

Weitere Dichten bei +80 % Angriffstempo:

| Ausrüstung | 30 Gegner | 110 Gegner | 400 Gegner |
| --- | ---: | ---: | ---: |
| Turbo-Bohrer | 0,09 ms | 0,11 ms | 0,17 ms |
| Zahnstocher-Speer | 0,35 ms | 1,15 ms | 4,15 ms |
| Zahnseidenpeitsche | 0,53 ms | 1,63 ms | 5,58 ms |
| Interdentalbürste | 0,85 ms | 1,91 ms | 6,47 ms |
| Wasserflosser einschließlich Geschossen | 0,13 ms | 0,16 ms | 0,29 ms |

400 Gegner überschreiten das normale Limit von 110 und sind ausschließlich ein
Stresstest. Auch 110 dauerhaft im Nahbereich gehaltene Gegner sind dichter als
viele gewöhnliche Kampfsituationen. Langsame Skalierung des Einzelzielpfads
entsteht unter anderem durch die weiterhin nötige gemeinsame Zielsuche.

Rohdaten: [CPU-Vergleich](melee_performance_cpu.json).

## Vergleich mit Darstellung und Gegnerbewegung

Windows, RTX 4070, Compatibility-Renderer, 1280 × 720, volle Grafik,
VSync und FPS-Limit aus, gewöhnliche 60-Hz-Physik. 110 bewegte, nahezu
unsterbliche Plaque-Gegner in Welle 17, sechs belegte Wurzeln mit Waffen IV,
+80 % Angriffstempo, keine gekauften Items oder Beute. Trefferfeedback,
Waffenstatus, Telemetrie und Gegnerbewegung laufen normal. Autosaves sind
ausgenommen. Zwei frische Szenen je Ausrüstung, jeweils zwei Sekunden Aufwärmen
und vier Sekunden Messung; Diagnoseinstrumentierung misst jeden zehnten Frame.

| Ausrüstung | Mittlere Bildzeit, Mittel beider Läufe | P95, beide Läufe | Zeichenaufrufe, Mittel |
| --- | ---: | ---: | ---: |
| 6 Turbo-Bohrer | 1,31 ms | 1,69–2,30 ms | 91 |
| 6 Zahnstocher-Speere | 1,69 ms | 2,83–2,98 ms | 84 |
| 6 Zahnseidenpeitschen | 2,35 ms | 3,95–3,98 ms | 289 |
| 6 Wasserflosser | 1,49 ms | 2,20–2,23 ms | 141 |
| 3 magische Zahnbürsten | 1,34 ms | 1,84–1,97 ms | 88 |

Alle Szenen behalten 110 Gegner und führen während der Messung 240–241
Physikschritte aus. Die Peitsche benötigt in diesem Aufbau etwa 58 % mehr
mittlere Bildzeit als der Wasserflosser. Auf dieser Desktop-GPU bleiben alle
Szenen schnell. Die zusätzliche Flächen-Trefferarbeit wirkt sich auch mit
Rendering aus; die reine CPU-Messung darf jedoch nicht direkt auf Gesamt-FPS
übertragen werden.

Die Szenen spielen keinen identischen Kampf ab: Rückstoß, Status und Angriffsform
verändern die Gegnerpositionen und Trefferhäufigkeiten je Waffe. Bei der Peitsche
kommen unter anderem mehr sichtbare Blutungsanzeigen und Trefferfolgen hinzu.
Die höheren Zeichenaufrufe belegen deshalb keinen isolierten Fehler im
Waffenrenderer. Item-Synergien, bewegtes Denti und ein echter Web-/Handy-Build
wurden hier nicht gemessen.

Rohdaten: [native Messungen](melee_performance_rendered.json).

## Wo die Nahkampfzeit entsteht

Ein separater Durchlauf misst `WeaponStrike.tick()` inklusive der darin
ausgelösten direkten Treffer. Bei 110 Gegnern und +80 % Tempo entfallen beim
Speer etwa 91 %, bei der Peitsche etwa 94 % und bei der Interdentalbürste etwa
92 % der gemessenen Waffenzeit auf diesen Pfad. Diese Zeiten überlappen die
gesamte Waffenzeit; sie dürfen nicht dazuaddiert werden. Die zusätzlichen Timer
verändern den Messaufwand, weshalb die Haupttabelle aus dem Lauf ohne diese
Timer stammt.

Der Codebefund erklärt die Skalierung:

- Einzelzielwaffen (`melee`) verwenden die bereits bekannte Zielinstanz. Es gibt
  keinen vollständigen Gegner-Scan pro Trefferprüfung und keine eigene
  Godot-Kollisionsfläche pro Waffe.
- Speer, Peitsche und Bürste fragen während der aktiven Bewegung wiederholt den
  Gegnerkreis ab. Der Index erstellt und sortiert das Ergebnis in Spawnreihenfolge,
  bevor `WeaponStrike` bereits getroffene Gegner entfernt und die Angriffsform
  prüft. Zwei temporäre Listen entstehen zusätzlich pro aktivem Prüfschritt.
- Danach wird der animierte Waffenpfad in Schritten von höchstens 0,025
  Animationsfortschritt abgetastet. Jeder Abschnitt berechnet Pose und Segment
  erneut und prüft die verbliebenen Gegner gegen das Segment. Bei hohem Tempo
  sind mehr Samples in einem Physikschritt nötig; das bewahrt korrekte Treffer
  auch über übersprungene Animationsabschnitte hinweg.
- Spielerprojektile fragen dagegen räumlich den kurzen Flugabschnitt ab und
  schließen bereits getroffene IDs vor der Ergebnisliste aus. Sie sortieren nur
  tatsächliche Mehrfachkollisionen entlang der Flugrichtung. Ihr Pool vermeidet
  neue Nodes und Sprites; Nahkampf hat von vornherein keine pro Schlag neu
  erzeugten Angriffs-Nodes, die man entsprechend poolen müsste.

Rohdaten: [inklusive Strike-Messung](melee_performance_profile.json).

Alle Benchmark-Läufe enden mit Exitcode 0 und ohne Laufzeit-Skriptfehler. Der
zusätzlich instrumentierte Strike-Lauf meldet beim Beenden zwei verbliebene
ObjectDB-Instanzen und eine noch referenzierte Resource. CPU- und native
Hauptmessungen melden diese Cleanup-Warnung nicht; der Profilbericht wird
vollständig geschrieben.

## Sinnvolle nächste Optimierung

1. Bereits getroffene Gegner bei der räumlichen Abfrage ausschließen, bevor
   Listenaufbau und Sortierung stattfinden. Spawnreihenfolge und Proc-Reihenfolge
   müssen erhalten bleiben.
2. Besonders beim Speer die Kandidatensuche auf seine schmale Angriffsform
   begrenzen. Die heutige nachfolgende Trefferprüfung samt Gegnerkreisradius
   bleibt maßgeblich; bewegte Ziele dürfen nicht durch einen über den gesamten
   Schlag eingefrorenen Kandidatencache verloren gehen.
3. Feste Waffengeometrie vorbereiten und temporäre Pose-/Segmentdaten reduzieren.
   Derselbe bewegte Pfad muss für Grafik und Treffer gelten.

Die Sampling-Dichte oder Trefferzahl einfach zu reduzieren würde Gameplay
verändern. Für eine Umsetzung sollten die vorhandenen Tests zu Windup,
Ausweichen während des Schlags, schnellen Angriffen, Mehrfachtreffern und
Save/Resume erhalten und um einen Referenzvergleich erweitert werden.

## Wiederholen

```powershell
$env:APPDATA = 'D:\Projekte\denti\.godot\melee_benchmark_userdata'
Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file D:/Projekte/denti/.godot/melee_cpu.log --script res://tools/benchmark_melee_performance.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --log-file D:/Projekte/denti/.godot/melee_profile.log --script res://tools/benchmark_melee_performance.gd -- --profile
Godot_v4.7.2-stable_win64_console.exe --path . --log-file D:/Projekte/denti/.godot/melee_rendered.log --script res://tools/benchmark_melee_performance.gd -- --rendered
```

Die Umgebungsvariable gilt für die aktuelle Shell. Sie isoliert die Godot-
Benutzerdaten; die Run-Dateien liegen zusätzlich unter `.godot/`. Das Werkzeug
schreibt seine Messberichte nach `docs/`, setzt Optionen nur im Testprozess
und verändert den normalen Run nicht.
