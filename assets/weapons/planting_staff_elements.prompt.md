# Auftrag an Codex: Element-Varianten des Pflanzstabs

**Status: offen.** Gleiches Verfahren wie bei den 24 Waffenpaketen
([Format](reference/element_forms/README.md), [Laufzeit](../../docs/WEAPON_SKINS.md)).

## Was zu tun ist

1. Mit dem eingebauten Bildgenerator (`image_gen.imagegen`,
   `transparent_background: true`) **sieben** Bilder malen und ablegen unter
   `assets/weapons/reference/element_forms/planting_staff/`:
   `normal.png`, `fire.png`, `ice.png`, `poison.png`, `electric.png`, `bleed.png`, `wet.png`.
   Jedes Bild **1024 × 1536 Pixel**, RGBA, transparenter Hintergrund.
2. Dazu `prompts.json` (vollständige Prompts je Variante) und `manifest.json`
   (Maße, Transparenz, sichtbare Grenzen, SHA-256) wie bei den anderen Paketen.
3. `python tools/pack_weapon_skins.py` ausführen. Der Eintrag `planting_staff` in
   `data/weapon_skins/rigs.json` ist bereits angelegt. Das Skript erzeugt die
   Laufzeitbilder unter `assets/weapons/element_forms/planting_staff/`, die
   Skin-Ressourcen unter `data/weapon_skins/planting_staff/` und trägt
   `element_skins` in `data/weapons/planting_staff.tres` ein.
4. Die Varianten bei Spielgröße prüfen (Waffe ~60 px, Shop-Karte, Verzauberungsbild)
   und hier unter „Ergebnis“ eintragen.

Bis die Bilder da sind, tönt das Spiel den Pflanzstab in der Elementfarbe.

## Referenz und Aufbau

- Identität: `assets/weapons/planting_staff.png` (aktueller Pflanzstab, quadratisch).
  Nur dieses Objekt, Identität bewahren.
- Stil der Varianten: z. B. `reference/element_forms/uv_lamp/*.png` und
  `reference/element_forms/magic_toothbrush/*.png`.
- **Platzierung in allen sieben Bildern gleich:** Stab diagonal von links unten
  (Spitze bei etwa x = 0.14, y = 0.86) nach rechts oben (Kopf bei etwa x = 0.80,
  y = 0.20). Griff am Holz bei etwa (0.36, 0.62). Gleiche Größe, gleiche Blickrichtung,
  nicht drehen oder spiegeln. Großzügiger transparenter Rand.
- Die Form und das Material zeigen das Element; der Samen im Wurzelkopf ist der
  wichtigste Träger der Elementfarbe. Keine Partikel außerhalb der Silhouette, kein
  Hintergrund, kein Bodenschatten, kein Text.

## Gemeinsamer Vorspann

```text
Use case: precise-object-edit. Asset type: one standalone transparent 2D weapon sprite for Denti, a friendly glossy cartoon dental arena game. Input image 1 is the exact Pflanzstab (planting staff) of the class Kräuterzahn; use it as the ONLY subject and preserve its identity: a slender warm-brown wooden staff with two gold ferrules and teal inlays, a pointed gold dibber tip at the lower end, a curled living root head at the upper end holding one glowing seed with a tiny sprouting leaf, and a thin green vine wrapped around the upper third. Portrait 1024 x 1536 pixel canvas with true transparent RGBA background. The staff runs diagonally from the lower left (tip near x=0.14, y=0.86) to the upper right (root head near x=0.80, y=0.20), grip on the wood near (0.36, 0.62). Keep the same painterly volume, warm highlights and clean dark outlines, readable at 60px. No background, no ground shadow, no particles outside the silhouette, no text.
```

## Varianten

| Datei | Zusatz zum Vorspann |
| --- | --- |
| `normal.png` | `Normal unenchanted form, exactly as the reference, only reframed onto the portrait canvas.` |
| `fire.png` | `Fire form: the seed is a glowing orange-red ember with a small flame sprout, the root head is lightly charred with glowing orange cracks, the vine becomes dry red-orange with tiny glowing leaf edges.` |
| `ice.png` | `Ice form: the seed is a pale blue ice crystal with a frosted sprout, the root head and upper wood are rimed with frost and small icicles, the vine is frosted pale blue.` |
| `poison.png` | `Poison form: the seed is a glossy lime-green toxic bulb with a dark violet sprout, a single lime droplet hangs from the root head, the vine turns dark violet with lime veins.` |
| `electric.png` | `Electric form: the seed is a bright yellow crackling energy seed inside a thin copper coil wrapped around the root head, small yellow lightning arcs hug the head, the vine has copper-wire accents.` |
| `bleed.png` | `Bleed form: the seed is a deep crimson seed like a rose hip, the vine becomes a dark red thorny bramble with sharp thorns along the upper third, small red sheen on the thorns.` |
| `wet.png` | `Water form: the seed is a clear blue water droplet with a glistening sprout, the root head and vine look wet and glossy with a few blue water drops, aquatic blue-green leaves.` |

---

## Ergebnis

_Bitte nach dem Erzeugen ausfüllen._
