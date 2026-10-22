# Gemeinsame Belohnungsansicht

Stand: **22.10.2026**. Zweites Umsetzungspaket aus der
[UI-Bestandsaufnahme](UI_VIEW_AUDIT.md), auf Grundlage der [Menübühne](MENU_UI.md).

**Nachkorrektur zur Seltenheit:** Karten, Zielwaffen und Ersatzoptionen verwenden
jetzt sichtbare Farbkanten und getönte Flächen. Die älteren Bilder unten zeigen
noch den ersten neutraleren Stand; aktuelle Aufnahmen und die Prüfung aller
Seltenheitsanzeigen stehen unter [Seltenheit auf einen Blick](RARITY_UI.md).

## Im Spiel umgesetzt

- **Aufstiege:** vier direkte Auswahlkarten mit gemaltem Attributmotiv,
  Attributname, Seltenheit und großem Bonuswert. Auf breiten Bühnen stehen die
  Werte auf gemeinsamen Zeilen; schmale Fenster erhalten kompakte Reihen.
  Level, Münzen und Neuwürfeln bleiben im festen Fußbereich erreichbar.
- **Relikte:** drei Auswahlkarten mit ihren vorhandenen Bildern und vollständigen
  Effekten. Es gibt keine zusätzliche Auswahlbestätigung oder Bedienungsabsätze.
- **Itemfund:** eine größere Karte mit Bild, Effekt einschließlich Nachteilen,
  Stapellimit und „Behalten“. „Zerlegen“ mit Münzwert sitzt als ruhige Alternative
  im festen Fußbereich. Die Desktopfassung nutzt ein größeres Motiv als die
  schmale Handyfassung.
- **Upgrade-Kapseln:** Waffenraster mit unabhängigem Auswahlrahmen und Häkchen,
  darunter einmal die aktive Waffe mit Mk-Stufe und Effektplätzen. Die drei
  Angebote zeigen Effekt, Vergleich und konkrete Aktion. Bei vollen Plätzen
  lässt sich ein vorhandener Effekt zum Ersetzen markieren. Verstärken,
  Seltenheitsfortschritt, zusätzliche Plätze, Mk-Aufstieg und goldene Kapseln
  verwenden denselben Aufbau. Sperrgründe bleiben am betroffenen Angebot.
- **Gemeinsamer Rahmen:** offene pflaumenfarbene Bühne, cremefarbene Schrift,
  zurückhaltende Kartenflächen und gezieltes Gold. Vorhandene Bilder behalten
  ihr Seitenverhältnis. Tastaturfokus und ausgewählte Zielwaffe sind getrennte
  Zustände. Auf kleinen Fenstern scrollt der Inhalt in einem Bereich; Neuwürfeln
  bzw. Zerlegen bleiben außerhalb dieses Bereichs erreichbar.
- **Fortschritt:** mehrere Entscheidungen zeigen oben rechts einen gemeinsamen
  Zähler, etwa `2 / 5`. Ein einzelner Fund benötigt keinen Zähler. Neuwürfeln
  zählt nicht als erledigte Belohnung; drei Reliktangebote zählen gemeinsam als
  eine Entscheidung.

## Ablauf und Speicherung

`PostWaveRewards` bleibt die autoritative Belohnungsqueue. Aktiver Kampf wird
weiter nicht durch Aufstiege oder Funde unterbrochen. Erst nach dem Einsammeln
der verbliebenen Beute folgen Aufstiege, Kapseln und gegebenenfalls Relikt;
anschließend öffnet der Shop. Storydialoge zählen nicht als Belohnungsauswahl.

Die gespeicherten Felder `choices_resolved` und `choices_total` erhalten den
gemeinsamen Zähler beim Fortsetzen. Alte Saves ohne diese Felder beginnen den
Zähler anhand ihrer noch offenen Entscheidungen. Zielwaffe und Ersatzwahl der
Kapsel bleiben über die bestehenden Felder erhalten. Auswahl und Effekte laufen
weiter über die vorhandenen Signale und Datenmodelle.

## Bausteine

- `scripts/ui/reward_stage.gd`: Kopf, Fortschritt, Scrollbereich, fester Fuß,
  sichere Bildschirmgrenzen und lokaler Skalierungsausgleich.
- `scripts/ui/reward_choices.gd`: Anordnung von Aufstiegs-, Relikt- und Itemkarten.
- `scripts/ui/reward_card.gd`: eigenständige Belohnungskarte; der Shop verwendet
  weiterhin seine bisherigen Karten.
- `scripts/ui/choice_panel.gd`: Auswahl und Signale; die ältere Ergebnisansicht
  bleibt bis zu ihrem eigenen Umbau getrennt erhalten.
- `scripts/ui/weapon_chest_panel.gd`: Zielwaffe, Ersatzwahl und Kapselangebote
  innerhalb derselben Belohnungsbühne.

## Native Prüfung

Direkt mit Godot 4.7.2 gerendert: **320×568, 360×640, 568×320, 720×1280,
1280×720 und 1920×1080**, einschließlich Projekt-Stretch und lokaler
Menükorrektur. Die kleinen Fenster simulieren die mobile Projektbasis; ein
Test auf einem echten Telefon bleibt zusätzlich sinnvoll. Geprüft wurden
lange Effekte, volle Effektplätze, Ersatzwahl, goldene Kapseln und die unteren
Scrollenden.

| Zustand | Desktop | Kleines Fenster |
| --- | --- | --- |
| Aufstieg | [1280×720](screenshots/reward_stage/levelup_1280x720.png) | [320×568](screenshots/reward_stage/levelup_320x568.png) |
| Kurzes Querformat | — | [568×320](screenshots/reward_stage/levelup_568x320.png) |
| Relikte | [1280×720](screenshots/reward_stage/relics_1280x720.png) | [320×568](screenshots/reward_stage/relics_320x568.png), [Scrollende](screenshots/reward_stage/relics_bottom_320x568.png) |
| Itemfund | [1280×720](screenshots/reward_stage/item_1280x720.png) | [320×568](screenshots/reward_stage/item_320x568.png) |
| Kapsel | [1280×720](screenshots/reward_stage/capsule_1280x720.png) | [320×568](screenshots/reward_stage/capsule_320x568.png), [Scrollende](screenshots/reward_stage/capsule_bottom_320x568.png) |
| Volle Plätze / Ersatz | [1280×720](screenshots/reward_stage/capsule_full_1280x720.png) | [360×640](screenshots/reward_stage/capsule_replace_360x640.png) |
| Goldene Kapsel | — | [320×568](screenshots/reward_stage/capsule_golden_320x568.png) |
| Weitere Formate | [1920×1080](screenshots/reward_stage/levelup_1920x1080.png) | [720×1280](screenshots/reward_stage/levelup_720x1280.png) |

Reproduktion: `godot --path . --script res://tools/preview_rewards.gd`.
Das Werkzeug isoliert Save, Einstellungen, Fortschritt und Berichte unter
`.godot/reward_preview/`. Dort bleiben auch die übrigen temporären Aufnahmen.

## Automatisierte Prüfung

**137 unterschiedliche Tests erfolgreich geprüft**, einschließlich der
gezielten Wiederholungen nach den letzten Auswahl- und Fortsetzenkorrekturen.
`tests/reward_stage.gd` prüft
physische Bildschirmmaße unter Projekt-Stretch, mindestens 48 Pixel große
Auswahlziele, Karten- und Textgrenzen, gemeinsame Wertzeilen, erreichbare
Scrollenden und feste Aktionen. `tests/reward_choice_progress.gd` prüft den
gemischten Zähler einschließlich Save/Resume, alten Saves und später
hinzugefügten Belohnungen. Bestehende Auswahl-, Reroll-, Kapsel-, Relikt- und
Fortsetzen-Tests decken die angebundene Spiellogik ab.

## Nächster Schritt

Die eigene Run-Ergebnisansicht. Danach folgen Shop/Build und die Leseseiten
als getrennte, nativ zu prüfende Pakete.
