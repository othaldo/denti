# Waffenpakete: Normalbild und sechs Elemente

Arbeitsstand: 27.10.2026. **18 Standardwaffen und alle sechs Evolutionen sind
vollständig: 24 Pakete mit insgesamt 168 Einzelbildern.** Die Galerie `index.html`
enthält alle Bilder und Prompts. Alle Formen sind im Spiel eingebunden;
Details stehen in `docs/WEAPON_SKINS.md`.

## Gemeinsames Format

- Jede Variante ist eine eigene PNG-Datei mit **1024 × 1536 Pixeln**, RGBA und
  transparentem Hintergrund. Keine zusammengefassten Bilder oder Atlanten.
- Pro Waffe sieben Dateien: `normal.png`, `fire.png`, `ice.png`, `poison.png`,
  `electric.png`, `bleed.png` und `wet.png`.
- Innerhalb eines Pakets bleiben Ausrichtung, Objektgröße und Griffposition an
  derselben Basisreferenz orientiert. Die Form und das Material zeigen das Element.
- Bestehende Normalbilder werden als Originalreferenz erhalten. Falls sie bereits
  zum Format passen, wird eine unveränderte Kopie ins Paket übernommen.
- `prompts.json` enthält die vollständigen Prompts des eingebauten Imagegen.
  `manifest.json` verzeichnet Maße, Transparenz, sichtbare Grenzen und SHA-256.
- Das übergeordnete Referenzverzeichnis ist bereits per `.gdignore` vom
  Spielimport ausgeschlossen. Kompakte Laufzeitkopien sind unter
  `assets/weapons/element_forms/` ins Spiel eingebunden.

## Fortschritt

| Nr. | Waffe | Paket |
| --- | --- | --- |
| 1 | Zauberbürste | **7/7 fertig zur Ansicht** · `magic_toothbrush/` |
| 2 | Turbo-Bohrer | **7/7 fertig zur Ansicht** · `turbo_drill/` |
| 3 | Zahnseidenpeitsche | **7/7 fertig zur Ansicht** · `floss_whip/` |
| 4 | Wasserflosser | **7/7 fertig zur Ansicht** · `water_jet/` |
| 5 | Kronenwerfer | **7/7 fertig zur Ansicht** · `crown_launcher/` |
| 6 | Schmelzspiegel | **7/7 fertig zur Ansicht** · `enamel_mirror/` |
| 7 | Zahnsteinkratzer | **7/7 fertig zur Ansicht** · `plaque_scaler/` |
| 8 | Mundspülungs-Mörser | **7/7 fertig zur Ansicht** · `mouthwash_mortar/` |
| 9 | Zahnstocher-Speer | **7/7 fertig zur Ansicht** · `toothpick_spear/` |
| 10 | Karies-Fräse | **7/7 fertig zur Ansicht** · `cavity_grinder/` |
| 11 | Interdental-Bürste | **7/7 fertig zur Ansicht** · `interdental_brush/` |
| 12 | Fluorid-Sprüher | **7/7 fertig zur Ansicht** · `fluoride_sprayer/` |
| 13 | Mundduschen-Turbine | **7/7 fertig zur Ansicht** · `water_turbine/` |
| 14 | UV-Lampe | **7/7 fertig zur Ansicht** · `uv_lamp/` |
| 15 | Amalgam-Schleuder | **7/7 fertig zur Ansicht** · `amalgam_slingshot/` |
| 16 | Zahnseiden-Garotte | **7/7 fertig zur Ansicht** · `floss_garrote/` |
| 17 | Prophylaxe-Polierer | **7/7 fertig zur Ansicht** · `prophylaxis_polisher/` |
| 18 | Fluorid-Rakete | **7/7 fertig zur Ansicht** · `fluoride_rocket/` |
| 19 | Gewitterdusche | **7/7 fertig zur Ansicht** · `storm_shower/` |
| 20 | Schicksalsfaden | **7/7 fertig zur Ansicht** · `fate_thread/` |
| 21 | Wurzelkanalbrecher | **7/7 fertig zur Ansicht** · `root_breaker/` |
| 22 | Heiligenschein | **7/7 fertig zur Ansicht** · `halo/` |
| 23 | Dreifaltigkeitsbürste | **7/7 fertig zur Ansicht** · `trinity_brush/` |
| 24 | Zahn der Offenbarung | **7/7 fertig zur Ansicht** · `revelation/` |

Standardwaffen: **18 × 7 = 126 Einzelbilder**.
Evolutionen: **6 × 7 = 42 Einzelbilder**.
Gesamtbestand: **24 × 7 = 168 Einzelbilder**.

## Erstes Paket: Zauberbürste

Alle sieben Dateien sind 1024 × 1536 Pixel groß. Die Normalvariante ist eine
pixelidentische Kopie von `assets/weapons/magic_toothbrush.png`. Die vier bereits
erzeugten Elementformen wurden übernommen; Blut und Wasser wurden einzeln ergänzt.

Geprüft: RGBA, transparente Ecken, vollständige Konturen und gleiche Canvasmaße.
Die sichtbaren Längen bei Alpha ≥ 32 unterscheiden sich um höchstens 22 Quellpixel
(rund 1 Pixel bei 70 Pixel Darstellung). Die Originalbilder wurden nicht verändert.

Die Vergleichsansicht zeigt alle sieben auf demselben Hintergrund, im gleichen
Bildausschnitt und zusätzlich mit 70 Pixeln Höhe:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility --script res://tools/preview_weapon_asset_pack.gd -- --weapon=magic_toothbrush
```

Die Aufnahme liegt unter
`docs/screenshots/weapon_elements/magic_toothbrush_complete_pack.png`.

## Zweites Paket: Turbo-Bohrer

Auch hier liegen sieben einzelne RGBA-PNGs im Format 1024 × 1536 vor. Die
Normalvariante wurde mit Imagegen anhand der quadratischen Originalgrafik für
das Hochformat neu erzeugt; sie ist deshalb keine pixelidentische Kopie. Das
Original `assets/weapons/turbo_drill.png` bleibt erhalten. Die sechs Elemente
wurden einzeln aus dieser einheitlich positionierten Normalvariante erzeugt.

Geprüft: gleiche Canvasmaße, transparente Ecken und vollständige Konturen. Als
Bezugspunkt liegt der rote Zahnknopf in allen Varianten höchstens 5,22 Pixel von
der Normalvariante entfernt. Die Elementformen und die später im Spiel verwendete
Griffposition sind vor der Integration noch gemeinsam zu prüfen.

Die Aufnahme liegt unter
`docs/screenshots/weapon_elements/turbo_drill_complete_pack.png`; erzeugen mit
`tools/preview_weapon_asset_pack.gd -- --weapon=turbo_drill`.

## Drittes Paket: UV-Lampe

Sieben einzelne transparente RGBA-PNGs im Format 1024 × 1536. Die Normalvariante
wurde anhand des originalen Atlasfelds der UV-Lampe für das Hochformat neu erzeugt
und ist keine pixelidentische Kopie. Die ursprüngliche Atlasgrafik bleibt erhalten.

Die sechs Elemente wurden einzeln aus der Normalvariante erzeugt. Bei Gift wurde
die am rechten Rand angeschnittene Mündung in einem zweiten Imagegen-Schritt
vollständig ergänzt; beide Prompts stehen in `prompts.json`.

Geprüft: gleiche Canvasmaße, transparente Ecken und vollständige Konturen. Der
Schwerpunkt des Zahnmedaillons liegt in allen Varianten höchstens 25,58 Quellpixel
vom Normalbild entfernt. Bei einer 65 Pixel hohen Assetfläche entspricht das rund
1,1 Pixel. Die Vergleichsminiatur zeigt die gesamte Assetfläche; bei der späteren
Spieleinbindung müssen sichtbare Größe und Griffposition separat geprüft werden.

Die Aufnahme liegt unter `docs/screenshots/weapon_elements/uv_lamp_complete_pack.png`;
erzeugen mit `tools/preview_weapon_asset_pack.gd -- --weapon=uv_lamp`.

## Viertes Paket: Mundspülungs-Mörser

Sieben transparente RGBA-PNGs im Format 1024 × 1536. Die Normalvariante der
Waffe mit zwei Wurzeln wurde anhand des originalen Atlasfelds für das Hochformat
neu erzeugt und ist keine pixelidentische Kopie. Das Original bleibt erhalten.
Alle sechs Elementbilder entstanden einzeln auf Basis dieser Normalvariante.

Geprüft: identische Canvasmaße, transparente Ecken, vollständige Konturen und
beide Griffe. Zahnmedaillon und Griffe liegen jeweils höchstens 30,52 Quellpixel
von der Normalvariante entfernt; auf 75 Pixeln Assethöhe sind das rund 1,5 Pixel.
Bei der späteren Einbindung müssen sichtbare Größe und Griffposition im Spiel
noch geprüft werden.

Die Aufnahme liegt unter
`docs/screenshots/weapon_elements/mouthwash_mortar_complete_pack.png`; erzeugen
mit `tools/preview_weapon_asset_pack.gd -- --weapon=mouthwash_mortar`.

## Fünftes Paket: Kronenwerfer

Sieben transparente RGBA-PNGs im Format 1024 × 1536. Die Normalvariante der
Waffe mit zwei Wurzeln wurde anhand des originalen Atlasfelds für das Hochformat
neu erzeugt und ist keine pixelidentische Kopie. Das Original bleibt erhalten.
Alle sechs Elementbilder entstanden einzeln auf Basis dieser Normalvariante;
die geladene Krone bleibt im Lauf sichtbar.

Geprüft: identische Canvasmaße, transparente Ecken, vollständige Konturen und
beide Griffe. Zahnmedaillon und Griffe liegen jeweils höchstens 35,81 Quellpixel
von der Normalvariante entfernt; auf 65 Pixeln Assethöhe sind das rund 1,5 Pixel.
Bei der späteren Spieleinbindung werden sichtbare Größe und Griffposition geprüft.

Die Aufnahme liegt unter
`docs/screenshots/weapon_elements/crown_launcher_complete_pack.png`; erzeugen
mit `tools/preview_weapon_asset_pack.gd -- --weapon=crown_launcher`.

## Gesamter Standardwaffensatz

Alle 18 Pakete sind vollständig: **126 einzelne transparente RGBA-PNGs**,
jeweils 1024 × 1536 Pixel. Die lokale Übersicht `index.html` zeigt alle Varianten
mit direktem Zugriff auf die volle Auflösung, Prompts und Dateidaten.

Im abschließenden Durchgang wurden die übrigen 13 Waffen ergänzt: 11 neue
Normalformen und 78 einzeln erzeugte Elementformen mit dem eingebauten Imagegen.
Die Normalbilder von Schmelzspiegel und Zahnsteinkratzer passten bereits zum
Format und wurden pixelidentisch kopiert. Die übrigen neuen Normalformen sind
Hochformat-Neuinterpretationen anhand der aktiven Originalgrafik. Alle
ursprünglichen Waffenbilder und Atlanten bleiben erhalten.

Geprüft: Dateianzahl, 1024 × 1536 Pixel, RGBA, transparente Ecken,
vollständige feste Konturen, individuelle SHA-256-Prüfsummen und Vergleich in
Godot mit gemeinsamer Bildfläche je Paket. Jeder Waffenordner enthält eine
`manifest.json` und die vollständigen Imagegen-Prompts in `prompts.json`.

Die drei Gesamtübersichten liegen unter
`docs/screenshots/weapon_elements/all_weapons_page_1.png`,
`all_weapons_page_2.png` und `all_weapons_page_3.png`.
Zusätzlich gibt es je Waffe `<weapon_id>_complete_pack.png`.

Die Bilder sind über kompakte Laufzeitkopien ins Spiel eingebunden. Größe,
Griffposition, Mündungen und Kontakt wurden im Spiel geprüft. Fräse, Polierer
und Schleuder besitzen abgeleitete Animationsteile; dieses Referenzpaket behält
die vollständigen Originalbilder.

## Vollständige Evolutionen

Die sechs Evolutionen ergänzen den Bildsatz um **42 weitere Einzelbilder**:
Gewitterdusche, Schicksalsfaden, Wurzelkanalbrecher, Heiligenschein,
Dreifaltigkeitsbürste und Zahn der Offenbarung. Insgesamt liegen damit
**168 transparente RGBA-PNGs für 24 Waffenformen** vor, alle 1024 × 1536 Pixel.

Alle sechs Normalformen wurden mit dem eingebauten Imagegen anhand ihrer aktiven
Atlasgrafik für das Hochformat neu interpretiert. Es sind keine pixelidentischen
Kopien. Der Originalatlas `assets/weapons/weapon_evolutions.png` bleibt erhalten.
Die 36 Elementformen wurden jeweils einzeln anhand der zugehörigen Normalform
erzeugt. Jede Waffe behält ihre charakteristischen Köpfe, Fäden, Spitzen und Ringe;
die drei Köpfe der Dreifaltigkeitsbürste tragen pro Variante dasselbe Element.

Geprüft: sieben Dateien pro Paket, RGBA, identische Canvasmaße, transparente
Ecken, vollständige feste Konturen und SHA-256-Prüfsummen. Die Vergleiche in Godot
zeigen je Paket denselben Bildausschnitt sowie eine kleine Spriteansicht.
Die Evolutionen sind auf `docs/screenshots/weapon_elements/all_weapons_page_4.png`
zusammengefasst und in `index.html` mit allen Einzelbildern enthalten.

Auch die sechs Evolutionen sind einschließlich ihrer Elementformen eingebunden.
Bestehende Evolutionseffekte und Projektilbilder bleiben erhalten; die Form folgt
dem geerbten Element. Ressourcen und Drehpunkte sind den neuen Bildern zugeordnet.
