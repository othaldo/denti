# Denti: UI- und UX-Plan

Stand: 22.10.2026. **Run-Vorbereitung in Godot umgesetzt.**
Die Browserstudie wurde vom Nutzer als Richtung bestätigt. Native Aufnahmen und
Ablaufprüfung stehen unter [Startauswahl](STARTER_SELECTION.md); die persönliche
visuelle Rückmeldung zum spielbaren Ergebnis bleibt ein eigener Schritt.
Gilt als Gestaltungsgrundlage über die Run-Vorbereitung hinaus. Die erste
Umsetzung bleibt auf Schwierigkeit und Startwaffe begrenzt.

## Verbindliche Nutzeranforderung

Die Oberfläche braucht nicht für jede Bedienung eine Erklärung. Keine
Anleitungssätze auf jeder Seite, keine doppelt beschrifteten Informationen,
keine Absatzsammlungen in der Standardansicht. Anordnung, Bilder und sichtbare
Zustände übernehmen die Führung. Zusätzliche Erklärungen sind gezielt abrufbar.

Seltenheit muss ohne Lesen des Wortes erkennbar bleiben: sichtbare Farbkante
und leicht getönte Fläche am Objekt, mit eigener Markierung für Auswahl und
Fokus. Bereits farbige Karten bekommen keinen zweiten Seltenheitskasten im
Inneren. [Bestandsaufnahme und aktuelle native Ansichten](RARITY_UI.md).

Ein UX-Plan darf ausführlich sein; diese Ausführlichkeit wandert nicht als
Text in die Spieloberfläche.

## 1. Befund am aktuellen Stand

| Befund | Ursache im aktuellen Aufbau | Konsequenz |
| --- | --- | --- |
| Kleiner Dialog in einer großen leeren Fläche | Schwierigkeit begrenzt die Breite in `GameMenu._update_build_layout()` auf 520 logische Pixel | Desktop-Fläche ist unabhängig vom verfügbaren Raum beschnitten |
| Immer dieselbe kompakte Anordnung | `difficulty_grid.columns = 2`, auch im breiten Format | Vier Optionen wirken wie Formularfelder statt einer Spielauswahl |
| Kaum erkennbare Denti-Identität | Hintergrund und Standardbuttons tragen fast die gesamte Ansicht | Die vorhandene gemalte Bildsprache wird nicht genutzt |
| Auswahl und Aktion konkurrieren | Ausgewählte Schwierigkeit und Weiter haben beide eine große vollgoldene Fläche | Zwei unterschiedliche Zustände erhalten dieselbe optische Betonung |
| Überschrift und Fortschritt wiederholen einander | „1. Schwierigkeit“ plus „1 Schwierigkeit › 2 Waffe“ | Unnötige Beschriftung ohne zusätzlichen Nutzen |
| Waffendetails werden zur Textsammlung | Name, Rolle, Grundwerte, Ressourcenbeschreibung und `combat_text()` werden zusammen angezeigt | Wurzelkosten und Mechaniken wiederholen sich; einfache Entscheidungen werden schwerer lesbar |
| Kleine Formate brauchen mehrere Scrollbereiche | Raster und vollständige Beschreibungen erhalten jeweils einen Scrollcontainer | Häufiges Scrollen zwischen Waffe, Werten und Navigation |
| Bestehende Tests melden Erfolg | Sie prüfen vor allem Zustand, Ablauf und äußere Grenzen | „Passt hinein“ wurde fälschlich als ausreichende gestalterische Abnahme behandelt |

Die Funktionsarbeit bleibt wertvoll: Vorbereitung im Menü, Entwurf speichern,
Vor/Zurück, einmaliger Start und alte Spielstände sind vorhanden. Überarbeitet
werden deren Präsentation und Bedienungsqualität.

## 2. Gestaltungsrichtung: eine Auswahlbühne für Denti

Empfohlen wird eine zusammenhängende, großzügige Run-Vorbereitung mit einer
gemeinsamen Kopf- und Fußzeile. Das zentrale Motiv beziehungsweise die Auswahl
erhält die Fläche. Die bisherige dunkle Nachtklinik bleibt die Grundlage.

- Pflaumenhintergrund, Elfenbeinschrift, warmes Gold, gemalte Dentalmotive.
- Gold als volle Fläche für die Hauptaktion. Eine Auswahl erhält Goldkontur
  und ein kleines eindeutiges Auswahlzeichen; ihr Motiv bleibt farbig.
- Fokus bekommt eine eigene helle Kontur, nur bei Tastatur-/Controllerbedienung.
  Ein fokussiertes erstes Icon sieht nicht wie eine bereits gewählte Waffe aus.
- Gemeinsame Fluchten, Abstände und Bildhöhen in allen Vorbereitungsschritten.
  Die äußere Bühne springt beim Wechsel nicht zwischen kleinen und großen Dialogen.
- Freiraum trennt Gruppen und gibt dem Bild Gewicht. Karten werden nicht bloß
  zu leeren höheren Säulen vergrößert.
- Bilder behalten ihr Seitenverhältnis. Optische Größe wird am sichtbaren Motiv
  beurteilt, nicht nur am transparenten Bildrechteck. Ornamente werden modular
  aufgebaut; erweiterbare Rahmenteile werden gekachelt, Endstücke proportional gehalten.

Hauptmenü und Vorbereitung teilen Hintergrund, Typografie und Materialwirkung.
Das vorbereitete Spiel lädt weiterhin erst nach der endgültigen Startaktion.
Shop und HUD werden in dieser ersten Ausbaustufe nicht pauschal neu gestaltet.

## 3. Gemeinsamer Aufbau und Flächennutzung

Alle Maße sind **logische UI-Pixel**, keine ungeprüften Monitorpixel.
Godots bestehendes Canvas-Stretching wird berücksichtigt; die globale Skalierung
von Kampf und Kamera wird für diese Menüarbeit nicht verändert.

### Breites Format

Startpunkt bei 1280×720: ungefähr 56 Pixel Seitenabstand, eine Inhaltsbreite von
1168 Pixeln, eine kompakte Kopfzeile und eine feste Navigationszeile unten.
Die Auswahl nimmt die große mittlere Fläche ein. Diese Proportion wird bei
normaler Skalierung auf größeren Monitoren erhalten.

Bei tatsächlich größeren **logischen** Ansichten darf die Bühne bis etwa 1600
Pixel Breite wachsen. Danach wachsen Außenabstände statt Schrift und Karten
unbegrenzt weiter. Bei Ultrawide bleibt die zusammengehörige Auswahl zusammen.

Kopfzeile: kleines Denti-Branding und ein einziger Schrittverlauf.
Der aktive Schritt ist sichtbar markiert. Es gibt keine zweite große
Überschrift mit demselben Inhalt.

Fußzeile: Zurück links, die Hauptaktion rechts. Ein zurückhaltender Zugang zu
Details ist vorhanden. Keine zusätzliche dauerhaft sichtbare Erklärung oder
Zusammenfassung derselben Auswahl unter den Karten.

### Mittlere und schmale Formate

Die Entscheidung folgt verfügbarem Inhalt und Seitenverhältnis, nicht allein
einem pauschalen Mobile-Flag.

| Format | Schwierigkeit | Waffen |
| --- | --- | --- |
| Breites Desktopformat | Vier gleichwertige Motive nebeneinander | Alle 18 Icons in 6×3, daneben die große Auswahlvorschau |
| Mittlere Breite | Vier nebeneinander, solange Bild und Titel gut lesbar bleiben; sonst 2×2 | Raster und Vorschau nebeneinander, solange beide ihre Mindestbreite behalten |
| Hochformat | Vier kompaktere Karten in 2×2 | Raster oben, kompakte Bild-/Wertezeile darunter, Navigation unten |
| Kurzes Querformat | Vier flachere Auswahlkarten oder 2×2 nach gemessener Höhe | Raster neben kompakter Vorschau, Hauptaktion bleibt sichtbar |

Mindest-Touchflächen: 48×48. Kleine Icons werden nicht durch winzige Treffflächen
erkauft. Ein 320-Pixel-Format kann beispielsweise fünf 52-Pixel-Waffenspalten
mit passenden Abständen tragen; die endgültige Zeilenzahl wird aus Breite und
verfügbarem Platz berechnet, nicht als feste Desktop-Spaltenzahl übernommen.

Bei Platzmangel wird zuerst umgeordnet, anschließend dekorative Bildhöhe
reduziert. Falls Scrollen nötig bleibt, scrollt die Auswahl. Ausgewählte Waffe,
Kernwerte und Navigation behalten ihre erreichbaren Positionen. Zwei gleichzeitig
notwendige Scrollfenster für die normale Auswahl sind kein Zielzustand.

## 4. Schwierigkeit: vier erkennbare Entscheidungen

Jede Karte enthält im Normalzustand ein großes gemaltes Motiv und genau den
Schwierigkeitsnamen: Easy, Normal, Hard, Hell. Die gesamte Karte ist die Auswahlfläche.

Die Motive bilden eine gemeinsame Familie mit zunehmend bedrohlicher Wirkung.
Sie sollen denselben Denti-Kosmos zeigen und nicht die vier Bosse oder vier
zukünftige Klassen suggerieren. Die Entwurfsskizze verwendet vorhandene Sprites,
um den Flächenbedarf zu zeigen. Diese Spritegruppen sind keine neue
Gameplay-Regel und keine fertige Schwierigkeitsgrafik.

Für die finale Fassung wird ein zusammenpassender Satz gemalter Motive erzeugt:
gleiche Perspektive, gleiche Grundgröße und Silhouettenführung, zunehmender
Karies-/Gefahrendruck. Zuerst alle vier gemeinsam in Zielgröße beurteilen.
Keine unterschiedlichen Stilrichtungen pro Schwierigkeit und keine überladenen
Ornamente, die klein zu Pixelmatsch werden.

### Sichtbare Zustände

- Normal ist beim ersten neuen Run vorausgewählt. Ein vorhandener Entwurf behält seine Wahl.
- Auswahl: Goldkontur und Auswahlzeichen. Hover und Fokus ändern keine Wahl.
- Klick oder Antippen wählt. Der Schritt wechselt erst durch Weiter.
- Gesperrtes Hell: Motiv gedämpft, Schloss, kurze Bedingung „Sieg auf Hard“.
  Antippen zeigt die Freischaltbedingung. Die bisherige gültige Wahl bleibt erhalten.
- Keine zusätzliche Empfehlungsplakette, Sternwertung oder erfundene Prozent-Gesamtnote.

### Informationen auf Anfrage

Details zur gewählten Schwierigkeit öffnen einen kompakten Bereich oder eine
kleine Ansicht. Die Inhalte kommen aus den echten Difficulty-Ressourcen.
Erst dort stehen Gegnerdruck, Bosseskalation und frühe Statuseffekte, bei Bedarf
genauer aufklappbar. Die Grundauswahl erhält keine vier Erklärungstexte.

Die Unterschiede umfassen tatsächlich Dichte/Horden, Eliten, Projektil- und
Bossdruck, Statusbeginn und auf Hard/Hell stärkere Gegnerkurven. Aussagen wie
„nur mehr HP“ wären falsch. Eine höhere Beutechance auf höheren Stufen wird
nicht behauptet: Die vorhandenen Belohnungsmultiplikatoren steigen gerade nicht mit.

## 5. Startwaffe: zeigen, auswählen, starten

### Normalansicht

- Raster mit den 18 vorhandenen gemalten Waffenbildern in stabiler Katalogreihenfolge.
- Eine Auswahlmarkierung, eine große Vorschau, ein Waffenname.
- Wurzelkosten einmal, in der Nähe der ausgewählten Waffe.
- Schaden, Angriffspause und Reichweite als vorhandenes Icon mit Wert und Einheit.
- Höchstens ein kurzer mechanischer Schlüsselbegriff, wenn er für diese Waffe
  entscheidend ist, etwa Blutung oder Nass. Keine vollständige Beschreibung als Standard.
- Ein einziger finaler Button „Run starten“. Ohne ausdrückliche Waffenwahl bleibt er deaktiviert.

Vor der Auswahl zeigt die Vorschau Denti unbewaffnet. Kein Text „Tippe auf eine
Waffe“, keine zweite Erklärung des Iconrasters, keine künstlich vorgewählte Waffe.
Namen bleiben per Fokus, Hover und zugänglicher Auswahl erreichbar. Das Raster
wird nicht zusätzlich mit langen Namen unter allen 18 Bildern beschriftet.

### Details

Erst auf Nachfrage: Rolle, Besonderheiten, vollständige Mechanik und Skalierung.
Wurzelkosten und Basiswerte werden dort nicht aus mehreren Rohtexten dupliziert.
Neue Spieler können auch ein Werteicon antippen; Erklärungen sind nicht an eine
Desktop-Maus gebunden. Unbekannte Symbole bekommen einen Namen, keine unsichtbare
Bedeutungspflicht.

Basis für alle Werte ist die tatsächliche Mk-I-Waffe. Eine geschätzte DPS wird
nicht zur großen Gesamtnote gemacht, weil Fläche, Support und Blutung darin
unvollständig abgebildet werden. Es gibt in diesem Schritt keinen Preis,
Kaufbutton oder erfundenen Buildbonus.

## 6. Textregeln für das gesamte UI

| Inhalt | Dauerhaft sichtbar? |
| --- | --- |
| Objektname, Aktionsname, Wert mit notwendiger Einheit | Ja, am zugehörigen Objekt |
| Gewählte Option und verfügbar/gesperrt | Als Zustand; kurze Bedingung nur bei einer Sperre |
| Ein entscheidender ungewöhnlicher Effekt | Ein kurzer Begriff oder gezielter Hinweis |
| Bedeutung eines bekannten Icons, vollständige Mechanik, Berechnung | Auf Anfrage |
| „Tippe hier“, „Wähle eine Waffe“, „Erst ansehen, dann starten“ | Entfällt im normalen Ablauf |
| Dieselbe Information als Titel, Untertitel und Zusammenfassung | Einmal anzeigen |
| Erklärungstext, der nur leeren Raum füllen soll | Entfällt |

Fehler oder Blockierungen dürfen knapp sagen, was fehlt. Ein deaktivierter
Button ohne ersichtlichen Grund ist ebenso wenig gute UX wie ein ständiger
Anleitungstext. Leere Waffenvorschau und klar markierte Auswahl sollen den
normalen Fall bereits verständlich machen.

Diese Regel wird bei späteren Arbeiten auch auf Shop, Pause und Belohnungen
angewendet. Die bereits freigegebenen HUD-Anker und Ressourcenformen bleiben
dabei erhalten; es wird keine neue Textschicht ins Kampfbild eingebaut.

## 7. Zustände, Navigation und Rückmeldung

- Vor/Zurück und bereits besuchte Schritte behalten die Wahl. Der Schrittverlauf
  zeigt keine noch nicht existierende Klasse. Später wird der Klassenschritt
  zwischen Schwierigkeit und Waffe eingefügt, mit derselben Bühne und Navigation.
- Vorschau, Tastaturfokus, gewählte Option und gesperrte Option sind verschiedene Zustände.
- Escape beziehungsweise Zurück geht eine Ebene zurück, ohne einen Run zu starten.
- Doppelklick und Doppeltippen können weder Schritte überspringen noch einen zweiten Run anlegen.
- Die aktuelle Run-Datei bleibt bis zum bestätigten neuen Start erhalten.
- Ein kleiner Speicherentwurf erhält Seite und Wahl. Weiterführende Hilfen ändern
  weder die gewählte Waffe noch den erreichten Schritt.
- Beim Drehen des Geräts bleiben Auswahl, Fokus und sichtbare Navigation erhalten.
- Keine Auswahlbestätigung per Toast oder erklärendem Satz. Kurzer Konturwechsel,
  eine passende UI-Rückmeldung und gegebenenfalls ein dezenter Bildimpuls reichen.
- Übergänge dauern ungefähr 120–180 ms und blockieren keine Eingabe. Keine
  Mindestwartezeit, kein Dauerpulsieren, kein dekoratives Flackern. Reduzierte
  Bewegung wird respektiert. Der eigentliche Spielstart nutzt den vorhandenen Szenenwechsel.

## 8. Technischer Schnitt für die nächste Umsetzung

Die große View-Logik wächst nicht weiter im allgemeinen `GameMenu`.

1. `RunSetup` bleibt Daten- und Ablaufmodell: Schrittfolge, Schwierigkeit, Waffe,
   gespeicherter Entwurf und spätere Klassendaten. Es enthält keine Layoutmaße.
2. Eine eigene `RunSetupScreen`-Szene besitzt Hintergrund, Kopfzeile, Bühne,
   Schrittanzeige und Navigation. Dieselbe äußere Geometrie für alle Schritte.
3. `DifficultySelection` und `WeaponSelection` liefern den jeweiligen Inhalt.
   Auswahlereignisse ändern das Modell; Ansichten starten keine Welle selbständig.
4. Eine kleine Präsentationsschicht erzeugt kompakte Iconwerte und optionale
   Detaildaten aus den Ressourcen. Kein Zusammenkleben von `description`,
   `stats_text()` und `combat_text()` zum permanenten Leseblock.
5. Ein eigener Layouthelfer berechnet aus logischer Breite, Höhe und Safe Area
   das passende Layout. Keine verteilten Sonderfälle mit 520/960-Pixel-Kappen.
6. Gemeinsame Zustandsstile für Auswahl, Fokus und Hauptaktion werden für
   weitere Menüs wiederverwendbar. Neue gemalte Assets bleiben separate Texturen.

Spielregeln, Schwierigkeitsbalance, Gegnerdruck und Kampfskalierung ändern sich
bei dieser Arbeit nicht. Die Datenquelle bleibt maßgeblich.

## 9. Umsetzung in überprüfbaren Paketen

### A. Gestaltung und Geometrie festziehen

Die klickbare Studie macht Bühnenbreite, Auswahlzustand, Navigationspositionen
und den reduzierten Textumfang konkret. Desktop und Hochformat, gewählte und
ungewählte Waffe sowie gesperrtes Hell ansehen. Anschließend dieselbe Geometrie
als native Godot-Vorschau herstellen. Die Browserstudie ersetzt keine native Abnahme.

### B. Finale Bildfamilie

Vier zusammenpassende Schwierigkeitsmotive erstellen; vorhandene Waffen behalten.
Originale bewahren. Bildgewichte und Silhouetten in der tatsächlichen Kartengröße
prüfen. Erst danach zusätzliche Materialeffekte oder Ornamente ergänzen.

### C. Run-Vorbereitung als eine Szene umsetzen

Gemeinsame Bühne, responsive Schwierigkeit und kompakte Waffenvorschau verbinden.
Textduplikate entfernen. Vor/Zurück, Entwurfspeicherung, Story-Start und Migration
alter offener Auswahlen übernehmen. Kein Wechsel der Präsentationssprache pro Schritt.

### D. Rückmeldung und Feinschliff

Auswahl, Fokus, Sperre und Übergang aufeinander abstimmen. Danach freie Flächen,
Bildabstände, vertikale Mitte und tatsächliche Schriftwirkung prüfen. Erst dann
die Funktions- und Layouttests als letzten Teil der Abnahme laufen lassen.

### E. Andere Menüs anhand derselben Regeln prüfen

Hauptmenü, Optionen/Pause und Belohnungen einzeln auf unnötige Texte, doppelte
Beschriftung, unklare Aktionen und unnötige Scrollbereiche prüfen. Keine pauschale
Großbaustelle mit gleichzeitigem Umbau aller Spielansichten.

Die [Bestandsaufnahme der übrigen Ansichten](UI_VIEW_AUDIT.md) ist abgeschlossen:
15 native Ansichtszustände auf Desktop und mit mobiler Projektbasis geprüft.
Die gemeinsame Grundlage sowie Hauptmenü, Pause und Einstellungen sind nun
[im ersten Paket umgesetzt und nativ geprüft](MENU_UI.md), einschließlich
mobiler Größenkorrektur und klarer Aktions-/Fokuszustände. Auch die
[Belohnungsbühne](REWARD_UI.md) ist umgesetzt. Anschließend folgen Run-Ende,
Shop/Build und Leseseiten als eigenständige Pakete.

## 10. Abnahme: Gestaltung und Verhalten

### Visuelle Prüfung

- Native Screenshots in 320×568, 568×320, 720×1280, 1040×600, 1280×720 und 1920×1080.
- Zusätzlich echte Fenstergrößen mit unveränderter Projekt-Stretch-Einstellung
  prüfen. Ein Test, der `content_scale_size` auf jede Zielauflösung setzt, allein
  belegt das tatsächliche Verhalten auf einem größeren Monitor nicht.
- Auf Desktop alle vier Schwierigkeiten und alle 18 Waffen ohne Auswahlscrollen.
- Bei 1280×720 nutzt die Auswahl die geplante Bühnenbreite; kein kleiner Dialog
  mit willkürlich großem Rand. Kein bloßes Aufblasen leerer Buttonflächen.
- Keine gestreckten Motive, abgeschnittenen Ornamente oder unterschiedlich
  wirkenden Icongrößen wegen transparenter Ränder.
- Auswahl, Fokus, Hover, Sperre und Hauptaktion sind in einem Bild unterscheidbar.
- Schrift in echter Größe ansehen. Wesentliche Werte bleiben lesbar; essentielle
  Touch-Bedienung erhält mindestens 48×48 große Ziele.
- Normalansicht enthält keine Bedienungsabsätze und keine dreifache Beschreibung
  der gewählten Waffe. Neue Texte brauchen eine konkrete Entscheidungsfunktion.

### Ablaufprüfung

- Eine Person ohne Einweisung findet Schwierigkeit, Waffe, Zurück und Start.
- Iconwahl startet kein Spiel; bestätigter Start beginnt genau einmal Welle 1.
- Informationen sind bei Bedarf per Maus, Tastatur und Touch zugänglich.
- Fokus bleibt beim Layoutwechsel sinnvoll; Zurück setzt keine Auswahl zurück.
- Gesperrtes Hell kann nicht gestartet werden und hat eine erkennbare Bedingung.
- Entwurf, bestehender Run, alte Saves und Story-Intro bleiben korrekt.
- Reduzierte Bewegung und schnelle Eingaben führen zu keinem Hängenbleiben.

Ein bestandener Grenztest und eine hohe Testanzahl sind weiterhin nötig. Sie
werden künftig nicht mehr als Beleg für eine gelungene visuelle UX präsentiert.

## Vorschau

Die lokale Studie liegt unter `docs/concepts/ui-ux-plan/index.html`; `mobile.html`
zeigt dieselbe Richtung mit schmaler Bühne. Sie verwendet bestehende Bilder als
Layoutreferenzen. Die vier neuen
Schwierigkeitsillustrationen und die gemeinsame Godot-Szene sind inzwischen umgesetzt.
Die Studie bleibt die Entwurfsreferenz; die nativen Aufnahmen zeigen den Spielstand.

Die Browserstudie wurde mit Auswahlwechsel, Weiter/Zurück, erhaltener Waffenwahl,
gesperrtem Hell und der kompakten mobilen Waffenvorschau geprüft. JavaScript-Syntax
und eigenständig eingebettete Bild-/Schriftdaten wurden ebenfalls geprüft.
[Desktopaufnahme](concepts/ui-ux-plan/desktop.png),
[mobile Waffenansicht](concepts/ui-ux-plan/mobile.png).


## Umgesetzter Stand

Pakete A–D sind im Spiel umgesetzt: gemeinsame Bühne, vier Imagegen-Motive,
responsive Karten und Waffenraster, kompakte Iconwerte, abrufbare Details,
getrennte Auswahl-/Fokuszustände und nicht blockierende Rückmeldungen.
Vor/Zurück, besuchte Schritte, Entwurfsfortsetzung, bestehende Runs, alte offene
Auswahlen und Story-Start nutzen denselben Ablauf. Ein lokaler Skalierungsausgleich
und MSDF-Schrift erhalten Bedienbarkeit und Schärfe in echten kleinen Fenstern;
die globale Kampfskalierung bleibt bestehen.

Die visuelle Prüfung umfasst alle sechs vorgesehenen Größen, die tatsächliche
Desktop-Projektskalierung bei 1920×1080 und die mobile Projektbasis im physischen
320×568-Fenster. Geprüft wurden auch leere Auswahl, langer Waffenname, Sperre,
Detaildialoge und native Maus-/Escape-Eingabe. Paket E ist als
[Prüfung und Umsetzungsplan](UI_VIEW_AUDIT.md) ausgearbeitet. Sein erstes
[Menüpaket](MENU_UI.md) und die [Belohnungsansichten](REWARD_UI.md) sind
umgesetzt; Run-Ende, Shop/Build, Leseseiten und echte Balancevergleiche bleiben
eigenständige Folgearbeiten.
