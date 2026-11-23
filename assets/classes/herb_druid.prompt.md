# Auftrag an Codex: Bilder für den Kräuterzahn (Druidenklasse)

**Status: erzeugt und bei Spielgröße geprüft.** Konzept der Klasse: [docs/CLASS_HERB_DRUID.md](../../docs/CLASS_HERB_DRUID.md).

Bitte mit dem eingebauten Bildgenerator (`image_gen.imagegen`,
`transparent_background: true`) erzeugen. Keine bestehenden Grafiken ersetzen oder
umzeichnen. Nach dem Erzeugen jede Datei bei Spielgröße prüfen (Porträt ~30 px im
Kampf, Waffe ~60 px, Pflanzen 30–40 px, Talent-Icons 28 px) und hier unter
„Ergebnis“ eintragen: Tool, Quelle, finaler Prompt.

Das Spiel lädt die Dateien unter genau diesen Pfaden; es ist kein Code nötig.
`herb_druid_portrait.png` und `planting_staff.png` liegen bereits als **Platzhalter**
(Kopien von Denti und dem Extraktionsstab) und sollen **überschrieben** werden.
Pflanzen-Bogen und Talent-Atlas fehlen noch; bis dahin zeichnet das Spiel einfache
Pflanzen und Platzhaltersymbole.

| Nr. | Datei | Format |
| --- | --- | --- |
| 1 | `assets/classes/herb_druid_portrait.png` | quadratisch, RGBA, 1254 × 1254 |
| 2 | `assets/weapons/planting_staff.png` | quadratisch, RGBA, 1254 × 1254 |
| 3 | `assets/classes/herb_druid_plants.png` | 4 Spalten × 2 Zeilen, gleich große quadratische Zellen, RGBA |
| 4 | `assets/classes/herb_druid_talent_icons.png` | 8 Spalten × 3 Zeilen, Zellen 192 × 192 (1536 × 576), RGBA |

Stilreferenzen (nur Stil, nicht verändern):

- Denti-Identität: `assets/denti/denti_unarmed.png`
- Klassenporträts: `assets/classes/necrodent_portrait.png`, `assets/classes/ember_portrait.png`
- Waffen: `assets/weapons/extraction_staff.png`, `assets/weapons/plaque_scaler.png`
- Kampffiguren: `assets/classes/necrodent_retinue.png`
- Talent-Icons: `assets/classes/talent_icons.webp`, `assets/classes/molar_talent_icons.webp`

---

## 1. Porträt Kräuterzahn

```text
Create a new square painted game sprite and class-selection portrait on genuine transparent RGBA for Denti: Divine Dentistry, using the attached ivory molar as identity and the attached Nekrodent and Glutzahn portraits as finish and composition reference. The Kräuterzahn (herb druid) is the same cute squat ivory molar with round glossy black eyes and tiny root feet, wearing a small wreath of fresh sage leaves and tiny white chamomile flowers on top of the crown, and a short moss-green gardener's apron with one small clove bud pinned to it like a brooch. Friendly, calm, a little proud gardener. One full-body centered figure, readable at 30px, bold warm-brown outline and warm painted glossy enamel highlights. No staff or tools in its hands, no other objects, no effects, no shadows or color outside the silhouette, no text. Keep the whole silhouette and transparent padding.
```

## 2. Pflanzstab (Exklusivwaffe)

```text
Create an original painted 2D equipment sprite on genuine transparent RGBA for Denti: Divine Dentistry. A single slender magical planting staff running diagonally from lower left to upper right: a smooth warm-brown wooden handle with two small gold ferrules, the lower end shaped like a small gardening dibber point, the upper end a curled living root that holds one glowing green seed with a tiny sprouting sage leaf. A thin green vine wraps loosely around the upper third. Emphasize the seed and the curled root head silhouette. Match the attached dental weapon references for gloss, warm dark outlines and dimensional hand-painted cartoon finish. Isolated single object, no background, no ground shadow, no particles, no text. Square composition, clean tight framing with transparent padding so it stays legible at 60px.
```

## 3. Pflanzen im Kampf (Kontaktbogen 4 × 2)

Spalten von links: Salbeitrieb, Salbeistrauch, Kamillentotem, Nelkenknospe.
Zeile 1: ausgewachsen. Zeile 2: dieselbe Pflanze als junger Spross (Wachstumsphase).

```text
Original game sprites for Denti: Divine Dentistry. A transparent PNG contact sheet with 4 columns and 2 rows, exactly eight small game sprites at equal scale, almost front facing, each standing on its own tiny root ball without any ground plane. Column 1 Salbeitrieb: a slim upright sage sprout with soft grey-green velvety leaves and a small green bud at the top that looks like it can shoot seeds. Column 2 Salbeistrauch: a fuller round sage bush, clearly larger and denser than column 1, with three small bud tips pointing outwards. Column 3 Kamillentotem: a small carved light-wood totem post crowned by a big white-and-yellow chamomile blossom, a soft friendly shape. Column 4 Nelkenknospe: a chunky reddish-brown clove bud shaped like a small nail with a round four-pointed head, glossy, slightly menacing. Row 1 shows the four plants fully grown. Row 2 shows each of the same four plants as a small young sprout just breaking out of its root ball, recognisable by color and shape. Distinct silhouettes and colors so all four read apart at 30–40 pixels. Match the attached Nekrodent retinue sheet for glossy painted 2D finish, warm dark outline and clear proportions. Rigid grid, equal gaps, generous transparent gutters, no overlapping sprites, no text, no grid lines, no backgrounds, no effects or blank cells.
```

## 4. Talent-Icons (Atlas 8 × 3)

Pro Ast ein Bogen mit 4 × 2 Zellen erzeugen (wie bei den anderen Klassen), dann in
den Atlas packen: **eine Zeile pro Ast**, acht Icons in der Reihenfolge der Tabelle.

| Zeile | Ast | Icons von links nach rechts |
| --- | --- | --- |
| 1 | Salbeibeet | Dornen, Dichtes Beet, Bitterkraut, **Salbeistrauch** (Skill), Wildwuchs, Samenschuss, Tiefe Wurzeln, Monokultur (Schlüsselstein) |
| 2 | Kamillenhain | Beruhigend, Gießkanne, Blütenstaub, **Kamillentotem** (Skill), Großer Kranz, Kamillentee, Ableger, Teezeremonie (Schlüsselstein) |
| 3 | Nelkenhecke | Betäubung, Ranken, Hecke, **Nelkenknospe** (Skill), Nelkenöl, Platzende Knospe, Würgeranke, Giftgarten (Schlüsselstein) |

Gemeinsamer Vorspann für jeden Ast:

```text
Create a NEW painted 2D video game sprite sheet for Denti: Divine Dentistry. The supplied talent atlases (assets/classes/talent_icons.webp, molar_talent_icons.webp) are a style reference ONLY. Match their warm ivory enamel, glossy gold and painted metal, saturated accent colors, warm directional highlights, slight brush texture, bold dark-brown outlines and chunky, toy-like three-dimensional shapes. Make exactly 8 symbols on a strict evenly spaced layout of FOUR square columns and TWO square rows, reading left to right, top to bottom. Keep 25% clear space within each cell and every silhouette well inside its cell. Each object is large and unmistakable even at 28 pixels. Real clean transparent alpha background: zero alpha in gutters, borders and empty cells, no cast shadows, haze, backdrop glows, base plates, text, numbers, grid, borders or watermarks. Use a wide 2:1 canvas.
```

**Salbeibeet** (Palette: salbeigrün, moosgrün, Gold):

```text
Branch: Salbeibeet. Palette: sage green, moss green and gold.
Top row, column 1: a sage stem with a sharp little thorn on a glowing green seed bullet.
Top row, column 2: a tightly packed garden bed with five small sage sprouts in a row.
Top row, column 3: a bitter dark-green sage leaf with a small drop of green essence.
Top row, column 4: a round lush sage bush with three bud tips firing small seeds outwards (this is the skill, make it the most striking).
Bottom row, column 1: tangled wild overgrowth of sage stems spilling over a small wooden fence edge.
Bottom row, column 2: a seed pod bursting into many tiny green seeds.
Bottom row, column 3: a sage plant with long deep roots visible below it.
Bottom row, column 4: a single perfect sage plant in a plain clay pot with a golden ring around the pot (keystone).
```

**Kamillenhain** (Palette: weiß, butterblumengelb, helles Holz):

```text
Branch: Kamillenhain. Palette: white, buttercup yellow and light wood.
Top row, column 1: a steaming cup of chamomile tea with a little ivory tooth charm on the saucer.
Top row, column 2: a small copper watering can pouring glittering water drops.
Top row, column 3: a chamomile blossom releasing a puff of golden pollen.
Top row, column 4: a carved light-wood totem post crowned by a big chamomile blossom with a soft golden glow ring (skill, most striking).
Bottom row, column 1: a large wreath of chamomile flowers.
Bottom row, column 2: a teapot with a small round ivory shield pattern on its side.
Bottom row, column 3: a cut chamomile stem with a fresh new sprout growing from its base.
Bottom row, column 4: a tiny tea ceremony set of a bowl and whisk with chamomile flowers, ceremonial gold trim (keystone).
```

**Nelkenhecke** (Palette: nelkenbraun, rotbraun, dunkles Grün, Violett):

```text
Branch: Nelkenhecke. Palette: clove brown, reddish brown, dark green and violet.
Top row, column 1: a clove bud with small dizzy swirl stars above it.
Top row, column 2: a curling green vine tendril springing from a little dash-shaped root.
Top row, column 3: a dense dark-green hedge block with a few clove buds.
Top row, column 4: a chunky glossy clove bud shaped like a nail with a four-pointed head, giving off a numbing violet shimmer (skill, most striking).
Bottom row, column 1: a small glass vial of golden clove oil with a cork.
Bottom row, column 2: a clove bud bursting open with brown fragments flying out.
Bottom row, column 3: a thick strangling vine tightly coiled into a loop.
Bottom row, column 4: a clove bud dripping lime-green poison into a small garden pot (keystone).
```

---

## Ergebnis

Erzeugt mit dem eingebauten `image_gen.imagegen` mit `transparent_background: true`.
Die ImageGen-Originale liegen im Ausgabeordner `01a20546-89e6-7741-96f7-3925185c56da`.

| Ergebnis | ImageGen-Quelle | Finaler Prompt |
| --- | --- | --- |
| `herb_druid_portrait.png` | `exec-aac349be-c32b-4a47-8ea6-1c9f55600267.png` | Vorspann fürs Porträt unten und der Prompt aus Abschnitt 1 |
| `planting_staff.png` | `exec-05419c58-e5cd-4cb7-ae72-470abb750442.png` | Vorspann für den Stab unten und der Prompt aus Abschnitt 2 |
| `herb_druid_plants.png` | `exec-88f92bbc-de44-4a91-81d0-7102e541b710.png` | Nachbearbeitung des mit Abschnitt 3 erzeugten Bogens `exec-81c7c09e-7ed5-45d9-86c7-da414193dd66.png`. Beide Prompts stehen unten. |
| `herb_druid_talent_icons.png`, Salbeibeet | `exec-999fd1cd-d1ea-4a96-9725-973c88225c63.png` | `Use case: stylized-concept.` gefolgt vom gemeinsamen Vorspann und dem Salbeibeet-Prompt aus Abschnitt 4 |
| `herb_druid_talent_icons.png`, Kamillenhain | `exec-0e89482c-8f0a-4c6b-a1c4-33bb40c7ef80.png` | `Use case: stylized-concept.` gefolgt vom gemeinsamen Vorspann und dem Kamillenhain-Prompt aus Abschnitt 4 |
| `herb_druid_talent_icons.png`, Nelkenhecke | `exec-a69d0697-33e5-47ba-8361-42111107f4a3.png` | `Use case: stylized-concept.` gefolgt vom gemeinsamen Vorspann und dem Nelkenhecke-Prompt aus Abschnitt 4 |

**Vorspann fürs Porträt**

```text
Use case: stylized-concept. Input image 1 is the identity reference. Images 2 and 3 are style and composition references only.
```

**Vorspann für den Stab**

```text
Use case: stylized-concept. Both attached weapons are only style references for this new weapon.
```

**Vorspann für den ersten Pflanzenbogen**

```text
Use case: stylized-concept. The attached sheet is a painted game-art style reference only. The new plant grid has four square columns and two square rows on a wide 2:1 canvas. Put each sprite's root ball at the same baseline inside its cell.
```

**Finaler Prompt zum Freistellen des Pflanzenbogens**

```text
Use case: background-extraction. Image 1 is the edit target. Change only the background alpha of this existing 4-column by 2-row painted sprite sheet. Remove the entire cloudy gray backing and every cast shadow, both outside and between the eight isolated plant figures. The broad background, gutters and image corners must be literally zero-alpha transparent pixels, not a pale fog or a checkerboard illustration. Keep precisely the original eight painted plant designs, colors, warm dark outlines, and attached little root balls. Keep the upper row with mature sage sprout, round sage bush, carved chamomile totem, and red-brown clove bud; lower row the same four as smaller sprouts. Keep the original relative scales and group order. Leave unobstructed empty transparent gutters, including around the root balls. Isolated crisp cutouts, wide 2:1 canvas, genuine RGBA. No letters or new objects.
```

Die Pflanzen sind in 256 × 256 px großen Zellen mit gemeinsamer Wurzelhöhe gepackt. Die drei Icon-Bögen lesen sich jeweils links nach rechts, erst oben, dann unten und ergeben je eine Atlaszeile. Alle Zellen haben transparente Ränder. Sichtprüfung bei 30 px fürs Porträt, 60 px für den Stab, 30–40 px für die Pflanzen und 28 px für die Icons.
