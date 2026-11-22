# Meta-Progression: Waffen-Freischaltungen

Stand: 22.11.2026. Erster Baustein (Slice 1) im Spiel umgesetzt.

## Ziel

Neue Spieler beginnen mit einer überschaubaren Auswahl. Komplexere Waffen
und die besonders sicheren Flächen-/Fernwaffen kommen erst hinzu, wenn man das
Spiel kennt. Freischaltungen sind **horizontal**: neue Optionen, keine
dauerhaften Schadens-, HP- oder Dashboni. Es zählen nur die Ketten: Auch wer
eine Waffe vor dieser Version schon gemeistert hat, schaltet sie über ihre Kette
frei. Siegel selbst bleiben erhalten.

Freischaltungen sind kein Ersatz für Balance. Sobald UV-Lampe oder
Mundduschen-Turbine freigeschaltet sind, gelten für sie dieselben Regeln wie
vorher. Ob sie im späten Run Positionierung aushebeln, muss weiterhin über
Welle 10–20 gemessen werden.

## Startpool

Acht Waffen sind von Anfang an verfügbar, je Rolle mindestens zwei:
Zauberbürste, Turbo-Bohrer, Zahnseidenpeitsche, Wasserflosser,
Zahnstocher-Speer, Amalgam-Schleuder, Zahnsteinkratzer, Fluorid-Sprüher.
Jede Klasse hat damit mindestens zwei passende Starts; die Assassine erhält
Bohrer und Kratzer.

## Ketten

Eine Freischaltung verlangt ein [Meisterschafts-Siegel](WEAPON_MASTERIES.md)
mit einer der genannten Startwaffen. Die einfachere Waffe bringt die Mechanik
bei, die komplexere baut darauf auf.

| Freigeschaltet | Siegel | Mit Startwaffe |
| --- | --- | --- |
| Schmelzspiegel | Zahnprüfung | Zauberbürste |
| Prophylaxe-Polierer | Zahnprüfung | Zahnsteinkratzer |
| Karies-Fräse | Zahnprüfung | Turbo-Bohrer |
| Interdental-Bürste | Zahnprüfung | Turbo-Bohrer oder Zahnsteinkratzer |
| Zahnseiden-Schneide | Zahnprüfung | Zahnseidenpeitsche |
| Kronenwerfer | Zahnprüfung | Amalgam-Schleuder oder Zahnstocher-Speer |
| Mundspülungs-Mörser | Zahnprüfung | Wasserflosser |
| **UV-Lampe** | **Bronze** | Schmelzspiegel oder Prophylaxe-Polierer |
| **Mundduschen-Turbine** | **Bronze** | Wasserflosser oder Fluorid-Sprüher |
| **Fluorid-Rakete** | **Bronze** | Mundspülungs-Mörser oder Kronenwerfer |

Zahnprüfung = ersten Boss in Welle 5 besiegen (auch Easy).
Bronze = Welle 20 auf Normal oder höher gewinnen.

## Regeln

- Der Status wird **nur aus den vorhandenen Siegeln abgeleitet**;
  `progression.cfg` erhält kein neues Feld. Ältere Siegel zählen damit
  rückwirkend.
- Ein eigenes Siegel der gesperrten Waffe zählt nicht; nur die Quellwaffen
  der Kette öffnen sie. So beginnen auch bestehende Profile mit wenigen Waffen.
- Gesperrte Waffen erscheinen in der Startauswahl gedimmt mit Schloss. Antippen
  zeigt Bild, Namen und Bedingung statt der Werte; „Run starten“ bleibt
  deaktiviert.
- Der Shop bietet gesperrte Waffen nicht an. Eine bereits ausgerüstete gesperrte
  Waffe (etwa aus einem alten Spielstand) bleibt für Fusionen im Angebot.
- Neue Freischaltungen nennt das bestehende Meisterschafts-Banner nach dem
  Loot-Sweep („Neu: …“). Der Hinweis überlebt Fortsetzen; er erscheint
  einmal.
- Testarenen sowie Läufe über ein Skript (Tests, Bots, Benchmarks) verwenden den
  vollständigen Katalog (`GameSession.weapon_locks_enabled`). Tests für
  Freischaltungen schalten sie ausdrücklich ein.
- Das F4-Testmenü kann weiterhin jede Waffe hinzufügen.

## Daten und Code

- `data/unlocks/*.tres` (`WeaponUnlockData`): Waffe, Quellwaffen, benötigtes Siegel.
- `WeaponUnlocks`: Regeln, Bedingungstext und neu freigeschaltete Waffen.
- `GameSession.weapon_unlocked(id)`: einzige Abfrage für Menü, Starter und Shop.
- `ShopController.weapon_available`: optionaler Filter, im Spiel gesetzt.
- `RunWeaponMastery.unlocks / pending_unlocks`: Bannerzustand im Run-Spielstand.
- Test: `tests/weapon_unlocks.gd`.

## Nächste Slices

1. ~~Waffen~~ (umgesetzt)
2. Klassen: Good Old Molar und Assassine sofort, übrige über kurze thematische Aufgaben.
3. Komplexe Synergie-Items und Relikte nach und nach in den Pool.
4. Kariesstufen pro Klasse: jeder Sieg öffnet eine Stufe mit zusätzlichem Druck
   (Elites, Projektile, weniger Heilung) statt höherer Gegner-HP.
