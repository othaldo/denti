# Karies-Imperator: das Kronengericht

Aktueller Ausbau: [Imperator als Finalboss](EMPEROR_FINALE.md), mit schnellen Urteilsfächern, neu gezieltem Portalanschluss, wechselndem Nerventakt und vier Hell-Wiederholungen. Die folgenden Details dokumentieren den vorherigen Stand; insbesondere die gleichzeitige Urteil-/Portal-Kombination und die zusätzliche Nerven-AoE bleiben nur für alte laufende Spielstände erhalten.

Aktuelle Prüfung vom 31.10.: [Vergleich aller vier Bosse und Imperator-Befund](BOSS_AUDIT.md). Zielerfassung und Annähern funktionieren; insbesondere Flucht und der ähnliche Hard-/Hell-Takt bleiben Ansatzpunkte für den nächsten Ausbau.

Stand: 31.10.2026. Eigener Encounter im Welle-20-Profil, in Story und Endlos.
Der alte Charge-/Orb-/Phasenring-Ablauf wird ersetzt. Der aktuelle Stand reduziert
das Basisleben auf 2.000 und verkürzt Schutzzeitraum, Gesundheitspausen und
Erholung. Bewegung, alle vier Schwierigkeiten und neue Vergleichsmessungen stehen
in [BOSS_AGGRESSION.md](BOSS_AGGRESSION.md). Rüstung, Phasenschwellen und Adds
behalten ihre Regeln.

Neu sind häufigere Neupositionierung und ein gemeinsam angekündigtes Urteil mit
Portalstich. [Vorher-/Nachher-Messung und Grenzen](ROYAL_PRESSURE_BALANCE.md).

[Native Vergleichsaufnahmen](concepts/emperor-court/fight.html) ·
[Generierte Assets und vollständiger Prompt](concepts/emperor-court-art.md).

## Repertoire

Der Imperator schwebt in einem schmalen violetten Mantel. Körper, Krone,
Zepterarm, Siegelhand, offener Kern und drei Kronenplatten werden an acht
Gelenken bewegt. Alle Teile behalten ihr Seitenverhältnis. Warnung, Pose,
Geschossgeburt und Treffer werden durch denselben Encounter-Timer gesteuert.

Die drei Abläufe **Hofurteil → Portalstich → Nerventakt** beginnen bereits in
der ersten Gesundheitsphase. Dazwischen liegt jeweils ein 1,25-s-Angriffsfenster,
Erholung, angekündigtes Drehen der Wache und eine kurze Neupositionierung.

| Mechanik | Umsetzung | Antwort |
| --- | --- | --- |
| Kronenwache | Drei sichtbare Platten schützen ±70°; Richtungswechsel um 90° über angekündigte 0,7 s | Seitlich/hinten angreifen, neue Ausrichtung beobachten |
| Hofurteil | Zwei gegenüberliegende Sektoren, je ±30° und 390 px; ein Sektor zielt bei Warnbeginn mittig auf Denti; 1,05 s Warnung, 0,22 s Trefferphase | Aus der festgelegten Fläche ausweichen; jedes Folgeurteil erfasst Dentis neue Position |
| Portalstich | Zwei gemalte Portale; feste Bahn durch die bei Warnbeginn erfasste Spielerposition; 1 s Warnung, dann echte Wurzellanze | Quer zur festgelegten Bahn ausweichen; weitere Stiche bekommen eigene Warnungen |
| Urteil + Portalstich | Letztes Urteil einer kurzen Folge mit gleichzeitig festgelegter Portalbahn, gemeinsam 1,4 s angekündigt | Freien Sektor und feste Portalbahn zusammen berücksichtigen |
| Blanker Nerv | Brust offen, vollständige gleichmäßig verteilte Geschossringe mit versetzten Winkeln; jede Salve 1,05 s angekündigt, 0,22 s Freigabe | Reguläre Geschossabstände und Takt nutzen; nicht beliebig kreisen |

Die Kronenwache multipliziert Schaden von vorn mit **0,55**, Seite/Rücken mit
**1,0**, der offene Kern aus allen Richtungen mit **1,2**. Wache ist keine
Immunität. Normale Waffentreffer übergeben ihre tatsächliche Bewegungs-/
Trefferrichtung durch `WeaponAttackShapes`; ohne Richtung dient Dentis Standort
als Ursprung. Bestehende DoT-/Sondereffekt-Procs umgehen die Richtungsprüfung,
profitieren aber ebenfalls vom offenen Kern. Debug-Profiling reicht die
zusätzliche Richtung unverändert weiter.

Hofurteile richten den gefährlichen Sektor bei jedem Warnbeginn **auf Dentis
aktuelle Position**. Auch das mit dem Nerventakt kombinierte Urteil verwendet
diese Zielerfassung. Ursprung und Winkel bleiben danach während Warnung und
Trefferphase fest. Folgeurteile erfassen das Ziel erst nach der Neupositionierung
erneut. Beginnt eine Warnung während eines Dash-Frames, zählt Dentis Position
zum tatsächlichen Warnbeginn. Fortsetzen übernimmt den bereits angekündigten
Winkel, statt neu zu zielen. Diese Regel gilt auf allen vier Schwierigkeiten.
Urteilfächer bleiben innerhalb der angekündigten Winkel. Nervensalven sind
vollständig, ohne ausgelassene Schüsse in Richtung Denti. Ihre Entstehung
hängt nur von der Uhr ab; schnelleres Treffen erzeugt keine zusätzlichen Salven.

Die neue Kombination beginnt auf Easy in der dritten Gesundheitsphase, auf
Normal in der zweiten und auf Hard/Hell bereits in der ersten. Nach dem
kombinierten Urteil setzt der Imperator neu an und wechselt zum Nerventakt.
Außerhalb dieser Kombination bleiben selbstständige Portalfolgen verfügbar.
Alle drei Folgen sind auf höchstens drei Wiederholungen begrenzt. In der letzten
Phase kommen vier Strahlen je Nervensalve dazu. Die erste
Nervensalve wird dann gemeinsam mit einem Hofurteil angekündigt und ausgelöst.
Es werden höchstens zwei Hauptmechaniken gleichzeitig kombiniert.

## Alle vier Schwierigkeiten

Einzelne Warnungen, Wachen-Dreh- und Kernöffnungszeiten bleiben gleich; die neue
Urteil-/Portal-Kombination warnt auf allen Stufen volle 1,4 s. Ressourcen werden
pro Encounter kopiert, einschließlich beider externen Projektilprofile.

| Wert | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Urteile / Portalstiche, erste und zweite Phase | 1 | 2 | 3 | 3 |
| Urteile / Portalstiche, letzte Phase | 2 | 3 | 3 | 3 |
| Nervensalven, erste / spätere Phasen | 1 / 2 | 2 / 3 | 3 / 3 | 3 / 3 |
| Strahlen je Nervensalve, erste und zweite / letzte Phase | 10 / 14 | 12 / 16 | 14 / 18 | 16 / 20 |
| Geschosse je Urteilsektor | 3 | 5 | 7 | 9 |
| Geschossgeschwindigkeit, px/s | 202,5 | 225 | 252 | 288 |
| Portalgeschwindigkeit, px/s | 684 | 760 | 851,2 | 972,8 |
| Eigener Positionierungsfaktor vor gemeinsamem Schwierigkeitstempo | 1,125 | 1,5 | 1,875 | 2,25 |
| Bewegung während des Portalfluges, Anteil der Positionierung | 0,10 | 0,16 | 0,22 | 0,28 |
| Erholungs- und Positionierungszeit, Faktor | 1,20 | 1,00 | 0,80 | 0,55 |
| Neue Position zwischen zwei Salven suchen, mindestens | 0,32 s | 0,32 s | 0,32 s | 0,32 s |

Vor einem Hofurteil oder der ersten Urteil-/Nervenkombination nähert sich der
Imperator gezielt auf 280 px an. Die Warnung beginnt erst bei höchstens 300 px
Abstand; die Grenze wird zusätzlich auf die tatsächliche AoE-Reichweite begrenzt.
Die vorbereitende Bewegung ist daher bei großer Entfernung länger als die
bisherige feste Positionierungszeit. Auch zwischen Folgeurteilen setzt er
nötigenfalls länger als 0,32 s nach. Er verbraucht dabei keine Angriffe und
erzeugt keine verfrühte Warnung. Reine Fernangriffe behalten ihre Positionierung.

Die gemeinsame Schwierigkeit beeinflusst zusätzlich das normale Boss-Bewegungstempo.
Bei der Positionierung wird ein Weg durch Denti vermieden. Während fest
angekündigter Hofurteile bleibt ihr Ursprung stehen. Die Portalbahnen behalten
ihre Weltkoordinaten auch beim anschließenden Schweben des Imperators.
Die Bewegung zwischen Salven endet vor der nächsten Warnung. Erst dort wird
der neue Ursprung festgelegt; während der Warnung bleibt er stehen.

`crown_court_positioning` prüft 48 Annäherungen an entfernte bzw. seitlich
laufende Ziele auf allen vier Stufen und in drei Bildformaten. Dazu kommen
erneutes Nachsetzen zwischen Urteilen, Pausieren/Fortsetzen, kein Weg durch
Denti und eine feste Position während der Warnung. Der bestehende
`REPOSITION`-Zustand speichert den noch ausstehenden Angriff; es entstehen
keine neuen Zustandsnummern oder Savefelder. Native Hell-Prüfung: 580 px
Startabstand, Warnbeginn bei 280 px, danach unveränderter Bossstandort.

## Darstellung, Grenzen und Fortsetzen

Urteilflächen verwenden den [gemeinsamen analytischen Warnungsrenderer](UNIFIED_TELEGRAPHS.md).
Eine ruhige Gesamtfläche zeigt den Umfang, die stärkere Füllung wächst bis zur
Freigabe. Keine zusätzlichen Umrisskreise oder Laufzeit-Bilderzeugung. Die Siegel,
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

`REPOSITION` wurde an die Zustandsliste angehängt; alte Zustandsnummern bleiben
gültig. Das gesondert gespeicherte `portal_combo`-Flag verhindert, dass eine
bereits halb abgelaufene alte Urteilwarnung beim Laden eine ungezeigte Portalbahn
erhält. Kombowarnung, Neupositionierung und fliegende Lanzen überstehen echtes
Speichern/Fortsetzen.

## Nachweise und offene Balance

Die folgende vollständige Test-/Messhistorie beschreibt den Stand vom 21.10.
Für die neuen Abläufe gelten die [Prüfungen vom 30.10.](ROYAL_PRESSURE_BALANCE.md).
Die Druckmessungen unten stammen noch aus der Zeit vor der Zielkorrektur vom
31.10. Die aktuelle Zielerfassung ist für acht Spielerrichtungen, Folgesalven,
die Nervenkombination, Dash-Geburtszeit und alle vier Stufen geprüft. Die
Ecken-/Ausweichprüfungen einschließlich 216 Urteil-/Portalkombinationen haben
mit der neuen Zielerfassung erneut bestanden, ebenso die Ziel-, Save- und
Schwierigkeitsprüfungen. [Native Hell-Aufnahme](screenshots/emperor_targeting.png).

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
