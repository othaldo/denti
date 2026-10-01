# Gold, Shoppreise und vier Auswahlkarten

Umgesetzt am 2026-10-01 auf Grundlage der [Untersuchung](ECONOMY_RESEARCH.md).

## Gold

Gold wird unabhängig von XP gewürfelt. Die bisherigen XP-Werte und deren Drop-Abschwächung bleiben bestehen. Plaque/Bakterien/Säurespucker haben 40/45/50 % Basis-Münzchance mit Wert 1; Zucker 65 % mit Wert 2. Eliten geben weiterhin garantiert 4 Münzen. Luck verändert normale Gold-Drops nicht.

Der Gold-Faktor beträgt in Welle 1–4 100 %. Danach gilt `max(1 - 0,015 * Welle, 0,70)`, unabhängig davon, ob es eine Bosswelle ist. Die normale Schwierigkeitsgrad-Anpassung wird zusätzlich angewendet; die finale Chance liegt zwischen 0 und 100 %. Boss-Kills selbst geben weiterhin Relikt-Fortschritt und keinen neuen Gold-Bonus.

Ein zusätzlicher Startbonus auf die Münzchance beträgt +60 % in Welle 1, +40 % in Welle 2, +20 % in Welle 3 und 0 % ab Welle 4. Beispiel Plaque: 64/56/48/40 % Münzchance in den ersten vier Wellen. Diese Anpassung folgt aus der Kampfmessung: Eine einzelne Startwaffe besiegt deutlich weniger Gegner als ein kompletter Spawnplan enthält.

## Shop

`Preis = floor(Basispreis * (1 + 0,1 * Welle) + Welle)`.

Die Welle ist die gerade abgeschlossene Welle, der erste Shop verwendet also 1. Für Waffen wird zunächst ihr Stufenpreis mit den bestehenden Faktoren 1/1,65/2,4/3,3 ermittelt und gerundet; darauf folgt genau einmal die Welleninflation. Katalog-Ressourcen und Itemeffekte werden nicht verändert, um Preise zu berechnen.

| Shop nach Welle | Zauberbürste I | Zauberbürste IV | Item mit Basispreis 5 |
| --- | ---: | ---: | ---: |
| 1 | 10 | 34 | 6 |
| 5 | 18 | 50 | 12 |
| 10 | 28 | 70 | 20 |
| 19 | 45 | 106 | 33 |

Stufe IV wird hier nur als Preisvergleich gezeigt, nicht als Angebot früher Shops.

Jeder Shop hat vier Angebote. „Merken“ reserviert ein Angebot kostenlos, auch wenn aktuell Münzen oder freie Hände fehlen. Es bleibt beim Reroll und im nächsten Shop im selben Platz und behält seinen Preis. „Gemerkt“ gibt es wieder frei. Ein Kauf entfernt die Reservierung. Vier gemerkte Angebote sperren bezahlte Rerolls. Rerolls behalten die bisherige Kostenfolge 2/3/4/... und beginnen pro Shop erneut bei 2.

Save/Resume erhält alle vier Angebote, ihre exakten Preise, Reservierungen und Rerollkosten, auch während der folgenden Kampfwelle. Alte Shops mit drei Plätzen behalten ihre Angebote, ausverkauften Plätze und Preise; nur der vierte Platz wird ergänzt. Alte gespeicherte Level-ups mit drei Optionen bleiben erhalten, neue Level-ups bieten vier verschiedene geeignete Stats.

Kisten-Zerlegewerte bleiben zunächst bei 60 % des Item-Basispreises plus vorhandenen Itemboni. Waffenverkauf bleibt bei 50 % des tatsächlich investierten Kaufwertes. Diese Werte steigen daher nicht beide pauschal mit der Shopinflation.

## Darstellung

Level-ups bieten vier Karten nebeneinander auf breiten Bildschirmen, ein 2×2-Raster in kleineren Fenstern und vier Karten untereinander in hohem Hochformat. In kurzem Querformat werden das Maskottchen und der Erklärungstext ausgeblendet, um Platz für die vier Entscheidungen zu schaffen. Die Effekte bleiben sichtbar; ausführliche Texte stehen zusätzlich im Tooltip.

Der Shop zeigt ab 1000×560 vier kompakte Angebote nebeneinander über die gesamte Dialogbreite. Ausrüstung, Stats und der ausgewählte Vergleich stehen darunter. Die Karten zeigen Icon und Namen in einer Zeile sowie bis zu zwei Zeilen Kurzbeschreibung; vollständige Effekte stehen im Tooltip und in den Details. Kaufen und Merken liegen in senkrechten Karten unten nebeneinander, in waagerechten Listen rechts übereinander. Merken verwendet ein Pin-Icon; ein goldener Hintergrund kennzeichnet reservierte Angebote. Unterhalb dieser Breite wird ab 760 Pixeln ein 2×2-Raster verwendet, darunter eine scrollbare Liste.

Die Karten haben pro Ansicht feste Höhen und reservieren je zwei Textzeilen für Titel und Kurzbeschreibung. Aktionen bleiben am unteren Kartenrand; unterschiedliche Texte und Preise verändern ihre Position oder Größe nicht. Der Kaufknopf ist 96 Pixel breit, der Pin in senkrechten Karten quadratisch und in waagerechten Listen ebenfalls 96 Pixel breit. Beide sind auf breiten Bildschirmen 40 Pixel hoch, sonst 44 Pixel. Shopkarten vergrößern sich beim Hover nicht, damit die Klickflächen stabil bleiben.

Der kleine Reload-Knopf sitzt rechts in der Angebotsüberschrift und zeigt den aktuellen Münzpreis; der Tooltip erklärt Rerolls und Reservierungen. Unten rechts steht ein kleiner Wellenstart-Knopf. Die gesammelten Items und Relikte bleiben als feste Icon-Leiste außerhalb der Angebots-/Detail-Scrollbereiche sichtbar: Icons mit Stapelzahl und getrennte Gesamtzahlen für Items und Relikte. Titel und vollständige Effekte stehen im Hover-Tooltip. Große Sammlungen scrollen seitlich; Antippen oder Tastaturauswahl öffnet ebenfalls die vollständigen Effekte. In schmalem Hochformat sitzt der Wellenstart unter der Item-Leiste. Ein leeres Inventar zeigt ausdrücklich „Keine Items“.

Automatisch geprüft wurden 320×568, 360×640, 568×320, 640×360, 540×960, 720×1280, 800×600, 1024×600, 1280×670, 1280×720 und 1920×1080 sowie der anschließende Wechsel zurück ins Hochformat. Der Layout-Test verwendet sechs belegte Hände, alle 30 Items (eins davon doppelt) und drei Relikte. Er prüft die sichtbare Item-Leiste, Hover-Titel/-Effekte und Stapelzahlen, das Erreichen des letzten Relikts per Scrollen sowie die kompakten Reload-/Startknöpfe. Gemischte Titel, lange/mehrzeilige Texte, Preise von 5/100/1000/9999 und wechselnde Reservierungen müssen identische Aktionsgrößen und Baselines behalten. Karten, Text/Icon-Grenzen und Knöpfe werden auf Überschneidungen und Überläufe geprüft, auf breiten Bildschirmen auch alle Katalogtexte in den schmalen Karten. Gerenderte Ansichten bei 320×568, 720×1280, 1024×600, 1280×670 und 1280×720 wurden zusätzlich visuell geprüft.

## Messung und Grenzen

`tools/audit_economy.gd` erzeugt [Spawnplan-Erwartungswerte](economy_audit.json) für 30 Seeds. `tools/benchmark_economy.gd` erzeugt [Kampfmessungen](economy_combat_benchmark.json) für vier konfigurierte Builds mit je drei Seeds.

| Welle | Gold in drei Kampfmessungen | Zauberbürste I |
| --- | --- | ---: |
| 1 | 15 / 15 / 9 | 10 |
| 4 | 15 / 17 / 17 | 16 |
| 10 | 32 / 25 / 28 | 28 |
| 19 | 58 / 74 / 71 | 45 |

Die Messungen verwenden unsterbliches Denti, eine vorgegebene Ellipsenbewegung, konfigurierte Waffen/Stats und keine Economy-Items oder Shopkäufe. Sie erfassen eingesammeltes und bei Zeitablauf auf dem Boden liegendes Gold. Bosswelle 10 endet für die Messung am normalen Zeitlimit, nicht erst nach einem verlängerten Bosskampf. Die Builds belegen keine vollständige, erreichbare Kaufhistorie. Rendering-/Frame-Reihenfolge kann die Kampfmessung trotz festem Seed leicht verändern. Diese Ergebnisse prüfen die laufende Kampf- und Drop-Implementierung; manuelle Runs bleiben für die endgültige Balance erforderlich.

Die Telemetrie speichert pro Welle Einnahmequellen (Drops, Pickup-Items, Kill-Items, Zinsen, Kisten, Waffenverkauf) und Shopausgaben getrennt nach Waffen, Items und Rerolls. So lässt sich ein realer Run anschließend auf Kaufkraft untersuchen.

Quellen für die übernommenen Kurven: [Brotato Materials](https://brotato.wiki.spellsandguns.com/Materials), [Brotato Shop](https://brotato.wiki.spellsandguns.com/Shop).
