# Wiederverwendbare Spielerprojektile

Spielerwaffen verwenden einen gemeinsamen `PlayerProjectilePool` unter dem bisherigen Szenenpfad `Projectiles`. Vorher erzeugte jede Salve neue Geschoss- und Sprite-Nodes und löschte sie nach Flug, Rückkehr oder Explosion. Jetzt werden die vollständigen Nodes wiederverwendet; die bereits vorhandenen gemeinsamen Texturen bleiben erhalten.

## Vorbereitung und Lebensdauer

Nach einer Änderung der Ausrüstung werden 24 Geschosse je ausgerüsteter Projektil-Resource und Waffenstufe vorbereitet. Das schließt Käufe, Fusionen, Evolutionen, F4-Änderungen und das Wiederherstellen der Ausrüstung ein. Unterschiedliche Resources und Stufen teilen keine Reserve, auch wenn ihre IDs gleich sind. Damit bleiben Form, Farbe und stufenabhängige Größe der vorbereiteten Sprites passend.

Die Reserve liegt außerhalb des Szenenbaums. Nur aktive Geschosse zeichnen, erhalten Physikcallbacks oder gehen in den Run-Snapshot ein. Abgelaufene Schüsse, Rückkehr zu Denti, Ende einer Explosion und Wellenende geben Geschosse zurück. Jeder neue Abschuss setzt Trefferlisten, Flugstrecke, Crit, Item-Effekte, Rückflug, Orbit und Impact vollständig zurück; ein Redraw entfernt alte Explosionszeichnungen. Rückflugschaden, Durchschlag, Halo-Orbit und Splash verwenden die bisherigen Kampfabläufe.

Reserven verkaufter oder fusionierter Ausrüstung werden beim nächsten Ausrüstungswechsel freigegeben. Bereits fliegende Schüsse beenden ihren Flug normal. Insgesamt bleiben höchstens 512 inaktive Geschosse erhalten. Mehr gleichzeitig fliegende Geschosse sind weiterhin erlaubt: Eine erschöpfte Reserve erzeugt zusätzliche Geschosse, überzählige Rückgaben werden freigegeben. Das Löschen der Arena gibt sowohl aktive als auch inaktive Nodes frei.

Headless-Ausführungen überspringen die automatische Vorbereitungsreserve, damit gewöhnliche Tests keine unbenutzten Sprites erzeugen. Auch dort laufen echte Abschüsse und Save/Resume durch denselben Pool. Der Pooltest bereitet Reserven ausdrücklich vor; ein zusätzlicher nativer Test deckt die automatische Vorbereitung bei echter Waffenfusion ab.

## Messungen

`tools/benchmark_player_projectiles.gd` vergleicht neun Tier-IV-Dreifaltigkeitsgeschosse pro Salve, je 1000 Salven und drei abwechselnde Vergleichspaare nach einem Aufwärmpaar. Referenz: Szeneninstanziierung, Abschuss und synchrones Freigeben; Pool: Erwerb, Abschuss und Rückgabe derselben Nodes. Der alte Spielbetrieb löschte verzögert per `queue_free`; dieser isolierte Test erfasst stattdessen die gesamte Node-Freigabe unmittelbar. Flug, Treffer, GPU-Arbeit und Echtzeit-FPS werden dabei nicht gemessen.

| Durchlauf | Instanziierung/Freigabe je Salve | Pool je Salve |
| --- | ---: | ---: |
| 1 | 0,319 ms | 0,146 ms |
| 2 | 0,318 ms | 0,146 ms |
| 3 | 0,320 ms | 0,152 ms |

Auf diesem Desktop benötigt der isolierte Lebenszyklus damit ungefähr 54 % weniger Zeit. Während des Pool-Benchmarks entstehen nach der Vorbereitung keine weiteren Geschoss-Nodes.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_player_projectiles.gd --log-file .godot/benchmark_player_projectiles.log
```

Die native volle Arena (RTX 4070, VSync aus, feste Simulation 1/60 s, 300 Aufwärmframes und 1800 Messframes) zeigt ohne Profiler praktisch unveränderte FPS: etwa 309,5 vor und nach der Änderung. Ein kurzer instrumentierter Vergleich lag bei 284,1 vorher und 292,1 danach; Waffenzeit bei 0,084 gegenüber 0,069 ms. Gegner-/Geschoss-/Beutezahlen und Texturspeicher blieben gleich. Daraus folgt kein verlässlicher Android-FPS-Gewinn oder Beleg für weniger lange Frames. Der Pool zielt auf wiederholte Node-Allokation und Abschussspitzen; die verbleibende Treffer-, Render- und Simulationsarbeit wird dadurch nicht beseitigt.

## Regressionen

`tests/player_projectile_pool.gd` prüft Reserve ohne Callbacks/Save-Einträge, idempotente Rückgabe, unveränderte Sprite-Identität, vollständigen Zustandsreset gegenüber einem frischen Geschoss, wiederholte Salven ohne neue Allokationen, Resource-/Stufentrennung und Raketenexplosionen. Echte Gegner prüfen Durchschlag und Trefferreihenfolge sowie erneute Treffer nach Wiederverwendung. Volles Save/Resume prüft Halo-Orbit, Rückflug und Treffer-IDs. Außerdem werden Wellenende, Freigabe alter Ausrüstung, aktive Schüsse beim Stufenwechsel, die Speichergrenze und Salven über dieser Grenze geprüft. Die native Ausführung prüft zusätzlich die Vorbereitung durch den echten Loadout-Fusionspfad.
