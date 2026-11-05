# Assassine und gemeinsame Talentverteilung

Stand **05.11.2026**: spielbare Umsetzung von P3 des
[Klassen-/Synergieplans](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md).
Vollständige Run-/Endlosbalance und menschliche Spielstilabnahme bleiben offen.

## Klassenauswahl

Die Vorbereitung führt durch **Schwierigkeit → Klasse → Waffe**. Bereits gewählte
Werte bleiben im Entwurf gespeichert. Ein Klassenwechsel verwirft eine
unzulässige Startwaffe; ein begonnener Run behält Klasse und Wurzelparameter.

| Eigenschaft | Good Old Molar | Assassine |
| --- | --- | --- |
| Wurzeln / Start-Schmelz | 6 / 100 | 4 / 85 |
| Waffen | Freie reguläre Waffenwahl | Kurze Kontaktwaffen; keine Fernwaffen, langen Fadenwaffen oder Speere |
| Startbonus | Bisherige Grundwerte | +3 Nahschaden, +8 % Bewegung |
| Nahschadensgewinne | Normal | ×1,25; negative Beiträge bleiben unverändert |
| Dashvorrat / Kosten / Nachladen | 100 / 100 / 25 pro s | 150 / 75 / 30 pro s |
| Kontaktschaden während Dash | ×1,5 | ×0,65 |
| Antritt | Über Talent erlernbar | Erster akzeptierter Kontaktwaffentreffer binnen 0,9 s nach Dash: +20 Prozentpunkte Waffenschaden |

Der Assassine beginnt mit zwei Dashes. Treffer, Kills und Talente füllen keine
Dashladung gratis auf. Projektile bleiben gefährlich. Startwahl, Shop, Fusion,
Evolution und Save verwenden weiterhin dieselbe zentrale Waffenfreigabe.
Daten: `data/classes/assassin.tres`, `data/classes/good_old_molar.tres`.

## Ein gemeinsames Levelpunktebudget

Neue Runs erhalten pro verdientem Level **einen Punkt für Talent oder Attribut**.
Nach dem Loot-Sweep erscheinen alle vorgemerkten Punkte gemeinsam. Kapseln
finanzieren weiterhin getrennte Waffenpunkte.

Die Attributstufe wird pro verdientem Level einmal mit den vorhandenen
Level-/Glücksregeln gewürfelt. Alle brauchbaren Attribute stehen zur Auswahl;
Undo und Fortsetzen würfeln die Stufen nicht erneut. Der Assassine erhält keinen
unbrauchbaren Fernschadenskauf. Klassenfaktoren und Grenzen gelten auch für
Talentstatbeiträge und Vorschau.

Wahlen bilden zunächst einen Entwurf. **Rückgängig** nimmt den letzten Kauf zurück.
**Übernehmen** prüft den ganzen Entwurf, vergibt Beiträge genau einmal und setzt
die Rewardqueue fort. Alle vorgemerkten Punkte müssen verteilt sein. Die Vorschau
ändert weder HP noch Stats, Talente oder Dashladung. Alle ausgelieferten Knoten
kosten zunächst einen Punkt.

Alte Runs ohne aktivierte Talentprogression behalten ihre Statkarten, gespeicherten
Auswahlen und Rerolls. Es gibt keine rückwirkenden kostenlosen Talentpunkte.

## Zwei Assassinenwege

Frühe Knoten sind kombinierbar. Die Abschlüsse schließen einander aus und
benötigen drei Ränge im jeweils vorherigen Knoten.

| Weg | Einstieg, 1 Rang | Vertiefung, 3 Ränge | Abschluss, 1 Rang |
| --- | --- | --- | --- |
| Giftlauf | **Giftstich:** Antritt legt ein Depot mit 75 % Grundstärke an. | **Flüchtig:** +4 % Bewegung je Rang. | **Beißwechsel:** Antritt gegen ein anderes Ziel als beim letzten Antritt: weitere +25 Prozentpunkte Schaden, auch nach einem Kill. |
| Nachsetzen | **Druckpunkt:** Bis zu vier Fokusstufen mit je +4 Prozentpunkten Schaden. | **Bisspolster:** +8 Schmelz je Rang. | **Durchziehen:** Bei vier Fokusstufen weitere +20 Prozentpunkte gegen dieses Ziel. |

Giftstich funktioniert ohne Shop-Pflichtteil und nutzt den vorhandenen Depotcode:
maximal drei Ziele, gemeinsames 0,6-s-Intervall, 8-s-Zielpause. Depotfüllung behält
ihre volle Stärke und ermöglicht Depots unabhängig vom Antritt. Nervensonde,
Giftzahn und Reaktionen erkennen die Klassendepots. Giftstich ergänzt den
Gift-Tag für Shop und Relikte.

Nachsetzen hält genau eine Fokusreferenz. Aufbau ist höchstens alle 0,45 s
möglich. Ohne Treffer auf dieses Ziel verfällt der Fokus nach 2 s. Zusätzliche
Mehrzielkontakte stehlen den lebenden Fokus nicht. Nach seinem Tod kann ein
neues Ziel aufgebaut werden. Der Bonus wirkt nur gegen das Fokusziel.

Die Boni gehen additiv durch das gemeinsame Schadensmodell. DoTs/Folgeeffekte
aktivieren weder Antritt noch Fokus. Blockierte Bosstreffer verbrauchen keinen
Antritt. Kein Knoten vergibt Dashladung oder verlangt eine Killkette.

## Good Old Molar

Der Basis-Denti verwendet dieselbe Verteilung, freie Waffenwahl und alle Attribute.

| Weg | Knoten |
| --- | --- |
| Freie Werkzeugwahl | **Werkzeugkunde:** je +1 Nah-/Fernschaden, drei Ränge. **Anlauf nehmen:** erster Waffentreffer binnen 0,9 s nach Dash +20 Prozentpunkte Schaden. **Wurzelreserve:** +15 Wurzelkraft je Rang, drei Ränge. |
| Standfest | **Solider Schmelz:** +2 Härte je Rang, drei Ränge. **Nachpolieren:** +0,4 Speichel je Rang, drei Ränge. **Versiegelung:** 50 % Überheilung speisen den bestehenden Schildvorrat; je 20 ein Schild, maximal fünf. |

Überheilung teilt Vorrat und Schutzgrenzen mit Speichelkelch. Talentbeiträge
eröffnen keine zweite Schildschleife.

## Komponenten und Speicherung

- `TalentNodeData` / `TalentTreeData`: Resources für Ränge, Voraussetzungen,
  Kosten, exklusive Abschlüsse und Beiträge in `data/talents/`.
- `TalentProgression`: Attributstufen, Entwurf, Vorschau und atomare Bestätigung.
  Statbeiträge laufen durch `PlayerStats.apply_upgrade()`.
- `ClassCombatData` / `ClassCombatEffects`: Antritt/Fokus mit begrenzten schwachen
  Zielreferenzen; keine globale Gegnersuche im Kampf.
- `TalentPanel`: gemeinsame Reward-Bühne, verbundene Pfade, Attribute und Details
  auf Auswahl; Tastatur-/Controllerfokus und feste Bestätigungsaktionen.
- `RunSnapshot`: separate `talents`-Version und `class_combat`. Zielreferenzen
  werden nach Wiederherstellung der Gegner wieder verbunden.

Laden addiert gespeicherte Talentstatbeiträge nicht erneut. Offene Käufe,
Attributstufen, Tab und Auswahl bleiben erhalten. Antrittsfenster, Fokusstufen,
Aufbausperre und letztes Antrittsziel überleben Combat-Resume. Ein totes vorheriges
Ziel bleibt als begrenzte Verlaufsaussage erhalten; kein Gegner wird dafür am
Leben gehalten. Wellenstart setzt die kurzen Kampfzustände zurück.

Ungültige Versionen, IDs, Ränge, Eltern, Abschlüsse und Entwürfe über dem
Levelbudget werden vor Wiederherstellung abgewiesen. Wellen-Startbuild und
Run-Bericht enthalten die Talente. Support-Zähler: `class_openers`,
`class_switch_openers`, `class_focus_steps`, `class_focus_finish_hits`.
Schaden steht weiterhin bei den tatsächlichen Waffen und bekannten Gift-Procs.

## Prüfung und verdiente Eröffnungsruns

`tests/class_talents.gd` prüft Klassenauswahl, Waffenfilter, gemeinsames Budget,
Voraussetzungen, exklusive Abschlüsse, Klassenfaktoren, unverbindliche Vorschau,
Loot vor Verteilung, weitere Rewards vor Shop, Entwurf über Szenenneustart,
Antritt, Fokus, Bossphasen und Legacy-Statkarten. 320×568, 568×320 und 1280×720
prüfen Footer, Header und Attributbeschriftung.

Nach Beißwechselkorrektur: **7/7** gezielte Prüfungen,
`.godot/test_runs/20261105-145453-f39280af`. Erweiterte Telemetrie-, Debug- und
Statgrafikprüfung: **3/3**, `.godot/test_runs/20261105-145204-0b795867`.
Abschließende Kernregression: **181/181**, 316,46 s,
`.godot/test_runs/20261105-145558-4be718e3`.
Zusätzlicher echter F-Tastendruck nach Wiederaufnahme: **1/1**,
`.godot/test_runs/20261105-150305-2a89dadf`.

`tools/benchmark_class_talents.gd` nutzt den bestehenden Earned-Run-Ablauf:
ein freier Startbohrer, tatsächliche HP/XP/Drops, verdiente Punkte, gekaufte
Shopangebote und bezahlte Rerolls. Dieselbe Feuer-Upgradepolitik für alle, echte
Dashanfragen mit endlichem Vorrat, keine Warnungsreaktion oder Gratisheilung.
Zwei Seeds je Weg, Normal, Wellen 1–5. Ende beim ersten Bosskill, vor dessen
anschließenden Belohnungen. Skriptierte Entscheidungen, keine menschlichen Winrates.

| Weg | Seeds | Boss-TTK | Level / verteilte LP | Dashes | Eigene Wirkung |
| --- | --- | --- | --- | --- | --- |
| Good Old Molar | 13579 / 24680 | 18,52 / 19,05 s | 12 / 11 | je 43 | 31 / 30 Antritte |
| Giftlauf | 13579 / 24680 | 18,63 / 19,02 s | 12 / 11 | je 66 | 7 / 5 Depots, 24 / 27 Wechselantritte |
| Nachsetzen | 13579 / 24680 | 18,68 / 19,53 s | 12 / 11 | je 66 | 50 / 49 Treffer mit Fokusabschluss |

Alle sechs Proben besiegen den ersten Boss. Die erste Wechselbedingung verlangte
ein noch lebendes vorheriges Ziel und blieb früh ohne Auslösung. Die aktuelle
Regel erlaubt Wechsel nach einem Kill und ist gegen Resume und dasselbe Ziel
gesondert geprüft. [Rohdaten](balance_class_talents.json).

Offen: menschliche Gift-/Fokusläufe, mobile Bedienung im echten Run, vier gegen
sechs Wurzeln im späten Ausbau und weitere Starter. Danach Abschlussbalance;
Eis/Feuer folgen als eigene Pakete, Hüter/Spültechniker später.

Reproduktion mit isoliertem Benutzerverzeichnis:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/class_earned_userdata'
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script res://tools/benchmark_class_talents.gd -- --output=res://.godot/class_talent_earned.json
```

## Native Ansichten und Grafik

[Klassen Desktop](screenshots/class_talents/classes_desktop.png),
[Klassen Mobil](screenshots/class_talents/classes_mobile.png),
[Baum Desktop](screenshots/class_talents/tree_desktop.png),
[Baum Mobil](screenshots/class_talents/tree_mobile.png),
[Attributvorschau Mobil](screenshots/class_talents/stats_mobile.png),
[Offener Entwurf](screenshots/class_talents/draft_desktop.png),
[Good Old Molar Mobil](screenshots/class_talents/molar_mobile.png).
Native Godot-Compatibility-Aufnahmen mit `tools/preview_class_talents.gd`.

Neues gemaltes Porträt: [assassin_portrait.png](../assets/classes/assassin_portrait.png).
Eingebautes `imagegen`, transparente Ausgabe, kanonisches Denti als Referenz.
[Exakter Prompt](../assets/classes/assassin_portrait.prompt.md).
Bestehende Referenzen und Kampfgrafiken bleiben erhalten.
