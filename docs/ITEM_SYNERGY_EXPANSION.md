# Item-Erweiterung: Synergie-Items (Bauplan)

Stand 23.11.2026. **Status: umgesetzt und mit gemalten Grafiken versehen.** Dieser Plan ist so geschrieben, dass Claude
oder Codex jederzeit übernehmen kann. Erledigte Schritte werden unten abgehakt.

## Ziel

Seit den letzten Items sind neue Mechaniken dazugekommen, für die es kein Item gibt:
Gefolge (Kräuterzahn-Pflanzen, Nekrodent-Zähne), platzierte Felder (Eiswände,
Spülspur, Giftfelder, Pfützen), der Dash als Klassenkern, Element-Reaktionen und
einsammelbare Heil-Drops. Die 14 Items verbinden jeweils mindestens zwei
bestehende Systeme (Vorbild: Brotatos Ingenieur- und Farmer-Builds). Werte sind
Startschätzungen für Spieltests.

Konventionen wie bei allen Items: `ShopOfferData` in `data/items/<id>.tres`,
Eintrag in `ItemCatalog.ALL`, Wirkung über `effect_kind`/`effect_value`
(`ItemInventory.power(&"<kind>")` summiert über Kopien), Werte-Nachteile über
`stat_changes`. Texte ohne Pixelwerte (relativ: „in der Nähe“, „kurz“).

## Die 14 Items

| # | id | Name | Stufe | Preis | max | effect_kind = Wert | stat_changes | Tags |
| --- | --- | --- | --- | ---: | ---: | --- | --- | --- |
| A1 | `flower_pot` | Blumentopf | 2 | 9 | 6 | `placed_duration` = 0.15 | Bewegung −3 | area, summon |
| A2 | `fertilizer` | Dünger | 2 | 9 | 6 | `summon_power` = 0.12 | – | summon, ranged |
| A3 | `root_net` | Wurzelnetz | 4 | 22 | 1 | `summon_proximity` = 0.03 | – | summon |
| A4 | `pocket_bed` | Taschenbeet | 3 | 13 | 4 | `wild_sprout` = 1 | – | ranged, summon |
| A5 | `floss_trap` | Zahnseidenfalle | 2 | 9 | 6 | `dash_trap` = 14 | – | area, mobility |
| B1 | `spring_coil` | Sprungfeder | 3 | 12 | 2 | `dash_charge` = 1 | Schmelz −10 | mobility |
| B2 | `echo_crown` | Nachhall-Krone | 3 | 13 | 1 | `dash_volley` = 1 | – | mobility, melee, ranged |
| B3 | `slide_wax` | Rutschwachs | 2 | 8 | 3 | `dash_damage` = 0.3 | – | mobility, sugar |
| C1 | `catalyst` | Katalysator | 3 | 13 | 3 | `reaction_damage` = 0.4 | – | fire, ice, poison, water |
| C2 | `thermos` | Thermoskanne | 3 | 12 | 3 | `thermal_shock` = 1 | – | fire, ice, area |
| C3 | `storm_cloud` | Gewitterwolke | 2 | 9 | 3 | `shock_wet` = 1.5 | – | chain, water |
| D1 | `mint_bed` | Minzbeet | 2 | 9 | 4 | `mint_drops` = 1 | – | heal, economy |
| D2 | `spicy_paste` | Scharfe Zahnpasta | 3 | 13 | 3 | `mint_burst` = 1 | – | heal, area, defense |
| D3 | `compost` | Kompost | 2 | 8 | 3 | `summon_mint` = 0.15 | – | summon, heal |

### Effekte im Detail (Spielertext und Regel)

- **A1 Blumentopf** – „Platzierte Pflanzen, Eiswände, Giftfelder, Spülspur und Pfützen
  halten 15 % länger. −3 % Bewegung.“ Faktor `1 + power(placed_duration)` auf:
  `HerbSkills.lifetime`, `FrostSkills.wall_seconds`, `ClassDashCut.field_duration`,
  `RinserSkills.segment_seconds`, Pfützendauer (`ItemInventory.create_puddle`).
- **A2 Dünger** – „Gefolge (Pflanzen, untote Zähne) verursacht 12 % mehr Schaden und
  hält 25 % mehr aus.“ Schaden: Salbeischüsse (`HerbSkills._shoot`) und Bisse
  (`NecrodentSkills._bite`) × `1 + p`; Ausdauer: `plant_health` und
  `tooth_max_health` × `1 + 2·p`.
- **A3 Wurzelnetz** – „Jedes Gefolgsmitglied in deiner Nähe gibt 3 % Waffenschaden,
  höchstens 30 %.“ Neuer Bonus in `ItemInventory.modify_damage`: Anzahl Pflanzen
  (ausgewachsen) und stehender Zähne im Umkreis um Denti × 3 %, Deckel 30 %.
- **A4 Taschenbeet** – „Alle 10 Kills wächst für kurze Zeit ein wilder Salbeitrieb bei
  dir, der mit deinem Fernschaden schießt. Jede Kopie: zwei Kills weniger.“ Neues
  System `scripts/systems/wild_sprouts.gd` (Node unter `Items`): Kills zählen, Trieb
  6 s, schießt alle 0,8 s auf den Gegner nächst an Denti in mittlerer Reichweite,
  Schaden `scale_damage(8 + 1.0 × Fernschaden)`, Bild Zelle 0 aus
  `herb_druid_plants.png`. Kills pro Trieb `max(4, 12 - 2 × Kopien)`. Höchstens 6 Triebe.
- **A5 Zahnseidenfalle** – „Jeder Dash legt eine Falle, die beim ersten Gegner in der
  Nähe explodiert.“ Am Dash-Start eine Falle (max. 3 je Kopie, 8 s); Explosion
  `scale_damage(effect)` im Umkreis, Zahnseiden-Optik. Hook `player.dash.started`.
- **B1 Sprungfeder** – „+1 Dash-Ladung. −10 Schmelz.“ `PlayerStats.stamina_bonus()`
  um `power(dash_charge) × dash_config().cost` erhöhen.
- **B2 Nachhall-Krone** – „Am Ende eines Dashes greifen alle Waffen sofort an,
  höchstens alle 4 s.“ Hook Dash-Ende (`Player` → `dash_origin`/`on_dash_ended`),
  `WeaponInstance.force_attack(0.0)` für alle Waffen.
- **B3 Rutschwachs** – „Kurz nach einem Dash verursachen Waffen 30 % mehr Schaden.“
  0,5 s Fenster ab Dash-Ende, Bonus in `modify_damage`.
- **C1 Katalysator** – „Element-Reaktionen (Frost, Dampf, Giftstichflamme)
  verursachen 40 % mehr Schaden.“ In `ElementReactions.after_hit` den Schaden ×
  `1 + power(reaction_damage)`.
- **C2 Thermoskanne** – „Feuer auf einem gekühlten Gegner löst einen Thermoschock aus,
  der Gegner in der Nähe trifft.“ In `WeaponEnchantmentEffects.after_hit`: Feuerpaket
  auf ein vorher gekühltes Ziel → Flächenschaden 50 % des Feuerpakets je Kopie,
  gemeinsame Abklingzeit 0,3 s.
- **C3 Gewitterwolke** – „Elektro-Treffer machen Gegner kurz nass.“ Elektro-Affix-
  Treffer → `apply_wet(1.5 × Kopien)`. Verbindet Spültechniker, Leitlack, Kupferkrone.
- **D1 Minzbeet** – „Eliten und jeder 25. Kill lassen ein Minzblatt fallen, das heilt.
  Jede Kopie: fünf Kills weniger.“ Neue Beute-Art `&"mint"` (Heilt 4, Magnet wie
  Münzen, keine XP). Kills pro Blatt `max(10, 30 - 5 × Kopien)`.
- **D2 Scharfe Zahnpasta** – „Eingesammelte Minzblätter explodieren um dich; der
  Schaden wächst mit deinem Schmelz.“ Pickup `mint` → Fläche,
  `scale_damage(10 + 0.1 × max_health) × Kopien`.
- **D3 Kompost** – „Verwelkte Pflanzen und gefallene Zähne lassen manchmal ein
  Minzblatt fallen.“ 15 % je Kopie in `HerbSkills._wilt` und beim Umfallen eines
  Nekrodent-Zahns.

### Neue Beute-Art „Minzblatt“

- `Loot.kind == &"mint"`, `game._spawn_loot(at, &"mint", 4)` – Wert = Heilung.
- Einsammeln: `player.stats.heal(amount)`, löst `on_loot_collected` aus (Zahnfee feuert,
  Glückspfennig nicht, da keine Münze).
- Sprite: `assets/loot/mint_leaf.png` (siehe Bildauftrag).
- Spielstand: Beute wird schon generisch gespeichert; Art `mint` zulassen.

## Icons

Der Atlas `assets/items/item_icons_synergy.png` enthält 7 Spalten × 2 Zeilen in
der Reihenfolge A1 … D3. `DentiUIIcons.item()` bildet die `icon_index`-Werte
120–133 auf jeweils eine Zelle ab. Bildauftrag:
[item_icons_synergy.prompt.md](../assets/items/item_icons_synergy.prompt.md).

## Tests

Neuer Test `tests/synergy_items.gd`: je Item ein Wirkungsnachweis (Dauer-Faktor,
Gefolge-Schaden, Nähebonus mit Deckel, wilder Trieb nach Kills, Falle explodiert,
Dash-Ladung, Salve mit Abklingzeit, Dash-Fenster, Reaktionsbonus, Thermoschock,
Nässe durch Elektro, Minzblatt-Drop/Heilung/Explosion/Kompost), Speichern/Laden
mit Minzblatt-Beute, alle Items im Katalog mit gültigem Icon.

## Fortschritt

- [x] Bauplan (dieses Dokument) und Bildauftrag
- [x] Item-Daten (`data/items/*.tres`), Katalog, Icon-Zuordnung 120–133
- [x] `scripts/systems/synergy_items.gd` (Node `Synergies` unter dem Spiel, in `game.gd`
      angelegt): Taschenbeet, Zahnseidenfalle, Nachhall-Krone, Rutschwachs, Minzblätter,
      Wurzelnetz
- [x] Passive Faktoren: Blumentopf (Kräuterzahn, Frostwächter, Giftschneise,
      Spülspur, Pfützen), Dünger (Pflanzen, Nekrodent-Zähne), Katalysator
      (`ElementReactions`), Thermoskanne und Gewitterwolke
      (`WeaponEnchantmentEffects.after_hit`), Sprungfeder (`PlayerStats.extra_dash_charges`)
- [x] Minzblatt-Beute (`kind = &"mint"`), Textur, Laden/Speichern,
      Dash-Ende-Signal `Player.dash_finished`
- [x] Test `tests/synergy_items.gd`
- [x] `docs/items.md`, README, Roadmap
- [x] volle Suite (192/192)
- [x] Gemalte Icons und Minzblatt-Sprite. Alle Motive bei Spielgröße geprüft.
