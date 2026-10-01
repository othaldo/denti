# Denti: Divine Dentistry

Ein kleiner 2D-Arena-Survivor über einen göttlichen Zahn, der Plaque, Zucker und Karies den Kampf ansagt. Denti bewegt sich von Hand; seine Waffen greifen automatisch an. Zwischen den Wellen entscheiden Levelaufstiege und Einkäufe, wie der nächste Kampf läuft.

**Aktuelle Version: 0.2.0 · Pressure + Build Depth.** Alle Änderungen seit 0.1 stehen in der [Patchnote-Historie](CHANGELOG.md).

![Denti kämpft in Welle 4 gegen Plaque, Bakterien, Zucker und Säurespucker](docs/screenshots/kampf.png)

## Ein Blick ins Spiel

| Bosskampf am Arenarand | Levelaufstieg |
| --- | --- |
| [![Denti und der Karies-Graf an der oberen Arenamauer](docs/screenshots/bosskampf.png)](docs/screenshots/bosskampf.png) | [![Drei wählbare Boni beim Levelaufstieg](docs/screenshots/levelaufstieg.png)](docs/screenshots/levelaufstieg.png) |

| Shop zwischen den Wellen | Hauptmenü |
| --- | --- |
| [![Waffen und Items in der Zahnklinik](docs/screenshots/shop.png)](docs/screenshots/shop.png) | [![Das Hauptmenü von Denti: Divine Dentistry](docs/screenshots/hauptmenue.png)](docs/screenshots/hauptmenue.png) |

Die Bilder sind direkt aus Godot aufgenommen. Für die Kampfbilder wurden Gegner und Beute in einem separaten Testlauf arrangiert. Einige Aufnahmen zeigen ältere Menü- und Shoplayouts; seit 0.2.0 gibt es vier Level-up-Boni und vier Shopangebote.

[![Die vier Bossränge mit ihren animierten Entzündungs-Auren](docs/screenshots/boss_entzuendung.png)](docs/BOSS_INFLAMMATION.md)

Die vier Farbstufen der Boss-Entzündung. Die Vorschau zeigt einen Frame der Animation; für den direkten Vergleich sind die Bosse gleich groß dargestellt. [Details zur Entzündung](docs/BOSS_INFLAMMATION.md).

## Spielen

Das Projekt mit **Godot 4.4 oder neuer** öffnen und mit **F5** starten. Unter Linux geht es auch im Projektordner:

```bash
./play.sh
```

`play.sh` nutzt `/usr/local/bin/godot`, falls vorhanden, sonst `godot` aus dem `PATH`. Mit `DENTI_GODOT_BIN=/pfad/zu/godot ./play.sh` lässt sich eine andere Installation wählen. `./play.sh --probe` misst die Bildrate im Fenster, im Vollbild und mit 100 Gegnern.

| Eingabe | Aktion |
| --- | --- |
| WASD oder Pfeiltasten | Denti bewegen |
| Escape | Pause, Stats und Optionen öffnen |
| F3 (Debug-Build) | Kampf-Telemetrie ein- und ausblenden |
| F4 (lokaler Debug-Build) | Testmenü: Waffen, Items, Münzen, Stats und Wellen |
| Maus | Waffen, Boni und Shopangebote wählen |
| Touchscreen | Linken Joystick ziehen, Pause antippen; Menüs und Shop per Tippen bedienen |

Vor einem neuen Run wählst du **Easy, Normal oder Hard**; **Hell** wird nach einem Sieg auf Hard freigeschaltet. Der Grad bleibt beim Fortsetzen erhalten. Normal entspricht der bisherigen Balance, während die anderen Grade vor allem Gegnerdichte, Horden, Eliten und Projektilmuster verändern.

Zu Beginn wählst du eine Startwaffe. Im Kampf sammelst du XP und Münzen. Erreichte Level werden vorgemerkt, ohne die Welle anzuhalten. Selten kann eine Zahnfee-Kiste fallen; auch ihr Einsammeln unterbricht den Kampf nicht. Am Wellenende fliegt verbliebene Beute erst zu Denti. Danach wählst du für jedes erreichte Level einen von vier Stat-Boni und entscheidest bei jeder Kiste, ob du das Item behältst oder für Münzen zerlegst. Nach den Bossen in Welle 5, 10 und 15 wählst du außerdem eines von drei göttlichen Relikten. Erst dann öffnet der Shop. Dort kannst du Waffen und Items kaufen oder die vier Angebote neu würfeln oder kostenlos mit Preisbindung merken. Waffen und Boni haben vier farblich markierte Stufen. Gleiche Waffen bleiben bei freien Plätzen einzeln ausgerüstet; bei voller Ausrüstung verschmilzt ein passender Kauf. Angebote öffnen zunächst ihre Details; der Preisbutton auf jeder Karte kauft direkt. Nicht kaufbare Angebote bleiben inspizierbar, ihr Preisbutton wird ausgegraut. Tippe eine belegte Hand an, um die Waffe zu vergleichen, mit einem passenden Exemplar zu fusionieren oder nach Bestätigung zu verkaufen. Fusionen reichen bis Stufe IV; Rechtsklick bleibt als Abkürzung erhalten. Die gesammelten Items und Relikte stehen unten als Icons mit Anzahl, Effekt beim Hover und Details per Antippen. Auf kleinen Bildschirmen ordnet der Shop Angebote und Details untereinander an und hält die Aktionen erreichbar. Höheres Glück erhöht innerhalb fester Grenzen die Chance auf Kisten, seltene Angebote und Boni; Waffen, die du schon trägst, erscheinen häufiger. Items können sich stapeln und bilden Kombinationen aus Blutung, Flächenschaden, Schild, Heilung und Münzgewinn. Unter **Escape → Stats** stehen die Werte und Waffen, unter **Escape → Items** die gesammelten Icons mit Anzahl und anwählbaren Effekten. Alle Effekte stehen in der [Item-Übersicht](docs/items.md) und der [Relikt-Übersicht](docs/relics.md).

## Was schon spielbar ist

Gold fällt unabhängig von XP und in den ersten Wellen häufiger. Shoppreise steigen nach der Brotato-Kurve; gemerkte Angebote behalten ihren Preis. Die neue Economy, vier Auswahlkarten und die Messungen sind in [ECONOMY_BALANCE.md](docs/ECONOMY_BALANCE.md) dokumentiert.

- **20 Wellen mit variabler Dauer**: frühe Wellen dauern 35–44 Sekunden, späte normale Wellen bis zu 50 Sekunden; Bosswellen bleiben bei 45 Sekunden. Horden, Bursts und Eliten richten sich zeitlich nach der jeweiligen Wellenlänge. Die Boss-Dynastie steigert sich in Welle 5 vom **Karies-Grafen** über den **Karies-Prinzen** in Welle 10 und den **Karies-König** in Welle 15 bis zum **Karies-Imperator** in Welle 20. Jeder Rang hat ein eigenes Sprite und zunehmend dichtere Fächerschüsse, Projektilringe, schnellere Attacken und mehr Verstärkung. Bosse haben zwei kurze Schutzphasen, kündigen Anstürme an, setzen Flächenpulse ein und werden bei halbem Leben schneller. Überleben sie das Zeitlimit, beginnt der Zustand **Entzündet**: pro voller Sekunde steigen Schaden und Verteidigung um 5 %, Bewegungs-/Projektiltempo um 3 %, Angriffstempo um 4 % und Lebenspunkte um 2 % der Ausgangswerte. Aktuelle und maximale Lebenspunkte wachsen im gleichen Verhältnis; der Boss wird nicht voll geheilt. Warnzeiten bleiben erhalten. Eine animierte Energie-Aura umgibt den Zahn: orange beim Grafen, rot beim Prinzen, pink beim König und violett beim Imperator. Sie wird während der Entzündung stärker; ihre sichtbare Größe bleibt begrenzt. Das HUD zeigt die Entzündungs-Sekunden; Fortsetzen bewahrt die Eskalation und Aura. Details stehen in [Boss-Entzündung](docs/BOSS_INFLAMMATION.md).
- **Vier normale Gegnertypen** und zwei Eliten, die schrittweise hinzukommen. Der Säurespucker kündigt seine Schüsse an; das zähe Zuckerstück startet ab Welle 7 einen langen Ansturm mit markiertem Einschlagbereich. Ab Welle 8 kann die Säurekrone als Elite mit angekündigtem Projektilring erscheinen. Ab Welle 12 bringt der Jagdkeim drei Bakterien mit, beschleunigt nahe Gegner und stürmt selbst an. Beide Eliten haben einen sichtbaren Schmelzschild gegen hohen Schaden in kurzer Zeit. Normale Wellen variieren ihre Gegnerverteilung durch die Profile Schwarm, Kreuzfeuer, Ansturm oder Zuckerflut. Das Profil verändert nur die Gegnerverteilung im normalen Spawnmix; Bosswellen, Spawnrate und Gegnerwerte bleiben davon unberührt. Wellen enthalten zusätzlich mehrere zeitlich variierende Gegnergruppen; ab Welle 6 kommen zum Schluss weitere Säurespucker und ab Welle 12 in normalen Wellen ein zusätzlicher Druckschub. Plaque bleibt leicht zu besiegen, während Zuckerstück und Säurespucker später stärker wachsen und häufiger erscheinen. In späteren Wellen schießen Säurespucker dichtere Fächer. Ab Welle 11 erscheinen mehrere Elite-Gruppen pro normaler Welle; später treten bis zu drei Eliten gleichzeitig auf. Einzelne Wellen bringen außerdem größere Themenhorden. Mehr Kills bedeuten in späten Wellen nicht mehr garantiert mehr XP und Münzen.
- **18 Waffen und 30 Shop-Items** für unterschiedliche Builds. Stichlinien, Frontbögen, Sprühkegel, Ziel-Fokus und durchdringende UV-Strahlen erweitern die bisherigen Angriffe. Fluorid-Spray bereitet Gegner für Schmelzschaden vor; Turbine und Polierer ergänzen Wasser- und Crit-Builds. Items können sich innerhalb ihrer Stapellimits ergänzen; der Shop bevorzugt gelegentlich Angebote mit passenden Eigenschaften zu deinem Build. Levelaufstiege verbessern zehn Grundwerte. Waffenkarten zeigen Rolle, Treffer, Angriffspause und Reichweite mit den aktuellen Buildwerten. Die Details ergänzen Crit, Effekte, Synergien und Vergleich.
- **Seltene Zahnfee-Kisten** mit höchstens einem normalen Zufallsfund pro Welle. Ihr Item und der Zerlegewert stehen beim Drop fest; die Entscheidung fällt nach der Welle.
- **Fünf göttliche Relikte** mit besonderen Effekten für Blutung, Wasser, Schild, kritische Treffer und Bewegung. Nach den ersten drei Bossen erscheint jeweils eine Auswahl aus drei noch nicht gewählten Relikten.
- Eine **scrollende Arena**, größer als der Bildschirm, mit Mauer und dunklem Außenbereich. Das kompakte HUD zeigt Leben, XP, Münzen, Welle und verbleibende Sekunden.
- Automatisches Speichern während des Laufs. **Fortsetzen** lädt ihn auch nach einem Neustart; ein neues Spiel fragt vor dem Überschreiben nach.
- Musik für Menü, Wellen und Bosse, Kampfgeräusche sowie Regler für Gesamt-, Musik- und SFX-Lautstärke. Eine FPS-Anzeige lässt sich einschalten.

Das Spiel ist ein **spielbarer Prototyp**. Balancing, Effekte und weitere Inhalte sind noch in Arbeit.

**0.2.0 · Pressure + Build Depth** bündelt mehr Gegnerdruck, häufigere Horden, Bullet-Hell-Muster, neue Bossmechaniken, seltene Item-Kisten mit Behalten/Scrappen und mehr Synergien. Die [Patchnotes](CHANGELOG.md) beschreiben die Änderungen gegenüber 0.1.0. Weitere Balance-Arbeit und geplante Ausbaustufen stehen in der [Roadmap](docs/ROADMAP.md).

## Entwicklung

**F4** öffnet in lokalen Desktop-Debug-Builds das pausierende Testmenü. Dort lassen sich Waffen samt Stufe hinzufügen, ändern und entfernen, Items mit ihren normalen Stack-Limits hinzufügen sowie Münzen und Stats setzen. Wellen 1–20 starten direkt mit dem aktuellen Build und vollem Leben, einschließlich der jeweiligen Bosse. F4 oder Escape schließt das Menü und stellt den vorherigen Pausezustand wieder her. Änderungen werden im Run-Spielstand gespeichert; Web- und Release-Builds enthalten keinen zugänglichen Cheat-Modus.

Mit **F3** zeigt ein Debug-Build rollenden DPS, Kills pro Sekunde, Gegnerdichte, Spawns, durch das Gegnerlimit blockierte Spawns, erlittenen Schaden, Boss-Kampfzeit und Wellenbeute. Nach Sieg oder Niederlage zeigt der Run-Rückblick unter anderem Spieldauer, Kills, Schaden, Beute, Kistenentscheidungen sowie die stärksten Waffen und Synergien. Ein JSON-Bericht mit detaillierten Werten pro Welle wird zusätzlich unter `user://run_reports/` gespeichert. Darin stehen auch die mittlere und höchste Zahl gleichzeitig lebender Gegner, das Maximum feindlicher Projektile, Elite-Spawns und -Kills.

Ein reproduzierbarer Boss-/Projektil-Benchmark und der Vorher/Nachher-Vergleich
stehen im [Performance-Bericht](docs/PERFORMANCE_PROJECTILES.md).

Putzeifer und Bewegung verwenden additive Prozentboni; Speichel zählt Regenerationspunkte mit langsamen HP-Ticks. Formeln, Level-up-Werte und die Umrechnung alter Spielstände stehen in [Tempo und Regeneration](docs/STATS_BALANCE.md). Bisskraft verstärkt Schaden prozentual; Nah- und Fernschaden ergänzen gewichteten Basisschaden. Härte reduziert Treffer prozentual. Formeln, Waffenkoeffizienten und gemessene Bosskämpfe stehen im [Schadens- und Verteidigungsbericht](docs/DAMAGE_DEFENSE_BALANCE.md).

Nach dem ersten Godot-Import lassen sich die Tests so ausführen:

```bash
for test in tests/*.gd; do
  godot --headless --fixed-fps 60 --path . --script "res://$test" || exit 1
done
```

Unter Windows können die Tests mit dem Godot-Konsolenprogramm ausgeführt werden
(Namen bei anderer Godot-Version anpassen):

```powershell
Get-ChildItem tests -Filter *.gd | ForEach-Object {
  & Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script ("res://tests/" + $_.Name)
  if ($LASTEXITCODE -ne 0) { throw "Test fehlgeschlagen: $($_.Name)" }
}
```

Eine Vorschau aller neuen Waffen im Shop und ihrer Effekte im Kampf erstellt
`Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_weapon_expansion.gd`
unter `docs/screenshots/weapon_expansion_*.png`, mit einem getrennten Testspielstand.

Die ursprünglichen README-Screenshots erzeugt:

```bash
godot --path . --script res://tools/capture_readme.gd
```

Das Aufnahmeskript schreibt nach `docs/screenshots/` und verändert den normalen Spielstand nicht. Hinweise zu Grafiken, Musik, Sound und Schrift stehen in [CREDITS.md](CREDITS.md).

Den responsiven Shop zeigt `Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_shop_workbench.gd` mit getrenntem Testspielstand in Desktop-, Hoch- und Querformat.
