# Patchnote-Historie

Die Versionsnummer wird zentral in `project.godot` gepflegt und im Hauptmenü angezeigt. 0.1.0 wurde rückblickend anhand der Git-Historie dokumentiert; 0.2.0 bündelt die seitdem entstandenen Änderungen. Die Einträge beschreiben implementierte Funktionen. Weitere Pläne stehen in der [Roadmap](docs/ROADMAP.md).

## Noch ohne neue Versionsnummer — 02.11.2026

- **Testpilot weicht dem ersten Boss gezielter aus:** Warnungen werden zum tatsächlichen Trefferfenster bewertet; verzögerte Beobachtungen werden fortgeschrieben. Langsame Schritte erlauben sichere Positionen in Ringangriffen. Eine Gegenprobe mit gleichen gespeicherten Startbuilds verbessert sich von 6/18 auf 17/18 Bosskills, ohne Waffen- oder Gegnerwerte zu ändern. [Messung, weitere Seeds und Grenzen](docs/BOSS_PILOT.md).

- **Bot-Test per UI starten:** Lokaler Python-Launcher mit Waffen-, Bot-, Strategie-, Build- und Schwierigkeitsauswahl, gespeicherten Einstellungen und Berichtzugriff. Sichtbare Testläufe zeigen jetzt die echten Aufstiege, Verzauberungspläne, Käufe und Rerolls. Die Tempowahl gilt auch im Shop; Leertaste hält die aktuelle Entscheidung an. [Aufruf und Bedienung](docs/BOT_SIMULATION.md).

- **Verzauberungsschritte im Botlauf:** Jeder Punkteeinsatz zeigt einzeln das Waffenexemplar, den neuen Rang und die verbleibenden Punkte. Tempo und Pause gelten auch zwischen diesen Schritten. Die Buildregeln heißen im Launcher jetzt „Feuer-Referenz“ und „Synergie-Heuristik“, um ihre festen Entscheidungsregeln kenntlich zu machen.

- **Testpiloten und sichtbarer Zeitraffer:** Entwicklerwerkzeug mit drei verzögerten Reaktions-/Fehlerprofilen, vier Kampfstrategien und unabhängigen Buildregeln für W1–5. Bots beobachten aktuelle Gegner, Projektilbahnen und Graf-Warnungen und benutzen den echten Dash. Native Pause und 1×/4×/8×/16× erhalten feste Physikschritte; Headless-Matrizen verteilen Konfigurationen und Seeds auf isolierte Worker. [Start, Grenzen und Prüfungen](docs/BOT_SIMULATION.md).

- **Kontaktwaffen gezielt stärken:** Kleine Rückstöße bei Bohrer, Fräse, Kratzer und Polierer schaffen Raum. Der Kratzer kann ein weiteres Ziel auf seiner Hiebspur für 50 % Trefferschaden treffen. Der Polierer erhält 110 Reichweite und einen gespeicherten Crit-Zyklus pro Waffenexemplar: Jeder dritte Angriff ist kritisch, auch nach Zielwechsel und Pausen. Kratzer und Polierer können ein bereits totes Ziel innerhalb derselben sichtbaren Bewegung ersetzen. [78 Einstiegsproben, Grenzen und Spieltest-Punkte](docs/CONTACT_WEAPON_BALANCE.md).

- **Waffenskalierung direkt sichtbar:** Startauswahl, Shopkarten, Waffendetails und Dentipedia zeigen Nahkampf/Fernkampf samt individuellem Faktor. Die Details erklären den Beitrag von Nah-/Fernschaden; Schadensarten wie Licht oder Schnitt bleiben davon getrennt. Auch geheime Evolutionen verwenden ihre tatsächlichen Ressourcendaten.

- **Bohrwerkzeuge im frühen Ausbau:** Der Turbo-Bohrer kann bei verlorenem Ziel einen Gegner auf derselben Stoßbahn treffen und einen weiteren Gegner vorwärts für 50 % Schaden durchbohren. Die Karies-Fräse erhält 110 statt 78 Reichweite und verursacht gegen normale Gegner vollen statt 75 % Schaden. Hauptziel-/Bossschaden des Bohrers und Boss-/Eliteboni der Fräse bleiben erhalten. Gespeicherte Angriffe bewahren ihr verbrauchtes Kontaktbudget. [Kontrollproben, Auswertung und Grenzen](docs/DRILL_CONTACT_BALANCE.md).

- **Erster gemessener Balancepass:** Die Interdental-Bürste erreicht weiter und stößt Gegner radial zurück. Der Imperator hält auf Normal/Hard/Hell bei seinen fest angekündigten Urteilen begrenzt vor. Lebensraub bleibt bis Rang 4 unverändert und wächst danach langsamer; Rang 10 heilt maximal 1,11 statt 1,65 HP je Wurzel und Impuls. UV-/Elementschaden bleibt erhalten. Reproduzierbare Kampfproben und verbesserte Run-Telemetrie erfassen auch tatsächliche Heilung, Überheilung und den Build zu Wellenbeginn. [Werte, Vergleiche und Grenzen](docs/BALANCE_FIRST_PASS.md).

- **Anklickbare Tastaturleiste:** Kontextabhängige Tastenkappen für Enter, Esc, R, F, I, P, Backspace und Q/E ergänzen die Controller-Leiste. Maus und Tastatur nutzen dieselben Aktionen; Suchfelder, native Details, gehaltene Tasten und Modalgrenzen bleiben geschützt. Pfeiltasten und Tab / Shift+Tab navigieren innerhalb des aktuellen Menüs. [Belegung und Ansichten](docs/CONTROLLER_SUPPORT.md#tastatur-und-anklickbare-pc-aktionsleiste).

- Einheitliche Vergleichspfeile `→` auch bei Waffen, Fusionen, Verzauberungen und alten Upgrade-Kapseln statt der bisherigen `->`-Ausweichschreibweise. Die Pfeile sind passend zu Fredoka 25 % größer, kräftiger und optisch an den Ziffern ausgerichtet.

## 0.7.0 — 01.11.2026

- **Controller-Steuerung:** Bewegung, Dash und Menüs mit Xbox- und PlayStation-Symbolen. Eine gemeinsame Aktionsleiste verwendet A/Kreuz für die Primäraktion, B/Kreis für Zurück, Menu/Options für Pause und RS/R3 für Details. X/Quadrat würfelt, Y/Dreieck merkt oder macht rückgängig und RT/R2 schließt einen Arbeitsschritt ab. Gehaltene Tasten und Trigger bestätigen keine folgende Ansicht automatisch. [Bedienung und geprüfte Ansichten](docs/CONTROLLER_SUPPORT.md).

- **Controller-Modus wählbar:** Automatisch, Xbox, PlayStation oder Aus. Bewusste Eingaben aktivieren ein geeignetes Gamepad; Lenkräder, Pedale und Simulator-Panels übernehmen weder Symbole noch Steuerung. Totzonen, Neutralstellung und Gerätebindung verhindern flackernde Eingabeanzeigen und Eingriffe anderer Geräte. Die Symbolfamilie lässt sich unabhängig von der Mausbedienung festlegen.

- **Shop als gemeinsame Vergleichsansicht:** Angebote, Waffen und Stats bleiben zusammen sichtbar. Jede Angebotskarte ist ein Fokusziel zum Kaufen, Merken und Nachschlagen. L1/LB und R1/RB wechseln den Fokus zwischen Build und Angeboten; nach einem Kauf bleibt er beim nächsten verfügbaren Angebot. Waffenaktionen öffnen am gewählten Exemplar. Doppelte Shop-Buttons entfallen bei Controller-Bedienung.

- **Verzaubern und Fusion gezielt bedienen:** Schultertasten wechseln Waffen; die Verzauberungsübersicht führt vertikal über Aufsteigen und die vier Effektplätze. Auch Mk V und weitere Stufen sind regulär erreichbar. Die Effektauswahl bleibt im eigenen Raster. RT/R2 übernimmt den angezeigten Abschluss, offene Entwürfe verlangen beim Zurückgehen eine ausdrückliche Entscheidung. Fusion, Pflichtbelohnungen, Details und Pause beachten dieselben Modalgrenzen.

- **Fokus in den übrigen Ansichten:** R3 zeigt Informationen zur fokussierten Startwaffe, Schwierigkeit, Meisterschaft oder Belohnung. Dentipedia-Tabs wechseln über L1/R1 beziehungsweise LB/RB und merken ihren Eintrag. Kleine Build-/Itemansichten scrollen mit dem Fokus. Pause erhält Ansicht und Entwurf und hält Dialogtext und Kapitelreise an. Äußere View-Umrandungen entfallen; Karten, Buttons und Fokus behalten ihre Konturen. [Aktuelle Aufnahmen in 16:9](docs/screenshots/16x9/).

- **Aufstiege besser vergleichen:** Auswahlkarten zeigen den resultierenden Attributwert und berücksichtigen Obergrenzen. Gespeicherte Upgrade-Kapseln bleiben bei Änderungen der Ausrüstung stabil bedienbar.

- **Lesbare Vergleichspfeile:** Die mitgelieferte Ersatzschrift Arimo ergänzt fehlende Zeichen in Fredoka. Level-up-Vorschauen zeigen ihren Pfeil auch im Web und ohne installierte Systemschrift korrekt.

- **Mk V und höher gezielt kaufen:** Ab Mk IV bietet Verzaubern den Waffenaufstieg gegen Punkte und Gold. Kosten steigen je Stufe und Wurzel; Endlos skaliert den Goldanteil. Gemeinsame Vorschau, Rückgängig, kompatibles Fortsetzen und budgettreue Vererbung bei Evolutionen. [Preise, native Ansichten und Nachschub-Prognose](docs/WEAPON_ASCENSION.md).

- **Rahmenlose Dentipedia:** sechs direkt sichtbare Kategorien statt Dropdown, ruhigere Eintragsliste und größere Waffenvorschau mit kompakter Mk-Tabelle. Im schmalen Hochformat wechseln Liste und Details; Zurück/Escape bewahren Suche, Listenposition und Spielpause. [Native Ansichten](docs/DENTIPEDIA.md).

- **Imperator als aktiverer Finalboss:** Schnellere, weitreichend angekündigte Urteilsfächer, neu gezielter Portalanschluss und wechselnde Nervenringe/-fächer. Die Wache dreht während der Kernöffnung; Hell erhält vier Wiederholungen. Vollständige Warnungen, kompatibles Fortsetzen und 144 vollständige verlangsamte Ausweichrouten geprüft. [Verhalten und Vergleich](docs/EMPEROR_FINALE.md).

- **König mit mehr Angriffsdruck:** Gezielte Säurefächer während jeder Säurebahn und jedes Pegelwechsels, 3/5/7/9 Tropfen von Easy bis Hell. Auf Hard/Hell setzt er zwischen zwei Stampffolgen nach und erfasst Denti neu. Vollständige feste Warnungen, begrenzte Geschossbatches und kompatibles Fortsetzen. [Verhalten und Messung](docs/KING_ASSAULT.md).

- **Prinz wirft auf Hell doppelt so häufig:** Bomben einer Serie folgen alle 0,68 statt 1,36 s. Easy ×0,75, Normal ×1 und Hard ×1,5 des bisherigen Wurftakts. Überlappende Bomben behalten jeweils 1,1 s Vorwarnung und ein festes Ziel; Save/Fortsetzen erhält jede Flugbahn. [Takt und Prüfung](docs/PRINCE_BOMB_FREQUENCY.md).

- **Kürzere, aktivere Bosskämpfe:** Prinz −17 %, König −18 %, Imperator −20 % Basisleben; kürzere Schutz- und Gesundheitspausen. Der Prinz setzt während des Bombenflugs nach, König und Imperator bewegen sich nach kurzer Atempause auch mit offenem Kern. Weniger Leerlauf und mehr Nähe auf allen vier Schwierigkeiten, mit vollständigen Warnfenstern. [Vorher-/Nachher-Messung](docs/BOSS_AGGRESSION.md).

- **Imperator verfolgt Denti für seine AoE:** Vor Hofurteilen und der Kombination mit dem Nerventakt kommt er auf höchstens 300 px heran. Der gefährliche Sektor zielt bei Warnbeginn auf Denti und bleibt danach fest. Folgeurteile erfassen die neue Position erneut und setzen bei Bedarf erst nach. Gleiche Zielregel auf allen Schwierigkeiten, bestehende Warnzeiten bleiben erhalten.

- **Einheitliche Bodenwarnungen:** Kreise, sichere Ringe, Sektoren, Charge-/Geschossbahnen, Säurekapseln, Kissenrechtecke, Zielstrahlen und Timer verwenden dieselben glatten Konturen und bewegten Lichtfronten. Beschleunigte Aufladung, freie Angriffsfarben und gemeinsam gezeichnete Flächen ersetzen die separaten Boss-Warnwege. [Vorschau und Messung](docs/UNIFIED_TELEGRAPHS.md).

- **Waffenmeisterschaften:** Vier dauerhafte Auszeichnungen je Startwaffe, eigenes Menü Achievements im Hauptmenü und in der Zahnpause mit Waffenübersicht, gemalten Siegeln, Gesamtfortschritt, Suche, Filtern und Anforderungen auf Abruf. Die Run-Vorbereitung bleibt auf die Waffenauswahl begrenzt. Erste Bossprüfung auch auf Easy; Normal-/Hard-/Hell-Siege vergeben kumulative Medaillen. Neue Erfolge erscheinen nach der Welle und im Rückblick. Startwaffe, neue Erfolge und Debug-Ausschluss überleben Fortsetzen; bestehende Hell- und Evolutionseinträge bleiben erhalten. [Regeln und Vorschau](docs/WEAPON_MASTERIES.md).

- Waffenverzauberung nach Wurzelkosten: zwei Punkte je Kapsel, gleiche Ausbaukosten für sechs kleine oder drei große Waffen; Prozentboni ohne zusätzliche Wurzelgewichtung, Lebensraub mit Heilbudget je Wurzel. Glück kann eine Bonuskapsel nach der Welle geben; das neue Item Runenpolitur belohnt jede fünfte gesammelte Kapsel. Fusion und alte Punkte werden entsprechend umgerechnet.

- **Lebensraub je Waffe:** Jedes Waffenexemplar heilt mit seinem eigenen Intervall von 0,6 s. Salven und Flächentreffer teilen weiterhin den Takt ihrer Waffe; Der Heilanteil bleibt 5 % des wirksamen Treffers; das Heilbudget folgt den Wurzelkosten. Geschosse, Pooling und Fortsetzen behalten die Herkunft. Die Feen-Itemfamilie heilt nun 0,10 / 0,25 / 0,35 / 0,45 statt 0,15 / 0,35 / 0,45 / 0,60 Leben je XP. [Messung und Regeln](docs/SUSTAIN_BALANCE.md).

## 0.6.0 — 27.10.2026

- **Dentipedia aktualisiert:** 25 Mechanikthemen erklären Waffenpunkte, Mk-Plätze, ein Element pro Waffe, manuelle Fusion mit Punkteerstattung, Dash und Ausdauer, Elementtreffer und die neuen Zahnseidenangriffe. Shop, Belohnungsfolge, Gauner, Endlos und Fortsetzen sind auf dem aktuellen Stand; alte Zufallskapseln stehen ausdrücklich unter Altbestand. Waffeneinträge zeigen ihre Normal- und sechs Elementformen als Ansicht. Suche nach „Garotte“ findet die Schneide; geheime Evolutionen bleiben geschützt. [Inhalte und native Ansichten](docs/DENTIPEDIA.md).

- **Zahnseide mit festen Griffen:** Garotte und Zahnseidenpeitsche halten ihre Griffe bei Denti. Zwei beziehungsweise ein Faden schnellen nach vorn und treffen Gegner entlang des sichtbaren Wegs, höchstens einmal pro Angriff. Alle sechs Elemente animieren den Faden selbst. Die Garotte heißt Zahnseiden-Schneide, behält Rückstoß und 220–270 Reichweite; die Peitsche erhält 180–210 Reichweite für ihren Vorwärtsschlag. [Native Animationen und Messung](docs/FLOSS_CUT.md).

- **Sichtbare elementare Einschläge:** Geschosse, Nahkampf, Strahlen und Explosionen erzeugen ausbrechende Partikel und kurze Bodenspuren: Glut, Eissplitter, Giftschleim, elektrische Entladung, Blutlache oder Wasserspritzer. Größe und Richtung folgen dem Treffer; die Effekte bleiben unabhängig vom Projektil sichtbar und fügen keinen zusätzlichen Schaden hinzu. [Native Animation und Regeln](docs/WEAPON_ELEMENT_EFFECTS.md#einschläge-und-bodenspuren).

- **Eigene Verstärkungssymbole:** Reichweitenpfeil, Tempospuren, Lebensraubherz, Krit-Zielscheibe, kritischer Einschlag und Wuchtfaust ersetzen die bisherigen Item-Platzhalter. Einheitlich in Auswahl, Effektplätzen, Fusion und Dentipedia. [Ansicht und Asset](docs/art/support_icons.md).

- **Eigene Elementsymbole:** Flamme, Eiskristall, Giftschädel, Blutstropfen, Blitz und Wassertropfen ersetzen die Item-Platzhalter. Einheitlich in Verzauberung, Effektplätzen, Fusion und Dentipedia. [Native Ansicht und Asset](docs/art/element_icons.md).

- **Waffengrößen korrigiert:** Die neuen Texturen berücksichtigen wieder die sichtbaren Größen der bisherigen Normalformen. Gemeinsamer Maßstab je Waffe für alle Elemente; transparente Ränder verändern die Proportionen zu Denti nicht mehr. [Vergleich und Regeln](docs/WEAPON_SKINS.md#sichtbare-größe-neben-denti).

- **Manuelle Verzauberungsfusion:** Evolutionen und Mk-Fusionen mit Konflikten bieten eine reversible Effektauswahl. Maximal vier Plätze und ein Element, gleiche Effekte bis 10/10 zusammenführen, alle übrigen Ränge als Upgradepunkte zurück. Direktes Wiederverzaubern im Shop, gespeicherte Restpunkte und Verzauberungsentwürfe. [Regeln und Ansichten](docs/WEAPON_UPGRADES.md).

- **Angriffe passend zum Element:** eigene Geschosskerne für Feuer, Eis, Gift, Elektro, Blutung und Wasser; dazu passende Mündungsblitze, Nahkampfspuren, Strahlen, Sprühkegel, Treffer und Explosionen. Evolutionen übernehmen Farben und Effekte ebenfalls. Bereits fliegende Geschosse behalten ihr ursprüngliches Element, auch beim Fortsetzen. Vorbereitete Atlanten erhalten einen Sprite je Geschoss; Kampfwerte und Trefferflächen bleiben erhalten. [Animation und Prüfung](docs/WEAPON_ELEMENT_EFFECTS.md).

- **Alle Waffenformen im Spiel:** 18 Standardwaffen und sechs Evolutionen tragen ihre neuen Normal- und sechs Elementformen, insgesamt 168 Bilder. Die Auswahl zeigt die passende Form schon vor dem Verzaubern. Shop, Inventar, Kampf, Fusion und Fortsetzen übernehmen sie je Waffenexemplar. Fräse, Polierer und Schleuder behalten passende Animationsteile; kompakte Spieltexturen mit Mipmaps ersetzen die großen Vorlagen im Laufzeitimport. [Umsetzung und native Ansichten](docs/WEAPON_SKINS.md).

- **Ein Element pro Waffe:** Feuer, Eis, Gift, Blutung, Elektro oder Wasser; andere Plätze tragen Verstärkungen. Neu: Krit-Chance, Krit-Schaden und Wucht. Wasser verursacht eigenen Schaden mit Schwächen gegen Zucker (+50 %) und Plaque (+25 %). Weihe entfällt aus der neuen Auswahl; alte Investitionen bleiben erhalten. Elementkonflikte lassen sich in der Fusionsvorschau auflösen; übrige Ränge werden als Upgradepunkte erstattet. [Regeln und Waffenformen](docs/WEAPON_UPGRADES.md).

- **Dash geht durch Gegner:** Körperkontakt beendet den Wurzelsprung nicht mehr und verursacht währenddessen 50 % mehr Schaden. Wände und Arenarand stoppen weiter; Härte, Schild, Zahnflutsch und Trefferpausen gelten weiterhin. Dash-Cooldown 1,5 → 0,5 s; Regeneration feste 25 Ausdauer/s unabhängig vom Maximum. 300 Ausdauer erlauben drei schnelle Dashes, bevor nachgeladen werden muss. Lebensraub durch Waffenverzauberungen heilt nun gemeinsam alle 0,6 statt 0,75 s.

- **Gezielte Waffenverzauberung:** Upgrade-Kapseln geben frei verteilbare Punkte. Eine Waffe besitzt je nach Mk einen bis vier Effektplätze; Aktivieren startet bei 1/10, weitere Ränge kosten je einen Punkt bis 10/10. Neue Waffenansicht mit großer Vorschau, sichtbaren Mk-Sperren, tatsächlichen Vorher-/Nachher-Werten und Rückgängig. Unverbrauchte Punkte und offene Verteilungen werden gespeichert. [Regeln und native Ansichten](docs/WEAPON_UPGRADES.md).

- **Windows-Updater:** Stable/Beta-Prüfung im Hauptmenü, abbrechbarer Download, Paketprüfung und „Installieren & neu starten“. Austausch erst nach Spielende; fehlgeschlagene Dateiersetzung oder fehlende Startbestätigung stellen die bisherige Version wieder her. Spielstände bleiben außerhalb des Austauschs. Native Windows-Tests prüfen den Helfer samt Prozessübergabe und Rückfall. [Ablauf](docs/RELEASES.md#updater-im-windows-spiel).
- **GitHub-Builds und Releases:** automatische Web-/Windows-Pakete, herunterladbare Testbuilds, versionierte Release-Entwürfe, Prüfsummen und Update-Manifeste. Stabile Webversion und `/dev/` sind ab dem ersten veröffentlichten Release getrennt. [Ablauf](docs/RELEASES.md).
- **Gauner hält länger durch und sammelt im Laufen:** deutlich stärkere Gesundheitskurve; nahe Münzstapel werden alle 0,12 Sekunden gemeinsam eingesackt, auch beim Fliehen. Sammelpriorität für Denti und Beutellimit bleiben erhalten. Vergleich in Welle 11 auf Normal mit fünf Mk-III-Waffen: etwa 4,8 statt 1,8 Sekunden Lebensdauer.
- **Seltenheit wieder sichtbar:** Aufstiege, Itemfunde, Relikte und Kapselangebote tragen Farbkanten und getönte Flächen. Shop, Ausrüstung, Besitz und Dentikon verwenden dieselbe Zuordnung. Auswahl erhält die Seltenheitsfarbe; Ersatzoptionen haben keine doppelten Farbrahmen. Waffenwerte zeigen ihre eigene Rollqualität unabhängig vom Mk-Rahmen. [Native Ansichten](docs/RARITY_UI.md).
- **Goldzahn-Gauner:** seltener animierter Beutedieb ab Welle 8, höchstens einer pro normaler Welle. Sammelt lose Münzen, flieht und sucht Deckung hinter Gegnern. Beim Töten gibt es die Beute zurück und eine goldene Upgrade-Kapsel; bei Flucht am Wellenende gehen gestohlene Münzen verloren. Kampf bleibt ununterbrochen; Save/Resume erhält Beutel und Belohnung.
- **Weniger endlose Rerolls:** Shopkosten beginnen bei 2/3/5/8/12 statt 2/3/4/5/6; derselbe progressive Zuschlag gilt für Level-Auswahlen. Die Goldkurve bleibt in Welle 1–4 erhalten und fällt bis Welle 20 auf 55 %, später mindestens 40 %. [Regeln, native Animation und Einkommensprognose](docs/LOOT_GOBLIN.md).

## 0.5.0 — 17.10.2026

- **Gemalte Projektile:** eigene Formen für Wasser, Paste, Mundspülung, Metall, Licht, Raketen sowie gegnerische Säure- und Splittergeschosse. Spielerprojektile verwenden einen gemeinsamen Sprite statt mehrerer Ebenen. Flugrichtung, Rückflug und kreisende Geschosse richten sich korrekt aus, auch unter transformierten Eltern.
- **Verzauberungen am Geschoss:** bis zu vier gleichzeitig sichtbare Effekte als animierte Funken, Tröpfchen, Nebel und Lichtfäden. Die Darstellung wird beim Ausrüsten vorbereitet und bleibt ein Sprite pro Projektil. Aktive Geschosse behalten beim Waffenwechsel und Fortsetzen ihre ursprünglichen Effekte.
- **Waffen- und Bodeneffekte:** gemalte Licht- und UV-Ströme, Sprühnebel, Ketteneffekte, Nahkampf-Nachbilder, Pfützen und Impulse ersetzen einfache Linien und Flächen. Charge- und Geschosswarnungen zeigen pulsierenden Bodendruck mit Rissen.
- **Lesbarkeit bei vielen Warnungen:** überlagerte Füllungen werden lokal transparenter, während Zeitringe und Einschlagsgrenzen sichtbar bleiben. Boss-Charges werden nach gewöhnlichen Warnflächen gezeichnet und behalten eine stärkere Mindest-Sichtbarkeit. Belastungsszenen zeigen 10 und 20 gleichzeitige Warnungen mit zusätzlichen Projektilen.
- **Eigene Beute-Sprites:** XP fällt als türkisblauer Schmelzkristall in Zahnform, Gold als plastische Münze mit Zahnprägung. Beide nutzen den bestehenden Texturatlas und weiterhin nur einen Sprite pro Drop.
- **Vorbereitung und Messwerkzeuge:** gemeinsame Atlanten, vorbereitete Animationsframes und Menü-Warmup begrenzen Arbeit während des Kampfes. Neue reproduzierbare Vorschauen und Prüfungen decken Projektilausrichtung, kombinierte Verzauberungen, Warnungsüberlagerungen und Sammelflüsse ab. Nahkampf-Benchmarks samt Berichten ergänzen die Performance-Dokumentation; Desktop-Messwerte sind keine Browser-FPS-Zusage.

## 0.4.4 — 15.10.2026

- **Fusion behält die besten Werte:** Kauf und manuelle Fusion übernehmen je Attribut den besseren Wert beider Waffen. Mehrere passende Partner werden nach dem erwarteten Ergebnis ausgewählt; die Shopdetails zeigen die Vorschau. Eine einzige Kaufaktion ersetzt die Wahl zwischen alten und neuen Werten. Verzauberungen, Waffen-ID und investierte Münzen bleiben erhalten.

- **Verzauberungen in der Dentipedia:** eigene Kategorie mit Übersicht und allen zehn Effekten, ihren Regeln, Grenzen und passenden Builds. Die Mechanikartikel zu Strom, Blutung, Krits und Heilung erklären die neuen Verbindungen.
- **Zehn Verzauberungen mit Build-Rollen:** Glut-Verbreitung, Eissplitter bei Krits, begrenzter Giftaufbau und Elektroketten. Blutungsitems und Blutmond unterstützen verzauberte Waffen; geringere Grundschadensbudgets schaffen Platz für die Mechaniken.
- **Nässe, Weihe und Lebensraub:** Nassstatus für Wasser-/Elektrobuilds, Krit-Markierungen mit Lichtstoß und begrenzte Trefferheilung. Gemeinsame Abklingzeiten, Zielgrenzen und Schutz vor rekursiven Ketten.
- **Sichtbare Synergien und Messwerte:** passende Build-Hinweise in Kapselkarten, Verzauberungstags in der Shopgewichtung und eigene Schadens-/Unterstützungszahlen in der Debug-Telemetrie. Laufende Effekte und Abklingzeiten bleiben beim Fortsetzen erhalten.
- **Verzauberungen verständlicher:** ersetzt „Affixe“ im Spiel. Waffen erhalten einen Namenszusatz aus ihrer stärksten Verzauberung, der auch in Shop und Pause-Menü erscheint.
- **Kompaktere Kapselkarten:** Wirkung und konkrete Werte im Vordergrund, ausführliche Fundwerte im Tooltip. Symbole neben dem Titel, geringere Abstände und dynamische Umbrüche für Desktop und Mobilgeräte; die bestehende Schrift bleibt erhalten.
- **Prüfungen:** Namenswechsel nach Verstärkung, Austausch, Fusion und Fortsetzen sowie Textgrenzen in sechs Bildschirmgrößen.

## 0.4.2 — 14.10.2026

- **Upgrade-Kapsel:** neues transparentes Icon im gemalten Denti-Stil für HUD und Bodenbeute. Goldene Funde behalten ihre Tönung; die Drop-Größe bleibt konstant. Der Texturimport begrenzt die Laufzeitauflösung und verwendet Mipmaps.
- **Einheitliche Bezeichnung:** Tooltips, Belohnungsmenüs, Shop, Dentipedia, Items, Run-Rückblick und Dokumentation verwenden Upgrade-Kapsel. Titel und Zerlegen-Button berücksichtigen die längeren Texte auf kleinen Bildschirmen.
- **Tests:** gemeinsame HUD-/Drop-Textur, Drop-Größe und responsive Belohnungsansichten geprüft.

## 0.4.1 — 14.10.2026

- **Affix-Kartenlayout korrigiert:** Zeilenabstände und tatsächlich verfügbare Kartenbreite werden bei der Größenberechnung berücksichtigt. Lange Texte und Fortschrittsbalken bleiben innerhalb der Karten; Symbole und Überschriften sind oben einheitlich ausgerichtet.
- **Regressionstest erweitert:** vier belegte Affix-Slots, lange Fortschrittstexte, wiederholte Waffenwechsel und Inhaltsgrenzen auf Desktop- und Mobilgrößen geprüft.

## 0.4.0 — 14.10.2026

- **Individuelle Waffen und Shop-Loot:** Waffen besitzen eigene gewürfelte Attribute, Affixe und Effekt-Slots. Mk-Stufe und Attributqualität werden getrennt dargestellt; Namen behalten ihre Mk-Angabe.
- **Upgrade-Kapseln mit Build-Entscheidungen:** drei Angebote, direkt sichtbare Waffen- und Ersatzauswahl, durch Glück beeinflusste Funde und seltene goldene Beuteträger. Belohnungen werden nach der Welle aufgelöst; der HUD zeigt eingesammelte Upgrade-Kapseln als Icon mit Zähler.
- **Fortlaufende Affix-Progression:** gleiche Effekte verstärken sich, schwächere Funde bringen anteiligen Fortschritt und höhere Seltenheiten ermöglichen Aufstiege. Nach Legendär III geht es weiter. Bis zu vier Slots, Reichweite und Angriffstempo sowie seltene Upgrade-Kapseln-Aufstiege über Mk IV erweitern Builds; Shop und Fusion bleiben bei Mk IV.
- **Lesbarer Elementarschaden:** zusätzliche farbige Schadenszahlen ohne Typtext; auch Heilung zeigt nur Zahlen. Feuer, Gift und Blutung wirken über Zeit, Gegner besitzen passende begrenzte Resistenzen.
- **Mehr Druck:** höhere Gegner-HP und Skalierung, mehr Gegner und angepasste Kapselchancen. Normal dient als gemeinsame Basis. Hard und Hell erhalten beschleunigende Zusatzkurven für HP, Verteidigung, Tempo und Angriffsschaden. HP und Schaden wachsen im Endlosmodus weiter.
- **Stabile Affix-Karten:** feste Fundwerte, eindeutige Aktionsanzeigen und Text-/Höhenberechnung unabhängig von der zuvor ausgewählten Waffe, auch auf kleinen Bildschirmen.
- **Speichern und Tests:** individuelle Waffenwerte, Affix-Fortschritt, Kapselentscheidungen und laufende Effekte werden beim Laden erhalten. Automatisierte Prüfungen decken Progression, Effekte, Layout und Schwierigkeitskurven ab.


- CI-Tests auf die gewünschte Einstiegskurve (35 % Start-HP) abgestimmt. Effekt-Tests verwenden haltbare Ziele; der Save/Resume-Angriffstest verwendet reguläre Welle-10-HP und prüft separat, dass Laden und Trefferliste erhalten bleiben. Der Smoke-Test vergleicht Welle 2 mit den tatsächlichen Welle-1-HP.

## 0.3.0 — 08.10.2026

- **Sanfterer Einstieg:** gewöhnliche Gegner beginnen mit 35 % ihrer bisherigen HP. Ein weicher Übergang bringt sie bis Welle 10 auf die bisherige Kurve zurück. Gegnerrollen, Rüstung, Schaden, Spawn-Dichte, Bosse, Eliten und Endlosskalierung bleiben unverändert. Mehr frühe Kills können entsprechend mehr frühe Beute ermöglichen.

- **Lane-Warnflächen im Atlas:** rechteckige Warnflächen wechseln nicht mehr zwischen Polygon- und Atlaszeichnung. Darstellung im nativen Pixelvergleich identisch; isoliert 60 Lanes: 120 → 1 Zeichenaufruf. Keine zusätzlichen Bilddaten oder weniger Angriffe. [Vergleich und Grenzen](docs/WARNING_LANE_PERFORMANCE.md).

- **Dreifaltigkeits-Markierungen vorbereiten:** gemeinsame Atlasringe statt erneut aufgebauter Polygonlinien, dazu weniger temporäre Arbeit im Trefferpfad. Isolierter Desktop-Test mit 100 Ringen: 100 → 1 Zeichenaufruf und 0,75 → 0,21 ms Zeichenzeit. Handy-Auswirkung noch zu prüfen. [Messwerte und Grenzen](docs/MOBILE_PROFILE_FINDINGS.md).

- **Mobile Kampfdiagnose:** sechs Vergleichscodes für die volle Arena, CPU-Stichproben, P95/P99-Framezeiten und ein kopierbarer Messbericht. Varianten isolieren Text, zusätzliche Effektzeichnungen, eigene Angriffe, Trefferfolgen und Zeichnen. Messskripte laufen ausschließlich in Diagnosearenen. [Codes und Messgrenzen](docs/TEST_ARENAS.md#diagnose-der-vollen-arena).

- **Schadenszahlen bündeln:** gemeinsam gezeichnete Schriftumrandungen/-füllungen, vorbereiteter Text, gemeinsame Animation und wiederverwendete Labels. Volle Testarena auf Desktop: 408 → 221 Zeichenaufrufe und etwa 7 % weniger mittlere Framezeit. Spieler-Schaden und wichtige Meldungen bleiben sichtbar. [Messung und Grenzen](docs/DAMAGE_TEXT_PERFORMANCE.md).

- **Angriffe vorbereiten:** gebündelte Warnungen/Ansturmspuren, vorbereitete Warnsymbole und Spieler-/Beutegrafiken, erweiterter App-Warmup sowie wiederverwendete Gegnergeschosse. Entfernte Kontaktprüfungen werden früh abgewiesen. Bakterien-Warntest: 4,83 → 1,59 ms und 474 → 36 Zeichenaufrufe. `bacteria charge` isoliert Bakterien; Testanzeigen zeigen einzelne Framespitzen. [Prüfung und Grenzen](docs/ATTACK_PERFORMANCE.md).

- **Geschosse und Trefferupdates:** vorbereiteter gemeinsamer Atlas für alle 29 Säure-/Gift-/Blutungs-/Bossvarianten und weniger Zeichenupdates bei wiederholten Treffern/Statuseffekten. Isolierter 600-Geschoss-Test: 600 → 1 Zeichenaufruf. Neuer Vergleichscode `debug enemies` ohne eigenen Build. [Messung und Grenzen](docs/PROJECTILE_PRESSURE_PERFORMANCE.md).

- **Schnellere Tests:** vollständige Suite mit bis zu vier parallelen Godot-Prozessen, getrennten Benutzerdaten, Zeitlimits und Einzelzeit-/Log-Berichten. Lokal 84 Tests in 96 statt 325 Sekunden; CI verwendet denselben Runner. [Laufzeitvergleich](docs/TEST_RUNTIME.md).

- **Testarenen im Web:** siebenmal Einstellungen → Zurück schaltet die Code-Eingabe frei. `debug map` startet eine volle Welle-17-Arena, `boss charge` den isolierten Karieskönig. FPS-/Objektanzeige und Neustart im Pausemenü; der normale Spielstand bleibt erhalten. Der Web-Export unterstützt die Bildschirmtastatur. [Testcodes](docs/TEST_ARENAS.md).

- **Performance bei vielen Objekten:** gezielte Rasterabfragen, weniger doppelte Trefferprüfungen, gemeinsame Verarbeitung entfernter Beute und gebündelte Gegnerschatten. Keine verringerte Gegnerdichte oder Kampfwerte. [Messungen](docs/DENSE_COMBAT_PERFORMANCE.md).

- **Nass verlangsamt:** Wasserwaffen, Pfützen und andere Nassquellen senken das Lauftempo um 20 %, bei Eliten um 10 % und bei Bossen um 5 %. Erneutes Durchnässen verlängert nur die Dauer; Verlangsamung stapelt sich nicht. Angekündigte Anstürme bleiben unverändert. Karten/Details erklären den Effekt, Save/Resume erhält die verbleibende Nassdauer. [Regeln und Tests](docs/WET_STATUS.md).

- **Waffenbalance:** mehr Nahkampfschaden als Ausgleich für Reichweite und verlorene Angriffszeit, stärkere Fusion bis IV und gezielte Buffs für schwache Fernwaffen. Die Zauberbürste bleibt unverändert. Karies-Fräse verursacht 75 statt 55 % Schaden gegen normale Gegner; bestehende Evolutionen übernehmen die verbesserten Grundwerte. Reproduzierbare echte DPS-Messungen für alle 18 Waffen und vier Stufen, getrennt nach Einzelziel, Gruppe, Linie und Boss. [Vergleich und Tests](docs/WEAPON_DPS_BALANCE.md).

- Bossgeschosse werden beim Laden als gemeinsame Texturen vorbereitet und zusammen mit Charge-Zeichenpfaden einmal in einem kleinen separaten Viewport gerendert. Dadurch entfällt ihre erstmalige Bilderzeugung am Ende des ersten Charge.

- Flaky Save/Resume-Test korrigiert: Die Prüfung berücksichtigt die Obergrenze von 65 % Krit-Chance, statt bei einer zufälligen Glanz-Karte einen höheren Wert zu erwarten. Neue gezielte Prüfungen decken alle elf Level-up-Typen und vier Seltenheiten sowie Glanz unter, nahe und an der Obergrenze ab.

- Mobiler Pause-Button sitzt unter der FPS-Anzeige, damit sich beide im Hochkant- und Querformat nicht überdecken.

- **Performance:** räumliche Gegnerabfragen für Waffen und Synergien, gemeinsame
  Projektil-/Beuteatlanten, laufende Telemetrie-Summen, weniger HUD-Arbeit und
  Treffer-Tweens sowie begrenzte kosmetische Schadenszahlen. Neue Grafikoptionen
  Automatisch / Sparsam / Voll; Automatisch startet in voller Auflösung und
  senkt sie bei anhaltend unter 20 FPS im Kampf für den Run ab.
  Kampfwerte und Gegnerdruck bleiben erhalten.
  [Messungen und Prüfungen](docs/PERFORMANCE_AUDIT.md).

- Gerichtete Gegnergrafiken folgen der tatsächlichen Laufrichtung, einschließlich Rückzug und Ansturm; Angriffswarnungen zeigen die angekündigte Richtung. Die Blickrichtung bleibt beim Fortsetzen eines Runs erhalten.

- **Gift und Blutung für Denti:** erfolgreiche Gegnerkontakte und Geschosse können zeitlich begrenzte Effekte übertragen. Gift ignoriert Härte, Blutung wird durch Härte reduziert. Dodge und Schild verhindern die Anwendung; gleiche Effekte stapeln keinen Schaden endlos. Gesichter und HUD zeigen echte Zustände, Save/Resume bewahrt Tickzeiten und Eigenschaften. Effekte enden vor der Beutesammlung. Neu: Giftkeim mit Giftschuss-Fächer und Zahnfleischbeißer mit Blutungsansturm, eigene gemalte Sprites; Einführung, Häufigkeit, Stärke und Dauer skalieren mit Schwierigkeit. Spätere gewöhnliche Gegner und Eliten können eine erkennbare Statuseigenschaft tragen. [Regeln, Messwerte und Vorschau](docs/PLAYER_STATUS_EFFECTS.md).

- **Zahnflutsch:** neues Ausweichattribut mit höchstens 60 % effektiver Chance, eigenem Icon und vier Level-up-Stufen. Erfolgreiches Ausweichen bewahrt Schilde und lässt Denti zwinkern. Gleitwachs, Seidenwurzel, Flutschspülung, Lotusschmelz und das einmalige Mythic Unfassbare Wurzel erweitern den Pool auf 93 Items; Heilungs- und Schildsynergien haben begrenzte Auslösefrequenzen. Shop, Stats, Testmenü, Telemetrie und Save/Resume unterstützen das Attribut. [Werte und Vorschau](docs/DODGE.md).
- **Gesichtsausdrücke:** Denti reagiert auf Schaden, Heilung, wenig HP, Schildblock, Wellenabschluss und Tod. Gift-/Blutungsanzeigen zeigen die laufenden Effekte einzeln und kombiniert. [Animation und Anschluss](docs/DENTI_EXPRESSIONS.md).

- Goldextraktor-Icon: Armführung überarbeitet, linker Griff zur oberen rechten Backe; keine Klinge zwischen den Münzen. Zwei äußere Backen und vollständige Griffe ohne abgeschnittene Atlasränder. Die Goldsonde bleibt unverändert.

- **Endlosmodus:** nach dem Sieg in Welle 20 mit dem bestehenden Build weiterspielen. Ab Welle 21 dauern Wellen 60 Sekunden; die Brotato-Endloskurve verstärkt Gegner und Shoppreise. Mehr Elite- und Gegnerdruck, Doppelbosse in Welle 30/40/... und vollständiges Save/Resume. Der ursprüngliche Sieg bleibt erhalten. [Kurve, Messungen und Vorschau](docs/ENDLESS_MODE.md).

- Normale Gegner haben auf Normal 100 % Basis-Münzchance, mit Wellenabschwächung ab Welle 5 auf 70 % in Welle 20. Die bisherige zusätzliche niedrige Grundchance entfällt; XP bleibt unabhängig.
- **32 Shop-Items:** Goldsonde kann Münz-Drops verdoppeln und profitiert begrenzt von Glück; Goldextraktor gibt mehr Münzen aus Zucker und Eliten. Beide haben Nachteile, Stapellimits und neue gemalte Icons.
- **Level-up-Rerolls:** vier neue Angebote gegen Münzen, steigende Kosten pro Auswahl und Zurücksetzen beim nächsten verdienten Level. Meilenstein-Seltenheit und Save/Resume bleiben erhalten. [Messungen und Vorschau](docs/ECONOMY_BALANCE.md).

- Dentis Ausrüstung belegt **Wurzeln**: Shop, Waffenbeschreibungen, Fusion und Pausemenü verwenden „1 Wurzel“ beziehungsweise „2 Wurzeln“. Im Shop-Tooltip steht „ca.“ statt des von der Schrift nicht unterstützten „≈“-Zeichens vor dem DPS-Wert.

- Acht überarbeitete Waffengrafiken mit klareren Formen: Kronenwerfer, Mörser, Wasserflosser, Fluorid-Sprüher, Turbine, Schleuder, Fräse und Polierer. Separate Arbeitsflächen drehen sich bei stabiler Perspektive; die Schleuder spannt Gummibänder und Beutel statt den Griff zu verformen. Fernkampfwaffen erhalten passendere Ruhepositionen, die Zauberbürste steht aufrecht. [Bilder, Animation und Prüfung](docs/WEAPON_ART_REFINEMENT.md).

- Größenvergleich mit Denti und allen 18 Waffen als Screenshots in Ruhe und im Angriff. Bohrer, Kratzer, Peitsche, Garotte und Speer erhalten passendere Proportionen.
- Turbo-Bohrer: 60 statt 100 Pixel, 0,72 statt 1,28 Sekunden Angriffspause, 22 statt 33 Basisschaden und 100 statt 150 % Nahschaden-Skalierung. Schnellerer Takt und moderat höherer dauerhafter Schaden; Reichweite und Bossbonus bleiben erhalten.
- Nahe Gegner werden bei kurzen Rundum- und Bogenschnitten zuverlässiger getroffen. Zusätzliche Kontaktprüfungen für alle Stufen und Richtungen sichern die Reichweite kleinerer Waffen ab. [Vorschau und Messungen](docs/WEAPON_SIZE_BALANCE.md).

## 0.2.0 · Pressure + Build Depth — 01.10.2026

### Mehr Builds und Belohnungen

- **18 statt 8 Waffen:** Zahnstocher-Speer, Karies-Fräse, Interdental-Bürste, Fluorid-Sprüher, Mundduschen-Turbine, UV-Lampe, Amalgam-Schleuder, Zahnseiden-Garotte, Prophylaxe-Polierer und Fluorid-Rakete erweitern das Arsenal. Neue Angriffe bieten unter anderem Stichlinien, Frontbögen, Sprühkegel und durchdringende Strahlen. [Waffenübersicht](docs/waffen.md).
- **30 statt 18 Shop-Items:** mehr Kombinationen für Blutung, Wasser, Crit, Schild, Heilung, Projektile und Economy sowie Zucker-Builds mit Vor- und Nachteilen. [Itemübersicht](docs/items.md).
- **Zehn statt acht Stats:** Nahschaden und Fernschaden ergänzen Bisskraft. Waffen nutzen eigene Koeffizienten für diese Schadensboni.
- **Ununterbrochene Wellen:** Levelaufstiege werden im Kampf vorgemerkt. Nach dem Einsammeln aller verbliebenen Beute folgen die Level-up-Auswahl, Kapselentscheidungen und gegebenenfalls Bossrelikte; danach öffnet der Shop.
- **Seltene Upgrade-Kapseln:** Item behalten oder gegen Münzen zerlegen. Glück beeinflusst die Chancen innerhalb fester Grenzen; gewöhnliche Zufallskapseln sind auf einen Fund pro Welle begrenzt.
- **Fünf göttliche Relikte:** nach den Bossen in Welle 5, 10 und 15 jeweils eines von drei Angeboten wählen. Die Effekte unterstützen Blutung, Wasser, Schild, Crit und Bewegung. [Reliktübersicht](docs/relics.md).

### Kampf und Gegnerdruck

- Dichtere spätere Wellen, zeitlich variierende Gegnergruppen, zusätzliche Horden und wechselnde Gegnermischungen. Normale Wellen dauern je nach Fortschritt 35–50 Sekunden; Bosswellen bleiben bei 45 Sekunden.
- Zwei Elite-Gegnertypen: **Säurekrone** mit Projektilmustern und **Jagdkeim** mit Verstärkung und Tempo-Aura. Später erscheinen mehrere Elite-Gruppen; ein sichtbarer Schutz begrenzt extreme Schadensspitzen.
- Mehr angekündigte Angriffe: Zucker-Anstürme, Schussfächer, versetzte Projektilringe, parallele Bahnen und langsame Projektile zur Raumkontrolle.
- Eigene Bossränge und Grafiken: **Karies-Graf**, **Karies-Prinz**, **Karies-König** und **Karies-Imperator**. Schutzphasen, Verstärkung und zusätzliche Angriffe an Lebensschwellen geben ihren Mechaniken mehr Zeit und Gewicht.
- Überlebende Bosse werden nach Ablauf des Timers **Entzündet**. Eine animierte Aura passt sich der Bossgröße an und steigert Farbe und Intensität vom orangefarbenen Grafen bis zum violetten Imperator. Die Eskalation setzt sich beim Fortsetzen eines Runs korrekt fort. [Aura-Vorschau und Details](docs/BOSS_INFLAMMATION.md).
- Schwierigkeitsgrade **Easy, Normal und Hard**; **Hell** wird durch einen Sieg auf Hard freigeschaltet.
- Treffer-Unverwundbarkeit berücksichtigt die Höhe des erlittenen Schadens innerhalb begrenzter Werte. Waffen erhalten animierte Angriffe, Rückstoß und Treffereffekte.

### Stats und Economy

- **Bisskraft skaliert Schaden prozentual.** Nah- und Fernschaden erhöhen den gewichteten Basisschaden der jeweiligen Waffe. Härte reduziert eingehenden Schaden prozentual mit abnehmendem Zusatznutzen. Waffenwerte und Verteidigung wurden dazu neu abgestimmt. [Schaden und Verteidigung](docs/DAMAGE_DEFENSE_BALANCE.md).
- **Putzeifer und Bewegung verwenden additive Prozentboni.** Speichel zählt Regenerationspunkte und heilt einzelne HP in passenden Zeitabständen; die vorher sehr starke Regeneration wurde abgeschwächt. [Tempo und Regeneration](docs/STATS_BALANCE.md).
- Gold fällt unabhängig von XP und in frühen Wellen häufiger. Shoppreise steigen mit jeder Welle entlang der untersuchten Brotato-Kurve; gemerkte Angebote behalten ihren Preis. [Economy und Messungen](docs/ECONOMY_BALANCE.md).
- **Vier statt drei Angebote** im Shop und beim Levelaufstieg. Neue Nah-/Fernschaden-Boni berücksichtigen die passenden ausgerüsteten Waffen.
- Gleiche Waffen belegen bei freien Händen eigene Plätze. Manuelle Fusionen reichen bis Stufe IV; bei voller Ausrüstung kann ein passender Kauf direkt fusionieren. Verkäufe verlangen eine Bestätigung und erstatten einen Teil der ausgegebenen Münzen.

### Bedienung und Darstellung

- Kompakter, responsiver Shop: vier Angebote nebeneinander bei ausreichend Platz, angepasste Anordnung auf kleinen Bildschirmen und größere ausgerüstete Waffenplätze.
- Preis- und Merken-Buttons bleiben pro Ansicht an festen Positionen und haben einheitliche Größen. Ein Pin markiert gemerkte Angebote; Neu würfeln sitzt oben bei den Angeboten, der Startbutton unten rechts.
- Gesammelte Items und Relikte bleiben als Icons mit Anzahl sichtbar. Hover und Antippen zeigen Namen, Stats und Effekte.
- Der zusätzliche Wellenprofil-Text im Shopkopf entfällt; die Gegnermischungen bleiben aktiv.
- Touch-Joystick und angepasste Menüs für mobile Geräte, einschließlich kleiner Querformat-Ansichten.
- Eigene gemalte Icons für alle zehn Stats; Glanz und Zahnglück sind unterscheidbar. Level-up-Icons passen vollständig in ihre Karten.
- Waffenvergleiche zeigen die aktuellen Buildwerte. Mehrere Darstellungs- und Zeichensatzprobleme wurden behoben.

### Korrekturen, Spielstände und Entwicklung

- **Seltenheit bei mehreren vorgemerkten Levelaufstiegen korrigiert:** Ein Sprung von Level 8 auf 10 wertet die Auswahl für Level 9 und 10 getrennt aus. Der garantierte Bonus eines Meilensteins gilt nur für den jeweiligen Levelaufstieg.
- Speichern/Fortsetzen bewahrt unter anderem ausstehende Belohnungen, Relikte, Schwierigkeitsgrad, Wellenlänge, gemerkte Angebote und Boss-Eskalation. Alte Statwerte werden in das neue Modell umgerechnet; die Versionsanhebung erfordert keinen Spielstand-Reset.
- Kampf-Telemetrie im Debug-Build zeigt DPS, Kills pro Sekunde, Gegnerdruck, Schaden, Boss-Kampfzeit und Economy. Der Run-Rückblick fasst Sieg oder Niederlage zusammen; JSON-Berichte erleichtern Balance-Vergleiche.
- Lokales Debug-Menü zum gezielten Testen von Waffen, Items, Stats und Wellen. Die automatisierte Testsuite wurde auf 46 Tests für Gameplay, Belohnungsablauf, Spielstände und UI erweitert.

## 0.1.0 · Spielbare Grundlage — 29.09.2026

Rückblickend dokumentierter Stand beim Einführen der Versionsanzeige ([Commit 197b5d8](https://github.com/othaldo/denti/commit/197b5d8)).

- Manuelle Bewegung und automatische Angriffe in einer scrollenden Arena.
- 20 Wellen zu je 45 Sekunden, vier normale Gegnertypen und Bosskämpfe in Welle 5, 10, 15 und 20.
- Acht Waffen mit Handkosten und Fusionen bis Stufe IV, 18 stapelbare Shop-Items und acht Level-up-Stats.
- Drei Shopangebote und drei Level-up-Boni; Seltenheit, Glück, Neu würfeln, Waffenverkauf und buildabhängige Shopgewichtung.
- Beute wird am Wellenende eingesammelt. Level-up-Auswahlen unterbrechen zu diesem Zeitpunkt noch den Kampf.
- Hauptmenü, Pause, Optionen, automatische Spielstände und Fortsetzen.
- Musik, Kampfgeräusche, Lautstärkeregler und optionale FPS-Anzeige.
- Automatisierte Tests sowie Godot-Web-Export und Veröffentlichung auf GitHub Pages.
