# Nass: Verlangsamung und Synergien

Seit dem 4. Oktober 2026 hat Nass auch ohne Items einen eigenen Nutzen:

| Gegner | Weniger Lauftempo |
| --- | ---: |
| Normale Gegner | 20 % |
| Eliten | 10 % |
| Bosse | 5 % |

Die Werte liegen gemeinsam in `data/statuses/wet.tres`. Die Verlangsamung gilt
für Verfolgung sowie Rückzug/Seitwärtsbewegung von Ferngegnern. Angekündigte
Anstürme, Schussgeschwindigkeit, Angriffstimer und Schutzphasen bleiben unverändert.
Damit stimmen die angekündigten Angriffsstrecken weiterhin mit der Bewegung überein.

Alle bisherigen Nassquellen verwenden dieselbe Regel: Wasserflosser, Turbine,
Spülventil-Pfützen, Gezeiten-Siegel und Gewitterdusche. Wasserflosser durchnässt
für 2,5 Sekunden, Turbine für 3 Sekunden. Leitlack verlängert Waffen-Nass um
0,5 Sekunden und behält seinen Wasser-/Licht-Schadensbonus. Kettenitems behalten
ihre zusätzliche Reichweite von 85 Pixeln bei nassen Ausgangszielen.

Wiederholtes Durchnässen setzt die verbleibende Zeit auf das Maximum aus Restzeit
und neuer Dauer. Es addiert weder die Zeit noch weitere Verlangsamung. Mehr
Leitlack verstärkt den Slow nicht. Grundtempo bleibt erhalten: Slow wird aus
der aktuellen Nassdauer abgeleitet und mit aktiver Elite-Haste sowie
Boss-Entzündung verrechnet. Beim Ablauf entfällt nur der Nassfaktor.

Save/Resume speichert bereits `wet_time`; aus der verbleibenden Dauer und dem
Gegnerrang wird die Wirkung nach dem Laden erneut abgeleitet. Zusätzliche
Save-Felder oder eine Migration sind nicht nötig. Waffenkarte nennt den Slow,
die Details erklären Elite-/Bosswirkung und die Ausnahme für Anstürme.

`tests/wet_slow.gd` prüft tatsächliche Bewegung normaler Gegner, Ferngegner,
Eliten und Bosse, wiederholte Anwendung, Ablauf, unverändertes Grundtempo,
Zusammenspiel mit Haste/Entzündung, angekündigte Anstürme, Waffen-/Pfützenquellen,
Save/Resume für alle drei Gegnerränge und die Beschreibungen.

```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tests/wet_slow.gd
```

Der stationäre Waffen-DPS-Vergleich verändert sich dadurch nicht. Der praktische
Mehrwert ist zusätzliche Zeit und Platz beim Ausweichen; Winrate und dichte
Hard-/Hell-Wellen brauchen weitere Spieltests.

Die [erneute Bosskontrolle mit Nass-Slow](balance_wet_slow_bosses.json) verwendet
denselben gemischten Referenzbuild wie der Waffenpass. Welle 5/10/20 dauert
18,2/23,6/47,5 Sekunden bis null Boss-HP; beide Schutzphasen kommen zum Einsatz.
Alle neun relevanten Tests bestehen: `wet_slow`, `enemy_behaviors`, `elite_aura`,
`boss_overtime`, `item_synergies`, `weapon_rework`, `weapon_expansion`,
`weapon_evolutions` und `weapon_dps_balance`.
