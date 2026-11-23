# Meta-Progression: Freischaltungen

Stand: 23.11.2026. Waffen und Klassen werden freigeschaltet.

## Ziel

Neue Spieler beginnen mit einer überschaubaren Auswahl, und jeder Run, auch ein
verlorener, bringt sichtbaren Fortschritt. Freischaltungen sind **horizontal**:
neue Optionen, keine dauerhaften Schadens-, HP- oder Dashboni.

Leitlinien für den „nur noch eine Runde“-Effekt (angelehnt an Brotato):

- **Jeder Run zählt.** Kills, Bosse, Elites, Münzen und Tode sammeln sich über alle
  Runs. Zähler gehen nie verloren.
- **Immer ein nächstes Ziel.** Das Run-Ende zeigt neben Neuem die nächsten Ziele
  („Fast geschafft“) mit Fortschrittsbalken.
- **Dichter Anfang, langer Schwanz.** Die ersten Runs öffnen fast jedes Mal etwas,
  spätere Ziele brauchen länger.
- **Keine Ketten, kein Zufall.** Jede Bedingung nennt etwas, das man von Anfang an
  erreichen kann. Keine Regel setzt eine gesperrte Waffe voraus.
- **Feiern.** Neue Waffen meldet das Banner nach der Welle und eine Karte am Run-Ende;
  in der Auswahl tragen sie ein „Neu“-Abzeichen, bis man sie einmal startet.

Freischaltungen sind kein Ersatz für Balance. Ob UV-Lampe oder Mundduschen-Turbine
im späten Run Positionierung aushebeln, muss weiterhin gemessen werden.

## Startpool

Acht Waffen sind von Anfang an verfügbar: Zauberbürste, Turbo-Bohrer,
Zahnseidenpeitsche, Wasserflosser, Zahnstocher-Speer, Amalgam-Schleuder,
Zahnsteinkratzer, Fluorid-Sprüher. Spielbar ist zunächst nur Good Old Molar.

## Waffen

| Waffe | Bedingung |
| --- | --- |
| Interdental-Bürste | einmal ausfallen (Trostpreis für den ersten Tod) |
| Karies-Fräse | 500 Kills |
| Kronenwerfer | 3 Bosse |
| Zahnseiden-Schneide | 25 Elites |
| Prophylaxe-Polierer | 1.500 Münzen eingesammelt |
| Schmelzspiegel | 2.500 Kills |
| Mundspülungs-Mörser | 10 Bosse |
| Mundduschen-Turbine | Welle 20 gewinnen mit Spültechniker |
| UV-Lampe | Welle 20 gewinnen mit Zahnfee |
| Fluorid-Rakete | Welle 20 gewinnen mit Glutzahn |

Bosse zählen Mini- und Endbosse, Elites nur Elite-Gegner, Münzen nur eingesammelte
Münzen. Klassensiege zählen auf jeder Schwierigkeit.

[Meisterschafts-Siegel](WEAPON_MASTERIES.md) bleiben Trophäen pro Waffe und
schalten nichts frei.

## Klassen

Jede Klasse außer Good Old Molar öffnet sich am Ende eines Runs, wenn Denti in
diesem Moment eine Waffe mit einem passenden Element trägt. Der Run muss
mindestens Welle 10 erreicht haben und darf durch Tod oder Sieg enden. Als
Element zählen die Schadensart (Wasser, Licht) und jede Element-Verzauberung
(Feuer, Eis, Gift, Blutung, Elektro, Wasser).

| Klasse | Bedingung |
| --- | --- |
| Assassine | Gift-Waffe |
| Spültechniker | Wasser-Waffe |
| Glutzahn | Feuer-Waffe |
| Frostwächter | Eis-Waffe |
| Zahnfee | Elektro-Waffe |
| Nekrodent | Welle 20 auf Normal oder höher gewinnen, mit einer Blutungs- oder Gift-Waffe |

## Regeln

- Zähler sammeln sich im Run (`RunMetaProgress`) und gehen nach jeder Welle sowie
  am Run-Ende ins Profil. Nicht übertragene Zähler überleben Speichern/Fortsetzen.
- Nur wertbare Runs zählen (keine Testmenü-Eingriffe, keine Testarenen).
- Gesperrte Waffen erscheinen in der Startauswahl gedimmt mit Schloss; Antippen zeigt
  die Bedingung samt Fortschritt („2.312 / 2.500 Kills“). Gesperrte Klassen zeigen
  ein Schloss und ihre Bedingung.
- Der Shop bietet gesperrte Waffen nicht an. Eine bereits ausgerüstete gesperrte
  Waffe bleibt für Fusionen im Angebot.
- Bestehende Profile starten versiegelt; bisherige Kills wurden nie gezählt.
- Testarenen sowie Läufe über ein Skript (Tests, Bots, Benchmarks) verwenden den
  vollständigen Katalog und die regulären Klassen (`GameSession.weapon_locks_enabled`).
- Das F4-Testmenü kann unter **Run → Alles freischalten** alle Klassen und Waffen im
  lokalen Profil öffnen.

## Daten und Code

- `data/unlocks/*.tres` (`WeaponUnlockData`): Zähler und Zielwert oder Klassensieg.
- `data/unlocks/classes/*.tres` (`ClassUnlockData`): Elemente, Mindestwelle, Sieg.
- `WeaponUnlocks`, `ClassUnlocks`: Regeln, Fortschritt, Bedingungstexte.
- `MetaCounters`: Zählerschlüssel und Zahlenformat.
- `ProgressionStore`: `counters`, `class_victories`, `unlocked_classes`, `fresh_unlocks`.
- `GameSession`: `weapon_unlocked`, `class_unlocked`, `add_meta_progress`,
  `record_class_unlocks`, `near_unlocks`, `mark_seen`.
- Tests: `tests/weapon_unlocks.gd`, `tests/class_unlocks.gd`.

## Nächste Schritte

1. Relikte nach und nach in den Pool (z. B. ab 20 Bossen).
2. Kariesstufen pro Klasse: jeder Sieg öffnet eine Stufe mit zusätzlichem Druck
   (Elites, Projektile, weniger Heilung) statt höherer Gegner-HP.
3. Langzeitziele mit kosmetischen Titeln, etwa „Alle huldigen dem Denti“ ab 25.000 Kills.
