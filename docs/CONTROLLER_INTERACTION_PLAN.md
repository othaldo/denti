# Einheitliche Menübedienung

Stand: 01.11.2026. **Umgesetzt; Shop nach Rückmeldung als gemeinsame Vergleichsansicht.**
Die bereits implementierte Fokusführung beim Verzaubern ist die Ausgangsbasis.

## Ausgangsbefund vor der Umsetzung

Mit simulierten Godot-Controllerereignissen bei 1280×720 und 320×568 geprüft:

- Ein Shop mit einer ausgerüsteten Waffe, ohne gesammelte Items und mit vier
  Angeboten hat 17 Fokusziele: eine Waffe, zwölf Statistikfelder, vier Angebote.
- Auf dem Desktop führt unten von jeder Angebotskarte in ein Statistikfeld.
  Im Hochformat führen seitliche Bewegungen aus der Angebotsliste in Statistiken.
- Nach Kauf von Angebot 4 springt der Fokus zu Angebot 1 statt zum nächsten
  räumlich passenden Angebot.
- B/Kreis und Menu/Options öffnen beide die Pause im Shop-Grundzustand.
- Menu/Options öffnet in Shop-Details und beim Verzaubern keine Pause.
- Details liegt in der Startauswahl auf Y/Dreieck, im Shop auf RB/R1 und beim
  Verzaubern auf RS/R3.
- LB/L1 öffnet im Shop Verzaubern; beim Verzaubern ist dieselbe Taste der
  Wechsel zur vorigen Waffe. Das Schulterpaar hat im Shop keine gemeinsame Rolle.
- RT/R2 startet im Shop die Welle, plant beim Verzaubern aber einen Aufstieg;
  X/Quadrat würfelt im Shop, bestätigt beim Verzaubern und beendet dessen Ansicht.

Relevante Stellen: `scripts/ui/shop_panel.gd`, `scripts/ui/offer_card.gd`,
`scripts/ui/game_menu.gd`, `scripts/ui/controller_action_bar.gd` und
`scripts/ui/weapon_enchantment_panel.gd`.

## Priorität im Shop

Die Reihenfolge ist aus dem wiederkehrenden Spielablauf abgeleitet, nicht aus
gemessenen Nutzungszahlen:

1. Angebote vergleichen, kaufen, gegebenenfalls merken und neu würfeln.
2. Nächste Welle starten.
3. Bei Platzbedarf Waffen verwalten, fusionieren oder verkaufen.
4. Gegebenenfalls nach Käufen oder Fusionen erneut verzaubern.
5. Für einzelne Build-Entscheidungen Items, Relikte und Statistiken nachschlagen.

Verzaubern ist bereits Teil der automatischen Belohnungsfolge vor dem Shop.
Der erneute Zugang aus dem Shop ist deshalb eine Verwaltungsaktion, kein
notwendiger Umweg für jeden Kauf.

## Gemeinsame Rollen in allen Menüs

| Eingabe | Rolle |
| --- | --- |
| A / Kreuz | Primäraktion des fokussierten Eintrags: kaufen, öffnen, Rang erhöhen oder aufsteigen. |
| B / Kreis | Genau eine Ebene zurück oder die aktuelle Auswahl abbrechen; öffnet keine Pause und bestätigt keinen Entwurf. |
| Menu / Options | Im aktiven Run Pause öffnen beziehungsweise schließen, auch über Details und Belohnungsansichten. |
| RS / R3 | Details zum markierten Eintrag, überall dieselbe Taste. |
| LB/RB / L1/R1 | Shop: LB zum sichtbaren Build, RB zu den Angeboten. Verzaubern: vorige/nächste Waffe. |
| X / Quadrat | Neu würfeln, nur wo es diese Aktion gibt, mit sichtbaren Kosten. |
| Y / Dreieck | Reversible Kontextaktion: Angebot merken/freigeben oder geplante Änderung rückgängig. Nie verkaufen oder Belohnungen verwerfen. |
| RT / R2 | Expliziten Arbeitsschritt abschließen: weiter, Verzauberung anwenden, Fertig oder Welle starten. Kein Aufstieg. |
| Linker Stick / Steuerkreuz | Innerhalb des aktuellen Arbeitsbereichs navigieren. |
| Rechter Stick | Den aktuellen Bereich beziehungsweise die offenen Details scrollen. |

Die Kernrollen sind fest; fehlende Aktionen lassen Tasten frei. Nicht jeder
Screen benötigt jeden Shortcut. Die Leiste nennt ausschließlich gültige
Aktionen des obersten Bereichs, ohne denselben Aktionsnamen mehrfach zu zeigen.
Ein fokussierter regulärer Button bleibt mit A bedienbar; das ist keine
zusätzliche globale Bestätigungstaste wie bisher B neben X bei Fertig.

RT führt pro frischem Druck genau einen Schritt aus. Nach einem Ansichtswechsel
muss es erst losgelassen werden. Ungetroffene Level-up-/Truhenentscheidungen
werden damit weder vorausgewählt noch übersprungen. Verkauf und Fusion bleiben
bewusste Aktionen an ihren jeweiligen Einträgen beziehungsweise Bestätigungen.

## Shop-Fokus

- Eine gemeinsame Ansicht: **Angebote, aktuelle Waffen und Build-Infos bleiben sichtbar**.
  LB/L1 führt zur linken Build-Fokusgruppe, RB/R1 zurück zu den Angeboten.
  Es gibt keine drei Reiter; die Gruppierung betrifft nur die Fokusnavigation.
- Angebote ist der Einstieg. Der Stick bleibt im sichtbaren Angebotsraster;
  bei einer einspaltigen Ansicht wirkt nur oben/unten. Ränder sind Grenzen,
  keine unsichtbaren Übergänge zur linken Statistik.
- Jede Karte ist ein Fokusziel: A kauft, Y merkt, R3 zeigt Details. Kauf- und
  Pin-Buttons bleiben für Maus/Touch direkt benutzbar.
- Nach Kauf wird das nächste verfügbare Angebot in einer festgelegten,
  räumlich verständlichen Reihenfolge markiert. Merken und Würfeln behalten
  nach Möglichkeit denselben Platz. Sind alle Angebote verkauft, bleibt der
  Fokus im Angebotsbereich; Würfeln und Wellenstart sind weiterhin erreichbar.
- Im Waffenbereich öffnet A die gezielten Aktionen zur markierten Waffe:
  Fusionieren, Verzaubern und Verkaufen, soweit verfügbar. R3 öffnet ihre Details.
- Waffen, Items, Relikte und Werte sind in der Build-Fokusgruppe erreichbar.
  Sie bleiben zum Vergleichen sichtbar, verlängern aber nicht den Kaufweg.
- Geschlossene Details stellen den Ausgangseintrag wieder her. Hinter Modals
  wirken weder Kauf noch Würfeln, Bereichswechsel oder Wellenstart.

## Pause, Zurück und Verzauberungsentwürfe

Menu/Options wird zentral für den aktiven Run behandelt, statt in jedem Panel
einzeln. Die Pause liegt über der aktuellen Ansicht; Schließen stellt Ansicht,
Fokus und Entwurf wieder her. In den Pause-Einstellungen geht B zunächst zum
Pausenhauptmenü, Options schließt die gesamte Pause.

B darf ein geöffnetes Pausenmenü als Zurück-Aktion schließen, öffnet es aber
nie. Im Shop-Grundzustand ohne übergeordnete Spielansicht führt B keine Aktion aus.

Beim Verzaubern bleibt der erreichte Fokusgraph erhalten. Der Aufstieg ist mit
A an seiner regulären Zeile erreichbar; sein zusätzlicher RT-Shortcut entfällt.
X wird nicht länger für Bestätigen/Fertig verwendet, sondern bleibt Würfeln
vorbehalten. RT übernimmt den ausdrücklich angezeigten Abschluss des aktuellen
Schritts. B verlässt die Effektauswahl ohne Investition.

Ein Zurück aus der Verzauberungsübersicht braucht eine ausdrückliche Regel für
offene Entwürfe: ohne Änderungen direkt zur vorherigen Ansicht; bei Änderungen
eine Entscheidung zwischen Weiterbearbeiten, Verwerfen und Fertig. Weder B noch
Options bestätigen oder verwerfen stillschweigend Punkte-/Goldinvestitionen.
In diesem Entscheidungsdialog ersetzt RT keine der ausdrücklichen Antworten.

## Umsetzung und Abnahme

1. Gemeinsames Aktionsschema und zentrale Pause festlegen; alle Hinweise aus
   denselben semantischen Aktionen erzeugen wie die tatsächliche Eingabe.
2. Begrenzte Shop-Fokusgruppen mit stabiler Fokusgruppen-/Eintragsposition ergänzen.
3. Details vereinheitlichen, danach Workflow-Abschluss und Schulterbelegung
   einschließlich Startauswahl und Belohnungsansichten angleichen.
4. Prüfen: Kauf des letzten Angebots, alle Angebote verkauft, kein Gold,
   volle Wurzeln, leere Bereiche, gehaltene Trigger, Modalwechsel, Pause in jeder
   Run-Ansicht, Entwurf plus Zurück, Größenänderungen und beide Symbolfamilien.

## Primärquellen

- [Xbox Accessibility Guideline 112: UI navigation](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112)
  empfiehlt vorhersagbare Fokuswege und dieselben Interaktionsmechanismen
  über Menüs hinweg, beispielsweise A zum Auswählen und B für Zurück.
- [Xbox Accessibility Guideline 114: Context](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/114)
  nennt konsistente LB/RB-Navigation zwischen Menüreitern als Beispiel.
- [Steam Input: Getting Started for Developers](https://partner.steamgames.com/doc/features/steam_controller/getting_started_for_devs)
  beschreibt Aktionssätze für unterschiedliche Zustände wie Menü und Spiel.
  Das begründet die Kontexttrennung; die konkrete Tastenbelegung oben ist
  ein Vorschlag für Denti und keine Plattformvorgabe.
