# Items und Builds

Shopangebote haben jetzt vier Plätze und steigende Wellenpreise. Mit „Merken“ lassen sich Angebote samt Preis kostenlos über Rerolls und Wellen hinweg reservieren. Gold fällt unabhängig von XP häufiger; die neuen Werte und Messungen stehen in [ECONOMY_BALANCE.md](ECONOMY_BALANCE.md). Die Itempreise sind Basispreise vor der Welleninflation.

In der Zahnklinik gibt es 32 Items in vier Seltenheitsstufen. Ein Kauf gewährt den beschriebenen Effekt sofort; mehrere Exemplare verstärken ihn bis zum Stapellimit. Im Shop werden maximale Stapel nicht mehr angeboten. Die Pausenseite **Items** zeigt den Besitz, die Shopzeile eine kompakte Zusammenfassung.

Schadensstats verwenden jetzt Prozentboni: Goldfüllung +5 %, Implantat +12 %, Keramikschale, Ansteckende Zahnseide und Rücklaufbohrer jeweils -5 %, Blutungsuhr -6 %. Zahnseide-Spule gibt +2 Nahschaden. Bisskraft und Item-Prozentboni werden addiert; trefferabhängige Folgeeffekte skalieren den bereits berechneten Trefferschaden nicht erneut. Details stehen im [Schadens- und Verteidigungsbericht](DAMAGE_DEFENSE_BALANCE.md).

Glück beeinflusst wie bisher die Stufe der Angebote. Zusätzlich hat ein Item-Angebot eine Chance von 28 %, aus den Items mit passenden Eigenschaften gewählt zu werden, sofern solche Items in der gewürfelten Stufe verfügbar sind. Dabei zählen die Eigenschaften bereits gekaufter Items und der ausgerüsteten Waffen. Seltenheit und Preis bleiben von dieser Vorliebe unberührt.

| Item | Effekt neben den angezeigten Stats | Max. |
| --- | --- | ---: |
| Metallkrone | Härte gegen Bewegung | unbegrenzt |
| Fluoridgel | Ein zusätzlicher Schild zu Beginn jeder Welle | 3 |
| Goldfüllung | 15 % mehr Münzen beim Einsammeln | 3 |
| Mundspülung | Fernkampfprojektile verursachen 25 % ihres Trefferschadens im Umkreis | 3 |
| Implantat | 25 % mehr Waffenschaden gegen Bosse | 2 |
| Polierpaste | Kritische Treffer lösen einen Flächenblitz mit 35 % Trefferschaden aus | 3 |
| Speichelquelle | +2 Regenerationspunkte, -3 % Bewegung; alle acht Kills 3 Leben heilen | 3 |
| Keramikschale | Nach erlittenem Schaden 16 Schaden im Umkreis | 3 |
| Minz-Essenz | Beute wird aus 55 zusätzlichen Pixeln Entfernung angezogen | 3 |
| Glücks-Molar | 10 % mehr XP beim Einsammeln | 3 |
| Zahnseide-Spule | Die Blutung von Schnittwaffen verursacht 3 zusätzlichen Schaden pro Sekunde | 3 |
| Karies-Kopfgeld | Alle zwölf Kills eine zusätzliche Münze | 2 |
| Funkensonde | Wasser- und Lichttreffer springen mit 40 % Trefferschaden auf einen nahen Gegner über | 3 |
| Zahnfee-Pakt | Jeder gesammelte XP-Punkt heilt 0,35 Leben | 2 |
| Amalgamkern | Jede Rüstung erhöht Waffenschaden um 2,5 %, bis maximal 60 % | 2 |
| Skalpellwachs | 35 % mehr Waffenschaden gegen blutende Gegner | 2 |
| Heiliges Elixier | Alle zehn Kills ein Zahnblitz mit 25 Flächenschaden | 2 |
| Göttliches Siegel | Zwei zusätzliche Schilde zu Beginn jeder Welle | 1 |
| Ansteckende Zahnseide | Tödliche Waffentreffer auf blutende Gegner übertragen deren Blutung auf einen nahen Gegner; größere Reichweite pro Exemplar, aber weniger Bisskraft | 2 |
| Leitlack | Wasser hält Ziele 0,5 Sekunden länger nass; nasse Gegner erleiden 18 % mehr Wasser- und Lichtschaden pro Exemplar, und Kettenblitze von ihnen reichen weiter; weniger Bewegung | 2 |
| Verbotener Lolli | Während Denti sich tatsächlich bewegt, verursachen Waffen 20 % mehr Schaden pro Exemplar; weniger maximales Leben und Härte | 2 |
| Zahnfee-Pfand | 50 % mehr Münzen beim Zerlegen von Kisten pro Exemplar und mehr Glück; weniger maximales Leben | 2 |
| Blutungsuhr | Blutungen halten pro Exemplar 1 Sekunde länger und können einen zusätzlichen Stapel tragen; weniger Bisskraft | 2 |
| Spülventil | Wassertreffer erzeugen kurzlebige Pfützen, die Gegner nass machen und regelmäßig schädigen; weniger Bewegung | 2 |
| Glanzprisma | Kritische Treffer schicken einen Lichtstrahl zum nächsten Gegner; Lichtwaffen verstärken ihn; weniger Härte | 2 |
| Splitterkrone | Ein geblockter Treffer schädigt nahe Gegner mit Splittern; weniger Bewegung | 2 |
| Zinszahn | Am Wellenende 8 % Zins auf verbleibende Münzen pro Exemplar, höchstens 6 Münzen pro Exemplar; weniger maximales Leben | 2 |
| Rücklaufbohrer | Direkte Projektile fliegen nach dem Treffer oder Reichweitenende zu Denti zurück und können erneut treffen; weniger Bisskraft | 2 |
| Speichelkelch | Überheilung sammelt sich zu 50 % pro Exemplar und erzeugt bei 20 gesammelten Punkten einen Schild; weniger maximales Leben | 2 |
| Zuckerschock | Alle zwölf normalen Kills: vier Sekunden +30 % Putzeifer pro Exemplar (max. +50 %), dann drei Sekunden -25 %; weniger maximales Leben | 2 |
| Goldsonde | 20 % Chance auf doppelten Basis-Münzwert pro Exemplar; zusätzlich einmal +1 Prozentpunkt je 10 Glück (max. +10), Gesamtchance max. 50 %; -5 % Bisskraft | 2 |
| Goldextraktor | +1 Münze pro Exemplar für Drops ab 2 Basis-Münzen (Zucker/Eliten); dieser Bonus wird nicht verdoppelt; -3 % Bewegung | 2 |

Peitsche und Kratzer verursachen auch ohne Items Blutung; der Wasserflosser macht Ziele auch ohne Leitlack nass. Blutung stapelt sich normalerweise auf Gegnern bis zu dreimal und läuft nach 2,5 Sekunden ohne erneuten Schnitt aus; die Blutungsuhr erhöht Dauer und Stapelgrenze. Wet läuft nach 2,5 Sekunden ab, mit Leitlack nach 3 Sekunden. Schilde fangen jeweils einen Treffer ab und sind insgesamt auf fünf Ladungen begrenzt. Kettenblitze, Blutungsübertragung, Spritzer, kritische Blitze, Lichtstrahlen und Keramiksplitter haben kurze interne Abklingzeiten, damit dichte Gegnergruppen das Spiel nicht mit Effekten überfluten. Laufende Effekte, Schildladungen, Stapel und Fortschritte zu Kill-Boni werden mit dem Spielstand gespeichert. Bei Kisten steht der normale Zerlegewert schon beim Drop fest; das Zahnfee-Pfand erhöht den angezeigten und ausgezahlten Wert bei der Entscheidung.

Beispiel-Builds:

- **Schnittpraxis:** Zahnseide-Peitsche oder Plaque-Schaber, Zahnseide-Spule, Skalpellwachs, Ansteckende Zahnseide und Blutungsuhr. Blutende Ziele fördern Flächendruck beim Kill.
- **Wasserwerk:** Wasserflosser oder Mundspülungs-Mörser mit Funkensonde, Leitlack, Spülventil und Mundspülung. Pfützen halten Ziele nass; Ketten erreichen weitere Gegner.
- **Unzerstörbarer Molar:** Metallkrone, Fluoridgel, Göttliches Siegel, Amalgamkern, Keramikschale und Splitterkrone. Geblockte Treffer geben Flächendruck zurück.
- **Zahnfee-Ökonomie:** Glücks-Molar, Goldsonde, Goldextraktor, Goldfüllung, Karies-Kopfgeld, Zahnfee-Pfand und Zinszahn. Wertvolle Drops, Zerlegen und gesparte Münzen zahlen sich aus, aber Denti wird langsamer, schwächer und fragiler. Goldfüllung wirkt beim Einsammeln auf den bereits erhöhten Dropwert.
- **Zuckerrausch:** Verbotener Lolli, Zuckerschock und Heil- oder Schilditems. Tempo nach Killserien kostet Leben und führt anschließend ins Zuckertief.
