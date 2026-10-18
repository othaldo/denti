# Schildhülle: Vergleich und Kampf-HUD

Der Vergleich zeigt denselben HUD-Zahn mit 61/100 Leben und 0, 1, 3 sowie
5 Schildladungen. Bereits eine Ladung bedeckt die vollständige Zahnsilhouette
mit einer transparenten, leicht schimmernden blauen Schicht. Jede Ladung erhält
eine vollständige zusätzliche Kontur; weitere Konturen wachsen gleichmäßig
nach außen. Die rote Lebensfüllung und ihre Zahlen bleiben unabhängig davon.

Obere Reihe: 1,6-fach vergrößert auf warmem dunklem Hintergrund.
Untere Reihe: tatsächliche Desktop-HUD-Größe auf hellem Arenaboden.
Die Originalgrafik bleibt unverändert. Die Konturen folgen einer geglätteten
Distanzmaske, mit gleichmäßigem Abstand und weichem Schein.

- [Statischer Vergleich](screenshots/shield_aura/shield_comparison.png)
- [Animierter Vergleich](screenshots/shield_aura/shield_comparison.gif)

Die Darstellung steckt in `HUDToothVessel.show_shield(charges)` und
`HUDShieldAura`. Sie verwendet den vorhandenen Zahn und dessen Originalkontur.
Pause und reduzierte UI-Bewegung steuern auch das Schimmern.
Bei null Ladungen verschwinden Hülle und Konturen vollständig. Bis zu fünf
Konturen entsprechen dem üblichen Ladungslimit in `PlayerStats`.

Die pixeligen Line2D-Übergänge sind durch einen einzelnen Shader ersetzt.
`tools/bake_shield_distance.gd` glättet die geschlossene Zahnkontur und berechnet
ein 512×512-Distanzfeld, gespeichert als 16-Bit-Wert in zwei Texturkanälen in
`assets/ui/tooth_shield_distance.res`. Das passiert nur beim Erzeugen der
Grafikdaten. Der laufende Effekt liest die gefilterte Textur: klare Lichtkerne,
weicher Gauß-Schein und eine dezente wandernde Reflexion. Ableitungsbasierte
Kantenglättung passt sich der Anzeigegröße an. Die früheren überlappenden
Liniensegmente und ihre harten breiten Leuchtränder entfallen.

Die Schildhülle ist an `GameHUD` angeschlossen: `PlayerStats.shield_charges`
steuert die sichtbaren Konturen über die normale HUD-Aktualisierung. Die bisherige
Schild-Pille entfällt. Nach einem geblockten Treffer verschwindet die äußerste
Kontur; bei null Ladungen verschwinden alle Konturen und die blaue Hülle.
Die Spielregeln für Schutz, Ladungsgewinn, Verbrauch und gespeicherte Ladungen
bleiben unverändert. Abstände zu Statussymbolen und Zählern reservieren Platz
für alle fünf Konturen, ohne den Zahn oder seine Zahlen zu verschieben.

[Native Spielaufnahmen in sechs Größen](screenshots/combat_hud/)
zeigen die eingebundene Darstellung. `combat_hud` prüft zusätzlich den echten
Verbrauch von fünf auf null über die normale HUD-Aktualisierung, unveränderte
HP beim Block, verschwundene Hülle bei null und freie Ränder. `mobile_controls`
prüft Bewegungsgesten auf der Schildhülle; `tooth_vessel` prüft Pause, reduzierte
Bewegung und voneinander getrennte Zustände verschiedener Zahninstanzen.

Nach der Einbindung bestanden: `combat_hud`, `tooth_vessel`, `mobile_controls`,
`smoke` und `player_status_effects`. Native Aufnahmen wurden in allen sechs
HUD-Testauflösungen erzeugt.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/bake_shield_distance.gd
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_shield_aura.gd
ffmpeg -framerate 30 -i .godot/shield_smooth_frames/frame_%03d.png -vf "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a" -loop 0 docs/screenshots/shield_aura/shield_comparison.gif
```
