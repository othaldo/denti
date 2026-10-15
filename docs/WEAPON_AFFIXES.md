# Verzauberungen aus Upgrade-Kapseln

Im Spiel heißen Affixe **Verzauberungen**. Die am weitesten entwickelte
Verzauberung bestimmt einen Namenszusatz, etwa „Zauberbürste der Glut“ oder
„Turbo-Bohrer der Eile“. Bei Gleichstand bleibt die Reihenfolge der belegten
Plätze maßgeblich. Der Zusatz wird aus der jeweiligen Waffeninstanz abgeleitet;
Ersetzen, Verstärken, Fusion und Fortsetzen aktualisieren ihn automatisch.
Mk-Stufe und alle weiteren Verzauberungen bleiben separat sichtbar.

Erster spielbarer Stand: Upgrade-Kapseln verbessern eine konkrete Waffeninstanz. Es gibt
keine festen Kapselwellen, keine garantierte Run-Gesamtzahl und keine Maximalstufe
für den Schaden eines Affixes. Waffen bleiben Shopkäufe; ihre Werte werden pro Angebot individuell gewürfelt.

![Drei Funde für eine gewählte Waffe](screenshots/affix_chest_1280x720.png)

## Funde und Entscheidungen

- Drei unterschiedliche Angebote werden beim Drop festgelegt und gespeichert.
- Nach Loot-Sweep und ausstehenden Level-ups wird die Zielwaffe gewählt.
  Alle Waffen stehen als anklickbare Karten bereit; auch ersetzbare Effekte haben
  eigene Buttons. Es gibt keine Dropdowns.
- Gleiche Art und Seltenheit erhöht die Ausbaustufe I → II → III.
  Nach III folgt beim nächsten passenden Fund die nächste Seltenheit I.
- Ein höherer Fund derselben Art springt direkt auf seine Seltenheit I. Niedrigere
  Funde geben 50 % / 25 % / 12,5 % Fortschritt bei einer / zwei / drei Seltenheiten Abstand.
  Der Schaden steigt zwischen den Ausbaustufen anteilig; kein passender Fund ist wertlos.
- Sobald Affixe vorhanden sind, enthält jede neu gedroppte Upgrade-Kapsel mindestens einen
  passenden Fund mit mindestens der Seltenheit eines vorhandenen Affixes.
  Die übrigen Typen bleiben zufällig und unterscheiden sich vom passenden Fund.
- Eine Waffe startet mit einem Slot. Ab Welle 2 ersetzt ein Slotfund mit 20 %
  Wahrscheinlichkeit das dritte Angebot, solange mindestens eine Waffe den
  vierten Slot noch nicht besitzt. Die maximale Affixanzahl ist vier. Slotfunde öffnen
  den jeweils nächsten Slot; der dritte und vierte Slot stehen ebenfalls zur Wahl.
- Ein neuer Effekt belegt einen freien Slot. Sind alle Slots belegt, muss der
  Spieler ausdrücklich den zu ersetzenden Effekt auswählen. Wiederholungen
  verbessern den passenden Effekt unabhängig von dieser Ersatzwahl.
- Alternativ wird die ganze Upgrade-Kapsel für Münzen zerlegt. Ohne ausgerüstete Waffe
  bleibt diese Option verfügbar.
- Zielwaffe, Ersatzwahl und alle drei Funde überstehen Fortsetzen unverändert.
- Alte gespeicherte Item-Upgrade-Kapseln bleiben KEEP/SCRAP-Belohnungen.

Seltenheit und Ausbau stehen getrennt neben dem elementaren Effekt. Seltenheitsnamen
verwenden dieselben Farben wie Mk-Stufen: Gewöhnlich = Mk I, Ungewöhnlich = Mk II,
Selten = Mk III, Legendär = Mk IV. Elementnamen und Trefferzahlen behalten ihre
Elementfarbe. Details, Ersatzwahl und Upgrade-Kapseln zeigen I/II/III bzw. III+.

| Seltenheit | I | II | III |
| --- | --- | --- | --- |
| Gewöhnlich | 3 | 4 | 5 |
| Ungewöhnlich | 7 | 9 | 11 |
| Selten | 14 | 17 | 20 |
| Legendär | 25 | 30 | 35 |

Nach Legendär III bringt jeder weitere legendäre Fund derselben Art +2 Schaden.
Alte Waffen behalten ihren bereits gespeicherten Schaden als Untergrenze; ihre
neue Ausbaustufe startet bei I. Gespeicherte neue Stufen und legendäre Beiträge
werden unverändert wiederhergestellt.

## Zusätzlicher Schaden

| Verzauberung | Schadenszahl | Eigene Rolle |
| --- | --- | --- |
| Feuer | Orange | Schaden über 2 s; beim Tod Glut an bis zu drei Ziele |
| Eis | Blau | 15 % Slow für 1,5 s; Krits gegen gekühlte Gegner lösen Eissplitter aus |
| Gift | Grün | Schaden über 5 s; wiederholtes Vergiften baut bis zu fünf Stufen auf |
| Blutung | Rot | Schaden über 3 s; gemeinsame Synergien mit Blutungsitems und Blutmond |
| Elektro | Gelb | Ein Kettensprung, +1 durch Nässe und +1 durch Kettenitems, höchstens drei |
| Nässe | Cyan | Kein Zusatzschaden; Nassstatus für Elektro, Leitlack und Spülpfützen |
| Weihe | Gold | Drei kritische Treffer auf ein markiertes Ziel erzeugen einen Lichtstoß |
| Lebensraub | Rosa | Kein Zusatzschaden; begrenzte Heilung durch wirksame Waffentreffer |

Zusammen mit Reichweite und Angriffstempo gibt es zehn Verzauberungen. Alle
Mechanikwerte liegen in `WeaponAffixData`-Ressourcen. Die Rollen ersetzen einen
Teil des alten pauschalen Schadens: Feuer/Eis/Gift erhalten 65 %, Blutung 80 %,
Elektro 55 % des bisherigen Werts. Alte Investitionen und Rangfortschritt bleiben
gespeichert; die neuen Faktoren gelten auch für vorhandene Waffen.

Feuer, Gift und Blutung rechnen weiter in Halbsekunden-Raten ab. Jede Anwendung
hat ein eigenes Budget, das beim erneuten Treffen weder aufgefrischt noch erneut
multipliziert wird. Gift erhöht ausschließlich neue Budgets: höchstens eine neue
Stufe je 0,6 s, +15 % pro weiterer Stufe bis +60 %. Nach 5 s ohne Gift verfällt der
Aufbau. Blutungsuhr verlängert die Verzauberung bis zur gemeinsamen Obergrenze
von 8 s. Zahnseide ergänzt auf Waffen ohne eigene Schnitt-Blutung die normalen,
begrenzten Blutungsstapel. Skalpellwachs, Verbreitung und Blutmond erkennen beide
Blutungsquellen; DoT-Kills lösen die Todesmechaniken ebenfalls aus.

Glut überträgt 45 % eines einzelnen akzeptierten Feuerbudgets an höchstens drei
Gegner in 115 Reichweite, höchstens alle 0,35 s. Übertragene Glut kann sich nicht
erneut verbreiten. Eissplitter treffen bei Krits höchstens sechs andere Gegner
in 95 Reichweite mit 75 % des gespeicherten Eistreffers, Intervall 0,8 s.

Elektro springt alle 0,45 s. Ein nasses Startziel vergrößert die Sprungreichweite
um 85. Kettenitems verstärken den Sprungschaden von 45 % um höchstens weitere
60 Prozentpunkte des Elektrotreffers. Leitlack verstärkt Elektro gegen bereits
nasse Ziele um höchstens 100 %. Jedes Ziel wird innerhalb einer Kette nur einmal
getroffen. Zusätze durch Wasser-/Lichtitems bleiben eigene, getrennt gemessene
Folgeeffekte.

Nässe hält `min(1,2 + Stärke × 0,06; 4)` Sekunden, mit Leitlack +0,5 s.
Weihe speichert höchstens drei Krit-Markierungen für 4 s; Krits anderer Waffen
können ein markiertes Ziel auslösen. Der Lichtstoß trifft höchstens acht Ziele
in 105 Reichweite, Intervall 0,8 s. Sein Schaden beträgt Stärke × Waffen-/Bisskraft-
Skalierung × 0,9 × 1,3. Lebensraub heilt höchstens 5 % des tatsächlich gezählten
Trefferschadens und `min(0,25 + Stärke × 0,04; 2)` HP je Impuls, alle 0,75 s.
Alle Waffen teilen diese Intervalle. DoTs und Folgeeffekte lösen keine neuen
Waffentreffer oder Lebensraub aus. Gegnerverteidigung und Boss-/Elitebudgets
gelten auch für alle Folgeeffekte.

Neue Funde starten auf Stufe I ihrer Seltenheit. Die Ressourcen unter `data/affixes/`
enthalten die zwölf Ausbauwerte. Bei der Verwendung skaliert der Zusatz mit
`(Basisintervall / 0,65)^0,65` und Bisskraft. Schwere, langsamere Waffen erhalten
größere Ergänzungen pro Treffer; schnelle Waffen kleinere. Karten erklären zuerst
die Wirkung und zeigen danach den angepassten Schaden dieser Waffe samt Dauer
bzw. direktem Schaden pro Treffer. Upgrades zeigen den bisherigen und neuen Wert
sowie den Ausbaufortschritt. Der Tooltip enthält zusätzlich den festen Fundwert
(Basisschaden auf Stufe I). Diese Werte gelten vor Gegnerresistenzen.
Beim Waffenwechsel bleibt der Fundwert gleich; nur die Vorschau der Waffenwirkung
verändert sich. Symbole und Titel teilen sich eine Zeile; linksbündiger Text,
schmalere Innenränder und dynamische Höhen nutzen die Kartenbreite. Schmale
Bildschirme zeigen die Angebote untereinander im scrollbaren Menü.

Mk und der normale Krit-Multiplikator multiplizieren diesen Zusatz nicht.
Gezielte Synergien wie Leitlack greifen ausschließlich an den beschriebenen Stellen.
Seitliche Bürstengeschosse und zusätzliche Offenbarungsstrahlen skalieren auch
ihren Affixschaden mit ihrem jeweiligen Schadensanteil. Rückflug verwendet den
gleichen Rückflugfaktor wie der Grundschaden. Evolutions-Sekundärschaden startet
keine neuen Affix-Procs.

Grundschaden und direkte Zusätze bilden weiterhin einen gemeinsamen Treffer für
Verteidigung, Bossphasen und Boss-/Elite-Schadensbudgets. DoT-Anwendungen werden
bei einem akzeptierten Treffer auf überlebenden Gegnern gespeichert. Ihre späteren
Ticks durchlaufen dieselbe Verteidigung und dieselben Schutzbudgets. Während
Unverwundbarkeit verfallene Ticks werden nicht nachträglich ausgezahlt.
DoT-Fraktionen haben keinen künstlichen Mindestschaden von 1; Overkill wird in
der Telemetrie auf verbleibendes Leben begrenzt. Item-/Relikt-On-Hit-Mechaniken
laufen nur am Grundtreffer; DoTs starten keine rekursiven Treffer-Procs.

Die neue Komponente `EnemyAffixEffects` speichert höchstens die feste Anzahl
zukünftiger Halbsekunden-Raten je Effekt, unabhängig von der Trefferzahl.
Restzeit, Raten, Giftaufbau, Glut-Herkunft, Eisschaden, Weihemarken und gemeinsame
Abklingzeiten werden beim Fortsetzen erhalten, ohne Resistenz oder Aufbau erneut
anzurechnen. Treffer gegen bereits tote Gegner erzeugen keine weiteren DoTs.

Die Karten nennen passende vorhandene Build-Teile. Shopgewichtung berücksichtigt
Verzauberungstags. Die Debug-Telemetrie trennt Elektroketten, Eissplitter und
Lichtstöße und zählt tatsächliche Lebensraub-Heilung, Nasstreffer und Glutereignisse.
`tests/enchantment_synergies.gd` prüft Rollen, Itemverbindungen, Grenzen,
Schutzphasen, Fundpool, Textglyphen, Fortsetzen und 300 feste Schritte mit echten automatischen Nahkampf- und Projektilangriffen. Die Werte sind ein Ausgangspunkt
für weitere Spieltests, keine abschließend gemessene Balance.

Eis und Nass verwenden die stärkere Verlangsamung, ohne sie zu multiplizieren.
Eliten erhalten die halbe Eiswirkung, Bosse ein Viertel. Angekündigte Anstürme
bleiben wie bei Nass unverändert. Schadenszahlen bleiben im bestehenden
Darstellungsbudget; der tatsächlich berechnete Schaden wird nie verworfen.
Treffer und Heilungen zeigen nur Zahlen in ihrer jeweiligen Farbe, keine Typnamen.

![Zusatzschaden und goldener Gegner im echten Trefferpfad](screenshots/affix_damage_1280x720.png)

## Zufällige Drops und goldene Gegner

- Normaler Kill: 1,6 % Kapselchance.
- Elite-Kill: 16 %.
- Glück multipliziert die Chancen mit `1 + 3 × max(Glück, 0) / (max(Glück, 0) + 100)`.
  Bei 100 Glück: 4 % normal / 40 % Elite; Obergrenze: vierfache Chance.
- Höchstens drei gewöhnliche Zufallsfunde pro Welle. Neue normale Drops bleiben
  an die aktive Timerzeit gebunden. Bosse selbst droppen weiterhin keine Upgrade-Kapsel.
- Ab Welle 3 kann ein regulär gespawnter normaler Gegner mit 0,17 % Chance ein
  goldener Träger werden. Glück erhöht diese Chance um höchstens 50 %.
- Höchstens ein goldener Träger pro Welle, ohne feste Spawnzeit oder Wellenliste.
- Träger besitzen 2,8× Leben und 85 % Laufgeschwindigkeit, goldene Färbung und
  Glitzer. Ihr Kill während aktiver Timerzeit garantiert eine goldene Upgrade-Kapsel,
  auch wenn alle drei gewöhnlichen Zufallsfunde bereits gefallen sind.
- Goldene Funde sind mindestens Ungewöhnlich; ihre Seltenheit würfelt mit
  vier zusätzlichem Wellenfortschritt auf der vorhandenen, begrenzten Kurve.
- Grundwert beim Zerlegen: `5 + floor(Welle / 2)`, goldene Upgrade-Kapseln zusätzlich +5;
  vorhandene Zerlegeboni bleiben wirksam.

Die Häufigkeit ist eine großzügigere erste Balancehypothese. Es gibt keinen
festen Zielzähler und keinen Ausgleich für lange Durststrecken. Reale Run-Berichte
sollen zeigen, wie viele Upgrade-Kapseln fallen, wie viel zusätzlicher Schaden entsteht
und wie sich Boss-TTK verändert. Affixschaden steht als `affix_fire`, `affix_ice`,
`affix_poison`, `affix_bleed` und `affix_electric` in der bestehenden Proc-Telemetrie.

## Fusion und Fortsetzen

Waffeninstanzen besitzen eine dauerhafte ID, Slotkapazität und eigene Effektliste.
Gleiche Fusionsaffixe behalten die höhere Seltenheit und ihren Ausbau. Bei gleicher
Seltenheit wird der Ausbau des zweiten Affixes als passende Beiträge angerechnet;
Niedrigere Beiträge liefern anteiligen Fortschritt. Legendäre Zusatzbeiträge
werden übernommen. Der höhere bereits vorhandene Schadenswert bleibt mindestens erhalten. Unterschiedliche Effekte werden übernommen, sofern ihre
Anzahl in die größere Slotkapazität beider Waffen passt. Andernfalls bleibt die
Fusion gesperrt. Es wird kein wertvoller Effekt still verworfen. Dieselben
Regeln gelten für Zwei-Waffen-Evolutionen. Die Primär-ID bleibt bei Fusion und
Evolution erhalten. Verkauf erstattet weiterhin nur investierte Münzen.

Alte Waffen erhalten einen leeren Slot und keine Affixe. Neue Instanzfelder sind
additive Save-Erweiterungen; die globale Save-Version bleibt kompatibel.
Aktive Projektile speichern ihre eigene Affixkopie und den Schadensfaktor.
Recycelte Projektile erhalten beim Start neue Daten und übernehmen keine
Affixe ihres vorherigen Einsatzes. Goldene Gegner, Eiszeit, Upgrade-Kapseln auf dem Boden
und offene Belohnungen werden ebenfalls gespeichert.

![Individuelle Werte im Shop bei gleicher Mk-Stufe](screenshots/weapon_rolls_shop_1280x720.png)

## Prüfung und Vorschau

`tests/weapon_affixes.gd` prüft getrennte Exemplare, 100 niedrigere Funde mit weiterlaufendem Fortschritt,
Seltenheitsschutz, Slots, bewusstes Ersetzen, Fusionsschutz, Glück, Farben,
Bossbudgets, Overkill, Projektilquellen, garantierte goldene Drops, Combat- und
Reward-Resume sowie unterbrechungsfreie Sammlung und Layouts bis 360×640 und 568×320.

`tools/preview_weapon_affixes.gd` rendert Desktop-/Mobilkapseln und die arrangierte
Kampfvorschau mit echten Schadenspfaden und getrenntem Spielstand:

```bash
godot --path . --fixed-fps 60 --script res://tools/preview_weapon_affixes.gd
```

## Individuelle Shop-Waffen

Mk-Stufe und individuelle Qualität sind getrennte Eigenschaften. Jedes neue
Waffenangebot würfelt vier Werte innerhalb seiner Qualitätsbandbreite:

| Wert | Gesamtbereich relativ zur Standardwaffe |
| --- | --- |
| Grundschaden | 60–170 % |
| Angriffspause | 72–135 % (kleiner ist schneller) |
| Reichweite | 80–125 % |
| Zusätzliches Crit | 0–10 Prozentpunkte |

Qualitäten heißen Schrott, Solide, Meisterwerk und Göttlich. Ihre Wertebereiche
überlappen; einzelne Werte werden getrennt gezogen. Höhere Wellen und Glück
verbessern die Qualitätschancen innerhalb fester Grenzen. Mk färbt weiterhin
Waffennamen (z. B. „Zauberbürste · Mk I“), Rahmen und Stufenmarker. Individuelle
Qualität färbt ausschließlich die vier Zahlenwerte, separat nach ihrer Position
im jeweiligen Rollbereich: unter 38 % gewöhnlich, ab 38 % ungewöhnlich, ab 68 %
selten, ab 90 % legendär. Bei Angriffspause ist kleiner besser. Ein Mk-I-Angebot
mit sehr guten Werten bleibt dadurch ein Mk-I-Angebot. Tooltips nennen die
Wertequalität; Karten, DPS und Vergleich zeigen die tatsächlichen Werte.
Preise verwenden weiterhin die bestehende Mk-/Wellenkurve.

Reservierte Angebote behalten ihre Werte. Kauf und Fortsetzen würfeln nichts neu.
Manuelle und automatische Fusion übernehmen je Attribut den besseren Wert beider
Exemplare: Maximum für Schaden, Reichweite und Crit, Minimum für Angriffspause.
Legendäre Einzelwerte können dadurch beim direkten Kartenkauf nicht verloren gehen.
Bei mehreren passenden Partnern gewinnt das Ergebnis mit der höchsten erwarteten
Grund-DPS unter den aktuellen Spieler- und Itemwerten; bei Gleichstand entscheidet
die Reichweite, danach die Ausrüstungsreihenfolge. Verzauberungs-Konflikte bleiben
bei manueller Fusion gesperrt. Affixe verbinden sich nach den Ausbau-Regeln; beim
Kauf bleiben alle Affixe des ausgerüsteten Exemplars erhalten. Zusätzliche Mk-Aufstiege
aus Kapseln übernehmen den höheren Stand beider Waffen, ohne ihn zu addieren. Tempo-
und Reichweiten-Verzauberungen werden aus den übernommenen Affixen neu berechnet.
Die Details zeigen Fusionspartner und Ergebnis vorab; es gibt eine einzige Kaufaktion.
Evolution übernimmt weiterhin die Rollfaktoren der Primärwaffe auf die neue Waffenbasis.
Alte Saves bleiben neutral; bei Fusion gelten ihre neutralen Faktoren als Vergleichswerte.
Affix-Beiträge skalieren mit dem Standardintervall des Waffentyps, unabhängig vom
individuellen Tempo-Roll, damit ein Wertewechsel die gespeicherten Beiträge nicht ändert.

`tests/weapon_rolls.gd` prüft Vielfalt, tatsächlichen Kauf, Reservieren, Shop- und
Waffen-Resume, bessere Einzelattribute, optimale Partnerwahl, direkten Fusionskauf,
Vorschau, unveränderte Ausgangsressourcen, Projektil-Resume und Dropfrequenz.
Eine Simulation mit 20/30/40/55/60/70/80/90 normalen Kills je Welle und 300 Seeds
liefert im Mittel 6,8 Upgrade-Kapseln ohne Glück und 14,7 mit konstant 100 Glück bis Welle 8.
Das ist ein Vergleichsmodell, keine garantierte Run-Ausbeute.

`tests/affix_progression.gd` prüft alle Ausbauübergänge, Seltenheitssprünge,
endloses legendäres Wachstum, Fusion, Migration, passende Angebote und Mk-Farben.

Die höhere Gegnerdichte und HP-Kurve nach Einführung der Affixe kompensieren
deren zusätzlichen Schaden. [Zahlen und Vergleich](AFFIX_PRESSURE_BALANCE.md).

## Gegnerresistenzen

Resistenzen reduzieren ausschließlich den passenden Affix-Zusatzschaden (und bei
Blutung auch die bestehende Waffen-/Item-Blutung). Der Grundtreffer verwendet
weiterhin das normale Verteidigungssystem. Resistenzen wirken einmal vor normaler
Schadensreduktion; sie verändern die Eis-Verlangsamung nicht. Standard ist 0 %,
die Datenobergrenze 60 %. Es gibt in diesem Stand keine Immunitäten.

| Gegner | Resistenz |
| --- | --- |
| Plaque | Feuer 25 % |
| Bakterium | Gift 30 % |
| Giftkeim | Gift 50 % |
| Säurespucker | Gift 35 % |
| Zuckerstück | Blutung 35 % |
| Säurekrone | Eis 30 % |
| Jagdkeim | Elektro 25 % |

Ein kleines Schild in Elementfarbe am Gegner zeigt die Resistenz. Farbige Punkte
über dem Gegner zeigen laufende Affix-DoTs. Im Dentikon erklärt „Resistenzen“
die Farben und konkreten Gegnerprofile; der Begriff ist aus den Waffendetails
verlinkt. Schadenszahlen bleiben reine Zahlen mit Elementfarbe.

`tests/affix_damage_over_time.gd` prüft Budgeterhaltung, getrennte Laufzeiten,
Wiederholungen, Bruchteile, Resistenz und Verteidigung, Overkill, Boss-Schutz und
Fortsetzen. Der zentrale Bewegungstest vergleicht beide Simulationspfade auch
mit laufendem Feuer und Gift.

## Waffenwerte, vier Slots und Mk-Funde

Reichweite und Angriffstempo sind eigene Affixe und belegen einen der bis zu vier
Slots. Ihre Ausbauwerte sind Prozentpunkte (3/4/5, 7/9/11, 14/17/20, 25/30/35).
Weitere legendäre Beiträge liefern +2 Prozentpunkte. Reichweite multipliziert
Basisreichweite und alle Stufenbereiche; Angriffstempo verkürzt die Angriffspause
über Division durch `1 + Tempo / 100`. Beide verändern nur die gewählte Waffe und
verursachen keinen zusätzlichen Elementarschaden. Entfernen oder Ersetzen nimmt
auch ihren Bonus zurück. Der ursprüngliche Shop-Roll bleibt erhalten.

Ab Welle 8 können Upgrade-Kapseln sehr selten einen Mk-Aufstieg auf dem dritten Platz
enthalten, sofern mindestens eine Waffe die Basisstufe IV erreicht hat: 2,5 %,
mit Glück bis höchstens 4 %. Der Fund braucht keinen Affix-Slot. Je Fund erhält
die gewählte Waffe +1 Mk, +10 % Basisschaden sowie +3 % Tempo und Reichweite.
Diese Zuschläge summieren sich gegenüber der Waffenbasis; sie potenzieren sich
nicht miteinander. Shop und normale Fusion enden weiter bei IV. Mk V, VI usw.
kommen ausschließlich aus Upgrade-Kapseln. Die Angriffsmuster/Pierce-/Geschossstaffeln
bleiben auf dem Mk-IV-Muster; höhere Mk erhöhen die genannten Waffenwerte.

Evolutionen sind separate Waffenformen auf Basisstufe IV. Sie erhalten Rollen,
Affixe und Mk-Funde; bei zwei Zutaten werden deren Mk-Funde zusammengeführt.
Eine Evolution allein vergibt keine zusätzliche Mk-Stufe mehr. Stufenanzeige und
Rahmen entsprechen der tatsächlichen Mk-Stufe, statt pauschal Mk V zu behaupten.

Anwendbare Funde tragen eine sichtbare Aktionszeile. Schwächere gleiche Affixe
zeigen Fortschrittsgewinn, einen Balken und vorher/nachher. Volle Slots verlangen
sichtbar eine Ersatzwahl; Slotfunde bei vier Slots und Mk-Funde unter IV nennen
den konkreten Grund. Im HUD steht die Anzahl bereits eingesammelter Upgrade-Kapseln
der laufenden Welle, einschließlich goldener und eingesammelter Restbeute.
Der Zähler wird bei neuer Welle zurückgesetzt und beim Fortsetzen wiederhergestellt.

`tests/weapon_chest_expansion.gd` prüft Wirkung, Fortschritt, vier Slots, seltene
Mk-Funde, Save/Resume für Waffen und Projektile sowie den Wellenzähler.
