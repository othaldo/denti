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
| Listen und Details scrollen | Rechter Stick, auf/ab | Rechter Stick, auf/ab |

B öffnet im Kampf keine Pause. Pflichtbelohnungen werden weiterhin ausdrücklich
ausgewählt. Beim Verzaubern schließt B zuerst die Effektauswahl; auf der
Waffenübersicht entspricht B „Fertig“ und übernimmt den vorhandenen Entwurf.
Eine Fusion wird mit B abgebrochen und erst über „Fusionieren“ bestätigt.

## Tastensymbole

`Einstellungen → Tastensymbole` speichert Automatisch, Xbox oder PlayStation.
Automatisch berücksichtigt Namen und Hersteller des zuletzt verwendeten
Controllers. Unbekannte Geräte verwenden Xbox-Symbole. Die manuelle Wahl hilft
auch, wenn ein Treiber oder Browser einen PlayStation-Controller als Xbox-Gerät
meldet. Maus, Tastatur und Touch blenden die Gamepad-Symbole wieder aus.
Eine kleine Stickdrift ändert den Eingabemodus nicht.

Die SVGs unter `assets/ui/controller/` sind eigene, skalierbare Zeichnungen der
Tasten. Sie ersetzen keine Item- oder Waffenbilder. Die Menüs zeigen eine
gemeinsame Aktionsleiste unten: Symbol vor Aktionsname, gemeinsame Mittellinie,
gleiche Abstände. A bezieht sich auf das fokussierte Element; B, X und Y werden
nur mit den im aktuellen Kontext verfügbaren Aktionen angezeigt. Modale
Details zeigen keine Kürzel der dahinterliegenden Ansicht. Karten und Buttons
behalten ihren Fokusrahmen und ihre Bilder, ohne Tastenaufkleber an den Ecken.
Das Menü reserviert 48 logische Pixel für die Leiste. Bei Maus, Tastatur oder
Touch fällt dieser Bereich weg. Im Kampf steht RB/R1 mittig unter Wurzelkraft.

Die Anordnung folgt den offiziellen Beispielen in Microsofts
[XAG 112: UI navigation](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112)
und [XAG 113: UI focus handling](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/113):
Sea of Thieves gruppiert Auswählen, Zurück und weitere Aktionen am unteren Rand;
The Outer Worlds trennt den Auswahlrahmen vom Zurück-Hinweis, und das
Forza-Dialogbeispiel verwendet einen Auswahlhinweis außerhalb der Optionen.
Die Umsetzung für Denti übernimmt daraus eine feste Leiste mit Glyph/Text-Paaren
und einen separaten, gut sichtbaren Fokusrahmen.

## Technischer Schnitt

- `GameInput` erkennt Eingabegerät und Symbolfamilie, filtert doppelte gehaltene
  Tasten und meldet den Verlust des aktiven Controllers.
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
gehaltenes Bestätigen, Symbolwechsel und Persistenz ab. Der UI-Durchlauf umfasst
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
[Verzaubern](screenshots/controller/enchant_xbox_1280x720.png) und
[Fusion / Hochformat](screenshots/controller/fusion_xbox_320x568.png).

Ein Test mit physisch angeschlossenen Xbox-/PlayStation-Controllern und die
Geräteerkennung in Browsern bleiben eigene praktische Abnahmen. Ein bestandener
Test mit synthetischen Ereignissen bestätigt das Routing, jedoch keine
bestimmte Treiber- oder Browserkombination.
