# Attribute und Anzeigenamen

`DentiAttributes.Type` in [denti_attributes.gd](../scripts/player/denti_attributes.gd) ist die gemeinsame Attributdefinition. Sie ordnet jedem Attribut den bestehenden Ressourcen-/Speicherschlüssel, Anzeigenamen, Bedeutung, Einheit und Stat-Icon zu. Shop, Level-up-Karten, Buildübersicht und Debugmenü beziehen diese Angaben von dort. Waffen verwenden dieselben Namen für ihre Attributskalierung und die kritische Trefferchance.

| Enum | Anzeigename | Bedeutung | Einheit |
| --- | --- | --- | --- |
| DAMAGE | Bisskraft | Allgemeiner Waffenschadensbonus | Prozent |
| ARMOR | Härte | Rüstung, verringert erlittenen Schaden | Punkte; Anzeige zusätzlich mit Schadensminderung |
| MAX_HEALTH | Schmelz | Maximale Lebenspunkte | HP |
| ATTACK_SPEED | Putzeifer | Angriffstempo | Prozent |
| CRIT_CHANCE | Glanz | Kritische Trefferchance | Prozent |
| REGEN | Speichel | Regeneration | Punkte; Anzeige zusätzlich mit HP/s |
| MOVEMENT | Bewegung | Bewegungstempo | Prozent |
| LUCK | Zahnglück | Glück bei Beute und Seltenheiten | Punkte |
| MELEE_DAMAGE | Nahschaden | Bonus auf Nahkampf-Waffenskalierung | Punkte |
| RANGED_DAMAGE | Fernschaden | Bonus auf Fernkampf-Waffenskalierung | Punkte |
| DODGE | Zahnflutsch (Arbeitsname) | Ausweichchance | Prozent; für nächsten Schritt reserviert |

**Härte und Schmelz sind verschiedene Attribute.** Leben/HP bei Heilung und Treffer-/Basisschaden einer Waffe bleiben eigene Größen. Beispielsweise erhöht „+12 Schmelz (HP)“ das Lebensmaximum; „nach einem Kill +1 Leben“ heilt. Die frühere Waffen-Schadensart „Schmelz“ wird als **Schmelzbruch** angezeigt, damit sie nicht wie ein HP-Attribut aussieht. Ihr interner Wert bleibt aus Kompatibilitätsgründen erhalten.

Item-Ressourcen und ältere gespeicherte Texte können weiterhin die früheren Wörter enthalten. `effect_text()` / `resolve_text()` vereinheitlichen sie an der Anzeigegrenze. Die zugrunde liegenden Effekte und gespeicherten Schlüssel werden dadurch nicht geändert. Neue Attribute werden zuerst hier definiert; UI-Code erhält keine eigenen Namenslisten. `ACTIVE` enthält nur die bereits spielbaren Attribute. Dodge hat noch keine Trefferlogik, Items, Level-ups oder Icon und wird deshalb nicht angezeigt.

Die Shopübersicht hört auf `PlayerStats.changed`, auch während der pausierten Zwischenphase. Kauf, direkte Statänderung und Wiederaufnahme eines Spielstands zeigen so aktuelle permanente Werte. Bedingte Itemeffekte, etwa Zusatzschaden beim Laufen, sind weiterhin im Itemtext beschrieben und sind keine dauerhaften Grundstatboni.

`tests/attribute_presentation.gd` prüft die Enum-Zuordnung, Einheiten, alten Textvarianten, Heilung gegenüber maximalen HP, tatsächliche Käufe, Statänderungen im pausierten Shop, das Fortsetzen und den Wechsel der Statquelle.

Visuell geprüft: [Shop direkt nach dem Kauf](screenshots/attribute_shop_after_purchase.png), [Level-up auf dem Handy](screenshots/attribute_levelup_mobile.png) und [Startwaffen im Querformat](screenshots/attribute_starters_landscape.png). Erzeugen mit `tools/preview_attributes.gd`; der Vorschau-Spielstand ist vom normalen Spielstand getrennt.
