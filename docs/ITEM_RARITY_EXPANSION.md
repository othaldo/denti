# Itemfamilien und Mythics

## Umfang

Der Pool wächst von 32 auf 88 Items: 48 neue Varianten schließen die Lücken in 16 Familien; acht Mythics ergänzen reine, einmalige Statboni. Die [vollständige Liste](items.md) enthält alle 88 Items einschließlich Seltenheit, Stats, Nebenwirkung, Limits und Basispreis.

Die Familien sind HP, Rüstung, Schaden/Bossjagd, Angriffstempo, Crit, Regeneration, Bewegung/Magnet, Glück/XP, Schnitt/Blutung, Wasser/Licht/Ketten, Schilde, Münzen, Projektilrücklauf, Flächenschaden, Zucker und XP-Heilung. Die übrigen bisherigen Items bleiben Spezialisten: etwa Blutungsuhr, Spülventil, Amalgamkern, Zinszahn und Speichelkelch. Sie verbinden Familien miteinander. Nicht jeder Spezialproc wird künstlich viermal dupliziert.

Varianten sind bewusst verschiedene Gegenstände, keine zufällig verstärkten Kopien desselben Items. HP etwa beginnt mit Schmelzsplitter (+12 Leben, -2 % Bewegung), geht über Porzellanpolster (+24 Leben, +1 Regeneration, -3 % Tempo) und die bestehende Keramikschale (+35 Leben, -5 % Schaden, Vergeltung) zu Herzkeramik (+45 Leben, -5 % Bewegung, stärkere Vergeltung). Die höhere Seltenheit verändert damit die Buildentscheidung.

## Brotato-Recherche

Abgerufen am 2. Oktober 2026. Inspiration, keine direkte Übernahme der Zahlen:

- [Items im Brotato-Wiki](https://brotato.wiki.spellsandguns.com/Items): Die Tabelle zeigt Statkombinationen, Nachteile, Limits und Tags. HP-Items wie Acid, Alien Baby oder Alien Magic kaufen mehr Leben mit unterschiedlichen Kosten für den Build. Daraus stammt die Idee verschiedener HP-Varianten mit eigener Nebenwirkung.
- [Shop im Brotato-Wiki](https://brotato.wiki.spellsandguns.com/Shop): Welle und Glück steuern Seltenheit; Waffenbesitz beeinflusst passende Angebote, begrenzte Items verlassen bei erreichtem Limit den Pool. Denti behält seine bereits vorhandene Buildgewichtung und ergänzt verfügbare Varianten.

Die lückenlose Familienmatrix, die gemeinsamen Familienlimits und die fünfte Mythic-Stufe sind Denti-Designentscheidungen. Brotato begrenzt einzelne Items: [Unique und Limited](https://brotato.wiki.spellsandguns.com/Restricted_Items) bezeichnen einmaligen beziehungsweise begrenzten Besitz eines konkreten Items. Die HP-Items der [Itemtabelle](https://brotato.wiki.spellsandguns.com/Items) teilen kein allgemeines HP-Familienlimit. Unsere Limits verhindern, dass vier Varianten die bisherige erlaubte Stapelzahl vervierfachen; sie sind noch nicht durch Playtests validiert. Mythic bedeutet hier „einmal pro Run, genau ein Bonus, ohne Nachteil“, unabhängig von der Seltenheitsbezeichnung anderer Spiele.

## Balance und Spielstände

Familienlimits werden über alle Seltenheiten gemeinsam gezählt. Andernfalls würden die zusätzlichen Varianten bisherige Proc- und Statlimits vervierfachen. Metallkrone ist nun Teil der auf sechs Exemplare begrenzten Rüstungsfamilie. Alle anderen Familien verwenden das bisherige Limit ihres Ausgangsitems. Die 32 alten IDs, Statwerte, Effekte und Bilder bleiben erhalten; bestehende Spielstände wenden Boni beim Laden nicht erneut an. Alte Builds über einem Familienlimit werden erhalten, können die Familie aber nicht weiter kaufen.

Mythics starten ab Welle 12 und teilen die normalen Itemwürfe in Shop/Kisten. Die maximale Chance pro Itemwurf beträgt 1 %, einschließlich Glück. Die Chance auf einen Kistendrop und das gewöhnliche Kistenlimit pro Welle ändern sich nicht. Der Shop würfelt weiterhin zu 35 % eine Waffe (mit den bestehenden frühen Garantien); diese Würfe bringen keine Mythic-Waffen. Waffen und Level-ups bleiben bei vier Stufen. Schilde bleiben auf fünf, Rücklauf auf 70 %, Bewegungsschaden auf 40 % und bestehende Proc-Cooldowns bleiben aktiv.

Die neuen Zahlen sind Startwerte. Besonders Crit-/Flächenketten und die Versorgung mit HP-/Schildvarianten sollten im nächsten Playtest anhand der Telemetrie beobachtet werden. Diese Änderung behauptet keine empirisch validierte Endbalance.

## Shopfehler

Die Angebotssuche konnte nach einem Reroll leer enden, wenn in der gewürfelten/niedrigeren Stufe alle Items bereits ausgereizt oder angeboten waren und das volle Waffeninventar keine passende Fusion zuließ. Ein solcher Slot wurde als „Ausverkauft“ dargestellt, obwohl er neu gewürfelt war.

Die Suche verwendet jetzt als letzten Ersatz eine normale Waffe, die sich ansehen und merken lässt. Ihr Kauf bleibt gesperrt, bis der Spieler Wurzelplatz schafft. Bereits gekaufte Slots bleiben beim Fortsetzen korrekt ausverkauft und werden erst beim nächsten bezahlten Reroll aufgefüllt. Gemerkte Angebote behalten Preis und Gegenstand.

## Icons

56 eigenständige Motive wurden mit dem eingebauten Imagegen erzeugt: drei Atlanten mit je 16 Varianten und ein Atlas mit acht Mythics. Die bisherigen Atlanten dienen als Stilreferenz. Kein Originalbild wurde ersetzt. Die [48-px-Kontaktübersicht](screenshots/item_families_icons_48px.png) zeigt jede neue Zelle mit Name und Seltenheit.

Die finalen Spielatlanten heißen `assets/items/item_icons_families_1_packed.png` bis `_3_packed.png` sowie `item_icons_mythic_packed.png`. Rohbilder bleiben daneben erhalten. Das [Manifest](item_icon_manifest.json) enthält die Zuordnung und Motive; die vollständigen Prompts stehen unter `docs/art/item_families_prompt_*.txt`. Transparente Trennbereiche werden geprüft, Motive ohne Bemalung zugeschnitten und in gleichmäßig gepolsterte Zellen gesetzt. Atlas 3 erhielt vor dem Packen eine Imagegen-Korrektur für größere Abstände.

## Prüfung

`tests/item_families.gd` prüft Katalogvollständigkeit, sämtliche Seltenheiten je Familie, gemischte Familienlimits, echte Stats, Mythic-Einmaligkeit, gedeckelte Würfe, Shop-/Kistenfilter und Fortsetzen. `tests/shop_reroll_exhaustion.gd` prüft einen vollständig ausgeschöpften Build, Ersatzangebote, Reservierungen und Kauf nach Freimachen einer Wurzel. Bestehende Combat-/Reward-/Shop-/Save-Tests müssen weiterhin bestehen.

Verifiziert mit Godot 4.7.2: alle 54 automatisierten Testskripte bestanden. Die Erweiterungstests prüfen außerdem die 56 Atlaszellen, vorgemerkte Mythic-Kisten und den Erhalt alter Builds über dem Familienlimit. Die [HP-Shopansicht](screenshots/item_family_health_1280x720.png) und die [Mythic-Ansicht auf dem Handy](screenshots/item_family_mythic_360x640.png) wurden im tatsächlichen Spiel gerendert und visuell kontrolliert.
