# Karies-Graf: der Umhang-Graf

Stand: 20.10.2026. **Im regulären Kampf, Story und Endlos aktiv.** Der Graf
verwendet weiterhin `data/enemies/cavity_count.tres`; die alten Kissenbahnen
sind dort durch einen eigenen Umhang-Encounter ersetzt. Die drei anderen
Bossprofile bleiben unverändert.

## Figur und Darstellung

Der ausgewählte Entwurf C ist ein burgunderfarbener Bettwanzen-Vampir mit
einem einzelnen Fangzahn, Fühlern und einem gepolsterten Umhang. Zwölf Knochen
und zwei gewichtete Stoffnetze bewegen die bereits generierten Einzelteile;
es gibt keinen Wechsel der Ganzkörperbilder. Körper und Gesicht bleiben starr
und proportional, die Stoffspitzen ziehen nach. Das Gesicht bleibt vor dem
Stoff sichtbar. Die dritte Schlagpose und ihre Erholung werden eingeblendet,
damit die Gelenke nicht auf die andere Umhangseite springen.

Das Rig hängt unter dem bisherigen visuellen Enemy-Knoten und übernimmt
Trefferfarbe, Bobbing, Pausen und die vorhandene Boss-Todesanimation. Ein aus
dem Rig nativ gerendertes transparentes Porträt ersetzt den alten Zahn auch im
Storydialog. [Teile, ursprünglicher Generierungsprompt und Rig](concepts/count-rig.md).
Neue Grafiken wurden für diese Integration nicht generiert und keine
Originalreferenzen überschrieben.

## Ablauf und Startwerte

1. Der Graf sucht eine Position mit möglichst langem kürzestem Fluchtweg aus
   seinem Sektor. Auf dessen Mittellinie sind seitlicher Ausgang und Außenrand
   bei `Reichweite / (1 + sin(Halbwinkel))` gleich weit entfernt: normalerweise
   **207 Welteinheiten**, beim schmaleren Wandsektor ungefähr **247**.
   Nähert sich Denti zu stark, geht der Graf dafür auch zurück. Er nimmt den
   nächstgelegenen erreichbaren Punkt auf diesem Abstandskreis, innerhalb der
   Arena und ohne den Weg durch Denti zu legen. Sein Anlauf verwendet das
   normale, durch Nässe/Tempo/Entzündung veränderte Bewegungstempo × **2,5**.
   Eine Toleranz von 18 Einheiten erlaubt den Angriff schon nahe am Ziel.
   Nach **0,65 s** darf er auch aus einer näheren Position angreifen, damit ein
   nachsetzender Nahkämpfer ihn nicht endlos rückwärtslaufen lässt.
2. Er öffnet den Umhang und markiert einen Sektor **0,85 s** im Voraus.
   Ursprung, Richtung und Winkel bleiben ab Warnbeginn fest. Der Wirkungsbereich
   ist 340 Einheiten lang und normalerweise insgesamt 80° breit.
3. Der schnelle Schlag dauert 0,24 s einschließlich Nachschwingen. Schaden ist
   ausschließlich im Abschnitt **0,04–0,14 s** aktiv. Markierung, Stoffpose,
   heller Schlagstrich und Treffer folgen demselben Encounter-Timer.
4. Während **0,32 s** setzt der Graf sichtbar nach: Er sucht erneut den
   günstigen Abstand zum aktuellen Denti statt eines beliebigen Seitenversatzes.
   Die Füße setzen dabei abwechselnd auf. Danach zielt er erneut auf Denti.
   Der nächste Schlag besitzt wieder **0,75 s** vollständige Vorwarnung.
   Die erste Phase hat zwei Schläge; ab der nächsten Gesundheitsphase sind es drei.
   Der Einstieg bleibt der Fächer. Bei Zweierfolgen wechselt der zweite Schlag
   pro Folge zwischen Stoß und Ring; Dreierfolgen sind Fächer → Stoß → Ring.
5. Anschließend folgen **1,05 s Erholung**. Die ersten **0,35 s** steht er und
   atmet durch, danach korrigiert er seine Position mit **55 % seines Anlauftempos**.
   Ein anderer aktiver Graf erhält dabei weiterhin Abstand. Während Warnung
   und Schlag bleibt der Graf vollständig stehen; angekündigte Flächen wandern nicht.
   Schaden, Reichweite und Vorwarnzeit wurden für diese Bewegungsänderung nicht erhöht.
   Entzündung verkürzt nur diese Pause
   bis auf ungefähr 0,75 s und verstärkt den normalen Anlauf; Vorwarnungen und
   Trefferfenster werden nicht schneller abgespielt.

An Wänden wird der angekündigte Sektor auf insgesamt 44° eingeengt, damit eine
seitliche Flucht nicht am Arenarand scheitert. Dieser Winkel wird beim Warnen
festgelegt und ebenfalls gespeichert. Zwei Grafen reservieren ihre Folgen
nacheinander; ein wartender Graf hält größeren Abstand. Die Regeneration des
Schmelzschutzes, Gesundheitsphasen und Verstärkungen bleiben erhalten. Ein
Phasenwechsel bricht eine laufende Folge ab und beginnt später mit neuer Warnung.

Es gibt keine zusätzlichen HP, keine zusätzlichen generischen Projektilringe
und keine langsam wandernden Kissen mehr. Ein einzelner früher Seitenschritt
erledigt die neu zielenden Nachschläge nicht automatisch.

## Drei Schlagformen

Die drei Flächen verwenden inzwischen den gemeinsamen vorbereiteten Warnatlas:
feste korallrote Grenze, ruhige Füllung, animierter goldener Saum. Ein Ring
benötigt zwei Texturrechtecke statt 64 Füllsegmenten und zusätzlichen Kurven.
Warnung und Lichtanimation folgen weiterhin dem Encounter-Timer.
[Darstellung, Speicher und gemessene Performance](TEXTURED_WARNINGS.md).

Die Geometrien liegen separat in `data/encounters/count_fan.tres`,
`count_thrust.tres` und `count_ring.tres` (`CloakStrikeData`).

| Schlag | Gefahrfläche | Bevorzugter Abstand | Ausweichantwort |
| --- | --- | ---: | --- |
| Umhangfächer | 80°-Sektor, Radius 340; an Wänden 44° | 207 / 247 an Wänden | seitlich oder nach außen |
| Umhangstoß | 28°-Sektor, Radius 420 | 338 | besonders seitlich |
| Saumschlag | Ring zwischen Radius 130 und 290 | 210 | nach innen oder über den Außenrand |

Der Ring verteilt keine neuen Geschosse und füllt seinen Innenbereich nicht.
Sein größter kürzester Fluchtweg liegt zwischen beiden Rändern: einschließlich
Dentis Körperradius 100 Einheiten. Ein Zielradius von 100 im Innenbereich lässt
auch Abstand zur Körperkollision des Grafen. Die nächsten Bodenflächen werden
erst nach dem Nachsetzen sichtbar und besitzen jeweils die volle Warnzeit.
Die gesamte Ringfläche ist im bestehenden kurzen Trefferfenster aktiv; die
helle auslaufende Linie ist nur Schlagfeedback, keine separate wandernde Gefahr.

Der Stoß zieht beide Umhangseiten zusammen, der Ring öffnet sie gemeinsam.
Die bereits generierten Teile werden ausschließlich mit Knochen bewegt;
es wurden dafür keine neuen Bilder gemalt oder Ganzkörperbilder gestreckt.
Wechselnde Posen werden über das erste Viertel der nächsten Warnung eingeblendet.

## Schaden, Pause und Fortsetzen

Die normale Schadensverarbeitung übernimmt Härte, Schild, Zahnflutsch und
Trefferpause. Jede einzelne Schlagfläche kann höchstens einmal treffen. Die
Kreis-/Sektorprüfung berücksichtigt Dentis Körperradius und die gesamte
Dashstrecke im tatsächlich aktiven Zeitabschnitt. Ein Dash bietet keine neue
Unverwundbarkeit und kann aktive Gefahr nicht durch einen langsamen Frame
überspringen. Reine Warnzeit verursacht keinen Schaden.

`CloakEncounterData` enthält die Werte, `CloakEncounter` besitzt die maßgebliche
Zustandsmaschine. `EnemySnapshot` speichert die versionierte Phase, Restzeit,
Folge, Schlagvariante, gesperrte Richtung/Position/Winkel und verbrauchte Treffer. Die Knochenpose
wird daraus wiederhergestellt. Alte Kissen-/Charge-Saves erhalten eine Pause
und danach eine vollständige neue Ankündigung; keine alte Attacke wird als
unsichtbarer neuer Treffer fortgesetzt. Tod und Gesundheitsphase entfernen
aktive Warnungen zuverlässig.
Saves aus der vorherigen Fächerversion ohne Variantenfeld beenden ihre bereits
angekündigte Fläche weiterhin als Fächer. Neue Formen verwenden denselben
Einmaltreffer-/Schildpfad; die Ringprüfung erfasst auch Dashes mit beiden
Endpunkten außerhalb der Gefahrfläche.

Der Menü-Warmup zeichnet auch das echte Rig samt Skinning einmal, bevor es im
Kampf benötigt wird. Der historische `PillowEncounter` bleibt nur für die
Vergleichswerkzeuge und dessen separate Regressionstests erhalten.

## Prüfung und Messung

`tests/cloak_encounter.gd` prüft Zeitpunkt und Ortsbindung, optimalen Fluchtabstand,
Annäherung und Rückzug ohne Teleport, begrenzten Rückzug gegen Nahkämpfer,
Erholungsbewegung erst nach der Atempause, erneutes Zielen,
Schilde/Einmaltreffer, tatsächlichen Schaden im Dash, seitliche Dashstrecken,
Eckrouten mit Grundtempo, Snapshot-/Szenenfortsetzung, Pausen, alte Saves,
Phasenabbrüche, Doppel-Graf und Tod. Die Rig-Geometrie wird zusätzlich über
615 Posen aller drei Bewegungen auf kollabierende Dreiecke und Gesichtsverzerrung geprüft.

Der vollständige Lauf bestand zunächst mit **121/122**; allein die bisherige
exakte Anzahl der Warmup-Knoten musste um das neue Rig ergänzt werden.
Warmup, neuer Encounter und Smoke bestanden danach gemeinsam mit **3/3**.
Vollständiger Lauf: `.godot/test_runs/20261020-205435-ffab03c3`, korrigierter
Warmup-Lauf: `.godot/test_runs/20261020-205732-95d8afce`.
Nach der Bewegungsänderung bestanden zusätzlich Rig, Smoke, Entzündung, Nässe
und Wellenbalance; der erweiterte Encounter-Test inklusive Schrittpose und
Fortsetzen bestand in `.godot/test_runs/20261020-211725-c28487b3`.
Die gezielte Platzierung bestand anschließend mit Bossdruck, Smoke und
Wellenbalance in `.godot/test_runs/20261020-212136-c531b540`; Encounter und
Wellenbalance nach dem Rückzugslimit in `.godot/test_runs/20261020-212303-8dbf5009`.
Die drei Formen bestanden mit Rig, Entzündung, Bossdruck und Warmup als **5/5**
in `.godot/test_runs/20261020-212950-1d15c2b1`; Smoke und Wellenbalance bestanden
ebenfalls. Die neuen Tests prüfen alle Formen auf Treffer, Warnzeit, Fortsetzen,
Einmaltreffer und Eckrouten sowie Ringloch und zeitlich begrenzte Dashstrecken.

`tools/measure_cloak_boss.gd` vergleicht den vorherigen Kissen-Grafen mit dem
neuen Ablauf: isolierte Welle 5 Normal, 120 Roh-DPS innerhalb 148 beziehungsweise
600 Einheiten, keine Items, Adds oder Dashes, feste 60 Schritte/s und
skriptgesteuerte Bewegung. [Rohdaten](count_cloak_measurements.json).

| Verhalten | Kissen: Schaden Nah / Fern | Umhang: Schaden Nah / Fern |
| --- | ---: | ---: |
| Stehen bleiben | 151,8 / 151,8 | 1547,5* / 267,8 |
| Nur auf die erste Warnung reagieren | 0 / 23,6 | 178,6 / 148,8 |
| Jede Warnung beantworten | 0 / 23,6 | 208,3 / 0 |

*Ein stillstehender Nahkämpfer erreicht den Grafen bei 207 Abstand mit dem
synthetischen Radius 148 überhaupt nicht: nach 90 s abgebrochen, kein Kill.
Diese Zeile ist daher kein Vergleich gleich langer Kämpfe. Aktives Nachsetzen
außerhalb der Warnungen ergibt ungefähr **19,9–21,1 s**, Fernkampf **18,8 s**.
Der Ausweichcontroller wählt nun den kurzen Weg senkrecht über die Sektorkante
oder über den Außenrand einschließlich Körperradius; im Nahkampf verfolgt er
außerhalb von Warnungen auch während Schlag/Schritt, wodurch er erneut getroffen
werden kann. Die Probe legt weder echte Waffenbuilds noch vollständige Wellen
zugrunde; daraus folgt keine abgeschlossene Balanceabnahme. Menschliche Tests,
sehr langsame Builds, Touch und Web-Performance bleiben offen.

## Native Aufnahmen

`tools/preview_cloak_boss.gd -- --animate` erzeugt Desktop-, Hoch- und
Querformatansichten und eine arrangierte sieben Sekunden lange Ausweichdemo.
Sie verwendet Grundbewegung ohne Dash und einen unbewaffneten Denti, damit der
Ablauf sichtbar bleibt. Die Portrait-Aufnahme beginnt in unmittelbarer Nähe,
um Figur und Warnung im kleinen Ausschnitt gemeinsam zu zeigen. Das ist kein
menschlicher Spieltest und keine Performance-Messung.

[Desktop](screenshots/count_cloak/desktop.png) ·
[Hochformat](screenshots/count_cloak/mobile.png) ·
[Video](concepts/count-bedbug/fight.mp4) ·
[GIF](screenshots/count_cloak/fight.gif)

Formvergleich: [Fächer](concepts/count-bedbug/fan-area.png) ·
[Stoß](concepts/count-bedbug/thrust-area.png) · [Ring](concepts/count-bedbug/ring-area.png).

Das MP4 enthält die vollständige sieben Sekunden lange Aufnahme mit 30 Bildern/s;
das kleinere GIF zeigt einen 4,4-s-Ausschnitt der ersten Folge.

Das Porträt lässt sich mit `tools/capture_count_portrait.gd` aus der nativen
Rig-Szene neu rendern. Originale Einzelteile bleiben unverändert.
