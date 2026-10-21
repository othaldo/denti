# Kronengericht: generierte Originalgrafik

Erstellt am 21.10.2026 mit dem eingebauten Imagegen-Werkzeug, kein CLI-/API-Fallback.
Die Referenzen wurden vor der Generierung betrachtet. Originalgrafiken bleiben erhalten.

- `assets/enemies/emperor_court/parts.png`: transparenter generierter Teileatlas.
- `assets/enemies/emperor_court/portrait.png`: transparentes natives Renderbild des daraus gebauten Rigs.
- Generiertes Original: `C:/Users/othal/.codex/generated_images/01a14f91-1a1b-7303-b702-57f1b1bdf748/exec-911ad6f4-3fb1-4d70-831c-cb914b8bb9b1.png`.

`EmperorCourtArt.REGIONS` legt die tatsächlichen Ausschnitte fest. Die gemalten
Teile werden proportional skaliert und an acht Gelenken bewegt. Portale,
Wurzellanzen und Bodensiegel stammen aus demselben Atlas. Die weichen
Urteilflächen verwenden die vorhandene Charge-Textur, auf feste Sektorgeometrie
gelegt; im Kampf werden keine Bilder erzeugt.

## Verwendeter Prompt

Use case: stylized-concept. Asset type: production transparent 2D game sprite parts atlas for Denti: Divine Dentistry, a charming painted cartoon dental arena survivor. Generate a square transparent image with a strict evenly spaced 3 by 3 grid of NINE ISOLATED PARTS, no gridlines, labels or text. Reference 1 is the old Karies Emperor: thematic inspiration, NOT an edit target. Reference 2 is the Acid King parts atlas: ONLY painted finish/outline quality reference. New character: THE CROWN COURT EMPEROR, a floating corrupted ivory tooth monarch, grand menacing but playfully absurd dental fantasy, stylized nonrealistic. MUST be visually different from the bulky green armored king: narrow elongated floating plum-purple ceremonial cloak, broken ivory face-mask with small magenta eyes and an open dark round chest socket, ruby and amethyst jewels, imperial brass-gold trim, no green tanks or stone boots, no caramel cauldron. Detached crown and guard plates levitate around him. Frontal slight top-down view, upper-left lighting, confident warm dark outlines, glossy painted surfaces, simplified strong shapes readable at 200px assembled size. Keep ALL NINE components completely within equal cells with transparent gutters, no part crossing a cell:
top left: elongated central body with ivory tooth-mask face, dark purple hanging imperial robe tapering to 2 tooth-root tails, chest round empty dark socket, NO crown, NO arms, NO guard shields;
top middle: one wide tall GOLD AND IVORY imperial crown with a central red ruby, floating alone, no head;
top right: detached right arm with ivory hand grasping tall golden scepter topped with a purple diamond, arm and scepter together, no body;
middle left: detached left forearm with ivory hand holding a round small ruby royal seal, no body;
middle middle: one broad curved heraldic CROWN GUARD PLATE, gold border, ivory enamel center, tall tooth-like prongs and a red ruby, isolated; this same plate will be reused three times around the character;
middle right: one glowing magenta-purple exposed nervous core, tooth-root shaped crystal inside a thin gold oval bezel, alone;
bottom left: one magical PORTAL, elliptical upright violet glowing opening with bright magenta organic swirls and a few ivory tooth fragments, transparent surround AND a dark purple translucent opening, not a floor warning or hard geometric circle;
bottom middle: one horizontal root lance projectile pointing RIGHT, ivory tooth-root spear tip, short brass collar and violet magical tail, entire lance in the cell;
bottom right: one ornate small imperial edict seal for the floor, dark plum round medallion with a GOLD tooth-and-crown symbol, painted chunky silhouette.
No background, no gradients outside parts, no text, no watermark. Preserve true alpha transparency. This is an original game asset set, not a UI mockup.
