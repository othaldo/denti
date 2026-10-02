# Items und Builds

Die Zahnklinik bietet **88 Items**: 16 Familien mit je vier Seltenheiten, 16 ergänzende Spezialitems und acht einmalige Mythics. Alle bisherigen 32 Items behalten ihre IDs, Effekte und Icons; 56 neue Items ergänzen den Pool.

**Common / Gewöhnlich**, **Uncommon / Ungewöhnlich**, **Rare / Selten** und **Legendary / Legendär** bieten verschiedene Kombinationen aus Bonus, Synergie und Nachteil. Seltenere Varianten sind eigene Items: Sie ersetzen vorhandene Exemplare nicht und fusionieren nicht. Das **Familienlimit gilt über alle vier Seltenheiten zusammen**; unterschiedliche Familien und Spezialitems ergänzen sich weiterhin. Bereits gespeicherte Builds behalten ihren Besitz, auch oberhalb eines neuen Familienlimits; dann sind weitere Käufe dieser Familie gesperrt. Die bisher unbegrenzte Metallkrone teilt jetzt das Rüstungs-Familienlimit von sechs.

**Mythic / Mythisch** ist eine neue, pink markierte Itemstufe. Jedes Mythic ist höchstens einmal pro Run erhältlich und gewährt genau einen positiven Statbonus ohne Nachteil oder zusätzlichen Proc. Die Stufe kann ab Welle 12 in Itemangeboten und Kisten erscheinen: `min((Welle - 11) × 0,00035 × max(1 + Glück/100, 0), 0,01)`, vorher 0. Das sind auf Welle 20 ohne Glück 0,315 % je Itemwurf, maximal 1 %. Waffen und Level-ups bleiben auf Stufe I–IV. Ein erschöpfter seltener Pool fällt auf verfügbare niedrigere Stufen zurück; besessene Mythics werden nicht erneut angeboten.

Ein Kauf gewährt den Effekt sofort. Alle Preise unten sind **Basispreise vor der Welleninflation**. Shopangebote haben vier Plätze; „Merken“ bindet Angebot und Preis kostenlos über Rerolls und Wellen. Details: [Economy](ECONOMY_BALANCE.md). Itemangebote werden zu 28 % aus passenden Build-Tags gewählt, wenn solche Items in der gewürfelten Stufe vorhanden sind. Das ändert die Seltenheitschance nicht.

Bisskraft und Item-Prozentboni werden addiert; Folgeeffekte skalieren einen bereits berechneten Treffer nicht erneut. Proc-Abklingzeiten und vorhandene Obergrenzen bleiben bestehen. Details: [Schaden und Verteidigung](DAMAGE_DEFENSE_BALANCE.md). Die Werte dieser Erweiterung sind ein Ausgangspunkt für Playtests, keine gemessene finale Balance.

Die [Designnotizen mit Brotato-Recherche](ITEM_RARITY_EXPANSION.md) erklären Auswahl und Limits. Die [Attributübersicht](ATTRIBUTES.md) definiert die einheitlichen Namen: Härte ist Rüstung, Schmelz sind maximale HP. Die Tabellen geben die Ressourcentexte wieder; im Spiel werden deren ältere Bezeichnungen zentral aufgelöst. [Alle 56 neuen Icons in Kartengröße](screenshots/item_families_icons_48px.png).

## Schmelz / HP

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Schmelzsplitter | +12 Leben, -2 % Bewegung. | 5 |
| Uncommon | Porzellanpolster | +24 Leben, +1 Regeneration, -3 % Angriffstempo. | 9 |
| Rare | Keramikschale | +35 Leben, -5 % Schaden. Bei erlittenem Schaden: 16 Basis-Splitterschaden im Umkreis. | 12 |
| Legendary | Herzkeramik | +45 Leben, -5 % Bewegung. Bei Schaden: 24 Splitterschaden im Umkreis. | 22 |

## Härte / Rüstung

Gemeinsames Familienlimit: **6**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Metallkrone | +3 Härte, -8 % Bewegung. Karamell bleibt gefährlich. | 4 |
| Uncommon | Titankrone | +4 Härte, -4 % Angriffstempo. | 9 |
| Rare | Panzerkeramik | +5 Härte, +12 Leben, -6 % Bewegung. | 14 |
| Legendary | Bollwerkkrone | +6 Härte, -8 % Schaden. Schildblock: 12 Splitterschaden im Umkreis. | 22 |

## Bisskraft / Bossjagd

Gemeinsames Familienlimit: **2**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Bissschraube | +5 % Schaden, -5 Leben. | 5 |
| Uncommon | Titanstift | +8 % Schaden, +8 % gegen Bosse, -1 Regeneration. | 9 |
| Rare | Wurzelanker | +10 % Schaden, +16 % gegen Bosse, -4 % Bewegung. | 14 |
| Legendary | Implantat | +12 % Schaden, -6 % Angriffstempo. +25 % gegen Bosse. | 20 |

## Putzeifer / Spritzer

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Mundspülung | +10 % Angriffstempo, -4 % Bewegung. Fern-Projektile: 25 % Spritzschaden (gesamt max. 80 %). | 4 |
| Uncommon | Druckspülung | +14 % Angriffstempo, -8 Leben. Fern-Projektile: 28 % Spritzschaden. | 9 |
| Rare | Turbospülung | +18 % Angriffstempo, -2 Härte. Fern-Projektile: 32 % Spritzschaden. | 14 |
| Legendary | Orkanspülung | +22 % Angriffstempo, -8 % Schaden. Fern-Projektile: 40 % Spritzschaden. | 22 |

## Glanz / Krit

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Glanzpuder | +4 % Krit, -5 Leben. Krits: Blitz mit 15 % Trefferschaden. | 5 |
| Uncommon | Polierpaste | +8 % Krit, -1 Härte. Krits: Flächenblitz mit 35 % Trefferschaden (gesamt max. 80 %). | 6 |
| Rare | Diamantpaste | +10 % Krit, -5 % Angriffstempo. Krits: Blitz mit 45 % Trefferschaden. | 14 |
| Legendary | Sternpolitur | +12 % Krit, -2 Härte. Krits: Blitz mit 55 % Trefferschaden. | 22 |

## Speichel / Regeneration

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Speicheltropfen | +1 Regeneration, -3 % Schaden. Alle 8 normalen Kills: +1 Leben. | 5 |
| Uncommon | Speichelquelle | +2 Regeneration, -3 % Bewegung. Alle 8 Kills +3 Leben. | 6 |
| Rare | Speichelbrunnen | +4 Regeneration, -10 Leben. Alle 8 normalen Kills: +4 Leben. | 14 |
| Legendary | Speicheloase | +6 Regeneration, -6 % Angriffstempo. Alle 8 normalen Kills: +6 Leben. | 22 |

## Bewegung / Beutemagnet

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Minz-Essenz | +5 % Bewegung, -5 % Angriffstempo. +55 Beutereichweite. | 4 |
| Uncommon | Minzsohlen | +7 % Bewegung, -1 Härte. +65 Beutereichweite. | 9 |
| Rare | Mentholwirbel | +9 % Bewegung, -12 Leben. +80 Beutereichweite. | 14 |
| Legendary | Minzkomet | +12 % Bewegung, -6 % Schaden. +100 Beutereichweite. | 22 |

## Zahnglück / XP

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Milchzahn-Talisman | +8 Glück, -2 % Schaden. +4 % gesammelte XP. | 5 |
| Uncommon | Glücks-Molar | +20 Glück, +3 % Krit. +10 % gesammelte XP. | 8 |
| Rare | Kleeblattkrone | +28 Glück, -2 Härte. +14 % gesammelte XP. | 14 |
| Legendary | Schicksalsmolar | +36 Glück, -6 % Angriffstempo. +18 % gesammelte XP. | 22 |

## Schnitt / Blutung

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Zahnseide-Spule | +2 Nahschaden. Schnitt-Blutung verursacht +3 Schaden/s. | 5 |
| Uncommon | Rasierseide | +3 Nahschaden, -1 Härte. Schnitt-Blutung: +4 Schaden/s. | 9 |
| Rare | Rubinseide | +4 Nahschaden, -5 % Angriffstempo. Schnitt-Blutung: +5 Schaden/s. | 14 |
| Legendary | Henkerseide | +6 Nahschaden, -15 Leben. Schnitt-Blutung: +7 Schaden/s. | 22 |

## Wasser / Licht / Ketten

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Funkenclip | Wasser/Licht springt mit 20 % Trefferschaden auf ein nahes Ziel. -2 % Schaden. | 5 |
| Uncommon | Funkensonde | Wasser- und Lichttreffer springen mit 40 % Schaden über. | 8 |
| Rare | Gewittersonde | +2 Fernschaden, -2 Härte. Wasser/Licht springt mit 50 % Schaden über. | 14 |
| Legendary | Blitzableiter | +3 Fernschaden, -6 % Angriffstempo. Wasser/Licht springt mit 60 % Schaden über. | 22 |

## Schilde / Schutz

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Fluoridgel | +25 Leben und Heilung. Zu Wellenbeginn +1 Schild. | 5 |
| Uncommon | Fluoridmantel | +28 Leben, -3 % Bewegung. Wellenbeginn: +1 Schild. | 9 |
| Rare | Fluoridpanzer | +30 Leben, -1 Härte. Wellenbeginn: +2 Schilde (gesamt max. 5). | 14 |
| Legendary | Fluoridbastion | +35 Leben, -6 % Angriffstempo. Wellenbeginn: +2 Schilde (gesamt max. 5). | 22 |

## Münzen / Economy

Gemeinsames Familienlimit: **3**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Kupferfüllung | +3 Glück, -5 Leben. +5 % Münzen beim Sammeln. | 5 |
| Uncommon | Silberfüllung | +1 Härte, -3 % Bewegung. +10 % Münzen beim Sammeln. | 9 |
| Rare | Goldfüllung | +5 % Schaden, +1 Rüstung. +15 % Münzen beim Sammeln. | 12 |
| Legendary | Platinfüllung | +12 Glück, -6 % Schaden. +22 % Münzen beim Sammeln. | 22 |

## Projektile / Rücklauf

Gemeinsames Familienlimit: **2**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Rückholfeder | +1 Fernschaden, -3 % Schaden. Direkte Projektile kehren mit 15 % Schaden zurück. | 5 |
| Uncommon | Rücklaufspindel | +2 Fernschaden, -4 % Angriffstempo. Direkte Projektile kehren mit 25 % Schaden zurück. | 9 |
| Rare | Rücklaufbohrer | Direkte Projektile kehren mit 35 % Schaden zurück. -5 % Schaden. | 13 |
| Legendary | Bumerangbohrer | +3 Fernschaden, -2 Härte. Direkte Projektile kehren mit 50 % Schaden zurück (gesamt max. 70 %). | 22 |

## Fläche / Zahnblitz

Gemeinsames Familienlimit: **2**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Blitzampulle | +2 % Krit, -1 Regeneration. Alle 10 normalen Kills: Zahnblitz mit 10 Basisschaden. | 5 |
| Uncommon | Zahnblitzflasche | +3 % Krit, -3 % Bewegung. Alle 10 normalen Kills: Zahnblitz mit 18 Basisschaden. | 9 |
| Rare | Heiliges Elixier | Alle 10 Kills: ein Zahnblitz mit 25 Flächenschaden. | 14 |
| Legendary | Heilige Nova | +5 % Krit, -15 Leben. Alle 10 normalen Kills: Zahnblitz mit 36 Basisschaden. | 22 |

## Zucker / Bewegungsschaden

Gemeinsames Familienlimit: **2**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Zuckerwürfel | Beim tatsächlichen Laufen: +8 % Waffenschaden. -6 Leben. | 5 |
| Uncommon | Kariesbonbon | Beim tatsächlichen Laufen: +14 % Waffenschaden. -1 Härte, -1 Regeneration. | 9 |
| Rare | Verbotener Lolli | Laufen: +20 % Waffenschaden. -15 Leben, -2 Härte. | 13 |
| Legendary | Sündenlolli | Beim tatsächlichen Laufen: +28 % Waffenschaden (gesamt max. 40 %). -20 Leben, -3 Härte. | 22 |

## XP / Heilung

Gemeinsames Familienlimit: **2**.

| Seltenheit | Item | Vollständiger Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Feenquittung | Jeder gesammelte XP-Punkt heilt 0,15 Leben. -3 % Schaden. | 5 |
| Uncommon | Zahnfee-Pakt | XP heilt 0,35 Leben je Punkt. -8 maximales Leben. | 9 |
| Rare | Feenvertrag | Jeder gesammelte XP-Punkt heilt 0,45 Leben. -2 Härte. | 14 |
| Legendary | Feenbund | Jeder gesammelte XP-Punkt heilt 0,6 Leben. -15 Leben, -4 % Angriffstempo. | 22 |

## Spezialitems

Diese 16 bisherigen Items ergänzen die Familien mit eigenen Regeln. Ihre Stapellimits gelten je Item.

| Item | Seltenheit | Effekt | Max. | Basispreis |
| --- | --- | --- | ---: | ---: |
| Karies-Kopfgeld | Common | Alle 12 Kills +1 Münze. Jeder Belag hat seinen Preis. | 2 | 6 |
| Ansteckende Zahnseide | Uncommon | Kill auf blutendem Ziel: Blutung springt über. -5 % Schaden. | 2 | 8 |
| Blutungsuhr | Uncommon | Blutung hält +1 s und stapelt einmal mehr. -6 % Schaden. | 2 | 9 |
| Goldextraktor | Uncommon | +1 Münze bei Drops mit mindestens 2 Basis-Münzen (Zucker und Eliten). -3 % Bewegung. | 2 | 10 |
| Goldsonde | Uncommon | 20 % Chance auf doppelten Münz-Drop. +1 Prozentpunkt je 10 Glück (max. +10). -5 % Schaden. | 2 | 10 |
| Leitlack | Uncommon | Nass hält länger: +18 % Wasser/Licht, längere Ketten. -3 % Bewegung. | 2 | 9 |
| Speichelkelch | Uncommon | 50 % Überheilung ansparen (gesamt max. 100 %): je 20 Punkte +1 Schild (max. 5). -12 Leben. | 2 | 10 |
| Splitterkrone | Uncommon | Schildblock: 18 Splitterschaden im Umkreis. -3 % Bewegung. | 2 | 10 |
| Spülventil | Uncommon | Wassertreffer: 2 s Pfütze, nass und 4 Basisschaden je 0,5 s. -3 % Bewegung. | 2 | 9 |
| Zahnfee-Pfand | Uncommon | +10 Glück, +50 % Kisten-Zerlegewert. -10 Leben. | 2 | 9 |
| Zinszahn | Uncommon | Wellenende: 8 % Zins auf Erspartes, höchstens 6 Münzen pro Exemplar. -8 Leben. | 2 | 9 |
| Amalgamkern | Rare | Je Härte +2,5 % Waffenschaden (gesamt max. 60 %). -5 % Bewegung. | 2 | 13 |
| Glanzprisma | Rare | Krits: Strahl zu einem nahen Ziel mit 30 % Trefferschaden, bei Licht 45 %. -1 Härte. | 2 | 13 |
| Skalpellwachs | Rare | +35 % Schaden gegen blutende Gegner. Schnitt trifft tiefer. | 2 | 12 |
| Zuckerschock | Rare | Alle 12 Kills: 4 s +30 % Angriffstempo (max. +50 %), dann 3 s -25 %. -10 Leben. | 2 | 13 |
| Göttliches Siegel | Legendary | Zu jeder Welle +2 Schild. Einmalig. Alle huldigen Denti. | 1 | 22 |

## Mythics

Je Item einmal pro Run. Keine negativen Stats, keine zusätzlichen Nebeneffekte.

| Item | Reiner Bonus | Basispreis |
| --- | --- | ---: |
| Biss der Zahnheit | +20 % Schaden. Einmalig pro Run. Ohne Nachteil. | 38 |
| Ewiger Putzeifer | +30 % Angriffstempo. Einmalig pro Run. Ohne Nachteil. | 38 |
| Herz des Urmolars | +60 Leben. Einmalig pro Run. Ohne Nachteil. | 38 |
| Makelloser Glanz | +18 % Krit. Einmalig pro Run. Ohne Nachteil. | 38 |
| Quelle des Lebens | +8 Regeneration. Einmalig pro Run. Ohne Nachteil. | 38 |
| Schritte der Zahnfee | +18 % Bewegung. Einmalig pro Run. Ohne Nachteil. | 38 |
| Unvergänglicher Schmelz | +8 Härte. Einmalig pro Run. Ohne Nachteil. | 38 |
| Zahnfee-Stern | +50 Glück. Einmalig pro Run. Ohne Nachteil. | 38 |

## Effekte und Beispielbuilds

Peitsche und Kratzer verursachen auch ohne Items Blutung; der Wasserflosser macht Ziele auch ohne Leitlack nass. Blutung stapelt sich normalerweise auf Gegnern bis zu dreimal und läuft nach 2,5 Sekunden ohne erneuten Schnitt aus; die Blutungsuhr erhöht Dauer und Stapelgrenze. Wet läuft nach 2,5 Sekunden ab, mit Leitlack nach 3 Sekunden. Schilde fangen jeweils einen Treffer ab und sind insgesamt auf fünf Ladungen begrenzt. Kettenblitze, Blutungsübertragung, Spritzer, kritische Blitze, Lichtstrahlen und Keramiksplitter haben kurze interne Abklingzeiten, damit dichte Gegnergruppen das Spiel nicht mit Effekten überfluten. Laufende Effekte, Schildladungen, Stapel und Fortschritte zu Kill-Boni werden mit dem Spielstand gespeichert. Bei Kisten steht der normale Zerlegewert schon beim Drop fest; das Zahnfee-Pfand erhöht den angezeigten und ausgezahlten Wert bei der Entscheidung.

Beispiel-Builds:

- **Schnittpraxis:** Zahnseide-Peitsche oder Plaque-Schaber, Zahnseide-Spule, Skalpellwachs, Ansteckende Zahnseide und Blutungsuhr. Blutende Ziele fördern Flächendruck beim Kill.
- **Wasserwerk:** Wasserflosser oder Mundspülungs-Mörser mit Funkensonde, Leitlack, Spülventil und Mundspülung. Pfützen halten Ziele nass; Ketten erreichen weitere Gegner.
- **Unzerstörbarer Molar:** Metallkrone, Fluoridgel, Göttliches Siegel, Amalgamkern, Keramikschale und Splitterkrone. Geblockte Treffer geben Flächendruck zurück.
- **Zahnfee-Ökonomie:** Glücks-Molar, Goldsonde, Goldextraktor, Goldfüllung, Karies-Kopfgeld, Zahnfee-Pfand und Zinszahn. Wertvolle Drops, Zerlegen und gesparte Münzen zahlen sich aus, aber Denti wird langsamer, schwächer und fragiler. Goldfüllung wirkt beim Einsammeln auf den bereits erhöhten Dropwert.
- **Zuckerrausch:** Verbotener Lolli, Zuckerschock und Heil- oder Schilditems. Tempo nach Killserien kostet Leben und führt anschließend ins Zuckertief.
