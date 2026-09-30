# Waffen-Atlas: Generierung

Der Atlas illustriert die zehn Ideen aus `WEAPON_BALANCING_PROPOSAL.md`.
Alle zehn Waffen sind als `WeaponData` und Shopangebote unter `data/weapons/`
implementiert. Die Ressourcen verwenden die unten angegebenen `AtlasTexture`-
Regionen direkt; der Atlas liefert sowohl Spielsprites als auch Shopbilder.

Datei: `assets/weapons/weapon_icons_expansion.png`, 1983 × 793 Pixel,
RGBA mit echtem transparentem Hintergrund. Raster: fünf Spalten, zwei Reihen.
Die Ausgabegröße des Bildwerkzeugs ist nicht glatt durch das Raster teilbar.
Die folgenden ganzzahligen Regionen decken den Atlas lückenlos ab und können
als Godot-`AtlasTexture.region` verwendet werden (x, y, Breite, Höhe).

| Index | Waffe | Region |
| ---: | --- | --- |
| 0 | Zahnstocher-Speer | 0, 0, 397, 397 |
| 1 | Karies-Fräse | 397, 0, 396, 397 |
| 2 | Interdental-Bürste | 793, 0, 397, 397 |
| 3 | Fluorid-Sprüher | 1190, 0, 396, 397 |
| 4 | Mundduschen-Turbine | 1586, 0, 397, 397 |
| 5 | UV-Lampe | 0, 397, 397, 396 |
| 6 | Amalgam-Schleuder | 397, 397, 396, 396 |
| 7 | Zahnseiden-Garotte | 793, 397, 397, 396 |
| 8 | Prophylaxe-Polierer | 1190, 397, 396, 396 |
| 9 | Fluorid-Rakete | 1586, 397, 397, 396 |

Alle zehn Motive wurden visuell geprüft; die Alphatransparenz und belegten
Zellen wurden kontrolliert. Bestehende Waffengrafiken bleiben erhalten.

Erstellt mit dem eingebauten OpenAI ImageGen-Werkzeug. Stilreferenzen:
`assets/weapons/turbo_drill.png`, `water_jet.png` und `mouthwash_mortar.png`.

## Ursprünglicher Prompt

```text
Use case: stylized-concept
Asset type: production transparent weapon sprite atlas for the 2D cartoon dental roguelite Denti: Divine Dentistry.
Primary request: Create exactly TEN distinct new dental weapon sprites in a strict FIVE-COLUMN by TWO-ROW regular grid, landscape canvas, preferably 2560x1024 pixels (aspect ratio 2.5:1); each of ten equal square cells contains exactly one complete centered isolated weapon. Genuine transparent background everywhere outside the objects, no grid lines or labels.
Input images: the three supplied images are STYLE REFERENCES ONLY for existing turbo drill, water jet and mouthwash mortar. Match their polished hand-painted cartoon game art, thick dark plum contours, glossy ivory enamel housings, turquoise details, gold metal trim, bright readable highlights, soft dimensional shading, little tooth-shaped insignias. Draw NEW objects, not duplicates of those references.
Exact cell order, left to right:
TOP ROW:
1. Zahnstocher-Speer: a long sharpened honey-colored wooden toothpick spear with a slender ivory/turquoise grip and small gold collar, wooden needle point upper right. Distinctly long and slim.
2. Karies-Fräse: a heavy TWO-HANDED squat powered dental milling grinder, broad round serrated steel burr on its front, chunky turquoise motor and ivory housing, two grips, gold trim. Clearly different from the thin existing drill.
3. Interdental-Bürste: a very slim small interdental tool, narrow cylindrical orange bristle brush on a thin bent metal stem, turquoise/ivory ergonomic handle. Recognizable dense spiral brush bristles.
4. Fluorid-Sprüher: a chunky two-handed dental spray gun, mint-green translucent fluoride reservoir, wide fan nozzle and ivory/gold housing. Only a very small mint spray hint near nozzle; weapon dominates the cell.
5. Mundduschen-Turbine: a heavy water cannon, circular turbine rotor visible in cyan tank/housing, TWO handles, broad silver water nozzle, blue water details. Distinct from spray gun: mechanical rotor and large outlet.
BOTTOM ROW:
6. UV-Lampe: a long heavy dental ultraviolet beam gun, violet glowing wide rectangular emitter, ivory/gold casing, turquoise handle and purple glass. Distinct straight beam weapon silhouette, no detached beam.
7. Amalgam-Schleuder: compact Y-shaped ivory-and-gold slingshot with turquoise grip, dark elastic band, one shiny heavy gray metal ball cradled at center. Must unmistakably read as a slingshot.
8. Zahnseiden-Garotte: two separate ivory/turquoise handles linked by ONE taut curved silver-white dental floss cord forming a broad arch. ONE complete weapon assembly, symmetrical grips, no blood.
9. Prophylaxe-Polierer: compact hand-held powered dental polisher with small round lavender rubber polishing cup on an angled silver head, ivory/turquoise motor grip, gold accents. Small rounded cup instead of drill bit or bristles.
10. Fluorid-Rakete: chunky two-handed rocket launcher, long ivory/gold tube with mint accents, visible mint-tipped dental rocket at muzzle, gold fin details, rear grip. Unmistakable rocket launcher, distinct from mortar.
Composition/framing: each sprite centered in its own equal square cell, approx 75-82 percent of cell occupied, at least 9 percent transparent safety padding on all edges. Never cross cell boundaries. Weapons usually diagonal lower-left to upper-right, matching reference view; consistent three-quarter side view. Each sprite stays complete and recognizable at 58-70 px in game and at small shop icon sizes. Consistent scale and visual quality across all ten cells.
Constraints: exactly ten weapons, no bonus items, no characters, no hands holding weapons, no text, no watermark, no cards, no tiles, no opaque background, no checkerboard drawn into image, no drop shadows outside silhouettes, no large effects. Preserve the charming glossy painted dental fantasy look of the references, avoid flat vector art and photorealism.
```

## Korrektur

Die zehn Entwürfe und ihre Reihenfolge beibehalten. Genau fünf Spalten und
zwei Reihen mit gleich großen quadratischen Zellen, Seitenverhältnis 2,5:1.
Jede Waffe vollständig innerhalb ihrer Zelle zentrieren und verkleinern,
mit mindestens zwölf Prozent transparentem Abstand auf jeder Seite.
Keine Zellgrenzen überschreiten, keine Teile abschneiden, keine Beschriftung,
keine Rasterlinien; echte Alphatransparenz erhalten.
