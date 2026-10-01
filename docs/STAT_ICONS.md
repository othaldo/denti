# Stat-Icons

Die zehn Level-up-Stats verwenden eigene Motive aus `assets/ui/stat_icons_atlas.png`
(1983 × 793 Pixel, RGBA mit echter Transparenz), erstellt mit dem eingebauten
OpenAI ImageGen-Werkzeug. Stilreferenz: `assets/items/item_icons_atlas.png`.
Items, Waffen und Relikte behalten ihre bestehenden Grafiken.

| Index | Stat | Motiv | Quellregion (x, y, Breite, Höhe) |
| ---: | --- | --- | --- |
| 0 | Bisskraft | Zahn mit Einschlag | 35, 33, 391, 338 |
| 1 | Härte | Zahnschild | 458, 26, 306, 351 |
| 2 | Schmelz | Herz mit Zahn | 814, 61, 356, 313 |
| 3 | Putzeifer | Zahnbürste mit Blitz | 1208, 51, 347, 328 |
| 4 | Glanz | Goldener Glanzstern | 1604, 33, 343, 341 |
| 5 | Speichel | Tropfen mit Heilungsplus | 43, 407, 352, 345 |
| 6 | Bewegung | Geflügelter Zahn | 426, 437, 384, 294 |
| 7 | Zahnglück | Kleeblatt-Zahn | 837, 432, 312, 319 |
| 8 | Nahschaden | Gekreuzte Zahnarztinstrumente | 1189, 426, 379, 335 |
| 9 | Fernschaden | Zahnprojektil mit Zielscheibe | 1575, 416, 366, 347 |

## Vollständige Motive statt starrer Ausschnitte

Im bisherigen Item-Atlas schneiden die gleichmäßigen Zellen Teile der Motive
für Schmelz und Bisskraft ab. Auch generierte Raster richten Motive nicht immer
exakt an Zellgrenzen aus. Deshalb wählt `DentiUIIcons.stat()` die vollständigen
neuen Motive anhand ihrer tatsächlichen Grenzen mit vier Pixeln transparentem
Rand aus. `AtlasTexture.margin` zentriert jeden Ausschnitt in einem virtuellen
512 × 512 Pixel großen, transparenten Rahmen. Die Quelldatei bleibt unverändert.
`filter_clip` verhindert, dass benachbarte Motive beim Skalieren einblenden.

Level-up-Karten zeigen diesen quadratischen Rahmen mit 56 Pixeln Höhe auf großen
und 40 Pixeln in kompakten Ansichten; das komplette Motiv wird proportional
eingepasst. Stat-Bedeutung und Zuordnung bleiben beim Fortsetzen gespeichert,
weil Spielstände Stat-Namen und Seltenheitsstufen statt Icon-Indizes enthalten.

Automatische Prüfungen kontrollieren die zehn eindeutigen Zuordnungen,
Alphatransparenz, vollständige Motive, Abstand zum Rand und die Karteninhalte
bei verschiedenen Auflösungen. Gerenderte Vorschauen entstehen mit
`tests/four_choice_layout.gd -- --capture` unter `.codex/economy-previews/`.

## Verwendeter Prompt

```text
Use case: stylized-concept. Asset type: production transparent game UI stat icon atlas for Denti: Divine Dentistry. Transform the supplied item-icon reference into a NEW sheet of exactly TEN distinct STAT icons, preserving only its glossy hand-painted cartoon dental art style: warm ivory enamel, turquoise details, gold accents, dark plum outlines, rounded bold silhouettes and bright polished highlights. Replace all reference objects. Layout: landscape atlas, exactly FIVE equal columns and TWO equal rows, ten square cells, aspect ratio 5:2. One isolated centered icon per cell. Every entire icon including sparkles, outline and effects must fit within the middle 70% of its own cell, with at least 15% completely transparent padding on ALL four sides; no art crossing grid boundaries. Uniform apparent size and visual weight. Actual transparent background, NO grid lines, NO labels, NO letters, NO numbers, NO frame, NO background glow. Clear at 32-56px. Exact reading order, left to right top row then bottom row: 1 DAMAGE/Bisskraft: biting ivory tooth with strong orange impact burst, compact bold silhouette. 2 ARMOR/Härte: sturdy rounded silver shield with small tooth crest. 3 MAXIMUM HEALTH/Schmelz: large coral-pink heart cradling an ivory tooth, unmistakable health heart. 4 ATTACK SPEED/Putzeifer: compact turquoise toothbrush crossed with golden lightning bolt, dynamic speed strokes contained in cell. 5 CRITICAL CHANCE/Glanz: brilliant faceted golden four-point sparkle with a small shining ivory tooth, no clover. 6 REGENERATION/Speichel: friendly turquoise saliva droplet with a small bright green medical plus. 7 MOVEMENT/Bewegung: small ivory tooth with turquoise wing and short horizontal motion strokes, no bottle. 8 LUCK/Zahnglück: vivid green four-leaf clover over an ivory tooth, no sparkle mistaken for critical chance. 9 MELEE DAMAGE/Nahschaden: two short crossed silver dental scalers with orange handles, compact X silhouette, no shield or empty ceramic tooth shell. 10 RANGED DAMAGE/Fernschaden: flying small tooth projectile with blue tail passing through a round turquoise target reticle, compact contained silhouette, no mouthwash bottle. All ten icons equally readable, charming dental game style matching reference. Preserve genuinely transparent alpha.
```
