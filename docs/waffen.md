# Dentis Waffen

Denti beginnt ohne fest ins Charakterbild eingebaute Waffe. Vor Welle 1 wählt man Zauberbürste, Turbo-Bohrer oder Wasserflosser. Die übrigen Waffen sowie weitere Exemplare gibt es im Shop.

Bisskraft verstärkt alle Waffen prozentual. Nah- oder Fernschaden ergänzt ihren Basisschaden mit einem individuellen Gewicht; die Waffenkarte zeigt den passenden Stat und seine Skalierung. Schnelle Flächenwaffen erhalten kleinere Gewichte als schwere Einzelangriffe. Fusion erhöht die Waffenbasis, ohne die rohen Stat-Beiträge zusätzlich zu vervielfachen. Die vollständigen Faktoren und Messungen stehen im [Schadens- und Verteidigungsbericht](DAMAGE_DEFENSE_BALANCE.md).

| Waffe | Hände | Angriff | Rolle |
| --- | ---: | --- | --- |
| Zauberbürste | 2 | Schmelz-Projektil | Verlässliche Reichweite; ab Stufe III zwei, ab IV drei Pastegeschosse mit leichtem Streuwinkel. |
| Turbo-Bohrer | 1 | Bohrung im Nahkampf | Kompakte, schnelle Bohrstöße; Bossbonus wächst von 25 % auf 40 %. |
| Zahnseidenpeitsche | 1 | Rundumschnitt | Trifft alle nahen Gegner und verursacht Blutung; der Radius wächst mit der Stufe. |
| Wasserflosser | 1 | Schnelles Wasserprojektil | Macht Ziele nass, hat niedrigen Rohschaden und wachsenden Rückstoß. |
| Kronenwerfer | 2 | Schweres Metallprojektil | Durchdringt auf Stufe I einen weiteren Gegner, auf Stufe IV drei. |
| Schmelzspiegel | 1 | Sofortiger Lichtstrahl | Präziser Treffer ohne Flugzeit. |
| Zahnsteinkratzer | 1 | Schneller Nahkampfschnitt | Sehr kurze Reichweite und hoher Angriffstakt bauen kleine Blutungen schnell auf. |
| Mundspülungs-Mörser | 2 | Minzprojektil | Flächenschaden beim Einschlag; Explosionsradius wächst mit der Stufe. |
| Zahnstocher-Speer | 1 | Stichlinie / Schnitt | Lange, schmale Nahkampflinie trifft mehrere hintereinander stehende Gegner. |
| Karies-Fräse | 2 | Schneller Bohrungs-Nahkampf | Kurze Reichweite; Fokus wächst um 5 % pro Folgetreffer bis +50 %. Nur 55 % Schaden gegen normale Gegner, +40 % gegen Eliten, +35–50 % gegen Bosse. |
| Interdental-Bürste | 1 | Winziger Rundumschnitt | Sehr schnelle Treffer mit 1,2 Blutungsschaden/s für 2,5 s; Radius wächst mit der Stufe. |
| Fluorid-Sprüher | 2 | 65°-Minzkegel | Markiert Gegner für 2 s: +20 % Schaden durch Schmelzwaffen, etwa Zauberbürste und Fluorid-Rakete. Mehrere Sprüher stapeln den Bonus nicht. |
| Mundduschen-Turbine | 2 | 48°-Wasserkegel | Macht Gruppen 3 s nass und stößt sie kräftig zurück; geringer Rohschaden. |
| UV-Lampe | 2 | Breite Lichtlinie | Sofortstrahl trifft alle Gegner entlang einer 36 Pixel breiten Linie; +10 Prozentpunkte Waffen-Crit und ×2 Crit-Schaden. |
| Amalgam-Schleuder | 1 | Schweres Metallprojektil | Langsame Kugel, kleiner Splash und hoher Rückstoß, auch bei Explosionen. |
| Zahnseiden-Garotte | 2 | 150°-Frontschnitt | Langsamer schwerer Hieb mit 3,2 Blutungsschaden/s für 3,5 s; kein Treffer hinter Denti. |
| Prophylaxe-Polierer | 1 | Schneller Licht-Nahkampf | +10 Prozentpunkte Waffen-Crit; jeder dritte fortlaufende Treffer auf dasselbe Ziel ist garantiert kritisch. |
| Fluorid-Rakete | 2 | Schmelz-Rakete | Hoher Flächenschaden, große Explosion und lange Pause; explodiert auch am Reichweitenende. |

Die Waffen haben eigene Sprites unter `assets/weapons/` und werden getrennt von Dentis Körper geschwenkt beziehungsweise beim Schuss zurückgestoßen. Die zehn neuen Waffen verwenden zugeschnittene Regionen des transparenten `weapon_icons_expansion.png`-Atlas; derselbe Ausschnitt dient als Shopbild. Projektilfarbe, Tempo, Reichweite und Trefferform liegen in den jeweiligen `WeaponData`-Ressourcen unter `data/weapons/`.

Eine [Vergleichsansicht mit Denti und allen 18 Waffen](WEAPON_SIZE_BALANCE.md) zeigt Ruhehaltung und Angriff bei gleicher Vergrößerung. Der Bohrer ist auf Stufe I 60 Pixel groß, trifft für 22 Basisschaden alle 0,72 Sekunden und skaliert mit 100 % Nahschaden. Kratzer, Peitsche, Garotte und Speer wurden ebenfalls in ihren Proportionen angepasst; Reichweiten bleiben erhalten.

Die [optische Prüfung aller Waffen](WEAPON_ART_REVIEW.md) bewertet Perspektive, Werkzeugform, Haltung und Animation und nennt konkrete Prioritäten für die nächste Überarbeitung.

Die [anschließende Überarbeitung](WEAPON_ART_REFINEMENT.md) zeigt acht neue Waffengrafiken, separate rotierende Arbeitsköpfe und die bewegte Schleuder mit Bildern aus dem Spiel.

## Grundwerte der Erweiterung

Werte für Stufe I vor Spielerwerten, Items und kritischen Treffern. Schaden ist
pro Treffer und Ziel, nicht der Gesamtschaden eines Kegels oder einer Explosion.

| Waffe | Schaden | Pause | Reichweite | Preis |
| --- | ---: | ---: | ---: | ---: |
| Zahnstocher-Speer | 22 | 0,95 s | 205 | 10 |
| Karies-Fräse | 8 | 0,20 s | 78 | 15 |
| Interdental-Bürste | 4 | 0,24 s | 62 | 8 |
| Fluorid-Sprüher | 5 | 0,25 s | 155 | 14 |
| Mundduschen-Turbine | 4 | 0,40 s | 195 | 14 |
| UV-Lampe | 34 | 1,65 s | 600 | 17 |
| Amalgam-Schleuder | 24 | 1,30 s | 370 | 10 |
| Zahnseiden-Garotte | 30 | 1,45 s | 145 | 15 |
| Prophylaxe-Polierer | 7 | 0,32 s | 85 | 10 |
| Fluorid-Rakete | 58 | 2,60 s | 550 | 18 |

Alle zehn Waffen sind im normalen Shop erhältlich und unterstützen vier Stufen,
Fusion, Verkauf und Fortsetzen. Die drei Startwaffen bleiben wie bisher.
Die Erweiterung nutzt individuelle Schadenskurven; Speer, Bürste, Sprüher,
Turbine, UV-Lampe und Garotte gewinnen Reichweite. Schleuder und Rakete
gewinnen Explosionsradius, Turbine Rückstoß, Fräse Bossbonus.

Blutung, Nass, Licht-Crits und Projektiltreffer verwenden dieselben Item- und
Reliktsignale wie die bisherigen Waffen. Ziel-Fokus und Politur beginnen beim
Zielwechsel oder einer Angriffslücke neu. Spielstände erhalten ihren Zielbezug,
Zähler und Cooldown sowie aktive Fluorid-Markierungen. Angezeigte DPS schätzen
ein normales Einzelziel inklusive Waffen-Crit; Flächentreffer, Blutung,
voller Fokus und situative Itemeffekte sind zusätzliche Leistung.

Die Ausrüstung fasst sechs Hand-Plätze. Einhandwaffen belegen einen, Zweihandwaffen zwei. Solange genug Plätze frei sind, fügt ein Kauf die Waffe einzeln hinzu. Ist die Ausrüstung voll, verschmilzt eine gekaufte Waffe mit einem gleichen Exemplar derselben Stufe (bis IV). Zwei bereits ausgerüstete gleiche Waffen derselben Stufe lassen sich per Rechtsklick auf eine der Waffen verschmelzen. Verkauf benötigt zwei Linksklicks und erstattet die Hälfte des Kaufwerts aller in dieser Waffe aufgegangenen Exemplare. Jede Stufe erhöht Schaden und Angriffstempo. Der Spielstand speichert Waffentypen, Stufen und investierte Münzen.

Bohrung verursacht je nach Stufe 25–40 % mehr Schaden gegen Bosse. Schnitt verursacht 15 % mehr Schaden gegen nahezu unverletzte Gegner und baut Blutung auf. Wasserflosser-Treffer machen Gegner nass. Die anderen Schadensarten unterscheiden sich über Reichweite, Projektiltempo, Durchschlag, Rückstoß, Strahl oder Flächentreffer. Gegner haben derzeit keine elementaren Resistenzen. Die Waffen haben individuelle Schadensmultiplikatoren und ausgewählte Eigenschaften, die mit ihrer Stufe wachsen.

## Haltung und Angriffe

Alle 18 Waffen haben einen Griffpunkt und einen eigenen Abschuss- beziehungsweise
Kontaktpunkt. Fernkampfgeschosse starten am Waffenkopf. Laufwaffen zielen aus einer
Handposition neben Denti und spiegeln beim Seitenwechsel; die Amalgam-Schleuder
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
| Zahnsteinkratzer, Zahnseiden-Garotte | Ausholen, Frontschwung, Rückkehr |
| Zahnseidenpeitsche, Interdentalbürste | Rundumschwung |
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
