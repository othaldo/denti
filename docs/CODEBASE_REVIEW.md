# Codebase-Prüfung und Refactoring-Vorschläge

Stand: 18. Oktober 2026 · geprüfter Commit: `1db7662` · Godot 4.7.2.

Die Codebasis hat bereits viele sinnvolle Systemgrenzen. Den größten Nutzen bringen klarere Verantwortlichkeiten in Spielsteuerung, Speicherung, Shop und Effekten. Ein schrittweiser Umbau kann die vorhandenen Systeme und ihre Performance-Eigenschaften erhalten.

Die ursprüngliche Bestandsprüfung umfasste eine repositoryweite Struktur-, Abhängigkeits- und Referenzprüfung, vertiefte Quellcodeprüfung der zentralen Abläufe, den vollständigen vorhandenen Testlauf und gezielte Reproduktionen. Sie ist keine Zusicherung, dass jede mögliche Kombination fehlerfrei ist. Die nachfolgende Bestandsaufnahme bezieht sich auf den geprüften Commit. Die anschließende Umsetzung und ihre Prüfungen stehen im nächsten Abschnitt.

## Umsetzung im lokalen Checkout

Auf Wunsch direkt unter `/home/othaldo/projects/denti/` auf dem vorhandenen Branch umgesetzt. `AGENTS.md` hält diese Arbeitsweise auch für folgende Chats fest. Die Änderungen wurden in fachlichen Schritten geprüft; die ursprünglichen Befunde darunter bleiben als nachvollziehbare Ausgangslage erhalten. Zeilenangaben in diesen Befunden beziehen sich auf `1db7662`.

| Befund | Umsetzung |
| --- | --- |
| F1 | `Enemy._finish_death()` schließt den Tod genau einmal ab, auch wenn ein synchroner Folgetreffer das ursprüngliche Ziel tötet. `enemy_death_once` prüft echte Dreifaltigkeits-Treffer, Todes-/Beutesignale und Telemetrie. |
| F2 | Gemeinsamer Testabschluss stoppt Audio und räumt Szenen/losgelöste Stats auf. Runner erkennt Engine-Fehler und Leak-Warnungen trotz Exit-Code null; zwei zusätzliche negative Runner-Tests. |
| F3 | Dentipedia bezieht seine Itemkategorie ausschließlich aus `ItemCatalog`; Waffen bleiben in ihrer eigenen Kategorie. |
| A1 | `RunFlow` besitzt die übergeordnete Phase. Bisherige Flags sind kompatible abgeleitete Eigenschaften. Pause und Kampfaktivität verwenden diese Quelle. `PostWaveRewards` behält die Reihenfolge innerhalb der Belohnungsphase; `StoryRunController` kapselt Dialog und Reise. |
| A2 | Wellen, Shop und Gegner besitzen `save_state`/`restore_state`. `RunSnapshot` koordiniert; `RunIntermission` stellt die passende UI wieder her. `RunSaveData` prüft JSON-Container/Zahlen und normalisiert bekannte Alt-IDs. `RunStore` schreibt temporär und ersetzt nach erfolgreichem Schreiben. Negativtests prüfen unter anderem den Erhalt des letzten Saves bei Schreibfehlern. |
| A3 | `ShopLayout` baut den endgültigen Baum direkt. `EquipmentSlots` und `CollectedItems` kapseln wiederkehrende UI-Aufgaben. `ShopViewData` ersetzt den langen Laufzeitaufruf; der bisherige `show_shop`-Aufruf bleibt als Adapter für vorhandene Tests/Werkzeuge. `BuildPresentation` liefert gemeinsame Item-/Relikt- und Waffenanzeigedaten. |
| A4 | `ItemInventoryData` besitzt Inventar-/Limitregeln. `ItemEffectContext` stellt Bonusabfragen, gemeinsame Cooldowns und Feedback-Signale bereit; Verzauberungen benötigen keine privaten Inventar-Helfer mehr. `AffixPresentation` enthält Anzeigetexte, `WeaponAffixes` die Regeln. |
| A5 | `EnemyVisuals` übernimmt Marker und Telegraphen; `BossAttackController` Bossphasen, Angriffe und Overtime-Steuerung. Zustandsbesitz und bestehende Schnittstellen bleiben beim Gegner. Der gemessene Bewegungspfad und die Referenzsimulation bleiben erhalten. |
| A6 | `ItemCatalog` und `EnemyCatalog` sind unabhängige Quellen für Inventar, Rewards, Shop, WaveController, Save-Allowlist und Warmup. `catalogs` prüft Ressourcenregistrierung, eindeutige IDs, Statkeys, Waffentiers und die Pfad-Allowlist. |
| A7 | `RunStore`, `SessionSettings` und `ProgressionStore` trennen Speicherung, Einstellungen und Freischaltungen. `GameSession` bleibt als kompatible Fassade erhalten; die vorhandene Grafikadaption bleibt in `AdaptiveGraphics`. |
| A8 | Gemeinsame Fixture, direkte typisierte Kartenaufrufe, öffentliche `DentiUIComponents` statt fremder privater Label-Helfer und PR-Prüfung vor dem Deployment. |

Spielwerte, Ressourcen-IDs, interne `hands`-Felder und das äußere Save-Format bleiben kompatibel. Kampf-, Loot- und Belohnungsreihenfolge wurden durch die bestehenden Verhaltenstests abgesichert.

**Abschlussprüfung:** siehe aktualisierte Ergebnisse am Ende dieses Dokuments.

## Umfang und Ergebnis

| Bereich | Bestand | Prüfung und Ergebnis |
| --- | ---: | --- |
| Spiel und Arena | 2 Skripte, 1.141 Zeilen | Spielphasen, Spawning, Loot, Shop-Aktionen, Story, Save-Anbindung vertieft geprüft |
| Systeme | 41 Skripte, 4.766 Zeilen | Zustandsbesitz, Speicherung, Items, Belohnungen, Wellen, Telemetrie, Audio und Kataloge geprüft |
| Gegner | 17 Skripte, 2.206 Zeilen | Schaden/Tod, Spezialangriffe, Status, zentrale Bewegung, räumliche Suche und Projektilverwaltung geprüft |
| Waffen | 21 Skripte, 2.719 Zeilen | Trefferpipeline, Evolutionen, Fusion, Rolls, Affixe, Laufzeit-Saves und Pools geprüft |
| Spieler | 7 Skripte, 781 Zeilen | Statmodell, Schaden, Status, Bewegung und Darstellung geprüft |
| UI | 24 Skripte, 5.599 Zeilen | Struktur aller Komponenten; Shop, Menü, Karten, Belohnungen und Story-Abläufe vertieft geprüft |
| Debug und Story-Datentyp | 12 Skripte, 288 Zeilen | Diagnose-Instrumentierung und Schnittstellen geprüft |
| Szenen und Daten | 12 Szenen, 202 Datenressourcen | Statische Ressourcenverweise und Katalogeinträge geprüft; alle 93 Itemressourcen registriert, keine unbekannten Item-Statkeys gefunden |
| Tests | 107 Godot-Skripte, 13.556 Zeilen | Vollständiger Lauf, ergänzende Auswertung aller Testlogs und Prüfung der Teststruktur |
| Werkzeuge und CI | 53 GDScript-Werkzeuge, 11 Python-Dateien inklusive Runner-Tests | Struktur, Referenzen, Runner, Startskript, Exportkonfiguration und Workflow geprüft; Vorschau-/Bake-Werkzeuge nicht sämtlich ausgeführt |

Die größten Laufzeitdateien sind `game.gd` mit 1.080, `shop_panel.gd` mit 931 und `enemy.gd` mit 891 Zeilen. Die Größe ist ein Hinweis; ausschlaggebend sind die vermischten Zuständigkeiten.

## Konkrete Fehler und Prüflücken

### F1 · Hohe Priorität: Ein Gegner kann Tod und Beute zweimal auslösen

**Stellen:** `scripts/enemies/enemy.gd:642–663`, `scripts/weapons/weapon_evolution_effects.gd:61–70`.

`Enemy.take_damage()` sendet `weapon_hit`, bevor es den Todesabschluss behandelt. Ein Listener kann während dieses Signals denselben Gegner erneut beschädigen. Die Explosion der Dreifaltigkeitsbürste trifft auch ihr ursprüngliches Ziel. Tötet dieser verschachtelte Treffer, sendet der innere Aufruf `died` und `defeated`; nach seiner Rückkehr führt der äußere Aufruf denselben Todesblock erneut aus.

**Reproduziert über die echte Trefferpipeline:** Dreifaltigkeitsbürste Mk IV, Gegner mit 25 HP und ohne Schadensreduktion, zwei Treffer mit jeweils 10 Schaden. Der erste Treffer hinterlässt 15 HP und eine Markierung. Der zweite hinterlässt zunächst 5 HP; die Explosion tötet das Ziel.

```text
AFTER_FIRST health=15.0 marks=1
AFTER_SECOND health=0.0 died=2 defeated=2 loot=4
```

Für die Beuteprüfung wurden Welle 1, garantierte Münzbeute und unterdrückte Zufallskapseln verwendet. Erwartet sind genau ein `died`, ein `defeated` und zwei Drops. Die doppelte Meldung erreicht auch die Kill-Telemetrie und Kill-Effekte.

**Änderung:** Einen idempotenten Todesabschluss einführen und dessen Zustand vor dem Senden weiterer Signale setzen. Auch nach synchronen Treffer-Callbacks muss erkennbar sein, ob ein innerer Aufruf den Tod bereits abgeschlossen hat. Die Fläche der Evolution darf weiterhin das Ursprungsziel treffen.

**Absicherung:** Regressionstest über `WeaponAttackShapes.hit()`, der einen verschachtelten tödlichen Folgeeffekt erzeugt und Tod, Kill-Zähler, Drops und Kill-Belohnungen jeweils genau einmal erwartet. Zusätzlich normale direkte Kills und verzögerten Boss-Tod beibehalten. Der bestehende Evolutionstest ruft den Trinity-Effekt direkt auf; dieser verschachtelte Todesfall fehlt.

### F2 · Mittlere Priorität: Bestandene Tests enthalten unbeachtete Engine-Fehler

**Stelle:** `tools/run_tests.py:87–92`; Testaufbau und Testende in `tests/`.

Der Runner erkennt Fehlercodes, Timeouts und `SCRIPT ERROR:`. Allgemeine `ERROR:`-Zeilen beeinflussen das Ergebnis nicht. Im vollständigen Lauf bestanden 107/107 Tests, aber 71 Testlogs enthielten `resources still in use at exit`; 75 enthielten Warnungen. Sämtliche gefundenen `ERROR:`-Zeilen dieses Laufs waren Ressourcenmeldungen beim Beenden.

Ein zusätzlicher ausführlicher Lauf von `affix_layout_history` nannte `AudioStreamMP3`, `AudioStreamPlaybackMP3` und `wave-1.mp3`. In einer temporären Testkopie verschwanden die Meldungen nach Musikstopp, Freigabe der Spielszene und zwei weiteren Frames. Das belegt eine konkrete Verbesserung des Testabschlusses; es belegt keinen allgemeinen Speicheranstieg während normaler Runs.

**Änderung:** Gemeinsame Fixture mit definiertem Aufräumen einführen. Engine-Fehler im Runner separat erfassen und anzeigen; nach Bereinigung des Bestands unerwartete Fehler ebenfalls fehlschlagen lassen. Erwartete Werkzeugwarnungen gezielt behandeln. Ein pauschales Ignorieren aller Ressourcenfehler würde künftige Regressionen verdecken.

**Absicherung:** Runner-Test für `ERROR:` bei Exit-Code 0; Fixture-Test für wiederholtes Erstellen/Freigeben; vorhandene Prozess-Isolation und Timeout-Prüfungen erhalten.

### F3 · Niedrige Priorität: Dentipedia mischt Waffen in die Itemkategorie

**Stelle:** `scripts/ui/dentipedia_data.gd:47–49`.

Die Kategorie „Items“ iteriert über den gesamten `ShopController.CATALOG`. Dieser enthält Items und Waffenangebote. Der isolierte Aufruf lieferte 111 Einträge: 93 Items und zusätzlich alle 18 normalen Waffen. Die Waffen haben bereits eine eigene Kategorie.

**Änderung:** Sofort nach `weapon_data == null` filtern; beim späteren Katalog-Refactoring eine explizite Itemliste verwenden.

**Absicherung:** Die Itemkategorie enthält genau die Itemressourcen und keine Waffenangebote.

## Refactoring mit dem größten Nutzen

### A1 · Spielphasen eindeutig steuern

**Stellen:** `scripts/game/game.gd:45–58`, `:244`, `:656–765`, `:837–958`; `scripts/ui/game_menu.gd:54–56`; `scripts/systems/post_wave_rewards.gd`.

`PostWaveRewards` ist ein guter vorhandener Koordinator für die Belohnungsreihenfolge. Daneben entscheiden `in_shop`, `starter_pending`, `boss_pending`, `collecting_wave_loot`, `ended`, `wave.active` und sichtbare Panels über Eingabe, Pause und Fortsetzung. Das Pausenmenü rekonstruiert den Zustand erneut aus fünf sichtbaren Panels. Ein neuer Screen erfordert dadurch Änderungen an mehreren Stellen.

**Ziel:** Der Ablaufkoordinator entscheidet über Phasenwechsel, erlaubte Aktionen und Fortsetzen. UI-Sichtbarkeit folgt diesen Entscheidungen. Bestehende Flags zunächst nur noch aus dem autoritativen Zustand ableiten. Die vorhandene Belohnungsqueue und ihre gespeicherten Enum-Werte erhalten.

In `game.gd` danach klar begrenzte Bereiche auslagern: Story-Ablauf, Shop-Aktionen und Spawn-/Loot-Anbindung. Die Wurzelszene verbindet weiterhin die Systeme und ihre Signale. Eine neue Datei allein reicht nicht, wenn sie weiterhin sämtliche Felder von `game` verändert.

**Prüfen:** Kampf bleibt bei XP/Kapseln aktiv; Boss-Nachlauf; Loot vor Belohnungen; Shop erst nach der Queue; Pause aus jedem Intermissionsscreen; Story und Endless; Resume in jeder Phase.

### A2 · Spielzustand, Save-Kompatibilität und Wiederanzeige trennen

**Stellen:** `scripts/systems/run_snapshot.gd:7`, `:94–348`; `scripts/systems/game_session.gd:170–188`.

`RunSnapshot.restore()` umfasst 257 Zeilen. Es setzt Gegnerfelder, Wellenpläne, Inventare, Waffenreferenzen und Angebote, migriert alte Schlüssel und zeigt anschließend konkrete Panels an. Das Save-System benötigt dadurch internes Wissen fast aller Systeme und ruft private Methoden des Spiels auf.

**Ziel:** Wellen-, Gegner- und Shop-Zustand erhalten eigene Capture-/Restore-Schnittstellen. Bereits vorhandene Schnittstellen von Stats, Items, Relikten, Waffen und Belohnungen dienen als Vorbild. Alte Save-Formate vor dem Anwenden normalisieren. Danach stellt der Ablaufkoordinator die passende Phase dar. Referenzen zwischen Gegnern, Projektilen und Waffen weiterhin in der richtigen Reihenfolge wiederherstellen.

Den JSON-Rand einmal auf erwartete Container-/Werttypen prüfen. `load_run()` prüft aktuell nur Version und das Vorhandensein von `wave` und `player`; viele verschachtelte Typannahmen folgen erst beim Anwenden. Den Dateizugriff separat behandeln: temporär schreiben, erfolgreich schließen und dann ersetzen, mit erkennbarem Fehlerergebnis. Das ist eine Robustheitsverbesserung; ein Dateiverlust wurde hier nicht reproduziert.

**Prüfen:** Bestehende Legacy-Fälle, JSON-Roundtrips, aktive Geschosse/Evolutionen, unveränderte Upgrade-Angebote, komplette Reward-/Story-Zustände und gezielt ungültige Save-Daten. Das äußere Format schrittweise kompatibel halten.

### A3 · Den Shop aus dem endgültigen Layout aufbauen und typisierte Anzeigedaten nutzen

**Stellen:** `scripts/ui/shop_panel.gd:69–223`, `:367`, `:472–568`, `:745–856`; `scripts/game/game.gd:847–866`.

Der Shop baut in `_ready()` eine Struktur auf und hängt größere Teile direkt danach in `_build_night_layout()` erneut um. Inventar, Statgrid, Angebote, Detailpopup, Layout und Aktionen liegen in einer Klasse. `show_shop()` benötigt 13 Parameter und mehrere parallele Arrays. Ausstattungseinträge sind Dictionaries, deren benötigte Felder nur durch Produzent und Konsument zusammen bekannt sind.

**Ziel:** Endgültigen Szenenbaum direkt aufbauen. Build-Spalte und Detailpopup als überschaubare UI-Komponenten abtrennen. Ein kleines typisiertes Shop-Anzeigemodell ersetzt den langen Parameteraufruf und die parallel gepflegten Angebotsdaten. Kauf/Fusion/Verkauf bleiben über Signale an die Spiellogik angebunden.

`WeaponPresentation` für gemeinsame Werte/Texte weiterverwenden. Gemeinsame Item-/Relikt-Anzeigedaten auch im Pausenmenü einsetzen; die Zusammenstellung wird dort derzeit erneut implementiert (`game_menu.gd:403`).

**Prüfen:** Vorhandene Shop-, Kauf-, Reservierungs-, Fusions-, Touch- und Layouttests; insbesondere wiederholtes Wechseln von Auswahl und Fenstergröße. Darstellung zusätzlich nativ prüfen, sobald der Szenenbaum geändert wird.

### A4 · Inventarbesitz, Effektzustand und Darstellung entkoppeln

**Stellen:** `scripts/systems/item_inventory.gd:85–150`, `:192–435`; `scripts/weapons/weapon_enchantment_effects.gd`; `scripts/weapons/weapon_affixes.gd:230–347`.

`ItemInventory` verwaltet Besitz und Limits, verändert Stats, rechnet Economy-Boni, führt Treffer-/Kill-Procs aus und zeichnet Pfützen/Feedback. Das ausgelagerte `WeaponEnchantmentEffects` greift auf private Hilfen wie `_power`, `_ready_proc`, `_line` und `_ring` zurück. `WeaponAffixes` mischt Ausbau-/Anwendungsregeln mit Vergleichstexten und hängt dabei wieder von `WeaponPresentation` ab.

**Ziel:** Zunächst eine kleine öffentliche Effektschnittstelle für Bonusabfragen, gemeinsame Cooldowns und Feedback schaffen. Besitz-/Limitregeln und laufende Effekte getrennt halten. Affix-Anzeigetexte zu einer Präsentationsklasse verschieben; Berechnungen weiter gemeinsam verwenden. Für wirklich gemeinsam benötigte Flächen-/Zielsuche kleine Helfer nutzen.

Die Reihenfolge der synchronen Trefferereignisse, geteilte Cooldowns, Burst-Sperren und die Trennung von Primär- und Folgeschaden müssen erhalten bleiben. Ein generisches Effektsystem mit einer Klasse pro Item wäre für den aktuellen Bestand unnötig aufwendig.

**Prüfen:** Itemfamilien, Stacklimits, Enchantment-Synergien, DoT-Budgets, Heilung/Überheilung, Economy-Bruchteile und Save-Zustand. F1 ist vorher separat zu beheben.

### A5 · Gegnerverhalten und Darstellung trennen; schnelle Bewegung schützen

**Stellen:** `scripts/enemies/enemy.gd:194–281`, `:564–671`, `:703–891`; `scripts/enemies/enemy_motion.gd:58–157`.

`Enemy` besitzt Skalierung, Status, Angriffe, Bossphasen, Schadensregeln, Tod und Zeichnen. Der zentrale Bewegungspfad wiederholt bewusst einen Teil der allgemeinen Physik, einschließlich Statusablauf, Schützenbewegung und Kontaktprüfung. Das ist dokumentierte Performance-Arbeit und durch einen Referenzvergleich abgesichert.

**Ziel:** Zuerst Darstellung und Boss-Angriffssteuerung an klaren Schnittstellen auslagern. Gemeinsam verwendete Statusregeln als expliziten Vertrag behandeln. Gemeinsame Berechnungen nur dann zusammenziehen, wenn Referenzvergleich und Benchmark den Gewinn bestätigen. Die beiden Verarbeitungspfade dürfen vorerst bestehen bleiben.

**Prüfen:** `central_enemy_motion`, Status-/Kontakt-/Boss-/Telegraph-Tests; bei Änderungen im häufigen Pfad zusätzlich `benchmark_enemy_physics` und die dichte Testarena. Die getestete Entstehungsreihenfolge und transformierte Arenen erhalten.

### A6 · Kataloge unabhängig von ihren Konsumenten machen

**Stellen:** `scripts/systems/shop_controller.gd:4–116`; `scripts/systems/run_snapshot.gd:351–368`; `scripts/enemies/boss_projectile_warmup.gd:79`; `scripts/systems/wave_controller.gd:52–63`.

Items sind über den Shop-Knoten definiert. Inventar, Belohnungen, UI und Werkzeuge müssen deshalb den Shop-Katalog kennen. Die Gegnerliste wird unter anderem im WaveController, Save-Allowlist und Grafik-Warmup aufgezählt. F3 zeigt bereits eine konkrete Folge des gemischten Shop-Katalogs.

**Ziel:** Explizite `ItemCatalog`- und `EnemyCatalog`-Listen mit typisierten Ressourcen bereitstellen. Shop, Saves und Warmup verwenden diese Listen. Bestehende IDs, Ressourcenpfade und notwendige Kompatibilitätsaliase erhalten. Die explizite Save-Allowlist bewahren; gespeicherte Pfade nicht ungeprüft laden.

Gemeinsame Katalogtests sollten IDs, registrierte Ressourcen, Statkeys, Effekttypen und erforderliche Tier-Tabellen prüfen. Ein zentraler universeller Registry-Mechanismus ist dafür nicht nötig.

### A7 · GameSession in klar begrenzte Dienste aufteilen

**Stellen:** `scripts/systems/game_session.gd:37`, `:136–188`, `:196–255`, `:258–337`.

Der Autoload verwaltet Run-Speicherung, Einstellungen, Fortschritt, Grafikadaption, UI-Audio und geschützte Testruns. Damit hängt viel Infrastruktur an einem einzigen Objekt.

**Ziel:** Zuerst Dateizugriff und Einstellungen auslagern, später Fortschritt und Grafiksteuerung. `GameSession` kann als stabile Fassade bestehen bleiben. Konsumenten müssen dadurch nicht gleichzeitig umgebaut werden. Die vorhandene Sicherung normaler Runs beim Start einer Testarena erhalten.

**Prüfen:** Settings-/Grafik-/Audio-Tests, Difficulty-Unlocks, Entdeckungen, Save/Resume und Schutz des normalen Spielstands bei Testarenen.

### A8 · Testaufbau und Schnittstellen schrittweise vereinheitlichen

**Stellen:** `tests/`, `tools/run_tests.py`, `.github/workflows/deploy-web.yml:3–6`; außerdem `choice_panel.gd:21`, `shop_panel.gd:20`, `shop_details.gd:241`.

87 der 107 Tests instanziieren die ganze Spielszene. 56 Dateien definieren `_fail`, 38 `_check`; Spielaufbau und Aufräumen wiederholen sich. Das bestehende Testspektrum ist wertvoll, aber kleine Regelprüfungen brauchen dadurch oft UI, Musik und Szene. Der einzige eingecheckte CI-Workflow startet bei Push auf `main` oder manuell; Pull Requests haben in dieser Konfiguration keinen eigenen Testlauf vor dem Merge.

**Ziel:** Kleine Fixtures unter `tests/support/` einführen; der Runner entdeckt nur `tests/*.gd`. Zunächst Setup/Teardown vereinheitlichen, vorhandene Verhaltenstests erhalten. Reine Regeltests können die später extrahierten Systeme direkt prüfen. Einen PR-Testlauf ergänzen; Veröffentlichung weiterhin auf den vorgesehenen Hauptbranch begrenzen.

Bei berührten Schnittstellen Typen schärfen: Kartenarrays als `Array[UpgradeCard]` bzw. `Array[OfferCard]` statt `Array[Button]`, direkte Methoden statt `.call("show_upgrade", ...)`. `ShopDetails._label` wird bereits von vielen unabhängigen Screens als allgemeiner UI-Helfer verwendet; diese Funktion kann in eine passende öffentliche UI-Hilfe wandern. Das sind nachgeordnete, lokale Verbesserungen.

## Empfohlene Reihenfolge kleiner Änderungen

| Schritt | Lieferumfang | Nachweis |
| --- | --- | --- |
| 1 | F1 beheben: Todesabschluss genau einmal | Neuer verschachtelter Trefferfall plus Kampf-/Loot-/Evolutionstests |
| 2 | Test-Teardown und Engine-Fehlerauswertung verbessern | Erst bereinigte Fälle, danach voller Lauf; Runner-Negativtest |
| 3 | F3 beheben, explizite Kataloggrenzen und einfache Schnittstellentypen | Katalog-/Dentipedia-/Item-/Shop-Tests |
| 4 | Zuständigkeit für Phasen/Pause zentralisieren | Alle Intermissions-, Story-, Endless- und Resume-Fälle |
| 5 | Save-Verantwortung pro System und normalisierte Altformate | Vorhandene JSON-/Legacy- und aktive Kampf-Roundtrips |
| 6 | Shop-Anzeigemodell und endgültigen Szenenbaum einführen | Interaktion und Layouts; native Sichtprüfung |
| 7 | Effektzustand/Präsentation und Enemy-Zuständigkeiten entkoppeln | Synergien, Referenzsimulation und Performance-Messungen |
| 8 | GameSession-Dienste herauslösen | Einstellungen, Fortschritt und geschützte Testarenen |

Jeder Schritt soll als eigene überprüfbare Änderung spielbar bleiben. Reine Umstrukturierung und Balanceänderungen sollten getrennte Änderungen sein, damit sich Regressionen zuordnen lassen.

## Bestehendes, auf dem der Umbau aufbauen kann

- Stats besitzen mit `PlayerStats` bereits einen gemeinsamen Ursprung; die additiven Kurven und Migrationsfälle sind explizit getestet.
- `PostWaveRewards`, `EconomyRules`, `EndlessRules` und die Datenressourcen kapseln bereits gut abgegrenzte Regeln.
- Räumliche Indizes, Projektilpools, gebackene Atlanten, begrenzte Caches und die Vergleichssimulation sind wertvolle, begründete Lösungen. Sie sollten bei einer Bereinigung erhalten bleiben.
- `WeaponPresentation` und die existierenden `save_data`-/`restore`-Schnittstellen sind geeignete Vorbilder für weitere Extraktionen.
- Der Runner isoliert die Benutzerdaten pro Prozess, begrenzt Parallelität und behandelt Timeouts und Skriptfehler. Diese Eigenschaften sind eine gute Basis für die Refactorings.
- Gespeicherte Enum-Werte, interne `hands`-Felder und Legacy-Schlüssel sind bestehende Kompatibilitätsverträge. Eine Umbenennung aus rein kosmetischen Gründen bringt hier wenig Nutzen.

## Prüfungen der ursprünglichen Bestandsaufnahme

```bash
godot --headless --path . --editor --quit
python3 -m unittest discover -s tools/tests -v
python3 tools/run_tests.py --godot godot --jobs 4
```

Import erfolgreich. Python: **4/4 bestanden**. Godot: **107/107 laut Runner bestanden**, Laufzeit **87,41 Sekunden**. Die beschriebenen Shutdown-Meldungen wurden zusätzlich aus den Logs ausgewertet.

Die unabhängigen Probe-Skripte und ihre Logs liegen lokal im ignorierten Verzeichnis `.godot/review/`: doppelte Todes-/Beuteauslösung, Itemkategorie und bereinigter Testabschluss. Sie liefen mit getrennten Benutzerdaten. Bestehende Spielstände und Spielcode wurden nicht verändert.

## Prüfung nach der Umsetzung

**111/111 Godot-Tests bestanden in 97,92 Sekunden**, einschließlich der strengen Auswertung von Engine-Fehlern und Leak-Warnungen. **6/6 Python-Runner-Tests bestanden.** Editor-Import und `git diff --check` sind fehlerfrei. Neue direkte Tests prüfen Run-Phasen, Katalogverträge und Save-Validierung/atomare Speicherung. Die bestehende Szene-/JSON-Prüfung `upgrade_resume` behält alle 52 Fälle.

Vollständiges Protokoll: `.godot/test_runs/20261018-095716-1d4c819c/results.json` und die zugehörigen Testlogs. Die erste strenge Gesamtausführung nach dem Umbau erkannte noch zwei Tests mit umgangenem Audio-Teardown; nach deren Umstellung besteht der gesamte Lauf. Diese Fehlerwege wurden nicht ausgefiltert.

Native OpenGL-Vorschauen von Shop, Fusion, Stats und Items wurden in 1280×720, 720×1280 und 1040×600 erzeugt. Lokale Bilder liegen unter `.godot/refactor_ui/`; keine freigegebenen Art-Dateien wurden überschrieben. Ein Web-Export wurde lokal nicht ausgeführt, da keine Export-Templates installiert sind. Der Workflow prüft ihn weiterhin und nun zusätzlich für Pull Requests.

Der Gegnerbenchmark wurde vor und nach der Extraktion mit `--wet` ausgeführt. Die Positionsprüfsumme war in allen Durchgängen `(74543.11, 34101.18)`; `central_enemy_motion` prüft zusätzlich Zustandsübereinstimmung. Die Abschlussmessung lief separat nach der Testsuite: zentraler Pfad 0,352 / 0,354 / 0,354 ms pro Tick, Einzelpfad 0,538 / 0,547 / 0,540 ms. Vor der Gegnerextraktion lagen die drei Messungen bei zentral 0,376 / 0,359 / 0,363 ms und einzeln 0,615 / 0,549 / 0,533 ms. Damit ist in diesem Mikrobenchmark kein Laufzeitnachteil erkennbar; daraus folgt keine allgemeine FPS-Aussage für eine komplette Arena. Gemessen mit 110 Gegnern und 1.800 Ticks pro Durchgang, je ein Aufwärmdurchgang pro Pfad.

## Nachprüfung: stabile Shop-Geometrie bei Käufen

Der erste Itemkauf ließ die zuvor versteckte Itemleiste wachsen. Da die Angebotsfläche ihre bisherige Mindesthöhe behielt und der äußere ScrollContainer die Mindestgrößen weiterreichte, wuchs das Fenster bei 1280×720 von 696 auf 724 Pixel Höhe und ragte über den Bildschirm. `shop_layout_stability` reproduzierte diesen Fehler vor der Korrektur.

Die Itemleiste reserviert ihren Platz jetzt bereits bei leerem Inventar. Der Hauptbereich übernimmt nur das verbleibende Höhenbudget, statt den äußeren Shop über seine Kind-Minima zu vergrößern. Die Breite bestimmt weiterhin die Spaltenzahl; weniger verfügbare Höhe durch die Story-Leiste aktiviert zuerst die dichtere Darstellung und bei Bedarf einen Scrollbereich innerhalb des Shops. Zahlen und Beschriftungen bleiben in ihren vorgesehenen Flächen, mit vollständigen Werten im Tooltip. Bei unverändertem Layoutprofil werden die angepassten Textflächen der Karten erhalten, damit Käufe und Rerolls keinen erneuten verzögerten Reflow auslösen.

Die neue Regression prüft Käufe, Fusionen und Verkäufe in sechs Auflösungen. Bei Käufen vergleicht sie die Shop-, Hauptbereich- und Footer-Geometrie während aller zwölf folgenden Frames. Weitere Fälle prüfen die Story-Leiste, eine volle Itemleiste, große Zahlen und sämtliche 111 Angebote in fünf Auflösungen. Nichtleere Texte müssen eine sichtbare Zeilenhöhe behalten. Der bestehende Aktions-/Kartenlayouttest wurde zusätzlich zwölfmal mit unterschiedlichen zufälligen Angeboten ausgeführt; alle Wiederholungen bestanden.

Native Vorher-/Nachher- und Story-Bilder für 1280×720, 1040×600 und 720×1280 liegen unter `.godot/layout_debug/`. Die Shop-Korrektur betrifft `shop_layout.gd`, `shop_panel.gd` und die Text-/Zahlenslots von `offer_card.gd`; andere zuvor durchgeführte Refactorings bleiben erhalten.

**Abschluss der Shop-Nachprüfung:** 112/112 Godot-Tests bestanden in 98,55 Sekunden, 6/6 Python-Runner-Tests bestanden, `git diff --check` fehlerfrei. Vollständige Logs: `.godot/test_runs/20261018-101939-fa2584df/`. Die native Prüfung der Kauf- und Story-Fälle war ebenfalls fehlerfrei.

## Nachprüfung: vollständige und isolierte Icon-Ausschnitte

Die drei ursprünglichen Item-Bögen liegen nicht exakt in gleichmäßigen Zellen. Die Keramikschale enthielt dadurch die obere Kante des darunterliegenden Griffs; der Griff selbst verlor diese Pixel. Vergleichbare Grenzverschiebungen betreffen weitere Motive der Erweiterungsbögen.

`DentiUIIcons` verwendet für diese 28 Motive explizite Quellrechtecke mit transparentem Rahmen. Die Original-PNGs bleiben unverändert. `filter_clip` begrenzt zusätzlich die Abtastung aller UI-Atlas-Icons auf deren Ausschnitt. Neuere, bereits gepolsterte Bögen behalten ihre vorhandene Rasterzuordnung.

`item_icon_regions` reproduzierte den fremden Bildrest vor der Korrektur. Der Test prüft nun die zusammenhängende Keramikschale, ausreichenden Rand, quadratische Rahmen sowie für die drei Bögen den vollständigen Erhalt aller gezeichneten Pixel ohne doppelte Auswahl. Außerdem prüft er die Filterbegrenzung der Item-, HUD- und Relikt-Icons. Ein nativer Vergleich zeigt bisherige und korrigierte Ausschnitte sowie alle 91 Item-Atlas-Icons bei 24 und 48 Pixeln: `.godot/icon_debug/atlas_comparison.png`.

**Abschluss der Icon-Nachprüfung:** 113/113 Godot-Tests bestanden in 100,93 Sekunden; 6/6 Python-Runner-Tests bestanden. Editor-Import, native Darstellung und `git diff --check` fehlerfrei. Vollständige Logs: `.godot/test_runs/20261018-104053-cca739e1/`.
