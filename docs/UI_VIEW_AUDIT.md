# UI-Prüfung nach der neuen Run-Auswahl

Stand: **22.10.2026**. Bestandsaufnahme mit schrittweiser Umsetzung.
**Paket 1 ist umgesetzt:** gemeinsame Menübühne, Hauptmenü, Pause und
Einstellungen; [nativer Stand und Prüfung](MENU_UI.md).
**Paket 2 ist umgesetzt:** [Aufstiege, Relikte, Kapseln und Itemfunde](REWARD_UI.md).
Die folgenden Befunde dokumentieren den Ausgangsstand vor diesen Umbauten.
Run-Ende, Shop/Build und Leseseiten bleiben die weiteren Pakete.

## Entscheidung

Die neue Run-Auswahl wird die gestalterische Grundlage für Menüs und die Zeit
zwischen den Wellen: großzügige Bühne, dunkles Pflaumenviolett, cremefarbene
Schrift, gemalte Motive und gezielt eingesetztes Gold. Bilder, Abstände und
Typografie tragen die Hierarchie. Ein großer permanenter Dialograhmen ist dafür
nicht erforderlich.

Die wichtigsten Baustellen sind **mobile Größen, Hauptmenü/Pause, Belohnungen
und das Run-Ende**. Der Shop besitzt bereits eine brauchbare Aufteilung; seine
Karten und Detailansichten brauchen gezielten Feinschliff.

## Prüfgrundlage und Grenzen

- Geprüfter Ausgangsstand: `82563a5` auf `main`.
- 15 Ansichten/Zustände direkt in Godot gerendert: Hauptmenü, Einstellungen,
  Dentipedia, Credits, Shop, Shop mit Fusionsdetails, Pause, Stats, Items,
  Levelaufstieg, Relikte, Upgrade-Kapsel, Sieg, Storydialog und Kapitelreise.
- Jeweils 1280×720 und ein physisches 360×640-Fenster mit der mobilen
  Projektbasis 720×1280: **30 native Aufnahmen**. Das ist eine Fenstersimulation
  der mobilen Skalierung, kein Test auf einem echten Telefon.
- Kontrollierter Beispiel-Build: Welle 8, Level 11, 150 Münzen, fünf von sechs
  Wurzeln belegt, fusionierbare Waffen, sieben Items und ein Relikt. Für das
  Run-Ende wurden Beispieldaten einer siegreichen Runde verwendet.
- Save-, Einstellungs-, Fortschritts- und Berichtspfade des Aufnahmeprozesses
  wurden isoliert. Die Ansichten wurden gezielt geöffnet; das prüft Darstellung,
  nicht den vollständigen Spielablauf oder Balance.
- Zusätzlich wurden Layout, Zustandsdarstellung, Detailaufrufe und Datenquellen
  im aktuellen Code geprüft. Die älteren beige gestalteten Shop-Screenshots
  waren ausdrücklich keine Grundlage.
- Sechs repräsentative Ansichtspaare liegen unter
  [`screenshots/ui_audit/`](screenshots/ui_audit/). Die übrigen Aufnahmen sind
  temporäres Prüfmaterial unter `.godot/ui_audit/`.

| Native Belege | Desktop | Mobile Projektbasis im kleinen Fenster |
| --- | --- | --- |
| Hauptmenü | [1280×720](screenshots/ui_audit/home_1280x720.png) | [360×640](screenshots/ui_audit/home_360x640.png) |
| Einstellungen | [1280×720](screenshots/ui_audit/settings_1280x720.png) | [360×640](screenshots/ui_audit/settings_360x640.png) |
| Aufstieg | [1280×720](screenshots/ui_audit/levelup_1280x720.png) | [360×640](screenshots/ui_audit/levelup_360x640.png) |
| Kapsel | [1280×720](screenshots/ui_audit/capsule_1280x720.png) | [360×640](screenshots/ui_audit/capsule_360x640.png) |
| Shop | [1280×720](screenshots/ui_audit/shop_1280x720.png) | [360×640](screenshots/ui_audit/shop_360x640.png) |
| Run-Ende | [1280×720](screenshots/ui_audit/victory_1280x720.png) | [360×640](screenshots/ui_audit/victory_360x640.png) |

## Übergreifende Befunde

### Mobile Darstellung ist das dringendste Problem

Der gerenderte Canvas ist im 360×640-Fenster 720×1280 groß; Godot skaliert ihn
mit **0,5**. Viele ältere Menüs reagieren auf diese logische Canvasgröße, ohne
die Bildschirmgröße auszugleichen. Ein 48 Einheiten hoher Menübutton wird
dadurch 24 Bildschirm-Pixel hoch, eine Schriftgröße von 16 landet bei etwa 8.
Auch Breakpoints greifen teilweise zu spät: Ein 720 Einheiten breites Menü
behandelt das Telefon noch als relativ breite Ansicht.

Das Hauptmenü bleibt dabei ungefähr 240 Bildschirm-Pixel breit, obwohl 360
verfügbar sind. Shopkäufe und kleine Detailaktionen schrumpfen ebenfalls.
Diese Ansichten passen geometrisch ins Bild, sind aber schlecht lesbar und
schwer zu treffen. Reines Vergrößern einzelner Fonts löst das nicht.

Die neue Auswahl besitzt bereits einen lokalen Skalierungsausgleich und eine
darauf abgestimmte Schrift. Diese Grundlage sollte zu einer gemeinsam genutzten
Menübühne werden. Die Inhaltsanordnung richtet sich dann nach dem tatsächlich
verfügbaren Platz. Auf schmalen Geräten darf Inhalt bei guter Größe scrollen.

### Viele Flächen haben dieselbe Gewichtung

Der alte Stil zeichnet einen Außenrahmen, darin Gruppenflächen, Karten, Chips
und ähnlich gewichtete Buttons. Fast alles sieht dadurch nach einem eigenen
kleinen Dialog aus. Ein Rahmen sollte eine echte Auswahl, ein interaktives
Objekt oder eine Überlagerung kennzeichnen. Statische Gruppen lassen sich
meist über Abstand, Position und eine kurze Überschrift ordnen.

### Die Aktionssprache ist uneinheitlich

In älteren Ansichten kann Gold sowohl Fokus als auch Auswahl, Seltenheit,
Zurück oder eine Hauptaktion bedeuten. Die Kapsel färbt eine ausgewählte Waffe
vollständig gold; am Run-Ende sind Neustart und Endlos gleichzeitig gold.

Die neue Auswahl bietet die bessere Grundlage: Goldfläche für die Hauptaktion,
Goldkontur mit Markierung für Auswahl, cremefarbener Fokus. Seltenheit erhält
eine eigene, kleinere Kennzeichnung mit Text. Im Shop bleiben Preis und
Kaufbarkeit klar erkennbar, auch wenn nicht jeder Kaufbutton vollflächig gold
sein muss.

### Texte brauchen eine konkrete Aufgabe

Sätze wie „Wähle einen Bonus“ oder „Waffe wählen, dann verzaubern“ können durch
die Anordnung entfallen. Effekt, Nachteil, Preis, Ersatzentscheidung oder eine
Sperrbedingung müssen dagegen beim Entscheiden verständlich sein. Seltene
Mechaniken erhalten abrufbare Details. Storydialoge und Dentipedia sind
inhaltlich textorientiert und brauchen eine andere Lesefläche als eine Auswahl.

## Empfehlung pro Ansicht

| Ansicht | Befund | Geplante Verbesserung | Reihenfolge |
| --- | --- | --- | --- |
| Hauptmenü | Schmale, fast bildhohe Buttonbox; viele gleichwertige Einträge; zusätzlicher Untertitel neben dem bereits beschrifteten Logo. Mobil viel ungenutzter Rand und kleine Ziele. | Freie Bühne mit Logo und Denti. Fortsetzen mit knapper Run-Zeile als Hauptaktion, wenn ein Run existiert; sonst Neuer Run. Neuer Run und Story darunter; Einstellungen, Dentipedia und Credits als ruhige Navigation. Beenden separat. Codezugang bleibt bedingt sichtbar. | 1 |
| Pause | Derselbe hohe Buttonstapel; Stats und Items sind getrennte Untermenüs, obwohl beide denselben Build zeigen. | Kompakte Pausenbühne mit Fortsetzen und einer gemeinsamen Build-Ansicht. Klare Rückkehr zu genau dem pausierten Spielzustand. Einstellungen und Hauptmenü nachgeordnet. | 1 |
| Einstellungen | Rahmen um fast jede Zeile; Darstellung und Audio wirken zusammengewürfelt; viel freie Bildschirmfläche außerhalb des kleinen Dialogs. | Gemeinsamer Seitenkopf, offene Gruppen für Audio, Darstellung und Bedienung. Regler mit direkt zugeordnetem Wert; echte Schalter statt breiter Aktionsbuttons. Desktop zweispaltig, mobil eine Spalte. Änderungen wirken weiter sofort; Zurück ist Navigation. | 1 |
| Levelaufstieg | Außenbox, kleine Denti-Figur, Titel, Bedienungssatz und vier komplett eingefärbte Rahmenkarten. Statname erscheint im Titel und Effekt erneut. Mobil verschwinden die Werte optisch in großen Karten. | Gemeinsame Belohnungsbühne mit kleinem Fortschritt der noch offenen Auswahl. Gemaltes Icon, Statname einmal und großer Bonuswert. Seltenheit als kompakter Akzent mit Bezeichnung. Vier Karten am Desktop, kompakte lesbare Zeilen auf schmalen Geräten. Münzen und Reroll bleiben zusammen. | 2 |
| Reliktwahl | Andere Dialoghöhe und anderer Introtext, obwohl es dieselbe Entscheidungssituation wie beim Aufstieg ist. | Dieselbe Belohnungsbühne. Drei Relikte mit größerer eigener Kunst und jeweils einem klaren Kerneffekt. Ausführliche Regeln bei Bedarf. Die Seltenheit und dauerhafte Wirkung im Run bleiben erkennbar. | 2 |
| Upgrade-Kapsel | Mehrere Textzeilen zur Bedienung und zum Ziel, volle Goldfläche für Waffenwahl, winzige Effektdaten; ständig sichtbarer Scrollbalken selbst ohne Überlauf. | Oben kompakte Waffenwahl wie im neuen Waffenraster, darunter genau eine aktive Waffenvorschau mit belegten Effektplätzen. Anschließend drei Effektangebote. Wirkung und Änderung am gewählten Ziel sichtbar. Ersetzen nur bei vollen Plätzen einblenden; bestehender und neuer Effekt direkt vergleichbar. Zerlegen als ruhige Münzaktion. | 2 |
| Item behalten/zerlegen | Bestehender separater Darstellungsmodus der allgemeinen Auswahl, gleicher Kapseltitel wie bei Waffenverzauberungen. | In dieselbe Belohnungsbühne einordnen, Inhaltstitel passend zum tatsächlich erhaltenen Gegenstand. Ein Item mit Wirkung/Nachteil, Behalten und Zerlegen eindeutig. Kein zusätzlicher Einführungstext. | 2 |
| Shop | Gute grundlegende Aufteilung. Große Farbrahmen und lange vertikale Karten erzeugen trotzdem viel visuelles Gewicht; zwölf Stats links sind dauernd gleich prominent. Vier goldene Kaufaktionen konkurrieren mit der nächsten Welle. | Offene Werkbank erhalten: Angebote im Mittelpunkt, kompakter Build daneben, Münzen/Reroll im Kopf. Kürzere Karten mit größerem Motiv, Preis und Kerneffekt; Seltenheit kleiner kennzeichnen. Wertevergleich am ausgewählten Angebot, volle Stats abrufbar. Pin, Kaufbarkeit und nächster Wellenstart räumlich klar trennen. | 3 |
| Shopdetails/Fusion/Verkauf | Weitere Box über bereits eingerahmter Bühne; darin viele kleine Begriffsbuttons und Aktionsrahmen. Mobil besonders kleine Werte. | Gemeinsame Objekt-Detailfläche. Desktop verankerte Seitenfläche, mobil ausreichend große Detailseite mit Zurück. Vorher/Nachher-Werte und freigegebene Wurzeln sichtbar; Fusion und Verkauf nebeneinander unterscheidbar. Bestehende Bestätigungen für zerstörende Aktionen erhalten. | 3 |
| Stats, Waffen, Items und Relikte | Mehrere getrennte Seiten mit schmalem Dialog und großem Zurück-Button; dieselben Daten tauchen auch im Shop auf. | Gemeinsame Build-Ansicht mit Bereichen „Werte“, „Waffen“ und „Items & Relikte“. Oben Leben, Level und Wurzeln; darunter großzügiges Raster und Details des gewählten Objekts. Direkter Zugang aus Pause und Shop mit erhaltener Auswahl. | 3 |
| Run-Ende | Zentrierter Textblock vermischt Ergebnis, Wirtschaft und Schadensanalyse. Credits erhalten denselben Platz wie Spielaktionen. Bei Sieg zwei goldene Aktionen. | Große Ergebniszahl bzw. Welle und Schwierigkeit; wenige gut lesbare Kerndaten und Build-Bilder. Schadensaufteilung, Wirtschaft und Synergien unter „Details“. Bei regulärem Sieg Endlos als Hauptaktion, bei Niederlage Neuer Run. Hauptmenü und Neustart nachgeordnet. Hell-Freischaltung als eigener kurzer Moment. | 2, nach den Belohnungen |
| Dentipedia | Nützliche Suche und Kategorien vorhanden. Eintragsliste aus vielen Buttonboxen; Waffenwerte als lange Textzeilen; Wurzelzahl doppelt. Mobil zwei übereinander liegende Scrollbereiche bei kleiner Schrift. | Desktop offene Liste und Lesefläche. Waffenwerte als Mk-I–IV-Vergleichstabelle, Eigenschaften einmal. Mobil erst Liste, dann eigener Eintrag mit Rückkehr zu Suchzustand und Listenposition. Geheime Rezepte bleiben verborgen. | 4 |
| Storydialog | Bereits brauchbare kompakte Lesefläche. Durch generischen Dialogstil wirken Figur und Sprache klein. | Größeres Sprecherporträt, ruhigere Sprechfläche und passende Satzbreite. Kapitel, Sprecher, Text und Weiter reichen. Gemeinsame Typografie und Fokuszustände übernehmen; Textaufbau und Weiterverhalten bleiben. | 4 |
| Kapitelreise | Gemalte Kapitelkarten und Route tragen bereits gut; näher an der neuen Auswahl als die meisten Menüs. | Bestehende Kunst und Enthüllung behalten. Abstände, Schriftgrößen, gewählte Karte und Weiter anpassen. Auf Mobil tatsächliche Größen prüfen; keine zusätzliche Erklärung oder neue Kartenhierarchie nötig. | 4 |
| Credits / Bestätigung / Attributinfo | Diese Ansichten haben bewusst wenig Inhalt bzw. echte erklärende Aufgaben. | Credits als ruhige lesbare Seite, Bestätigungen und abrufbare Infos als kompakte Überlagerung mit einer klaren Aktionshierarchie. Bei Run-Ersetzung oder Verkauf muss die Konsequenz lesbar bleiben. | Mit jeweiligem aufrufendem Bereich |

## Die ersten drei konkreten Layouts

### Hauptmenü und Pause

Desktop: ein gemeinsamer Inhaltbereich bis etwa 1400 Bildschirm-Pixel, mit
visuell ausbalanciertem Logo/Aktionsbereich und Denti auf der anderen Seite.
Keine Umrandung um die gesamte Komposition. Die Aktionsgruppe selbst bleibt
kompakt; freie Fläche bedeutet nicht, alle Buttons breit zu ziehen.

Mobil: Logo, Aktionen und Figur werden bewusst angeordnet; Ziele mindestens
48×48 Bildschirm-Pixel. Die Figur gibt bei wenig Höhe Platz für die Bedienung
frei. Nur erreichbare Fortsetzung anbieten; kein dauerhaft dominanter
deaktivierter Fortsetzen-Button ohne Run.

Pause nutzt dieselben Materialien und Aktionsrollen, darf aber als tatsächliche
Überlagerung kompakter bleiben. Der abgedunkelte Spielstand macht den Kontext
deutlich. Fortsetzen bleibt jederzeit ohne Umweg erreichbar.

### Belohnungen

Ein wiederkehrender Kopf zeigt die aktuelle Belohnung und einen kleinen
Queue-Fortschritt, beispielsweise „Aufstieg · 1/3“. Keine Liste aller kommenden
Entscheidungen und kein Erläuterungsabsatz. Der Hauptbereich wechselt zwischen
Statkarten, Relikten und Kapselinhalt, Kopf und Aktionspositionen bleiben stabil.

Statkarten: gemaltes Icon, „Bisskraft“, großer Wert „+4 %“, kleine Seltenheit.
Ein Kartenklick übernimmt die Wahl wie bisher direkt; keine neue
Bestätigungsrunde. Reroll mit Preis unten rechts, Münzen in derselben Zeile.
Auf Mobil lieber eine gut lesbare Zeile je Option als eine große Karte mit
herunterskalierter Schrift. Die längeren Relikt- und Verzauberungseffekte dürfen
mehr Raum erhalten.

Die Kapsel zeigt eine aktive Zielwaffe und ihre Plätze zusammen. Ein
Waffenwechsel aktualisiert die drei Angebote. Bei einer Ersatzentscheidung
erscheint der betroffene alte Effekt unmittelbar am neuen Angebot. Der letzte
Klick muss eindeutig verzaubern, verbessern oder ersetzen; die Folge darf
nicht erst aus einer allgemeinen Anleitung hervorgehen.

### Shop und Build

Desktop: Kopf mit Welle, Münzen und Reroll; darunter ein kompakter Build-Bereich
und vier gleichrangige Angebote. Unten gesammelte Items sowie der Start der
nächsten Welle. Diese vorhandene Grundstruktur ist brauchbar.

Eine Karte zeigt Motiv, Name, Mk-Stufe bzw. Seltenheit, entscheidende Werte,
Kerneffekt und Preis. Waffenbild und Karteninhalt werden wie in der neuen
Auswahl unabhängig von Pin oder Zustandsmarkierungen zentriert. Negative
Effekte und Kosten verschwinden nicht hinter Details. Zusatzregeln und
ausführliche Vergleiche öffnen die Detailfläche.

Mobil: Angebote kommen früh in die Inhaltsreihenfolge; ein kompakter
Build-Zugang ersetzt die permanente Wand aus zwölf winzigen Stats. Je nach
realer Breite sind zwei kompakte Karten oder eine breite Karte sinnvoll.
Wenn Werte und Ziele nicht passen, wird auf eine Spalte umgebrochen, nicht
weiter verkleinert. Ein Haupt-Scrollbereich und ein klarer Abschluss zur
nächsten Welle; die Detailseite erhält ihren eigenen Rückweg.

## Gemeinsame technische Grundlage

1. Den lokalen Größenausgleich, die sichere Bühne und die skalierbare Schrift
   der Run-Auswahl zu gemeinsamen Menübausteinen machen. Layout-Breakpoints
   anhand der nutzbaren Bildschirmfläche entscheiden. Keine globale Änderung
   der Kampfskalierung.
2. Explizite Gestaltungsrollen: offene Bühne, Auswahlkarte, leise Aktion,
   Hauptaktion, Status/Seltenheit und echtes Detail-/Bestätigungsfenster.
   `DentiUIStyle.style_dialog()` nicht pauschal rahmenlos machen; seine
   Aufrufer haben unterschiedliche Aufgaben.
3. Wiederverwendbare Objektpräsentation für Bild, Namen, Mk-Stufe,
   Wurzelkosten und Werte in Auswahl, Build, Shop und Dentipedia.
   Sichtbaren Bildinhalt berücksichtigen, Seitenverhältnis erhalten und
   Zustandsmarkierungen unabhängig platzieren. Originalassets bleiben erhalten.
4. `ChoicePanel` entlasten: Belohnungsbühne und Ergebnisansicht trennen;
   konkrete Inhalte bleiben eigene Komponenten. `GameMenu` auf Navigation
   begrenzen, umfangreiche Build- und Einstellungsseiten auslagern.
5. Die vorhandenen Datenmodelle und Signale weiterverwenden. Shopkauf,
   Fusionsregeln, Belohnungsqueue und Speicherung erhalten ihre bestehende
   Autorität. Eine gestalterische Vereinheitlichung rechtfertigt keine zweite
   Spielablaufsteuerung in der UI.

## Umsetzung in überprüfbaren Schritten

1. **Gemeinsame Bühne + Hauptmenü, Pause und Einstellungen.** Hier zuerst die
   mobilen Größen und Aktionsrollen lösen. Das liefert die Grundlage für die
   übrigen Ansichten und macht den Wechsel in die neue Run-Auswahl stimmig.
2. **Belohnungsbühne.** Zuerst Aufstieg, dann Relikte, Kapsel und
   Behalten/Zerlegen. Danach das Run-Ende als eigene Ergebnisansicht.
3. **Shop und gemeinsame Build-Ansicht.** Vorhandene Angebotsaufteilung
   beibehalten, Karten/Details/Statzugang neu gewichten. Kauf-, Pin-, Fusions-
   und Verkaufszustände gemeinsam prüfen.
4. **Dentipedia, Story und Nebenansichten.** Lesefluss und Navigation
   angleichen, vorhandene Kapitelkunst erhalten.

Jeder Schritt wird erst nativ geprüft und funktional abgeschlossen, bevor der
nächste Bereich umgebaut wird. Zusätzliche Art ist für diese Grundlage nicht
nötig; die vorhandenen gemalten Motive und Icons tragen die Gestaltung.

## Abnahme für die spätere Umsetzung

- Echte Fenster in 320×568, 360×640, 568×320, 1280×720 und 1920×1080 prüfen;
  dazu 720×1280 als höher aufgelöste Hochkantansicht. Bilder in tatsächlicher
  Größe ansehen, nicht nur auf geometrischen Überlauf testen.
- Wesentliche Texte etwa 16–18 Bildschirm-Pixel, sekundäre Angaben mindestens
  12–14; Touchaktionen mindestens 48×48. Schrift und Motive bleiben scharf.
- Auswahl, Tastaturfokus, Seltenheit, Sperre, Hover und Hauptaktion sind
  unterscheidbar. Goldene Seltenheit ist keine ausgewählte Karte.
- Waffen mit unterschiedlich großen transparenten Rändern, lange Namen,
  volle Wurzeln, hohe Stapelzahlen und knappe Münzen prüfen.
- Shopzustände: kaufbar, zu teuer, Wurzeln belegt, Stapellimit, reserviert,
  Fusion möglich, Verkauf, Evolution und Vergleich.
- Belohnungen: mehrere Aufstiege, Reroll, volle Effektplätze, identischer Effekt
  als Verbesserung, Ersatz, Zerlegen und Fortsetzen nach Speichern. Loot wird
  weiter vor der Belohnungsqueue eingesammelt; aktiver Kampf bleibt ungestört.
- Ergebnis: Sieg mit Endlosangebot, Niederlage, beendeter Endlosrun und
  Hell-Freischaltung. Details sind auch mobil zugänglich.
- Zurück/Escape, erhaltene Auswahl/Scrollposition, schnelle Eingaben und
  reduzierte Bewegung prüfen. Keine neuen Erklärungstexte ohne konkrete
  Entscheidungsfunktion.

## Beibehalten

Das Zahngefäß für Leben und Ausdauer, Schildkonturen, Bossleisten und die
XP-Darstellung haben eine eigene Aufgabe im Kampf. Die Übertragung betrifft
Menüs und Entscheidungsansichten; deren bessere Typografie, Skalierung und
Zustandslogik lassen sich gezielt gemeinsam nutzen. Die gemalten Zahn- und
Goldornamente des Kampf-HUDs bleiben dabei eine passende visuelle Verbindung.
