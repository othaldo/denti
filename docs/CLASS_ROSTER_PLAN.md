# Klassenplan: vier weitere Klassen

Entwurf vom **20.11.2026**. **Umgesetzt am selben Tag**, alle vier Klassen sind
spielbar; Werte sind Schätzungen, Spieltests stehen aus. Porträts und Symbole
fehlen noch (Platzhalter), Auftrag: [ROSTER_ART_BRIEF.md](ROSTER_ART_BRIEF.md).

**Technik:** Jede Klasse hat ein `ClassSkillModule`
(`scripts/player/fairy_skills.gd`, `ember_skills.gd`, `rinser_skills.gd`,
`frost_skills.gd`), registriert in `ClassSkillRegistry`. Spieler, Spiel und
Spielstand reichen Ereignisse und Zustand generisch an alle Module weiter; ein
Modul handelt nur für seine eigene Klasse. Klassen- und Baumdaten erzeugt
`tools/generate_class_roster.py`. Tests: `tests/class_roster.gd`.

**Abweichungen vom Entwurf:** Frostwächter-Ast Gletscher hat statt Eiskorridor
den Skill **Frostwelle** (vergehende Wände zerspringen). Zerschmettern ist der
Skill des Bruch-Asts. Zahnfee-Talente nutzen teils vorhandene Item-Effekte
(Münzbonus, XP-Heilung, Wellenschild), ebenso Glutdornen und Heiße Sohlen. Grundlage ist das Schema aus
[CLASS_ESSENCE.md](CLASS_ESSENCE.md): **Verb + Linse + Verzicht**, dazu je Klasse ein
Baum mit drei Ästen, je einem Skill und Modifikatoren wie in
[TALENT_TREE_V3_PLAN.md](TALENT_TREE_V3_PLAN.md).

## Ausgangslage

| Klasse | Verb | Element | Hordenumgang |
| --- | --- | --- | --- |
| Good Old Molar | keines, Ausrüstung | frei | alles |
| Assassine | Dash zieht Giftschneise | Gift | hindurch |

Im Spiel gibt es sieben Waffenelemente: Feuer, Eis, Elektro, Wasser, Gift,
Blutung und Weihe. Dazu kommen drei Reaktionen: **Frost** (Eis + Wasser),
**Dampf** (Feuer + Wasser) und **Giftstichflamme** (Gift + Feuer). Die neuen Klassen
decken Wasser/Elektro, Eis, Feuer und Weihe ab, und jede bekommt einen anderen
Hordenumgang. Gift bleibt beim Assassinen, Blutung bleibt klassenfrei, denn die
Itemfamilie trägt sie schon gut.

| Klasse | Verb | Element | Hordenumgang | Gegenpol zu |
| --- | --- | --- | --- | --- |
| **Spültechniker** | Laufspur macht den Boden nass, Strom folgt ihr | Wasser + Elektro | Raum vorbereiten, hinterherlocken | Assassine (Strecke statt Schnitt) |
| **Frostwächter** | Dash wird zur Eiswand | Eis | Umlenken, kanalisieren | Assassine (blocken statt durchqueren) |
| **Glutzahn** | Hitze aufbauen, im Gedränge ausbrechen | Feuer | Hineinspielen, Timing | Molar-Schmelzwall (Angriff statt Abwehr) |
| **Zahnfee** | Beute einsammeln feuert Licht | Weihe + Glück | Durch die Beute laufen | Alle (Wege durch Loot statt durch Gegner) |

Jede Klasse ist **ohne** ihr Element-Item spielbar. Das Element ist die Linse,
nicht die Pflicht.

---

## 1. Spültechniker – „Erst wischen, dann zünden“

- **Verb:** Beim Laufen bleibt eine begrenzte Spülspur liegen (wenige Segmente,
  wenige Sekunden). Gegner darauf sind nass. Elektrotreffer und Kettenblitze
  springen **entlang der Spur** zu allen Gegnern darauf. Der Dash spült die ganze
  Spur einmal durch (ein Stromstoß über alle Segmente).
- **Hordenablauf:** Schleife ziehen → Horde läuft hinterher auf die Spur → zünden
  (Dash oder ein Elektrotreffer) → neue Schleife.
- **Linse:** Wasser- und Elektro-Verzauberungen, Leitlack (längere Spur, stärkerer
  Strom), Spülventil (Treffer verlängern Segmente), Kettenfamilie, Bewegung
  (mehr Spur pro Zeit). Reaktion Frost zahlt sich aus, wenn Eis dazukommt.
- **Verzicht:** −15 % direkter Waffenschaden, Ertrag kommt über Spur und Ketten.
  Wer stehen bleibt, hat keine Spur.
- **Waffen:** frei. 6 Wurzeln.

| Ast | Skill | Modifikatoren (Auswahl) |
| --- | --- | --- |
| **Leitung** (Elektro) | **Kurzschluss:** Treffen sich zwei Spurenden, schließt sich der Kreis und jagt alle 2 s Strom durch alles darin | Starkstrom, Funkenregen, Erdung (Schild bei vielen Treffern) |
| **Spülung** (Wasser) | **Schwall:** Der Dash schiebt alle nassen Gegner ein Stück in Dashrichtung | Sog (zieht statt schiebt), Pfützenteppich, Schaumbad (verlangsamt) |
| **Wartung** (Verteidigung) | **Notdusche:** Bei wenig Leben spült eine Welle um Denti Gegner und Geschosse weg | Kalkschutz, Nachspülen, Tropfsteinschild |

Technischer Bedarf: Laufspur (Segmentliste wie die Giftschneise), Kettenzustand
entlang der Spur. Wiederverwendbar: `ClassDashCut`-Muster, Nass-Status,
`ItemInventory`-Kettenlogik, Spülventil-Pfützen.

---

## 2. Frostwächter – „Bis hierhin und nicht weiter“

- **Verb:** Der Dash bewegt Denti und hinterlässt entlang des Weges eine **Eiswand**
  für wenige Sekunden. Gegner können sie nicht durchqueren, sie stauen sich
  davor und werden dabei unterkühlt (Sprödigkeit). Ein schwerer Treffer auf einen
  spröden Gegner zerschmettert ihn mit Splittern.
- **Hordenablauf:** Wand quer zur Horde setzen → Gegner laufen außen herum oder
  stauen sich → Engstelle mit Flächenwaffe bearbeiten → nächste Wand.
- **Linse:** Eis-Verzauberungen, Wucht/Rückstoß (gegen die Wand drücken),
  Krit-Familie (Zerschmettern kritisch), Fluorid-/Schildfamilie. Mit Wasser
  entsteht die Reaktion Frost.
- **Verzicht:** −10 % Bewegung, nur ein Dash im Vorrat, langsame Nachladung. Die
  Wand blockt keine Geschosse.
- **Waffen:** frei, Bonus-Skalierung für schwere Waffen (Schleuder, Kronenwerfer,
  Speer). 6 Wurzeln.

| Ast | Skill | Modifikatoren (Auswahl) |
| --- | --- | --- |
| **Gletscher** (Kontrolle) | **Eiskorridor:** Zwei Wände, die sich nahe kommen, verbinden sich zu einem Gang, durch den nur ein Gegner gleichzeitig passt | Dauerfrost, Rutschbahn, Zackenwand |
| **Bruch** (Schaden) | **Zerschmettern:** Spröde Gegner zerbersten bei schwerem Treffer, Splitter treffen Nachbarn | Kettenbruch, Eiszapfen, Schockfrost |
| **Wacht** (Verteidigung) | **Eisrüstung:** Solange eine Wand steht, +Härte und Rückstoß bei Kontakt | Raureif, Frostatem, Kältestarre |

Technischer Bedarf: Blockierende Wandsegmente in der Gegnerbewegung
(`enemy_motion`/`CENTRAL_ENEMY_MOTION`), Bossausnahme (Bosse brechen Wände),
Sprödigkeit als Status. Das ist der aufwendigste Kandidat, weil er die Gegnerwege
verändert.

---

## 3. Glutzahn – „Heiß gelaufen“

- **Verb:** Treffer und Nähe zu Gegnern laden **Hitze** auf. Bei voller Hitze
  bricht Denti automatisch aus: eine Feuernova um ihn, die mit der Zahl naher
  Gegner stärker wird. Danach kurz **überhitzt** (langsamer Angriff). Die
  Entscheidung ist, wann man mitten in der Horde steht.
- **Hordenablauf:** Hitze am Rand aufbauen → bei fast voll in die Masse laufen →
  Ausbruch → abkühlen und wieder an den Rand.
- **Linse:** Feuer-Verzauberungen, Zucker (Bewegung im Gedränge), Härte und
  Schmelz (das Gedränge aushalten), Dampf (mit Wasser) und Giftstichflamme (mit
  Gift) als Reaktionen.
- **Verzicht:** Weniger Schmelz, Überhitzung, schwacher Fernkampf
  (Fernwaffen −20 % Schaden).
- **Waffen:** frei, Nahkampf bevorzugt. 5 Wurzeln.

| Ast | Skill | Modifikatoren (Auswahl) |
| --- | --- | --- |
| **Esse** (Feuer) | **Glutkern:** Der Ausbruch hinterlässt einen brennenden Boden, der weiter Hitze lädt | Nachglühen, Funkenflug, Schmiedefeuer |
| **Dampfkessel** (Tempo) | **Druckablass:** Den Ausbruch per Dash sofort auslösen, dafür halbe Kraft | Kesselpfeife, Volldampf, Sicherheitsventil |
| **Hitzeschild** (Verteidigung) | **Glühende Haut:** Bei hoher Hitze verbrennen Gegner, die Denti berühren | Asbestschmelz, Schlacke, Abkühlung |

Technischer Bedarf: Hitzeleiste im HUD (eine kleine Anzeige am Lebenszahn), Nova
über `nearby_enemies`, Brennboden über `GroundEffects`. Mittlerer Aufwand.

---

## 4. Zahnfee – „Für jeden Zahn eine Münze“

- **Verb:** Die Zahnfee hat kaum Beutemagnet. Jede eingesammelte Beute (XP,
  Münze, Kapsel) feuert einen kleinen **Lichtsplitter** auf den nächsten Gegner.
  Wer durch die Beute läuft, kämpft. Der Dash ist ein längerer, langsamer
  **Gleitflug**.
- **Hordenablauf:** Gegner sterben, Beute fällt → Route durch die Beutefelder
  planen → Lichtsalven beim Einsammeln → Gegner folgen der Route.
- **Linse:** Glück (mehr Beute, mehr Splitter), Münzfamilie und Goldsonde,
  Zahnfee-Pakt (XP heilt), Weihe- und Krit-Familie (Splitter können kritisch
  treffen), Runenpolitur.
- **Verzicht:** Kleiner Beutemagnet, Waffen −15 % Schaden, nur 5 Wurzeln. Beute
  am Wellenende wird trotzdem eingesammelt (Loot-Sweep bleibt).
- **Waffen:** frei. 5 Wurzeln.

| Ast | Skill | Modifikatoren (Auswahl) |
| --- | --- | --- |
| **Glanz** (Weihe) | **Feenstaub:** Jede 20. eingesammelte Beute löst einen Lichtregen über den Bildschirm aus | Sternschnuppe, Heiligenschein, Funkelzauber |
| **Schatzkammer** (Glück) | **Kopfgeld:** Elite- und Bosstreffer werfen kleine Münzen ab, die nur die Fee sieht | Zinsfee, Goldene Zähne, Glückspilz |
| **Kissen** (Verteidigung) | **Zahnkissen:** Unter dem Kopfkissen gesammelte Beute gibt Schilde | Sanfter Schlaf, Federbett, Nachtwache |

Technischer Bedarf: Hook beim Einsammeln (`Loot`), Magnet-Radius pro Klasse,
Gleitdash (`DashData` kann Länge und Dauer schon). Geringer Aufwand.
Achtung: Glücks-Schneeball begrenzen, die Splitterrate daher pro Sekunde deckeln.

---

## Vergleich

| | Spültechniker | Frostwächter | Glutzahn | Zahnfee |
| --- | --- | --- | --- | --- |
| Bewegung | ständig laufen | Positionen setzen | rein und raus | Routen durch Beute |
| Dash | Spur zünden | Eiswand | (Druckablass) | Gleitflug |
| Risiko | Stillstand = nichts | wenig Mobilität | Überhitzung, wenig Leben | wenig Magnet und Schaden |
| Aufwand | mittel | hoch | mittel | gering |
| Neue Systeme | Laufspur | blockierende Wände | Hitze + Nova | Beute-Hook |

## Empfohlene Reihenfolge

1. **Zahnfee:** geringster Aufwand, ganz anderes Spielgefühl, testet die
   Klassenauswahl mit drei Einträgen.
2. **Glutzahn:** Feuer bekommt endlich ein Zuhause, das Hitze-System ist klar
   abgegrenzt.
3. **Spültechniker:** nutzt viele vorhandene Wasser-/Elektro-Items.
4. **Frostwächter:** zuletzt, weil Wände die Gegnerbewegung und Bossmuster berühren.

Jede Klasse kommt einzeln, mit Baum, Tests, Vorschau und einem Spieltest, bevor
die nächste startet.

## Später denkbar

- **Fadenmeister** (Blutung): Spannt Zahnseide zwischen Gegnern; Laufen zieht die
  Fäden straff.
- **Kariesteufel** (Zucker): Gegnerdichte gibt Tempo, Abstand lässt es zerfallen.
  Hohes Risiko, hoher Ertrag.
