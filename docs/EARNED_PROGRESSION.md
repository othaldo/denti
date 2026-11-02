# Verdienter Ausbau: Bohrer auf Hell

02.11.2026 · Spielerfeedback: Sechs Turbo-Bohrer scheitern am ersten Hell-Boss;
Flächenwaffen verdienen vorher mehr Gold, XP und potenziell Upgrades.

Die anschließende [Prüfung und Umsetzung für Bohrer/Fräse](DRILL_CONTACT_BALANCE.md)
misst Zielverluste, begrenzten Durchschlag und sichere Reichweite getrennt.
Die folgenden Werte dokumentieren die Ausgangsdiagnose vor diesem zweiten Pass.

**Der bisherige Waffenvergleich blendete diesen Nachteil aus.** Er verglich
fertig ausgestattete Checkpoints mit gemeinsamen Stat-, Item- und Punktebudgets.
Das beantwortet die Kampfleistung bei vorhandenem Ausbau. Es beantwortet nicht,
welcher Ausbau mit einer Startwaffe tatsächlich verdient und gekauft wird.
„Guter früher Bosskiller“ war deshalb als allgemeines Urteil zu weit gefasst:
Belegt war hoher Bossdurchsatz auf Normal bei vorgegebenem Ausbau.

## Die Rückkopplung im Spiel

Gegnerkills erzeugen Gold, XP und Chancen auf Upgrade-Kapseln. Mehr Kills können
mehr Levelaufstiege und Einkäufe ermöglichen; diese erhöhen wiederum die Killrate.
Flächenangriffe können zusätzlich Platz schaffen und eingehenden Schaden vermeiden.
Die nächste Welle beginnt dann mit mehr Leben und besserem Ausbau.

Auf Hell multipliziert `reward_chance_multiplier = 0.8` die Gold- und
XP-Dropchancen. Kapseln werden separat pro Kill gewürfelt; gewöhnliche Zufallsfunde
sind auf drei pro Welle begrenzt. Die nachträgliche Beutesammlung holt alle
erzeugten Drops ein, ersetzt aber keine Belohnungen aus nicht getöteten Gegnern.
Ein Bossbonus hilft vor dem Boss kaum beim Aufbau der Wirtschaft.

## Neue Messung: Startwaffe bis Welle 5

30 Proben auf Hell: fünf Startwaffen, drei Seeds und zwei Bewegungsregeln.
Jeder Lauf beginnt mit **einer echten kostenlosen Mk-I-Startwaffe**, 100 HP,
Level 1 und null Gold. Deren Wurzelkosten unterscheiden sich wie im echten Start.
HP, Geld, XP, Ausrüstung, Items und Verzauberungen bleiben zwischen den Wellen
erhalten. Es gibt keine kostenlose Heilung oder vorgegebene Ausbauwerte.

Die echte Beutesammlung und Belohnungsqueue laufen vor dem Shop. Levelaufstiege
wählen aus tatsächlichen Angeboten; verdiente Waffenpunkte verbessern Feuer
möglichst gleichmäßig. Der echte Shop verkauft passende Waffen und höchstens
ein einfaches Standarditem je Shop. Höchstens vier Rerolls werden tatsächlich
bezahlt. Angebote und Levelentscheidungen sind reproduzierbar gesetzt.

`hunt` sucht aktiv Gegner auf und richtet den Abstand nach der Waffenreichweite;
`orbit` läuft die bisherige Ellipse. Am Boss wird gezielt nachgesetzt. Beide
Regeln reagieren nicht bewusst auf Warnungen und verwenden keinen Dash.
Das sind **Diagnoseverfahren, keine menschlichen Winrates oder optimalen
Hell-Strategien**. Die genaue Ausrüstung des gemeldeten Spieltests ist unbekannt.

### Erste vollständig beendete Welle

Alle drei `hunt`-Proben jeder Waffe überleben W1. Mediane nach vollständiger
Beutesammlung, noch vor Käufen:

| Startwaffe | Kills | Gold | XP | Level danach |
| --- | ---: | ---: | ---: | ---: |
| Turbo-Bohrer | 46 | 38 | 35 | 4 |
| Zahnseiden-Schneide | 42 | 31 | 32 | 4 |
| UV-Lampe | 52 | 45 | 42 | 5 |
| Mundduschen-Turbine | 56 | 43 | 45 | 5 |
| Interdental-Bürste | 57 | 42 | 41 | 5 |

UV verdient hier gegenüber dem Bohrer rund 18 % mehr Gold und 20 % mehr XP.
Das reicht bereits für einen weiteren Levelaufstieg. Die Schneide zeigt zugleich:
Nicht jede Flächenwaffe verdient in jeder frühen Situation automatisch mehr.

### Zustand vor dem ersten Boss

Nur `hunt`; Einkommen und Start-HP werden nur für tatsächlich bis W5 gelangte
Läufe angegeben. Deshalb sind diese Mediane **nicht über identische Seedmengen**
gebildet. Die Rohdaten erlauben den paarweisen Vergleich.

| Waffe | W5 erreicht | Gold verdient W1–4 | XP W1–4 | Level | Start-HP W5 | Boss besiegt |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Turbo-Bohrer | 2/3 | 278,5 | 254 | 12 | 42,7 % | 0/3 |
| Zahnseiden-Schneide | 2/3 | 264,5 | 244,5 | 12 | 82,6 % | 0/3 |
| UV-Lampe | 3/3 | 301 | 285 | 13 | 58,8 % | 3/3 |
| Mundduschen-Turbine | 3/3 | 280 | 273 | 13 | 66,1 % | 1/3 |
| Interdental-Bürste | 2/3 | 288,5 | 264 | 13 | 25,3 % | 0/3 |

Auch die beiden Bohrer-Proben mit Bossankunft besitzen sechs tatsächlich gekaufte
und teilweise fusionierte Bohrer. Sie beginnen den Boss mit 46,8/107 bzw.
49,6/119 HP und sterben dort. Checkpoints mit vollen HP verdeckten diesen Nachteil.
Gold in der Tabelle ist **verdientes Gesamteinkommen**, nicht unverbrauchtes Geld:
Im Geldbeutel liegen beim Bohrer noch 18 bzw. 0 Gold.

Beim paarweisen Vergleich der zwei gemeinsamen bis W5 überlebten Seeds verdient
UV im Median rund 6 % mehr Gold und 11 % mehr XP. In einem dieser Seeds verdient
der Bohrer sogar geringfügig mehr Gold. Das ist kein Beleg für einen universellen
riesigen Goldabstand. Einkommen, Wahlmöglichkeiten, erlittene Schäden und bezahlte
Ausrüstung wirken gemeinsam. Die reine Kreisroute scheitert mit dem Bohrer schon
vor W5 in allen drei Proben; aktive Zielsuche verändert die Erreichbarkeit deutlich.

## Folgerung für den nächsten Balancepass

Eine Waffe braucht neben guter Leistung bei gleicher Ausrüstung einen realistisch
finanzierbaren und überlebbaren Weg zu ihrer Stärke. Daher zuerst:

1. **Verlorene Bohrstöße messen.** Einzelziel-Nahwaffen halten während des Stoßes
   ihr ursprünglich gewähltes Ziel fest. Stirbt es vorher, kann der Stoß ohne
   Nutzen enden. Bei sechs Exemplaren die tatsächliche Ausfallrate erfassen und
   Ersatzkontakt innerhalb der sichtbaren Bewegung prüfen.
2. **Begrenzten Gruppenbeitrag testen.** Ein kleiner Durchbohr-Treffer auf ein
   zweites Ziel entlang des vorhandenen Stoßes wäre ein passender Buff-Kandidat.
   Boss-Fokus und klare Trefferform bleiben seine Rolle. Das ist ein Vorschlag,
   noch keine implementierte Eigenschaft.
3. **Mindestversorgung als Systemalternative prüfen.** Wenn mehrere Einzelziel-
   Starts strukturell zurückfallen, eine begrenzte Versorgung nach überlebter
   Welle an bezahlbaren frühen Angeboten messen. Zusätzlicher Kill-Ertrag bleibt
   attraktiv. Keine unbegrenzte Auszahlung oder automatische Gleichstellung
   aller Builds.
4. **Gemeinsame Abnahme:** verdientes Gold/XP/Kapseln, bezahlte Waffen und Rerolls,
   Stats, verbleibende HP sowie Bossleistung. Starke AoE-Mechaniken bleiben
   befriedigend; ein schwacher Einzelziel-Start begründet keinen pauschalen Nerf.

Ein weiterer reiner Boss-Schadensbonus beantwortet die vorgeschaltete Einkommens-
und Überlebensfrage kaum. In diesem Schritt wurden keine Waffen-, Gegner- oder
Belohnungswerte verändert.

## Reproduktion und Prüfung

[30 Rohproben mit Wellen- und Shopzuständen](balance_earned_progression.json),
[automatisch erzeugte Mediane](balance_earned_progression.md).

```powershell
python tools/run_earned_progression.py --output docs/balance_earned_progression.json
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --suite all --filter earned_progression --filter build_comparison --filter economy_shop --filter post_wave_rewards
python -m unittest discover -s tools/tests -p test_earned_progression.py
```

Der neue Godot-Test prüft Hell-Dichte/Eliten, unveränderte Normal-Spawnplanung,
einen echten Zwei-Wellen-Pfad, vollständige Beutesammlung, verdiente Levels,
bezahlte Angebote, fortgeführte HP/Ausrüstung und reproduzierbare Einnahmen.
Er und die drei bestehenden Vergleichs-/Flowtests bestehen. Zwei zusätzliche
Python-Prüfungen verhindern, dass vorzeitig gestorbene Läufe als vollständiger
Weg zum Boss ausgewertet werden. Auch die zwei bestehenden Aggregationstests bestehen.

Normale Benutzerdaten, Spielstände und Meisterschaftsfortschritt werden nicht
beschrieben. Die normale Spieloberfläche erhält keine zusätzlichen Anzeigen.
