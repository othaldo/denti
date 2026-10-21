# Karies-Prinz: die Karamellküche

Stand 21.10.2026. Eigenständiger spielbarer Prinz-Encounter mit drei Angriffsabläufen für Welle 10,
Story und Endlos. Schwierigkeit skaliert jetzt auch Bewegung, Aktionsmenge
und Projektile. Graf, König und Imperator verwenden dieselben gemeinsamen
Druckfaktoren; König und Imperator behalten vorerst ihre bisherigen Repertoires.
Die alte Prinz-Grafik bleibt als Original erhalten.

## Figur

Ein selbstgefälliger Karamellprinz steckt in einem breiten Kupferkessel. Seine
Zuckergusskrone, große Kelle und Zuckergranate ergeben eine andere Silhouette
als der Umhang-Graf. Fünf Bone2D-Gelenke bewegen Körper, beide Arme und Füße.
Alle gemalten Teile werden proportional skaliert und nur als starre Teile
gedreht/versetzt; Gesicht und Kessel werden nicht verzerrt. Die Animation wird
aus demselben Timer wie Wurf und Warnung abgetastet, nicht unabhängig abgespielt.

Die generierten Teile liegen in
`assets/enemies/prince_caramel/parts.png` (1254×1254, RGBA, Mipmaps).
`prince_caramel_art.gd` wählt gecachte AtlasTexture-Ausschnitte aus dem
unveränderten Original. Das native Rig-Porträt für Storydialog und Ressource
liegt in `assets/enemies/prince_caramel/portrait.png` (384×384).
[Generierung, Referenzen und vollständiger Prompt](concepts/prince-caramel-art.md).

## Drei Angriffsabläufe

Vor dem Ausbau wurden die Ideen für Prinz, König und Imperator zusammen gelesen
und zu unterscheidbaren Repertoires ausgearbeitet:
[Bedeutung der Angriffe und Eskalation aller drei Bosse](BOSS_ATTACK_DIRECTION.md).
König und Imperator sind dort Entwürfe, noch keine neuen Laufzeit-Encounter.

Die Reihenfolge im Prinz-Profil ist Bombenfolge → Herzfächer → Zuckerrausch.
Alle drei sind bereits in Phase 1 verfügbar. Jede beendete oder durch eine
Gesundheitsphase abgebrochene Folge gibt an die nächste weiter. Das Repertoire
wird nicht nach jedem Phasenwechsel wieder auf dieselbe Bombe zurückgesetzt.

Die folgende Basistabelle gilt für Normal:

| Ablauf | Vorwarnung / Aktion | Phase 1 / 2 / 3 |
| --- | --- | --- |
| Bomben | 0,50 s Ausholen + 0,60 s Flug je Bombe | 2 / 3 / 3 Würfe |
| Herzfächer | 0,85 s Vorbereitung, 0,22 s Abwurf; weitere Salve mit 0,75 s neuer Warnung | 5 / 7 / 9 Herzen; 1 / 2 / 2 Salven |
| Zuckerrausch | 0,90 s feste Lichtbahn, 0,45 s Bewegung über höchstens 255 Einheiten | gleiche faire Warnzeit und Strecke |
| Herzkranz nach Zuckerrausch | 0,80 s eigene Vorbereitung; 0,25 s Freigabe | 12 / 14 / 16 mögliche Strahlen, vollständiger Ring ohne Aussparung |

Der Fächer verwendet genau die vorher angekündigten Richtungen. Die zweite
Salve zielt neu und wird um einen halben Strahlabstand versetzt angekündigt.
Ein angehobenes Karamellherz, eine vorgebeugte Ansturmhaltung und die weit
geöffnete Kranzhaltung unterscheiden sich auch in den fünf Gelenken des Rigs.
Der Herzkranz feuert gleichmäßig in alle Richtungen. Seine Rotation hängt
nur vom Ablaufzähler ab, nicht von Dentis Position. Kein Schuss wird für
Denti ausgelassen und es gibt keine goldene Sicherheitsmarkierung.

Die Herzgeschosse lesen das vorhandene generierte Herzmotiv aus Atlaszelle 8.
Sie sind 30 Einheiten breit, haben Radius 10 plus Dentis Körperradius, fliegen
auf Normal mit 245 Einheiten/s und laufen nach 3 s aus. Maximal 28 pro Prinz
auf Normal, 42 auf Hard und 56 auf Hell; zwei Prinzen behalten getrennte
Projektilbudgets und koordinieren den Beginn ihrer Angriffe. Eine Zeichenebene pro Boss stellt
alle Herzen oberhalb der Figuren dar, nicht ein neuer Szenenknoten pro Herz.
Schaden verwendet 55 % des bestehenden Boss-Angriffsschadens. Kollisionsweg,
Launchzeitpunkt und Dash-Ende werden relativ zueinander geprüft.

Beim Zuckerrausch stimmen Bodenbahn, Bewegung und Körpertreffer überein.
Die Bahn bleibt fest. Die Dash-Kollision berücksichtigt den bewegten Prinzen
auch dann, wenn er von außerhalb der ursprünglichen Suchstrecke hineinläuft.
Ein Rush-Kontakt und seine Pause werden mit gespeichert, damit Fortsetzen
keinen bereits verrechneten Kontakt noch einmal verursacht.

## Schwierigkeit: Easy, Normal, Hard und Hell

Eine eigene Profilkopie pro Boss kombiniert die Bossdaten mit der gewählten
Difficulty-Ressource. Vorwarnungen, Bombenflugzeit, Projektilradius und Laufzeit
bleiben erhalten. Schwierigkeitsgrade skalieren Aktionen und Bewegung zusätzlich
zu den bereits bestehenden Lebens-/Schadens-/Verteidigungskurven.

| Eigenschaft | Easy | Normal | Hard | Hell |
| --- | --- | --- | --- | --- |
| Bomben je Folge, Gesundheitsphasen 1 / 2 / 3 | 1 / 2 / 2 | 2 / 3 / 3 | 3 / 4 / 4 | 4 / 5 / 5 |
| Herzen je Fächer | 3 / 5 / 7 | 5 / 7 / 9 | 7 / 9 / 11 | 9 / 11 / 13 |
| Fächersalven je Folge | 1 / 1 / 1 | 1 / 2 / 2 | 2 / 3 / 3 | 3 / 4 / 4 |
| Herzgeschwindigkeit | 220,5 | 245 | 274,4 | 313,6 |
| Herzkränze nach Ansturm | 1 | 1 | 1 | 2 |
| Tatsächliche Geschosse je vollständigem Kranz | 8 / 10 / 12 | 12 / 14 / 16 | 16 / 18 / 20 | 20 / 22 / 24 |
| Maximale Ansturmstrecke | 229,5 | 255 | 285,6 | 344,25 |
| Erholung nach Folge | 1,38 s | 1,15 s | 0,92 s | 0,6325 s |
| Kochposition suchen | 0,78 s | 0,65 s | 0,52 s | 0,3575 s |
| Zusätzlicher Boss-Bewegungsfaktor | 0,9 | 1 | 1,12 | 1,35 |
| Bewegung zwischen Salven relativ zur Positionierung | keine | 0,45 | 0,8 | 1,15 |
| Spätere Graf-Schlagfolge | 2 | 3 | 4 | 5 |

Ab Normal bewegt sich der Prinz zwischen Würfen und Salven sowie nach zunächst
0,30 s stationärer Erholung. Er plant seitliche Positionswechsel und läuft
nicht durch Denti. Warnungen fixieren weiter den Ursprung und die Schussbahnen.

Fächer besitzen durchgehend gleichmäßige 18°-Abstände. Es werden keine
zusätzlichen Strahlen erzeugt und anschließend für eine freie Gasse entfernt.
Beide Herzkränze sind vollständige Kreise; der zweite auf Hell ist um einen
halben Geschossabstand versetzt. Seine Rotation folgt nicht dem Spieler.
Ausweichen erfolgt über Bewegung, Abstand, normale Geschossabstände und Timing.
Auch die bisherigen Phasenringe von König/Imperator sind vollständig und
haben keine auf Denti ausgerichtete ausgesparte Gasse mehr. Warnstrahlen
entsprechen ihren tatsächlichen vollständigen Verteilungen.

Graf, König und Imperator verwenden dieselben gemeinsamen Bewegungs-,
Erholungs- und Projektilfaktoren. Beim Grafen skalieren die Schlagfolgen
auch nach unten auf Easy. Beim König/Imperator wachsen sowohl die Anzahl
aufeinanderfolgender Salven als auch die Geschosszahl im einzelnen Ring.
Ältere gespeicherte längere Easy-Folgen dürfen ihre bereits angekündigten
Schritte beenden; neue Folgen verwenden die neue Stufung.

### Messung und Grenzen

Im 40-s-Vergleich mit stationärem unbewaffnetem Ziel, zweiter Gesundheitsphase
und ohne Adds ergeben Easy/Normal/Hard/Hell **45 / 84 / 99 / 176** Herzen,
**17 / 21 / 24 / 27** Warnungen und **1646,9 / 2191,6 / 2509,8 / 3308,8**
zurückgelegte Einheiten. Jede Stufe erhöht tatsächliche Aktions-, Projektil-
und Bewegungsmenge. [Methode und Rohdaten](boss_difficulty_pressure_measurements.json).

`tests/boss_difficulty_pressure.gd` prüft alle vier Stufen, vollständige
positionsunabhängige Ringe, feste Warnungen, verlangsamte Eckrouten gegen
Hell-Fächer und gegen beide vollständigen Ringe auf allen Schwierigkeiten.
Beim versetzten zweiten Ring wartet die getestete Bewegung erst den ersten
Ring ab und wechselt dann in den nächsten regulären Geschossabstand. Es wird
keine zusätzliche Lücke in den Angriff gebaut. Weitere Prüfungen betreffen
shared Ressourcen, zwei Prinzen, generische Boss-Charges/-Geschosse und echtes
Fortsetzen mit vier Salven und mehr als 28 fliegenden Herzen.

Gesamtlauf **127/127**: `.godot/test_runs/20261021-000151-63efa23b`.
Die zusätzliche Eckroutenprüfung vollständiger Ringe anschließend bestanden:
`.godot/test_runs/20261021-000453-2c045173`. Abschließende sechs
Encounter-/Projektil-/Warnprüfungen: **6/6** in
`.godot/test_runs/20261021-000814-513f1dc0`.

Ganze Wellen mit echten Builds, Touch, Endlos-Doppelboss und Web-Framerate
bleiben menschlich zu prüfen. Die strukturelle Druckmessung ist keine
menschliche Schwierigkeitsbewertung oder Balancefreigabe. Im separaten
120-Roh-DPS-Modell bleibt vorsichtiger Hell-Nahkampf nach 90 s unvollendet;
das ist ein offener Reichweiten-/Balancepunkt und keine gemessene Kill-Zeit.
[Hell-Rohdaten](prince_caramel_hell_measurements.json).

## Bombenfolge im Detail

1. Der Prinz sucht vor der Serie kurz eine Kochposition. Der Wunschabstand
   beträgt höchstens 300 Einheiten; Nähe wird nicht ständig durch Flucht auf
   volle Wurfweite aufgehoben. Auf schmalen Displays nutzt er sichtbaren Raum
   oberhalb/unterhalb Dentis. Er beginnt eine Serie erst im sichtbaren Bereich.
2. Die Einschlagstelle wird festgelegt und sofort als warme Glutmarkierung
   ohne geometrischen Kreisrand sichtbar. Nach 0,50 s Ausholen startet die
   Zuckerbombe aus der tatsächlichen Position der Kelle.
3. Der sichtbare Bogenflug dauert 0,60 s. Erst bei der Landung gibt es einen
   einzelnen Einschlagtreffer mit Radius 96 plus Dentis Körperradius. Lange
   Frames und ein Dash werden am tatsächlichen Landungszeitpunkt geprüft.
4. Nach 0,28 s Abstand wird neu gezielt. Der zweite Wurf berücksichtigt
   Dentis Bewegungsrichtung: 0,8 s Vorhalt, höchstens 180 Einheiten, zusätzlich
   auf den sichtbaren Bereich begrenzt. Diese Stelle bleibt anschließend fest.
   Es gibt keine nachführende Bombe. Die erste Phase hat zwei Würfe, spätere
   Gesundheitsphasen drei. Jede Bombe erhält die volle Vorwarn- und Flugzeit.
5. Nach der Serie steht der Prinz 1,15 s still und öffnet ein Nahkampffenster.
   Erst danach versetzt er sich während 0,65 s neu. Entzündung verkürzt nur
   Erholung/Anlauf, bis maximal Faktor 1,4; Vorwarnung und Flug bleiben gleich lang.

Es gibt keine zusätzlichen HP und keine alten generischen Charge-/HP-Ringsalven
für den Prinzen. Der bestehende Schmelzschutz, die Gesundheitsphasen und deren
begrenzte Verstärkungen bleiben. Ein Phasenwechsel verwirft eine angekündigte
oder fliegende Bombe, Herzsalve oder einen Ansturm sicher; vorhandenes Karamell läuft weiter regulär aus.

## Karamell und faire Wege

Nach dem Einschlag bleibt eine organisch gemalte, ruhige bernsteinfarbene
Pfütze. Sie verursacht keinen Dauerschaden, sondern setzt normale Bewegung
innerhalb ihrer flachen Grundfläche auf 72 %. Überlappungen multiplizieren
den Effekt nicht. PlayerStats, Wurzelkraft, Dashkosten und Dashstrecke werden
nicht verändert. Ein Dash bietet weiterhin keine zusätzliche Unverwundbarkeit.

Der volle Pfützenabdruck ist ungefähr 208×108 Einheiten groß, entsprechend
dem proportional dargestellten Gemälde. Die Abfrage verwendet dieselbe flache
Ellipse statt eines unsichtbar größeren Kreises. Der Rand verblasst in den
letzten 0,75 s. Jede Pfütze endet nach genau 5 s; höchstens vier existieren
gleichzeitig, auch bei zwei Prinzen zusammen. Bei Bedarf verschwindet die
älteste. Zwei Prinzen reservieren ihre aktiven Folgen gegeneinander. Ein zweiter wartet auch ab, solange die Herzen des ersten noch fliegen.
Pfützen sind keine blockierenden Wände und keine zusätzlichen Gegner.

Bei Tod/Entfernen des Bosses verschwinden seine ausstehenden Bomben, Herzen und Felder.
Kampfpausen frieren die gesamte Uhr ein. Speichern erhält Wurfzustand,
anvisierten Ort, Flugursprung, Restzeit, Angriffstyp, Serienindex, angekündigte Strahlen, Ansturm-Endpunkt, Herzpositionen/-geschwindigkeiten und sämtliche Feldlaufzeiten.
Alte Prinz-Saves ohne diesen Zustand beginnen mit einem sicheren neuen Anlauf.

Zerstörbare Zuckerkerne aus der Roadmap sind ausdrücklich eine spätere
Erweiterung. Das bereits generierte Kern-/Herzmotiv wird jetzt ausdrücklich als Projektil verwendet. Speicherformat 2 erhält die neuen Angriffe; Version-1-Saves beenden ihre bereits angekündigte Bombenfolge ohne sofortigen neuen Angriff.

## Prüfung und Grenzen

Der vollständige Lauf mit dem neuen Repertoire bestand mit **126/126 Tests**
in `.godot/test_runs/20261020-232156-d88a815e`. Danach wurde die native
Koordinatenübergabe der Rush-Warnung visuell korrigiert und die Aufnahme erneuert.

`tests/prince_attack_variants.gd` prüft alle drei Angriffe ohne Phasenfreischaltung,
angekündigte Strahlen, neue Vorwarnung der Folgesalve, zeitkorrekten Projektilstart
in langen Frames, verbrauchte Herzen, Dash-Sweeps und Launch nach Dash-Ende,
Rushbahn/Körperkontakt, dessen Save/Resume, vollständige Kranzverteilung, sämtliche
Speicherzustände, Pause, Tod, Budget sowie echtes Fortsetzen mit fliegenden Herzen.
Für jede Fächerstufe wird von allen vier Ecken eine schadensfreie Route mit
ständig auf 72 % verlangsamtem Grundtempo gesucht, ohne durch den Boss zu laufen.

`tests/caramel_encounter.gd` prüft Integration, proportionale Gelenkposen,
feste Ziele/Vorhaltgrenze, vollständige Warnung, einmaligen Einschlag,
zeitgenaue Dash-Treffer und Dash-Ende, sichere Eckrouten auch mit Verlangsamung,
keine gestapelte Verlangsamung, stehende Erholung, Budget und Ablauf bei zwei
Prinzen, Pause, Phasenabbruch, Tod, Legacy-Saves, ungültige Speicherdaten,
Snapshot-Roundtrips und echtes Speichern/Fortsetzen während eines Flugs.
Eine mobile Prüfung verhindert den Start eines außerhalb des Bildes wartenden Prinzen.

`tools/measure_caramel_prince.gd` vergleicht den alten generischen Ablauf und
das neue Repertoire isoliert in Welle 10 mit 120 Roh-DPS. Alle drei
Angriffstypen werden in den neuen Messfällen tatsächlich beobachtet, maximal
18 Herzen und drei Bodenfelder gleichzeitig. Fernkampf benötigt ungefähr
36 s, die vorsichtige Nahkampfreaktion etwa 54,4 s. Beide einfachen
Reaktionsmodelle erhalten inzwischen Schaden (45,7 beziehungsweise 114,3). Gleichmäßiges Kreisen wird getroffen. Das längere
Nahkampfmodell ist ein offener Balancepunkt, keine neue feste Mindestkampfzeit.
Die Bewegungsmodelle sind einfache Reaktionen, keine optimalen menschlichen
Spieler. Ein nicht gewonnener 90-s-Fall ist ausdrücklich keine Kill-Zeit.
[Rohdaten und genaue Methode](prince_caramel_measurements.json).

Diese Werte sind keine Balancefreigabe. Ganze Bosswelle, echte Waffen/Builds,
Touch, zwei Bosse mit normalen Gegnern und Web-Framerate müssen menschlich
gespielt werden. Es gibt keine neue Laufzeit-Bilderzeugung: Flächen und
Flugbombe sind Ausschnitte derselben vorbereiteten Grafik. Die GPU-Kosten
des vollständigen Kampfes auf Mobilgeräten sind noch nicht vermessen.

## Vorschau reproduzieren

`tools/preview_caramel_prince.gd` erzeugt native Desktop-, Hochkant- und
Querformat-Aufnahmen sowie 18 Sekunden Kampf mit skriptgesteuertem Denti.
`-- --stills-only` erzeugt die Einzelstudien ohne das Video neu aufzunehmen.
`-- --hell` nimmt den Hell-Ablauf in `.godot/caramel_preview_hell` auf;
die Vorschauseite bietet Easy, Normal, Hard und Hell als direkten Vergleich.
`-- --difficulty=easy` beziehungsweise `normal`, `hard` oder `hell` wählt die Aufnahme.
`-- --portrait` rendert das transparente Porträt aus den echten Rig-Teilen.
Die Aufnahmen zeigen keine Waffen und keine normalen Gegner, damit Wurf,
Einschlag und Karamell beurteilt werden können. Die Figur ist im regulären
Bossprofil eingebunden und nicht nur Teil der Vorschauseite.
