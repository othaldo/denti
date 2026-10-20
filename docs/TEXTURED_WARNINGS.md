# Gemeinsame animierte Bodenwarnungen

Umgesetzt am 20.10.2026: Charge-/Lane-Bahnen und die drei Graf-Flächen verwenden
jetzt denselben vorbereiteten Atlas wie Angriffseffekte und Warnringe.
Angriffstimer, Schaden und Kollision bleiben unverändert. Die Charge speichert
zusätzlich die beim Warnbeginn anvisierte Entfernung; ältere Saves bleiben gültig.

## Darstellung

Charges haben keine rechteckige Kontur mehr. Eine weich auslaufende korallrote
Lichtspur wächst vom Gegner bis zur beim Anvisieren festgelegten Position Dentis.
Eine goldene, gebogene Lichtfront markiert die Spitze. Ihre Position folgt dem
normalisierten Angriffstimer: Wenn sie das gespeicherte Ziel erreicht, wechselt
der bestehende Angriff in ACTIVE. Die Bahn zieht beim Ausweichen nicht nach.
Der darüber hinausgehende tatsächliche Ansturmweg bleibt schwach sichtbar.
Bei einem kürzeren, an der Arenagrenze endenden Angriff endet auch die Front dort.
Alte Saves ohne Zielentfernung verwenden die vollständige bereits angekündigte Bahn.

Die Explosionsstelle des Zuckerstücks hat ebenfalls keinen Kreisrand mehr:
eine weich auslaufende Glutfläche mit gebrochenen radialen Funken zeigt den
Einschlagbereich. Der kurze Aufpralleffekt verwendet dieselbe Textur statt
wieder einen Kreis zu zeichnen. Auch der Fortschrittsring am Charge-Ursprung
entfällt; die wandernde Spitze übernimmt die Zeitinformation.

Diese Charge-Texturen nutzen freie Zellen in der letzten Atlaszeile: weicher
Körper, auslaufender Anfang, gebogene Spitze, Einschlagglut und Funken. Es wird
keine weitere Textur geladen und der Atlas wird dafür nicht vergrößert.
Dichtewerte bleiben entlang der vollständigen Bahn verankert; der Aufbau der
Lichtspur verschiebt die Dämpfung nicht. Ihre Spitze bleibt stets lesbar.

Geschoss-Lanes und Orb-Bahnen behalten feste Endstücke und eine gekachelte Mitte.
15 vorbereitete StyleBoxTexture-Ressourcen decken deren vier Lichtphasen und
Konturschicht ab. Dort bleibt bei Dämpfung die vollständige Grenze sichtbar.

Die drei Graf-Flächen behalten ihre durchscheinende Füllung und schmale Kontur.
Fächer und Ring bekommen einen goldenen Lichtsaum, der innerhalb der bereits
markierten Fläche nach außen wandert. Die freie Ringmitte bleibt transparent.

Animation kommt aus dem vorhandenen Angriffstimer und vorbereiteten Texturen.
Pause und Fortsetzen frieren daher auch die Warnung ein. Es entstehen im Kampf
keine Bilder, Viewports, Shader-Materialien oder neuen StyleBox-Ressourcen.
Der Menü-Warmup zeichnet auch den neuen Charge- und Einschlagpfad.

## Erzeugung und Speicher

`tools/bake_warning_effects.gd` liest die drei `CloakStrikeData`-Ressourcen und
bereitet Formen, Lichtbänder und Bahnabschnitte offline in
`assets/vfx/warning_shapes.png` vor. Die Datei ist nur Baker-Eingabe, keine
zusätzliche zur Laufzeit geladene Textur. `prepared_warning_shapes.gd` hält die
dabei verwendeten Profilmaße fest; Tests erkennen veraltete Maße nach Tuning.

Anschließend packt `tools/bake_attack_effects.py` alles in den vorhandenen
`attack_effects.png`. Dieser wächst von 1024×1680 auf **2048×1792**: reine
RGBA-Pixel **14 MiB statt 6,56 MiB**, also +7,44 MiB. Die PNG-Datei liegt bei
etwa 596 KiB. Die Zahl der geladenen Atlas-Texturen steigt nicht. Waffenregionen
und bisherige Warnring-Zellen behalten ihre Position und ihren Inhalt.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_warning_effects.gd
python tools/bake_attack_effects.py
Godot_v4.7.2-stable_win64_console.exe --headless --editor --path . --import
```

Die vorbereiteten Sektoren sind die drei aktuellen Profilwinkel. Nach Änderungen
an deren Winkeln oder dem Verhältnis der Ringradien den Baker erneut ausführen.
Es gibt weiterhin separate mathematische Trefferprüfungen; die Textur bestimmt
keinen Schaden.

## Native Messungen der vorherigen Warnfassung

Die Charge-Lichtspur ersetzt inzwischen den rechteckigen Charge-Pfad. Die folgende
Bahn-Messung betrifft die weiter genutzten Geschoss-Lanes, nicht die neue Charge.

RTX 4070, Godot 4.7.2 Compatibility, VSync aus, isolierte Warnszenen. Messungen
abwechselnd zweimal pro Pfad. Es lief während der hier dokumentierten Messungen
kein zweites Aufnahme-/Benchmarkfenster.

| Aufbau | Vorher: Zeichenzeit / Frame / Drawcalls | Jetzt: Zeichenzeit / Frame / Drawcalls |
| --- | --- | --- |
| ein Graf-Ring | 0,315–0,323 ms / 0,937–0,971 ms / 73 | 0,004 ms / 0,292–0,313 ms / 1 |
| zwei Graf-Ringe | 0,634–0,636 ms / 1,652–1,669 ms / 146 | 0,005 ms / 0,289–0,311 ms / 1 |
| 60 bisherige Rissbahnen → 60 neue Bahnen | 0,370–0,376 ms / 0,662–0,671 ms / 1 | 0,589–0,616 ms / 0,895–0,939 ms / 2 |

Der Graf spart erheblich CPU-Zeichenarbeit. Die Bahn kostet gegenüber der alten
gestreckten Textur etwas mehr: Kachelung und feste Enden benötigen mehr Befehle,
Nine-Patch-Bahnen und rechteckige Fortschrittsringe bilden zwei Batches. Der
60er-Aufbau ist ein Stresstest; die Mehrkosten werden nicht als Verbesserung
ausgegeben. Im normalisierten Dichtetest mit 20 deckungsgleichen Warnungen
liegen aktuell 0,342–0,352 ms Zeichenzeit und 0,634–0,648 ms Framezeit bei zwei
Drawcalls an. Dieser Lauf umfasst auch die Dichteberechnung.

Das ist keine volle Kampfszene und keine Handy-FPS-Prognose. Transparente
Texturrechtecke verursachen weiterhin Pixelarbeit, auch in der transparenten
Ringmitte; der vollständige dichte Web-Aufbau muss auf dem Zieltelefon geprüft
werden. In realen Szenen können Figuren und Zeichenreihenfolgen Batches trennen.

Reproduktion:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_cloak_warnings.gd
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --painted
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --density
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/benchmark_warning_lanes.gd -- --verify-density
```

`benchmark_cloak_warnings.gd -- --stress` fügt optional 60 Ringe hinzu. Die
reguläre Probe verwendet einen und zwei. [Ring-Rohdaten](warning_ring_measurements.json).

## Prüfung und Vorschau

Acht relevante Tests bestanden in `.godot/test_runs/20261020-220942-19031f55`.
Nach der separaten Dichtekontur bestanden Warnatlas, Dichte, Warmup und gemeinsames
Gegnerzeichnen erneut mit 4/4 in `.godot/test_runs/20261020-221457-f27b295f`.

Die neuen Atlasprüfungen kontrollieren Profilmaße, Gefahrengrenzen, freie
Ringmitte, Bahn-Enden/Breite, Lichtphasen und wiederverwendete gekachelte Styles.
Der native Vergleich lokaler und gemeinsamer Ausgabe besteht für drei
Fortschrittsstände unter Rotation, Scherung und Spiegelung; maximale mittlere
Kanalabweichung im normierten Bild etwa 0,000077. Der Encounter-Test deckt
weiterhin Warnzeiten, Dash-Schaden, Schilde, Phasen, Tod und Fortsetzen ab.

[Charge-Vergleich](concepts/warning-effects/index.html) ·
[Graf im Kampf](concepts/count-bedbug/fight.html).

## Charge-Überarbeitung: Prüfung

Sechs relevante Tests bestanden in `.godot/test_runs/20261020-223243-799fba3d`:
`charge_warning`, `warning_effects`, `enemy_attack_batch`,
`warning_visual_density`, `boss_projectile_warmup`, `boss_overtime`.
Der Charge-Test prüft Zuckerstück und generische Boss-Charge, Zielbindung trotz
Spielerbewegung, Zeit bis ACTIVE, tatsächliche Bewegungsrichtung, Pause,
Snapshot-Roundtrip, Legacy-Fallback und Ablehnung ungültiger Zieldaten.

`tools/preview_charge_ribbon.gd` nimmt eine echte Zuckerstück-Charge mit
0,85 Sekunden Warnzeit auf; Denti weicht seitlich aus. Die Vorschau unter
`docs/concepts/warning-effects/` zeigt diese native Aufnahme statt der früheren
statischen Bahnvergleiche. Der Graf-Videoclip zeigt weiterhin seine drei Flächen.
