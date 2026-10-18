# Denti — Roadmap

Stand: **18.10.2026**, auf Basis des spielbaren Stands 0.5.0 und der anschließenden Refactorings und UI-Korrekturen. Die folgenden Ausbaustufen sind **geplant**. Zahlenwerte sind Startwerte für Prototypen und werden erst nach Messung und Spieltests festgelegt.

Das nächste Ziel: ein kompakteres Kampf-HUD, eine bewusste Dash-Entscheidung, vier eigenständige Bosskämpfe und mehr unterschiedliche Starts. Denti darf sehr mächtig werden; Positionierung, freie Wege und lesbare Gefahren sollen trotzdem wichtig bleiben.

## Vorhandene Grundlage

- 20 Wellen, anschließend optional Endlos; Bossabschlüsse in Welle 5, 10, 15 und 20. Wellenlängen variieren, Bosswellen dauern vor der Entzündung 45 Sekunden.
- Vier Story-Areas mit Dialogen und Ortswechseln: **Unter dem Kissen**, **Das süße Verderben**, **Tief im Säurestrom**, **Die letzte Krone**.
- 18 reguläre Waffen, sechs geheime Evolutionen, 93 Shop-Items, fünf Relikte und elf Grundattribute. Startwaffen sind bisher Zauberbürste, Turbo-Bohrer und Wasserflosser.
- Ununterbrochener Kampf; danach Beutesammlung, Levelaufstiege, Upgrade-Kapseln, gegebenenfalls Relikt und Story-Übergang, anschließend Shop. Dieser Ablauf bleibt erhalten.
- Gegnerdruck, Projektilmuster, Bossphasen und Entzündung sind vorhanden. Die vier Bosse teilen aber weiterhin den wesentlichen Kampfablauf; andere Projektile und mehr Salven reichen als Unterscheidung noch nicht aus.
- Telemetrie, Run-Rückblick, Speichern/Fortsetzen und automatisierte Tests bilden die Grundlage für weitere Änderungen. Shopgrößen und Atlas-Ausschnitte wurden zuletzt korrigiert; entsprechende Layoutgrenzen sollen auch im Kampf gelten.

Details zum Iststand: [README](../README.md), [Story-Modus](STORY_MODE.md), [Waffen](waffen.md), [Items](items.md), [Codebase-Review](CODEBASE_REVIEW.md). Die ausführliche frühere Planung bleibt im [historischen Planungsstand](ROADMAP_V02.md) erhalten.

## Prioritäten

| Priorität | Vorhaben | Ergebnis |
| --- | --- | --- |
| P0 | Kampf-HUD vereinheitlichen | Gleich hohe Ressourcenleisten und ein kompakter Timer ohne springendes Layout |
| P1 | Wurzelkraft und Dash | Eine gezielte Bewegung mit einer Ladung, eigener Erholung und verbindlichem Cooldown |
| P1 | Vier Bossidentitäten | Jeder Story-Abschluss verlangt eine andere Positionierungsentscheidung |
| P2 | Alle Standardwaffen als Starts | Kompaktes Iconraster mit Details und ausdrücklicher Auswahlbestätigung |
| Danach | Synergien und Feinschliff | Begrenzte Dash-Synergien, eventuell Cooldown-Reduktion und Balance aller Starts |

Jede Stufe wird einzeln umgesetzt, getestet und gespielt. Bossumsetzung erfolgt pro Encounter; der spielbare Build bleibt während der Überarbeitung erhalten.

## 1. Kampf-HUD: feste Maße, weniger belegte Fläche

### HP, XP und später Wurzelkraft

Aktuell reserviert die Szene 31 Pixel für HP und 22 Pixel für XP. Icons, Schrift und Abstände sind ebenfalls unterschiedlich. Daraus soll eine gemeinsame Ressourcenzeile entstehen:

- HP und XP erhalten dieselbe sichtbare Leistenhöhe, Breite, Iconfläche, Innenabstände und Textausrichtung. Startwert: **28 logische Pixel Höhe**, Iconfläche 24 Pixel; eine kompakte Variante skaliert beide gemeinsam.
- Wurzelkraft verwendet später dieselbe Zeilenkomponente. HP bleibt durch Farbe und Gewichtung sofort erkennbar; Ressourcen unterscheiden sich zusätzlich durch Icon und Beschriftung.
- Werte stehen innerhalb ihrer reservierten Flächen. Schildladungen, große HP-Zahlen und vorgemerkte Level vergrößern keine Leiste. Zusätzliche Informationen erhalten feste Plätze oder stehen in den Stats.
- Statusanzeigen werden unter dem tatsächlichen Ressourcenblock angeordnet. Sie dürfen bei einer zusätzlichen Leiste weder den Block noch das Spielfeld unkontrolliert überlagern.

### Timer oben in der Mitte

Das derzeitige übereinander angeordnete Paket aus Welle, Timer, Kapselzähler und Bossanzeige wird entzerrt:

- Im normalen Kampf eine kompakte Zeile: **`Welle 12 · 0:27`**. Zielhöhe inklusive Rahmen: höchstens 44 logische Pixel im Standardlayout.
- Der Kapselzähler zieht in die bestehende Münz-/Levelzeile und erhält dort einen festen Platz. Er braucht keine eigene Zeile unter dem Timer.
- Bossname und Bossleben erhalten einen eigenen schmalen Bereich unter der Timerzeile. Der Timer behält seine Maße. Lange Namen kürzen die Darstellung, ohne die volle Information in Pause/Details zu verlieren.
- Entzündung ersetzt den Zeitwert durch eine kurze Anzeige wie **`Entzündet +12 s`** innerhalb desselben reservierten Bereichs. Warnfarbe und Icon ergänzen den Text; eine größere Schriftbox ist dafür unnötig.
- Für zwei Endlosbosse gibt es eine explizite kompakte Anordnung mit höchstens zwei Bossleisten. Der normale Timerbereich wächst dadurch nicht weiter.
- In schmalen Ansichten ordnet ein gemeinsames HUD-Layout die Bereiche ohne Überschneidungen an. Pause, FPS, Statusanzeigen und Touchsteuerung werden dabei berücksichtigt.

**Abnahme:** HP- und XP-Leisten sind pixelgleich hoch. Zahlenwechsel, erste Kapsel, Schild und Entzündung verändern ihre Geometrie nicht. Timer und Bossleisten bleiben bei 320×568, 568×320, 720×1280, 1040×600, 1280×720 und 1920×1080 im sichtbaren Bereich. Automatische Layoutprüfungen werden durch native Aufnahmen mit großen Zahlen, langen Bossnamen und aktivierter Touchsteuerung ergänzt.

## 2. Wurzelkraft und Dash

### Name und Attribut

**Wurzelkraft** ist der Arbeitsname für Dentis Stamina. Er passt zu seiner Bewegung auf Wurzeln und lässt sich kurz beschriften. Der aktive Move heißt zunächst **Dash**, mit dem möglichen Anzeigenamen **Wurzelsprung**.

Es gibt eine Ressource und einen investierbaren Wert:

- **Wurzelkraft:** feste Kapazität von 100; jeder Dash verbraucht die gesamte Ladung. Teilfüllung erlaubt keinen Dash. Es gibt zunächst weder zusätzliche Ladungen noch ein Upgrade auf die Kapazität.
- **Wurzelkraft-Erholung:** das neue Grundattribut erhöht die Nachladerate additiv in Prozent. Beispiel: `+25 % Erholung` verkürzt die reine Auffüllzeit von 4 auf 3,2 Sekunden. Stats und Level-up-Text zeigen neben dem Bonus die resultierende Auffüllzeit.
- Das Attribut wird in denselben Statkatalog wie die elf vorhandenen Werte aufgenommen und über Levelaufstiege sowie ausgewählte Items angeboten. Bestehende Einträge behalten ihre IDs.
- **Speichel** regeneriert weiterhin Leben; **Zahnflutsch** bleibt die passive Ausweichchance. Beide bleiben mechanisch von Wurzelkraft getrennt.

Die feste Kapazität verhindert, dass ein vermeintliches Kapazitätsupgrade die Wartezeit bis zur zwingend vollen Ladung verlängert. Build-Investition verbessert gezielt die Erholung.

### Verbindliche Ablaufregeln

1. Ein Dash startet nur im aktiven Kampf, bei voller Wurzelkraft und abgelaufenem Cooldown. Boss-Entzündung zählt zum aktiven Kampf.
2. Desktop-Auslöser ist eine neue Eingabeaktion `dash`, zunächst auf **Shift**. Gedrückthalten löst keinen weiteren Dash aus; es gibt keine automatische Wiederholung oder wartende Dash-Eingabe.
3. Die Richtung wird beim Auslösen festgelegt: aktuelle Bewegungsrichtung, sonst letzte Bewegungsrichtung, vor der ersten Bewegung nach unten. Mausziel und automatische Waffen ändern sie nicht.
4. Der Dash bewegt Denti kurz und geradlinig. Startwerte: **150 Welteinheiten in 0,16 Sekunden**. Bewegungstempo erhöht zunächst weder Strecke noch Dauer; Diagonalen sind gleich schnell.
5. Die Ladung fällt beim Start auf null. Nach dem Dash und einer kurzen Erholungspause lädt sie kontinuierlich nach. Bewegung und Schaden setzen den Ladefortschritt nicht zurück.
6. Ein neuer Dash braucht **beides**: volle Ladung und abgelaufenen Cooldown. Ein volles Ressourcenfeld bei noch laufendem Cooldown zeigt die verbleibende Sperre; „bereit“ erscheint erst bei erfüllten Bedingungen.
7. Ungültige Eingaben verbrauchen nichts. Ein gestarteter Dash, der an einem Hindernis endet, verbraucht seine Ladung und erhält keine Erstattung.
8. Vor der ersten Welle und beim tatsächlichen Start einer neuen Welle ist die Ladung voll und der Cooldown frei. Menü, Pause, Shop-Aufruf oder Laden eines laufenden Kampfes geben keine zusätzliche Ladung.

### Startwerte und Begrenzung

| Parameter | Prototyp |
| --- | ---: |
| Kapazität / Kosten | 100 / 100 |
| Dashdauer / Strecke | 0,16 s / 150 Welteinheiten |
| Erholungspause nach Dashende | 0,35 s |
| Basis-Nachladerate | 25 pro Sekunde; reine Auffüllzeit 4 s |
| Cooldown ab Dashstart | 1,5 s |
| Wirksamer Erholungsbonus | zunächst 0 bis +400 % |

Ohne Blockierung gilt zwischen zwei Dashstarts:

```text
Auffüllzeit = 4 s / (1 + wirksamer Erholungsbonus / 100)
Frühester nächster Dash = max(Cooldown, Dashdauer + Erholungspause + Auffüllzeit)
```

Bei den Startwerten sind das rund **4,51 s** ohne Bonus, **2,51 s** bei +100 % und **1,50 s** bei +400 %. Der Cooldown begrenzt also auch einen stark ausgebauten Erholungswert. Über dem wirksamen Limit wird kein weiterer Erholungsbonus angeboten.

**Cooldown-Reduktion bleibt eine spätere Erweiterung.** Zuerst wird geprüft, ob schnellere Erholung allein genug Build-Entscheidungen schafft. Falls nötig, reduzieren wenige seltene Items den separaten Cooldown, mit einer absoluten Untergrenze von zunächst **1,0 s**. Sie ändern weder Ladungskosten noch die Bedingung „voll geladen“ und werden im HUD gemeinsam mit der Erholung erklärt.

### Dash durch Gegner bleibt gefährlich

Der Dash dient dazu, einen noch freien Weg rechtzeitig zu nutzen. Er räumt keine Horde weg und verleiht **keine zusätzlichen Unverwundbarkeitsframes**, keine Unberührbarkeit, keinen Rückstoß und keinen eigenen Schaden.

- **Körperkontakt mit einem lebenden Gegner stoppt den Dash am ersten Kontakt.** Denti landet vor dessen Körper, niemals auf der anderen Seite. Wände und Arenagrenzen begrenzen ihn ebenfalls.
- Beginnt Denti bereits überlappend in einer Horde, schafft der Dash keinen Fluchtweg durch diese Gegner. Vorhandene Schilde, passive Ausweichchance und laufende Trefferpausen heben die Bewegungsblockierung nicht auf.
- Kontakt wird entlang der gesamten bewegten Strecke geprüft. Ein hoher Dashspeed oder ein langsamer Frame darf weder Gegner noch Projektile oder aktive Schadensflächen überspringen.
- Bei Kontakt greift die normale Schadensverarbeitung einschließlich Härte, Schild, Zahnflutsch und bereits bestehender Trefferpausen. Der Dash setzt diese Schutzmechanismen weder neu noch verlängert er sie. Laufendes Gift und Blutung ticken weiter.
- Der Kontakt erzeugt höchstens einen unmittelbaren Treffer über den vorhandenen Schadensweg; die normale Gegnerberührung darf denselben Kontakt nicht noch einmal abrechnen.
- **Zusätzlicher Kontaktschaden ist eine gezielte Playtest-Variante:** Ausgangswert +25 % auf den beim Dash-Kontakt ausgelösten Treffer, vor Härte. Die erste Variante testet zunächst Stopp plus normalen Schaden. Nur falls Horden dadurch noch zu leicht umgangen werden, wird der Aufschlag aktiviert. Er erhöht weder sämtliche Projektile noch laufenden Statusschaden.

Ein Kontaktstopp mit verlorener Ladung bestraft schlechte Planung bereits deutlich. Ein zusätzlicher Schadensaufschlag braucht deshalb einen erkennbaren Nutzen im Spieltest und verständliches Feedback.

### Mobile Steuerung

- Ein eigener **Dash-Button unten rechts**, zunächst 64×64 logische Pixel, mindestens 56×56 im kompakten Layout. Er berücksichtigt Bildschirmränder, Pause und andere Bedienelemente; im Stillstand gilt dieselbe Richtungsregel wie am Desktop.
- Der Bewegungsfinger behält seine Geste. Ein zweiter Finger kann Dash drücken, ohne den Joystick-Ursprung oder die Bewegungsrichtung zu übernehmen. Die Buttonfläche startet selbst keine Bewegungsgeste.
- Der Button zeigt den Füllstand als Ring und die Einsatzbereitschaft durch Form/Icon plus Farbe. Bei vollem Ring und noch aktivem Cooldown bleibt die Sperre sichtbar.
- Ungültiges Antippen startet keine spätere Aktion. Pause, Fokusverlust, Fingerfreigabe und Bildschirmdrehung hinterlassen keine festhängende Eingabe.
- Swipe und Doppeltippen werden erst nach Touch-Spieltests als optionale Alternativen bewertet. Der erste Prototyp verwendet den klar erreichbaren Button.

### Integration und Abnahme

Die Dash-Logik erhält eine kleine eigene Bewegungskomponente. `PlayerStats` bleibt die Quelle des Erholungsbonus; HUD und Touchbutton lesen denselben Dash-Zustand. Werte liegen in einer gemeinsamen konfigurierbaren Ressource.

Speichern/Fortsetzen erhält Ladung, Cooldown, Erholungspause und bei aktivem Dash Richtung sowie Restdauer. Alte Saves starten mit Basis-Erholung und einer vollen Ladung; bestehende Zahlen-IDs der Attribute bleiben kompatibel. Pausierte Spielzeit und Offlinezeit laden den Dash nicht nach. Beim Laden einer Bewegung wird die verbleibende Strecke wieder regulär auf Kontakt geprüft.

**Abnahme:** Tests für volle/teilweise Ladung, gleichzeitige Sperren, gehaltenes Shift, Diagonalen, Randkontakt, Start innerhalb einer Horde und Kontakt trotz Schild/Dodge/Trefferpause. Streckenprüfungen decken auch Projektile und Schadensflächen bei längeren Frames ab. Dazu Pause/Fortsetzen mitten im Dash und Cooldown, alte Saves, Mehrfingereingabe und Drehung des Displays. Telemetrie erfasst Dashanzahl, Kontaktabbrüche und Schaden während des Dashs; normale Spielanzeigen bleiben kompakt.

## 3. Vier Story-Areas, vier unterschiedliche Bosskämpfe

Die Herrschertitel und ihre Storyfunktion bleiben erhalten. Jeder Boss erhält eine eigene Silhouette, ein eigenes Bewegungsverhalten, einen charakteristischen Angriffsablauf und eine andere Antwort des Spielers. Die folgende Matrix beschreibt die geplante Identität, keine bereits vorhandenen Angriffe.

| Area / Boss | Kampfidee | Typische Antwort |
| --- | --- | --- |
| Unter dem Kissen / Karies-Graf | Kissenstürze und wandernde Falten bilden angekündigte Bahnen | Freie Bahn lesen, rechtzeitig die Seite wechseln |
| Das süße Verderben / Karies-Prinz | Geworfene Zuckerbomben hinterlassen begrenzte Karamellfelder | Freien Boden erhalten, Ablageorte der Bomben planen |
| Tief im Säurestrom / Karies-König | Säureströme verändern vorhersehbar die sicheren Ufer | Nächste sichere Position vorausplanen |
| Die letzte Krone / Karies-Imperator | Eine gerichtete Kronenwache und wechselnde Hofsektoren | Verwundbare Seite erreichen und sichere Sektoren nutzen |

### Karies-Graf: Herr unter dem Kissen

- Der Graf kämpft an wenigen gut sichtbaren Positionen. Er markiert einen breiten Kissensturz als Rechteck auf dem Boden; erst danach schlägt das Kissen ein.
- Nach dem Einschlag wandert eine klar angekündigte Falte durch eine Bahn. Eine benachbarte Bahn bleibt frei. Die Spielerentscheidung ist ein Seitenwechsel statt dauerhaftes Kreisen um den Boss.
- Eine spätere Phase lässt zwei versetzte Stürze folgen. Sie überlappen zeitlich so, dass ein lesbarer Weg bestehen bleibt; es gibt immer eine Erholungspause mit erreichbarem Boss.
- Optische Richtung: Kissenumhang, Stofffalten und verlorene Zahnfee-Münzen. Kleine Staub-/Krümelgruppen können Druck geben, ersetzen aber den Kissenablauf nicht.

**Abnahme:** Schon der erste Angriff erklärt das Bahnenprinzip. Ein Basis-Denti kann jede Folge mit normaler Bewegung lösen. Reihenfolge und Rhythmus sind erkennbar anders als die bisherigen Charge-/Ringkombinationen.

### Karies-Prinz: Die Karamellküche

- Der bewegliche Prinz wirft Zuckerbomben auf zuvor markierte Spielerpositionen. Nach dem Einschlag bleiben zeitlich begrenzte, verlangsamende Karamellfelder zurück; die Flugbahn und Landefläche sind sichtbar.
- Denti kann neue Felder bewusst an Rändern ablegen. Es gelten eine feste Obergrenze für aktive Felder und eine feste Lebensdauer; der Boden kann nicht dauerhaft vollständig verkleben.
- Später wirft der Prinz kurze Bombenfolgen und lässt zerstörbare Zuckerkerne wachsen. Ein zerstörter Kern verhindert den nächsten lokalen Karamellguss und schafft eine bessere Angriffsgelegenheit.
- Kerne sind optionale Kontrollziele, keine Pflicht für Schaden am Boss. Automatische Waffen müssen sie zuverlässig erfassen können; ein bestimmter Waffentyp wird nicht vorausgesetzt.
- Optische Richtung: Zuckergusskrone, Karamellkessel und Bonbonwürfe. Klebeflächen und gefährliche Einschläge haben unterschiedliche Markierungen.

**Abnahme:** Feldobergrenze und Ablauf verhindern Sackgassen. Keine Fläche erscheint sofort aktiv unter Denti. Der Kampf lässt sich auch ohne Kernzerstörung gewinnen; gezieltes Freihalten von Boden lohnt sich sichtbar.

### Karies-König: Der Säuresammler

- Der König steuert Säurerinnen durch die Arena, statt selbst ständig anzustürmen. Die Ströme wandern langsam entlang angekündigter Routen; sichere Ufer bleiben erreichbar.
- Ein sichtbarer Pegel kündigt einen Richtungswechsel an. Alte Rinnen laufen aus, bevor der nächste gefährliche Abschnitt entsteht. Säure verursacht Schaden über den normalen Gefahrenpfad; ein Dash bietet keinen Schutz davor.
- Während der König seinen Vorrat abgibt, öffnet sich ein klares Angriffsfenster. Eine spätere Phase verzweigt die Rinnen und verschiebt sichere Flächen, ohne alle Wege gleichzeitig zu schließen.
- Optische Richtung: säuregefüllte Herrscherinsignien und Zahn-Trophäen als sichtbare Leitpunkte. Seine Sammlerrolle aus dem bestehenden Dialog erhält damit eine Entsprechung in der Arena.

**Abnahme:** Der Spieler kann den nächsten sicheren Ort vor dem Umschalten erkennen. Spawnpositionen, Randkontakt und langsamere Builds behalten eine Route. Mobile Ansichten zeigen Strömungsrichtung und Vorwarnung ebenso klar wie Desktop.

### Karies-Imperator: Das Kronengericht

- Der Imperator besitzt eine erkennbare gerichtete Kronenwache: geschützte Vorderseite, verwundbare Seiten beziehungsweise Rückseite. Die Orientierung wechselt angekündigt; Schutz bedeutet Schadensreduktion, keine unbegrenzte Immunität.
- Ein Erlass markiert Hofsektoren, die nacheinander gefährlich werden. Denti sucht einen sicheren Sektor, von dem aus zugleich ein günstiger Angriffswinkel erreichbar ist.
- In späteren Phasen dreht sich die Kronenwache zwischen den Erlassen. Die abschließende Phase verbindet höchstens zwei dieser eigenen Mechaniken und öffnet deutliche Gegenangriffsfenster.
- Optische Richtung: große bewegliche Kronensegmente, Zepter und die Portal-/Gefängnismagie der Zahnfee. Die Arena und ihre Warnungen tragen den Kampf; der Imperator ist mehr als eine dichtere Version der ersten drei Bosse.

**Abnahme:** Die verwundbare Seite ist mit automatischen Nah- und Fernwaffen nutzbar. Kein Erlass zwingt zur Passage durch einen Gegner. Ein erlaubter sicherer Sektor bleibt auch bei laufender Kronendrehung rechtzeitig erreichbar.

### Gemeinsame Regeln, eigenständige Abläufe

- Vorwarnung, Bewegung und aktive Gefahr sind klar unterscheidbar. Alle Encounter bleiben mit Grundbewegung und ohne Dash-Upgrades lösbar. Wurzelkraft schafft Handlungsspielraum und wird nicht zur Pflichtinvestition.
- Phasen verändern Verhalten und sichere Räume. Die Anzahl der Phasen und ihre Auslöser werden pro Boss definiert; es gibt keinen vorgeschriebenen identischen Ring-/Charge-Zyklus für alle vier.
- Verstärkung unterstützt die Mechanik und besitzt ein eigenes Mengenlimit. Bossangriff, normale Wellengegner und Telegraphe dürfen zusammen keine unlösbare Situation erzeugen.
- Angestrebte Kampfzeiten auf Normal mit einem mittleren Build: ungefähr **20–40 Sekunden** für die ersten drei Bosse, **35–55 Sekunden** für den Imperator. Das sind Messziele. Starke Builds dürfen deutlich schneller sein; zusätzliche starre Mindestkampfzeiten werden daraus nicht abgeleitet.
- Die bestehende Entzündung beginnt weiterhin nach der Bosswellenzeit. Neue Mechaniken erhalten passende Eskalationen mit begrenzter gleichzeitiger Gefahr; Vorwarnung und erreichbare Wege bleiben erhalten. Falls normale Builds regelmäßig erst tief in der Entzündung gewinnen können, werden Encounter und Zeitbudget gemeinsam nachjustiert.
- Die Story-Area bestimmt das Bossprofil. Freier Run und Endlos verwenden dieselben Profile über ihre Wellenzuordnung. Zwei Endlosbosse koordinieren Flächen und Warnungen, statt unabhängig sämtliche sicheren Wege zu schließen.
- Neue Grafiken erweitern die vorhandene gemalte Bildsprache. Originalreferenzen und bestehende Art bleiben erhalten; Attacken und Silhouetten werden vor aufwendigen Effektvarianten lesbar gemacht.

### Technische Umsetzung und Messung

Die vorhandenen Systeme für Projektile, Warnungen, Schaden, Bossanzeige und Encounter-Abschluss werden weiterverwendet. Eigene Verhaltenskomponenten pro Boss steuern den Ablauf; Resource-Profile enthalten Zeiten, Grenzen und Phasenwerte. Ein gemeinsamer Controller wächst dadurch nicht zu einer Sammlung aller Boss-Sonderfälle.

Speichern/Fortsetzen bewahrt aktive Angriffsschritte, Warnzeiten, Orientierung, Flächen, Feldlebensdauer und Entzündung. Laufende alte Boss-Saves benötigen einen ausdrücklich versionierten Übergang; eine gespeicherte Warnung darf beim Laden nicht zu einem sofortigen neuen Angriff werden. Bossgebundene Gefahren werden bei Tod/Encounter-Ende zuverlässig entfernt, bevor Belohnungen beginnen.

Pro Boss werden TTK, Schaden nach Angriffsquelle, Treffer während Vorwarnung/aktiver Phase, aktive Gefahren und Dash-Nutzung ausgewertet. Geprüft werden schwache, mittlere und starke Builds, Nah-/Fernkampf, langsame Bewegung, verschiedene Schwierigkeiten und zwei Bosse im Endlosmodus. Native Aufnahmen und Spieltests unter hoher Effektdichte ergänzen automatische Ablauf-, Kollisions- und Save-Tests.

## 4. Alle Standardwaffen als Startauswahl

**Alle aktuell 18 Standardwaffen sind von Anfang an auswählbar.** Die Auswahl liest den regulären Waffenkatalog; eine zusätzliche begrenzte Starterliste entfällt. Künftige Standardwaffen erscheinen ebenfalls dort. Geheime Evolutionen gehören weiterhin zu ihrer eigenen Progression und erscheinen nicht als Starts.

### Ablauf: Icon → Details → Bestätigung

1. Ein kompaktes Raster zeigt die vorhandenen Waffenbilder als kleine Icons. Die Reihenfolge bleibt stabil; Namen können als kurze Beschriftung oder Tooltip ergänzt werden.
2. Ein Klick beziehungsweise Antippen markiert das Icon und öffnet die Details der Waffe. Weitere Icons wechseln die Vorschau, ohne eine Waffe zu vergeben oder den Kampf zu starten.
3. Die Detailansicht zeigt Bild, Namen, Rolle, Wurzelkosten, Schaden, Angriffspause, Reichweite und besondere Effekte. Grundlage sind die tatsächlichen Mk-I-Startwerte.
4. Erst **„Mit dieser Waffe starten“** bestätigt die Auswahl, vergibt genau diese Waffe und startet Welle 1. Bis eine Waffe angeklickt wurde, ist die Bestätigung deaktiviert.

### Layout und Bedienung

- Desktop: Iconraster mit Detailbereich daneben und fest erreichbarer Bestätigung.
- Mobile: mehrere Spalten mit kleinen Bildern und ausreichend großen Touchflächen; Zielgröße mindestens 48×48 logische Pixel pro Iconbutton. Die Anzahl der Spalten folgt der verfügbaren Breite.
- Bei wenig Platz stehen die Details unter dem Raster oder in einer eigenen Detailansicht mit Rückweg zur Auswahl. Scrollen bleibt auf den Inhaltsbereich begrenzt; die Bestätigung bleibt erreichbar.
- Ausgewähltes Icon und Detailansicht stimmen jederzeit überein. Lange Namen und Beschreibungen verändern weder Icongrößen noch die äußeren Fenstergrenzen. Details sind auch ohne Hover vollständig erreichbar.

### Startwerte und Balance

- Jede Auswahl beginnt mit genau einer normalen Mk-I-Waffe, ohne Zufallsrollen oder Verzauberungen. Wurzelkosten bleiben unverändert. Alle Standardwaffen sind ohne Freischaltung oder vorherigen Sieg verfügbar.
- Die ersten drei Wellen auf Normal werden mit jeder Waffe geprüft, einschließlich langsamer Flächen- und Unterstützungswaffen. Schwache Starts erhalten gezielte Balanceanpassungen; die Auswahl wird dadurch nicht wieder auf eine Teilmenge eingeschränkt.
- Eine noch unbestätigte Vorschau wird beim Speichern als Auswahlzustand behandelt. Fortsetzen darf daraus keine bereits ausgerüstete Waffe machen; nach bestätigtem Start wird keine zweite Waffe vergeben.
- Optional später: „Zufällig“ aus allen Standardwaffen. Auch eine zufällige Vorschau braucht die Bestätigung und bleibt beim Fortsetzen stabil.

**Abnahme:** Das Raster enthält jede Standardwaffe genau einmal und keine Evolution. Alle Icons und vollständigen Details sind bei den HUD-Testauflösungen erreichbar. Ein Iconklick vergibt nichts; die Bestätigung übernimmt genau die angezeigte Waffe. Doppelklicks, Intro, Neustart und Fortsetzen starten Welle 1 genau einmal. Frühe Überlebensrate, erlittene Treffer und erste Kaufmöglichkeiten werden pro Starter verglichen.

## Umsetzung in spielbaren Schritten

| Schritt | Lieferumfang | Prüfung vor dem nächsten Schritt |
| --- | --- | --- |
| 1 | Gemeinsame HP-/XP-Zeile, kompakter Timer, getrennte Bossanzeige | Größen, Textgrenzen, Statusanzeigen, sechs Auflösungen und native Bilder |
| 2 | Dash-Basis inklusive Touchbutton, Kontaktstopp und Save/Resume | Eine Ladung, beide Sperren, keine neuen Schutzframes, vollständige Streckenprüfung |
| 3 | Erholungsattribut, wenige passende Angebote und Telemetrie | Wartezeiten, Stat-/Save-Kompatibilität, maximaler Bonus, Vergleich mit/ohne Investition |
| 4 | Karies-Graf als erster eigener Encounter | Bahnenprinzip, Bossabschluss, Alt-Saves, Nah-/Fernkampf und Mobile |
| 5 | Karies-Prinz, dann Karies-König, dann Karies-Imperator | Je Boss erst eigener Ablauf samt Grenzen und Tests, dann nächster Encounter |
| 6 | Alle 18 Standardwaffen im Iconraster mit Details und Bestätigung | Vollständiger Katalog, Auswahlablauf, frühe Wellen und UI pro Start prüfen |
| 7 | Balance aller Starts und gegebenenfalls Dash-Cooldown-Items | Endlos-/Schwierigkeitsvergleich wiederholen |

Nach Schritt 3 wird geprüft, ob Dash die bisherige Gegnerdichte zu stark entwertet. Nach jedem Boss folgt ein eigener Druck-/TTK-Vergleich. Mehr HP und zusätzliche Projektile ersetzen diese Prüfung nicht.

## Weiterer Backlog

- **Build-Tiefe:** Zusätzliche Items nur mit klarer Wechselwirkung. Blutung, Nässe/Elektro, Crit/Weihe, Schild/Vergeltung, Heilung, Ökonomie und Zucker-Risiko bleiben die Build-Familien. Der frühere Mengenplan „30–35 Items“ ist mit 93 Items überholt.
- **Dash-Synergien:** Nach der Basis etwa begrenzte Erholung durch tatsächliche Schildblocks oder ein Zucker-Item mit schnellerer Erholung und klarer Gegenleistung prüfen. Keine automatischen Vollaufladungen durch jede Tötung, keine endlosen Proc-Ketten und kein Durchqueren von Gegnern durch ein Item.
- **Gegnerdruck:** Dichte, gemischte Rollen, Burst-Rhythmus und Projektilräume weiter messen. Neue Bossmechaniken und Dash werden gemeinsam mit den vorhandenen Drucksystemen getestet.
- **Risiko-/Belohnungswellen:** Freiwillig erschwerte Wellen mit vorher sichtbaren Zusatzbelohnungen. Auswahl bleibt zwischen Wellen.
- **Meta und weitere Inhalte:** Zusätzliche Arenen und neue Entscheidungen. Standardwaffen bleiben vollständig als Starts verfügbar. Schwierigkeit, Story, Endlos, Relikte und Evolutionen sind bereits vorhanden und werden weiter abgestimmt.
- **Run-Rückblick und Telemetrie:** Bestehende gemeinsame Messung um Dash und Boss-Angriffsquellen ergänzen. Direkte Waffen-, Item- und Proc-Schäden bleiben getrennt und werden nicht doppelt gezählt; Werte überleben Fortsetzen.
- **Performance und Lesbarkeit:** Neue Flächen, Kollisionsprüfungen und Bossdarstellung unter hoher Gegnerzahl sowie im Web-Build messen. Warnungen bleiben auch unter Waffen- und Verzauberungseffekten sichtbar.

## Leitplanken

1. Gewöhnliche Gegner dürfen unter einem starken Build schnell sterben. Gefahr entsteht durch Positionierung, Dichte, Rollen und Angriffe.
2. Jeder Boss verändert, worauf der Spieler achten und wie er sich bewegen muss.
3. Dash belohnt einen freien Weg und gutes Timing. Gegnerkontakt bleibt ein Hindernis.
4. Grundmechaniken funktionieren ohne Pflicht-Item, Pflicht-Starter oder Pflicht-Dash-Investition.
5. UI-Komponenten haben feste Zustandsgrenzen; Inhalte dürfen ihre Umgebung nicht unerwartet vergrößern.
6. Kampf bleibt ununterbrochen. Beute und Pflichtentscheidungen werden nach der Welle abgearbeitet.
7. Stats, Ablauf und Speichern haben jeweils eine maßgebliche Quelle; neue Systeme verwenden klare Schnittstellen.
8. Jede Ausbaustufe wird implementiert, getestet, gespielt und gemessen, bevor die nächste mehr Komplexität hinzufügt.
