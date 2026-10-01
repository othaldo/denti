# Entzündete Bosse

![Die vier entzündeten Bosse mit orangefarbener, roter, pinker und violetter Energie-Aura](screenshots/boss_entzuendung.png)

Direkt aus Godot aufgenommen. Für den Farbvergleich sind die Bosse hier gleich
groß dargestellt; im Spiel behalten sie ihre tatsächliche Größe. Die Aufnahme
zeigt einen Frame der laufenden Aura-Animation nach 30 Sekunden Entzündung.

Nach Ablauf des Wellenzeitlimits erscheint **ENTZÜNDET +Ns** im HUD und einmal
**ENTZÜNDET!** am Boss. Die bereits vorhandene Wutphase bei halbem Leben bleibt
getrennt und heißt im Feedback **BOSS WIRD WÜTEND!**.

Die Entzündung behält das bestehende Balancing: pro voller Sekunde +5 % Schaden
und Verteidigung, +3 % Bewegungs-/Projektiltempo, +4 % Angriffstempo und +2 %
Ausgangs-HP. Das Verhältnis aktueller zu maximaler Gesundheit bleibt erhalten.
Warnzeiten werden nicht verkürzt.

| Boss | Aura | Grundintensität | Aura-Breite / Radius |
| --- | --- | ---: | ---: |
| Karies-Graf, Welle 5 | Orange | 0,65 | 3,2 |
| Karies-Prinz, Welle 10 | Rot | 0,75 | 3,4 |
| Karies-König, Welle 15 | Pink | 0,85 | 3,6 |
| Karies-Imperator, Welle 20 | Violett | 0,95 | 3,8 |

Die Werte stehen in den vier EnemyData-Ressourcen. Der separate Baustein
`BossInflammationAura` spielt acht gemeinsam verwendete Frames mit 14 FPS ab,
folgt dem schwebenden Zahnsprite und pulsiert leicht. In den ersten 60 Sekunden
steigt die sichtbare Breite um höchstens 22 %, die Animationsgeschwindigkeit um
höchstens 45 % und die Deckkraft um die Hälfte der verbleibenden Differenz zu 1.
Die Kampfwerte eskalieren weiterhin unbegrenzt. Die Aura blendet mit dem Tod aus.

Die Aura liegt hinter dem Boss und dessen Warnzeichnungen; ihr Zentrum bleibt
transparent. Normale Gegner erzeugen keinen Aura-Knoten. Der Status wird aus den
bereits gespeicherten Overtime-Daten wiederhergestellt; alte Spielstände bleiben
kompatibel. Der alte gespeicherte Schlüssel `enraged` beschreibt weiterhin die
bisherige Wutphase und wird aus Kompatibilitätsgründen beibehalten.

## Grafik und Prüfung

`assets/vfx/boss_inflammation_aura.png`: 1774 × 887 Pixel, RGBA, acht weiße
Energie-Aura-Frames in vier Spalten und zwei Reihen, erstellt mit dem eingebauten
OpenAI ImageGen-Werkzeug. Die Engine färbt das gleiche Motiv je Boss ein. Die
`SpriteFrames`-Resource `data/effects/boss_inflammation_frames.tres` legt das
Raster mit ganzzahligen Ausschnitten, Filterbegrenzung und identischen virtuellen
480 × 480 Pixel großen Rahmen fest. Die Quelldatei bleibt unverändert.

`tests/boss_inflammation.gd` prüft die Frames, transparente Mitte, Randabstände,
Farben/Intensitäten, laufende Animation, begrenztes Wachstum, Position und Ausblenden.
`tests/boss_overtime.gd` prüft außerdem Auslösung, HUD, Balancing und Fortsetzen.
`tools/preview_boss_inflammation.gd` rendert 16 Vorschauframes nach
`.codex/boss-inflammation-previews/`. Für den direkten Farbvergleich zeigt diese
Vorschau die vier Bosse gleich groß; im Spiel behalten sie ihre tatsächliche Größe.

## Verwendeter Prompt

```text
Use case: stylized-concept. Asset type: transparent animated VFX sprite sheet for the 2D hand-painted cartoon dental arena game Denti: Divine Dentistry. Create exactly EIGHT consecutive frames of ONE seamlessly looping power-up aura, dramatic Kaioken-like upright flickering energy flames surrounding a character, with NO character included. Strict FOUR equal columns by TWO equal rows on a landscape 2:1 canvas, preferably 1536x768. Every cell is an identical square. Same stationary centered oval flame shell in every frame, same scale, center, footprint and baseline; only small flame tips, flickering energy arcs and tiny sparks change progressively around the perimeter for a smooth loop (frame 8 flows back to frame 1). Frame order left-to-right top row then bottom row. Art: bold clean stylized cartoon energy flame tongues, flowing upward, polished dimensional highlights, white hot rims, soft faint glow at the outside only, compatible with glossy hand-painted dental game characters. MONOCHROME WHITE / pale silver light with alpha transparency, suitable for tinting red, orange, pink and purple in engine. No opaque dark lines. A broad completely TRANSPARENT hollow center occupying at least central 55% width and 60% height in each frame, so the boss's face, tooth body and crown remain fully readable. Energy wraps around both sides and underneath in an oval, tall flames above, a few small curved energy streaks just at the perimeter. Entire art within the middle 80% of each cell, with at least 10% fully transparent padding on all sides. Nothing touches or crosses a cell boundary; NO background fill, NO glow filling center, NO backdrop, NO ground, NO teeth, NO people, NO character silhouette, NO text, NO labels, NO grids. Actual transparent alpha background everywhere outside flame strands including the hollow center. Effect should remain compact near one boss, not cover the arena. Eight visibly distinct but consistent animation phases, no growing/shrinking or drifting oval, one aura per cell.
```
