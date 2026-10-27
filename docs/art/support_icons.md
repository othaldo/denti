# Gemalte Verstärkungssymbole

Erzeugt am 27.10.2026 mit dem eingebauten Imagegen-Werkzeug und
`transparent_background: true`, ohne CLI. Stilreferenz:
`assets/ui/element_icons_atlas.png`. Die Referenz bleibt unverändert.

Spielasset: `assets/ui/weapon_support_icons_atlas.png`, 1536×1024 RGBA mit echtem
Alpha, pixelidentisch aus der Generierung übernommen. Mipmaps werden beim
Import erzeugt. `DentiUIIcons.item()` wählt die vollständigen Motive inklusive
Sicherheitsrand und zentriert sie. Die längste Seite nimmt jeweils 86 % des
transparenten Rahmens ein; breite Pfeile werden nicht verzerrt.

| Index | Effekt | Symbol |
| --- | --- | --- |
| 97 | Reichweite | Doppelpfeil mit Endpunkten |
| 98 | Angriffstempo | Drei schnelle Schnittspuren |
| 99 | Lebensraub | Rotes Herz mit einströmendem grünem Pfeil |
| 100 | Krit-Chance | Zielscheibe mit zentralem Stern |
| 101 | Krit-Schaden | Klinge durch einen starken Einschlag |
| 102 | Wucht | Goldene Faust mit Schubpfeilen |

Die Indizes 97–102 sind für Waffenverstärkungen reserviert. Die sechs
Affixressourcen wählen sie; Auswahl, belegte Plätze, Fusionsvorschau,
Dentipedia und alte Kapselansichten verwenden dadurch dieselben Symbole.
Die Iconklasse lädt den Atlas über `preload`. Element- und Itemicons bleiben
unverändert. Die Änderung betrifft ausschließlich die Darstellung.

Native Prüfung:
`tools/preview_element_icons.gd -- --supports` erzeugt die tatsächliche
[Verstärkungsauswahl](../screenshots/support_icons/supports.png) und
[Darstellungen in 16/24/32/48 Pixel](../screenshots/support_icons/native_sizes.png).

## Verwendeter Prompt

Use case: stylized-concept. Asset type: production transparent game UI icon atlas for Denti Divine Dentistry. Generate ONE NEW 1536 x 1024 transparent PNG sprite sheet with exactly THREE equal square columns by TWO equal square rows (512px cells), SIX SEPARATE upgrade symbols. The supplied element icon sheet is STYLE REFERENCE ONLY: match its glossy hand-painted cartoon finish, chunky dark plum outlines, dimensional color shading and crisp highlights. Do not reuse its element subjects. These six symbols represent weapon SUPPORT STATS, readable at 24-48px, with distinct silhouettes even without labels. Uniform optical size, each entire motif centered in its own cell with generous transparent gutters; no overlap with neighboring cells. Exact row-major order: TOP LEFT RANGE: a bold horizontal double-headed ivory-and-turquoise arrow spanning between two small circular endpoint rings, unmistakable distance/reach symbol. TOP MIDDLE ATTACK SPEED: three bold tapering curved ivory slash strokes sweeping forward together with two turquoise speed trails; compact speed/motion silhouette, no lightning bolt, no clock or potion bottle. TOP RIGHT LIFE STEAL: one glossy ruby-red heart with a thick small green curved arrow flowing INTO the heart from the side, conveying stolen vitality arriving in the heart; arrow clearly distinct, no medical cross, no droplets, no blood or gore. BOTTOM LEFT CRITICAL CHANCE: one compact golden target/bullseye with thick ivory crosshair lines and a bright small star at the precise center, unmistakably precision/chance to hit a weak point, no percent sign or numbers. BOTTOM MIDDLE CRITICAL DAMAGE: one short broad diagonal ivory blade piercing a vivid red-orange pointed impact burst; simple forceful silhouette, conveys a devastating critical hit, no target rings or crosshair. BOTTOM RIGHT KNOCKBACK FORCE: one chunky golden cartoon clenched fist facing right with a turquoise pushing-motion chevron behind it; bold punch/force silhouette, no blade, no impact explosion, no detached background objects. No text, letters, numbers, labels, bottles, teeth, badges, frames, backgrounds, floor shadows, halos or external haze. Actual transparent alpha background everywhere outside the six silhouettes; not a painted checkerboard. Keep motifs simple, comparable in apparent size, thick readable contours. Exactly six icons, in the specified grid order.
