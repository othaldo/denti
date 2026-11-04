# Don Karamello: weniger Prüfungen, mehr normaler Kampf

Stand: 03.11.2026, nach der [ersten gemeinsamen Bossdruck-Messung](BOSS_PRESSURE_2026_11_03.md).

Neue Kämpfe haben auf Easy/Normal eine Herzprüfung im letzten Drittel und auf
Hard/Hell zwei Prüfungen: Herzboten bei 2/3 Leben und vier Herzen bei 1/3.
Die mittlere Zwei-Herzen-Prüfung entfällt. Ihre Daten und Slotnummer bleiben
erhalten, damit eine laufende alte Prüfung nach dem Laden fertig werden kann.

Erfolgreiche Prüfungen öffnen weiter ein bis zu vier Sekunden langes
Schadensfenster mit Faktor 1,75. Es erlaubt insgesamt höchstens 8 % Bossleben.
Nach Verbrauch endet es sofort; das normale Schadensbudget beginnt bei null.
Don bleibt anvisierbar und greift wieder normal an. Hoher Schaden führt so
nach einem Erfolg wieder durch einen normalen Kampfabschnitt. Brösel bleibt
in allen Phasen aktiv und angreifbar.

Die Bombenfrequenz innerhalb einer Serie steigt auf Normal/Hard/Hell um 20 %.
Landestellen bleiben volle 1,1 Sekunden vorher festgelegt und sichtbar. Don
erholt sich zwischen Angriffsfolgen 15 % kürzer. Auf Hard/Hell fliegen Herzen
zusätzlich 3/6 % schneller; Folgefächer warnen 0,72/0,69 Sekunden. Die erste
Salve behält 0,85 Sekunden Warnzeit. Bossleben und Trefferschaden bleiben wie
vorher. Eine zunächst größere Salvenfolge bestand den langsamen Eckentest mit
Brösel nicht; sie ist nicht Teil dieser Fassung.

## Vollständige Vergleichskämpfe

Vorher: vorhandene 24 Don-Samples aus der gemeinsamen Messung.
Nachher: 24 neue vollständige Kämpfe mit denselben Schwierigkeiten, Builds,
Steuerungen und Seeds. Darunter je drei reaktive und drei kreisende Durchläufe
pro Schwierigkeit/Build. Alle enden am Bossende und erreichen genau die
vorgesehene Zahl von Prüfungen, ohne Aufgabenfehlschlag.

Die Tabelle zeigt die Mediane der reaktiven Durchläufe. Normale Abschnitte
sind die Zeit außerhalb der gesamten Prüfungsroutine einschließlich ihres
Gegenangriffsfensters; reguläre Gesundheitswechsel zählen zum normalen Teil.

| Schwierigkeit / Build | Prüfungen vorher → nachher | Duell vorher → nachher | Normale Abschnitte vorher → nachher |
| --- | ---: | ---: | ---: |
| Normal, Nahkampf | 2 → 1 | 21,6 → 26,6 s | 11,4 → 21,0 s |
| Normal, Fernkampf | 2 → 1 | 20,9 → 25,5 s | 10,9 → 20,6 s |
| Hell, Nahkampf | 3 → 2 | 30,4 → 45,0 s | 13,0 → 33,3 s |
| Hell, Fernkampf | 3 → 2 | 34,7 → 47,2 s | 16,4 → 35,7 s |

Auf Hell stehen zwischen beiden Prüfungsroutinen in allen sechs reaktiven
Samples rund **11,6 Sekunden normaler Kampf**. Zuvor lagen zwischen den ersten
Routinen 0 Sekunden und danach nur 1,62 Sekunden. Der Immunanteil sinkt im
Median von 56,4 auf 29,8 % im Nahkampf und von 44,8 auf 28,1 % im Fernkampf.

| Hell, Schaden außerhalb der Prüfungsroutine | Vorher | Nachher |
| --- | ---: | ---: |
| Nahkampf, tatsächlicher Schaden pro normaler Kampfsekunde | 8,19 | 11,02 |
| Fernkampf, tatsächlicher Schaden pro normaler Kampfsekunde | 3,22 | 3,74 |

Der Don greift dadurch länger normal an und erzeugt dort bei den beiden
Hell-Testbuilds mehr messbaren Schaden. Der gesamte Schaden entspricht auf
Hell im Median 3,24 normalen Lebensbalken im Nahkampf und 1,47 im Fernkampf.
Die Messreserve setzt das Duell fort; diese Zahlen sind keine menschlichen
Siegraten. Die längeren Kämpfe und die zwei deutlicher getrennten Aufgaben
sind der nächste menschliche Testpunkt.

## Zusätzliche Kontrolle nur der normalen Attacken

Je 24 Vorher-/Nachher-Durchläufe beobachten exakt 30 Sekunden ohne Prüfungen
und Spielerwaffen, bei fester Bossphase 2. Brösel bleibt dadurch am Leben.
Dies isoliert den Takt der späten normalen Muster. Es simuliert keinen
vollständigen Kampf und keinen Spieler, der den Minion ausschaltet.

| Reaktiv, Schaden/s im 30-Sekunden-Kontrollfenster | Vorher | Nachher |
| --- | ---: | ---: |
| Normal, Nahkampf | 7,23 | 5,35 |
| Normal, Fernkampf | 4,70 | 3,71 |
| Hell, Nahkampf | 14,62 | 12,09 |
| Hell, Fernkampf | 7,98 | 5,36 |

Die Warnungszahl steigt von 20 auf 21 auf Normal und von etwa 40 auf 41–42
auf Hell. Der Kontrollpilot kassiert trotzdem weniger Schaden. Dichterer
Takt erhöht nicht auf jeder Route monoton die Trefferzahl: Überlagerungen
und Bewegungsentscheidungen ändern sich ebenfalls. Deshalb ist die stärkere
Schadenslast in den normalen Abschnitten der vollständigen Duelle der
relevantere positive Befund; die feste Phasenkontrolle belegt keinen allgemeinen
Schadenszuwachs aller normalen Muster. Spielspaß muss der direkte Test zeigen.

## Bedingungen, Speicherung und Prüfung

- Echte automatische Tier-II-Turbo-Bohrer bzw. Schmelzspiegel in den vollen
  Kämpfen; keine Items/Verzauberungen/Dash. Gleiche 130 Basis-HP und 6 Rüstung.
- 100.000 diagnostische HP mit normalen, anhand von 130 HP berechneten
  Treffer-Schutzzeiten. Grosschaden wird vor Heilung über das Schadenssignal
  gezählt. Die Steuerung kennt die Aufgaben und reagiert verzögert auf Warnungen.
- Godot 4.7.2, feste 60 Hz, Zeitskalierung 1, isolierte Benutzerdaten und
  SFX-Aufrufe ohne Eingriff in den Kampf-RNG.
- 14/14 relevante Kernprüfungen bestanden: komplette 1/1/2/2-Folge,
  begrenzte Gegenangriffe, normaler Kampf danach, Save/Resume einschließlich
  einer alten mittleren Öffnung, Brösels durchgehende Aktivität, verlangsamte
  kombinierte Eckrouten, Bomben-/Fächerwarnungen und ihre Überlappung,
  HUD, Bossabschluss, Endlos sowie Korrodon-/Imperator-Regressionen.
- Zusätzlich besteht `boss_pressure_probe` die Messreserve-/SFX-/Warnungsprüfung.
- Laufberichte: `.godot/test_runs/20261103-220925-705e7c54/results.json`
  und `.godot/test_runs/20261103-221740-c5913183/results.json`.
- [96 Rohsamples in vier Vergleichsarmen samt Zusammenfassungen](don_pressure_rework_2026_11_03.json).

Vollständiges Nachmessen mit isoliertem APPDATA und dem in den Bossdruck-Docs
genannten Godot-Pfad:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/don_pressure_manual/userdata'
& 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --fixed-fps 60 --path . --script res://tools/measure_boss_pressure.gd -- --waves=10 --policies=circle,reactive --output=res://.godot/don_full_manual.json
```

Für das feste 30-Sekunden-Kontrollfenster zusätzlich `--attack-only=true
--seconds=30` verwenden. Die Vorher-Daten dokumentieren die vorherige Fassung;
die Befehle führen die aktuelle Implementation aus.
