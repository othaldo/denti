# Klassen und Skilltrees für Denti

Aktuelle Reihenfolge und technische Abnahme:
[Umsetzungsplan für Klassen und Synergien, 05.11.2026](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md).
Die Zahlen und Baumgrößen in diesem Entwurf bleiben Beispiele.

Designvorschlag vom 04.11.2026 auf Nutzeranregung. **Historischer Entwurf:** Der
aktuelle erste Baum und Assassine stehen in [Umsetzung P3](ASSASSIN_AND_TALENTS.md).
Ziel sind erkennbare Spielstile von Welle 1 an und unterschiedliche Builds
innerhalb derselben Klasse. Konkrete Zahlen sind Startwerte für einen Prototyp,
keine gemessene Balance. Dieses Konzept vertieft die
[vorherige Spielstil-Recherche](BUILD_PLAYSTYLES_RESEARCH.md).

Vergleich vom 05.11.2026: [Brotatos Charakterregeln und ihre Übertragung auf Denti](BROTATO_CLASSES_COMPARISON.md).
Der Vergleich trennt feste Klassenidentität von einem zusätzlichen Run-Skilltree.

## Leitidee

**Klasse = Ausgangsregeln. Skilltree = Spezialisierung im Run. Waffen und Items =
konkrete Ausgestaltung.**

Die Klasse gibt eine erkennbare Stärke, eine Grenze und eine besondere
Handlungsmöglichkeit. Der Baum erweitert diese Handlung in mehrere Richtungen.
Der Shop liefert Werkzeuge und Synergien. Ein Assassine soll schon ohne seltene
Funde wie ein Assassine funktionieren; sein bestes Endbuild steht beim Start
aber noch nicht fest.

## Basis-Denti: Good Old Molar

Nutzervorgabe: Der klassische Basis-Denti bleibt als eigene vollwertige Klasse
erhalten. **Good Old Molar** ist dafür der vorgeschlagene Arbeitsname.

- Standardmäßig freigeschaltet und als Einstieg verfügbar.
- Freie Wahl aller regulären Waffen, normale Wurzeln und normale Dashregeln.
- Vertrautes, ausgewogenes Grundspiel ohne erzwungenen neuen Kampfablauf.
- Sein Baum unterstützt freie Buildentwicklung und unterschiedliche Waffen-
  und Itemkombinationen. Er wird im selben Klassensystem entwickelt; er ist
  weder ein unvollständiger Platzhalter noch auf eine Tutorialrolle begrenzt.
- Seine Stärke ist Anpassungsfähigkeit an Funde. Spezialisierte Klassen gewinnen
  besondere Mechaniken und haben dafür eigene Grenzen. Good Old Molar muss als
  gleichwertige Wahl auch für erfahrene Spieler attraktiv bleiben.

Als überschaubare erste Auswahl sind **Good Old Molar, Assassine, Hüter und
Spültechniker** vorgeschlagen. Artillerist und weitere Ideen bleiben spätere
Kandidaten. Der erste technische Prototyp kann trotzdem mit weniger Profilen
beginnen. Keine weitere Klasse ersetzt den Basis-Denti.

## Gemeinsamer Systemrahmen für alle Klassen

Ergänzung nach dem Nutzerfeedback: Klassen sollen ein erweiterbares System für
unterschiedliche Spielstile und neue Inhalte bilden. Der Assassine unten ist ein
Beispiel dafür. Seine Zahlen, Talentanzahl und Punktgrenzen sind noch keine
beschlossenen allgemeinen Regeln.

### Jede Klasse braucht einen vollständigen Kampfablauf

Das gemeinsame Entwurfsmuster lautet:

**Handlung → Vorbereitung → besondere Wirkung → Erholung oder Verbrauch → neue
Entscheidung.**

Die Handlung muss mit Dentis tatsächlicher Steuerung funktionieren: vor allem
Bewegung, Abstand, Laufweg und Dash. Automatische Angriffe lösen die Wirkung aus.
Für den ersten Klassenpass werden keine zusätzlichen aktiven Fähigkeitstasten
vorausgesetzt. Ein Status oder Zähler ist nur nötig, wenn er diesen Ablauf
verständlicher oder steuerbarer macht.

Eine neue Klasse wird mit derselben kurzen Vorlage entworfen:

| Bestandteil | Verbindliche Designfrage |
| --- | --- |
| Spielversprechen | Was möchte der Spieler im Kampf wiederholt tun? |
| Klassenkern | Welche Handlungsmöglichkeit ist dafür schon bei Runstart vorhanden? |
| Vorbereitung und Ertrag | Wie stellt der Spieler die günstige Situation her, und was gewinnt er daraus? |
| Grenze | Wann muss er abbrechen, ausweichen, nachladen oder neu aufbauen? |
| Ausrüstung | Welche Waffenrollen passen, welche Einschränkungen sind wirklich nötig? |
| Entwicklung | Welche mindestens zwei unterschiedlichen Abläufe werden innerhalb der Klasse tragfähig? |
| Verbindungen | Welche vorhandenen Items, Stats und Elemente bekommen einen anderen Nutzen? |
| Bossfähigkeit | Wie bleibt der Kern ohne Killserie, mit wenigen Gegnern und bei Ortswechseln brauchbar? |

Ein Waffenverbot ist eine mögliche Grenze. Alternativen sind eine angreifbare
Stellung, ein verbrauchbarer Schutz oder eine Erholungsphase. Eine neue Klasse
braucht nicht zusätzlich zu ihrer besonderen Mechanik immer eine lange Liste
globaler Statboni und Nachteile.

### Erste Klassenfamilien als gemeinsamer Entwurfsraum

Diese Matrix beschreibt Zielverhalten, keine bereits vorhandenen Klassen:

| Klasse | Bevorzugte Handlung | Vorbereitung → Wirkung → Grenze | Unterschiedliche Wege innerhalb der Klasse |
| --- | --- | --- | --- |
| Good Old Molar | Gefundene Waffen und Items flexibel kombinieren | Vertrauter Grundkampf mit frei gewählter Ausrüstung; keine zusätzliche erzwungene Klassenroutine | Flexible Entwicklung über Waffenmix, Grundwerte und Itemsynergien |
| Assassine | Kurze Nahkampfgelegenheiten schaffen | Dash / Anlauf → Antritt → Rückzug oder riskantes Nachsetzen | Giftläufer, Schattenlauf, Vollstrecker |
| Hüter | Schutz für einen günstigen Gegenangriff einsetzen | Schutz halten → Block und Gegenangriffsfenster → Schutz erneuern | Kurzer Vergeltungsstoß, längere Schutzstellung, Überheilung als Schutzreserve |
| Spültechniker | Einen Kampfplatz vorbereiten und die Horde hindurchführen | Flächen setzen → leitende Strecke oder Kontrollkorridor nutzen → Stellung wechseln | Leitnetz, Kälteführung, kurze Druckstöße mit häufigem Stellungswechsel |
| Artillerist | Gute Schussbahnen und Zeitfenster suchen | Position / Aufladung → begrenzte Salve → während der Erholung versetzen | Präzisionslinie, Flächenbeschuss, durch Bewegung ausgerichteter Rückflug |

Good Old Molar ist der vollwertige klassische Allrounder mit freier Waffenwahl.
Der Artillerist ist in dieser Matrix ein späterer Erweiterungskandidat.
Eine spätere Alchemistenklasse wäre erst sinnvoll, wenn Vorbereiten und Umwandeln
von Zuständen einen eigenen Ablauf trägt, der über den Giftast des Assassinen
und die Flächen des Technikers hinausgeht. Neue Klassen werden nicht allein
wegen einer noch unbesetzten Elementfarbe ergänzt.

### Der Skilltree verändert den Ablauf der Klasse

Die Äste sollen sich in der gewünschten Handlung unterscheiden. Drei allgemeine
Spalten für Schaden, Verteidigung und Tempo würden eher zum gleichen Ausbauplan
führen. Besser sind beispielsweise beim Assassinen: sofortiger Rückzug,
Zielwechsel für Giftdepots oder längeres Festhalten am Einzelziel.

Als Arbeitsmodell dienen drei kurze Äste mit mischbaren unteren Talenten und
einem gewählten starken Abschluss. Die endgültige Baumgröße und Punktverteilung
folgen aus erreichbaren Levels und Tests. Eine gute Klasse braucht nicht für
jeden Ast eine komplett neue Fähigkeit oder eine neue Ressource.

Der Kern muss ohne seltenes Item funktionieren. Funde sollen die Verteilung
beeinflussen können: eine früh gefundene Fokuswaffe macht beim Assassinen einen
anderen Ausbau attraktiv als gute Giftunterstützung. Der vor Runstart sichtbare
Baum bleibt verlässlich; der Shop liefert Gründe, ihn anders zu entwickeln.

### Gemeinsame Ausrüstung schafft Verbindungen zwischen Klassen

Elemente, die meisten Items und Stats bleiben gemeinsame Werkzeuge. Eine Klasse
bestimmt, wie sie diese anwendet. So kann Gift beim Assassinen an Nahkampfantritte
gebunden sein und bei einer anderen Klasse an vorbereitete Zonen.

Klassenfähigkeiten nutzen dieselben grundlegenden Ereignisse und Grenzen:
gültiger direkter Treffer, Dash, Block, Statusanwendung, Kill und tatsächlich
zurückgelegte Strecke. Jeder Effekt kennt seine Herkunft. Ein Folgeeffekt darf
nicht unbegrenzt einen weiteren gleichartigen Treffer, Heilung oder eine neue
Ressourcenerstattung auslösen.

Klassenexklusive Shop-Pools sind zunächst nicht nötig. Waffenangebote beachten
die tatsächliche Eignung; Items behalten sinnvolle Verbindungen zwischen Klassen.
Neue Ausrüstung soll dadurch möglichst mehrere Builds bereichern.

### Neue Inhalte können auf mehreren Ebenen entstehen

| Ergänzung | Welcher neue Inhalt entsteht? | Voraussetzung |
| --- | --- | --- |
| Neue Klasse | Ein weiterer grundlegender Kampfablauf | Erkennbar andere Entscheidungen und ein brauchbarer Start |
| Neuer Talentzweig oder alternatives Talent | Andere Entwicklung einer bekannten Klasse | Veränderter Ablauf statt nur höherer Wert |
| Neues gemeinsames Item | Neue Verbindung zwischen bestehenden Builds | Mehrere sinnvolle Anschlüsse, kein exklusives Pflichtteil |
| Neue Waffe / Evolution | Andere Angriffsgeometrie oder ein später Höhepunkt | Passende Klassenrollen und verständliche Kosten |
| Klassenaufgabe / Freischaltung | Ein zusätzlicher Anlass, eine Spielweise auszuprobieren | Horizontale Belohnung; keine erforderliche permanente Statsteigerung |

Vier Klassen mit je mehreren Wegen sind eine Arbeitsstruktur für Inhalte, kein
Beweis für eine bestimmte Anzahl verschiedener fertiger Builds. Erst tatsächliche
Unterschiede im Spiel und sinnvolle Mischungen machen daraus Wiederspielwert.

### Abnahme einer Klasse vor der nächsten Erweiterung

Zuerst eine normale Welle und einen Boss mit Good Old Molar, Assassine und Hüter
vergleichen. Diese drei Profile sollen bereits ohne umfangreiche neue Itemsets
zeigen, ob das gemeinsame System funktioniert. Die späteren Klassen können dann
auf denselben Punkten, Voraussetzungen, Effekten und Speicherregeln aufbauen.

Eine Klasse gilt erst als tragfähig, wenn:

- ihr Kern von Anfang an nutzbar und verständlich ist;
- mindestens zwei Wege andere Abstände, Laufwege oder Angriffsfenster belohnen;
- mehrere Waffenstarts und verschiedene Fundverläufe funktionieren;
- ihre Grenze im Spiel tatsächlich spürbar bleibt, auch bei starkem Sustain;
- sie gegen Horden und Bosse einen sinnvollen Ablauf behält;
- die passende Spielweise besser funktioniert als blind übernommenes Kreisen;
- der Baum keine wiederkehrende Pflichtreihenfolge für alle Builds erzwingt.

Erst danach werden mehr Klassen oder zusätzliche Talentvarianten produziert.
Damit wächst der Inhalt aus erprobten Mechaniken und gemeinsam nutzbaren
Bausteinen.

Ein passendes Vorbild für die Trennung von Grundklasse und Vertiefung ist
Last Epoch: Die offizielle Klassenbeschreibung unterscheidet Klassen und
Masteries mit eigenen passiven Boni und Fähigkeiten. Die Support-Dokumentation
beschreibt außerdem begrenzten Zugriff auf andere Mastery-Bäume.
**Übertragung auf Denti:** tiefe Spezialisierung mit begrenzter Möglichkeit zum
Mischen; kein Übernehmen der Größe oder der Levelanforderungen eines langen ARPG.
[Klassenbeschreibung](https://lastepoch.com/classes/),
[Passive-Bäume](https://support.lastepoch.com/hc/en-us/articles/46363282865435-Can-I-spend-Passive-points-in-the-Mastery-trees).

## Drei Ebenen, die unterschiedliche Entscheidungen tragen

| Ebene | Entscheidung | Bleibt über Runs? |
| --- | --- | --- |
| Klasse vor dem Start | Welche Grundregeln und welcher Kampfstil? | Die Freischaltung ja; die Wahl gilt für diesen Run |
| Skilltree während des Runs | Welche Fähigkeiten und Kombinationen entwickle ich? | Nein; neue Verteilung in jedem Run |
| Shop / Waffenverzauberung / Relikte | Mit welchen Werkzeugen verwirkliche ich das? | Wie bisher Run-Ausrüstung |

Ein dauerhafter Meta-Techtree kann später weitere Klassen, alternative Talente
oder Startvarianten freischalten. Er erhöht im ersten Konzept keine permanenten
Schadens-, HP- oder Dashwerte. Neue Runs sollen durch Erfahrung und andere
Optionen besser werden, nicht durch verpflichtendes Hochgrinden der Klasse.

## Level-ups: ein gemeinsames Budget

Empfehlung für neue Klassen-Runs:

- Jeder tatsächlich verdiente Levelaufstieg gibt **einen Skillpunkt**.
- Derselbe Punkt kauft entweder einen allgemeinen Attributknoten oder ein
  Klassentalent. Es gibt keine zweite kostenlose Talentbelohnung zusätzlich
  zum bisherigen vollständigen Statbonus.
- Allgemeine Knoten bieten die vorhandenen Attribute: etwa Schmelz, Härte,
  Nahschaden, Putzeifer, Speichel oder Wurzelkraft. Nutzlose reine Fernkampfwerte
  werden beim Assassinen nicht als sinnvolle Investition angeboten.
- Klassentalente verändern vor allem Mechaniken. Kleine numerische Knoten
  können verbinden, sollten aber nicht den Großteil des Baums ausmachen.
- Die feste Attributwahl im Baum würde die heutigen zufälligen Level-up-Karten
  ersetzen. Die Seltenheitswürfe und das Neuwürfeln dieser Karten entfallen in
  diesem Modus. Glück bleibt für Shop und Beute relevant. Das ist eine bewusste
  Änderung des XP-Systems und muss gegen dessen heutige Progression verglichen
  werden; als Knotenwert darf nicht einfach jedes bisherige Maximalangebot dienen.

Als erster Größenversuch: **drei Klassenäste mit je vier Knoten**, insgesamt
zwölf verschiedene Klassentalente. Die ersten beiden Knoten jedes Asts besitzen
je zwei Ränge, die beiden folgenden je einen Rang. Alle Ränge kosten einen Punkt.
Allgemeine Attribute stehen in einem gemeinsamen kompakten Bereich daneben.

Für Spezialisierung auch in langen Runs:

- Höchstens **zwölf ausgegebene Punkte in Klassentalenten pro Run** als
  vorläufige Grenze. Weitere Levelpunkte gehen in allgemeine Attribute.
- Neue Talentstufen öffnen nach 2, 5 und 10 bereits ausgegebenen Klassenpunkten;
  dazu gehört mindestens ein Rang im Vorgänger des jeweiligen Asts.
- Ein Abschluss benötigt zusätzlich mindestens vier ausgegebene Punkte im
  eigenen Ast einschließlich des Knotens davor.
- Pro Run ist **ein** Abschluss wählbar. Die niedrigeren Talente anderer Äste
  bleiben zum Mischen offen.

Damit kann ein Spieler einen Ast stark entwickeln und andere ergänzen. Er kann
nicht im Endlosmodus alle drei vollständigen Spielstile gleichzeitig maximieren.
Die Zwölf-Punkte-Grenze und Gates werden anhand der tatsächlich verdienten Level
geprüft. Sie sind nicht gleichbedeutend mit zwölf garantierten frühen Punkten.
Ein Level-1-Start verdient beispielsweise bis Level 12 elf Punkte insgesamt;
Investitionen in Attribute verzögern die höheren Klassentalente entsprechend.

## Ununterbrochener Kampf und Zwischenphase

XP erhöht während des Kampfes nur den ausstehenden Punktestand. Eine Wahl öffnet
weiterhin kein Kampffenster. Nach Wellenende wird zuerst die gesamte Beute
eingesammelt. Anschließend öffnet der Baum **einmal mit allen verdienten Punkten**.
Mehrere Levelaufstiege erzeugen keine Folge identischer Einzeldialoge.

Die Reihenfolge bleibt beim bestehenden Koordinator:

**Kampf → Loot-Sweep → Skillpunkte → weitere Belohnungen / Waffenverzauberung →
Relikt / Story, falls fällig → Shop.**

Die genaue heutige Reihenfolge alter gespeicherter Belohnungsarten bleibt im
Koordinator erhalten. Der Baum ersetzt den Aufstiegsschritt, nicht die übrigen
Belohnungssysteme. Im Shop darf er zum Planen und Ausgeben gesparter Punkte
wieder geöffnet werden; ein neuer Run muss nicht aufgesparte Punkte erzwingen.

Planänderungen vor dem Bestätigen sind kostenlos. Als Prototyp ist ein einmaliges
kostenloses vollständiges Umskillen in einer Zwischenphase sinnvoll. Die Klasse
bleibt fest. Umskillen regeneriert weder HP noch Schilde oder Wurzelkraft und
setzt keine Cooldowns zurück. Abhängige Knoten werden gemeinsam zurückgenommen.
Damit bleibt eine frühe Fehlentscheidung korrigierbar, ohne vor jeder Welle
automatisch alle Spezialisierungen wechseln zu können.

## Beispielklasse: Assassine

**Ablauf:** sicheren Anlauf wählen, ein kurzes Nahkampffenster nutzen, sich wieder
lösen oder für einen gezielten Abschluss länger am Gegner bleiben.

### Was die Klasse von Beginn an gibt

| Regel | Prototyp-Vorschlag | Zweck |
| --- | --- | --- |
| Waffen | Nur dafür freigegebene Nahkampfwaffen | Echte Positionierungsgrenze |
| Dashvorrat | 200 statt 100 Wurzelkraft | Zwei schnelle Dashes für Angriff und Rückzug |
| Dashregeneration | Zunächst normale 25/s | Größerer Vorrat ist noch keine schnellere Nachladung; Ausbau im Baum |
| Körperkontakt beim Dash | Normaler Kontaktschaden statt des üblichen 1,5-fachen | Die Klasse kann riskante Wege eher nutzen, bleibt aber verwundbar |
| Klassenfähigkeit **Antritt** | Nach einem normalen Dash verstärkt ein kurzer Zustand den nächsten gültigen direkten Nahkampftreffer | Spielbarer Rhythmus ab Welle 1 |
| Schwäche | Beispielsweise 15 % weniger maximales Schmelz (HP) | Kontaktfehler bleiben relevant; Wert offen für Messung |

Antritt besitzt beispielsweise ein 1-s-Fenster und +20 Prozentpunkte auf den
direkten Waffenschaden dieses Treffers. Der Bonus wird mit bestehenden
prozentualen Angriffsboni addiert, nicht erneut mit allen Procs multipliziert.
Die Werte sind lediglich ein erster Messpunkt.

Antritt gilt **einmal pro Spieler und Dash**, nicht einmal pro Waffe oder
getroffenem Gegner. Ein weiterer Dash ersetzt ein ungenutztes Fenster; er
stapelt keine Trefferladungen. Nur ein akzeptierter direkter Waffentreffer mit
wirksamem Schaden verbraucht es. DoTs, Rückstöße oder Folgeeffekte lösen es nicht
erneut aus. Ein Fehlschlag im leeren Raum verbraucht keine Ladung, aber die Zeit
läuft weiter. Das wird an der Waffe kurz sichtbar.

### Welche Waffen dazugehören

Bohrer, Kratzer, Polierer und Interdental-Bürste sind naheliegende Kandidaten.
Die vollständige Freigabeliste wird vor einer Umsetzung für alle Waffen und
Evolutionen festgelegt.

**Nicht nur den Stat-Schlüssel `melee` prüfen:** Die Zahnseiden-Schneide skaliert
mit Nahschaden, hat aber lange Trefferbahnen. Waffenrolle und Skalierungsattribut
sind unterschiedliche Dinge. Für die Klasse sind ausdrückliche Rollen-/Eignungstags
sinnvoll. Begrenzte Sekundäreffekte einer echten Nahkampfwaffe können erlaubt
sein; ein dauerhaft sicherer Fernangriff darf die Beschränkung nicht aushebeln.

Dieselbe Freigabe gilt in Startauswahl, Shop, Kauf-Fusion, Evolution und
Speicherprüfung. Reine verbotene Waffenangebote werden vor der Angebotswahl
ausgeschlossen. Gemischte Items bleiben möglich, wenn sie einen sinnvollen
Nutzen besitzen. Die Klasse bekommt nicht automatisch ausschließlich optimale
Gift- oder Nahkampfitems.

### Drei Äste im Assassinenbaum

Alle Talente unten sind neu vorgeschlagen. Die ersten zwei Knoten pro Ast haben
je zwei Ränge; Spezialtalent und Abschluss je einen. Die genannten Schadenswerte
und Grenzen müssten in Resources liegen.

| Stufe | Schattenlauf | Giftklinge | Vollstrecker |
| --- | --- | --- | --- |
| Einstieg | **Durchatmen:** +5/+10 Wurzelkraft-Regeneration pro Sekunde | **Giftauftrag:** Antritt kann eine begrenzte Giftdosis auf das getroffene Ziel legen; Rang 2 erhöht das Budget | **Sauberer Schnitt:** Der Nahschaden-Stat trägt bei geeigneten Waffen 10/20 % mehr bei |
| Vertiefung | **Leichter Tritt:** Körperkontakt während des Dashs auf 90/75 % des normalen Schadens reduzieren | **Konzentrat:** Neue Giftdosen dieser Klasse und eigener Giftwaffen werden gezielt stärker | **Präzision:** Höhere Kritchance für den Antrittstreffer; kein dauerhafter Bonus für alle Treffer |
| Spezialtalent | **Schnittwechsel:** Antritt kann ein weiteres Ziel auf der tatsächlich getroffenen kurzen Hiebspur treffen | **Nervengift:** Die Klassen-Giftdosis verlangsamt ihr Ziel kurz; Elite-/Bossregeln begrenzen die Kontrolle | **Zielbindung:** Der Antrittgegner bleibt kurz das bevorzugte erreichbare Ziel geeigneter Waffen |
| Abschluss | **Rückzugsfenster:** Nach erfolgreichem Antritt ist für kurze Zeit genau ein Rückzugsdash günstiger; dieser erzeugt keinen neuen Antritt | **Wanderndes Depot:** Wechsel auf andere nahe Ziele verstärkt den Giftläufer-Ablauf; nur wenige aktive Klassendepots gleichzeitig | **Todesurteil:** Mehrere direkte Treffer auf den Antrittgegner innerhalb eines kurzen Fensters lösen einen begrenzten physischen Abschluss aus |

**Daraus entstehen drei unterschiedliche Assassinen:**

- Schattenlauf: kurz hineingehen, treffen, rechtzeitig heraus. Der günstige
  Rückzug ist Schutz gegen eine gefährliche Situation; er startet keine endlose
  Folge weiterer günstiger Angriffe.
- Giftklinge: nach einem Antritt auf ein anderes erreichbares Ziel wechseln und
  die Depots arbeiten lassen. Derselbe Gegner kann nicht durch ständiges
  Wiederbetreten neue Depot-Sonderboni liefern. Die Zielregel und geringe
  Depotzahl verhindern, dass die stärkste Spielweise nur dauerhaftes Nachsetzen ist.
- Vollstrecker: einen Elitegegner erreichen, bewusst länger bei ihm bleiben und
  den Abschluss erarbeiten. Das ist das Gegenstück zum sofortigen Rückzug.

Die unteren Talente dürfen kombiniert werden. Eine Giftklinge kann beispielsweise
in bessere Nachladung investieren; ein Vollstrecker kann etwas Gift mitnehmen.
Die starken Abschlüsse bleiben alternative Entscheidungen.

### Gift stärker und häufiger, ohne unkontrollierte Trefferketten

Die Klasse darf einen kleinen eigenen Giftzugang freischalten. Dafür muss kein
zufälliges Shopteil fallen. Eine Giftverzauberung bleibt als bewusste Investition
für häufigere reguläre Giftanwendungen sinnvoll.

Die Klassen-Giftdosis ist eine eigene begrenzte Quelle und wird als solche
gemessen. Sie belegt keinen zusätzlichen Waffen-Verzauberungsplatz, vergibt aber
auch kein kostenloses Waffenrang-10-Gift. Das ist mit der bisherigen Regel
„ein Element pro Waffenexemplar“ ausdrücklich zu erklären: Der Klassenproc kommt
von der Klasse und verändert die belegten Waffeneffekte nicht.

Regeln für einen Prototyp:

- Zusätzliche Klassenanwendung nur am gültigen Antritt, mit gemeinsamem
  Klassenintervall und begrenztem Depotbestand, nicht an jedem Kontakt aller
  sechs Waffen.
- Höherer Rang erhöht ein definiertes Giftbudget. Eine spätere schnellere
  Anwendung senkt nicht nebenbei mehrfach die Waffen- und Klassenintervalle.
- Giftticks und Giftkills erzeugen keine neuen Antrittsfenster, Dashes oder
  Giftdosen. Folgeeffekte aktivieren keinen Lebensraub.
- Giftstärke, Bisskraft und Statboni werden an klaren Stellen einmal angewandt.
  Der Nahschaden-Bonus verbessert seinen Statbeitrag; er multipliziert nicht
  zusätzlich alle Giftbudgets.
- Gift-Resistenzen, Gegnerverteidigung und Boss-Schutzbudgets bleiben wirksam.
  Todesurteil ist kein pauschaler Prozentsatz des Bosslebens und kein Instantkill.

### Dashschutz gezielt begrenzen

Die vorgeschlagene Klassenregel betrifft Körperkontakt während des Dashs.
Sie verleiht keine allgemeinen Schutzframes und reduziert nicht automatisch
Geschosse, Bodenflächen und DoTs. Ein eigener Schutz gegen diese Quellen wäre
ein gesondertes Talent mit eigener Bewertung.

Dashkosten, Vorrat, Nachladung und Cooldown bleiben getrennte Parameter.
Reduzierte Kosten oder Erstattungen benötigen eine Untergrenze und dürfen
sich nicht durch ihren eigenen ausgelösten Treffer unbegrenzt refinanzieren.
Speichern oder Umskillen verschenkt keine aktuelle Ladung.

## Weitere mögliche Klassen mit jeweils mehreren Wegen

| Klasse | Sofortiger Kern | Mögliche Äste | Grenze / Risiko |
| --- | --- | --- | --- |
| **Good Old Molar / Basis-Denti** | Klassisches Grundspiel und freie Waffenwahl | Flexible Entwicklung über Waffenmix, Grundwerte und Itemsynergien | Keine spezielle Klassenmechanik, die eine bestimmte Situation besonders stark begünstigt; als vollwertigen Allrounder ausbalancieren |
| **Assassine** | Nahkampf, Dashvorrat, Antritt | Schattenlauf, Giftklinge, Vollstrecker | Kurze sichere Angriffsfenster und geringere Fehlertoleranz |
| **Hüter** | Begrenzter Schutz und kurzes Gegenangriffsfenster nach Block | Vergeltung, Schutzaufbau, Überheilungsnutzung | Schilde sind verbrauchbar; Stillstehen löst die Gefahren nicht dauerhaft |
| **Spültechniker** | Wenige platzierte Wirkflächen | Leitstrecken, Kältekorridore, Druckstöße | Vorbereitung und Stellung; häufige Ortswechsel kosten Nutzen |
| **Artillerist** | Ausgeprägte Salven mit erkennbarer Erholungsphase | Präzision, Flächenbombardement, Rückflugbahnen | Angriff und sicherer Stellungswechsel müssen zeitlich zusammenpassen |

Weitere Waffenverbote sind kein Pflichtmerkmal jeder Klasse. Eine echte
Funktionsgrenze kann auch durch Stellungsbindung, Verbrauch oder ein kurzes
Wirkfenster entstehen. Allgemeine Items sollen klassenübergreifend bleiben.
Elemente werden nicht exklusiv einer Klasse zugewiesen: Gift kann beim
Assassinen über Nahkampferöffnungen und beim Techniker über vorbereitete Flächen
funktionieren. Die Anwendung und der Spielrhythmus erzeugen den Unterschied.

## Freischaltungen und Wiederspielwert

Good Old Molar ist immer von Anfang an zugänglich. Für den ersten Versuch ist
auch der Assassine sofort zugänglich. Der Test der
Klassenidee soll nicht erst hinter einer langen Freischaltung liegen.

Spätere Klassen können durch kurze thematische Aufgaben freigeschaltet werden.
Alternative Abschlussknoten dürfen langfristige Entdeckungen sein, sollten aber
gleichwertige andere Möglichkeiten bieten. Alle wesentlichen Funktionen einer
Klasse und mindestens zwei tragfähige Wege sind von Anfang an erreichbar.
Kein dauerhafter Meta-Punkt muss vor einem fairen Versuch erst gefarmt werden.

Der Run-Skilltree setzt zurück. Klassenfreischaltung und Kosmetik bleiben.
Auch ein erfahrener Assassine verteilt im nächsten Run neu und reagiert auf die
tatsächlich gefundenen Waffen und Items.

## Darstellung

Klassenwahl in die vorhandene Run-Vorbereitung integrieren. Auf der Klassenkarte
genügen eine klare Stärke, eine Grenze und ein kurzes Motiv. Die Waffenauswahl
zeigt anschließend passende Starts. Denti bleibt derselbe erkennbare Molar;
Klasseninszenierung verlangt keine dauerhaft bewaffnete neue Grundfigur.

Im Baum: gemeinsamer Attributbereich und drei kurze Äste, sichtbare Punktzahl,
gut erkennbare Verbindungslinien. Details erscheinen beim Anwählen. Kein großer
frei verschiebbarer ARPG-Sternenhimmel. Auf dem Handy werden die Äste als
kurze wählbare Spalten/Ansichten dargestellt, statt den gesamten Baum zu verkleinern.
Gesperrte Knoten nennen genau die fehlende Bedingung.

Die Kampfansicht zeigt nur den relevanten kurzen Zustand, etwa Antritt. Der
Skilltree schafft keine zusätzlichen Pflichtanzeigen für jeden Ast.

## Technische Schnittstellen für eine spätere Umsetzung

- `ClassData`: Startregeln, erlaubte Waffenrollen, Baum, Grenzen und Darstellung.
- `TalentNodeData`: stabile ID, Ränge, Kosten, Voraussetzungen, Effekt und
  gegebenenfalls exklusive Abschlussgruppe.
- Eigener Zustand für gewählte Klasse, verdiente/ausgegebene Punkte und Ränge.
  Vorschau und Bestätigung ändern die gesamte Verteilung atomar.
- Permanente Statbeiträge gehen in das vorhandene `PlayerStats`-Modell.
  Kein zweiter vollständiger Klassen-Statrechner. Bedingte Klassenfähigkeiten
  werden durch kleine Komponenten an Dash, Treffer und Statusereignisse gebunden.
- Ein gemeinsamer Eignungstest prüft Waffen und Evolutionsresultate bei allen
  Erwerbswegen. Darstellung und Kampf dürfen verschiedene Verbote nicht doppeln.
- `PostWaveRewards` bleibt der einzige Ablaufkoordinator. Skillpunkte und
  reservierte Vorschau dürfen beim Fortsetzen nicht doppelt vergeben werden.
- Neue Saves brauchen Klassen-/Baumversion, Ränge, verdiente und offene Punkte
  sowie aktive Klassenfenster, Zielreferenzen und Intervalle.
- Laufende alte Saves behalten ihre bisherigen Attribute und den bisherigen
  Level-up-Ablauf. Keine rückwirkenden freien Klassenpunkte oder erzwungene
  Waffenentfernung mitten im Run. Der neue Modus beginnt mit einem neuen Run.

## Sinnvoller erster Umsetzungsschritt

1. **Good Old Molar und Assassine**, zunächst zwei Klassenprofile; noch keine weiteren
   Klassen und kein dauerhafter Meta-Techtree.
2. Gemeinsame Punkte-/Baumgrundlage mit zwölf Assassinen-Talenten, normalen
   Attributen, eindeutiger Waffenfreigabe und Save/Resume. Giftweg und
   Schattenlauf müssen vor einem großen Ausbau bereits anders spielbar sein.
3. Danach ein **Hüter** als kontrastierender Test derselben Architektur. Ein
   Allrounder plus nur eine Spezialklasse beweisen noch keine Vielfalt.

Prüfen: erste fünf Wellen samt verdientem Einkommen, normale Horden,
Elitebegegnung, isolierter Boss und längerer Run. Klassenboni ersetzen bewusst
einen Teil bisheriger Möglichkeiten; der Assassine erhält nicht gleichzeitig
unverändert alle alten Statbelohnungen plus einen vollständig kostenlosen Baum.

Wichtige Abnahmekriterien:

- Klassenidentität ist in Welle 1 erkennbar, ohne seltene Pflichtitems.
- Zwei Assassinenwege verlangen erkennbar anderes Verweilen am Gegner.
- Weder Baum noch Giftklinge müssen mit jedem Assassinen identisch geskillt werden.
- Kein verbotener Fernkampfstart oder Evolutionsumweg; mehrere Starts bleiben
  tatsächlich spielbar.
- Dashschutz und Rückzug trivialisieren weder Kontakt noch Projektilmuster.
- Punkte, Abschlussgrenze und gespeicherte Klassenfenster überstehen Fortsetzen.
- Aktiver Kampf wird weiterhin nicht unterbrochen; Loot kommt vor der Skillwahl,
  die vollständige Belohnungsphase vor dem Shop.
- Der Baum bleibt auf Mobilgeräten schnell bedienbar. Mehrere verdiente Punkte
  verursachen einen gemeinsamen Besuch, keine Reihe neuer Unterbrechungen.
- Tests vergleichen Stats, Sustain, Bosszeit, Gold, Nachladezeit und Laufwege.
  Menschliche Runs entscheiden zusätzlich über Verständlichkeit und Spielfreude.
