# Gift: Depot, Zielwechsel und Rückzug

Stand: **05.11.2026**, P2 des [Klassen-/Synergieplans](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md).
Spielbar mit Good Old Molar, ohne neue Klasse oder Talentpflicht. Die technische
Umsetzung ist abgeschlossen; menschliche Spielstil- und Balanceabnahme bleibt offen.

## Spielablauf und Zugriff

**Depotfüllung** ist ein gewöhnliches Shop-Item für sieben Basismünzen. Ein
echter Waffentreffer legt ein langsam wirkendes Depot an. Denti kann danach
ein anderes Ziel anlaufen und Abstand gewinnen. Bis zu drei Ziele können
gleichzeitig ein Depot tragen; ständiges Nachsetzen füllt dasselbe Depot nicht
erneut. Eine Giftverzauberung wird für diesen Einstieg nicht benötigt.

**Nervensonde** kostet neun Basismünzen und ist ungewöhnlich. Echte Waffentreffer
auf bereits vergiftete Ziele verlangsamen sie kurz. Das hilft beim Verlassen
der Reichweite. Sie funktioniert auch ohne Depotfüllung mit gewöhnlichem Gift.

**Giftzahn** ist das neue Bossrelikt: Beim Wechsel zwischen vergifteten Zielen
wird ein begrenzter Teil des Restgifts am vorherigen Ziel sofort wirksam.
Dieser Anteil wird vorher aus dem Restbudget entfernt. Ein einzelner Boss
erzeugt keine künstlichen Wechsel; Depot und bisheriger Giftaufbau wirken auch
ohne Kills, Nachbarziel oder Relikt.

Der bisherige konzentrierte Aufbau bis zu fünf Giftstufen bleibt erhalten.
Beide Items sind auf je ein Exemplar begrenzt. Es gibt nun 96 Shop-Items und
sechs Relikte. Exakte Angebote: [Items](items.md), [Relikte](relics.md).

## Grenzen und Herkunft

Zentrale Konfiguration: `data/synergies/poison_build.tres`, Typ `PoisonBuildData`.

| Regel | Wert |
| --- | --- |
| Depot-Grundbudget vor Bisskraft | Größerer Wert aus 18 und 125 % des Waffen-Grundtreffers je Wurzel; Stufe und Nah-/Fernschaden zählen |
| Restgift-Bonus | 35 % des bereits vorhandenen normalen Giftbudgets; höchstens ein weiteres Depot-Grundbudget |
| Depotlaufzeit / Tick | 6 s / 0,5 s |
| Gleichzeitige Depots | 3, über alle Waffen gemeinsam |
| Anwendungsintervall / Zielpause | 0,6 s gemeinsam / 8 s pro Ziel |
| Depot-Nachteil | −3 % Putzeifer |
| Nervensonde | 25 % Slow für 1,4 s; Zielpause 3 s |
| Kontrolle auf Eliten / Bossen | Halbe / Viertelwirkung; kein Abbruch von Warnungen, Charges oder Phasen |
| Giftzahn | Wechsel innerhalb 2 s, höchstens 240 Abstand zwischen den Zielen; einmal je 1 s |
| Vorgezogenes Budget | 25 % des normalen Restgifts plus Depotrest; höchstens 30 insgesamt |

Das Depot verwendet den Grundtreffer, einschließlich Waffenstufe und passendem
Schadensattribut, **ohne** Krit, angenommenen Gesamttreffer, Bossbonus oder
Item-Multiplikatorketten. Giftresistenz wird bei Anwendung berücksichtigt,
Verteidigung und Phasenschutz bei tatsächlichem Schaden. Der Bonus aus bereits
resistentem Restgift zahlt seine Resistenz nicht erneut.

Ticks und Reliktfolgeeffekte besitzen keine Waffe. Sie erzeugen keine neuen
Depots, Nervensonden, Reaktionen, Giftstufen oder Lebensraubimpulse. Der normale
Elementreaktionspfad erkennt ein aktives Depot als Gift; die drei vorhandenen
Reaktionen werden hier nicht grundlegend umgebaut.

## Komponenten und Speicherung

- `PoisonBuildEffects`: höchstens drei schwache Zielreferenzen und ein letztes
  Reliktziel. Keine globale Zielsuche oder Gegnerpaarprüfung pro Frame.
- `PoisonDepotState`: maximal zwölf kommende Raten, eigener Tickrest,
  Zielpause, Kontrolltimer und ursprüngliche Waffenreichweite pro Gegner.
- `EnemyAffixEffects` trägt diesen Zustand; sein Aktivitätsflag integriert ihn
  in den vorhandenen normalen und zentralen Bewegungsablauf.
- `RunSnapshot` speichert Referenzen als Gegnerindizes. Laden verbindet sie erst
  nach Wiederherstellung der Gegner. Restbudgets, Kapazität, Intervalle und
  letztes Wechselziel bleiben erhalten; es gibt keine neue freie Anwendung.
- Alte Saves ohne diese Felder starten mit leerem Giftpaketzustand. Neue
  Container und Zahlen werden vor der typisierten Wiederherstellung validiert.

Gift bekommt einen eigenen Build-Tag, unabhängig von Nah-/Fernkampf. Die
Klassenpräferenzen bleiben verwendbar. Relikte besitzen ebenfalls Tags. Wenn
passende unbesessene Relikte vorhanden sind, enthält die Bossauswahl mindestens
eine passende Option und weiterhin freie Alternativen. Kein bestimmtes Relikt
ist garantiert; vorhandene gespeicherte Auswahlen werden nicht neu gewürfelt.

Die normale Kampf-/Rewardfolge bleibt erhalten. Das Paket öffnet keine Modals.

## Messwerte und Prüfungen

Tatsächlicher Schaden erscheint unter `poison_depot` und `poison_switch` in der
vorhandenen Proc-Telemetrie. Weitere Zähler in `enchantment_support`:

- `poison_depots`, `poison_nerve_applications`, `poison_switches`;
- `poison_budget_advanced`: tatsächlich aus dem Restbudget entfernte Menge,
  vor Verteidigung/Phasenbegrenzung; kein zusätzlich erfundener Schaden;
- `poison_depot_kills_outside_range`: nur echte Depot-Tickkills jenseits der
  bei Anwendung gespeicherten Waffenreichweite einschließlich Zielradius.

Das Debug-HUD zeigt eine zusätzliche Giftzeile, sobald Depots/Wechsel auftreten.
Die normale HUD-Ansicht bekommt keine neuen Zahlenfelder.

`tests/poison_build.gd` prüft Erwerb, schnelle Waffen-/Schussereignisse,
gemeinsame und zielbezogene Limits, Resistenz/Verteidigung, Stufenskalierung,
keine Kritübernahme, verlangsamungsresistente Bosse, reine Gift-Bossschäden,
Budgeterhaltung, Reichweite, echte automatische Nah-/Fernangriffe, frühe
Shopangebote, Reliktrelevanz und einen vollständigen Szenenneustart aus dem Save.

Die kontrollierte Probe mit **sechs gleichen Treffern und gleichem Zeitbudget**
liefert 35 Depotschaden beim Fokussieren und 105 bei Verteilung auf drei Ziele.
Das belegt den mechanischen Anreiz; es ist kein Nachweis für bessere Run-Winrates.

Prüfprotokoll:

- Kernintegration: **180/180** in 312,35 s,
  `.godot/test_runs/20261105-140439-c3749dd8`.
- Nach Skalierungsanpassung: **6/6** für Gift, Verzauberungssynergien,
  DoTs, Itemfamilien, Relikte und Verteidigung;
  `.godot/test_runs/20261105-140901-2dc5258e`.
- Nach zusätzlichem Spielstil-/Boss-/Savevertragstest: **5/5**;
  `.godot/test_runs/20261105-141132-38e23c2e`.
- Erweiterte Telemetrie-, Debug- und Atlasprüfung: **3/3**;
  `.godot/test_runs/20261105-141252-001b0a67`.
- Abschließende Relikt-/Synergie-/Klassenprüfung: **5/5**, anschließend nach
  Absicherung noch nicht eingebundener Loadouts **3/3**;
  `.godot/test_runs/20261105-141557-0a2016fe` und
  `.godot/test_runs/20261105-141649-80256cca`.

## Wellenvergleich und offene Abnahme

`tools/benchmark_poison_build.gd` verwendet echte automatische Waffen, Bewegung,
Kollisionen und Wellenpläne des vorhandenen Vergleichswerkzeugs. 36 Proben:
Wellen 4, 5 und 19, je zwei Bohrer oder zwei Bürsten, Gift allein / Items /
Items plus Relikt, Fokus-/Wechselpilot, Seed 13579. Ausrüstung und Stats sind
synthetische Checkpoints, keine vollständig verdienten Runs. Die Items kosten
zusammen 16 Basismünzen mehr; der Kontrollbuild behält dieses Geld ungenutzt.
Der Wechselpilot reagiert auf echte Depotanwendungen, Waffen wählen weiterhin
selbst ihr Ziel. Beide Piloten weichen keinen Warnungen aus und dashen nicht.

Auszug des letzten Laufs, mit beiden Items:

| Welle / Waffe | Fokus: Depot-Schaden | Wechsel: Depot-Schaden | Beobachtung |
| --- | ---: | ---: | --- |
| 4 / Bohrer | 43,5 | 50,9 | Beide beenden die Welle mit 85 Kills; Wechsel erhält hier mehr Schaden. |
| 4 / Bürste | 36,9 | 41,4 | 76 gegenüber 78 Kills; beide behalten 86,8 HP. |
| 5 / Bohrer | 78,7 | 78,7 | Beide töten den isolierten Boss nach ca. 19,1 s; kein Reliktwechsel ohne zweites Ziel. |
| 19 / Bohrer | 295,4 | 360,8 | 41 gegenüber 44 Kills, beide sterben; kein Beleg für bestandene späte Balance. |
| 19 / Bürste | 129,1 | 99,7 | Wechsel stirbt früher und verliert Angriffszeit. Dieser Pilot bestätigt keine Verbesserung. |

Die erste feste 18-Schaden-Variante war zu schwach gegen spätere Gegner und
bezahlte zu hohe Statnachteile. Die aktuelle Variante skaliert deshalb mit dem
Grundtreffer; die Nervensonde besitzt keinen zusätzlichen Bisskraftnachteil.
Es wurden keine bestehenden Blut-/Wassereffekte reduziert.

Offen bleibt ein menschlicher Run mit bewusstem Markieren/Rückzug und ein
vollständig verdienter Vergleich. Insbesondere die Fernkampfroute darf keinen
unnötigen Nahkontakt erzwingen. Solange dieser Nachweis fehlt, ist P2 technisch
spielbar, aber nicht als insgesamt besserer oder fertig balancierter Build
abgenommen. Rohdaten: [36 Proben](balance_poison_package.json).

Reproduktion mit isoliertem Godot-Benutzerverzeichnis und 60 Hz:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/poison_probe_userdata'
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script res://tools/benchmark_poison_build.gd -- --output=res://.godot/poison_build_comparison.json
```

## Gemalte Icons und native Ansichten

Neuer transparenter Atlas: [item_icons_poison.png](../assets/items/item_icons_poison.png).
Er enthält Depotfüllung, Nervensonde und Giftzahn in drei getrennten Zellen.
Erstellt mit dem eingebauten `imagegen`-Tool; vorhandene Item-/Reliktatlanten
dienten als Stilreferenzen. Originale wurden nicht überschrieben.
[Exakter Prompt und Quelle](../assets/items/item_icons_poison.prompt.md).

Geprüft im nativen Godot-Compatibility-Renderer:
[Shop Desktop](screenshots/poison_package/shop_desktop.png),
[Shop Mobil nach Scrollen](screenshots/poison_package/shop_mobile.png),
[Details Mobil](screenshots/poison_package/details_mobile.png),
[Reliktauswahl Desktop](screenshots/poison_package/relic_desktop.png),
[Reliktauswahl Mobil](screenshots/poison_package/relic_mobile.png).
Kleine transparente Kampfbögen und Kontrollmarkierungen bleiben untergeordnet.
`tools/preview_poison_build.gd` erzeugt die nativen Aufnahmen unter `.godot/`.
