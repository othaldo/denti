# Denti: eine lesbare und liebenswerte Zahnklinik

Konzept aus den fünf bereitgestellten Brotato-Beispielen und Dentis aktuellem
Shop. Dieser Vorschlag ändert noch keine Spieloberflächen oder Spielregeln.

## Was an den Referenzen hilft

- Angebote, Ausrüstung und aktuelle Spielerwerte sind gleichzeitig sichtbar.
- Wiederkehrende Werte stehen in derselben Reihenfolge: Schaden, Crit, Pause,
  Reichweite; besondere Effekte bekommen einen eigenen Absatz.
- Waffen haben ein großes Bild, eine klare Kategorie und eine erkennbare Stufe.
- Details erklären neben Zahlen auch die konkrete Mechanik und den Buildbezug.
- Gemessene Leistung und hypothetische Werte beantworten unterschiedliche Fragen.

Denti sollte seine warme Farbwelt, gemalten Waffen und kurzen Zahnwitze
beibehalten. Große schwarze Texttafeln, weitere Stats, Waffen-Setboni und
zusätzliche Shopangebote sind keine Voraussetzung für dieses UI-Konzept.

## Erste Ausbaustufe: Kaufentscheidungen erleichtern

### Waffenkarte

Großes Sprite, Name in normaler Schreibweise, Stufe I–IV und expliziter
Wurzelbedarf. Dazu eine verständliche Rolle wie „Gruppen zurückdrängen“,
„Boss-Fokus“ oder „Blutung aufbauen“. Die Rolle erklärt den Einsatz; die
Schadensart erklärt Synergien. Seltenheit bleibt mit Farbe UND Text erkennbar.

Auf der kleinen Karte nur Treffer, Angriffspause, Reichweite und ein markanter
Effekt. Im Detailbereich zusätzlich Crit-Chance und -Multiplikator,
Rückstoß, Blutung, Nass, Flächenradius und Ausbaueigenschaften.

Im Shop die Werte des aktuellen Builds zeigen, nicht nur Basiswerte. Aufklappbar
bleibt „So entsteht der Wert“ mit Basiswert, Stufe, Spielerwert und konstanten
Modifikatoren. Zielabhängige Boni wie Bossbonus, Nass und Ziel-Fokus stehen
getrennt daneben. Geschätzte Einzelziel-DPS ist ergänzende Information und
keine Gesamtnote; sie unterschätzt Support, Flächenangriffe und Blutung.

### Ein gemeinsamer Detailbereich

Hover oder Tastaturfokus zeigt ein Angebot; Antippen oder Anklicken fixiert die
Auswahl. Der separate Kaufknopf verhindert versehentliche Käufe beim Lesen.
Auf kleinen Bildschirmen erscheint derselbe Inhalt direkt unter der Auswahl;
keine wesentliche Information ist nur per Hover zugänglich.

Für echte Gegenüberstellungen wählt der Spieler eine Vergleichswaffe selbst.
Bei demselben Waffentyp kann das vorhandene Exemplar vorgewählt werden.
Grün/Rot kennzeichnet ausschließlich eindeutig gerichtete Änderungen und steht
immer neben einer Zahl. Zwei Wurzeln sind Platzbedarf, nicht automatisch ein
Nachteil. Wasserfächer und Rakete verdienen einen Rollenvergleich statt einer
pauschalen „besser“-Markierung.

### Sechs Wurzelplätze sichtbar machen

Die Ausrüstung als Bildleiste zeigen. Jede Waffe trägt eine Stufenmarke;
Waffen mit zwei Wurzeln belegen zwei zusammenhängende Plätze. Dieselbe Waffe wird
trotzdem nur einmal gezeigt, sodass Anzahl und Wurzelkosten nicht verwechselt
werden. Auswahl öffnet den gemeinsamen Detailbereich mit Verkaufen und Fusion.

Kaufaktionen beschreiben ihr Ergebnis: „Ausrüsten · 2 Wurzeln“, „Zu Stufe III
fusionieren“ oder „Kein Platz · 2 Wurzeln benötigt“. Ein konkreter Fusionspartner
wird sichtbar hervorgehoben. Verkauf bleibt bestätigt; ein nur auf Text
basierender versteckter Doppelklick ist langfristig weniger verständlich.

Die klickbare Skizze setzt die Auswahl belegter Wurzelplätze um: Im gemeinsamen
Detailbereich lässt sich eine ausgerüstete Waffe verkaufen (mit Bestätigung)
oder mit einem gleichen Exemplar derselben Stufe fusionieren. Der passende
Partner wird markiert; die Vorschau zeigt neue Stufe, Werte und frei werdende
Wurzelplätze. Ohne Partner beziehungsweise auf Stufe IV ist Fusion deaktiviert.
Als Beispiel enthält die Startausrüstung zwei Polierer auf Stufe I.

### Aktueller Build

Im Desktop-Shop rechts eine kompakte Übersicht der acht vorhandenen Stats;
auf kleinen Screens ein aufklappbarer Bereich „Deine Werte“. Einheitliche
Bezeichnungen: „Bisskraft · Schaden“, „Putzeifer · Angriffstempo“ usw.
Bei Level-ups eine unmittelbare Vorschau: beispielsweise „Leben 100 → 110“.
Die Wahlphase bleibt nach dem Loot-Sweep; das Konzept führt keine Kampfmodals ein.

## Zweite Ausbaustufe: Zusammenhänge erklären

- Konkrete Buildhinweise: „Deine Zauberbürste profitiert vom Fluorid-Spray“
  oder „Nass bereitet deine UV-Lampe vor“. Nur anzeigen, wenn die passende
  Ausrüstung oder der konkrete Itemeffekt tatsächlich vorhanden ist.
- Vorhandene Effekte in verständlichen Familien bündeln, etwa Blutung, Wasser,
  Licht, Schmelz und Schild. Keine erfundenen Familienboni suggerieren.
- Gesammelte Items bleiben als kleine Icons ganz unten sichtbar, jeweils mit
  Stapelzahl. Hover, Tastaturfokus oder Antippen zeigt Titel und Effekt. Im
  Tooltip klar zwischen Effekt je Exemplar und tatsächlich wirksamer Summe
  unterscheiden; Caps und nicht stapelbare Effekte dürfen nicht einfach
  multipliziert werden. Die Iconleiste bleibt auch in der kompakten Variante
  erhalten. Relikte können daneben als getrennte Gruppe erscheinen.
- Im nächsten-Welle-Hinweis die relevante Gefahr erklären, z. B. mehr
  Fernkämpfer, statt nur einen internen Profilnamen anzuzeigen.
- Bei der Schwierigkeit erklären, welche Gegnerdruck-Regler der vorhandene
  Schwierigkeitsgrad tatsächlich verändert; keine fremden Brotato-Regeln übernehmen.

## Liebenswert durch Rückmeldung

Denti bekommt einen sichtbaren Platz in der Zahnklinik und kurze Reaktionen
auf Käufe, erfolgreiche Fusionen und Belohnungen. Beispiele: „Frisch poliert!“
bei einer Fusion oder „Bereit für die nächste Behandlung?“ am Wellenstart.
Klare Aktionsnamen bleiben erhalten; Humor steht daneben statt an ihrer Stelle.

Kauf: Münze fliegt kurz zum Angebot, die Waffe landet im richtigen Wurzelplatz.
Fusion: beide Exemplare verbinden sich zu einer neuen Stufenmarke.
Upgrade: der geänderte Stat wird kurz hervorgehoben. Animationen bleiben kurz,
überspringbar und blockieren keine nächste Eingabe. Reduzierte Bewegung beachten.

Eine ruhige Minz-/Elfenbeinfläche, dunkle Pflaumenschrift, goldene Aktionsakzente,
große Waffenbilder und großzügigere Abstände unterstützen den vorhandenen Stil.
Keine Dauerpartikel und keine zusätzliche Dekoration im Kampf-HUD.

## Spätere Leistungsauswertung: ehrlich bleiben

Die Telemetrie zählt Waffenschaden aktuell nach Waffentyp über den ganzen Run,
nicht nach Einzelexemplar und nicht als gespeicherte Wellenstatistik pro Waffe.
Blutung und andere Procs werden separat gezählt. Ein Wert „diese Waffe verursachte
letzte Welle …“ braucht daher erst passende Instrumentierung.

Zunächst kann ein sauber beschrifteter Run-Wert pro Waffentyp gezeigt werden.
Später echte Wellenwerte ergänzen, einschließlich einer erklärten Zuordnung von
Statusschaden. Supportwaffen erhalten keinen irreführenden Schadensrang.

## Empfohlene Reihenfolge

1. Gemeinsame Waffendetails, aktuelle Buildwerte, Rollen und Wurzelplätze.
2. Explizite Kauf-/Fusionsergebnisse und Vergleich mit eigener Ausrüstung.
3. Derselbe Detailstil für Level-ups, Kisten, Relikte und Startwaffen.
4. Konkrete Synergiehinweise und kurze Denti-Reaktionen.
5. Gemessene Wellenleistung nach Erweiterung der Telemetrie.

Die klickbare Skizze zeigt zwei Richtungen: eine offene „Werkbank“ mit
Angebotskarten und dauerhaftem Detailbereich sowie eine „Kompakte Zahnklinik“
mit Angebotszeilen und Details unter der Auswahl. Alle Build-, Münz- und
Leistungswerte darin sind illustrative Beispiele, keine gemessenen Runs.

## Im Spiel umgesetzt

Der Shop verwendet jetzt Angebotskarten mit gemeinsamen Details auf Desktop und Angebotszeilen mit Details darunter auf kleineren Ansichten. Die aktuellen Buildwerte, Waffenrollen, tatsächliche Synergiehinweise und ein Vergleich mit eigener Ausrüstung stehen zur Verfügung. Der Preisbutton auf jeder Karte kauft direkt und wird bei fehlenden Münzen, vollem Loadout oder Stapellimit deaktiviert. Die Karte bleibt für Details anwählbar. Ein zusätzlicher Kaufbutton und der Berechnungsbereich entfallen.

Belegte Wurzeln öffnen denselben Detailbereich. Verkauf braucht eine Bestätigung; Fusion zeigt die nächste Stufe, frei werdende Wurzeln und markiert passende Exemplare. Kauf fusioniert nur dann automatisch, wenn für eine zusätzliche Waffe kein Platz bleibt und ein passendes Exemplar vorhanden ist. Die bestehenden Spielregeln bleiben maßgeblich.

Items und Relikte stehen als horizontal scrollende Icons mit Stückzahl unten. Hover zeigt Name und Effekt, Antippen öffnet die Details. Aktionen, Weiter und Itemleiste bleiben auch im mobilen Hoch- und Querformat erreichbar. Level-up-, Kisten- und Reliktauswahl verwenden vorerst ihre vorhandene Darstellung; Kaufanimationen und neue Waffentelemetrie sind weitere Konzeptideen.

Stats und Items im Pausenmenü verwenden inzwischen kompakte Tabellen beziehungsweise Icons mit Anzahl und gemeinsamen Details, ohne großes Charakterbild. Kleine Sammlungen belegen nur ihre benötigte Höhe.
