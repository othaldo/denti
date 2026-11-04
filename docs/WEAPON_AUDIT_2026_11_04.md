# Waffen-Audit: verdiente Einstiege auf Normal und Hell

04.11.2026 · Stand `e636465` nach dem Interdental-Buff.

**Die nächsten Prüfprioritäten sind der Polierer und der frühe Ausbau der
Zauberbürste.** Der Schmelzspiegel folgt dahinter. Der Kronenwerfer liefert in
der größeren Probe keinen ebenso deutlichen Anlass für einen frühen Buff.
Spielwerte wurden für diesen Audit nicht verändert.

Die anschließende Umsetzung steht im [kleinen Waffen-Buff](WEAK_WEAPON_BUFF_2026_11_04.md).
Dieser Bericht behält die ursprünglichen Werte und Ergebnisse als Vorher-Vergleich.

## Umfang und Kontrolle

- 108 Einstiegsläufe: alle 18 Startwaffen, Normal/Hell, je drei gleiche Seeds,
  `regular`-Pilot, `kite`-Strategie und `synergy`-Ausbau.
- 45 Hell-Nachläufe: neun Seeds für Zauberbürste, Polierer, Kronenwerfer,
  Schmelzspiegel und UV als Kontrolle, gleiche Regeln.
- 18 Hell-Nachläufe: Zauberbürste und Polierer mit dem `expert`-Pilot.
- Neun Hell-Nachläufe: Zauberbürste mit `regular` und `full_build`.

Das sind **180 ausgeführte Läufe und 165 unterschiedliche Konfigurationen**.
Die 15 wiederholten Fälle liefern exakt dieselben Endpunkte für Ausgang,
Welle, Kills, Gold, XP, Level und Kapseln. Alle Berichte verwenden denselben
Spielquellen-Hash; Godot 4.7.2, feste 60 Hz und Zeitskalierung 1. Bis zu vier
Prozesse laufen gleichzeitig, jeder mit eigenen Benutzerdaten.

Jeder Lauf beginnt mit einer kostenlosen Mk-I-Startwaffe, 100 HP, Level 1 und
null Gold. Weitere Waffen, Items und Rerolls werden bezahlt. Die echte
Beutesammlung, Levelangebote und Waffenpunkte bestimmen den Ausbau; HP werden
mitgenommen. Der Pilot reagiert verzögert auf sichtbare Warnungen und nutzt
den echten Dash. Es werden überwiegend Waffen derselben Familie gekauft.

Die Prüfung endet am ersten Boss, **nicht an Welle 20**. Die Pilotprofile sind
Diagnoseverfahren, keine menschlichen Siegchancen. Drei Seeds dienen der
Suche nach Auffälligkeiten, neun der gezielten Kontrolle. HP-Mediane gelten
nur unter tatsächlichen Bossankünften, Bosszeiten nur unter erfolgreichen Kills.
Die 18 Startwaffen umfassen nicht die sechs Evolutionen.

## Breite Suche: alle 18 Startwaffen

Auf Normal bestehen alle 54 Proben den ersten Boss. Auf Hell erreichen 51/54
Proben den Boss; 49/54 besiegen ihn. Die folgende Tabelle enthält den ersten
Dreiervergleich, nicht die späteren Neunergebnisse.

| Waffe | Normal: Boss erreicht / besiegt | Hell: Boss erreicht / besiegt | Hell: HP vor Boss | Hell: Boss-TTK |
| --- | ---: | ---: | ---: | ---: |
| Zauberbürste | 3/3 · 3/3 | 1/3 · 1/3 | 84,1 % | 18,28 s |
| Turbo-Bohrer | 3/3 · 3/3 | 3/3 · 3/3 | 100,0 % | 18,67 s |
| Zahnseidenpeitsche | 3/3 · 3/3 | 3/3 · 3/3 | 86,3 % | 21,12 s |
| Wasserflosser | 3/3 · 3/3 | 3/3 · 3/3 | 91,5 % | 18,95 s |
| Kronenwerfer | 3/3 · 3/3 | 3/3 · 2/3 | 80,1 % | 18,98 s |
| Schmelzspiegel | 3/3 · 3/3 | 3/3 · 2/3 | 86,0 % | 18,68 s |
| Zahnsteinkratzer | 3/3 · 3/3 | 3/3 · 3/3 | 67,4 % | 21,63 s |
| Mundspülungs-Mörser | 3/3 · 3/3 | 3/3 · 3/3 | 95,7 % | 18,97 s |
| Zahnstocher-Speer | 3/3 · 3/3 | 3/3 · 3/3 | 61,6 % | 18,82 s |
| Karies-Fräse | 3/3 · 3/3 | 3/3 · 3/3 | 51,8 % | 19,90 s |
| Interdental-Bürste | 3/3 · 3/3 | 3/3 · 3/3 | 68,2 % | 20,55 s |
| Fluorid-Sprüher | 3/3 · 3/3 | 3/3 · 3/3 | 93,8 % | 19,47 s |
| Mundduschen-Turbine | 3/3 · 3/3 | 3/3 · 3/3 | 91,9 % | 18,83 s |
| UV-Lampe | 3/3 · 3/3 | 3/3 · 3/3 | 76,8 % | 18,87 s |
| Amalgam-Schleuder | 3/3 · 3/3 | 3/3 · 3/3 | 87,8 % | 18,87 s |
| Zahnseiden-Schneide | 3/3 · 3/3 | 3/3 · 3/3 | 73,7 % | 19,17 s |
| Prophylaxe-Polierer | 3/3 · 3/3 | 2/3 · 2/3 | 61,1 % | 21,63 s |
| Fluorid-Rakete | 3/3 · 3/3 | 3/3 · 3/3 | 51,1 % | 19,83 s |

Mörser, Rakete, Fluorid-Sprüher, Peitsche und Amalgam-Schleuder zeigen hier
keinen akuten Einstiegsfehler. Das ist kein Urteil über späte Wellen oder
optimal gebaute Mischgruppen. Der Support-Sprüher wird insbesondere nicht
allein anhand niedriger Einzelziel-DPS zum Buff-Kandidaten erklärt.

## Nachprüfung mit neun Hell-Seeds

| Waffe | Boss erreicht | Boss besiegt | HP vor Boss | Erfolgreiche Boss-TTK |
| --- | ---: | ---: | ---: | ---: |
| Polierer | 5/9 | 5/9 | 78,2 % | 19,95 s |
| Zauberbürste | 7/9 | 6/9 | 78,0 % | 18,76 s |
| Schmelzspiegel | 7/9 | 6/9 | 86,0 % | 18,33 s |
| Kronenwerfer | 9/9 | 7/9 | 78,4 % | 19,02 s |
| UV-Kontrolle | 9/9 | 8/9 | 83,6 % | 19,06 s |

### 1. Polierer: Zugang zur Stärke bleibt anspruchsvoll

Alle vier Fehlschläge liegen vor dem Boss: einer in W2, zwei in W3 und einer
in W4. Wer den Boss erreicht, besiegt ihn. Mit dem `expert`-Pilot steigen
Bossankünfte und Siege auf **9/9**, bei 78,8 % medianem Startleben.

Die vorhandene Kontaktmessung zählt ausschließlich abgeschlossene Angriffe;
bei Tod/Wellenende unterbrochene Angriffe werden separat geführt. Nur über
vollständig überstandene Wellen des `regular`-Piloten:

| Welle | Vollständige Proben | Angriffe | Ohne Kontakt | Anteil |
| --- | ---: | ---: | ---: | ---: |
| W1 | 9 | 801 | 15 | 1,9 % |
| W2 | 8 | 1.385 | 238 | 17,2 % |
| W3 | 6 | 1.706 | 393 | 23,0 % |
| W4 | 5 | 2.310 | 454 | 19,7 % |

In W3 verlieren 287 der 393 erfolglosen Angriffe ihr ursprüngliches Ziel vor
dem Kontakt. Bereits vorhandener Ersatzkontakt löst somit nicht jeden leeren
Schwung. Der Expert-Pilot hat in W3 ebenfalls rund 23 % kontaktlose Angriffe;
der Anteil allein erklärt den Überlebensunterschied nicht.

**Nächster Schritt:** begrenzten Gruppennutzen, sicher nutzbare Kontaktzeit,
frühe Shop-Ausstattung und die Auszahlung des Crit-Zyklus zusammen prüfen.
Noch mehr theoretischer Boss-DPS wäre am beobachteten Hauptproblem vorbei.

### 2. Zauberbürste: frühe Horden und Ausbaupolitik

Der Dreiervergleich wirkte mit 1/3 Siegen besonders schlecht. Die neun Seeds
relativieren das auf **6/9**: zwei Fehlschläge in W4, einer beim Boss. Es gibt
damit ein Einstiegsrisiko, aber keinen Beleg für eine grundsätzlich unspielbare
Waffe. Mit `expert` werden **8/9** Bosse erreicht und besiegt.

In den beiden gescheiterten W4-Proben stehen durchschnittlich 17,6 bzw. 23,9
Gegner gleichzeitig, gegenüber 5,1 bzw. 5,4 bei UV mit denselben Seeds.
Die Zauberbürste trägt dort bereits zwei Mk-III- und eine Mk-II-Waffe bzw.
drei Mk-II-Waffen. Ein bloßer Bonus ausschließlich auf Mk I würde den
beobachteten W4-Engpass daher nicht vollständig adressieren.

Mit demselben `regular`-Pilot, aber `full_build`, bestehen **9/9** Läufe.
Diese Politik darf mehrere bezahlbare Items pro Shop kaufen und verteilt
Waffenpunkte früher zwischen Feuer und Lebensraub; sie verändert nicht nur
einen einzelnen Wert. Der Effekt darf deshalb nicht vollständig einem Item
oder Lebensraub allein zugeschrieben werden.

**Nächster Schritt:** den frühen Gruppen-Clear und die Überbrückung bis zur
Mehrfachsalve prüfen, außerdem erschwingliche defensive Ergänzungen. Die
Boss-TTK unter erfolgreichen Läufen ist bereits ähnlich wie bei UV.

### 3. Spiegel und Kronenwerfer: kleinere Auffälligkeiten

Der Schmelzspiegel verliert je einen Lauf in W2, W4 und beim Boss. Als
Einzelzielwaffe braucht er eine Prüfung mit Flächen-/Kontrollpartner, bevor
der Grundschaden erhöht wird. Die neun Seeds liefern eine Prüfpriorität,
keine gesicherte allgemeine Rangfolge gegenüber der Zauberbürste.

Der Kronenwerfer erreicht in allen neun Seeds den Boss und verliert dort
zweimal. Gegenüber der UV-Kontrolle mit einem Bossfehlschlag ist das ein
schwächerer Anlass für einen sofortigen Buff. Zunächst die beiden Bossrouten
ansehen; ein pauschaler früher Schadensschub folgt daraus nicht.

## Daten und Reproduktion

Der [kompakte Messbericht](weapon_audit_2026_11_04.json) enthält alle 180
Einzelresultate, Wellenmetriken, Kontaktzähler, Startausrüstung, Methoden,
Quellen-Hashes und Hashes der vollständigen lokalen Rohberichte. Die
15 wiederholten Konfigurationen sind keine zusätzlichen unabhängigen Seeds.
Es gab keine Prozessfehler, Abbrüche oder geänderten Simulationsschritte.

```powershell
python tools/run_bot_comparison.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --weapons magic_toothbrush,turbo_drill,floss_whip,water_jet,crown_launcher,enamel_mirror,plaque_scaler,mouthwash_mortar,toothpick_spear,cavity_grinder,interdental_brush,fluoride_sprayer,water_turbine,uv_lamp,amalgam_slingshot,floss_garrote,prophylaxis_polisher,fluoride_rocket --skills regular --strategies kite --build-policies synergy --difficulties normal,hell --seeds 13579,24680,112233 --jobs 4 --output .godot/weapon_audit_repeat.json
```

Die Hell-Nachprüfung verwendet die fünf Waffen der zweiten Tabelle und die
Seeds `13579,24680,112233,31415,27182,42424,77777,88888,99999`.
Für die Pilotkontrolle `--skills expert` und für die Zauberbürsten-Ausbaukontrolle
`--build-policies full_build` setzen. Maximal vier Prozesse gleichzeitig;
Benchmark-Quellen während der Messungen unverändert lassen.

Automatische Resultate und Codeprüfung bestimmen hier die nächste sinnvolle
Spieltest-/Buff-Priorität. Ein vollständiger Hell-Run, verschiedene manuelle
Spielweisen und spätere Bossaufgaben bleiben eigene Prüfungen.
