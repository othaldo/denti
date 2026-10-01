# Economy-Vergleich: Denti und Brotato

Stand der Untersuchung: 2026-10-01, vor der Umsetzung. Die nachfolgenden Tabellen beschreiben diesen Ausgangszustand. Die anschließende Umsetzung einschließlich Startbonus und vier Auswahlkarten steht in [ECONOMY_BALANCE.md](ECONOMY_BALANCE.md).

## Befund in Denti

Gold und XP sind getrennt. Ein normaler Gegner muss zuerst die gemeinsame Loot-Prüfung bestehen. Danach gibt es für Gold eine weitere gegnerspezifische Prüfung:

`Erwartetes Gold/Kill = Loot-Chance * Münzchance des Gegners * Münzwert`.

| Gegner | Münzchance | Wert | Gold/Kill, Welle 1 | Gold/Kill, Welle 19 |
| --- | ---: | ---: | ---: | ---: |
| Plaque | 22 % | 1 | 0,22 | 0,0836 |
| Bakterium | 28 % | 1 | 0,28 | 0,1064 |
| Säurespucker | 32 % | 1 | 0,32 | 0,1216 |
| Zuckerstück | 55 % | 2 | 1,10 | 0,4180 |

Welle 1 dient in dieser Tabelle als Vergleich der Basiswerte; Bakterien, Zucker und Säurespucker erscheinen erst später. Eliten umgehen die gemeinsame Loot-Prüfung und geben garantiert 4 Gold. Normale Loot-Chance fällt von 100 % um 4 Prozentpunkte pro Welle bis auf 38 %. Bosswellen haben eine eigene Kurve mit mindestens 45 %. Luck erhöht die normale Münzchance nicht.

Boss-Kills selbst geben keine Münzen oder XP. Boss-Relikte sind ein separater Build-Reward. Nach Ablauf der Wellenzeit werden verbleibende Gegner entfernt; sie werden nicht automatisch in Kill-Belohnungen umgewandelt. Boden-Loot wird hingegen vollständig eingesammelt. Es gibt deshalb keinen Grund, die Sammelreichweite als erste Lösung für fehlendes Gold zu erhöhen.

Waffen auf Stufe I kosten 7–18 Gold. Die Zauberbürste kostet 9/15/22/30 Gold auf I/II/III/IV. Items kosten 4–22 Gold. Es gibt keine allgemeine Welleninflation: Itempreise bleiben konstant, höhere Waffenstufen kosten mehr. Ein Shop hat drei Angebote, anfangs mindestens zwei Waffen, danach immer mindestens eine. Rerolls kosten 2, 3, 4, ... Gold und starten in jedem Shop erneut bei 2. Angebote können derzeit nicht für die nächste Welle reserviert werden.

Economy-Items existieren, ersetzen aber keine gesunde Basisversorgung: Karies-Kopfgeld kostet 6 und gibt 1 Gold pro 12 Kills; Goldfüllung kostet 12 und erhöht gesammelte Münzen um 15 %; Zinszahn kostet 9 und gibt 8 % Zins auf vorhandenes Gold, höchstens 6 pro Stapel. Der Zins wird am Wellenende vor den Shopausgaben berechnet. Bei knappem Startkapital und schwacher Killrate hilft das nur begrenzt. Kisten können zerlegt werden und bringen 60 % des Itempreises, mit Pfand-Bonus mehr; gewöhnliche Kisten sind auf eine pro Welle begrenzt.

## Brotato als Referenz

Ein Material-Pickup zahlt sowohl XP als auch Kaufwährung. Die normale Material-Drop-Chance beträgt in Welle 1–4 100 %, danach `1 - 0,015 * Welle`: Welle 10 hat 85 %, Welle 20 70 %. Hordenwellen senken die Chance zusätzlich. Nicht gesammelte Materialien gehen in einen Beutel und werden in späteren Wellen ausgezahlt. Die 50-Pickup-Grenze bündelt Werte, ohne Einkommen zu verlieren. [Materials](https://brotato.wiki.spellsandguns.com/Materials)

Brotato bietet vier Shopplätze und kostenlose Reservierung mit Preisbindung. Die ersten zwei Shops enthalten genau zwei Waffen und zwei Items. Preise steigen durch `Basispreis + Welle + Basispreis * 0,1 * Welle`; frühe Investitionen bleiben dadurch wertvoll. Rerolls werden innerhalb eines Shops und über die Wellen teurer. Der Kauf aller vier Angebote gewährt einen kostenlosen Refresh. Diese Mechaniken verbinden höheres Einkommen mit Geldsenken und Planung. [Shop](https://brotato.wiki.spellsandguns.com/Shop)

Harvesting gibt am Wellenende Kaufwährung und XP entsprechend seinem Wert und wächst anschließend um 5 %, aufgerundet. Das schafft eine frühe Investition mit späterem Ertrag. Für Denti wäre eine identische Übernahme zugleich ein XP- und Gold-Buff; eine reine Gold-Variante passt eher zur bestehenden Trennung beider Fortschrittssysteme. [Harvesting](https://brotato.wiki.spellsandguns.com/Harvesting)

Luck erhöht unter anderem Consumable-/Kistenchancen und Angebotsqualität. Es ist damit eine indirekte Economy-Investition. Eine zusätzliche direkte Gold-Skalierung über Dentis Luck würde mehrere Vorteile im selben Stat bündeln und müsste gesondert getestet werden. [Luck](https://brotato.wiki.spellsandguns.com/Luck)

## Berechnung der Kaufkraft

Reproduktion: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tools/audit_economy.gd`.

Das Tool wertet 30 vollständige Spawnpläne auf Normal mit festen Seeds und 60 Hz aus. Berücksichtigt werden normale Spawns, Bursts, Horden, Eliten und deren Eskorte. Die Drop-Werte sind mathematische Erwartungswerte. Keine Kampfsimulation: Spawn-Caps, Killgeschwindigkeit, Positionierung, Bossbeschwörungen, Items, Kisten, Erspartes und Shopausgaben sind ausgeschlossen. Die Annahme „60 % Clear“ multipliziert alle Gegnerrollen gleichmäßig mit 0,6; ein echter Build kann eine andere Zusammensetzung töten.

| Welle | Angeforderte Gegner | Aktuell, alle besiegt | Aktuell, 60 % besiegt | Begrenzter Vorschlag, 60 % besiegt |
| --- | ---: | ---: | ---: | ---: |
| 1 | 44 | 9,7 | 5,8 | 10,5 |
| 2 | 52 | 11,8 | 7,1 | 12,8 |
| 4 | 80 | 21,5 | 12,9 | 23,2 |
| 5 | 79 | 22,3 | 13,4 | 23,3 |
| 10 | 133 | 40,1 | 24,1 | 35,5 |
| 15 | 175 | 39,4 | 23,7 | 28,5 |
| 19 | 267 | 73,6 | 44,2 | 48,6 |

Der begrenzte Vorschlag erhöht den normalen Gold-Erwartungswert bis Welle 4 um 80 %. Der Faktor sinkt linear auf +15 % ab Welle 16; Elite-Gold bleibt gleich. Das ist ein Testkandidat, kein bereits spielgetesteter Balancewert. Gold kann separat von der XP-Prüfung mit einer einzigen kombinierten Wahrscheinlichkeit gewürfelt werden; die Entkopplung allein erhöht den Erwartungswert nicht.

Zum Vergleich wurde ein großzügiger Kandidat berechnet: Plaque/Bakterien/Säure/Zucker mit 40/45/50/65 % Münzchance und Brotatos normaler Drop-Abschwächung, ausschließlich für Gold. Welle 19 würde bei vollständigem Clear etwa 151 statt 74 Gold liefern. Bei Dentis konstant günstigen Items wäre das ein großer zusätzlicher Build-Buff. Eine direkte Übernahme ohne Preis- und Kaufkraftprüfung ist deshalb nicht der erste Vorschlag.

## Empfohlene Reihenfolge

1. Frühe Goldversorgung stärken und unabhängig von XP auswerten. Den begrenzten Kandidaten gegen echte Runs vergleichen. Ziel: nach frühen Wellen normalerweise eine sinnvolle Waffenanschaffung; bei gutem Clear zusätzlich ein günstiges Item oder ein Reroll. Bei Bedarf mit einem gespeicherten Bruchteil-/Fortschrittskonto die Zufallsschwankung dämpfen, ohne Gold zu verschenken oder XP zu erhöhen.
2. Angebote kostenlos reservierbar machen, einschließlich Save/Resume. Ein seltenes Wunschangebot soll ein erreichbares Sparziel bleiben. Das verbessert Kaufentscheidungen auch bei begrenztem Budget.
3. Garantiertes Gold für besiegte Zwischenbosse prüfen: beispielsweise 10/15/20 Gold in Welle 5/10/15, nach dem Loot-Sweep und vor dem Shop. Keine wirtschaftlich nutzlose Auszahlung nach dem finalen Boss. Dies kompensiert die geringere normale Gegnerzahl in Bosswellen und belohnt den riskanten Encounter; Relikte bleiben separat.
4. Einen kleinen festen Gold-Ertrag am Wellenende als optionale Economy-Investition prüfen, etwa „Zahnfee-Honorar“. Zunächst über bestehende Items und mit Stacklimit statt sofort einem weiteren Level-up-Stat. XP unverändert lassen. Erst nach gesunder Basisversorgung ergänzen, damit das Item keine Pflichtwahl wird.
5. Vier Shopplätze und die Waffen-Garantie ab Welle 6 überprüfen. Derzeit beansprucht auch spät eine garantierte Waffe mindestens ein Drittel des Shops. Reservierung und bessere Auswahl können mehr bewirken als weitere Münzen. Höheres Einkommen und neue Slots müssen zusammen auf erreichbare Käufe und zusätzliche Build-Stärke geprüft werden.

Keine pauschale Brotato-Inflation oder billigeren Rerolls als erster Schritt: Dentis Rerolls sind schon günstig und Itempreise steigen nicht. Falls nach der Anpassung dauerhaft zu viele Käufe möglich sind, gezielt mächtige Items und hohe Waffenstufen bepreisen.

## Ergänzung: Gold und Brotato-Preiskurve gemeinsam

Der Nutzer schlägt inzwischen ausdrücklich steigende Preise pro Welle und die Brotato-Preiskurve vor. Damit ändert sich die Bewertung der großzügigeren Gold-Variante: Sie ist gemeinsam mit Inflation ein sinnvoller Testkandidat. Der begrenzte Gold-Bonus oben wurde für die bisherigen konstanten Preise gerechnet und wäre mit voller Inflation besonders spät wahrscheinlich zu knapp.

Die Preiskurve kann direkt verwendet werden: `floor(Basispreis + Welle + Basispreis * 0,1 * Welle)`. Dabei bleiben Dentis Basispreise die Grundlage. Für Waffen gilt zunächst der vorhandene Stufenpreis als Basis, auf den die Welleninflation einmal angewendet wird. Höhere Stufen und Welleninflation müssen danach gemeinsam auf erreichbare Käufe überprüft werden.

| Shop nach Welle | Gold, großzügiger Kandidat bei 60 % Clear | Zauberbürste I | Zauberbürste IV | Item mit Basispreis 5 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 10,6 | 10 | 34 | 6 |
| 5 | 22,2 | 18 | 50 | 12 |
| 10 | 42,2 | 28 | 70 | 20 |
| 19 | 90,8 | 45 | 106 | 33 |

Stufe IV wird zur Preisveranschaulichung gezeigt; sie wird in frühen Shops nicht angeboten. Budgetwerte sind durchschnittliche neue Einnahmen ohne Erspartes und Economy-Items, keine echte Run-Messung. Die Tabelle zeigt, warum zusätzliche Einnahmen bei Inflation weiterhin Entscheidungen erfordern. Eine vollständige Brotato-Materialübernahme (jeder frühe Kill gibt mindestens 1 Gold und denselben XP-Wert) ist ein eigener, deutlich stärkerer Umbau und wird hier nicht vorausgesetzt.

Empfehlung für den nächsten Umsetzungsschritt: großzügigere separate Gold-Drops zusammen mit dieser Preiskurve, Reservierung mit Preisbindung und Economy-Telemetrie. XP und Leveltempo beibehalten. Die Kurve kann exakt sein; Basiskosten, Dropraten und Waffenstufenfaktoren bleiben die Stellschrauben für Denti. Danach echte Runs messen und erst anschließend zusätzliche passive Einnahmen oder Boss-Gold festlegen. Noch keine Spielwerte geändert.

## Nächste Messung

Für mehrere Starter und feste Seeds reale Runs messen: Kills/angeforderte Spawns, Gold pro Welle nach Quelle, Gold beim Shopstart, Käufe, Waffenstufen, Rerollausgaben, Sparbetrag, Boss-TTK und Schaden genommen. Bestehende Telemetrie erfasst Kills, Spawnblockaden und Gold/XP pro Welle, aber weder vollständige Ausgabehistorie noch alle Goldquellen getrennt. Die Schadensreform kann die Killrate und damit Einkommen gesenkt haben; das ist eine plausible Ursache, keine bereits bewiesene Messung.

Erst diese Daten zeigen, ob eine weitere Anpassung an Drops, Shopauswahl oder Kampfleistung nötig ist. Mehr Gold erhöht erreichbare Build-Stärke; deshalb Bosszeiten und Arenadruck mitmessen.
