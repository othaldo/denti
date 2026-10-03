# Waffen-Evolutionen

Sechs Spezialwaffen ergänzen die 18 normalen Waffen. Sie entstehen ausschließlich durch freiwilliges Fusionieren in der Zahnklinik. Die Rezepte sind zunächst geheim: Erst mit allen erforderlichen Mk-IV-Waffen und Items erscheint beim Anklicken einer beteiligten Waffe die Fusionsoption samt Ergebnis und Effekt. Es gibt keine Hinweise auf fehlende Zutaten, keine Vorschau bei niedrigerer Stufe und keinen Eintrag im normalen Shopangebot.

Unter **Esc → Dentipedia → Waffen** stehen die Spezialwaffen am Ende der Liste. Vor der ersten erfolgreichen Fusion erscheint nur eine schwarze Silhouette ohne Namen, Werte oder Rezept. Danach ist der Eintrag mit Erklärung und Zutaten dauerhaft freigeschaltet. Die Entdeckung steht in `progression.cfg`, unabhängig vom aktuellen Run und von einem späteren Verkauf. Bereits gespeicherte Spezialwaffen werden beim Fortsetzen ebenfalls als entdeckt eingetragen. Suche und Tooltips verraten keine gesperrten Inhalte.

Evolutionen haben kein Limit pro Run oder Spezialwaffentyp. Solange Voraussetzungen und Wurzelplätze passen, sind weitere Entwicklungen möglich. Items bleiben erhalten, beteiligte Waffen werden verbraucht. Investierte Münzen gehen vollständig in den Verkaufswert der Spezialwaffe über. Sie belegt die in ihrer Ressource angegebenen Wurzeln. Jede Seltenheit einer benötigten Itemfamilie erfüllt die Voraussetzung.

## Entwicklungsreferenz – enthält Rezepte

Diese Tabelle ist für Entwicklung und Tests bestimmt, nicht für ein Rezeptbuch im Spiel.

| Ergebnis | Voraussetzungen | Wurzeln | Mechanik |
| --- | --- | ---: | --- |
| Gewitterdusche | Wasserflosser IV, Ketten-Familie, Spülventil | 1 | Treffer erzeugen bis zu vier leitende Pfützen für 4 s. Entladungen machen Gegner nass und verbinden nahe Ziele. |
| Schicksalsfaden | Zahnseidenpeitsche IV, Blutungs-Familie, Blutungsuhr | 1 | Bis zu drei Fäden verbinden Gegner. 60 px Spielerbewegung oder gedehnte Fäden lösen Schnittschaden entlang des Fadens und Blutung aus. |
| Wurzelkanalbrecher | Turbo-Bohrer IV, Bisskraft-Familie | 1 | Jeder vierte Treffer auf dasselbe Ziel erzeugt einen 360 px langen Bohrdurchbruch. Zielwechsel halbiert die Ladung. |
| Heiligenschein | Kronenwerfer IV, Rückflug-Familie | 2 | Kronen kreisen 0,85 s am Einschlagspunkt, treffen nahe Gegner und kehren zu Denti zurück. |
| Dreifaltigkeitsbürste | Zauberbürste IV und Fluorid-Sprüher IV | 2 | Drei Pastegeschosse markieren Gegner. Weitere Treffer detonieren die Markierung in einem 100-px-Umkreis. |
| Zahn der Offenbarung | UV-Lampe IV und Schmelzspiegel IV | 2 | 0,45 s sichtbare Aufladung; breiter Lichtstrahl. Kritische Salven erzeugen zwei zusätzliche Strahlen mit ±20° Winkel. |

Die Werte sind eine erste spielbare Balance. Itemeffekte bleiben erhalten; Sekundärschaden startet keine rekursiven Waffen-Procs. Pfützen, Fäden, Treffer-Cooldowns und sichtbare Linien sind begrenzt. Boss- und Elite-Schutzmechaniken bleiben wirksam. Der normale Waffen-DPS-Wert schätzt den Grundangriff; zusätzliche Evolutionseffekte sind darin nicht vollständig eingerechnet.

## Speicherung und Technik

- Rezepte: `data/evolutions/*.tres`, Typ `WeaponEvolutionRecipe`.
- Spezialwaffen: `data/weapons/*.tres`, normale `WeaponData` mit `evolution_kind` und Effektparametern.
- `WeaponLoadout` prüft Voraussetzungen und ersetzt die beteiligten Instanzen atomar.
- `WeaponEvolutionEffects` hält Pfützen, Fäden, Markierungen, Durchbruch-Ladung und Licht-Aufladung.
- Der Heiligenschein nutzt die Orbit-/Rückflugphase von `WeaponProjectile`.
- `RunSnapshot` speichert mehrere entwickelte Waffen, aktive Evolutionseffekte und Spielerprojektile inklusive Orbitphase und bereits getroffener Gegner.

Die neuen Sprites liegen im transparenten Atlas [weapon_evolutions.png](../assets/weapons/weapon_evolutions.png). Sie wurden mit dem eingebauten Imagegen-Tool anhand der vorhandenen bemalten Waffen erstellt. [Prompts und Assetdetails](../assets/weapons/weapon_evolutions_prompt.md). Individuelle Atlasregionen und Griff-/Spitzenanker liegen bei der jeweiligen Waffe.

## Prüfung

`tests/weapon_evolutions.gd` prüft alle sechs Rezepte, Zutaten verschiedener Seltenheiten, verborgene unvollständige Rezepte, Mk-III-Ausschluss, beide Seiten einer Doppelfusion, Wurzeln, Items, Verkaufswert, wiederholte und mehrere gleichzeitige Evolutionen, Shop-Button, Bildschirmgrößen, alle sechs Kampfmechaniken und Fortsetzen aktiver Effekte. Mit `-- --capture` erzeugt der Test Vorschauen unter `.godot/evolution-preview/`.
