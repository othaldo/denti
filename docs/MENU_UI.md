# Gemeinsame Menübühne

Stand: **22.10.2026**. Erstes Umsetzungspaket aus der
[UI-Bestandsaufnahme](UI_VIEW_AUDIT.md).

## Im Spiel umgesetzt

- **Hauptmenü:** offene Bühne mit bestehendem Logo und Denti-Motiv, einer
  goldenen Hauptaktion und ruhigen Nebenaktionen. Ein gültiger Run erhält
  „Fortsetzen“ mit Welle, Level und Schwierigkeit. Ohne Run ist „Neuer Run“ die
  Hauptaktion. Eine offene Vorbereitung lässt sich ebenfalls fortsetzen.
- **Pause:** derselbe Aufbau über dem abgedunkelten Spiel; Fortsetzen bleibt
  hervorgehoben. „Mein Build“ führt zu den vorhandenen Werten und Items, die
  jetzt direkt miteinander verbunden sind. Ihre inhaltliche Überarbeitung
  bleibt Bestandteil des späteren Shop-/Build-Pakets.
- **Einstellungen:** offene Gruppen für Audio, Darstellung und Bedienung.
  Drei getrennte Lautstärkeregler mit Werten, Goldschalter und eine kompakte
  Grafikauswahl. Änderungen wirken und speichern sofort. Auf breiten Bühnen
  zwei Spalten, auf schmalen eine Spalte mit einem gemeinsamen Scrollbereich.
  Der Rückweg bleibt oberhalb des scrollbaren Inhalts erreichbar.
- **Neuer Run bei vorhandenem Save:** der kurze Hinweis verwendet ebenfalls
  die neue Bühne. Vorbereiten löscht den alten Run nicht; erst bestätigter
  Start ersetzt ihn.
- **Größen und Fokus:** lokale Menüs kompensieren das Verkleinern des
  Spiel-Canvas. Hauptaktionen, Navigation, Regler und Schalter bleiben
  mindestens 48 Bildschirm-Pixel hoch. Schrift wird über MSDF scharf
  dargestellt. Tastaturfokus erscheint cremefarben; Maus-/Touchbedienung
  zeichnet diesen Fokusrahmen nicht. Zurück aus den Einstellungen stellt den
  Fokus am aufrufenden Button wieder her.

Kurzes Querformat ordnet die Hauptaktionen nebeneinander an. Längeres
Hochformat zeigt Denti zusätzlich über der Aktionsgruppe; auf kleinen Geräten
gibt das Motiv den benötigten Platz für die Bedienung frei. Der Start benötigt
keinen zusätzlichen Warte- oder Bestätigungsschritt.

## Bausteine

- `MenuLayout`: Größenkorrektur und sichere Bühnenfläche; auch von der
  bestehenden Run-Auswahl verwendet.
- `MenuStyle`: gemeinsame Schrift, Hintergrund und Aktions-/Fokusdarstellung;
  die Run-Auswahl verwendet dieselbe Grundlage.
- `MenuStage`: Seitenkopf, fester Rückweg, scrollbarer Inhaltsbereich und
  dezente Versionszeile.
- `MenuHome`: responsive Hauptmenü-/Pausenkomposition und benannte Aktionen.
- `MenuSettings`: Einstellungsformular und Weitergabe an die vorhandenen
  GameSession-Setter.

GameMenu koordiniert die Navigation. Die Run-Vorbereitung, Testcode-Freigabe,
Story-Einstiege und Save-Migration verwenden weiterhin ihre vorhandenen
Schnittstellen. Beim Schließen der Pause bestimmt `RunFlow.requires_pause()`,
ob etwa Shop oder Belohnung weiterhin pausiert bleiben.

## Native Prüfung

Aufnahmen direkt mit Godot 4.7.2, einschließlich Projekt-Stretch und lokaler
Menükorrektur: **320×568, 360×640, 568×320, 720×1280, 1280×720 und 1920×1080**.
Die kleinen Fenster simulieren die mobile Projektbasis; ein echter
Hardwaretest auf dem Telefon steht zusätzlich aus.

| Zustand | Desktop | Mobil / kurzes Querformat |
| --- | --- | --- |
| Ohne Run | [1280×720](screenshots/menu_stage/home_1280x720.png) | [568×320](screenshots/menu_stage/home_568x320.png) |
| Fortsetzen | [1280×720](screenshots/menu_stage/continue_1280x720.png) | [320×568](screenshots/menu_stage/continue_320x568.png) |
| Pause | [1280×720](screenshots/menu_stage/pause_1280x720.png) | [320×568](screenshots/menu_stage/pause_320x568.png) |
| Einstellungen | [1280×720](screenshots/menu_stage/settings_1280x720.png) | [320×568](screenshots/menu_stage/settings_320x568.png) |
| Unteres Scrollende | — | [320×568](screenshots/menu_stage/settings_bottom_320x568.png) |
| Grafik-Popup | [1280×720](screenshots/menu_stage/settings_popup_1280x720.png) | [320×568](screenshots/menu_stage/settings_popup_320x568.png) |
| Run vorbereiten | — | [320×568](screenshots/menu_stage/confirm_320x568.png) |
| Weitere Formate | [1920×1080](screenshots/menu_stage/home_1920x1080.png) | [720×1280](screenshots/menu_stage/home_720x1280.png) |

Die Grafik-Auswahlliste übernimmt den lokalen Skalierungsfaktor auch für ihr
Popup: etwa 18 Bildschirm-Pixel Schrift und 50 Pixel hohe Zeilen auf dem
320×568-Fenster. Öffnen per vollständiger Maus-Eingabesequenz lässt den
Grafikmodus unverändert. Das untere Setting ist bis zum Scrollende erreichbar.

Reproduktion: `godot --path . --script res://tools/preview_menu_stage.gd`.
Das Werkzeug isoliert Save, Einstellungen und Fortschritt unter
`.godot/menu_preview/` und schreibt die nativen Aufnahmen ebenfalls dort.

## Automatisierte Prüfung

**135/135 Tests bestanden.** Nach dem letzten Aufräumen und dem zusätzlichen
Hochformatlayout wurden die betroffenen Menü-, Einstellungs-, Save-/Start-,
Testcode-, Dentipedia- und Wurzelkapazitätstests nochmals erfolgreich geprüft.

`tests/menu_stage.gd` prüft echte Bildschirmmaße unter Projekt-Stretch,
mindestens 48 Pixel hohe Ziele, Bildschirmgrenzen, fehlende unnötige
Home-Scrollbalken, erreichbares Einstellungsende, Run-Kontext,
Tastatur-/Pointerfokus, Escape-Rückkehr und Pausebesitz während des Shops.
Die bestehenden Menütests verwenden benannte Aktionen bzw. Inhalte statt
fester Kindindizes der alten Buttonstapel.

## Nächster Schritt

Die [Belohnungsbühne für Aufstiege, Relikte und Kapseln](REWARD_UI.md) ist
inzwischen umgesetzt. Als Nächstes folgt die eigene Run-Ergebnisansicht.
Shop/Build und Leseseiten folgen als getrennte Pakete.
