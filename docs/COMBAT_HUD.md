# Zahn-HUD mit animierter Lebensfüllung

Stand: 18.10.2026. Das HUD verwendet das warme dunkle Denti-Theme und gemalte
Grafiken. Der Spielfeldmitte bleibt frei; Spielerressourcen sind unten verankert.

## Gestaltung

- Das Zahngefäß steht unten links: 108×108 Pixel auf Desktop, kompakt 96×96.
  Die Lebensfüllung bewegt sich mit sanftem Wellengang, Bläschen und kurzer
  Schadensspur. Aktuelles Leben steht mit 18 Pixeln in der Krone, darunter
  das Maximum mit 12 Pixeln und vorangestelltem Schrägstrich: `123 / 155`.
  Das Wort „max“ erscheint nicht. Beide Zeilen tragen eine dunkle Kontur.
  Große Werte werden mit `k`/`M` abgekürzt.
- Schildladungen bilden eine transparente, leicht schimmernde blaue Hülle über
  dem ganzen Zahn, mit einer vollständigen Kontur pro Ladung. Bis zu fünf Konturen
  bauen sich nach außen auf. Beim Block verschwindet die äußerste, bei null die
  gesamte Hülle. Lebensfüllung und Zahlen bleiben unabhängig davon.
  Ein geglättetes Distanzfeld zeichnet die Konturen mit weichen Kanten und
  Lichtschein; eine dezente Reflexion wandert darüber.
  [Vergleich und Einbindung](SHIELD_AURA_PREVIEW.md). Gift und Blutung stehen
  mit Abstand oberhalb der Hülle: je 24-Pixel-Icon und 12-Pixel-Restzeit.
- Münzen und Kapseln stehen rechts neben dem Zahn, als zwei ausgerichtete
  24-Pixel-Zeilen mit vier Pixeln Abstand. Der Abstand zur Zahngruppe beträgt
  16 Pixel, damit alle fünf Schildkonturen Platz haben. Es gibt keinen Sockel.
- XP bleibt eine fünf Pixel dünne Mint-Linie am unteren Rand. Ihr Track ist
  warmes Pflaumenbraun. Das Level-Medaillon sitzt auf allen Bildschirmformaten
  unten mittig: ein gemaltes Goldsiegel mit kleinen Elfenbein-Zahnornamenten
  und Pflaumenkern, 48×42 Pixel. Die kleine Fassung hat eine ruhige Kontur,
  breiteren Rand und eine größere Levelzahl mit 16 Pixeln.
  Offene Aufstiege stehen in einer schlichten, 18 Pixel hohen Pille mit dünnem
  Goldrand, Chevron nach oben und 12-Pixel-Zahl. Chevron und Zahl werden als
  Gruppe zentriert, mit gleichmäßigem Randabstand. Die Breite folgt dem Inhalt:
  einstellige Zahlen benötigen etwa 30–34 Pixel, `99+` etwa 46–48 Pixel.
  Der linke Ansatz bleibt fest am oberen rechten Rand des Medaillons;
  nur der rechte Rand wächst. Level und Zahnperle bleiben frei und unverrückt.
  Bei null ist die Pille unsichtbar. Ab 100 zeigt sie `99+`. Die genaue Zahl steht
  unter Pause → Stats. Nur ein Zugewinn löst einmalig 300 ms sanftes Aufleuchten
  aus. Wiederholte HUD-Aktualisierungen und das Auswählen von Aufstiegen lösen
  keinen neuen Effekt aus. Pause friert ihn ein, reduzierte Bewegung unterdrückt ihn.
  In der Aufstiegsauswahl erhält die Pille einen kräftigeren, ruhigen Goldrand.
- Welle und Zeit teilen einen 44-Pixel-Bereich oben mittig, in schmalem Querformat
  oben links. Die Wellenangabe hat 13 Pixel. Bei Entzündung bilden Flamme und
  `+n s` eine gemeinsam zentrierte Zeile mit sechs Pixeln Abstand; die Flamme
  wird auf die Ziffernhöhe skaliert. Beutesammlung und Shop verwenden denselben
  Bereich. Nur die innere Ausrichtung folgt der Textbreite.
- Bossleisten sind bei 1280 Pixeln Bildschirmbreite 450×22 Pixel groß,
  einschließlich der unverzerrten Kappen. Zwei Leisten stehen mit vier Pixeln
  Abstand untereinander; bei 1920 Pixeln stehen zwei Bosse nebeneinander.
  Namen stehen linksbündig auf der Ressource, Prozentwerte rechts in einer
  reservierten Fläche. Beide verwenden 13 Pixel. Lange Namen werden gekürzt;
  vollständige Namen und exakte Lebenswerte: Pause → Stats → Bossdetails.
- Die gesamte gemalte Innenfläche des Bossrahmens ist die Lebensressource,
  einschließlich der Rundungen bis an beide Zahnenden. Der gefüllte Anteil
  ist rot, der verbrauchte dunkel. Endstücke behalten ihre Proportionen;
  nur der gerade Mittelteil wird wiederholt, ein Reststück abgeschnitten.
- Touch-Pause hat einen goldenen Rand und mindestens 44×44 Pixel Trefferfläche.
  FPS ist optional und verwendet 12 Pixel. Alle anderen HUD-Flächen lassen
  Bewegungsgesten durch. Reguläre Kampftexte sind mindestens 12 Pixel groß;
  debuginterne Telemetrie bleibt getrennt vom normalen Kampf-HUD.

## Animation und Technik

`HUDToothVessel` hält ausschließlich Darstellungszustand. `PlayerStats` bleibt
maßgeblich für Leben und Schaden. Zahlen werden sofort aktualisiert; der Pegel
nähert sich dem Wert schnell an. Die Schadensspur wartet 0,25 s und läuft kurz
nach. Pause friert die Animation ein. Reduzierte UI-Animationen deaktivieren
Wellengang, Bläschen und Interpolation.

Der gemalte [Zahnrahmen](../assets/ui/tooth_vessel_frame.png) wurde mit dem
**eingebauten Imagegen-Tool** erstellt; der [Prompt](art/tooth_hud_prompt.txt)
liegt im Projekt. Die technische grüne Innenfläche wird ausgeblendet. Die
Flüssigkeit folgt der einmalig ermittelten äußeren Alpha-Kontur darunter;
innere Transparenzen erzeugen deshalb keine Löcher. Originalreferenzen bleiben erhalten.

Die fünf [HUD-Symbole](../assets/ui/status/) stammen ebenfalls aus dem eingebauten
Imagegen-Tool; ihre [Prompts](art/hud_status_icon_prompts.txt) liegen im Projekt.
`HUDStatusIcons` entfernt transparenten Außenabstand nur für die Darstellung
und zentriert Motive ohne Verzerrung. Münzen und Kapseln nutzen vorhandene Grafiken.

Der [Bossrahmen](../assets/ui/boss_hud_frame.png) stammt aus demselben Tool;
der [Prompt](art/boss_hud_prompt.txt) ist dokumentiert. `HUDPaintedFrame` zeichnet
Endstücke und wiederholte Mitte aus der unveränderten PNG-Datei.
`boss_frame_mask.gdshader` färbt die gemalte Innenfläche anhand des angezeigten
Lebensanteils, einschließlich gebogener Übergänge. Der ProgressBar hält den
angezeigten Wert; sein Verhältnis steuert den Shader. Beschriftungen liegen darüber.

Das [vereinfachte Level-Medaillon](../assets/ui/level_seal_compact.png) wurde
mit dem eingebauten Imagegen-Tool erstellt; der [Prompt](art/level_seal_compact_prompt.txt)
liegt im Projekt. `HUDProgressionFrame` verwendet einmalig erzeugte gemeinsame
Mipmaps und passt die Grafik proportional ein. Der ursprüngliche
[Levelrahmen-Atlas](../assets/ui/level_frames_atlas.png) und sein
[Prompt](art/level_frames_prompt.txt) bleiben als Referenz erhalten.
`HUDPendingLevels` zeichnet die kleine Pille mit geglättetem Chevron und
verwaltet ausschließlich Darstellungszustand. Der exakte Zähler bleibt in
`PostWaveRewards`. Die Hervorhebung folgt dessen autoritativem Schritt `LEVELS`.

Pro Frame ändern sich wenige Materialwerte. Es werden keine Bilder oder
Partikelknoten neu erzeugt. Jede Zahninstanz hat eigene Animationswerte.
Außengeometrie hängt von Bildschirm und Safe Area ab; Zahlen verändern die
vorgesehenen Flächen nicht. Die spätere Wurzelkraft-/Dash-Mechanik bleibt separat.

## Prüfung und Aufnahmen

Der vollständige Testlauf nach der HUD-Überarbeitung und Aufräumaktion hat
**116/116 Tests** bestanden (18.10.2026). Darunter sind `combat_hud`,
`hud_pending_levels`, `tooth_vessel`, `mobile_controls`, `smoke`,
`boss_overtime`, `player_status_effects`, `ui_layout` und `arena_background`.

`combat_hud` prüft 320×568, 568×320, 720×1280, 1040×600, 1280×720 und
1920×1080 mit und ohne Touch-Pause/FPS, einschließlich großer Werte, 999
Schildladungen, vorgemerkter Aufstiege, langer Bossnamen und zweier Bosse.
Geprüft werden Ressourcenanker, Lebenszahlen in der Krone, Schildhülle,
Timerzentrierung, Schriftgrößen, Goldrand, Bossmaße und vier Pixel Leistenabstand.
`mobile_controls` prüft Bewegungsgesten auf dekorativen HUD-Elementen.
`tooth_vessel` prüft Zahlenformat, Animation, Pause und reduzierte Bewegung.

Die [aktuellen nativen Aufnahmen](screenshots/combat_hud/) zeigen normalen
Kampf und einen Belastungszustand in sechs Größen. Bosse haben 62 % und 24 %
Leben; zusätzliche Aufnahmen bei 100 % zeigen die Übergänge zur Zahnfassung.
Der Kampf ist für die Aufnahmen angehalten; FPS-Werte sind keine Performancemessung.
Nach der Umstellung auf die Aufstiegs-Pille bestanden `combat_hud`,
`hud_pending_levels`, `mobile_controls` und `ui_layout`; alle sechs Größen
wurden nativ gerendert. Zusätzliche Aufnahmen auf Handy und Desktop zeigen
1, 3, 5 und 123 offene Aufstiege. Tests prüfen feste Geometrie einschließlich
0 und `99+` mit festem Ansatz und inhaltsabhängiger Breite, genaue Zahl in Pause → Stats sowie einmaligen Gewinnhinweis,
Pause und reduzierte Bewegung.
Die [Detailansicht](screenshots/combat_hud/level_details_3x.png)
zeigt dieselben HUD-Komponenten dreifach vergrößert und darunter in Originalgröße.
Die [native Animation](screenshots/combat_hud/animated_tooth.gif) zeigt
dieselbe Zahnkomponente dreifach vergrößert. Überholte HUD-Zwischenstände wurden entfernt.

`tools/check_hud_frame_render.gd` vergleicht gerenderte Rahmenenden bei drei
Breiten auf Pixelgleichheit. Die [Symbolübersicht](screenshots/combat_hud/painted_icons.png)
zeigt die fünf gemalten Icons vergrößert und in ihrer ursprünglichen HUD-Größe.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter combat_hud --filter tooth_vessel --filter mobile_controls
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script res://tools/preview_combat_hud.gd
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 30 --script res://tools/preview_tooth_animation.gd
ffmpeg -framerate 30 -i .godot/tooth_animation_frames/frame_%03d.png -vf "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a" -loop 0 docs/screenshots/combat_hud/animated_tooth.gif
```

Vorschauen verwenden einen eigenen Run-Spielstand. Ein separater `APPDATA`-Pfad
trennt bei Bedarf zusätzlich Einstellungen.
