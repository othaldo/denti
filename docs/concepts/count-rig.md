# Graf C: erster 2D-Rig-Prototyp

Stand: 20.10.2026. **Eigenständiger visueller Prototyp in Godot.** Der hier dokumentierte Aufbau ist inzwischen in den aktiven
[Umhang-Encounter](../COUNT_CLOAK.md) integriert. Die unten verlinkte Werkbank
zeigt weiterhin die isolierte Rig-Studie.

## Ergebnis

- Zwölf echte `Bone2D`-Gelenke unter einem `Skeleton2D`: Körper, Kopf,
  zwei Fühler, zwei Füße und je drei Gelenke pro Umhangseite.
- Neun neue gemalte Einzelteile in einem transparenten Atlas. Originalreferenzen
  und die bisherigen Ganzkörperbilder bleiben erhalten.
- Zwei `Polygon2D`-Stoffnetze mit je 49 Punkten, 72 Dreiecken und normalisierten
  Einflüssen der jeweiligen Schulter-/Mitte-/Spitze-Kette.
- Körper, Gesicht, Fühler und Füße sind starre gemalte Einzelteile an Gelenken.
  Alle Bildskalierungen bleiben proportional. Nur die Stoffnetze werden gebogen.
- Ein nativer `AnimationPlayer` steuert eine 3,4-s-Studie: Auffächern, kurzer
  linker Schlag, erneutes Ausholen, rechter Gegenschlag und Erholung.
  Die eigentlichen Schläge dauern ungefähr 0,09 s; die Stoffspitzen folgen mit
  zeitlichem Versatz. Kopf und Füße reagieren ergänzend.
- Ein- und Ausblenden der Knochen-/Netzansicht dient nur der Entwicklung.
  Die Aufnahme enthält keinerlei Wechsel der Ganzkörperbilder.
- Eigene Mipmap-Importeinstellungen und lineare Filterung für kleine Darstellung.

Die Figur öffnet den Umhang aus getrennten Flächen. Das erhält die Identität
von Entwurf C, ist aber eine neu gemalte modulare Fassung; die Ruhepose und
die Überdeckung beim schnellen Schlag brauchen weiterhin gestalterische
Abnahme. Der Stoff schlägt vor dem Körper vorbei; das Gesicht bleibt für die Lesbarkeit
auch beim Schlag davor sichtbar. Noch nicht
enthalten sind vollständige Lauf-/Treffer-/Todesanimationen oder ein neuer
Schadensablauf. Die aktive Kampfkomponente taktet Warnung, Trefferzeit und
Rig-Darstellung gemeinsam; das Rig entscheidet nicht selbst über Schaden.

## Dateien und Vorschau

- [Editierbare native Rig-Szene](../../scenes/enemies/count_cloak_rig.tscn).
- [Rig und Bindungen](../../scripts/enemies/count_cloak_rig.gd).
- [Animationskurven](../../scripts/enemies/count_rig_motion.gd).
- [Debugansicht](../../scripts/enemies/count_rig_overlay.gd).
- [Generierter Teileatlas](../../assets/enemies/count_rig/parts.png).
- [Browser-Vorschau](count-bedbug/rig.html), [Video](count-bedbug/rig.mp4),
  [GIF](count-bedbug/rig.gif) und [native Einzelaufnahme](count-bedbug/rig-open.png).

Die Szene speichert Knochen, Bindungen und Animation als native Godot-Ressourcen.
Die Knochen und Kurven lassen sich dadurch im Editor weiter bearbeiten. Der
Builder erzeugt diese Szene aus der aktuellen modularen Definition erneut;
ein erneuter Builderlauf überschreibt manuelle Änderungen an der generierten Szene.

```powershell
# Interaktive native Werkbank mit Pause, Zeitleiste und Knochenansicht:
Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_count_rig.gd

# Reproduzierbare Aufnahmen, inklusive eines vollständigen Animationsloops:
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_count_rig.gd -- --animate

# Nur bei absichtlichem Neuaufbau der editierbaren Rig-Szene:
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/build_count_rig.gd
```

Aufnahmen entstehen unter `.godot/count_rig_preview/`. Das MP4 übernimmt alle
102 nativen Frames bei 30 Bildern/s und 1024×720 Pixeln. Die GIF-Vorschau ist
proportional auf 768×540 Pixel und 20 Bilder/s verkleinert; der gemeinsame
Farbsatz vermeidet wechselnde Farben. Die Ausgangsgrafik wurde nicht nachbearbeitet.

## Prüfung

`tests/count_rig.gd` prüft gültige Knochenbindungen und Gewichtssummen, die
Stoffgeometrie über 205 Zeitpunkte, unverzerrte Gesichtsachsen, unabhängige
Instanzen, bewegliche Spitzen sowie Scrubbing und Pause. Kleinste gemessene
Dreiecksfläche: rund **65 %** ihrer Ausgangsfläche; kein Dreieck klappt um
oder kollabiert in der untersuchten Folge.

**3/3 bestanden:** `count_rig`, `pillow_encounter` und `smoke`,
4,00 s am 20.10.2026, Logs
`.godot/test_runs/20261020-203808-19254b17`. Editor-Import nach Aktivierung
der Mipmaps fehlerfrei. Native Ruhe-, Auffächer- und beide Schlagposen sowie
die kleine Ansicht wurden visuell geprüft.

Dies ist kein Web-Performance- oder Kampf-Balancenachweis. Der aktive Encounter samt Kampfphysik und
Speichern/Fortsetzen wird gesondert in `../COUNT_CLOAK.md` geprüft.

## Artwork und genauer Generierungsauftrag

Erstellt mit dem **integrierten Imagegen-Werkzeug**, transparenter Hintergrund.
Identitäts- und Stilreferenz: `docs/concepts/count-bedbug/c.png`, vor dem
Auftrag angesehen. Ziel ist ein neuer Teileatlas, kein Überschreiben der Referenz.

Unverändertes generiertes Ergebnis:
`assets/enemies/count_rig/parts.png`.

Quelle:
`C:/Users/othal/.codex/generated_images/01a14f91-1a1b-7303-b702-57f1b1bdf748/exec-8c79ef90-446d-4889-956d-1f708e301b54.png`.

Die sichtbaren Teilregionen wurden über ihre Alpha-Komponenten bestimmt.
`AtlasTexture` beziehungsweise die UV-Koordinaten der Stoffnetze wählen sie
zur Laufzeit aus dem Original; es wurden keine Pixel aus der Referenz ausgeschnitten
oder neue Körperteile von Hand gezeichnet.

```text
Use case: stylized-concept. Asset type: ONE transparent modular character-parts atlas for a Godot 2D skeletal rig. Input image is the approved Denti Karies-Graf C CHARACTER AND PAINTING REFERENCE, not an image to overwrite. Preserve its burgundy bedbug-vampire identity, haughty amber eyes, single long ivory fang, curved antennae, plum velvet cloak with ivory padded lining, small brass throat clasp, thick warm dark outlines and glossy painted cartoon finish. Produce DISASSEMBLED PARTS, not assembled characters, no animation poses. EXACTLY NINE SEPARATE PIECES in a spacious regular 3 BY 3 square grid. Each piece centered entirely within its own cell with at least 12 percent transparent margins, no overlap, no labels. All nine pieces belong to this one creature, same frontal slightly elevated camera. Layout reading order: TOP LEFT: complete bare segmented burgundy oval abdomen and small shoulder/torso mass, fully painted hidden anatomy, no head, no collar, no limbs, no cloak. TOP CENTER: complete detached broad triangular-round head with amber eyes, angry heavy eyelids, small smile and ONE long ivory fang, no antennae, no neckwear, no body. TOP RIGHT: one complete broad LEFT cloak flap, attachment at its upper RIGHT corner, opening outward/downward to LEFT, richly padded warm ivory inner surface, plum velvet folded outer edge, large simple folds, wide triangular petal shape with a curved lower tip; no attached arm or head. MIDDLE LEFT: complete RIGHT cloak flap, attachment at upper LEFT corner, opening outward/upward to RIGHT, same inner ivory and plum edging, broad triangular petal, not a bat wing, no arm or body. MIDDLE CENTER: one detached LEFT antenna, curved burgundy stalk ending in glossy round tip, base clearly visible at bottom. MIDDLE RIGHT: matching detached RIGHT antenna curved the opposite way. BOTTOM LEFT: one short complete LEFT beetle leg and flattened burgundy foot, no body. BOTTOM CENTER: matching RIGHT leg and foot. BOTTOM RIGHT: separate broad ivory padded V-shaped collar with dark plum outer lapels and a small brass double-button clasp at the bottom of the V, open center suitable for layering over neck/body, no head or body. Every part is completely painted past its attachment point with generous hidden overlap, no cut-out holes needed. Preserve the approved character, do not invent crown, monocle, nightcap, extra teeth, human hands or skin. Clean source assets for rigging, no scenery, no ground shadows, no text or watermark, genuinely transparent alpha background. Large bold shapes that read at 112 px assembled height. Source proportions may be fitted by uniform scaling of each part only.
```
