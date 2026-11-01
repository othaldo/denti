# Controller-Steuerung

Die Menübedienung verwendet gemeinsame Tastenrollen. Angriffe bleiben
automatisch; im Kampf bewegt der linke Stick Denti und RB/R1 löst den Dash aus.

| Menüaktion | Xbox | PlayStation |
| --- | --- | --- |
| Fokus bewegen | Steuerkreuz / linker Stick | Steuerkreuz / linker Stick |
| Markierte Primäraktion ausführen | A | Kreuz |
| Eine Ebene zurück / Auswahl abbrechen | B | Kreis |
| Pause im Run öffnen/schließen | Menu | Options |
| Details zum markierten Eintrag | Rechten Stick drücken (RS) | R3 |
| Neu würfeln, wo verfügbar | X | Quadrat |
| Angebot merken/freigeben oder Entwurfsänderung rückgängig | Y | Dreieck |
| Shop: zum Build / zu Angeboten | LB / RB | L1 / R1 |
| Dentipedia: voriger / nächster Tab | LB / RB | L1 / R1 |
| Verzaubern: vorige / nächste Waffe | LB / RB | L1 / R1 |
| Arbeitsschritt abschließen: Weiter, Anwenden, Fertig, Welle starten | RT | R2 |
| Aktuellen Bereich oder Details scrollen | Rechter Stick | Rechter Stick |

## Tastatur und anklickbare PC-Aktionsleiste

Im automatischen Modus zeigt dieselbe Menüleiste auf dem PC Tastenkappen statt
Gamepad-Symbolen. Ihre Einträge sind mit der Maus anklickbar und behalten das
markierte Angebot beziehungsweise Bedienelement als Aktionsziel. Die Leiste
zeigt nur verfügbare Aktionen der obersten Ansicht; Details sperren die Ansicht
darunter. Controller-Eingaben stellen die gewählte Gamepad-Symbolfamilie wieder
her. Mobilgeräte, Touch-Web-Builds und mobile Layouts zeigen keine Tastaturleiste
und reservieren dafür keinen Platz. Aktive Kämpfe zeigen keine Menüleiste.

| Taste | Aktion |
| --- | --- |
| Enter | Markierte Primäraktion: wählen, kaufen, Rang erhöhen |
| Escape | Zurück oder schließen; an der Run-Basis Pause |
| R | Neu würfeln |
| F | Arbeitsschritt abschließen: Weiter, Verzaubern, Fertig, Welle starten |
| I | Details |
| P | Angebot merken/freigeben |
| Backspace | Verzauberungsänderung rückgängig |
| Q / E | Voriger/nächster Tab, Waffe oder Shopbereich |
| Pfeiltasten, Tab / Shift+Tab | Im aktuellen Menü navigieren |

Such- und Textfelder behalten ihre normale Texteingabe einschließlich Backspace;
die Leiste blendet dort die entsprechenden Kontextkürzel aus. Tastenwiederholung
kauft keine nächste Karte, würfelt nicht erneut und bestätigt keine Folgeansicht.
Escape wird einmal als Zurück oder Pause angezeigt, je nach aktuellem Kontext.

`desktop_menu_input` prüft echte Tastatur- und Mausklick-Ereignisse, Kauf und
Würfelkosten, Merken, Fokus, Verzauberungsentwürfe, Textfelder, native Popups,
Modalgrenzen, gehaltene Tasten sowie Gerätewechsel und fünf Fensterformate.
Native Ansichten: [Shop](screenshots/keyboard/shop_1280x720.png) und
[Verzaubern](screenshots/keyboard/enchant_1280x720.png),
[kleineres PC-Fenster](screenshots/keyboard/shop_1040x600.png) und
[Mobil ohne Tastaturleiste](screenshots/keyboard/shop_320x568.png).

## Gemeinsame Shopansicht

Angebote, Waffen, gesammelte Items und Stats bleiben gemeinsam sichtbar.
Es gibt keine drei Reiter und keinen Ansichtswechsel zum Vergleichen.
Der Controller startet in der Angebotsgruppe. Der Stick bleibt in ihrem Raster;
bei einer einspaltigen Darstellung bewegt er den Fokus nur oben/unten.
LB/L1 führt gezielt zum sichtbaren Build, RB/R1 zurück zu den Angeboten.
Beide Gruppen merken ihre Position. Auf kleinen Bildschirmen werden die
vorhandenen Inhalte gescrollt statt gegeneinander ausgetauscht.

Jede Angebotskarte ist ein Fokusziel: A/Kreuz kauft direkt, Y/Dreieck merkt
kostenlos oder gibt frei, RS/R3 zeigt optionale Details. Nach einem Kauf wird
das nächste verfügbare Angebot markiert, am Listenende das vorige. Merken und
Würfeln behalten nach Möglichkeit dieselbe Position. Sind alle Angebote verkauft,
bleibt ein Fokusziel in der Angebotsgruppe; Würfeln und Wellenstart bleiben
verfügbar. Fehlendes Gold, Stapellimits und volle Wurzeln sperren nur den Kauf.

A/Kreuz auf einer ausgerüsteten Waffe öffnet ihre gezielten Aktionen, darunter
Fusionieren, Verzaubern und Verkaufen. RS/R3 zeigt deren Informationen ohne
Verwaltungsaktionen. Verzaubern übernimmt das gewählte Waffenexemplar.
Verkaufen verlangt weiterhin eine ausdrückliche Bestätigung.
Items, Relikte und Statistiken sind über die Build-Fokusgruppe erreichbar.

Würfeln und Wellenstart liegen bei Controller-Bedienung in der Aktionsleiste;
die bisherigen zusätzlichen Shop-Buttons werden ausgeblendet. Maus-, Touch-
und Tastaturbedienung stellen die Bildschirm-Buttons wieder her. Enter kauft
das markierte Angebot, P merkt es und I öffnet Details. Eine fest gewählte
Symbolfamilie allein blendet die Buttons nicht aus.

## Verzaubern und Abschluss

Die Übersicht führt den Fokus vertikal über Aufsteigen und vier vollständige
Effektzeilen. Links/rechts verlässt diese Liste nicht. A/Kreuz erhöht den Rang,
öffnet einen freien Platz oder plant den markierten Aufstieg. Nach Mk V bleibt
die Aufstiegszeile markiert und bietet Mk VI und weitere Stufen an. Kosten und
Sperrgründe stehen am Eintrag. MAX, gesperrte Plätze und fehlende Ressourcen
bleiben für RS/R3-Details markierbar, erlauben aber keine Ausgabe.

Waffenwechsel hält die Zeilenposition; Verzaubern und Rückgängig stellen den
betroffenen Platz wieder her. In der Effektauswahl bleibt der Fokus im Raster;
Waffenwechsel und Aufstieg sind dort gesperrt. A/Kreuz wählt eine Vorschau,
RT/R2 wendet die ausdrücklich angezeigte Verzauberung an. In der Übersicht führt
RT/R2 Fertig aus. X/Quadrat ist ausschließlich Würfeln vorbehalten.

B/Kreis verlässt die Effektauswahl ohne Ausgabe. Aus der unveränderten Übersicht
kehrt es zurück und erhält die bankierten Punkte. Bei offenen Änderungen bietet
es Weiterbearbeiten, Verwerfen oder Fertig an. RT trifft diese Entscheidung
nicht automatisch. Verwerfen verliert weder Punkte noch Gold und ändert keine
bereits bestätigte Ausrüstung. Der Run-Koordinator führt danach zum Shop oder
zur nächsten noch offenen Belohnung.

RT/R2 muss zunächst losgelassen und dann deutlich gedrückt werden (über 0,8).
Ein Druck führt genau einen Schritt aus; gehaltenes RT bestätigt keine folgende
Ansicht, startet keine weitere Welle und beantwortet keine Pflichtbelohnung.

## Pause und Unteransichten

Menu/Options öffnet oder schließt die Pause zentral im aktiven Run, auch über
Shopdetails, Verzaubern, Belohnungen und nativen Informationsfenstern.
Beim Schließen kommen Ansicht, Fokus und offener Entwurf zurück. Native Popups
werden während der Pause ausgesetzt; ein Dropdown innerhalb der Pause wird beim
Verlassen der Pause geschlossen. B/Kreis geht eine Ebene zurück und öffnet
niemals die Pause. In Pause-Einstellungen kehrt B zum Pausenhauptmenü zurück,
Options verlässt die gesamte Pause. Escape behält die Desktop-Bedienung:
Details zuerst schließen, sonst im Shop Pause öffnen.

Modals sperren Kauf, Würfeln, Waffenwechsel und Abschluss der darunterliegenden
Ansicht. Beim Schließen wird der Ausgangseintrag wieder markiert. In der
Startauswahl zeigt RS/R3 Details und RT/R2 führt den freigegebenen Weiter-/Start-
Schritt aus. Level-ups und Truhen verlangen weiterhin eine ausdrückliche Wahl
mit A/Kreuz; RT wählt keine Belohnung automatisch aus.

## Prüfung der weiteren Ansichten

Die ergänzende Prüfung vom 01.11.2026 umfasst Hauptmenü, Startauswahl,
Einstellungen, Meisterschaften, Dentipedia, Pausen-Build, Fusion, Level-ups,
Item-/Reliktbelohnungen, alte Upgrade-Kapseln, Storydialoge, Kapitelreise und
Run-Abschluss. Die Änderungen schließen folgende Lücken:

| Ansicht | Korrigiertes Verhalten |
| --- | --- |
| Details und Entwurfsdialog unter Pause | B und Richtungen wirken ausschließlich auf die oberste Ansicht; darunterliegende Fenster bleiben offen. |
| Startauswahl | R3 beschreibt die fokussierte Waffe oder Schwierigkeit ohne Auswahländerung; Schließen stellt den Ausgangsfokus wieder her. |
| Meisterschaften und Dentipedia | R3 öffnet den markierten Eintrag. L1/LB und R1/RB wechseln Dentipedia-Tabs mit gemerkter Eintragsposition und festen Rändern. Suchtext bleibt erhalten. Im Hochformat führt B zur selben Dentipedia-Zeile zurück. |
| Mein Build | B aus Waffendetails kehrt zum Build und zum Waffenexemplar zurück. Die Build- und Itembereiche scrollen bei geringer Höhe mit dem Fokus, statt Aktionen außerhalb des Fensters zu platzieren. Items und Relikte bieten R3. |
| Fusion / Evolution | RT schließt die gültige Vorschau ab; B bricht ab. R3 erklärt Effekte. Doppelte und leere Platz-Buttons entfallen aus der Controller-Fokusfolge. |
| Level-up / Fund / Relikt / Upgrade-Kapsel | R3 zeigt Informationen, ohne die Belohnung zu wählen. RT und B überspringen keine Pflichtwahl. Würfeln nutzt X mit Kostenhinweis statt eines zusätzlichen Fokusziels. Behalten wird ausdrücklich benannt. |
| Storydialog / Kapitelreise | Pause hält Text, Sprachausgabe und Reisefortschritt an; Fortsetzen stellt die aktuelle Aktion wieder her. A bleibt Anzeigen / Weiter. |
| Run-Abschluss / Credits | B kehrt von den Credits zum Ergebnis zurück. Der Hinweis nennt Zurück einmal; ein beendeter Run bietet keine Pause an. |

Native Beispiele: [Waffendetails im Pausenmenü](screenshots/controller/pause_weapon_details_ps_320x568.png),
[Build im kurzen Querformat](screenshots/controller/pause_build_ps_568x320.png),
[Meisterschaften](screenshots/controller/mastery_details_ps_320x568.png),
[Dentipedia](screenshots/controller/dentipedia_entry_ps_320x568.png),
[Details einer Belohnung](screenshots/controller/levelup_details_ps_320x568.png),
[Fusion](screenshots/controller/fusion_xbox_320x568.png) und
[Credits nach dem Run](screenshots/controller/run_credits_ps_320x568.png).

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
  Ein Fokusbereich kann über `controller_focus_targets` und
  `controller_focus_neighbor` eine begrenzte Zielmenge und Richtungspolitik
  bereitstellen. `WeaponEnchantmentFocus` nutzt dies ausschließlich bei aktiver
  Controller-Bedienung; Desktop-Eingaben behalten den bestehenden Fokusgraphen.
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
`controller_enchantments` prüft die begrenzte Fokusfolge in drei Fensterformaten
und beiden Symbolfamilien: seitliche Stickbewegungen, Positionshaltung beim
Waffenwechsel, gesperrte/MAX-Zeilen, Aufstieg mit A bis Mk VI, Ressourcenpreise,
RS/R3-Details, Größenänderungen im Modal, die abgeschlossene Effektauswahl und
den Abschluss ohne ausgerüstete Waffen.
`controller_prompt_layout` prüft außerdem Kontext, Ausrichtung, Abstand und
Überlappungsfreiheit der Aktionsleiste für beide Symbolfamilien in Desktop-,
Hoch- und Querformaten sowie den Wechsel zurück zur Maus.
`controller_menu_schema` prüft die gemeinsame Shopansicht, getrennte Fokusgruppen,
Kaufnachfolger, globale Pause einschließlich nativer Popups, RT über Ansichtswechsel
und die ausdrückliche Entscheidung bei offenen Verzauberungsentwürfen.
`controller_view_consistency` prüft zusätzlich erreichbare Fokusgraphen und
R3-/Zurück-Übergänge der weiteren Ansichten bei 1280×720, 320×568 und 568×320
mit Xbox- und PlayStation-Symbolen. Enthalten sind volle Waffen, modale Pause,
Controller-Übernahme an Würfeln, Pflichtbelohnungen und eingefrorene Storyansichten.

`tools/preview_controller.gd` erzeugt native Aufnahmen beider Symbolfamilien
bei 1280×720, 320×568 und 568×320 unter `.godot/controller-preview/`. Der Preview verwendet
eigene Spielstand-, Einstellungs- und Fortschrittspfade. Für einen vollständig
isolierten Start auch `APPDATA` auf einen Ordner unter `.godot/` setzen.

Geprüfte native Ansichten: [Xbox / Desktop](screenshots/controller/setup_xbox_1280x720.png),
[PlayStation / Hochformat](screenshots/controller/setup_ps_320x568.png),
[Shop / Desktop](screenshots/controller/shop_ps_1280x720.png),
[Shop / Hochformat](screenshots/controller/shop_ps_320x568.png),
[Build-Fokus in derselben Ansicht](screenshots/controller/shop_build_ps_1280x720.png),
[Waffenaktionen / Hochformat](screenshots/controller/shop_weapon_actions_ps_320x568.png),
[Pause über Shopdetails](screenshots/controller/pause_shop_details_ps_1280x720.png),
[Verzaubern](screenshots/controller/enchant_xbox_1280x720.png),
[Verzaubern / Hochformat](screenshots/controller/enchant_ps_320x568.png) und
[Fusion / Hochformat](screenshots/controller/fusion_xbox_320x568.png).

Die Verzauberungsübersicht zeigt den Abschluss-Hinweis ausschließlich für RT/R2 und
nutzt den bisherigen Footer-Platz für den Inhalt:
[PlayStation / Desktop](screenshots/controller/enchant_overview_ps_1280x720.png),
[Xbox / Hochformat](screenshots/controller/enchant_overview_xbox_320x568.png).

Der Aufstieg ist als reguläre Zeile nativ geprüft:
[Mk V](screenshots/controller/enchant_ascension_ps_1280x720.png),
[nächste Stufe Mk VI](screenshots/controller/enchant_ascension_mk6_ps_1280x720.png),
[Sperrgrund im Hochformat](screenshots/controller/enchant_ascension_blocked_xbox_320x568.png).
Die [Entscheidung bei offenen Änderungen](screenshots/controller/enchant_exit_ps_320x568.png)
bleibt im Hochformat vollständig bedienbar.

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
