# Zentrale Gegnerbewegung

Die Handyberichte zu `6694ce5` zeigen etwa 33,3 FPS beim Stehen und 32,1 FPS beim Bewegen. Die Beutezeit fällt beim Stehen auf 0,086 ms; Gegnerphysik liegt weiterhin bei ungefähr 8 ms pro dargestelltem Frame. Trefferzeiten sind inklusive, hängen von den Angriffen ab und dürfen nicht zusätzlich auf Waffen-/Geschosszeiten addiert werden.

## Umsetzung

`EnemySpatialIndex` besitzt jetzt einen festen Physikcallback für seine Gegner. `EnemyMotion` hält deren Positionen in einem `PackedVector2Array`, zusammen mit einer geordneten Referenzliste und Zellgrenzen. Normale Verfolgung ohne aktive Statuseffekte läuft direkt in diesem Besitzer. Bei Bewegung innerhalb einer Zelle entfallen Instance-ID- und Dictionary-Abfragen des Index; Knockback und externe Teleports synchronisieren den Positionsspeicher weiterhin sofort.

Der schnelle Pfad verwendet dieselben Formeln für Verfolgung, Abstandhalten und Seitwärtsbewegung der Schützen. Sobald ein Angriff auslösen kann, übernimmt die vorhandene Gegnerfunktion diesen gesamten Schritt einschließlich Timer und Telegraph. Warning/Charge, Bosse, Eliten, Auren, aktive Statuseffekte und transformierte Arenen verwenden ebenfalls den vollständigen bisherigen Ablauf. Keine Angriffs- oder Physikschritte werden gedrosselt. Die Reihenfolge bleibt die Entstehungsreihenfolge; freigewordene Einträge werden gelegentlich unter Beibehaltung dieser Reihenfolge verdichtet.

Gesundheit, Angriffstimer, Statuseffekte und Save-Daten bleiben in `Enemy` autoritativ. Der Positionsspeicher ist abgeleitet und wird nach dem Laden durch die normale Registrierung aufgebaut. Zum ausdrücklichen Einfrieren eines Gegners dient `set_simulation_enabled(false)`: verwaltete Gegner haben keinen eigenen Engine-Physikcallback mehr. Direkte Aufrufe von `Enemy._physics_process()` bleiben für Referenzsimulationen möglich; alleinstehende Gegner verwenden weiterhin diesen Callback.

In Diagnosearenen wird `enemy_physics` einmal für den gesamten Besitzerschritt gemessen. Die darin aufgerufenen komplexen Gegner werden nicht zusätzlich unter derselben Kategorie gezählt. Trefferzeit kann weiterhin darin enthalten sein. Normale Runs verwenden keine Zeittimer.

## Vergleich

Nativer Desktop mit RTX 4070, VSync deaktiviert, fester Simulationsschritt 1/60 s, identische volle Arena mit stehender Figur, 300 Frames zum Aufwärmen und 1800 gemessenen Frames:

| Variante | vorher | zentral |
| --- | ---: | ---: |
| `debug map` ohne Messskripte, FPS Ø | 297,64 | 309,55 |
| `debug map`, Minimum (1 s) | 290,32 | 300,95 |
| `debug profile`, FPS Ø | 262,30 | 288,92 |
| `debug profile`, geschätzte Gegnerphysik | 0,568 ms | 0,381 ms |

Der uninstrumentierte Gesamtgewinn beträgt in diesem kurzen Vergleich etwa 4 %. Der Diagnosevergleich enthält zusätzlich die Einsparung vieler einzelner Messcallbacks; er darf nicht als alleiniger Beleg für die normale Spielgeschwindigkeit dienen. Gegner-/Geschoss-/Beutezahlen waren identisch. Die maximale Framezeit ohne Messskripte verbesserte sich nicht (15,44 gegenüber 16,41 ms); Speicher- und Renderlast bleiben weitere Baustellen. Dies belegt weder die gleiche Verbesserung auf Android noch konstante 60 FPS.

Die anschließenden Handyberichte für Build `739cf8b` liegen stehend bei 37,3 FPS und bewegt bei 36,6 FPS, gegenüber 33,3 beziehungsweise 32,1 FPS für `6694ce5`. Die geschätzte Gegnerphysik sank in beiden Berichten auf etwa 3,2 ms pro dargestelltem Frame. Das schlechteste Einsekundenfenster lag bei ungefähr 26 FPS, P95 bei 45–47 ms und P99 bei 62–75 ms. Diese Messungen verwenden den Profiler mit geändertem Messaufwand, unterschiedliche Testdauer und unterschiedliche Angriffszustände; sie belegen einen Fortschritt der vollen Diagnosearena, isolieren aber nicht den alleinigen Nutzen der zentralen Bewegung. Auflösung und Gegnerzahl waren gleich.

`tools/benchmark_enemy_physics.gd` isoliert die normale Bewegung von 110 gemischten Gegnern bei einem festgelegten Spielerpfad. Je Pfad gibt es einen Aufwärmdurchlauf und danach drei abwechselnde Durchläufe mit 1800 Schritten. Die individuelle Referenzfunktion benötigt mit dem neuen Index etwa 0,55–0,56 ms pro Schritt, der zentrale Pfad etwa 0,25 ms. Der Index der Referenzfunktion synchronisiert dabei zusätzlich den neuen Positionsspeicher; vor der Änderung lag ein separater Referenzlauf bei etwa 0,48 ms. Das Werkzeug prüft alle Endpositionen auf exakte Gleichheit und misst keine Echtzeit-FPS:

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/benchmark_enemy_physics.gd --log-file .godot/benchmark_enemy_physics.log
```

## Regressionen

`tests/central_enemy_motion.gd` vergleicht die zentrale Verarbeitung über 300 Schritte mit der bisherigen individuellen Gegnerfunktion. In jedem Schritt müssen alle gespeicherten Gegnerzustände, erzeugten Geschosse, Beute, Angriffsmeldungen und der Kontaktschaden exakt übereinstimmen. Enthalten sind alle normalen Rollen, Eliten, ein Boss, Statuseffekte samt Ablauf, Knockback, Zellteleports, Geschwindigkeitsänderungen, fehlende Ziele, eine transformierte Arena, Einfrieren, Entfernung und neue Gegner. Weitere Prüfungen sichern Entstehungsreihenfolge, gültige Slots und vollständiges Aufräumen nach der Verdichtung. Die vorhandenen Kampftests verwenden für ihre eingefrorenen Testgegner das neue explizite Interface.
