# Dentis Waffen

Zusätzlich gibt es sechs geheime Mk-IV-Evolutionen. Ihre Option erscheint erst, wenn alle Voraussetzungen erfüllt sind; normale Angebote verraten keine Rezepte. Mehrere freiwillige Evolutionen pro Run sind möglich, auch vom gleichen Typ. [Entwicklungsdokumentation mit Rezepten und Tests](WEAPON_EVOLUTIONS.md).

Denti beginnt ohne fest ins Charakterbild eingebaute Waffe. Vor Welle 1 kann jede der 18 Standardwaffen gewählt werden: Icon antippen, Mk-I-Details ansehen und mit „Run starten“ bestätigen. Weitere Exemplare gibt es im Shop. Geheime Evolutionen bleiben ausgeschlossen. [Startauswahl](STARTER_SELECTION.md).

Standardmäßig besitzt Denti **6 Wurzeln**. Die Kapazität ist ein gespeicherter
Spielerparameter und kann für Klassen oder Challenges abweichen; angebotene
Startwaffen müssen in das aktuelle Limit passen. [Konfiguration und Regeln](PLAYER_ROOTS.md).

Bisskraft verstärkt alle Waffen prozentual. Nah- oder Fernschaden ergänzt ihren Basisschaden mit einem individuellen Gewicht; die Waffenkarte zeigt den passenden Stat und seine Skalierung. Schnelle Flächenwaffen erhalten kleinere Gewichte als schwere Einzelangriffe. Fusion erhöht die Waffenbasis, ohne die rohen Stat-Beiträge zusätzlich zu vervielfachen. Die vollständigen Faktoren und Messungen stehen im [Schadens- und Verteidigungsbericht](DAMAGE_DEFENSE_BALANCE.md).

Startauswahl, Shopkarten, Waffendetails und Dentipedia zeigen die Skalierung direkt,
beispielsweise **Fernkampf · 150 %** bei der UV-Lampe: +1 Fernschaden ergibt
+1,5 Basis-Schaden vor Bisskraft. Die Erklärung steht in den Details beziehungsweise
im Tooltip. **Nahkampf** bezeichnet dabei den verwendeten Schadensstat, nicht
automatisch eine kurze Reichweite oder nur einen getroffenen Gegner. Die
Zahnseiden-Schneide nutzt **Nahkampf · 150 %**, obwohl ihre langen Fäden mehrere
Gegner treffen. Licht, Schnitt oder Bohrung sind davon getrennte Schadensarten.

Der aktuelle [DPS-Balancepass vom 4. Oktober 2026](WEAPON_DPS_BALANCE.md) vergleicht alle 18 Waffen auf Stufe I–IV vor und nach den Buffs, einschließlich Blutung, Fokus, Gruppen und DPS pro Wurzel. Nahkampf erhält mehr Schaden für das Risiko; schwächere Fernwaffen erhalten gezielte Verbesserungen. Die Zauberbürste bleibt unverändert.

Der [aktuelle Gesamtvergleich vom 1. November](WEAPON_ROSTER_REVIEW.md) ergänzt
erneuerte Schadensmessungen um volle Wellen, echte Bosse und Mischbuilds.
Besonders Turbine und Bürste zeigen dort, wie stark Kontrolle und Verzauberungen
die Einschätzung gegenüber reinen Einzelziel-DPS verändern.

| Waffe | Wurzeln | Angriff | Rolle |
| --- | ---: | --- | --- |
| Zauberbürste | 2 | Schmelz-Projektil | Verlässliche Reichweite; ab Stufe III zwei, ab IV drei Pastegeschosse mit leichtem Streuwinkel. |
| Turbo-Bohrer | 1 | Bohrung im Nahkampf | Schneller Stoß mit 8 Rückstoß; ein weiterer Gegner vorwärts erhält 50 % Schaden. Bossbonus wächst von 25 % auf 40 %. |
| Zahnseidenpeitsche | 1 | Einzelner Zahnseidenhieb nach vorn | Fester Griff, ausfahrender Faden; trifft Gegner auf seinem Weg. 180–210 Reichweite und Blutung. |
| Wasserflosser | 1 | Schnelles Wasserprojektil | Macht Ziele nass und verlangsamt sie, hat niedrigen Rohschaden und wachsenden Rückstoß. |
| Kronenwerfer | 2 | Schweres Metallprojektil | Durchdringt auf Stufe I einen weiteren Gegner, auf Stufe IV drei. |
| Schmelzspiegel | 1 | Sofortiger Lichtstrahl | Präziser Treffer ohne Flugzeit. |
| Zahnsteinkratzer | 1 | Schneller Nahkampfschnitt | 110 Reichweite, 6 Rückstoß und Blutung. Ein weiteres Ziel auf der sichtbaren Hiebspur erhält 50 % Trefferschaden; bei totem Ziel ist Ersatzkontakt möglich. |
| Mundspülungs-Mörser | 2 | Minzprojektil | Flächenschaden beim Einschlag; Explosionsradius wächst mit der Stufe. |
| Zahnstocher-Speer | 1 | Stichlinie / Schnitt | Lange, schmale Nahkampflinie trifft mehrere hintereinander stehende Gegner. |
| Karies-Fräse | 2 | Schneller Bohrungs-Nahkampf | 110 Reichweite und 6 Rückstoß; Fokus wächst um 5 % pro Folgetreffer bis +50 %. Voller Schaden gegen normale Gegner, +40 % gegen Eliten, +35–50 % gegen Bosse. |
| Interdental-Bürste | 1 | Schneller Rundumschnitt | Sehr schnelle Treffer mit 1,2 Blutungsschaden/s für 2,5 s; 100–130 Reichweite und radialer Rückstoß schaffen Platz. Der sichtbare Schwung deckt nahe und äußere Ziele gleichzeitig ab. |
| Fluorid-Sprüher | 2 | 65°-Minzkegel | Markiert Gegner für 2 s: +20 % Schaden durch Schmelzwaffen, etwa Zauberbürste und Fluorid-Rakete. Mehrere Sprüher stapeln den Bonus nicht. |
| Mundduschen-Turbine | 2 | 48°-Wasserkegel | Macht Gruppen 3 s nass, verlangsamt sie und stößt sie kräftig zurück; geringer Rohschaden. |
| UV-Lampe | 2 | Breite Lichtlinie | Sofortstrahl trifft alle Gegner entlang einer 36 Pixel breiten Linie; +10 Prozentpunkte Waffen-Crit und ×2 Crit-Schaden. |
| Amalgam-Schleuder | 1 | Schweres Metallprojektil | Langsame Kugel, kleiner Splash und hoher Rückstoß, auch bei Explosionen. |
| Zahnseiden-Schneide | 2 | Doppelter Zahnseidenhieb nach vorn | Zwei feste Griffe, zwei ausfahrende Fäden; 220–270 Reichweite, kurzer Rückstoß und 3,2 Blutungsschaden/s für 3,5 s. |
| Prophylaxe-Polierer | 1 | Schneller Licht-Nahkampf | 110 Reichweite, 4 Rückstoß und +10 Prozentpunkte Waffen-Crit. Jeder dritte Angriff pro Waffenexemplar ist kritisch, auch nach Zielwechsel und Pausen; Ersatzkontakt bei totem Ziel. |
| Fluorid-Rakete | 2 | Schmelz-Rakete | Hoher Flächenschaden, große Explosion und lange Pause; explodiert auch am Reichweitenende. |

Die Waffen haben eigene Sprites unter `assets/weapons/` und werden getrennt von Dentis Körper animiert. Alle Standardwaffen und Evolutionen verwenden ihre [Normal- und Elementformen](WEAPON_SKINS.md). Projektilfarbe, Tempo, Reichweite und Trefferform liegen in den jeweiligen `WeaponData`-Ressourcen unter `data/weapons/`.

Der [Kontaktwaffen-Pass vom 2. November](CONTACT_WEAPON_BALANCE.md) prüft kleine
Rückstöße, begrenzte Kratzerkontakte und den zielunabhängigen Polierer-Crit-Zyklus
mit verdienter Progression. Die Hell-Lücke zu sicheren Linienwaffen ist damit
weiter nicht geschlossen; insbesondere der Fräsen-Rückstoß zeigt gemischte Werte.

Der [Bürsten-Pass vom 4. November](INTERDENTAL_HELL_BUFF.md) verbessert gezielt
Reichweite, Grundschaden und Nahkampfskalierung der Interdental-Bürste und behebt
verkürzte Rundumschwünge bei nahen Gegnern.

Eine [Vergleichsansicht mit Denti und allen 18 Waffen](WEAPON_SIZE_BALANCE.md) zeigt Ruhehaltung und Angriff bei gleicher Vergrößerung. Der Bohrer ist auf Stufe I 60 Pixel groß, trifft jetzt für 28 Basisschaden alle 0,64 Sekunden und skaliert mit 100 % Nahschaden. Kratzer, Peitsche, Garotte und Speer wurden ebenfalls in ihren Proportionen angepasst; Reichweiten bleiben erhalten.

Die frühere Garotte heißt inzwischen **Zahnseiden-Schneide**. Ihre Griffe bleiben bei Denti; zwei Fäden schnellen nach vorn und treffen Gegner auf ihrem Weg. Die Peitsche arbeitet genauso mit einem Faden. Das gewählte Element bestimmt die Fadenanimation. [Native Animationen, Werte und Messung](FLOSS_CUT.md).

Die [optische Prüfung aller Waffen](WEAPON_ART_REVIEW.md) bewertet Perspektive, Werkzeugform, Haltung und Animation und nennt konkrete Prioritäten für die nächste Überarbeitung.

Die [anschließende Überarbeitung](WEAPON_ART_REFINEMENT.md) zeigt acht neue Waffengrafiken, separate rotierende Arbeitsköpfe und die bewegte Schleuder mit Bildern aus dem Spiel.

## Grundwerte der Erweiterung

Werte für Stufe I vor Spielerwerten, Items und kritischen Treffern. Schaden ist
pro Treffer und Ziel, nicht der Gesamtschaden eines Kegels oder einer Explosion.

| Waffe | Schaden | Pause | Reichweite | Preis |
| --- | ---: | ---: | ---: | ---: |
| Zahnstocher-Speer | 28 | 0,85 s | 205 | 10 |
| Karies-Fräse | 12 | 0,20 s | 110 | 15 |
| Interdental-Bürste | 8 | 0,24 s | 100 | 8 |
| Fluorid-Sprüher | 7 | 0,25 s | 155 | 14 |
| Mundduschen-Turbine | 7 | 0,36 s | 195 | 14 |
| UV-Lampe | 42 | 1,50 s | 600 | 17 |
| Amalgam-Schleuder | 28 | 1,15 s | 370 | 10 |
| Zahnseiden-Schneide | 44 | 1,20 s | 220 | 15 |
| Prophylaxe-Polierer | 10 | 0,28 s | 85 | 10 |
| Fluorid-Rakete | 70 | 2,40 s | 550 | 18 |

Alle zehn Waffen sind im normalen Shop erhältlich und unterstützen vier Stufen,
Fusion, Verkauf und Fortsetzen. Alle Standardwaffen stehen auch als Mk-I-Start zur Wahl.
Die Erweiterung nutzt individuelle Schadenskurven; Speer, Bürste, Sprüher,
Turbine, UV-Lampe und Zahnseiden-Schneide gewinnen Reichweite. Schleuder und Rakete
gewinnen Explosionsradius, Turbine Rückstoß, Fräse Bossbonus.

Der [Bohrwerkzeug-Pass](DRILL_CONTACT_BALANCE.md) ergänzt einen begrenzten
Vorwärtskontakt beim Turbo-Bohrer und verbessert den frühen Fräsen-Einstieg.
Der Bohrer kann bei verlorenem Ziel einen passenden Gegner auf derselben
Stoßbahn treffen; Reichweite, Windup und Hauptzielschaden bleiben erhalten.

Blutung, Nass, Licht-Crits und Projektiltreffer verwenden dieselben Item- und
Reliktsignale wie die bisherigen Waffen. Ziel-Fokus und Politur beginnen beim
Zielwechsel oder einer Angriffslücke neu. Spielstände erhalten ihren Zielbezug,
Zähler und Cooldown sowie aktive Fluorid-Markierungen. Angezeigte DPS schätzen
ein normales Einzelziel inklusive Waffen-Crit; Flächentreffer, Blutung,
voller Fokus und situative Itemeffekte sind zusätzliche Leistung.

Die Ausrüstung fasst sechs Wurzelplätze. Waffen mit einer Wurzel belegen einen, Waffen mit zwei Wurzeln zwei. Solange genug Plätze frei sind, fügt ein Kauf die Waffe einzeln hinzu. Ist die Ausrüstung voll, verschmilzt eine gekaufte Waffe mit einem gleichen Exemplar derselben Stufe (bis IV). Zwei bereits ausgerüstete gleiche Waffen derselben Stufe lassen sich per Rechtsklick auf eine der Waffen verschmelzen. Verkauf benötigt zwei Linksklicks und erstattet die Hälfte des Kaufwerts aller in dieser Waffe aufgegangenen Exemplare. Jede Stufe erhöht Schaden und Angriffstempo. Der Spielstand speichert Waffentypen, Stufen und investierte Münzen.

Bohrung verursacht je nach Stufe 25–40 % mehr Schaden gegen Bosse. Schnitt verursacht 15 % mehr Schaden gegen nahezu unverletzte Gegner und baut Blutung auf. Wasserflosser-Treffer machen Gegner nass. Nass senkt das Lauftempo um 20 %, bei Eliten um 10 % und bei Bossen um 5 %; angekündigte Anstürme bleiben unverändert. Erneute Treffer frischen die Dauer auf, ohne den Slow zu stapeln. [Nassregeln und Tests](WET_STATUS.md). Die anderen Schadensarten unterscheiden sich über Reichweite, Projektiltempo, Durchschlag, Rückstoß, Strahl oder Flächentreffer. Einige Gegner haben Affix-Resistenzen, sichtbar als farbige Schilde; Grundtreffer bleiben davon unberührt. Die Waffen haben individuelle Schadensmultiplikatoren und ausgewählte Eigenschaften, die mit ihrer Stufe wachsen.

Weiterentwickelte Spezialwaffen sind eigenständige Waffenformen. Ihre Mk-Stufe
kann ab IV mit Waffenpunkten und Gold gezielt auf V und höher steigen; alte
Mk-Funde bleiben erhalten. [Preise, Vorschau und Vererbung](WEAPON_ASCENSION.md). Ein grüner Aufwärtspfeil direkt auf der ausgerüsteten
Waffe im Shop zeigt eine verfügbare Fusion oder Evolution an. Er erscheint nur,
wenn der passende Fusionspartner beziehungsweise alle Evolutionszutaten vorliegen.

## Haltung und Angriffe

Alle 18 Waffen haben einen Griffpunkt und einen eigenen Abschuss- beziehungsweise
Kontaktpunkt. Fernkampfgeschosse starten am Waffenkopf. Laufwaffen zielen aus einer
Halteposition neben Denti und spiegeln beim Seitenwechsel; die Amalgam-Schleuder
bleibt aufrecht. Ruhepositionen kreisen nicht automatisch um Denti.

`WeaponLayout` setzt gemeinsame Größenlimits (100 px Nahkampf, 76 px Fernkampf),
seitliche Haltepunkte und eine zusätzliche Verkleinerung bis 12 % bei sechs Waffen.
Die Limits gelten unabhängig von der Atlasauflösung; die individuellen Größen
liegen in den Waffenressourcen. Linke Nahkampfwaffen ruhen nach außen gespiegelt
und werden hinter Denti gezeichnet, damit sein Gesicht sichtbar bleibt.
Angriffsanimation und Kontaktprüfung verwenden dieselbe Skalierung. Kleine
Waffen erreichen weiterhin ihre volle Reichweite durch die Angriffsbewegung.

Jede Waffe bevorzugt den Gegner, der ihrem eigenen Haltepunkt am nächsten liegt,
innerhalb ihrer bisherigen Reichweite um Denti. Es gibt keine feste Reservierung
von Gegnern: mehrere Waffen können einen einzelnen Gegner gemeinsam fokussieren.
Beim ersten Kontakt beziehungsweise nach einer Angriffslücke werden die Starts
über bis zu 75 % eines Angriffsintervalls verteilt. Anschließend bleibt das
ursprüngliche Intervall erhalten. Spielstände bewahren laufende Cooldowns und
den Status dieses ersten Versatzes. Die Zielsuche bestimmt das nächste Ziel
in einem linearen Durchlauf statt alle Gegner nach Entfernung zu sortieren.

| Waffen | Bewegung |
| --- | --- |
| Zahnstocher-Speer | Ausholen, gerader Stich, Zurückziehen |
| Zahnsteinkratzer | Ausholen, Frontschwung, Rückkehr |
| Zahnseiden-Schneide | Feste Griffe, zwei Fäden fahren nach vorn aus und ziehen sich zurück |
| Zahnseidenpeitsche | Fester Griff, ein Faden fährt nach vorn aus und zieht sich zurück |
| Interdentalbürste | Rundumschwung |
| Turbo-Bohrer, Karies-Fräse | Vorstoß und vibrierender Arbeitskontakt; Fräskopf rotiert |
| Prophylaxe-Polierer | Kurzer Arbeitskontakt mit rotierendem Polierkopf |
| Zauberbürste, Wasserflosser, Kronenwerfer, Fluorid-Rakete | Zielen, Abschuss, Rückstoß |
| Mundspül-Mörser | Stärkerer Rückstoß beim schweren Schuss |
| Amalgam-Schleuder | Elastisches Spannen/Loslassen, Griff bleibt unten |
| Fluorid-Sprüher, Wasserturbine | Sprühbewegung und Frontfächer ab der Düse |
| Schmelzspiegel, UV-Lampe | Lichtstrahl ab Spiegel beziehungsweise Emitter |

Nahkampfschaden entsteht erst beim Kontakt während der aktiven Bewegung,
nicht beim Beginn des Ausholens. Geprüft wird die bewegte Strecke zwischen Griff
und Spitze gegen den Gegnerkörper, innerhalb der Waffenreichweite und des
Frontbogens. Jeder Gegner kann pro Angriff höchstens einmal getroffen werden;
Einzelzielwaffen behalten ihr ausgewähltes Ziel. Zeitlich abgetastete Bewegungen
verhindern ausgelassene Treffer bei schnellen Angriffen oder längeren Frames.
Spielstände erhalten Angriffsphase, Richtung, Schaden und bereits getroffene Gegner.

Eine [animierte Vorschau](screenshots/weapon_motion.gif) zeigt Stich, Schwung,
aufrechte Schleuder und Seitenwechsel. Das Werkzeug
`tools/preview_weapon_motion.gd` rendert die vier Beispiele in getrennten,
manuell fortgeschalteten Testwelten unter `.godot/weapon_motion_frames/`.
Mit `-- --loadouts` zeigt das Werkzeug sechs Speere gegen ein Ziel,
sechs Kratzer und Wasserflosser gegen mehrere Ziele sowie einen gemischten Build
unter `.godot/weapon_loadout_frames/`;
die [Loadout-Vorschau](screenshots/weapon_loadouts.gif) zeigt diese Anordnung.

## Individuelle Verzauberungen

Upgrade-Kapseln geben je zwei Waffenpunkte. Nach dem Loot-Sweep verteilst du sie
gezielt auf Effekte von 1/10 bis 10/10: ein Punkt je belegter Wurzel und Rang.
Mk I–IV öffnen einen bis vier Plätze. Pro Waffe ist ein Element wählbar; weitere
Plätze tragen Verstärkungen. Punkte bleiben über Wellen und Fortsetzen erhalten.
Ab Mk IV steht zusätzlich der gezielte Mk-V+-Aufstieg gegen Punkte und Gold bereit.

Bei einer Fusion entscheidet die Vorschau über übernommene Effekte; ungenutzte
Punkte werden erstattet. Bezahlte Mk-Stufen werden aus ihrem Punktebudget zu den
Wurzelkosten des Ergebnisses übernommen. Alte Effekte und offene alte Kapseln
bleiben kompatibel. [Verzauberungsregeln](WEAPON_UPGRADES.md) und
[Mk-Aufstieg](WEAPON_ASCENSION.md) beschreiben aktuelle Kosten und Grenzen.

Shopwaffen haben zusätzlich individuelle Rolls für Grundschaden (60–170 %),
Angriffspause (72–135 %), Reichweite (80–125 %) und Crit (+0–10 Prozentpunkte).
Schrott/Solide/Meisterwerk/Göttlich ist unabhängig von Mk. Jede Fusion übernimmt
je Attribut den besseren Wert beider Waffen: mehr Schaden, Reichweite und Crit,
aber die kürzere Angriffspause. Bei mehreren passenden Partnern zählt die höhere
erwartete Grund-DPS mit den aktuellen Buildwerten, bei Gleichstand die Reichweite.
Die Shopdetails zeigen das Ergebnis vor dem Kauf. Verzauberungen bleiben erhalten.

Waffenname und Rahmen zeigen immer Mk. Die Rollqualität färbt nur die einzelnen
Attribute; auch eine Mk-I-Waffe mit hervorragendem Schaden behält ihren Mk-I-Rahmen.
