# Aktueller Bossvergleich und Imperator-Prüfung

Die daraus folgende Überarbeitung ist inzwischen umgesetzt: [Imperator als Finalboss, Messung und Prüfung](EMPEROR_FINALE.md). Dieser Bericht dokumentiert den Befund vor dem Ausbau.

Stand: 31.10.2026, nach dem neuen Prinzen-Wurftakt und den Säurefächern/Stampfketten des Königs. Kampfdaten für diese Prüfung unverändert.

## Ergebnis

Der Imperator hat weiterhin eine Schwäche beim **aktiven Bewegungsdruck**. Er erreicht Denti und zielt beim Warnbeginn korrekt; die bestehende Zielerfassungsprüfung besteht. Ein Spieler, der ohne Rücksicht auf Warnungen vom Boss wegsteuert und an Wänden abdreht, wird auf Hell im Mittel nur 3,4-mal in 45 s getroffen. Zwei der neun Imperator-Proben mit diesem Piloten bleiben vollständig ohne Treffer.

Das bedeutet nicht, dass er unter allen Bedingungen der leichteste Boss ist. Seine einzelnen Treffer sind deutlich stärker. Beim normalen Kreisen verursacht er trotz weniger Treffern mehr aufsummierten HP-Verlust als der Graf oder König. Die Schwäche ist vor allem, wie leicht Denti sich durch gleichförmige Flucht entziehen kann.

## Hell: alle vier Bosse

Mittelwerte über drei feste Gesundheitsphasen und drei Startwinkel, jeweils 45 s. Kreisen mit 230 px/s und Zielabstand 320 px; schnelles Kreisen mit 299 px/s. Der Fluchtpilot steuert vom Boss weg und hält 0,6 s Platz zum Abdrehen an Wänden. Kein Pilot liest Warnungen oder Geschosse.

| Boss | Nah kreisen, 160 px | Kreisen, 320 px | Schnell kreisen | Flucht mit Wandkurven |
| --- | ---: | ---: | ---: | ---: |
| Graf, Welle 5 | 10,0 | 23,3 | 6,3 | 26,3 |
| Prinz, Welle 10 | 18,0 | 15,6 | 11,0 | 6,8 |
| König, Welle 15 | 17,1 | 22,9 | 30,0 | 8,1 |
| Imperator, Welle 20 | 12,2 | 15,2 | 10,1 | 3,4 |

Werte sind **Treffer je 45 s**, keine Siegquoten. Normale Treffer-Unverwundbarkeit bleibt aktiv und hängt auch vom Schaden ab. Der König bestraft schnelles Kreisen inzwischen deutlich; mehr Lauftempo allein ist dort kein verlässlicher Ausweg. Der Graf bindet den Fluchtpiloten besonders stark. Auch Prinz und König sind beim Weglaufen noch leichter zu entschärfen als der Graf, der Imperator am stärksten.

| Boss | Aufsummierter HP-Verlust beim normalen Kreisen | Beim Fluchtpiloten | Killzeit bei gesättigtem Test-DPS |
| --- | ---: | ---: | ---: |
| Graf | 924 | 1.043 | 18,1 s |
| Prinz | 660 | 410 | 20,7 s |
| König | 1.284 | 429 | 25,3 s |
| Imperator | 1.495 | 339 | 36,1 s |

Der HP-Verlust wird mit einer großen aktuellen HP-Reserve gezählt, nicht als Überlebensdauer einer Figur mit 100 HP. Maximalleben bleiben bei 100, damit die Treffer-Unverwundbarkeit stimmt. Killzeiten stammen aus getrennten Proben mit 1.000.000 rohen DPS, zehn Treffern/s, echten Schutz-/Rüstungsregeln und Gesundheitsphasen. Sie sind keine realen Run-Builds. Bei 1.000 DPS benötigt der Imperator auf Hell 42,3 s; bei 350 DPS ist er nach der 90-s-Messgrenze noch nicht besiegt.

## Warum der Imperator Druck verliert

1. **Hard und Hell erreichen dasselbe Wiederholungslimit.** Urteile, Portale und Nervenpulse sind jeweils auf drei begrenzt. Beide Stufen erreichen dieses Limit bereits früh. Hell bekommt mehr Strahlen, schnellere Geschosse und Bewegung, aber kaum zusätzlichen Takt. Gemessen werden beim normalen Kreisen auf beiden Stufen 23 Mechanikfreigaben je 45 s; Geschosse steigen von 230 auf 272.
2. **Zwischen den Folgen liegen mehrere getrennte Schritte.** Auf Hell folgen 1,25 s Kernöffnung, 0,22 s Erholung, 0,70 s Wachendrehung und 0,22 s Positionierung aufeinander: rund 2,39 s vor der nächsten Folge, deren eigene Warnung erst danach beginnt. Restgeschosse können weiter aktiv sein; diese Zeit ist deshalb nicht vollständig gefahrenfrei. Die separate Wachendrehung beansprucht beim normalen Kreisen im Mittel 3,5 von 45 s.
3. **Er zielt korrekt, legt sich aber lange fest.** Urteile beginnen innerhalb von 300 px, haben 390 px Reichweite und mindestens 1,05 s feste Warnung. Denti kann bei Basistempo in dieser Zeit etwa 242 px zurücklegen. Bei engem Kreisen liegt der Pilot bei Freigabe in 0 von 54 angekündigten Urteilen noch im Sektor, beim schnellen Kreisen in 6 von 54, beim Fluchtpiloten in 12 von 54. Das zählt die eigentlichen Urteilsfolgen; der zusätzliche Sektor beim ersten Nerventakt der letzten Phase ist darin nicht mitgezählt.
4. **Der Portalstich schneidet die alte Position.** Die Bahn wird ohne Bewegungsvorhalt durch Dentis Warnbeginn-Position gelegt, ungefähr quer zur Verbindung zum Imperator. Auch das Portal einer Urteilskombination wird sofort mit dem Urteil festgelegt. Nach 1,0 bzw. 1,4 s Warnung ist ein gleichförmig laufender Spieler häufig schon aus dieser Bahn heraus. Es fehlt ein Angriff, der die Ausweichbewegung anschließend neu abfängt.
5. **Die Nervenprojektile fangen radiale Flucht schlecht ab.** Auf Hell fliegen sie mit 288 px/s für höchstens 2,6 s; Denti läuft bereits 230 px/s. Aus bestehendem Abstand und nach der 1,05-s-Warnung genügt der kleine Geschwindigkeitsüberschuss häufig nicht zum Aufholen. Das ist eine Erklärung aus den Profilwerten, keine separat gemessene Trefferquote dieses Einzelangriffs.

Beim normalen Kreisen steht der Imperator im Mittel 35,6 von 45 s still. Stillstand allein ist jedoch kein Aggressivitätsmaß: Auch der König steht viel, hält mit seinen Bahnen und Geschossen aber gefährliche Flächen aktiv. Entscheidend sind die wirksamen Anschlussangriffe.

Quellen im Code: [Wiederholungen und Zeiten](../scripts/enemies/crown_court_data.gd), [Annähern, feste Zielerfassung und Portalplanung](../scripts/enemies/crown_court_encounter.gd), [Nervenprojektile](../data/encounters/emperor_shots.tres).

## Schwierigkeitsskalierung im Vergleich

Dieselbe normale Kreisbewegung, Treffer je 45 s:

| Boss | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Graf | 12,9 | 9,9 | 13,0 | 23,3 |
| Prinz | 4,8 | 5,4 | 14,0 | 15,6 |
| König | 3,0 | 7,4 | 6,8 | 22,9 |
| Imperator | 2,3 | 5,0 | 6,4 | 15,2 |

Die Trefferkurven einzelner Piloten sind nicht überall monoton. Beim Grafen funktioniert dieses Muster auf Normal besser als auf Easy; beim König auf Hard etwas besser als auf Normal. Anzahl und Tempo der Mechaniken steigen trotzdem. Hier sind bei späterer Feinabstimmung mehrere Bewegungsarten gemeinsam zu prüfen, statt eine einzige Kreisbahn auf einen Zielwert zu trimmen.

Beim Imperator sind Schadens-/Geschossskalierung wirksam, die Wiederholungszahlen von Hard zu Hell stagnieren jedoch. Das ist der konkrete Ansatzpunkt für ein aktiveres Hell-Profil.

## Empfohlene nächste Änderung

1. **Ausweichen abfangen:** Auf ein Urteil folgt ein erneut auf Denti ausgerichteter Portal-/Lanzenangriff. Ein begrenzter Bewegungsvorhalt soll den Fluchtweg schneiden. Die neue Warnung erhält ihre eigene feste Geometrie und vollständige Reaktionszeit; kein nachträgliches Nachziehen sichtbarer Bahnen.
2. **Wache beim Nachsetzen drehen:** Die angekündigte Wachendrehung mit einer vorhandenen Bewegungs-/Erholungsphase verbinden, statt dafür einen weiteren stehenden Schritt anzuhängen. Das Kernfenster als Gelegenheit zum Gegenangriff erhalten.
3. **Hell bekommt eine zusätzliche Wiederholung:** Mit gezielterem Anschluss prüfen, ob Urteile/Portale/Nerventakt auf Hell vier statt drei Wiederholungen brauchen. Easy behält weniger Angriffe, Hard bleibt die Zwischenstufe. Wiederholungszahl allein behebt die vorhersehbaren Portalbahnen nicht.

Zuerst den Anschlussangriff und den zusätzlichen Dreh-Leerlauf bearbeiten, anschließend mit derselben Messung nachprüfen. Weiterhin höchstens zwei gleichzeitig kombinierte Hauptmechaniken, vollständige Warnungen und verlangsamte Ausweichrouten an allen Ecken/Ansichtsformaten. Mehr HP oder pauschal mehr Schaden sind für diesen Befund kein passender erster Schritt.

## Methode und Prüfung

[Komplette Rohdaten](boss_audit_2026_10_31.json), erzeugt mit Godot 4.7.2 und [benchmark_boss_comparison.gd](../tools/benchmark_boss_comparison.gd):

- 720 Druckproben: vier Bosse an ihren normalen Bosswellen, vier Schwierigkeiten, drei feste Gesundheitsphasen, drei Startwinkel, fünf Bewegungsstrategien, jeweils 45 s bei 60 Hz.
- 80 getrennte Kampfdauerproben mit 120 / 350 / 1.000 / 3.000 / 1.000.000 rohen DPS. Nicht besiegte Bosse werden bei 90 s abgebrochen, nicht als Kill verbucht.
- Keine Spielerwaffen, Rüstung, Heilung, Schilde, Dodge oder Dash; keine Adds, normalen Gegner oder Overtime. Umgebungsverlangsamung, echte Körper-/Hazardkollision und normale Treffer-Unverwundbarkeit bleiben aktiv. Gerade die Adds können den vollständigen Imperatorkampf zusätzlich gefährlich machen.
- Schema 2 ergänzt Zustandszeiten, Angriffswarnungen ohne reine Wachendrehung, reale Imperator-Freigabezähler, Urteilsabdeckung und den Fluchtpiloten. Prinzenbomben werden beim Projektilzähler separat von Herzen erfasst; eine Bombe zählt beim Angriffstakt beim Einschlag, nicht zusätzlich schon beim Abwurf. Mechanikfreigaben sind keine Treffer oder vergleichbar großen Angriffe: Eine Stampfreihe zählt einzeln, ein zusätzlicher Portalstich ebenfalls.
- Alle Zeitbilanzen und Freigabezähler geprüft. 144 unveränderte Königsproben reproduzieren die vorherige Königsmessung exakt bei Treffern und HP-Verlust.
- 5/5 bestehende Testskripte bestanden: `crown_court_encounter`, `crown_court_positioning`, `crown_court_routes`, `boss_difficulty_pressure`, `boss_pressure`. Einschließlich korrekter Zielerfassung, Annähern, festen Warnungen, Ausweichrouten und Speichern/Fortsetzen.

Reproduktion mit isoliertem Nutzerdatenordner: Godot mit `--headless --path . --script tools/benchmark_boss_comparison.gd -- --extended --output=res://docs/boss_audit_2026_10_31.json` starten. Unter Windows dafür APPDATA ausschließlich im gestarteten Prozess auf einen Testordner setzen; siehe bestehendes Testwerkzeug.
