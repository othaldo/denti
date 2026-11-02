# Buildvergleich und Balance-Diagnostik

Stand: 01.11.2026. Ausgangspunkt ist der Spieltest mit zwei UV-Lampen und einer
Zahnseiden-Schneide auf Normal. Der Vergleich untersucht Waffenrollen,
Verzauberungen und zusätzliche Shopstärke. Er rekonstruiert nicht den konkreten
Run: Seine Entscheidungen und damaligen Statwerte liegen nicht vor.

## Leitlinie: Buffs vor Nerfs

Zuerst schwächere Alternativen durch eine attraktive Rolle, verlässliche Treffer
oder angemessenen Ertrag für ihr Risiko verbessern. Befriedigende Mechaniken und
sichtbare Machtzuwächse sind erwünscht. Hoher Schaden allein begründet keinen Nerf.

Numerische Leistung und wahrgenommener Spielspaß werden getrennt beurteilt.
Ein gezielter Nerf braucht Hinweise auf trivialisierte Gefahren, verdrängte
Alternativen oder einen strukturellen Fehler. Ebenso wenig werden alle Waffen
blind gebufft: Gegnerdruck, Wirtschaft, Heilung und Progression gehören zur
gleichen Prüfung. Klassen bauen später auf dieser Grundlage auf.

Der erste darauf aufbauende [spielbare Balancepass](BALANCE_FIRST_PASS.md) ist
umgesetzt. Die folgenden Originaldaten dokumentieren den Zustand **vor** diesem
Pass; sie werden nicht mit neuen Werten überschrieben.

Ergänzung 02.11.: [Verdienter Ausbau bis zum ersten Hell-Boss](EARNED_PROGRESSION.md)
prüft den zuvor ausgeblendeten Weg über Kills, Gold/XP, tatsächliche Käufe und
mitgenommenen Lebensverlust. Gleiche Checkpointbudgets garantieren keinen gleich
gut erreichbaren Ausbau.

## Ausgangsbefund

Die Rückmeldung zum **maximalen Lebensraub** verändert die Diagnose deutlich.
Der UV-Mix läuft in der folgenden Kontrollprobe mit derselben Mk-IV-Ausrüstung,
soliden Qualität, denselben Grundstats und demselben allgemeinen Warenkorb.
Nur die beiden Verzauberungen wechseln. Drei Seeds, einfache Kreisbewegung,
jeweils vollständige Welle 19; HP, Schaden und Heilung sind Gruppenmediane.

| Verzauberung | Punkte | Welle bestanden | HP am Ende | Schaden erhalten | Heilung |
| --- | ---: | ---: | ---: | ---: | ---: |
| Feuer 10 allein | 60 | 0/3 | 0 % | 198,2 | 42,2 |
| Lebensraub 10 allein | 60 | 3/3 | 96,5 % | 454,8 | 441,8 |
| Feuer 10 + Lebensraub 10 | 120 | 3/3 | 96,2 % | 450,0 | 437,1 |

Die isolierten Hälften kosten absichtlich weniger als die Kombination. Entscheidend:
Lebensraub allein besteht diese Probe bereits mit derselben Punktinvestition wie
Feuer allein. Der normale Warenkorb liefert weiterhin eigene Heilung; ohne die
Lebensraub-Verzauberung wird sie in dieser Probe aber nicht ausreichend.
Alle sechs Elemente plus maximaler Lebensraub bestehen beim UV-Mix Welle 19
und den Endboss jeweils 3/3. Die exakte Elementwahl erklärt den Befund hier nicht.

Beim Endboss gewinnt Feuer allein 1/3, Lebensraub allein 3/3 und die Kombination
3/3. Mit beiden Effekten liegt die mediane Boss-TTK bei 57,7 Sekunden und die
mediane Endgesundheit bei 100 %. Selbst die Variante ohne Shop-Items und ohne
Qualitätsboni besteht den Endboss mit beiden maximalen Effekten 3/3; die normale
Welle 19 besteht sie allerdings nur 1/3. Die Gefahr unterscheidet sich damit
zwischen Hordenwelle und Bosskampf. Dies ist kein nachgespielter 20-Wellen-Sieg.

Die Beobachtung spricht für **zu verzeihenden Sustain in einem sicheren
Flächenbuild**, nicht für einen universellen Rohschadens-Ausreißer oder
2–5-Sekunden-Bosskills. Alle Stillsteh-Proben des UV-Mixes scheitern in diesen
beiden späten Wellen; Bewegung bleibt nötig. Eine simple wiederholte Laufroute
reicht mit maximalem Lebensraub im getesteten Ausbau aber oft aus, um sehr viel
Schaden ohne bleibende Konsequenzen zu nehmen.

Auch die Nahkampfdiagnose benötigt die passende Spielweise. Der ursprüngliche
Nachsetzpilot vergaß den Bossradius bei seiner Abstandswahl; kurze Waffen liefen
dadurch zu weit in den Gegner. Die 48 alten [Nachsetzproben](balance_build_pursuit.md)
bleiben als historische Rohdaten erhalten, begründen aber keine Waffenänderung.
Die [korrigierte Kontrolle vor dem Patch](balance_patch_pursuit_before.md) besteht
mit Bohrer und Bürste die ersten beiden Bosse jeweils 3/3. Ihre medianen TTKs
liegen bei 19,4/24,6 Sekunden (Bohrer) und 24,8/22,5 Sekunden (Bürste).
Die Bürste ist somit kein nachgewiesen schwacher früher Bosskiller. Ihr kleiner
Arbeitsbereich und das Risiko im Gedränge begründen den moderaten Nutzen-Buff.

Aus der Diagnose abgeleitete Reihenfolge:

1. **Interdental-Bürste gezielt attraktiver machen:** praktische Trefferabdeckung
   und Raumgewinn durch ihren Rundumschnitt untersuchen. Ihr Risiko soll sich
   lohnen; ein bloß höherer theoretischer Einzelziel-DPS hilft wenig, wenn sie
   beim Bewegen kaum angreifen kann. Der Bohrer behält seine Nahkampf-Bossrolle.
2. **Normal auf den starken Sustain-Build prüfen:** vorhandene angekündigte
   Raum-/Flankengefahren so kombinieren, dass man seine Route anpassen muss.
   Kleine Fehler bleiben verzeihbar; wiederholtes Ignorieren soll Konsequenzen
   haben. Keine universelle HP- oder Schadensmultiplikation, die schwächere
   Builds zusätzlich ausschließt.
3. **Lebensraub als Buildentscheidung prüfen:** Verfügbarkeit, Investitionszeitpunkt,
   Ränge und Zusammenspiel mit Rüstung/anderen Heilungen betrachten. Zuerst
   defensive Alternativen und echte Opportunitätskosten bewerten. Falls der
   maximale Ausbau weiterhin andere Entscheidungen verdrängt, ist ein gezielter
   Eingriff in Sustain begründbar. Die starke UV-/Elementwirkung soll sich dabei
   weiter befriedigend anfühlen. Ein pauschaler UV-Schadensnerf ist durch diese
   Isolationsprobe nicht der erste sinnvolle Schritt.

Die ursprüngliche Diagnose änderte keine Spielwerte. Der anschließende
[Balancepass](BALANCE_FIRST_PASS.md) dokumentiert jetzt Bürsten-Buff, lesbares
Vorzielen des Imperators und abnehmenden Lebensraub-Zuwachs auf hohen Rängen.

## Vergleichsaufbau

Vier Builds belegen jeweils sechs Wurzeln:

| ID | Ausrüstung | Untersuchte Rolle |
| --- | --- | --- |
| `uv_floss` | 2× UV-Lampe + Zahnseiden-Schneide | sicherer Linienangriff und Nahbereich |
| `melee_single` | 6× Turbo-Bohrer | kurzer Einzelziel-Nahkampf |
| `melee_area` | 6× Interdental-Bürste | kurzer Rundum-Nahkampf |
| `ranged_single` | 6× Schmelzspiegel | sofortiger Fernkampf gegen Einzelziele |

Die Matrix umfasst 576 Kämpfe: vier Builds × acht Wellen × drei Ausbaustände ×
zwei Bewegungsmuster × drei Seeds. Normale Wellen vor einem Meilenstein und die
zugehörigen Bosswellen werden unabhängig voneinander geprüft.

| Wellen | Mk | Goldobergrenze | Verzauberungspunkte | Entsprechende Kapseln | Shop-Items |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4 / 5 | I | 250 | 12 | 6 | 2 |
| 9 / 10 | II | 700 | 30 | 15 | 8 |
| 14 / 15 | III | 1300 | 48 | 24 | 16 |
| 19 / 20 | IV | 2200 | 72 | 36 | 24 |

- `base`: neutrale Waffen ohne Verzauberungen und Items, gemeinsame Statprogression.
- `enchanted`: dieselbe Basis mit Feuer, ab Mk II Lebensraub, ab Mk III Tempo.
  Ränge je Waffe: Feuer 2; Feuer 3 / Lebensraub 2; Feuer 4 / Lebensraub 2 / Tempo 2;
  zuletzt Feuer 6 / Lebensraub 3 / Tempo 3. Wurzelkosten ergeben identische Punkte.
- `shop`: wie `enchanted`, zusätzlich gleiche solide Waffenqualität und ein
  wiederholter allgemeiner Warenkorb: Schmelzsplitter, Titankrone, Bissschraube,
  Speicheltropfen, Druckspülung, Feenquittung. Ihre Nachteile und normalen Effekte
  bleiben aktiv. Keine Relikte, Evolutionen oder Mk-V+-Aufstiege.

Alle erhalten dieselbe Anzahl grundlegender Statverbesserungen. Das flache
Nah-/Fernschadensbudget verteilt sich nach den Wurzeln der jeweiligen Familie.
Genauer Ausbau, Preise und nach Items wirksame Stats stehen unter `setups` im JSON.

Gold bezeichnet eine gemeinsame **Obergrenze**, keine identisch ausgegebene Summe.
Berechnet werden direkte Shopangebote der gewählten Mk-Stufe und Items zu den
normalen Preisen des vorangehenden Shops. Restgold wird ausgewiesen und nicht
umverteilt. Angebote gelten als verfügbar; Rerolls, Fundchancen, kostenlose
Startwaffe und Fusions-/Kaufhistorie werden nicht simuliert. Die Profile sind
kontrollierte Checkpoints, kein Nachweis garantierter Erreichbarkeit in einem Run.

## Kampf und Messwerte

- Normal, 1280×720, echte Arena/Gegner, feste 60 Hz. Normale Wellen behalten ihre
  Länge; Bosskämpfe laufen bis Tod, Bosskill oder maximal 90 Sekunden. Entzündung,
  Schutzphasen, Adds, Statuseffekte und Gegnerlimits bleiben aktiv.
- Audio ist im Probeaufbau abgeschaltet. Der normale Soundcontroller begrenzt
  Stimmen anhand der Echtzeit und würfelt Tonhöhen mit dem globalen Generator;
  diese Darstellungszufälle sollen die reproduzierbaren Kampfproben nicht verändern.
- `stationary` steht in der Arenamitte. `orbit` folgt mit normalem Bewegungstempo
  einer Ellipse mit Halbachsen 480/280 Pixel. Normale Spielerphysik, Bodeneffekte
  und Kollisionen bleiben aktiv. Keine Teleports, gezieltes Ausweichen oder Dashes.
  Das Muster ist ein Kontrollversuch, kein menschlicher Spielerbot.
- Spawn-Anfragen entstehen vorab durch den echten `WaveController`. Gleiche
  Wave/Seed-Kombinationen verwenden denselben Plan; Kill-, Crit- und Lootzahlen
  verändern seine Anfragen nicht. Der Plan besitzt einen Hash. Positionen
  entstehen durch echte Spawnfunktionen relativ zu Denti; Bewegung und erreichte
  Gegnerlimits dürfen die tatsächliche Begegnung verändern.
- Erfasst werden Schaden, verbleibende/minimale HP, tatsächliche Heilung,
  Überheilung, Lebensraub, Kills, blockierte Spawns, Projektildichte und Boss-TTK.
  Waffenschaden und DoTs/Folgeeffekte stehen getrennt im Ergebnis.
- `near_enemy_fraction` zählt Schritte mit einem lebenden Gegnerkörper in höchstens
  120 Pixel Entfernung. `target_in_range_fraction` schätzt geometrische Zielchancen,
  nach Wurzeln gewichtet. Das sind Näherungen, keine Messung aller Gefahren oder
  tatsächlicher Angriffszeit; Strahlbreite und Blickrichtung fehlen darin.
- Boss-TTK ist bei Tod/Zeitlimit **null**. Die Tabelle nennt nur den Median
  erfolgreicher Kills und deren Anzahl. DPS/Kills bis zum Tod besitzen ein kürzeres
  Messfenster. Ein überlebter Probe-Kampf ist keine Run-Winrate.
- Zähler/HP werden nach dem letzten Physikschritt gelesen. In einer der 810
  Proben traf noch eine kleine Itemheilung im selben Schritt wie der Tod ein.
  Das Todesereignis bleibt maßgeblich; positive Rest-HP machen daraus keinen Sieg.
- Loot bleibt wirksam, XP verdient ausstehende Levelaufstiege. Gefundene Kapseln
  geben während des Tests keine sofortigen Buffs. Jeder Kampf startet unabhängig
  mit voller Gesundheit.

## Reproduktion

Nach dem normalen Godot-Import:

```powershell
python tools/run_build_comparison.py --godot Godot_v4.7.2-stable_win64_console.exe
```

Unter Linux `python3` und `--godot godot` verwenden. Bis zu vier Godot-Prozesse
laufen mit getrennten Benutzerdaten; normale Spielstände, Einstellungen, Erfolge
und Run-Berichte werden nicht beschrieben. Gameplay-/Benchmarkquellen müssen
während der Messung unverändert bleiben. Der Bericht enthält Engineversion,
Git-Basisrevision und einen Quellcode-Hash.

```powershell
python tools/run_build_comparison.py --waves 19,20 --builds uv_floss,melee_single --modes enchanted,shop --movements orbit --seeds 13579 --output .godot/build_subset.json
python tools/run_build_comparison.py --summarize
```

[Rohdaten](balance_build_comparison.json) und
[alle Gruppenmediane](balance_build_comparison.md).
Prozesslogs stehen unter `.godot/build_comparison/`.

## Telemetrie für echte Runs

Neue abgeschlossene Run-Berichte enthalten die finalen Spielerwerte. Jede neue
Welle erhält eine unabhängige Kopie der anfänglichen Stats, Waffen mit Qualität
und Verzauberungen, Items, Relikte und verbliebenen Upgradepunkte. Pro Welle werden
tatsächliche Heilung, Überheilung sowie Waffen-/Procschaden getrennt gespeichert.
Bestehende Boss-TTK-, Schadens-, Dichte- und Wirtschaftswerte bleiben verfügbar.
Die normale Spieloberfläche bekommt keine zusätzlichen Elemente.

Speichern/Fortsetzen erhält die Daten. Alte Spielstände bleiben ladbar; fehlende
historische Heilung und Builddetails werden nicht rückwirkend erfunden. Bei einer
fortgesetzten alten Welle sind die neuen Zähler erst ab dem Fortsetzen erfasst.
Ab der nächsten Welle ist auch der Startbuild vorhanden.

## Prüfungen und Spielgefühl

`tests/build_comparison.gd` prüft Wurzel-/Punktebudgets und Goldgrenzen, gültige
Verzauberungen, unabhängige Spawnpläne, wiederholte echte Angriffe, Lebensraub,
endliche HP, Tod und normale Bewegungsgeschwindigkeit.
Ein echter Prinzenkampf deckt außerdem den Übergang in die Entzündung und das
Aufräumen gepoolter Projektile ab. Wie im Spiel liegt das Wellenende nach dem
Physikschritt; bereits zum Löschen vorgemerkte Projektile werden nicht noch in
einem zusätzlichen Schritt in den Pool zurückgelegt.

Die korrigierte Zusatzprobe [gezieltes Nachsetzen](balance_patch_pursuit_before.md)
umfasst 48 Bosskämpfe mit dem `shop`-Ausbau. Alle Builds laufen gezielt zum Boss
und kreisen bei Bossradius plus 75 % der kürzesten eigenen Waffenreichweite.
Derselbe Algorithmus gilt für alle; Angriffe, Telegraphe und Dashes werden nicht
bewusst berücksichtigt. Die frühere Variante ohne Bossradius ist verworfen.
Das kontrolliert den Nachteil, den reiner Nahkampf beim Kreisen durch die Arena
hat. Es ist weiterhin kein Ersatz für menschliche Nahkampf-Spieltests.

Nach der Rückmeldung **Element und Lebensraub auf Maximum** ergänzt
[die Maximalprobe](balance_build_max_enchantments.md) 186 Kämpfe in Welle 19/20:
alle vier Rollen mit Feuer 10 allein, Lebensraub 10 allein und beiden zusammen;
jeweils Stillstehen/Kreisbewegung und drei Seeds. Zusätzlich wird der UV-Mix mit
den fünf anderen maximalen Elementen beim Kreisen sowie ohne Items/Qualitätsboni
mit maximalem Feuer und Lebensraub geprüft. Beide Effekte kosten zusammen
120 Punkte / 60 Kapseln für sechs Wurzeln, eine isolierte Hälfte 60 Punkte.
Alle Waffen eines Probe-Builds erhalten diese Ränge. Das ist ein kontrollierter
Maximalfall; die genaue Fund-/Kaufhistorie des gespielten Runs bleibt unbekannt.

```powershell
python tools/run_build_comparison.py --controller pursuit --output docs/balance_build_pursuit.json
python tools/run_build_comparison.py --controller max --output docs/balance_build_max_enchantments.json
```

Die 576 Basisproben, 48 Nachsetzproben und 186 Maximalproben ergeben 810 Kämpfe.
`tests/extended/max_enchantment_comparison.gd` prüft die sechs Elemente sowie
gleiche, tatsächlich ausgegebene 60-/120-Punkte-Budgets und die Variante ohne Items.
`tests/extended/run_telemetry.gd` prüft reale Heilung/Überheilung, unabhängige
Startbuilds, Wellenwechsel, JSON-Fortsetzen und abgeschlossene Run-Berichte.

Menschliche Tests prüfen zusätzlich: Macht die Waffe Freude? Ist ihre Schwäche
verständlich? Lohnt sich ihr Risiko? Bleiben mehrere Builds attraktiv? Sind
Gefahren lesbar und einzelne Fehler verzeihbar, während wiederholtes Ignorieren
Konsequenzen hat? Erst Messungen und Spielgefühl zusammen begründen den Eingriff.
