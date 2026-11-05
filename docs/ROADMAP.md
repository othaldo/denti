# Denti — Roadmap

Stand: **22.10.2026**, auf Basis des spielbaren Stands 0.5.0 und der anschließenden Refactorings und UI-Korrekturen. **Kampf-HUD, Dash-Prototyp und alle vier eigenständigen Boss-Encounter sind umgesetzt**. Menschliche Druck-/Balance-Playtests mit echten Nah-/Fernkampf-Builds und vollständigen Wellen sind die nächste Abnahme. Zahlenwerte bleiben Startwerte, bis Messung und Spieltests abgeschlossen sind.

Das nächste Ziel: ein kompakteres Kampf-HUD, eine bewusste Dash-Entscheidung, vier eigenständige Bosskämpfe und mehr unterschiedliche Starts. Denti darf sehr mächtig werden; Positionierung, freie Wege und lesbare Gefahren sollen trotzdem wichtig bleiben.

## Vorhandene Grundlage

- 20 Wellen, anschließend optional Endlos; Bossabschlüsse in Welle 5, 10, 15 und 20. Normale Wellenlängen variieren; Bosswellen enden ohne Wellentimer mit dem letzten Boss.
- Vier Story-Areas mit Dialogen und Ortswechseln: **Unter dem Kissen**, **Das süße Verderben**, **Tief im Säurestrom**, **Die letzte Krone**.
- 18 reguläre Waffen, sechs geheime Evolutionen, 96 Shop-Items, sechs Relikte und zwölf Grundattribute. Alle 18 Standardwaffen sind als Mk-I-Start auswählbar; geheime Evolutionen bleiben ausgeschlossen. Die Wurzelanzahl ist ein gespeicherter Spielerparameter, Standard 6; [Konfiguration](PLAYER_ROOTS.md).
- Ununterbrochener Kampf; danach Beutesammlung, Levelaufstiege, Upgrade-Kapseln, gegebenenfalls Relikt und Story-Übergang, anschließend Shop. Dieser Ablauf bleibt erhalten.
- Gegnerdruck, Projektilmuster, Bossphasen und Entzündung sind vorhanden. Der Graf besitzt einen Umhang-/Sektorenablauf, der Prinz eine Karamellküche, der König Säurerinnen/Pegelwechsel/Splitterstampf und der Imperator Kronenwache/Hofurteile/Portalstiche/Nerventakt. Eigene Abläufe, alle vier Schwierigkeitsgrade, Speicherung und native Vergleichsaufnahmen sind vorhanden; vollständige Build-Abnahme bleibt offen.
- Telemetrie, Run-Rückblick, Speichern/Fortsetzen und automatisierte Tests bilden die Grundlage für weitere Änderungen. Shopgrößen und Atlas-Ausschnitte wurden zuletzt korrigiert; entsprechende Layoutgrenzen sollen auch im Kampf gelten.
- Der [Goldzahn-Gauner](LOOT_GOBLIN.md) ist als seltener Beutedieb ab Welle 8 umgesetzt: eine Jagd pro geeigneter Welle, echte Münzverluste bei Flucht, goldene Upgrade-Kapsel beim Kill, animiertes Rig und Save/Resume. Weniger spätes Gold und progressive Rerollkosten begrenzen die Kaufkraft. Menschliche Jagd-/Economy-Balance bleibt offen.

Details zum Iststand: [README](../README.md), [Story-Modus](STORY_MODE.md), [Waffen](waffen.md), [Items](items.md), [Codebase-Review](CODEBASE_REVIEW.md). Die ausführliche frühere Planung bleibt im [historischen Planungsstand](ROADMAP_V02.md) erhalten.

## Prioritäten

Ergänzung 05.11.2026: Für die nächste Entwicklungsphase liegt ein
[gemeinsamer Umsetzungsplan für Klassenregeln und Synergiefamilien](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md)
vor. Reihenfolge: Klassen-/Stat-/Waffenfundament mit Good Old Molar, vollständiges
Giftpaket, Assassine mit Run-Skilltree, getrennte Eis-/Feuerpakete, danach Hüter
und Spültechniker sowie Gesamtbalance. Das
[Klassenfundament mit Good Old Molar](CLASS_FOUNDATION.md) ist jetzt umgesetzt:
zentrale Attributregeln, Waffenrollen/Eignung und kompatible Speicherung.
Das [Giftpaket](POISON_PACKAGE.md) ergänzt jetzt Depotfüllung, Nervensonde und
Giftzahn einschließlich Tags, gespeicherten Zielzuständen und relevanter
Reliktauswahl. Technische Prüfungen und erste Wellenproben sind vorhanden;
die menschliche Spielstil-/Balanceabnahme bleibt offen. [Assassine und gemeinsame
Talentverteilung](ASSASSIN_AND_TALENTS.md) sind jetzt ebenfalls spielbar: zwei
Klassen, zwei Assassinenwege, ein Levelpunktebudget und gespeicherte Entwürfe.
Sechs verdiente Eröffnungsruns besiegen den ersten Boss; vollständige/späte
Klassenbalance bleibt offen. Blutungs- und Wasserbuilds dienen als Kontrollen.

Ergänzung 01.11.2026: Der [Buildvergleich auf Normal](BUILD_COMPARISON.md) ergänzt
die stationären Waffenmessungen um vollständige Wellen, Verzauberungen, Heilung
und normale Bewegung. Buffs für unattraktive Alternativen haben Vorrang;
gezielte Nerfs benötigen Hinweise auf verdrängte Entscheidungen oder trivialisierte
Gefahren. Die Beurteilung des Spielgefühls bleibt Teil der menschlichen Abnahme.
Der [erste spielbare Pass](BALANCE_FIRST_PASS.md) verbessert den Raumgewinn der
Bürste, ergänzt begrenztes Vorhalten beim Imperator und bremst den Heilertrag
hoher Lebensraub-Ränge. Vollständige menschliche Runs bleiben die nächste Abnahme.
Der [verdiente Hell-Einstieg](EARNED_PROGRESSION.md) ergänzt die Prüfung um den
Weg zum Boss: Killrate, Einkommen, echte Käufe und verbleibendes Leben müssen
zusammen bewertet werden, bevor ein Einzelziel-Start als stark gilt.
Der [anschließende Bohrwerkzeug-Pass](DRILL_CONTACT_BALANCE.md) ist umgesetzt:
begrenzter Vorwärtskontakt beim Bohrer, sichere Reichweite und normaler
Gegnerschaden bei der Fräse. Eine kleine Mindestversorgung half den geprüften
Farm-Pfaden nicht und wurde nicht als neues System eingebaut.

Ergänzung 02.11.: Der [Kontaktwaffen-Spieltest-Pass](CONTACT_WEAPON_BALANCE.md)
ergänzt kleine Rückstöße, Kratzer-Folgetreffer und den zielunabhängigen
Polierer-Crit-Zyklus. Die Hell-Lücke zu sicheren Linienwaffen bleibt offen.

Auf Nutzeranregung sind nun [mehrere Testpiloten und sichtbarer Zeitraffer](BOT_SIMULATION.md)
für den verdienten Einstieg W1–5 umgesetzt: drei Reaktions-/Fehlerprofile, vier
Kampfstrategien und getrennte einfache/heuristische Buildregeln. Wahrnehmung,
Projektil-/Warnungsreaktion und echter Dash werden getestet. Die bisherigen
Kreis-/Nachsetzreferenzen bleiben erhalten. Die Diagnose rechnet headless ohne
Echtzeitbegrenzung und nativ mit Pause sowie 1×/4×/8×/16×; die Physik bleibt bei
1/60 Sekunde. Noch offen sind menschliche Kalibrierung, weitere Sensoren für
die späteren Spezialbosse und längere vollständige Runs. Bot-Ergebnisse sind
keine menschlichen Winrates.

Zurückgestellt: [Waffenfamilien-Setboni](WEAPON_SET_IDEA.md), zunächst höchstens
eine kleine Nah-/Fernkampf-Schwelle mit Platz für 4+2-Mischbuilds. Fusion,
Wurzelkosten und die zusätzliche Regelkomplexität müssen vor einer Umsetzung
geklärt werden. Das ersetzt nicht die Grundbalance schwächerer Starts.

Die Run-Vorbereitung ist nun als gemeinsame native Auswahlbühne umgesetzt:
vier gemalte Schwierigkeitsmotive, 18 Waffen, kompakte Vorschau und Details auf Abruf.
[Nutzerfeedback, Gestaltungsplan und native Prüfung](UI_UX_PLAN.md).
Als Nächstes bleiben menschliche Build-/Druckvergleiche und frühe Starter-Balance.
Für die übrigen Menüs liegt eine [native UI-Bestandsaufnahme mit Reihenfolge und
Abnahmekriterien](UI_VIEW_AUDIT.md) vor. Der erste UI-Schritt ist
[umgesetzt](MENU_UI.md): gemeinsame Bühne und mobile Größen für Hauptmenü,
Pause und Einstellungen. Auch die [Belohnungsbühne](REWARD_UI.md) für Aufstiege,
Relikte, Kapseln und Itemfunde ist umgesetzt. Als Nächstes folgt das Run-Ende.

| Priorität | Vorhaben | Ergebnis |
| --- | --- | --- |
| P0 · umgesetzt | Kampf-HUD vereinheitlichen | Animiertes Zahngefäß, dezente XP-Linie und feste Anzeigegrenzen; [Prüfung und Aufnahmen](COMBAT_HUD.md) |
| P1 · Prototyp umgesetzt | Wurzelkraft und Dash | 100 Punkte pro Dash, ausbaubarer Vorrat und verbindlicher Cooldown; [Umsetzung und Prüfung](DASH.md) |
| P1 · Alle vier als Prototyp umgesetzt | Vier Bossidentitäten | Graf: Umhang-Rig; Prinz: Karamellküche; König: Säuresammler; Imperator: Kronengericht; als Nächstes echte Build-/Wellenvergleiche |
| P2 · umgesetzt | Alle Standardwaffen als Starts | Iconraster, Details, ausdrückliche Bestätigung und gespeicherte Vorschau; [Umsetzung](STARTER_SELECTION.md). Frühe Build-Balance bleibt offen |
| Danach | Synergien und Feinschliff | Begrenzte Dash-Synergien, eventuell Cooldown-Reduktion und Balance aller Starts |

Jede Stufe wird einzeln umgesetzt, getestet und gespielt. Bossumsetzung erfolgt pro Encounter; der spielbare Build bleibt während der Überarbeitung erhalten.

## 1. Kampf-HUD: feste Maße, weniger belegte Fläche

**Umgesetzt und nach visuellem Feedback überarbeitet:** Statt gleicher HP-/XP-Balken gilt jetzt der vom Spieler gewählte **Zahn-HUD-Entwurf**. Ein gemaltes Zahngefäß enthält animierte korallrote Lebensfüllung mit Wellengang, Bläschen und kurzer Schadensspur. Aktuelles Leben steht groß in der Zahnkrone, darunter das Maximum mit Schrägstrich. Münzen und Kapseln stehen rechts daneben. Schildladungen bilden eine transparente blaue Hülle mit einer vollständigen Kontur pro Ladung. XP ist eine pflaumenbraun hinterlegte Randlinie mit Level-Medaillon. Welle und Timer bilden eine zentrierte Gruppe. [Aufbau, Grafikprompt, native Bilder und Animation](COMBAT_HUD.md).

- Leben ist das wichtigste Element; Schilde und negative Effekte stehen direkt am Zahn.
- In allen Formaten: Zahn, Statussymbole, Münzen, Kapseln und Level unten; XP als Linie am unteren Rand.
- Zahlen, Schildladungen, vorgemerkte Level und Kapseln haben feste Anker. Die Aufstiegs-Pille passt ihre Breite dem Inhalt an, ohne das Level-Medaillon zu verschieben; ab 100 zeigt sie `99+`.
- Welle und Zeit teilen einen festen 44-Pixel-Bereich: Welle klein über der größeren Zeit. Entzündung ersetzt den Zeitwert durch oranges Symbol und `+n s`.
- Bossrahmen sind bei 1280 Pixeln 450×22 Pixel groß. Die Füllung reicht bis an beide gebogenen Zahnenden; Name links und Prozent rechts verwenden 13 Pixel. Zwei Bosse stehen mit vier Pixeln Abstand untereinander, bei 1920 Pixeln nebeneinander. Endstücke bleiben proportional, nur der Mittelteil wird wiederholt.
- Exakte Werte und vollständige Bossnamen sind ohne Hover im Pausenmenü zugänglich.
- Pause hält die Animation an. Die vorhandene Option für reduzierte UI-Animationen schaltet die Bewegungen ab.
- Alle HUD-Elemente außer Pause lassen mobile Bewegungsgesten durch. Safe Areas werden berücksichtigt.

**Abnahme:** Stabile Anordnung ohne Überschneidungen bei 320×568, 568×320, 720×1280, 1040×600, 1280×720 und 1920×1080. Große Werte, lange Bossnamen, zwei Bosse, Schilde, Statussymbole und Entzündung werden gleichzeitig geprüft. Native Aufnahmen und eine vergrößerte Animation ergänzen automatische Layout-, Eingabe- und Animationstests. Die frühere Vorgabe gleich hoher HP-/XP-Leisten ist durch diesen Entwurf ersetzt.

## 2. Wurzelkraft und Dash

**Prototyp umgesetzt:** Shift, Touchbutton, Durchdashen mit Kontaktrisiko, zeitlich geprüfte Treffer,
Save/Resume, Wurzelkraft-Attribut, zwei passende Item-Ergänzungen und Telemetrie.
[Details, Prüfungen und native Animation](DASH.md). Der menschliche Vergleich
des Gegnerdrucks mit/ohne Dash und Wurzelkraft-Investition steht noch aus.

### Name und Attribut

**Wurzelkraft** ist der Arbeitsname für Dentis Stamina. Er passt zu seiner Bewegung auf Wurzeln und lässt sich kurz beschriften. Der aktive Move heißt zunächst **Dash**, mit dem möglichen Anzeigenamen **Wurzelsprung**.

Es gibt einen investierbaren Wert: **Wurzelkraft**, also maximale Ausdauer.
Die Stat-Kachel zeigt nur den Vorrat, anfangs **100**. Aufstiege und passende
Items erhöhen ihn in festen Punkten, etwa **+25 Wurzelkraft**. Speichel bleibt
Lebensregeneration; Zahnflutsch bleibt passive Ausweichchance.

### Verbindliche Ablaufregeln

1. Ein Dash startet nur im aktiven Kampf (einschließlich Boss-Entzündung), bei mindestens **100 Wurzelkraft** und abgelaufenem Cooldown.
2. **Shift** am Desktop oder Tippen auf den rechten Ressourcen-Zahn. Gedrückthalten wiederholt den Dash nicht; ungültige Eingaben werden nicht vorgemerkt.
3. Richtung: aktuelle Bewegung, sonst letzte Bewegung, anfangs nach unten. Maus und Waffen ändern sie nicht.
4. **150 Welteinheiten in 0,16 Sekunden**, unabhängig von Bewegungstempo und Diagonale.
5. Jeder Dash zieht genau **100 Punkte** ab. Restvorrat bleibt verfügbar; vollständige Füllung ist nicht erforderlich.
6. Nach Dashende und **0,35 s Erholungspause** lädt der Vorrat mit festen **25 Punkten/s** nach, unabhängig von der maximalen Wurzelkraft. Bewegung und Schaden setzen den Fortschritt nicht zurück.
7. **0,5 s Cooldown ab Dashstart** gilt auch bei gespeichertem Vorrat. Genug Ausdauer bei noch laufendem Cooldown zeigt dessen Restzeit im Zahn.
8. Ein Wand-/Randstopp erstattet die Kosten nicht. Tatsächlich neue Wellen starten voll; Pause, Shop und Fortsetzen gewähren keine Gratisladung.

### Startwerte und Begrenzung

| Parameter | Prototyp |
| --- | ---: |
| Basisvorrat / Kosten pro Dash | 100 / 100 |
| Maximal ausgebauter Vorrat | 500 |
| Dashdauer / Strecke | 0,16 s / 150 Welteinheiten |
| Erholungspause nach Dashende | 0,35 s |
| Auffüllzeit leer auf voll bei 100 / 300 / 500 Vorrat | 4 / 12 / 20 s |
| Nachladerate bei jedem Maximalvorrat | 25 pro Sekunde |
| Cooldown ab Dashstart | 0,5 s |

Levelaufstiege geben +25/40/60/90 Punkte je Seltenheit, begrenzt auf den
verbleibenden Platz bis 500. Am Limit wird das Attribut nicht mehr angeboten.
Mehr Vorrat speichert mehrere Dashes; die Regeneration bleibt gleich. Ein größerer
Vorrat muss vor einem Dash nicht vollständig gefüllt sein. 300 Punkte erlauben
drei schnelle Dashes, bevor neue Ausdauer nötig ist.
**Cooldown-Reduktion bleibt eine spätere Erweiterung.**

### Dash durch Gegner bleibt gefährlich

Der Dash kann Gegner durchqueren, räumt aber keine Horde weg. Er verleiht **keine zusätzlichen Unverwundbarkeitsframes**, keinen Rückstoß und keinen eigenen Schaden.

- **Körperkontakt mit einem lebenden Gegner beendet den Dash nicht.** Wände und Arenagrenzen stoppen die Bewegung weiterhin.
- Auch ein Start überlappend in einer Horde erlaubt das Durchqueren. Vorhandene Schilde, passive Ausweichchance und laufende Trefferpausen bleiben wirksam.
- Kontakt wird entlang der gesamten bewegten Strecke geprüft. Ein hoher Dashspeed oder ein langsamer Frame darf weder Gegner noch Projektile oder aktive Schadensflächen überspringen.
- Bei Kontakt greift die normale Schadensverarbeitung einschließlich Härte, Schild, Zahnflutsch und bereits bestehender Trefferpausen. Der Dash setzt diese Schutzmechanismen weder neu noch verlängert er sie. Laufendes Gift und Blutung ticken weiter.
- Der Kontakt erzeugt höchstens einen unmittelbaren Treffer über den vorhandenen Schadensweg; die normale Gegnerberührung darf denselben Kontakt nicht noch einmal abrechnen.
- **Dash-Kontakte verursachen 50 % mehr Schaden**, vor Härte. Der Zuschlag gilt auch bei einer kreuzenden gegnerischen Charge, aber nicht für Projektile, Flächen oder laufenden Statusschaden.

Der Schadensaufschlag hält das Durchqueren von Horden riskant; die Bewegung bleibt dabei verlässlich. Das Dash-Tooltip nennt den Zuschlag.

### Mobile Steuerung

- Das **generierte Wurzelkraft-Zahngefäß unten rechts** ist zugleich die Dash-Touchfläche: 80, 88 oder 100 logische Pixel je Layout. Es gehört als türkis gefülltes Gegenstück zum roten Lebenszahn. Im Stillstand gilt dieselbe Richtungsregel wie am Desktop.
- Der Bewegungsfinger behält seine Geste. Ein zweiter Finger kann Dash drücken, ohne den Joystick-Ursprung oder die Bewegungsrichtung zu übernehmen. Die Buttonfläche startet selbst keine Bewegungsgeste.
- Die animierte Flüssigkeit zeigt den Füllstand; die Zahlen stehen wie beim Leben innerhalb der Zahnkrone. Bei mindestens 100 Wurzelkraft und noch aktivem Cooldown steht dessen Restzeit in der zweiten Zahlenzeile. Es gibt keine frei platzierten Titel, Ladehinweise oder Tastaturtexte im Kampfbild.
- Ungültiges Antippen startet keine spätere Aktion. Pause, Fokusverlust, Fingerfreigabe und Bildschirmdrehung hinterlassen keine festhängende Eingabe.
- Swipe und Doppeltippen werden erst nach Touch-Spieltests als optionale Alternativen bewertet. Der erste Prototyp verwendet den klar erreichbaren Button.

### Integration und Abnahme

Die Dash-Logik erhält eine kleine eigene Bewegungskomponente. `PlayerStats` bleibt die Quelle der maximalen Wurzelkraft; HUD und Touchbutton lesen denselben Dash-Zustand. Werte liegen in einer gemeinsamen konfigurierbaren Ressource.

Speichern/Fortsetzen erhält Ladung, Cooldown, Erholungspause und bei aktivem Dash Richtung sowie Restdauer. Alte Saves starten mit 100 Wurzelkraft ohne Bonus; bestehende Zahlen-IDs der Attribute bleiben kompatibel. Pausierte Spielzeit und Offlinezeit laden den Dash nicht nach. Beim Laden einer Bewegung wird die verbleibende Strecke wieder regulär auf Kontakt geprüft.

**Abnahme:** Tests für 100-Punkte-Kosten, ausbaubaren Vorrat, feste Auffüllzeit, gespeicherte Dashes, gleichzeitige Sperren, gehaltenes Shift, Diagonalen, Randkontakt, Start innerhalb einer Horde und Kontakt trotz Schild/Dodge/Trefferpause. Streckenprüfungen decken auch Projektile und Schadensflächen bei längeren Frames ab. Dazu Pause/Fortsetzen mitten im Dash und Cooldown, alte Saves, Mehrfingereingabe und Drehung des Displays. Telemetrie erfasst Dashanzahl, Gegnerkontakte und Schaden während des Dashs; normale Spielanzeigen bleiben kompakt.

## 3. Vier Story-Areas, vier unterschiedliche Bosskämpfe

**Neuer Spielteststand 02.11.2026:** Bossstages laufen ohne normalen Trash und
enden mit dem letzten Boss-Tod, ohne Wellentimer oder zeitgesteuerte Entzündung.
Der Prinz führt auf Normal über zwei und auf Hard/Hell über drei Prüfungen:
schießende Karamellherzen und abzufangende Herzboten brechen seinen Schutz.
Beim König muss sein eigener fest einrastender Säurestrahl die Schildventile
zerstören. Easy/Normal haben eine Prüfung, Hard zwei, Hell drei bei 90/60/30 %
Restleben mit zwei/drei/vier Ventilen. Mehr Rüstung und ein langsameres
Schadensbudget schützen den normalen Kampf; Schildbrüche öffnen einen
Gegenangriff ohne Rüstung, mit einem eigenen Schadensbudget. Zwischen den
Hell-Schilden bleiben im Diagnosekampf rund elf Sekunden normaler Kampf.
Der Imperator lädt mit zwei eigenen Vasallen auf Normal und drei auf Hard/Hell
sein Urteil auf. Kronenlanze, Siegelhüter und Reichsrichter besitzen eigene
Grafiken und Angriffe. Der Siegelhüter ermöglicht begrenzte Heilung; seine
Zerstörung unterbricht diese. Vollständige Rufabfolgen und Save/Resume sind
automatisiert prüfbar; die menschliche Spielabnahme bleibt der nächste Schritt.
Festes XP-/Gold-/Kapselbudget ersetzt
normale Wellenbeute. [Direkter Teststart, Regeln und offene Balance](BOSS_STAGES.md).

Die Herrschertitel und ihre Storyfunktion bleiben erhalten. Jeder Boss erhält eine eigene Silhouette, ein eigenes Bewegungsverhalten, einen charakteristischen Angriffsablauf und eine andere Antwort des Spielers. Alle vier sind als eigene Encounter spielbar; die folgenden Abnahmeziele erfordern noch echte Build- und vollständige Wellenvergleiche.

| Area / Boss | Kampfidee | Typische Antwort |
| --- | --- | --- |
| Unter dem Kissen / Plaquula | Neu zielende Umhangschläge mit Knochenanimation | Warnsektoren verlassen, jeden Nachschlag neu lesen |
| Das süße Verderben / Don Karamello | Bomben, Karamellherzfächer, Zuckerrausch mit Herzkranz | Boden freihalten, Schussrichtungen lesen, Ansturm und Gasse beantworten |
| Tief im Säurestrom / Korrodon, der Ätzkoloss | Säurerinnen, Pegelwechsel, Splitterstampf und Sammlerzug | Ufer und Übergänge vorausplanen, Öffnung nach dem Entleeren nutzen |
| Die letzte Krone / Karies-Imperator | Kronenwache, Hofurteil, Portalstich und Nerventakt | Orientierung, Sektoren und feste Rhythmen kombinieren |

### Plaquula: der Umhang-Graf

**Im Kampf integriert:** Der vom Spieler ausgewählte Bettwanzen-Vampir C
verwendet zwölf Knochen und zwei gewichtete Stoffnetze. Die zu langsamen
Kissenbahnen wurden durch zwei, später drei schnell ausgeführte Umhangschläge
mit erneutem Zielen und kurzem Nachsetzen ersetzt. Eine Zustandsmaschine
synchronisiert Animation, Warnfläche und tatsächliches Trefferfenster.
[Ablauf, Aufnahmen, Prüfungen und Vergleich](COUNT_CLOAK.md).

- Erste Vorwarnung 0,85 s, Nachschläge jeweils 0,75 s; jede Ankündigung bleibt
  anschließend orts- und richtungsfest. Nur die Erholung verkürzt sich bei Entzündung.
- Die Sektoren sind an Wänden schmaler. Grundtempo-Routen, Dashstrecken,
  Einmaltreffer, zwei Grafen, Pause und Fortsetzen sind geprüft.
- Keine zusätzlichen HP oder generischen Phasenringe. Im isolierten Vergleich
  kündigt der neue Graf neun statt drei Angriffe an. Nur einmaliges Ausweichen
  reicht dort nicht mehr; auf jede Warnung reagierende Grundbewegung bleibt schadensfrei.
- Rig und neues Porträt werden auch im echten Run beziehungsweise Storydialog verwendet.
  Die frühere Kissenfassung bleibt als historischer Vergleich dokumentiert.

**Offene Abnahme:** Der isolierte Kampf mit synthetischen 120 Roh-DPS liegt
bei knapp 19 s. Menschlicher Vergleich der vollen Welle, langsame Builds,
Touch und Web-Performance bleiben offen; das ist noch keine Balancefreigabe.

### Don Karamello: Die Karamellküche

**Nach dem Varianten-Feedback erweitert:** Drei eigene Angriffsabläufe bereits ab Phase 1: Bombenfolge, Herzfächer und Zuckerrausch mit gesondert angekündigtem Herzkranz. Das generierte Herzmotiv ist ein echtes Projektil. Spätere Phasen verändern Strahlzahl und Folgesalven; neue Vorwarnungen bleiben erhalten. [Gemeinsam überarbeitete und inzwischen umgesetzte Repertoires für Prinz, König und Imperator](BOSS_ATTACK_DIRECTION.md).

**Erster Prototyp im Spiel:** Generierter Karamellprinz im Kupferkessel, fünf Gelenke, zwei beziehungsweise drei sichtbare Zuckerwürfe, begrenzter Vorhalt beim zweiten Wurf und eine stehende Nahkampfpause. Einschläge hinterlassen fünf Sekunden Karamell (72 % normale Bewegung), höchstens vier Felder gemeinsam bei zwei Prinzen. Keine zusätzlichen HP und keine generischen Phasensalven. Pause, Fortsetzen, Eckrouten und zeitgenaue Dash-Treffer sind geprüft. [Umsetzung, Werte, Aufnahmen und Grenzen](PRINCE_CARAMEL.md). Zerstörbare Zuckerkerne bleiben die spätere Erweiterung; ihr Herzmotiv wird inzwischen für Projektile genutzt; die folgenden Punkte beschreiben die Gesamtrichtung.

- Der bewegliche Prinz wirft Zuckerbomben auf zuvor markierte Spielerpositionen. Nach dem Einschlag bleiben zeitlich begrenzte, verlangsamende Karamellfelder zurück; die Flugbahn und Landefläche sind sichtbar.
- Denti kann neue Felder bewusst an Rändern ablegen. Es gelten eine feste Obergrenze für aktive Felder und eine feste Lebensdauer; der Boden kann nicht dauerhaft vollständig verkleben.
- Später wirft der Prinz kurze Bombenfolgen und lässt zerstörbare Zuckerkerne wachsen. Ein zerstörter Kern verhindert den nächsten lokalen Karamellguss und schafft eine bessere Angriffsgelegenheit.
- Kerne sind optionale Kontrollziele, keine Pflicht für Schaden am Boss. Automatische Waffen müssen sie zuverlässig erfassen können; ein bestimmter Waffentyp wird nicht vorausgesetzt.
- Optische Richtung: Zuckergusskrone, Karamellkessel und Bonbonwürfe. Klebeflächen und gefährliche Einschläge haben unterschiedliche Markierungen.

**Abnahme:** Feldobergrenze und Ablauf verhindern Sackgassen. Keine Fläche erscheint sofort aktiv unter Denti. Der Kampf lässt sich auch ohne Kernzerstörung gewinnen; gezieltes Freihalten von Boden lohnt sich sichtbar.

### Korrodon, der Ätzkoloss: Der Säuresammler

**Im Spiel umgesetzt:** Säurerinnen, Pegelwechsel, versetzter Splitterstampf mit echten Projektilen und Sammlerzug mit verwundbarer Brust. Generierter gepanzerter König mit sechs Gelenken und animierten Behältern; alle vier Schwierigkeiten skalieren Bewegung, Aktionsmenge und Splitter. Feste runde Bahnenden und zugehörige Trefferflächen bleiben beim Kameranachlaufen unverändert. [Umsetzung, Werte, Aufnahmen, Messung und offene Abnahme](KING_ACID.md).

- Der König steuert Säurerinnen durch die Arena, statt selbst ständig anzustürmen. Gemalte Texturen fließen entlang fest angekündigter Bahnen; Pegelwechsel markieren neue Rinnensätze.
- Ein sichtbarer Pegel kündigt einen Richtungswechsel an. Alte Rinnen laufen aus, bevor der nächste gefährliche Abschnitt entsteht. Säure verursacht Schaden über den normalen Gefahrenpfad; ein Dash bietet keinen Schutz davor.
- Nachdem der König seinen Vorrat zurückzieht, öffnet sich ein klares Angriffsfenster. Die letzte Phase kombiniert den finalen Rinnensatz mit einem angekündigten Stampf. Langsame Eckrouten der getrennten Angriffe sind geprüft; kombinierte Endphase und vollständige Builds benötigen weitere Spieltests.
- Optische Richtung: säuregefüllte Herrscherinsignien und Zahn-Trophäen als sichtbare Leitpunkte. Seine Sammlerrolle aus dem bestehenden Dialog erhält damit eine Entsprechung in der Arena.

**Abnahme:** Der Spieler kann den nächsten sicheren Ort vor dem Umschalten erkennen. Spawnpositionen, Randkontakt und langsamere Builds behalten eine Route. Mobile Ansichten zeigen Strömungsrichtung und Vorwarnung ebenso klar wie Desktop.

### Karies-Imperator: Das Kronengericht

**Im Spiel umgesetzt:** Acht Gelenke, generierter schwebender Imperator, drei gerichtete Kronenplatten, feste wechselnde Hofurteile, echte Portal-Wurzellanzen und vollständige Nervensalven mit offenem Kern. Alle vier Schwierigkeiten skalieren Bewegung, Aktionsmenge und Projektile. Erste langsame Eckrouten einschließlich kombinierter letzter Phase, Pause, tatsächliches Fortsetzen, zwei Imperatoren und Begrenzungen sind geprüft. [Werte, native Aufnahmen, Messung und offene Build-Balance](EMPEROR_COURT.md).

- Der Imperator besitzt eine erkennbare gerichtete Kronenwache: geschützte Vorderseite, verwundbare Seiten beziehungsweise Rückseite. Die Orientierung wechselt angekündigt; Schutz bedeutet Schadensreduktion, keine unbegrenzte Immunität.
- Ein Erlass markiert gegenüberliegende Hofsektoren, die nacheinander gefährlich werden. Die übrigen Flächen bleiben unabhängig von Dentis Position offen; Denti sucht einen Platz mit günstigem Angriffswinkel.
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

**Umgesetzt: Bossdruck auf allen vier Schwierigkeiten.** Easy, Normal, Hard
und Hell skalieren Bewegung, Aktionsmenge und Projektile. Prinz-Fächer und
Herzkränze sowie die eigenen Imperator-Nervensalven lassen keine
Geschosse mehr für eine auf Denti ausgerichtete Sicherheitsgasse aus.
Vorwarnungen bleiben erhalten. Tatsächlicher Druck, vollständige Ringe,
verlangsamte Eckrouten, Budgets und Save/Resume sind geprüft.
[Werte aller vier Stufen und Messungen](PRINCE_CARAMEL.md#schwierigkeit-easy-normal-hard-und-hell).

Die vorhandenen Systeme für Projektile, Warnungen, Schaden, Bossanzeige und Encounter-Abschluss werden weiterverwendet. Eigene Verhaltenskomponenten pro Boss steuern den Ablauf; Resource-Profile enthalten Zeiten, Grenzen und Phasenwerte. Ein gemeinsamer Controller wächst dadurch nicht zu einer Sammlung aller Boss-Sonderfälle.

Speichern/Fortsetzen bewahrt aktive Angriffsschritte, Warnzeiten, Orientierung, Flächen, Feldlebensdauer und Entzündung. Laufende alte Boss-Saves benötigen einen ausdrücklich versionierten Übergang; eine gespeicherte Warnung darf beim Laden nicht zu einem sofortigen neuen Angriff werden. Bossgebundene Gefahren werden bei Tod/Encounter-Ende zuverlässig entfernt, bevor Belohnungen beginnen.

Pro Boss werden TTK, Schaden nach Angriffsquelle, Treffer während Vorwarnung/aktiver Phase, aktive Gefahren und Dash-Nutzung ausgewertet. Geprüft werden schwache, mittlere und starke Builds, Nah-/Fernkampf, langsame Bewegung, verschiedene Schwierigkeiten und zwei Bosse im Endlosmodus. Native Aufnahmen und Spieltests unter hoher Effektdichte ergänzen automatische Ablauf-, Kollisions- und Save-Tests.

## 4. Alle Standardwaffen als Startauswahl

**Umgesetzt: Alle aktuell 18 Standardwaffen sind von Anfang an auswählbar.** Die Auswahl liest den regulären Waffenkatalog; eine zusätzliche begrenzte Starterliste entfällt. Künftige Standardwaffen erscheinen ebenfalls dort. Geheime Evolutionen gehören weiterhin zu ihrer eigenen Progression und erscheinen nicht als Starts.

### Ablauf im Menü: Schwierigkeit → Waffe → Start

Die Vorbereitung bleibt im Hauptmenü. Schwierigkeit markieren, mit Weiter zur
Waffenauswahl und bei Bedarf wieder zurück; beide Auswahlen bleiben erhalten.
Arena und Kampf-HUD werden erst nach „Run starten“ geladen. Ein separater
Vorbereitungsentwurf erhält Schritt und Auswahl, ohne einen bestehenden Run zu
ersetzen. Die Schrittreihenfolge erlaubt später eine Klassenauswahl dazwischen.
[Umsetzung und Abnahme](STARTER_SELECTION.md).

### Waffe: Icon → Details → Bestätigung

1. Ein kompaktes Raster zeigt die vorhandenen Waffenbilder als kleine Icons. Die Reihenfolge bleibt stabil; Namen können als kurze Beschriftung oder Tooltip ergänzt werden.
2. Ein Klick beziehungsweise Antippen markiert das Icon und wechselt die kompakte Waffenvorschau. Weitere Icons wechseln die Vorschau, ohne eine Waffe zu vergeben oder den Kampf zu starten.
3. Die Vorschau zeigt Bild, Namen, Wurzelkosten und drei Iconwerte für Schaden, Angriffspause und Reichweite. Grundlage sind die tatsächlichen Mk-I-Startwerte. Mechaniken, Skalierung und weitere Daten öffnen sich über „Details“.
4. Erst **„Run starten“** bestätigt die Auswahl, vergibt genau diese Waffe und startet Welle 1. Bis eine Waffe angeklickt wurde, ist die Bestätigung deaktiviert.

### Layout und Bedienung

- Desktop: 6×3-Iconraster mit kompakter Vorschau daneben und fest erreichbarer Bestätigung.
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
| 1 · umgesetzt | Animiertes Zahngefäß, XP-Randlinie, kompakter Timer, getrennte Bossanzeigen | Größen, Textgrenzen, Statusanzeigen, sechs Auflösungen und native Bilder; [Nachweis](COMBAT_HUD.md) |
| 2 · umgesetzt | Dash-Basis inklusive Touchbutton, Durchdashen und Save/Resume | Kontaktschaden +50 %, beide Sperren, keine neuen Schutzframes, Streckenprüfung und native Darstellung geprüft |
| 3 · Prototyp umgesetzt | Wurzelkraft-Attribut, wenige passende Angebote und Telemetrie | Wartezeiten, Stat-/Save-Kompatibilität und Limit geprüft; Druck-/Balance-Playtest noch offen |
| 4 · Prototyp umgesetzt | Plaquula als erster eigener Encounter | Umhang-Rig, Warnsektoren, Nachschläge, Dash-Streckenprüfung, Fortsetzen und nativer Nah-/Fernvergleich; menschliche Abnahme offen |
| 5 | Vier Boss-Encounter als Prototyp umgesetzt; Build-Abnahme folgt | Eigene Abläufe samt Grenzen und Tests vorhanden; Nah-/Fernkampf, Kernfenster, vollständige Wellen und mobile Performance vergleichen |
| 6 · umgesetzt | Alle 18 Standardwaffen im Iconraster mit Details und Bestätigung | Katalog, Vorschau, einmaliger Start, Fortsetzen und sechs Layoutgrößen geprüft; frühe Wellen-/Build-Balance bleibt offen |
| 7 | Balance aller Starts und gegebenenfalls Dash-Cooldown-Items | Endlos-/Schwierigkeitsvergleich wiederholen |

Nach Schritt 3 wird geprüft, ob Dash die bisherige Gegnerdichte zu stark entwertet. Nach jedem Boss folgt ein eigener Druck-/TTK-Vergleich. Mehr HP und zusätzliche Projektile ersetzen diese Prüfung nicht.

## Weiterer Backlog

- **Build-Tiefe:** Zusätzliche Items nur mit klarer Wechselwirkung. Blutung, Nässe/Elektro, Crit/Weihe, Schild/Vergeltung, Heilung, Ökonomie und Zucker-Risiko bleiben die Build-Familien. Der frühere Mengenplan „30–35 Items“ ist mit 94 Items überholt.
- **Dash-Synergien:** Nach der Basis etwa begrenzte Erholung durch tatsächliche Schildblocks oder ein Zucker-Item mit schnellerer Erholung und klarer Gegenleistung prüfen. Keine automatischen Vollaufladungen durch jede Tötung, keine endlosen Proc-Ketten und kein Durchqueren von Gegnern durch ein Item.
- **Gegnerdruck:** Dichte, gemischte Rollen, Burst-Rhythmus und Projektilräume weiter messen. Neue Bossmechaniken und Dash werden gemeinsam mit den vorhandenen Drucksystemen getestet.
- **Gauner und Economy · umgesetzt, Balance offen:** Verfolgen zwischen Horden und Münzverluste durch entkommene Beute mit Nah-/Fernkampf-Builds vergleichen. Einnahmen, Rerollausgaben und gerettetes/verlorenes Gold in vollständigen Runs auswerten; [Startwerte und Prognose](LOOT_GOBLIN.md).
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

## Waffenmeisterschaften · 27.10.2026 umgesetzt

Erster Achievement-Baustein: Zahnprüfung und drei kumulative Siegesmedaillen
pro Startwaffe, dauerhafter Fortschritt, eigenes Achievement-Menü, Suche, Filter und abrufbare Anforderungen sowie Meldung nach der Welle und im Run-Rückblick.
Keine Statboni oder Waffensperren. [Regeln und Prüfung](WEAPON_MASTERIES.md).
