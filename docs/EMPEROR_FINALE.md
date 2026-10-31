# Imperator: Ausbau zum Finalboss

Stand: 31.10.2026. Umsetzung nach der [Bossprüfung](BOSS_AUDIT.md). Der Ausbau verändert Angriffsmuster, Annähern und Takt. Basisleben (2.000), Rüstung, Grundschaden, Schutzbudget und Gesundheitspausen bleiben auf dem bisherigen Stand.

## Neue Angriffsfolge

**Hofurteile → neu gezielter Portalstich → Nerventakt.** Die Kombination beginnt wie bisher auf Easy in der letzten Gesundheitsphase, auf Normal ab der zweiten und auf Hard/Hell bereits in der ersten. Eigenständige Portal- und Nervenfolgen bleiben im Repertoire.

- Der Imperator nähert sich für seine Urteile auf einen Zielabstand von 240 px. Eine Warnung beginnt innerhalb von höchstens 260 px. Während einer sichtbaren Warnung bleiben Ursprung und Winkel fest.
- Das erste Urteil warnt 1,05 s, Folgeurteile 0,90 s. Beide angekündigten Sektoren geben schnelle, weitreichende Kronenlanzen ab. Die verlängerten Flugrichtungen werden zusätzlich zur Bodenfläche angekündigt. Einfach radial aus der 390-px-AoE zu laufen genügt deshalb häufig nicht mehr.
- Nach der letzten Urteilfreigabe erfasst der Portalstich Dentis aktuelle Position und Bewegungsrichtung neu. Vorhalt berücksichtigt seine eigene volle 1-s-Warnung und die Flugzeit bis zur Bahnmitte; die Vorhaltdistanz ist nach Schwierigkeit begrenzt. Die neue Bahn bleibt danach fest. Der Spieler kann seine Laufrichtung ändern und die Ankündigung gezielt ausspielen.
- Im Nerventakt wechseln **Geschossring + gezielter schneller Fächer** mit **reinen Geschossringen**. Der gemischte Puls warnt 1,20 s, der reine Ring 1,05 s. Die alte zusätzliche sofort schädigende Boden-AoE entfällt in neuen Nervensequenzen. Dadurch bleiben die engen langsamen Ausweichwege möglich.
- In der letzten Gesundheitsphase wachsen die Ringe um vier Geschosse. Auf Hell stehen nun vier Wiederholungen zur Verfügung.
- Während der Kernöffnung bleibt die erste Atempause von 0,25 s erhalten. Danach dreht der Imperator seine Wache innerhalb von 0,70 s, während er bereits nachsetzt und weiter verwundbar ist. Die Kernöffnung dauert weiterhin 1,25 s. Die zusätzliche stehende Drehphase nach der Erholung entfällt.

Die Begrenzung auf zwei kombinierte Hauptmechaniken bleibt erhalten: Urteilfläche mit angekündigten Lanzen; Portal als neu angekündigter Anschluss; im Nerventakt Ring und gezielter Fächer. Der Portalanschluss wird nicht mehr gleichzeitig mit dem letzten Urteil auf eine inzwischen alte Spielerposition festgelegt.

## Schwierigkeit

| Wert | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Urteile / Portalstiche, erste Phasen | 1 | 2 | 3 | 4 |
| Urteile / Portalstiche, letzte Phase | 2 | 3 | 3 | 4 |
| Nervenpulse, erste / spätere Phasen | 1 / 2 | 2 / 3 | 3 / 3 | 4 / 4 |
| Strahlen je normalem Ring, erste / letzte Phase | 10 / 14 | 12 / 16 | 14 / 18 | 16 / 20 |
| Schnelle Lanzen je Urteilsektor | 3 | 5 | 7 | 9 |
| Lanzen je gezieltem Nervenfächer | 3 | 5 | 7 | 7 |
| Tempo der schnellen Lanzen, px/s | 504 | 560 | 627,2 | 716,8 |
| Höchster Portalvorhalt, px | 81 | 180 | 279 | 378 |

Die Nervenfächer bleiben auf sieben Lanzen begrenzt, damit ihre Kombination mit dem dichten Ring ausweichbar bleibt. Hell erhöht dort Tempo, Ringdichte und die Zahl der Pulse. Die Reaktionszeiten werden zwischen den Schwierigkeiten nicht verkürzt. Vorhandene skalierte Bewegung und Erholungszeiten gelten weiter.

Schnelle Lanzen leben maximal 1,8 s, haben Kollisionsradius 8 px und verursachen 32 % des Grundangriffsschadens. Sie ersetzen bei neuen Urteilen die bisherigen langsameren Splitter mit 38 % Schaden pro Projektil. Es gibt keine Zielverfolgung nach Warnbeginn.

## Gemessene Wirkung auf Hell

Jeweils 45 s, Mittel über drei Gesundheitsphasen und drei Startwinkel. Keine Waffen, Adds oder Warnungsreaktion; normale Treffer-Unverwundbarkeit. [Vorher](boss_audit_2026_10_31.json), [aktueller Imperator](emperor_final_pressure.json), [Vergleich mit allen Bossen](emperor_final_after.json).

| Bewegung | Treffer vorher → nachher | Aufsummierter HP-Verlust vorher → nachher |
| --- | ---: | ---: |
| Stehen | 23,1 → 25,1 | 2.463 → 2.594 |
| Nah kreisen, 160 px | 12,2 → 11,8 | 937 → 963 |
| Kreisen, 320 px | 15,2 → 17,8 | 1.495 → 1.647 |
| Schnell kreisen, +30 % Tempo | 10,1 → 14,0 | 865 → 1.169 |
| Vom Boss fliehen und an Wänden abdrehen | 3,4 → 8,9 | 339 → 830 |

Der Fluchtpilot wird etwa **2,6-mal so häufig** getroffen. Schnelles Kreisen kassiert etwa 39 % mehr Treffer. Enges Kreisen bleibt ähnlich wirksam; der Ausbau soll nicht jede mögliche Route gleich schlecht machen. Diese Proben sind keine menschlichen Siegquoten.

Der aktuelle Vergleich zeigt unterschiedliche Stärken:

| Hell, Treffer / 45 s | Kreisen | Schnell kreisen | Fluchtpilot |
| --- | ---: | ---: | ---: |
| Graf | 23,3 | 6,3 | 26,3 |
| Prinz | 15,6 | 11,0 | 6,8 |
| König | 22,9 | 30,0 | 8,1 |
| Imperator | 17,8 | 14,0 | 8,9 |

Die Treffer sind unterschiedlich stark. Beim normalen Kreisen verliert der Testspieler gegen den Imperator 1.647 HP, gegen den König 1.284 und gegen den Grafen 924. Der König bleibt besonders gegen schnelles Kreisen gefährlich; der Graf zwingt den Fluchtpiloten weiter am häufigsten zum Umdenken. Der Imperator verbindet seinen höheren Trefferschaden und Schutz mit wirksameren Anschlussangriffen, statt nur längere Zeit mehr HP vorzuhalten.

Auf Easy / Normal / Hard / Hell steigen die Imperator-Treffer beim normalen Kreisen auf **3,0 / 6,7 / 11,7 / 17,8**, beim Fluchtpiloten auf **3,4 / 4,8 / 7,3 / 8,9**. Die neue Fassung skaliert damit in diesen Proben auch beim Bewegungsdruck durchgehend.

Die Killzeit bei gesättigten Test-DPS bleibt auf Hell bei etwa **36,1 s**. Mit 1.000 rohen DPS dauert die Probe 44,3 statt 42,3 s; längere Folgen verändern den Anteil der offenen Kernfenster. Die getrennten Proben bei 120 und 350 DPS erreichen die 90-s-Messgrenze ohne Sieg. Schutzbudget und HP wurden nicht erhöht.

## Lesbarkeit und Laufzeit

Die neuen Richtungen verwenden den vorhandenen analytisch geglätteten Warnungsrenderer. Keine neuen Kreise an Bahnenden. Grafik und Projektiltextur kommen aus dem bestehenden Imperator-Atlas. Ein zusätzlicher begrenzter Projektilbatch übernimmt die schnellen Lanzen; es entsteht kein Node pro Geschoss.

Grenzen je Imperator: 160 langsame Geschosse, 8 Portal-Lanzen, 48 schnelle Lanzen. In den Hell-Proben waren höchstens **47 Geschosse gleichzeitig aktiv**, vorher 40. Das ist eine gemessene Belegungsgrenze der Proben, kein FPS-Versprechen. Doppel-Imperatoren berücksichtigen auch die neuen Lanzen bei der Reservierung ihrer Angriffsfolgen.

[Urteilswarnung](screenshots/emperor_final/edict_1280.png) · [neu gezielter Anschluss](screenshots/emperor_final/intercept_1280.png) · [Nerventakt](screenshots/emperor_final/nerve_1280.png) · [Freigabe](screenshots/emperor_final/release_1280.png) · [überlappende Wachendrehung](screenshots/emperor_final/guard_1280.png)

## Speichern und Prüfung

Speicherversion 2 ergänzt den Portalanschluss, die laufende Wachendrehung sowie angekündigte und fliegende schnelle Lanzen. Version-1-Spielstände behalten ihre bereits angekündigte alte Kombination bis zum Ende der laufenden Folge. Neue Abläufe beginnen erst danach. Phasenwechsel und Tod räumen alle drei Projektilbatches, Nervenrichtungen und die Wachenbewegung auf.

Abschließend **11/11 Testskripte bestanden**, einschließlich:

- 144 vollständiger Urteils-/Portal-/Nervenketten: vier Schwierigkeiten, vier Ecken, drei Ansichtsformate, 72 % Basistempo, echte Trefferprüfung und Körperabstand. Jede neue Warnung und Neupositionierung erlaubt eine neue Bewegungsentscheidung; Geschossreste werden mitgeprüft.
- Zusätzlicher Prüfung des ersten Ereignisses, alter Urteil-/Portal-Kombinationen, tatsächlicher neuer Anschlussangriffe bei maximalem Test-DPS sowie des Endlos-Ablaufs.
- Fester vollständiger Warnungen, des Vorhalts, korrekter Projektilgeburt in langen Frames, Ressourcenisolation, Snapshot und echtem Fortsetzen, v1-Migration sowie Abbruch bei Phase/Tod.
- 15 nativen Screenshots in 1280×720, 320×568 und 568×320 mit geprüfter eingefrorener Pausengeometrie. Godot-Import ohne Skriptfehler.

Testbericht: `.godot/test_runs/20261031-142850-8b0a14b4/`.

Die abschließende Imperatormessung enthält 180 Druck- und 20 Kampfdauerproben. Der zusammengeführte Bossvergleich enthält zusätzlich 540 unveränderte Vergleichsproben und 60 Kampfdauerproben der übrigen Bosse. Alle 540 Druckproben wurden im vorhergehenden vollständigen Lauf bei Treffern, HP-Verlust, Projektilezahl, Freigaben und Spitzenbelegung exakt reproduziert. Die Herkunft ist im JSON vermerkt.

Werkzeuge: [Benchmark](../tools/benchmark_boss_comparison.gd), [native Vorschau](../tools/preview_emperor_final.gd). Für einen Einzelvergleich `--emperor-only --extended` verwenden und den Nutzerdatenordner wie beim bestehenden Testwerkzeug isolieren.
