# Karies-Imperator: das Kronengericht

Stand: 21.10.2026. Eigener Encounter im Welle-20-Profil, in Story und Endlos.
Der alte Charge-/Orb-/Phasenring-Ablauf wird ersetzt. Die vorhandenen HP,
Rüstung, Phasenschwellen, Adds und das übergreifende Schadensbudget bleiben.

[Native Vergleichsaufnahmen](concepts/emperor-court/fight.html) ·
[Generierte Assets und vollständiger Prompt](concepts/emperor-court-art.md).

## Repertoire

Der Imperator schwebt in einem schmalen violetten Mantel. Körper, Krone,
Zepterarm, Siegelhand, offener Kern und drei Kronenplatten werden an acht
Gelenken bewegt. Alle Teile behalten ihr Seitenverhältnis. Warnung, Pose,
Geschossgeburt und Treffer werden durch denselben Encounter-Timer gesteuert.

Die drei Abläufe **Hofurteil → Portalstich → Nerventakt** beginnen bereits in
der ersten Gesundheitsphase. Dazwischen liegt jeweils ein 1,8-s-Angriffsfenster,
Erholung, angekündigtes Drehen der Wache und eine kurze Neupositionierung.

| Mechanik | Umsetzung | Antwort |
| --- | --- | --- |
| Kronenwache | Drei sichtbare Platten schützen ±70°; Richtungswechsel um 90° über angekündigte 0,7 s | Seitlich/hinten angreifen, neue Ausrichtung beobachten |
| Hofurteil | Zwei gegenüberliegende Sektoren, je ±30° und 390 px; 1,05 s Warnung, 0,22 s Trefferphase; nächste Winkel mit neuer Warnung | Den wechselnden freien Boden lesen; ein Seitenschritt beantwortet nicht die ganze Folge |
| Portalstich | Zwei gemalte Portale; feste Bahn durch die bei Warnbeginn erfasste Spielerposition; 1 s Warnung, dann echte Wurzellanze | Quer zur festgelegten Bahn ausweichen; weitere Stiche bekommen eigene Warnungen |
| Blanker Nerv | Brust offen, vollständige gleichmäßig verteilte Geschossringe mit versetzten Winkeln; jede Salve 1,05 s angekündigt, 0,22 s Freigabe | Reguläre Geschossabstände und Takt nutzen; nicht beliebig kreisen |

Die Kronenwache multipliziert Schaden von vorn mit **0,55**, Seite/Rücken mit
**1,0**, der offene Kern aus allen Richtungen mit **1,2**. Wache ist keine
Immunität. Normale Waffentreffer übergeben ihre tatsächliche Bewegungs-/
Trefferrichtung durch `WeaponAttackShapes`; ohne Richtung dient Dentis Standort
als Ursprung. Bestehende DoT-/Sondereffekt-Procs umgehen die Richtungsprüfung,
profitieren aber ebenfalls vom offenen Kern. Debug-Profiling reicht die
zusätzliche Richtung unverändert weiter.

Hofurteile richten sich nach Zyklus und Schritt aus, **nicht nach Dentis
Position**. Es wird kein passender freier Sektor für den Spieler ausgewählt.
Urteilfächer bleiben innerhalb der angekündigten Winkel. Nervensalven sind
vollständig, ohne ausgelassene Schüsse in Richtung Denti. Ihre Entstehung
hängt nur von der Uhr ab; schnelleres Treffen erzeugt keine zusätzlichen Salven.

Die zweite Gesundheitsphase verkettet Hofurteil und Portalfolge vor der
Kernöffnung und ergänzt eine Nervensalve. In der letzten Phase kommen ein
Urteil, ein Portalstich und vier Strahlen je Nervensalve dazu. Die erste
Nervensalve wird dann gemeinsam mit einem Hofurteil angekündigt und ausgelöst.
Es werden höchstens zwei Hauptmechaniken gleichzeitig kombiniert.

## Alle vier Schwierigkeiten

Warn-, Wachen-Dreh- und Kernöffnungszeiten bleiben gleich. Ressourcen werden
pro Encounter kopiert, einschließlich beider externen Projektilprofile.

| Wert | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Urteile / Portalstiche, erste und zweite Phase | 1 | 2 | 3 | 4 |
| Urteile / Portalstiche, letzte Phase | 2 | 3 | 4 | 5 |
| Nervensalven, erste / spätere Phasen | 1 / 2 | 2 / 3 | 3 / 4 | 4 / 5 |
| Strahlen je Nervensalve, erste und zweite / letzte Phase | 10 / 14 | 12 / 16 | 14 / 18 | 16 / 20 |
| Geschosse je Urteilsektor | 3 | 5 | 7 | 9 |
| Geschossgeschwindigkeit, px/s | 202,5 | 225 | 252 | 288 |
| Portalgeschwindigkeit, px/s | 684 | 760 | 851,2 | 972,8 |
| Eigener Positionierungsfaktor vor gemeinsamem Schwierigkeitstempo | 0,825 | 1,1 | 1,375 | 1,65 |
| Bewegung während des Portalfluges, Anteil der Positionierung | 0,10 | 0,16 | 0,22 | 0,28 |
| Erholungs- und Positionierungszeit, Faktor | 1,20 | 1,00 | 0,80 | 0,55 |

Die gemeinsame Schwierigkeit beeinflusst zusätzlich das normale Boss-Bewegungstempo.
Bei der Positionierung wird ein Weg durch Denti vermieden. Während fest
angekündigter Hofurteile bleibt ihr Ursprung stehen. Die Portalbahnen behalten
ihre Weltkoordinaten auch beim anschließenden Schweben des Imperators.

## Darstellung, Grenzen und Fortsetzen

Urteilflächen verwenden die vorhandene weiche Charge-Textur, auf eine
zwischengespeicherte Sektorgeometrie gelegt. Eine ruhige Gesamtfläche zeigt
den Umfang, die stärkere Füllung wächst bis zur Freigabe. Keine rechteckigen
Umrisse, zusätzlichen Umrisskreise oder Laufzeit-Bilderzeugung. Die Siegel,
Portale und Lanzen stammen aus dem generierten Teileatlas.

Portalenden werden bei Warnbeginn in den sichtbaren, mit Abstand zu HUD und
Wänden begrenzten Arenabereich gesetzt. Erst dann sind Start, Ende und
Flugzeit fest. Eine Lanze verschwindet am Ausgangsportal; sie fliegt nicht
unsichtbar dahinter weiter. Bewegung und Projektilkollision verwenden die
vorhandenen Sweeps, damit ein Dash nicht durch eine aktive Gefahr tunnelt.

`CrownCourtData` und drei Encounter-Ressourcen halten die Werte.
`CrownCourtEncounter` koordiniert Ablauf/Bewegung, `CrownCourtVisuals` und
`EmperorCourtRig` zeichnen. Zwei Instanzen von `BossPaintedVolley` verwalten
kleine Geschosse und Portalspieße ohne Node pro Geschoss. Höchstens 160 normale
Geschosse und acht Portalspieße je Boss; im geprüften Hell-Ablauf maximal 59
kleine Geschosse gleichzeitig. Zwei Imperatoren desselben Spiels reservieren
ihre schweren Folgen, auch solange noch eigene Geschosse leben.

Snapshots bewahren Zustände, Restzeiten, Orientierung und Ziel der Wache,
Urteilwinkel, bereits verarbeitete Treffer, beide Portalenden sowie beide
Geschossbestände. Pause hält die Uhr an. Alte Saves ohne eigenes Profil
starten mit einer sicheren Vorbereitung. Phasenwechsel und Tod räumen eigene
Gefahren auf und verhindern die alten generischen Zusatzsalven. Warmup rendert
das Rig, den Kern, die Sektorform und die Grafiken vor dem ersten Kampf.

## Nachweise und offene Balance

**131/131 Tests bestanden**, vollständiger Logordner:
`.godot/test_runs/20261021-111226-c3a538c4`.

- `crown_court_encounter`: echte gerichtete Schadensunterschiede, feste
  Urteilwinkel, Fächer innerhalb der Warnung, Portalgeschosse erst nach Warnung,
  korrekte Geburtszeit in langen Frames, Dash-Kollision, vollständige Ringe,
  Trefferfrequenz unabhängig von Waffentreffern, alle Stufen, Kopierisolation,
  Pause, Snapshots, tatsächliches Laden einer Portalwarnung, zwei Imperatoren,
  alte/ungültige Saves sowie Phasen- und Todesbereinigung.
- `crown_court_routes`: alle vier Ecken und Schwierigkeiten, 72 % Grundtempo,
  tatsächliche erste Urteil-/Portal-/kombinierte Nervenfreigabe einschließlich
  ausgehender Geschosse, ohne durch den Bosskörper zu laufen. Das prüft
  einzelne erreichbare Wege, nicht jede komplette Folge mit normalen Gegnern.
- Bestehende Boss-Abschluss-/Relikt-/Shop-, Save-, Diagnose-, Waffen- und
  Schadensprüfungen bleiben grün. Der bestehende Extrem-DPS-Test besiegt den
  Imperator nach **46,9 s**, durchläuft beide Übergänge und eigene Portal-/
  Nervenangriffe. Er erzeugt keine alten generischen Phasensalven mehr.

[Isolierter Druckvergleich](emperor_court_pressure_measurements.json), je 60 s
in der letzten Gesundheitsphase, ohne Bossbeschuss oder Adds:

| Messwert | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Kleine Geschosse emittiert | 92 | 176 | 220 | 280 |
| Portalstiche | 11 | 12 | 16 | 19 |
| Warnungen einschließlich Wachendrehung | 28 | 32 | 35 | 38 |
| Tatsächlicher Bewegungsweg, px | 760,5 | 919,9 | 1.260,0 | 1.713,3 |
| Spitzenbestand kleiner Geschosse | 28 | 48 | 53 | 59 |

[Kampfzeit-/Schadensmessung](emperor_court_measurements.json): 350 roher DPS
nur innerhalb 180 px bzw. 600 px; drei einfache Bewegungsstrategien. Echte
Phasen und Richtungswache, keine Waffen, Items, Adds oder Dash. 10.000 Spieler-HP
dienen nur zur Schadenssummierung. 90-s-Abbruch; `defeated=false` ist keine
Killzeit. Die Warnungsreaktion berücksichtigt die Rolle: Nahkampf sucht nahe
sichere Urteilwinkel und nähert sich zwischen Gefahren wieder an; beim Nerventakt
werden reguläre Geschossabstände gelesen. Der Fernkampfbot gewinnt Easy/Normal
nach 74,2/77,92 s, der Nahkampfbot nach 81,68/87,13 s. Hard/Hell erreichen in
beiden Rollen den Abbruch. Diese einfachen Modellläufe belegen **keine
abgenommene Build-Balance**; insbesondere Kampfzeit und erreichbare Fenster
auf höheren Stufen müssen mit echten Waffen und Builds geprüft werden.

Als Nächstes müssen echte Welle-20-Builds im Nah- und Fernkampf, deren
Reichweiten sowie erreichbare Kernfenster verglichen werden. Vollständige
Folgen mit Adds und mobilen Web-/GPU-Messungen bleiben offen. Die nativen
Hochkantaufnahmen zeigen bei engem Bildausschnitt teilweise HUD-Überlagerung
der hohen Krone; das ist ebenfalls im Spieltest zu beurteilen.

Die Vorschau enthält je 36 s native Aufnahme mit drei neu gestarteten
12-s-Studien, zweiter Gesundheitsphase, 2.000 Spieler-HP und einfacher
Skriptsteuerung ohne Waffen/normale Gegner. Sie ist eine Darstellung der echten
Mechanik, kein menschlicher Überlebenstest.

```powershell
python tools/run_tests.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --filter crown_court* --timeout 90
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tools/measure_crown_court.gd
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --max-fps 0 --disable-vsync --script res://tools/preview_crown_court.gd -- --difficulty=hell
```
