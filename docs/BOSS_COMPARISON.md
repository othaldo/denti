# Bossdruck und Schwierigkeitsskalierung

Aktueller Stand nach der Imperator-Überarbeitung: [Finalboss und neuer Vergleich](EMPEROR_FINALE.md).

Neuester Stand vom 31.10.: [Aktueller Bossvergleich und Imperator-Prüfung](BOSS_AUDIT.md), einschließlich neuem Prinzen-Wurftakt, König-Säurefächern und Fluchtpiloten. Dieser Bericht bleibt als frühere Vergleichsmessung erhalten.

Stand: 30.10.2026, Referenzmessung nach v0.6.0 **vor** der Überarbeitung des Königs.
Gemessen mit Godot 4.7.2, 60 Physikschritten/s.

Die anschließende Änderung und ihr Vorher-/Nachher-Vergleich stehen unter
[König: mehr Druck beim Pegelwechsel](KING_PRESSURE_BALANCE.md).
Danach wurden [Prinz und Imperator](ROYAL_PRESSURE_BALANCE.md) überarbeitet.

**Der Graf erzeugt beim einfachen Umlaufen auf Hell deutlich mehr Treffer als die
späteren Bosse.** Die späteren Bosse besitzen dafür mehr HP und wesentlich höheren
Trefferschaden. Die Messung stützt den Eindruck unterschiedlicher Bewegungsanforderungen,
belegt aber keine allgemeine Rangliste der Schwierigkeit vollständiger Runs.

## Vergleich auf Hell

Kontinuierliches Umlaufen mit 230 px/s und angestrebten 320 px Abstand, ohne auf
Warnungen zu reagieren. Mittelwerte über drei feste Gesundheitsphasen und drei
Startwinkel, jeweils 45 Sekunden. Keine Rüstung, Heilung, Waffen, Dash, Adds oder
normalen Gegner; normale Treffer-Unverwundbarkeit und Umgebungsverlangsamung bleiben aktiv.

| Boss | Treffer / 45 s | Aufsummierter HP-Verlust / 45 s | Treffer bei +30 % Lauftempo | Bossbewegung / 45 s |
| --- | ---: | ---: | ---: | ---: |
| Graf, Welle 5 | 23,3 | 924 | 6,3 | 3.446 px |
| Prinz, Welle 10 | 15,6 | 725 | 9,0 | 4.061 px |
| König, Welle 15 | 9,7 | 533 | 6,6 | 2.100 px |
| Imperator, Welle 20 | 9,8 | 876 | 11,1 | 1.311 px |

Der HP-Verlust ist ein unbeschränkt aufsummierter Messwert, keine Überlebensdauer
eines Spielers mit 100 HP. Auch der höhere Trefferschaden des Imperators ist darin enthalten.
Bei normalem Lauftempo trifft der Graf etwa 2,4-mal so oft wie König und Imperator.
Das zusätzliche Lauftempo entschärft den Grafen stark; beim Imperator hilft es diesem
festen Kreis-Piloten nicht. Ein einzelnes Bewegungsmuster bewertet daher keine
vollständige Bossmechanik.

Die Nähe verändert das Bild ebenfalls: Beim Umlaufen mit Zielabstand 160 px liegen
die Trefferzahlen auf Hell bei **10,0 / 12,9 / 11,0 / 13,7**. Im Stillstand bei
**31,3 / 29,0 / 30,3 / 18,8**. Der Graf ist besonders gegen den langsameren
Kreislauf auf mittlere Distanz stark, nicht unter jeder Testbedingung der gefährlichste Boss.

## Skalierung zwischen Schwierigkeitsgraden

Dasselbe mittlere Umlaufen, dieselben Phasen und Startwinkel:

| Boss | Easy: Treffer / 45 s | Normal | Hard | Hell | Hell / Normal |
| --- | ---: | ---: | ---: | ---: | ---: |
| Graf | 12,9 | 9,9 | 13,0 | 23,3 | 2,36× |
| Prinz | 4,6 | 7,3 | 9,0 | 15,6 | 2,12× |
| König | 3,3 | 5,3 | 6,0 | 9,7 | 1,81× |
| Imperator | 3,4 | 7,7 | 7,9 | 9,8 | 1,28× |

Mehr nominelle Schwierigkeit garantiert bei einem festen Piloten keine monotonen
Trefferzahlen: Auf Easy trifft der Graf hier häufiger als auf Normal. Geänderte
Anzahl und Reihenfolge von Kombos verändern auch die Laufwege. Das ist ein
Untersuchungspunkt, kein Beweis, dass Easy insgesamt schwerer wäre.

Beim **HP-Verlust** beträgt Hell/Normal dagegen **3,14× / 2,86× / 3,62× / 3,03×**.
Schadensskalierung und Häufigkeit notwendiger Ausweichentscheidungen sind zwei
verschiedene Größen. Mehr Schaden allein macht die spätere Mechanik nicht aktiver.

Die gemeinsame Stat-Kurve wird bereits für alle Bosse verwendet. Ihre Zuschläge
steigen mit der Welle; deshalb ist Hell gegenüber Normal absichtlich spät stärker:

| Boss | HP-Faktor Hell/Normal | Effektive HP vor Spezialmechaniken | Angriffsschaden-Faktor | Bewegungstempo-Faktor |
| --- | ---: | ---: | ---: | ---: |
| Graf | 1,26× | 1,35× | 1,33× | 1,44× |
| Prinz | 1,37× | 1,52× | 1,63× | 1,48× |
| König | 1,52× | 1,77× | 2,02× | 1,53× |
| Imperator | 1,70× | 2,15× | 2,50× | 1,59× |

Effektive HP bezeichnet hier nur `HP / (1 - damage_reduction)`, ohne Schadensbudget,
Schutzphasen oder besondere Verwundbarkeitsfenster.

Der zusätzliche Angriffsdruck ist dagegen profilspezifisch. In Gesundheitsphase 1
ändern sich von Normal zu Hell unter anderem:

- Graf: 3 → 5 Komboschläge; kontinuierliches Nachpositionieren mit `chase_factor = 2.5`.
- Prinz: 3 → 5 Bomben, 2 → 4 Fächersalven und 7 → 11 Herzen je Fächer.
- König: weiterhin 2 Säurekanäle, aber 1 → 3 Verschiebungen und 4 → 6 Stampfreihen.
- Imperator: 2 → 4 Urteile, 2 → 4 Portale und 3 → 5 Nervenpulse.

Die regulären Warnfenster bleiben erhalten. Kürzere Erholung und mehr Einzelschritte
ergeben bei unterschiedlichen Angriffslängen jedoch unterschiedliche effektive Takte.
Ein gemeinsamer `boss_volley_bonus` erzeugt daher keinen einheitlichen Druckanstieg.

## Lebensdauer und Spielerskalierung

Bei unbegrenzt hohem Spielerschaden und 10 Treffern/s setzt das Schadensbudget
folgende Untergrenzen. Gesundheitsphasen und Schutzpausen sind aktiv:

| Boss | Easy | Normal | Hard | Hell |
| --- | ---: | ---: | ---: | ---: |
| Graf | 18,1 s | 18,1 s | 18,0 s | 18,1 s |
| Prinz | 23,4 s | 23,4 s | 23,5 s | 23,4 s |
| König | 28,9 s | 28,9 s | 28,9 s | 28,8 s |
| Imperator | 46,8 s | 46,8 s | 46,9 s | 46,9 s |

Die weitgehend gleichen Untergrenzen folgen daraus, dass sich Schadensbudget und
Wiederaufladung proportional zur Boss-HP berechnen. Mehr HP erhöht bei starkem
Build dann hauptsächlich den benötigten DPS, nicht weiter die Kampfdauer.
Abweichungen von 0,1 s entstehen durch das diskrete Trefferintervall und Phasengrenzen.

Auf Hell erreichen bereits 350 rohe DPS beim Grafen und Prinzen deren Untergrenze.
Der König benötigt bei 350 DPS 42,0 s, bei 1.000 DPS 28,8 s. Der Imperator benötigt
bei 1.000 DPS 64,7 s und bei 3.000 DPS 46,9 s. Diese Messung gewährt unbegrenzte
Angriffsreichweite und ist keine Simulation eines Waffenbuilds. Nicht besiegte
Proben nach 90 s sind in den Rohdaten als zensiert markiert.

Zusätzlich liegt ein lokaler abgeschlossener Hell-Run vom 27.10.2026 vor
(`run_1793095612_135191071.json`, Abschluss mit Level 46):

| Welle | Boss-Tötungszeit | Durchschnittlicher Gesamt-DPS der Welle | Erlittener Schaden der Welle |
| --- | ---: | ---: | ---: |
| 5 | 46,5 s | 186 | 108 |
| 10 | 34,9 s | 1.056 | 130 |
| 15 | 39,3 s | 3.153 | 83 |
| 20 | 65,1 s | 5.090 | 119 |

Das sind vorhandene Spielberichte, nicht die kontrollierten Tests des aktuellen
Checkouts. Sie enthalten keine Versionskennung. DPS und erlittener Schaden zählen
die gesamte Welle einschließlich Adds und normaler Gegner; sie isolieren den Boss
nicht. Mehrere ältere Berichte enthalten identische fortgesetzte Wellen und wurden
nicht als unabhängige Runs gezählt. Ein anderer Bericht vom 27.10. enthält für
Graf/Prinz 35,9/30,2 s. Diese Beispiele passen zu starkem Spielerwachstum, reichen
aber nicht für eine statistische Aussage über alle Builds oder Spieler.

Die verwendeten [Auszüge der lokalen Run-Reports](boss_comparison_run_samples.json)
enthalten nur die zugehörigen Wellenwerte und ihre Herkunft.

## Konsequenz für die nächste Balance-Runde

Den Grafen als Referenz für aktives Nachsetzen behalten. Zuerst beim König den
Druck auf kontinuierlich umlaufende Spieler erhöhen; beim Prinzen die Lücken
zwischen Salven und beim Imperator die geringe Bewegung beziehungsweise lange
Bindung an feste Muster prüfen. Zusätzlicher Druck sollte neue Positionsentscheidungen
erzwingen und seine vollständige Warnung behalten.

Für alle vier Schwierigkeitsgrade dieselbe Vergleichsmatrix verwenden und getrennt
prüfen: Trefferhäufigkeit, HP-Verlust, Bewegung, Projektilmenge und Tötungszeit.
Vergleichbare Drucksteigerung ist das Ziel; identische Projektilzahlen wären bei
verschiedenen Mechaniken kein sinnvoller Ersatz dafür. Insbesondere sollen sich
Verbesserungen auch bei Nahdistanz und höherem Spielertempo bewähren.

Für eine genaue Bewertung realer Builds fehlen in der gespeicherten Telemetrie
noch bossbezogener eingehender Schaden, Heilung während des Bosskampfs und ein
Snapshot der Spielerwerte beim Boss-Spawn. Derzeit lässt sich eine durch Heilung
neutralisierte Gefahr nicht vom problemlosen Ausweichen unterscheiden.

Die hier dokumentierte Referenzmessung hat keine Kampfwerte oder Spielstände
verändert. Ihre Rohdaten bleiben für den Vergleich mit späteren Änderungen erhalten.

## Reproduzieren und prüfen

[Messskript](../tools/benchmark_boss_comparison.gd), [Rohdaten](boss_comparison.json).
576 Druckproben: 4 Schwierigkeiten × 4 Bosse × 3 Gesundheitsphasen × 4 Bewegungen
× 3 Startwinkel. Zusätzlich 80 Tötungszeitproben: 4 × 4 × 5 DPS-Werte.

Der Spieler behält `max_health = 100` für die normale Berechnung der
Treffer-Unverwundbarkeit. Nur das aktuelle Leben wird als großer Messvorrat gesetzt.
Die Status-Uhren laufen explizit mit. Alle Varianten starten ohne Spielerangriffe;
für die Tötungszeiten werden stattdessen kontrollierte Treffer eingespeist.
Es gibt keinen menschlichen Piloten und keine Aussage über menschliche Siegraten.

PowerShell, aus dem Checkout, mit vom Spiel getrennten Benutzerdaten:

```powershell
$previousDentiAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path (Get-Location) '.godot/boss_comparison_userdata'
    Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --quit
    Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/benchmark_boss_comparison.gd
} finally {
    $env:APPDATA = $previousDentiAppData
}
```

Unter Linux entsprechend `XDG_DATA_HOME` auf ein separates Verzeichnis setzen.
Ein vollständiger neuer Lauf misst den aktuellen Checkout und schreibt nach
`docs/boss_comparison_current.json`; die ursprünglichen Referenzdaten bleiben erhalten.
`-- --quick` misst nur Phase 1 und den ersten Startwinkel sowie die gesättigten
Tötungszeiten und schreibt nach `.godot/boss_comparison_quick.json`.

Die vollständige Matrix wurde auf Vollständigkeit, eindeutige Szenarien und gültige
Messwerte geprüft. Die 64 Druckproben und 16 Tötungszeitproben des separaten
Kurzlaufs stimmen exakt mit den entsprechenden vollständigen Proben überein.
Alle sieben bestehenden `boss_*`-Tests bestanden.
