# Wurzelkraft: generierte Zahn-UI

Erzeugt am 19.10.2026 mit dem integrierten **Imagegen-Werkzeug**.
Keine CLI/API-Fallbacks und keine gezeichneten Ersatz-Icons. Originale Referenzen
bleiben erhalten. Die Alpha-Kanäle der generierten PNGs wurden übernommen.

- HUD-Rahmen: [`assets/ui/stamina_vessel_frame.png`](../assets/ui/stamina_vessel_frame.png)
- Erholungsattribut: [`assets/ui/stamina_recovery_icon.png`](../assets/ui/stamina_recovery_icon.png)
- Referenz: bestehender [`tooth_vessel_frame.png`](../assets/ui/tooth_vessel_frame.png)

Der grüne Innenbereich des HUD-Rahmens ist eine Ersatzmaske für die dynamische
Füllung, keine Spielfarbe. Der Shader zeichnet dort Türkis; Gold und Elfenbein
bleiben aus dem generierten Bild. Der Rahmen wird ausschließlich proportional
verkleinert. Die Erholungsgrafik ist ein fertiges gemaltes Icon mit türkisfarbener
Flüssigkeit und goldenem Kreis-Pfeil für die Karten/Stats.

## Prompt: Gefäßrahmen

Referenzbild: `assets/ui/tooth_vessel_frame.png`. Transparenter Hintergrund aktiviert.

```text
Use case: game UI painted raster asset, new sibling stamina vessel. Input image is STYLE AND PROPORTION REFERENCE ONLY: the existing Denti health resource tooth frame. Generate ONE standalone new polished stamina/Wurzelkraft tooth-shaped vessel FRAME, not a mockup or icon sheet. Match the reference's glossy hand-painted warm cartoon fantasy game UI: rich beveled gold, subtle plum-brown outer edge, ivory enamel accents, smooth clean anti-aliased silhouette, very readable when reduced to 96 logical pixels. Keep a recognizable molar silhouette with a broad softly lobed crown and TWO rounded roots, approximately square overall like the reference. Make this a visually related but distinct companion to the health vessel: slightly sleeker gold rim, small ivory enamel inlays integrated into the two crown shoulders and a tasteful small gold root/leaf engraving on the lower rim. No extra pedestal, floating objects, wings, crown, bolts, lettering or numbers. Technical compositing requirement: the entire inner cavity must be an uninterrupted SOLID FLAT pure chroma green (#00ff00) replacement-mask area all the way to the inside edge of the gold rim; no painted liquid, no gradients, no shadows or reflected highlights on that green cavity. The game replaces this green with animated teal stamina liquid. Paint shading/highlights ONLY on the gold/ivory frame. Background OUTSIDE the complete tooth shape must be genuinely TRANSPARENT with alpha, no black/white/checkerboard backdrop or drop shadow. Centre the complete asset with small even margins, no cropped root tips, no distortion. Original reference health artwork must remain unchanged; deliver only the new sibling stamina-frame asset.
```

## Prompt: Erholungs-Icon

Referenzbild: `assets/ui/stamina_vessel_frame.png`. Transparenter Hintergrund aktiviert.

```text
Create ONE companion painted game stat icon derived from this reference stamina vessel frame for Denti. Match the same molar silhouette, beveled warm gold rim, ivory enamel shoulder inlays and small engraved root leaves. The cavity is now completely filled with glossy translucent TURQUOISE/TEAL magical stamina liquid, brightest mint highlights near the top, deep petrol at the bottom, a subtle horizontal liquid surface and two tiny bubbles; no chroma green anywhere. Add one small tasteful gold clockwise recovery flourish integrated into the liquid, clearly communicating stamina recovery without letters or numbers. This is a finished static stat-card icon, not a HUD mockup or an atlas; broad forms and polished painted fantasy cartoon material readable at 48px. Centre the full tooth with even minimal margins, transparent alpha background outside, no shadow disc, no pedestal, no text, no extra surrounding objects. Preserve source file; create a new icon image.
```
