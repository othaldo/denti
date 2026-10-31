# Controller-Steuerung

Die Eingabeaktionen unterstützen Tastatur, Touch und Gamepads gemeinsam.
Angriffe bleiben automatisch; der rechte Stick dient in Menüs zum Scrollen.

| Aktion | Xbox | PlayStation |
| --- | --- | --- |
| Bewegen | Linker Stick | Linker Stick |
| Menüfokus bewegen | Steuerkreuz / linker Stick | Steuerkreuz / linker Stick |
| Fokussierte Aktion ausführen | A | Kreuz |
| Eine Ansicht zurück / Details schließen | B | Kreis |
| Wurzelsprung | RB | R1 |
| Pause / fortsetzen | Menu | Options |
| Shop oder Level-Boni neu würfeln | X | Quadrat |
| Startauswahl: Details | Y | Dreieck |
| Shop: fokussiertes Angebot kaufen | A | Kreuz |
| Shop: Angebot merken / freigeben | Y | Dreieck |
| Shop: optionale Angebotsdetails | RB | R1 |
| Shop: Verzaubern öffnen | LB | L1 |
| Shop: nächste Welle starten | RT | R2 |
| Verzaubern: gewählte Verzauberung / Fertig | X | Quadrat |
| Verzaubern: letzte geplante Änderung rückgängig | Y | Dreieck |
| Verzaubern: vorige / nächste Waffe | LB / RB | L1 / R1 |
| Verzaubern: Aufsteigen, sofern verfügbar | RT | R2 |
| Listen und Details scrollen | Rechter Stick, auf/ab | Rechter Stick, auf/ab |

B öffnet im Kampf keine Pause. Pflichtbelohnungen werden weiterhin ausdrücklich
ausgewählt. Beim Verzaubern verlässt B nur die Effektauswahl oder schließt
Details; es übernimmt nie den Entwurf. Nur X/Quadrat führt „Fertig“ aus.
Eine Fusion wird mit B abgebrochen und erst über „Fusionieren“ bestätigt.

Beim Verzaubern bestätigt X/Quadrat die gewählte Verzauberung unabhängig vom
Fokus; in der Übersicht übernimmt es wie „Fertig“ den Entwurf. Der Punktepreis
steht in der Aktionsleiste. Y/Dreieck nimmt in der Übersicht die letzte geplante
Änderung zurück, LB/RB bzw. L1/R1 wechseln die ausgewählte Waffe und RT/R2 plant
einen verfügbaren Aufstieg. Punkte-, Gold- und Effektsperren gelten auch für
diese Kürzel. Detailfenster sperren die dahinterliegenden Aktionen.

Bei Controller-Bedienung ersetzt die Aktionsleiste die unteren Bildschirm-Buttons
für Bestätigen und Rückgängig. In der Übersicht steht ein einziges „Fertig“,
ausschließlich auf X/Quadrat. In der Effektauswahl bleiben
„Zurück“ und „Verzaubern · Preis“ getrennte Aktionen. Mit Maus und Tastatur
kehren die Bildschirm-Buttons zurück; Tastaturfokus erreicht die Hauptaktion
vom letzten Eintrag im Effektraster und von der letzten Waffenkarte aus.
Nach einer Verzauberung bleibt der Fokus am bearbeiteten Platz; Waffenwechsel
und Rückgängig stellen den Fokus an der ausgewählten Waffe wieder her, auch
bei gleichen Exemplaren.

Shopangebote sind jeweils ein Fokusziel. A/Kreuz kauft direkt, Y/Dreieck merkt
das Angebot kostenlos oder gibt es wieder frei. Der Fokus bleibt beim Merken
auf der Karte und wechselt nach dem Kauf zu einem verfügbaren Ziel. Zu teure
oder blockierte Käufe bleiben gesperrt; sie öffnen auch kein Detailfenster.
RB/R1 und ein Mausklick auf die Kartenfläche öffnen weiterhin optionale Details.
Die sichtbaren Kauf- und Pin-Buttons bleiben direkt mit Maus/Touch bedienbar.
Mit Tastatur kauft Enter das fokussierte Angebot; P merkt es, I öffnet Details.

Bei Controller-Bedienung entfallen die Bildschirm-Buttons für Würfeln,
Verzaubern und Wellenstart. Die Aktionsleiste übernimmt diese Aktionen und zeigt
auch den Würfelpreis. Bei bewusster Maus-, Touch- oder Tastaturbedienung kommen
die Buttons zurück. Eine fest gewählte Symbolfamilie allein blendet sie nicht aus.
Verzaubern wird nur angeboten, wenn es im aktuellen Build verfügbar ist.
Diese Kürzel gelten nicht hinter Detailfenstern, Pausen oder Belohnungsansichten.
RT/R2 muss zunächst losgelassen und dann deutlich gedrückt werden (über 0,8);
gehaltenes Drücken startet beim nächsten Shopbesuch keine Welle automatisch.

## Controller-Modus

`Einstellungen → Controller-Modus` speichert vier Modi:

| Modus | Verhalten |
| --- | --- |
| Automatisch | Symbole für das bewusst aktivierte Gamepad; Maus, Tastatur und Touch wechseln zur jeweiligen Bedienung. |
| Xbox | Xbox-Symbole bleiben auch bei Maus- und Tastaturbedienung sichtbar. |
| PlayStation | PlayStation-Symbole bleiben auch bei Maus- und Tastaturbedienung sichtbar. |
| Aus | Keine Controller-Symbole oder Controller-Eingaben, auch nicht für Bewegung, Dash und Menüs. |

Automatisch berücksichtigt Namen und Hersteller des aktiven Gamepads. Ein von
Godot gemapptes Gamepad wird durch einen belegten Tastendruck oder eine bewusste
Stickbewegung aktiviert. Eine Achse muss zunächst die Neutralzone (0,2) erreichen,
bevor sie ab 0,55 den Eingabemodus übernehmen darf. Linker Stick, die vertikale
Scroll-Achse des rechten Sticks und der belegte rechte Trigger zählen;
unbenutzte Achsen und der linke Trigger aktivieren keine Anzeige.
Unbekannte Joysticks, Lenkräder, Pedale und erkennbare
Simulator-Panels werden nicht automatisch übernommen.

Nach Aktivierung bleibt das Gerät bis zum Trennen oder bis zur Wahl von „Aus“
ausgewählt. Andere angeschlossene Geräte können weder Spielaktionen auslösen
noch den Fokus übernehmen. Tastatur und Touch bleiben verfügbar. Die manuelle
Symbolwahl hilft, wenn ein Treiber oder Browser einen PlayStation-Controller als
Xbox-Gerät meldet; sie verändert nicht die Tastenbelegung.

Mauszittern unter einem logischen Pixel und Ereignisse ohne Bewegung ändern
den Modus nicht. Deutliche Mausbewegung wird über ein kurzes Fenster gesammelt;
analoge Gegenwechsel werden 600 ms lang abgefangen. Tastendrücke und Klicks
reagieren unmittelbar. Anzeige und Bedienfokus sind getrennt, damit feste
Xbox-/PlayStation-Symbole die Mausbedienung nicht behindern.

Die SVGs unter `assets/ui/controller/` sind eigene, skalierbare Zeichnungen der
Tasten. Sie ersetzen keine Item- oder Waffenbilder. Die Menüs zeigen eine
gemeinsame Aktionsleiste unten: Symbol vor Aktionsname, gemeinsame Mittellinie,
gleiche Abstände. A bezieht sich auf das fokussierte Element; B, X und Y werden
nur mit den im aktuellen Kontext verfügbaren Aktionen angezeigt. Modale
Details zeigen keine Kürzel der dahinterliegenden Ansicht. Karten und Buttons
behalten ihren Fokusrahmen und ihre Bilder, ohne Tastenaufkleber an den Ecken.
Der Panel-Hintergrund füllt die gesamte verfügbare Bildschirmbreite. Seitliche
Innenabstände gelten nur für die Tastenhinweise; das Panel wächst mit seinen
Zeilen und wird nicht auf die eingerückte Inhaltsbreite begrenzt.
Die Leiste verwendet 48 logische Pixel für eine Zeile und bei Bedarf weitere
40 Pixel je Zeile. Shopaktionen werden auf schmalen Bildschirmen umgebrochen,
ohne Schrift und Tastenzeichen zu verkleinern. Der Shop behält den reservierten
Platz beim Öffnen von Details, damit die Angebote im Hintergrund nicht springen.
Im automatischen Modus
fällt dieser Bereich bei Maus, Tastatur oder Touch weg. Bei fest gewählter
Symbolfamilie bleibt er stabil. Im Kampf steht RB/R1 mittig unter Wurzelkraft.

Fokussierte Schalterzeilen umschließen Beschriftung und Schalter mit demselben
Innenabstand. Während Tastatur-/Controllerbedienung erhält ein unter der Maus
liegendes anderes Bedienelement keinen zusätzlichen Auswahlrahmen; bei bewusster
Mausbedienung kehrt dessen Hover-Rückmeldung zurück.

Die Anordnung folgt den offiziellen Beispielen in Microsofts
[XAG 112: UI navigation](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112)
und [XAG 113: UI focus handling](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/113):
Sea of Thieves gruppiert Auswählen, Zurück und weitere Aktionen am unteren Rand;
The Outer Worlds trennt den Auswahlrahmen vom Zurück-Hinweis, und das
Forza-Dialogbeispiel verwendet einen Auswahlhinweis außerhalb der Optionen.
Die Umsetzung für Denti übernimmt daraus eine feste Leiste mit Glyph/Text-Paaren
und einen separaten, gut sichtbaren Fokusrahmen.

## Technischer Schnitt

- `GameInput` erkennt geeignete Gamepads und Symbolfamilie, filtert Rauschen und
  doppelte gehaltene Tasten und meldet den Verlust des aktiven Controllers.
- `ControllerBindings` bindet alle Gamepad-Ereignisse im InputMap an genau das
  aktive Gerät. Inaktive oder ausgeschaltete Controller haben keine Belegungen.
  Dadurch bleiben auch Godots globaler Eingabestatus und native GUI-Controls
  geschützt. Beim Umstellen werden Controller-Zustände freigegeben und noch
  gehaltene Tastaturtasten erhalten. Die erste aktivierende Eingabe wird einmal
  mit den passenden Belegungen weitergegeben.
- `ControllerNavigation` verwaltet Fokusbereiche nach CanvasLayer und lokaler
  Priorität. Der oberste sichtbare Bereich begrenzt die Controller-Navigation;
  Popup-Menüs und Slider behalten ihre nativen Eingabesemantiken. Gehaltene
  Richtungen wiederholen nach 0,35 Sekunden im Abstand von 0,11 Sekunden.
- `ControllerFocus` sammelt erreichbare Controls, merkt semantische Schlüssel
  und hält fokussierte Elemente beim Navigieren oder Umordnen sichtbar.
  Ausrüstungs- und Verzauberungsbuttons verwenden stabile IDs über Neuaufbauten.
- `ControllerPrompt` beschreibt verfügbare Aktionen. `ControllerActionBar` zeigt
  die zum obersten Fokusbereich passenden Glyph/Text-Paare aus `ControllerGlyphs`.
  Nur der Dash-Hinweis bleibt unmittelbar am zugehörigen HUD-Element.
- Der bestehende Run-Koordinator bleibt für Kampf, Belohnungen und Shop zuständig.
  Symbolwahl und Controller-Fokus verändern keine Belohnungs- oder Speicherdaten.

Im laufenden Kampf öffnet ein Verbindungsverlust die vorhandene Pause.
Erneutes Verbinden setzt den Run nicht selbstständig fort. Controller-Eingaben
in einem nicht fokussierten Anwendungsfenster werden von Godot ignoriert.

## Prüfung

```powershell
python tools/run_tests.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --filter 'controller_*'
```

Die Controller-Prüfungen senden tatsächliche `InputEventJoypadButton`- und
`InputEventJoypadMotion`-Ereignisse durch Godot. Sie decken analoge Bewegung,
Totzone, mehrere Geräte-IDs, Stickschwankungen, Richtungswiederholung,
gehaltenes Bestätigen, Symbolwechsel und Persistenz ab. Zusätzlich werden
Lenkrad-/Panel-Ereignisse neben einem aktiven Gamepad, Mauszittern, feste Symbole
bei Mausbedienung, der vollständige Aus-Modus, gehaltene Tastaturtasten und die
genau einmal zugestellte erste Gamepad-Eingabe geprüft. Der UI-Durchlauf umfasst
Startauswahl, Einstellungen, Kampf/Dash, Pause/Verbindungsverlust, Level-ups,
Itemtruhen, alte Upgrade-Kapseln, Shop/Käufe, Verzaubern und Fusion. Modalgrenzen,
Fokus nach Neuaufbauten und rechtes Stickscrollen werden separat geprüft.
`controller_prompt_layout` prüft außerdem Kontext, Ausrichtung, Abstand und
Überlappungsfreiheit der Aktionsleiste für beide Symbolfamilien in Desktop-,
Hoch- und Querformaten sowie den Wechsel zurück zur Maus.

`tools/preview_controller.gd` erzeugt native Aufnahmen beider Symbolfamilien
bei 1280×720 und 320×568 unter `.godot/controller-preview/`. Der Preview verwendet
eigene Spielstand-, Einstellungs- und Fortschrittspfade. Für einen vollständig
isolierten Start auch `APPDATA` auf einen Ordner unter `.godot/` setzen.

Geprüfte native Ansichten: [Xbox / Desktop](screenshots/controller/setup_xbox_1280x720.png),
[PlayStation / Hochformat](screenshots/controller/setup_ps_320x568.png),
[Shop / Desktop](screenshots/controller/shop_ps_1280x720.png),
[Shop / Hochformat](screenshots/controller/shop_ps_320x568.png),
[Verzaubern](screenshots/controller/enchant_xbox_1280x720.png),
[Verzaubern / Hochformat](screenshots/controller/enchant_ps_320x568.png) und
[Fusion / Hochformat](screenshots/controller/fusion_xbox_320x568.png).

Die Verzauberungsübersicht zeigt den Abschluss-Hinweis ausschließlich für X/Quadrat und
nutzt den bisherigen Footer-Platz für den Inhalt:
[PlayStation / Desktop](screenshots/controller/enchant_overview_ps_1280x720.png),
[Xbox / Hochformat](screenshots/controller/enchant_overview_xbox_320x568.png).

Die vier Modusoptionen sind nativ geprüft:
[Desktop](screenshots/controller/settings_modes_xbox_1280x720.png) und
[Hochformat](screenshots/controller/settings_modes_ps_320x568.png).
Auf schmalen Ansichten steht die Auswahl unter ihrer Beschriftung, damit alle
Einstellungen innerhalb der Bildschirmbreite bleiben.

[Schalterfokus mit geparktem Mauszeiger](screenshots/controller/settings_focus_xbox_1280x720.png):
ein vollständiger Fokusrahmen mit Innenabstand; die andere, unter der Maus
liegende Einstellung erhält keinen zweiten Rahmen.

[Pausenansicht mit durchgehendem Controller-Panel](screenshots/controller/pause_dentipedia_ps_1280x720.png):
Der Hintergrund reicht bis zu beiden Bildschirmkanten, während die Hinweise
ihren seitlichen Innenabstand behalten.

Ein Test mit physisch angeschlossenen Xbox-/PlayStation-Controllern und die
Geräteerkennung in Browsern bleiben eigene praktische Abnahmen. Ein bestandener
Test mit synthetischen Ereignissen bestätigt das Routing, jedoch keine
bestimmte Treiber- oder Browserkombination.
