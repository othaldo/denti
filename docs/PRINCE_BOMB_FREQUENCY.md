# Prinz: schnellerer Bombentakt

Stand: 03.11.2026. Nach dem [Aggressivitätsumbau](BOSS_AGGRESSION.md) und der
[Reduktion der Herzprüfungen](DON_PRESSURE_REWORK.md).

Normal, Hard und Hell werfen innerhalb einer Serie seit der Druckmessung
jeweils 20 % häufiger als zuvor. Easy behält seinen langsameren Takt.

| Schwierigkeit | Frequenz relativ zum bisherigen eigenen Takt | Bisheriger Wurfabstand | Neuer Wurfabstand | Vorwarnung pro Landestelle |
| --- | ---: | ---: | ---: | ---: |
| Easy | ×0,75 | 1,28 s | 1,707 s | 1,10 s |
| Normal | ×1,20 | 1,28 s | 1,067 s | 1,10 s |
| Hard | ×1,80 | 1,32 s | 0,733 s | 1,10 s |
| Hell | ×2,40 | 1,36 s | 0,567 s | 1,10 s |

Der Abstand bezieht sich auf aufeinanderfolgende Bomben innerhalb derselben Serie. Andere Angriffsarten und die Übergänge zwischen Serien besitzen weiterhin eigene Takte; Bomben pro Minute über das gesamte Repertoire steigen deshalb nicht pauschal um denselben Faktor.

## Überlappung und Lesbarkeit

Ausholen (0,50 s) und Flug (0,60 s) bleiben gleich. Auf Normal/Hard/Hell beginnt die nächste vollständige Warnung bereits vor der Landung der vorherigen Bombe. Jede Bombe erhält einen eigenen Startpunkt, ein festgelegtes Ziel und einen eigenen Fortschritt. Der vorhandene begrenzte Vorhalt beim zweiten Wurf bleibt wirksam. Die Warnung verfolgt Denti danach nicht weiter.

Es werden im regulären Ablauf höchstens zwei Bomben gleichzeitig angekündigt/gezeichnet. CaramelBombVolley verwendet eine begrenzte Liste mit harter Obergrenze drei und keinen Node pro Bombe. Die vier gemeinsamen Karamellpfützen bleiben ebenfalls begrenzt. Es entstehen keine zusätzlichen Vollbildeffekte oder Texturen.

[Native Hell-Ansicht mit zwei Warnungen](screenshots/prince_bomb_frequency.png).

## Ablauf und Speicherstände

Der neue BOMB_SEQUENCE-Zustand ist hinten an die Zustandsliste angehängt. Er steuert die nächste Warnung; der Bombenbatch verarbeitet Abwurf und Landung an ihren tatsächlichen Zeitpunkten. Große Frames werden an diesen Ereignissen geteilt. Nach der letzten Landung folgt die bisherige vollständig angekündigte Fächerkombination bzw. Erholung.

Version 3 des Prinzen-Snapshots speichert alle laufenden Bomben inklusive Alter, Ziel, Startpunkt und Abwurfstatus. Versionen 1 und 2 bleiben lesbar. Bereits gespeicherte serielle Warnungen/Flüge werden mit voller Vorwarnung beendet und erst eine neue Serie nutzt die überlappende Darstellung. Pause hält alle Bombenuhren an. Gesundheitspausen und Tod räumen eigene Bomben auf.

## Geprüft

- Tatsächliche Warnungs-/Abwurfabstände auf allen vier Stufen; jede Landung weiterhin erst nach 1,10 s.
- Mindestens eine vollständige Serie je Stufe; keine ausgelassene oder doppelte Landung und höchstens zwei gleichzeitige Bomben.
- 48 vollständige, warnungsbewusst ausgewichene Bombenserien bei durchgehend 72 % Grundtempo: vier Schwierigkeiten, vier Ecken und Desktop/Hoch-/Querformat. Echte Vorhalt-Ziele, kein Dash und kein Weg durch den Bosskörper. Diese beobachteten Wege sind keine allgemeine Garantie für sämtliche Überlagerungen einer echten Welle.
- Feste Bombenziele trotz späterer Würfe; große Frames, Pause, in-memory Snapshots und echtes Fortsetzen mit einer fliegenden sowie einer noch ausholenden Bombe.
- Alte Version-2-Warnung, ungültige Bombendaten, Gesundheitspause und Todesbereinigung.
- Bestehende Prinzen-, Fächer-/Kranz-, Aggressivitäts-, Kombinations-, Mindestkampfdauer- und Endlos-Ablauftests.
- Native Sichtprüfung: unabhängige Lichtfronten und Flugpositionen, pixelgleiche Pause.

Reproduzieren mit isoliertem APPDATA unter .godot:

~~~powershell
python tools/run_tests.py --godot GODOT_BINARY --filter prince_bomb_frequency --filter prince_bomb_routes
godot --path . --script tools/preview_prince_bomb_frequency.gd
~~~
