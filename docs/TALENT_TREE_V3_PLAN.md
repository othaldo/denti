# Talentbaum v3: Ziele, Skills und gebundene Wurzeln

Plan vom **20.11.2026** nach dem Molar-Spieltest bis Welle 10.
**Umgesetzt: Schritt A, B, C und F.** D (Hybride) und E (Rezepte) sind offen.

## Befund aus dem Spieltest

- **Molar-Talente fühlen sich wie Items an.** Das stimmt wörtlich: Spritzspülung,
  Funkenbrücke, Glanzfunke, Glanzprisma, Rückholfeder und Splitterschmelz sind
  schwächere Kopien vorhandener Items. Werkzeugvielfalt, Elementmix und Gleiches
  Werkzeug sind unsichtbare Prozente. Im Baum gibt es nichts, auf das man
  hinarbeiten will.
- **Werkzeugkasten bleibt liegen.** Er verlangt Investition, bringt aber nur
  Prozente auf einen Loadout, den man ohnehin hat.
- **Freie Wurzeln sind unklar.** Nach dem Übernehmen ist die gewählte Eigenschaft
  nicht mehr sichtbar. Jeder Rang darf ein anderes Attribut sein, dadurch hat der
  Knoten keine Identität.
- **Bosse gaben nur ~1 Levelpunkt** (behoben: Bossstages geben jetzt 4–5 Punkte,
  siehe [BOSS_STAGES.md](BOSS_STAGES.md)).

Grobe Punktezahl: bis Welle 10 rund 20–25 Punkte, bis Welle 20 rund 50–60.
Damit reicht es für ein bis zwei tiefe Äste, nicht für alles. Diese Knappheit
ist gewollt und macht Ziele erst wertvoll.

## Leitlinie: Wer macht was

| Ebene | Aufgabe | Nicht |
| --- | --- | --- |
| **Attribute** (Kreise) | Zahlen | – |
| **Items** (Shop) | Zahlen, Procs, Familien | – |
| **Talente** (Kacheln) | Regeln ändern, Mechaniken verbinden | keine Item-Kopien, keine reinen Prozente |
| **Skills** (große Knoten) | sichtbare, automatische Fähigkeiten, auf die man hinarbeitet | keine Statboni |

Ein Talent darf ein Item **verändern**, aber nie **ersetzen**.
Beispiel: Nicht „Krits explodieren mit 15 %“, sondern „Generalprobe löst bei Krit
deine Glanzpaste-Explosion zusätzlich aus“.

## 1. Freie Wurzeln werden gebunden

- Der erste Punkt in einer freien Wurzel **bindet** sie an ein Attribut. Danach ist
  sie ein normaler Attributknoten mit diesem Symbol und einem kleinen Wurzel-Marker.
  Weitere Ränge steigern nur noch dieses Attribut.
- Solange der Entwurf nicht übernommen ist, löst „Rückgängig“ die Bindung wieder.
- Die Bindung wird gespeichert (`talents.bound: {knoten_id: attribut}`).
  Alte Spielstände mit Rängen, aber ohne Bindung, binden beim nächsten Punkt.
- **Wurzelbund (Ziel):** Drei Wurzeln an dasselbe Attribut gebunden geben einen
  einmaligen Bonusrang dieses Attributs. Die Detailbox zeigt den Fortschritt (2/3).
  Das macht die Wahl zu einer kleinen Planungsentscheidung statt Beliebigkeit.

**Stand A:** `TalentProgression.bound` speichert Bindungen (`talents.bound` im
Spielstand). Ein Entwurf bindet mit seinem ersten Punkt, Rückgängig löst das. Ein
gespeicherter Entwurf, der eine gebundene Wurzel umstellt, wird abgewiesen. Alte
Spielstände ohne `bound` binden beim nächsten Punkt. Der Wurzelbund zahlt den
Bonusrang genau einmal, im Moment der dritten Bindung, mit derselben Seltenheit.

## 2. Knotentypen mit eigener Form

| Form | Typ | Bedeutung |
| --- | --- | --- |
| Kreis | Attribut | Zahl, mehrere Ränge |
| Kreis mit „+“ / Wurzel-Marker | Freie Wurzel | ungebunden / gebunden |
| Abgerundetes Quadrat | Talent | Regeländerung |
| **Großer Diamant** | **Skill** | sichtbare Fähigkeit, Ziel des Astes |
| Kleine Raute unter dem Skill | Skill-Modifikator | verändert den Skill, nur mit Skill nutzbar |
| Achteck mit dunklem Rand | Schlüsselstein | starker Tausch mit Nachteil |
| Knoten auf der Grenze zweier Äste | Hybrid | braucht Punkte in beiden Ästen |

**Stand B:** `TalentNodeData.kind` ist `""`, `skill`, `modifier` oder
`keystone`. Die vier bisherigen Schlüsselsteine sind markiert. Ein Talent mit
`icon_index < 0` zeichnet den Platzhalter.

Neue Skill-Knoten bekommen zunächst ein **Platzhaltersymbol** (gestrichelter Rahmen
mit Anfangsbuchstaben). Die gemalten Symbole erzeugst du später mit Codex;
die Motive stehen unten.

## 3. Aufbau eines Astes

| Reihe | Inhalt |
| --- | --- |
| 0–1 | Attribute, ein Einstiegstalent, eine freie Wurzel |
| 2 | **Gabel:** zwei Talente, die den Ast in zwei Richtungen lenken |
| 3 | **Skill** (großer Diamant) |
| 4 | zwei bis drei Skill-Modifikatoren |
| 5 | Schlüsselstein |

Der Skill erscheint so früh (Reihe 3 ≈ 9 Punkte), dass man ihn in einem Run
**vor dem ersten Boss oder kurz danach** erreicht und den Rest des Runs damit spielt.

## 4. Good Old Molar: drei Skills statt Item-Kopien (umgesetzt)

Jeder Ast hat jetzt 18 Knoten in sechs Reihen: Attribute und freie Wurzeln,
Einstiegstalente, in Reihe 3 der **Skill** (9 Punkte im Ast), in Reihe 4 drei
Modifikatoren, in Reihe 5 Schlüsselstein und Abschluss. Code:
`scripts/player/molar_skills.gd`, Daten: `data/talents/good_old_molar.tres`.

### Werkzeugkasten → Skill **Generalprobe**
Alle 8 s greifen **alle** ausgerüsteten Waffen gleichzeitig mit +50 % Schaden an,
mit goldenem Ring. Ohne Ziel in Reichweite wartet die Salve, statt zu verfallen.

| Knoten | Wirkung |
| --- | --- |
| Zugabe | Jede 3. Generalprobe wiederholt sich nach 0,35 s. |
| Elementfeuerwerk (2) | Verzauberte Waffen explodieren beim Salvenangriff mit ihrem Element, 35 % ihres Schadens je Rang im Umkreis. Verbindet den Ast mit Elementmix und Verzauberungen. |
| Schnellgriff | Nach einer Generalprobe 3 s lang +25 % Angriffstempo. |
| Lampenfieber (2, unter Zugabe) | Generalprobe 1 s früher je Rang. |
| Bunter Koffer | Schlüsselstein, unverändert. |

### Fachpraxis → Skill **Gleichtakt**
Jeder 5. Angriff einer mehrfach ausgerüsteten Waffe öffnet eine Salve **aller**
Exemplare: +60 % Schaden, garantiert kritisch, mintfarbener Ring. Die erzwungenen
Salvenangriffe zählen nicht für den nächsten Gleichtakt.

| Knoten | Wirkung |
| --- | --- |
| Meisterhand (2) | Waffen ab Mk III greifen 8 % schneller an je Rang. |
| Serienfertigung (2) | Gleichtakt bei jedem 4., mit zwei Rängen jedem 3. Angriff. |
| Schockwelle | Die Salve erschüttert ihr Ziel: 50 % Waffenschaden im Umkreis. |
| Taktgeber | Nach einer Salve greift dieser Waffentyp 3 s lang 20 % schneller an. |
| Fachidiot | Schlüsselstein, unverändert. |

### Standfest → Skill **Schmelzwall**
Ein geblockter Schildtreffer oder 1 s Stillstand entlädt einen Ring (130 px):
Gegner werden 70 px weggestoßen, gegnerische Standardgeschosse zerplatzen.
Stillstand-Ring alle 10 s, Schildblock frühestens 1 s nach dem letzten Ring.
Bossmuster aus eigenen Salvenobjekten werden bewusst nicht gelöscht.

| Knoten | Wirkung |
| --- | --- |
| Splitterring (2) | Ringschaden 12 + 4 je Härte, je Rang, mit Bisskraft. |
| Amalgamguss | Jedes zerplatzte Geschoss heilt 1 Leben, höchstens 6 je Ring. |
| Nachhall | Stillstand-Ring alle 6 s, Ring 30 px größer. |
| Unverrückbar | Schlüsselstein: −20 % Bewegung, +6 Härte, Ring 50 % größer, Härte zählt für Splitterring doppelt. |

Abgrenzung zum geplanten **Hüter**: Der Hüter *ist* ein Standhalte-Verb (Stampfer statt
Dash). Beim Molar ist Schmelzwall eine Belohnung für Schilde und Stillstand, kein Ersatz
des Dashs.

**Entfernt und erstattet:** Spritzspülung, Funkenbrücke, Glanzfunke, Glanzprisma,
Rückholfeder, Splitterschmelz (Item-Kopien) sowie der Zahnflutsch-Knoten. Erstattete
Punkte landen in den offenen Levelpunkten; liegt der Spielstand schon nach der
Levelverteilung (z. B. im Shop), werden sie in die nächste Welle übertragen
(`rewards.carry_levels`).

## 5. Hybridknoten: Ziele zwischen den Ästen

Ein Knoten auf der Grenze zweier Äste. Er braucht **je 6 Punkte in beiden** und
verbindet deren Skills:

- **Werkstattmeister** (Werkzeug × Fach): Die Generalprobe feuert einen
  Gleichtakt-Verschmelzungsschuss je Waffentyp mit mindestens zwei Exemplaren.
- **Gepanzertes Besteck** (Fach × Standfest): Ein Schmelzwall setzt den
  Gleichtakt-Zähler auf „nächste Salve verschmilzt“.
- **Notfallkoffer** (Standfest × Werkzeug): Ein gebrochener Schild löst sofort
  eine Generalprobe aus (eigene Abklingzeit 12 s).

Hybride sind teuer, aber das klare Ziel für Mischbuilds.

## 6. Rezeptknoten: Baum und Shop verbinden

Einige Skill-Modifikatoren tragen ein **Item-Symbol** als Bedingung. Sie sind immer
kaufbar, wirken aber erst, wenn ein Item dieser Familie besessen wird; bis dahin
zeigt der Knoten „schläft“. So entsteht im Shop ein Wunsch-Item.

Beispiele: Generalprobe + **Spülventil**: jede Salve hinterlässt Pfützen.
Gleichtakt + **Blutungsuhr**: Verschmelzungsangriffe stapeln Blutung bis 6.
Schmelzwall + **Speichelkelch**: der Ring heilt um gesperrte Projektile.

Der Shop gewichtet Items mit offener Rezeptbedingung etwas höher (Build-Tags).

## 7. Assassine (umgesetzt)

Gleiches Schema: 18 Knoten je Ast, Skill in Reihe 3, drei Modifikatoren in Reihe 4,
Schlüsselstein in Reihe 5. Die Giftschneise bleibt das Klassenverb; die Skills
bauen darauf auf. Code: `scripts/player/assassin_skills.gd`.

### Giftspur → Skill **Giftblüte**
Gegner, die bis 6 s nach einem Schneisentreffer sterben (auch durch die Schneise
selbst), platzen zu einer Giftwolke (60 px, 2,5 s), die alle 0,5 s ein Viertel des
Schneisengifts auf Gegner darin legt. Höchstens 6 Wolken gleichzeitig.

| Knoten | Wirkung |
| --- | --- |
| Kettenblüte | Gegner in einer Wolke gelten als getroffen; sterben sie, platzt eine neue Wolke. |
| Dichter Nebel | Wolken 25 px größer und 1,5 s länger. |
| Platzende Blüte | Eine Wolke trifft beim Entstehen alle Gegner darin mit 50 % Spurschaden. |
| Giftschneise | Schlüsselstein, unverändert. |

### Zuckerrausch → Skill **Rausch**
Drei Dashes binnen 4 s lösen einen Zuckerrausch aus: 4 s lang kosten Dashes keine
Wurzelkraft, die Schneise ist 40 % breiter, ein pinker Ring umgibt Denti. Danach
2 s Zuckerkater mit −25 % Bewegung. Die Dash-Abklingzeit bleibt bestehen.

| Knoten | Wirkung |
| --- | --- |
| Zuckerguss | Im Rausch schnappt die Schneise sofort zu. |
| Kein Kater | Kein Zuckerkater. |
| Hyperaktiv | Rausch schon nach zwei Dashes, 1,5 s länger. |
| Sprintfaden | Schlüsselstein, unverändert. |

### Zahnpflege → Skill **Durchflutschen**
Der Dash zerplatzt gegnerische Standardgeschosse auf seinem Weg (30 px um die
Bewegungsstrecke). Das erste je Dash gibt 1 Schild, höchstens alle 6 s. Bossmuster
aus eigenen Salvenobjekten bleiben bestehen.

| Knoten | Wirkung |
| --- | --- |
| Heilflutsch | Jedes zerplatzte Geschoss heilt 1 Leben, höchstens 4 je Dash. |
| Spiegelschmelz | Jedes zerplatzte Geschoss trifft den nächsten Gegner mit 50 % Spurschaden und Spurgift. |
| Schildpolitur | Schild schon alle 3,5 s. |
| Federleicht | Schlüsselstein: −20 Schmelz, +10 % Bewegung, Durchflutschen im 1,6-fachen Umkreis. |

Der Zahnpflege-Ast bekam außerdem einen Zahnflutsch- und einen Wurzelkraft-Knoten
und zwei weitere freie Wurzeln. Eine überzählige freie Wurzel der Giftspur fiel weg
und wird erstattet.

## Umsetzungsreihenfolge

| Schritt | Inhalt | Prüfung |
| --- | --- | --- |
| **A** ✓ | Freie Wurzeln binden, anzeigen, Wurzelbund | Save/Resume, Undo, alte Saves |
| **B** ✓ | Knotentypen und Formen, Platzhaltersymbole, Datenfeld `kind` (`hybrid_branches`, `requires_item` folgen mit D/E) | Layouttests auf allen Formaten |
| **C** ✓ | Molar: drei Skills mit Modifikatoren, Item-Kopien entfernen, Erstattung | Kampftests je Skill, Grenzen, keine Rekursion |
| **D** | Hybridknoten | Freischaltung, Darstellung schmal/breit |
| **E** | Rezeptknoten und Shop-Gewichtung | Aktiv/schlafend, Tags |
| **F** ✓ | Assassine nach demselben Schema | wie C |

Jeder Schritt ist für sich spielbar. Nach C ist ein Spieltest sinnvoll, bevor D–F folgen.

## Platzhalter → Motive für Codex

Diese Knoten haben `icon_index = -1` und zeigen den gestrichelten Platzhalter.

| Knoten (ID) | Motiv |
| --- | --- |
| Generalprobe (`tool_rehearsal`) | Werkzeugkasten, aus dem alle Instrumente gleichzeitig herausspringen, goldener Blitz |
| Zugabe (`rehearsal_encore`) | zwei überlagerte goldene Blitze mit Notenzeichen |
| Elementfeuerwerk (`rehearsal_fireworks`) | Feuerwerksrakete aus Zahnpasta-Tube, vier Elementfarben im Funkenregen |
| Schnellgriff (`rehearsal_quickdraw`) | Hand, die blitzschnell eine Zange greift, Bewegungslinien |
| Lampenfieber (`tool_rehearsal_quick`) | Scheinwerfer auf kleiner Bühne mit nervösen Schweißtropfen |
| Meisterhand (`spec_master`) | Mk-Abzeichen mit Lorbeer und Zahnsilhouette |
| Gleichtakt (`spec_unison`) | zwei identische Kratzer, deren Spitzen synchron leuchten, Metronom |
| Serienfertigung (`unison_rate`) | Fließband mit identischen Bohrern |
| Schockwelle (`unison_shock`) | Zahn mit konzentrischen Erschütterungsringen |
| Taktgeber (`unison_haste`) | Metronom mit mintfarbenem Pendel und Tempo-Pfeilen |
| Schmelzwall (`stand_bulwark`) | aufplatzender Schmelzring, abprallende Geschosse |
| Splitterring (`wall_shards`) | Ring aus Zahnschmelzsplittern |
| Amalgamguss (`wall_heal`) | zerplatztes Geschoss, das zu silbrigen Heiltropfen wird |
| Nachhall (`wall_echo`) | doppelter Ring mit Echo-Wellen |
| Unverrückbar (`wall_anchor`) | Backenzahn mit tiefen Wurzeln im Boden, Ankersymbol |

| Giftblüte (`venom_bloom`) | aufplatzende grüne Giftblüte mit Totenkopf-Zahn in der Mitte |
| Kettenblüte (`bloom_chain`) | drei verbundene Giftblasen in Kettenform |
| Dichter Nebel (`bloom_dense`) | dicke grüne Nebelwolke mit Zahnsilhouette |
| Platzende Blüte (`bloom_burst`) | explodierende Giftknospe mit Spritzern |
| Rausch (`rush_frenzy`) | Bonbon mit Blitz und pinken Geschwindigkeitslinien |
| Zuckerguss (`rush_glaze`) | glänzender Zuckerguss, der über eine Zahnseide läuft |
| Kein Kater (`rush_nocrash`) | fröhlicher Zahn mit Sonnenbrille neben leerer Bonbontüte |
| Hyperaktiv (`rush_hyper`) | zitternder Lolli mit doppelten Bewegungslinien |
| Durchflutschen (`care_slip`) | Denti als Schemen, der durch ein zerplatzendes Geschoss gleitet |
| Heilflutsch (`slip_heal`) | Geschosssplitter, die zu Heiltropfen werden |
| Spiegelschmelz (`slip_mirror`) | spiegelnder Schmelz, der einen grünen Pfeil zurückwirft |
| Schildpolitur (`slip_polish`) | Polierkopf auf glänzendem Schild |
| Federleicht (`care_feather`) | Backenzahn mit Feder, schwebend |

Später für D/E: Werkstattmeister, Gepanzertes Besteck, Notfallkoffer (Hybride) und
Wurzelbund (drei verflochtene Zahnwurzeln mit Krone).
