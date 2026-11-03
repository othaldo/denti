# Bossstages und Aufgabenphasen

Spielbarer Prototyp, aktualisiert am 03.11.2026. Alle Bosswellen sind eigene Encounter ohne
normalen Spawnstrom, Horden, Zufallseliten oder recycelte Phasenverstärkung.
Beschworene Gegner müssen eigene, bossbezogene Rollen und Grafiken besitzen.
Der Graf bleibt zunächst ein Duell. Prinz, König und Imperator besitzen eigene
Aufgaben, die nach Schwierigkeit aufeinander aufbauen. Das Kronengericht des
Imperators wird durch drei eigene Vasallenrollen ergänzt.

## Direkt testspielen

Im Projektordner unter PowerShell:

```powershell
.\tools\play_boss_stage.ps1
```

Der Start zeigt jetzt den vollständigen Prinzenkampf von Beginn an und pausiert.
**Weiter** startet den Kampf. Maus/Tastatur oder Controller funktionieren wie
im normalen Spiel. **F4** öffnet das vorhandene Testmenü für Build und Wellen;
Welle 10 startet dort den vollständigen Prinzenkampf mit dem aktuellen Build.
Unter **Run → Schwierigkeit** stehen Easy, Normal, Hard und Hell zur Wahl.
**Starten** übernimmt Welle und Schwierigkeit gemeinsam, behält den Build und
startet mit vollem Leben. Welle 15 auf Hell zeigt die drei Königsschilde.

```powershell
.\tools\play_boss_stage.ps1 -Trial
.\tools\play_boss_stage.ps1 -Build melee_single
.\tools\play_boss_stage.ps1 -Build melee_area -Difficulty hard
.\tools\play_boss_stage.ps1 -Boss king -Difficulty hell
.\tools\play_boss_stage.ps1 -Boss king -Trial
.\tools\play_boss_stage.ps1 -Boss emperor -Difficulty hell
.\tools\play_boss_stage.ps1 -Boss emperor -Trial
```

Zur Auswahl stehen `count`, `prince`, `king`, `emperor` und die Builds
`ranged_single`, `melee_single`, `melee_area`, `uv_floss`. Der Launcher legt
alle Spielstände, Einstellungen und Account-Fortschritte getrennt unter
`.godot/boss_stage_playtest/userdata/` ab. Normaler Spielstand und Account
werden nicht für diese Testläufe verwendet. Godot wird vor dem Start importiert.

## Abschluss ohne Wellentimer

Der Tod des letzten Bosses beendet die Stage nach seiner Todesanimation.
Bosswellen haben keinen laufenden Wellentimer und keine zeitgesteuerte
Entzündung. Im normalen Bosskampf zeigt das HUD keine Zeit. Kurze Warnungen
und Aufgabenfristen innerhalb einer Spezialattacke bleiben bestehen.
Verschwindet der letzte Boss ohne seine übliche Abschlussmeldung, führt die
Wellensteuerung ebenfalls Sammlung und Auszahlung aus.

Danach: Gefahren entfernen, Beute einsammeln, anstehende Level-/Kapsel-/Relikt-
Entscheidungen auflösen, Shop beziehungsweise Sieg. Bei zwei Endlosbossen
beginnen Sammlung und Auszahlung erst nach dem letzten Boss; das Budget ist
einmal pro Stage verfügbar.

## Prinz: Karamell-Katastrophe

Der Kampf beginnt mit dem normalen Repertoire aus Bomben, Herzfächern und
Zuckerrausch. Erst danach kommen die Prüfungen. Auf Normal lernt Denti bei
50 % Bossleben zunächst zwei schießende Herzen kennen. Im letzten Drittel
folgen vier Herzen, breitere Salven und gezielt angekündigte Karamellbahnen.

| Schwierigkeit | Prüfungen | Staffelung |
| --- | ---: | --- |
| Easy | 1 | Vier Herzen im letzten Drittel; einzelne Herzgeschosse |
| Normal | 2 | Zwei Herzen bei 50 %, danach vier Herzen mit Dreierfächern und Karamellbahnen |
| Hard | 3 | Drei Herzboten bei 2/3 Leben abfangen, zwei Herzen bei 50 %, vier Herzen mit Fünferfächern im letzten Drittel |
| Hell | 3 | Dieselben drei Aufgaben; schnellere Herzboten, kürzere Salvenpausen, größere Fächer bis sieben Geschosse |

Die Herzboten sind eigene bewegliche Bossziele: Sie hüpfen zum Kessel,
bleiben für ihre angekündigten Salven kurz stehen und können auf dem Weg
abgefangen werden. Durchgekommene Boten verstärken den anschließenden Angriff.
Die Herzgrafik kommt aus dem vorhandenen Prinzen-Atlas; normale Wellengegner
werden nicht als Platzhalter verwendet. Alle Ziele behalten 32 Basisleben;
mehr Prüfungen und Druck kommen aus Verhalten und Abfolge.

- Ein Herz öffnet sich in Dentis Nähe. Der Ring wechselt von Blau zu Gold;
  automatische Waffen wählen offene Herzen und ignorieren den immunen Boss.
  Alle normalen Waffen und Verzauberungen verwenden ihren bestehenden Trefferpfad.
- Jedes Herz kündigt eigene gezielte Salven an. Seine Zerstörung entfernt auch
  seine fliegenden Geschosse und verschafft unmittelbar Luft für den nächsten Weg.
- In der Abschlussprüfung durchqueren zusätzlich angekündigte Karamellbahnen
  die Arena. Ihre Richtung zielt einmal auf Dentis Position und bleibt danach
  fest. Die Vorwarnung bleibt eine volle Sekunde; Herzsalven warnen je nach
  Schwierigkeit 0,85–0,95 s.
- Das Zeitbudget berücksichtigt den Umfang der Zielanordnung, Dentis Bewegung
  und eine Schadens-/Reaktionsreserve: ungefähr 20 s auf Desktop mit Grundtempo,
  für die Abschlussprüfung mindestens 18 und höchstens 40 s. Kleinere Prüfungen
  erhalten ein anteiliges Zeitbudget. Keine Dash- oder Tempo-Investition ist Pflicht.
- Alle Ziele einer Prüfung abzufangen beziehungsweise zu zerstören bricht das Ritual sofort ab. Der Prinz bleibt bis zu vier
  Sekunden stehen und nimmt 75 % zusätzlichen Schaden; sein normaler
  Schadensbudget-Schutz greift in diesem Fenster nicht.
- Beim Fehlschlag folgt eine weitere sichtbare Vorwarnung. Je verbliebenem Herz
  entstehen vier zusätzliche Geschosse im anschließenden Ring. Danach endet die
  Immunität und der reguläre Kampf geht weiter. Kein erzwungener Soforttod und
  keine endlose Wiederholung derselben Aufgabe. Erledigte Prüfungen bleiben erledigt.
- Zielpositionen und Öffnungsradius berücksichtigen das Bildschirmformat und
  halten die Herzen vom HUD fern. Stationäre Herzen bleiben fest; die Herzboten
  bewegen sich zum Kessel und halten für ihre Vorwarnungen an.

Warnungen, Frist, Ziel-Leben, Besitzer-/Slotverknüpfung, einzelne Salven,
Herzbotenbewegung, abgeschlossene Prüfungen, Erfolg/Fehlschlag und das
Angriffsfenster werden gespeichert. Ältere gespeicherte Ritualfassungen erhalten
keine nachträglichen früheren Prüfungen und keine überraschenden neuen Salven. Vor Version 4 gespeicherte Prinzenkämpfe,
die bereits das letzte Drittel erreicht haben, erhalten kein nachträgliches Ritual.

## König: Säureschild und Strahlumlenkung

Die Schildphase prüft Positionierung: Denti stellt sich zwischen den König und
ein Ventil. Der Strahl folgt zunächst, rastet orange ein und feuert erst nach
der festen Vorwarnung. Jetzt seitlich ausweichen. Der eigene Strahl des Königs
zerstört das Ventil; automatische Waffen können diese Aufgabe nicht abkürzen.
Die Bodenmarkierungen zeigen passende Zielpositionen. Ventile sind eigene
Schildobjekte mit bemalter König-Grafik und erzeugen keine Minion-Kills/Beute.

| Schwierigkeit | Restleben beim Schildaufbau | Ventile pro Prüfung |
| --- | --- | --- |
| Easy | 2/3 | 2 |
| Normal | 2/3 | 3 |
| Hard | 80 %, 40 % | 3, 4 |
| Hell | 90 %, 60 %, 30 % | 2, 3, 4 |

Die sichtbare gläserne Schildhülle hat ein Segment pro Ventil. Zerstörte Ventile
löschen Segmente und lassen Risse zurück; nach dem letzten Ventil platzt die
Hülle. Lebensschwellen begrenzen auch sehr große Treffer, sodass keine Prüfung
übersprungen wird. Zwischen den Prüfungen kämpft der König regulär weiter.

- Die orange Warnung bleibt je nach Schwierigkeit 0,75–1,0 s fest. Auch mit
  minimalem Bewegungstempo kann Denti ohne Dash aus der Strahlbreite laufen.
  Der Strahl durchdringt Ventile; dahinter stehen bleiben bietet keine Deckung.
- Ein Schildbruch verursacht 4 % Rückschlag und öffnet bis zu vier Sekunden
  Gegenangriff mit Faktor 1,8 ohne Rüstung. Das Fenster erlaubt zusätzlich
  höchstens 8 % Bossleben als Waffenschaden und endet sofort, wenn dieses
  Budget verbraucht ist. Danach beginnt wieder normaler Kampf mit leerem
  Burstbudget. Große Treffer springen dadurch nicht in die nächste Prüfung.
- Nach drei zusätzlichen Fehlversuchen kündigt der König einen Säurering an;
  verbliebene Ventile verstärken ihn. Danach endet die Immunität und der Kampf
  geht weiter. Die erledigte Prüfung wiederholt sich nicht endlos.
- Mehr Abwehr zwischen den Öffnungen: Basisrüstung 18 → 32 %, geschlossener
  Panzer nimmt Faktor 0,55 statt 0,85; das normale Schadensbudget lädt in 60
  statt 28 s und speichert höchstens 4 statt 10 % des Bosslebens als Burst.
  Die Basis-HP bleiben bei 900. Schwierigkeiten skalieren weiter
  nach den vorhandenen Regeln.
- In großen Fenstern folgt die Kamera Denti auch während der Aufgabe; es gibt
  keinen sprunghaften Wechsel der Perspektive. Kleine Fenster erhalten während
  der Aufgabe einen Überblick über die gesamte Anordnung.

Prüfungsfortschritt, gebrochene Ventile, eingerasteter Strahl und verbleibende
Warn-/Öffnungszeiten bleiben bei Pause und Save/Resume erhalten. Vor Einführung
der Aufgabenphase gespeicherte Königskämpfe erhalten keine neue Prüfung mitten
im laufenden Angriff. Die erste gespeicherte Ein-Prüfungs-Fassung läuft ohne
nachträglich eingeschobene Schilde weiter.

Die Steinwelle besitzt keinen festen Nahkampf-Blindfleck mehr. Steht Denti beim
Ankündigen näher als 180 Einheiten, beginnt die Attacke mit einem runden
Nahbereichsstampf (Radius 145). Enges Umkreisen reicht nicht: Denti muss kurz
Abstand gewinnen. Danach folgen die nach außen breiter werdenden Steinreihen.

| Schwierigkeit | Einzelner Nahstampf | Fernwelle | Nah-Kombination mit Säurerinne |
| --- | ---: | ---: | ---: |
| Easy | 1,10 s | 1,10 s | 1,35 s |
| Normal | 0,85 s | 1,05 s | 1,15 s |
| Hard | 0,72 s | 1,00 s | 1,00 s |
| Hell | 0,60 s | 0,90 s | 0,90 s |

Breite Fernwellen in Kombination mit einer Säurerinne behalten 1,4 s Vorwarnung.
Alle Zeiten sind feste Vorwarnungen. Der Nahstampf lässt kurz Luft vor den
äußeren Reihen; bei einer Kombination läuft eine Säurerinne vor dem Einschlag
aus. Nahe Splitterfächer sperren den angekündigten Ausweg nicht wieder zu.
Einschläge verfolgen Denti nach der Warnung nicht. Geometrie, Trefferstatus und
verbleibende Warnzeiten bleiben beim Speichern/Laden erhalten; ein älterer
angekündigter Stomp wird durch die neuen Zeiten nicht verkürzt.

## Imperator: Kronenvasallen und aufgeladenes Urteil

Der Imperator ruft eigene kleine Minibosse, schützt sich während der Aufladung
und greift mit angekündigten Salven weiter an. Diese Gegner verwenden drei neue
gemalte Grafiken und eigene Verhaltensweisen; sie sind keine Wellengegner.

| Vasall | Rolle |
| --- | --- |
| Kronenlanze | Nähert sich, kündigt einen festen Lanzenvorstoß an und erholt sich danach |
| Siegelhüter | Schießt feste Fächer und hält die begrenzte Regeneration des Imperators aufrecht |
| Reichsrichter | Markiert eine Einschlagstelle, springt dorthin und erholt sich nach dem Hammerschlag |

| Schwierigkeit | Restleben beim Ruf | Vasallen je Ruf |
| --- | --- | ---: |
| Easy | 50 % | 2 |
| Normal | 70 %, 30 % | 2 |
| Hard | 80 %, 50 %, 20 % | 3 |
| Hell | 85 %, 55 %, 25 % | 3 |

Die Vasallen haben eigene Lebensleisten und begrenzte Burstbudgets. Ein extrem
starker Treffer kann sie nicht sofort entfernen. Während ihrer Auftritte gibt
es keinen normalen Spawnstrom. Den Siegelhüter zuerst zu besiegen stoppt die
Heilung unmittelbar; insgesamt kann der Imperator pro Ruf höchstens 4 % seines
Maximallebens regenerieren. Er erhöht dabei nicht seine maximalen HP.

Alle Vasallen vor Ende der Aufladung zu besiegen unterbricht das Urteil und
öffnet bis zu vier Sekunden Gegenangriff mit Faktor 1,65 ohne Rüstung. Ein
eigenes Budget von 8 % Bossleben begrenzt dieses Fenster; danach ist das normale
Burstbudget leer. Kommende Rufe bleiben an ihren Lebensschwellen geschützt.
Zwischen den Rufen läuft das normale Kronengericht weiter.

Die Aufladung dauert 24 s mit zwei und 30 s mit drei Vasallen. Ihr Ablauf wird
als Ring am Imperator angezeigt, nicht als Wellentimer. Bleiben Gegner übrig,
kündigt er seinen verstärkten Ringangriff noch einmal an, verliert anschließend
seine Immunität und kämpft mit den überlebenden Vasallen weiter. Kein erzwungener
Soforttod und keine dauerhafte Unverwundbarkeit. Spätestens beim Tod des
Imperators verschwinden seine Vasallen und ihre Gefahren.

Vasallen erzeugen keine zusätzlichen XP-/Münz-/Kapseldrops; das feste Budget
bleibt pro Bossstage erhalten. Reguläre Kill-Synergien funktionieren wie bei den
Prinz-Zielen. Speichern/Fortsetzen bewahrt Besitzer, Zielpositionen, Aufladung,
Heilbudget, Miniboss-Leben und Burstbudget. Alte Kronengericht-Spielstände
erhalten keine unangekündigten neuen Vasallen mitten im bestehenden Angriff.

Die Originalgrafiken und das Promptset liegen unter
`assets/enemies/imperial_vassals/`. Sie wurden mit dem eingebauten Imagegen und
dem Imperator-Porträt als Stilreferenz erzeugt. Die PNG-Originale bleiben mit
Alpha erhalten; Godot importiert sie mit Mipmaps und 512-Pixel-Limit für die
kleine Darstellung. Die erste native Vorschau liegt unter
`.godot/imperial_retinue_preview/` in Desktop-, Hoch- und Querformat.

## Beute: vorläufige Startwerte

| Stage | Basis-XP | Basis-Münzen | Upgrade-Kapseln |
| --- | ---: | ---: | ---: |
| W5 / Graf | 30 | 32 | 1 |
| W10 / Prinz | 45 | 55 | 2 |
| W15 / König | 55 | 70 | 2 |
| W20 und Endlosbossstage | 65 | 85 | 2 |

Die Werte stehen in vier `BossStageRewardData`-Resources. Jeder der ersten beiden
Lebensphasenwechsel kann einmal ungefähr 10 % der XP als sammelbaren Splitter
freigeben, damit XP-Heilung im Kampf nutzbar bleibt. Der Rest fällt beim Sieg.
Diese Anteile und die Minions erzeugen kein zusätzliches Zufallsbeutebudget.
Kill-Effekte der Items können bei echten Herzen-Kills regulär auslösen.

Münzen fallen in Einer-/Zweier-Drops; ungefähr die Hälfte des Grundwerts steckt
in Zweier-Drops. Goldsonde/Goldextraktor wirken beim Erzeugen des Drops,
Münz-/XP-Sammelboni beim Einsammeln. Der bestehende Glücksbonus auf Upgradepunkte
wird anschließend einmal aufgelöst. Reliktregeln und Zinsen bleiben erhalten.
Gespeicherte Auszahlung und XP-Anteile verhindern Doppelbelohnungen. Alte Saves
ohne Bossbudget erhalten nur eine Auffüllung nach bereits gesammelter/liegender
Beute; verdiente Belohnungen werden nicht entfernt.

Diese Budgets sind **keine abgeschlossene Economy-Abnahme**. Acht diagnostische
Vergleichskämpfe vor dem Umbau ergaben inklusive liegender Beute 20–61 XP und
27–77 Münzen, abhängig von Stage, Build und Überlebensdauer. Sieben der acht
starren Orbit-Piloten starben; die Daten belegen keine normale Kaufhistorie.
Vollständige menschliche Runs müssen Kaufkraft und Levelkurve nach dem Umbau prüfen.
Kill-basierte Builds verlieren während der Duelle Auslöser; weitere passende
Minions oder gezielte Item-Anpassungen sind eigene nächste Spieltestschritte.

## Prüfung

Der Runner enthält **172 Kernprüfungen**. Native Aufnahmen wurden bei 1280×720, 320×568
und 568×320 geprüft. [Vorher-/Nachher-Messungen](boss_stage_measurements.json)
enthalten die diagnostischen Bedingungen und ihre Grenzen.

`tests/boss_stages.gd` prüft Spawnfreiheit auf allen Schwierigkeiten, frühes Ende,
Doppelbosse, festes Budget, Legacy-Auffüllung, Belohnungsreihenfolge, Aufgaben-
Erfolg/Fehlschlag, automatische Zielabfragen, Pause und echtes Save/Resume.
`tests/caramel_overload_combat.gd` lässt reale Nah-, Fern- und Flächenwaffen mit
normaler Spielerphysik die vier Ziele angreifen, zusätzlich mit -60 % Bewegung.
Auch echte automatische Fernwaffen fangen auf Hard und Hell Herzboten ab.
`tests/caramel_trials.gd` prüft die komplette 1/2/3/3-Abfolge, nicht überspringbare
Lebensschwellen, zerstörbare Salvenquellen, durchgekommene Boten und Save/Resume
nach einem teilweise abgeschlossenen Ritual.
Die Messung schreibt `.godot/caramel_overload_combat.json`. Das stark erhöhte
Leben dient der Erreichbarkeitsprüfung, nicht der Überlebensbalance.

```powershell
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script res://tools/preview_boss_stage.gd
```

Die native Vorschau schreibt Desktop-, Hoch- und Querformat, Lernprüfung, Herzboten sowie das
Erfolgsfenster nach `.godot/boss_stage_preview/`. Diese Ansichten sind arrangierte
Testszenen. `tools/preview_king_pressure.gd` schreibt den König mit eingerastetem
Strahl, aktivem Strahl und Schildbruch nach `.godot/king_pressure_preview/`.
Ein separates Imperator-Siegelritual ist nicht umgesetzt; seine neue Aufgabe
verwendet die Kronenvasallen während der Aufladung und Regeneration.

`tools/measure_caramel_phases.gd` misst zusätzlich vollständige Kämpfe mit zwei
synthetischen Tier-II-Builds und einem Piloten ohne Reaktion auf Gefahren.
Die Normal-Stichprobe erreicht die erste Aufgabe nach ungefähr 10–11 s und
endet nach ungefähr 22–24 s; Hard/Hell durchlaufen alle drei Prüfungen.
Das erhöhte Testleben macht diese Messung ausdrücklich nicht zum Nachweis
menschlicher Überlebensbalance oder Spaß. Der direkte Spieltest entscheidet,
ob die Lernfolge genügend Zeit und Abwechslung bietet.

`tests/king_pressure_trial.gd` prüft die vollständige Hell-Abfolge bei 90/60/30 %,
nicht überspringbare Schwellen, Immunität, Rückschlag, rüstungsfreie Öffnungen,
Warnungen, Fehlschlag und Save/Resume mitten in wiederholten Schilden.
`tests/king_pressure_combat.gd` bewegt Denti mit echter Spielerphysik ohne Dash
durch alle Hell-Prüfungen, auch mit Minimaltempo und in kleinen Fenstern.
Alle zehn Routen waren ohne Strahltreffer lösbar. Das prüft Erreichbarkeit,
nicht die menschliche Schwierigkeit.

`tools/measure_king_phases.gd` vergleicht die vorherige und neue Abwehr bei
identischen Schildregeln und synthetischen Tier-III-Nah-/Fernkampf-Builds.
Mit denselben neuen Öffnungsregeln steigt Normal in dieser Stichprobe von rund
36 auf 64 s, Hell von 51–52 auf 70–71 s. Zwischen den Hell-Öffnungen und dem
nächsten Schild liegen 10,8–11,6 s normaler Kampf. Alle Hell-Kämpfe zeigen drei
Schilde; die HP bleiben im Paarvergleich gleich. Der Pilot reagiert auf die
Strahlprüfung, aber nicht auf normale
Bossgefahren. Sein stark erhöhtes Leben macht diese Messung nicht zur
Überlebens- oder Spaßabnahme.

`tests/imperial_retinue.gd` prüft alle Schwierigkeiten, die vollständige
Hell-Rufabfolge, echte Aufladung/Regeneration, Priorität des Siegelhüters,
Schadensbegrenzungen, Warnungen, Erfolg/Fehlschlag, tatsächliches Save/Resume
mit Vasallenbesitzern, Pause, Legacy-Übergang und Stageabschluss.
`tests/imperial_retinue_combat.gd` setzt reale automatische Nah-, Fern- und
Flächenwaffen sowie normale Spielerphysik ein. Der Pilot geht zuerst zum
Siegelhüter und reagiert nicht auf Gefahren; sein erhöhtes Leben dient nur
der Erreichbarkeitsprüfung. Die Messwerte stehen in
`.godot/imperial_retinue_combat.json`.
