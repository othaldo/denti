# Bohrwerkzeuge: sichere Kontakte und früher Ausbau

02.11.2026 · aufbauend auf dem [verdienten Hell-Einstieg](EARNED_PROGRESSION.md).
Setboni bleiben auf Nutzerwunsch zurückgestellt. Dieser Pass prüft kleine
Waffenverbesserungen und eine mögliche Mindestversorgung getrennt.

Dieser Bericht hält seinen ursprünglichen Messstand fest. Der anschließende
[Kontaktwaffen-Pass](CONTACT_WEAPON_BALANCE.md) ergänzt kleine Rückstöße,
Kratzerkontakte und einen eigenen Angriffszähler für den Polierer.

## Befund vor den Änderungen

54 echte Einstiegskontrollen: sechs Waffen, je neun identische Hell-Seeds,
aktive Zielsuche, ein kostenloser Starter und bezahlte Progression bis W5.
Erfasste Stöße benutzen echte Animation und Kollision. Unterbrochene Angriffe
bei Tod/Wellenende werden nicht als abgeschlossene Fehlschläge gezählt.

| Waffe | Ziel vor Kontakt verloren, kein Treffer | Abgeschlossene Stöße | Anteil |
| --- | ---: | ---: | ---: |
| Turbo-Bohrer | 950 | 5.379 | 17,7 % |
| Zahnsteinkratzer | 640 | 2.862 | 22,4 % |
| Prophylaxe-Polierer | 548 | 4.112 | 13,3 % |
| Karies-Fräse | 11 | 1.171 | 0,9 % |

Beim Bohrer geht damit ein relevanter Teil der Angriffe verloren, weil das Ziel
vor dem Kontakt besiegt wird, etwa durch andere Waffen oder laufende Effekte. Bei der Fräse erklärt
dieser Effekt die frühe Schwäche kaum: Nur 2/9 Proben überstehen W1.

## Beibehaltene Änderungen

### Turbo-Bohrer

- Stirbt das ausgewählte Ziel vor Kontakt, kann der unveränderte sichtbare
  Stoß ein anderes Ziel auf seiner Bahn treffen. Er dreht dabei nicht nach.
  Ein noch lebendes ausgewähltes Ziel wird nicht automatisch ausgetauscht.
- Nach dem ersten Kontakt kann genau **ein weiteres Ziel vorwärts** getroffen
  werden, mit **50 % Grund- und Verzauberungsschaden**. Es muss entlang der
  tatsächlichen Klingenbewegung und vor dem ersten Einschlagspunkt liegen.
- Reichweite 160, Hauptzielschaden, Bossbonus, Takt und Windup bleiben erhalten.
  Keine neue Kreisfläche, kein drittes Ziel, keine zusätzlichen Heilimpulse
  außerhalb des bestehenden Waffenintervalls.

`WeaponSingleContact` hält diese Kontakte als kleine separate Komponente.
Die Eigenschaften liegen in `WeaponData`; zunächst ist nur der Turbo-Bohrer
dafür freigeschaltet. Andere Waffen und Evolutionen ändern ihr Verhalten dadurch
nicht. Kratzer/Polierer bleiben Kandidaten für einen eigenen Test; insbesondere
der Crit-Zyklus des Polierers braucht eine saubere Regel beim Zielwechsel.

### Karies-Fräse

- Reichweite **78 → 110** auf allen vier Mk-Stufen.
- Gegen normale Gegner **100 % statt 75 %** Schaden: Der frühere Abschlag fällt
  weg. Grundschaden, Angriffstakt, Skalierung, Fokus und Elite-/Bossboni bleiben
  erhalten. Gegen normale Ziele entspricht das +33,3 % Schaden.
- Weiterhin eine kurze Einzelzielwaffe für zwei Wurzeln. Die größere Reichweite
  läuft über dieselbe sichtbare Bewegung und Kontaktprüfung wie bisher.

Die Fräse gewinnt damit sichere Angriffszeit und normalen Clear, statt ihren
bereits hohen theoretischen Boss-DPS nochmals zu erhöhen.

## Kontrollierte Ergebnisse

Je neun gleiche Seeds und dieselbe automatische Entscheidungsregel. Keine
menschlichen Winrates: Es gibt weder Dash noch bewusste Reaktion auf Warnungen.

| Bohrer-Variante | W5 erreicht | Boss besiegt | Start-HP bei W5-Ankunft |
| --- | ---: | ---: | ---: |
| Vorher | 7/9 | 0/9 | 28,3 % |
| Nur Ersatzkontakt | 4/9 | 0/9 | 41,8 % |
| Ersatzkontakt + zweites Ziel | 8/9 | 1/9 | 35,3 % |

Start-HP werden nur unter den angekommenen Läufen gemittelt (Mediane); die
Seedmengen unterscheiden sich. Der Ersatzkontakt allein zeigte keine robuste
Verbesserung des Einstiegs. Die Kombination liefert einen kleinen positiven
Schritt. Ihre praktische Bedeutung ist nach neun Seeds weiter vorläufig.

In **34 paarweise gleich vollständig überstandenen Wellen** bringt die Kombination
2.321 statt 2.249 Gold (+3,2 %) und 2.132 statt 2.109 XP (+1,1 %). Diese gleiche
Zeitbasis vermeidet einen scheinbaren Einkommensgewinn allein durch längeres
Überleben. Das ist eine moderate Verbesserung, kein behobenes Gesamtbalancing.
Die Zahl leerer Stöße nach Zielverlust sinkt auf 844/5.477 (15,4 %); ohne einen
anderen Gegner auf der vorhandenen Bahn bleibt ein Stoß weiterhin ohne Kontakt.

| Fräsen-Variante | W1 überlebt | W5 erreicht | Boss besiegt | W1 Gold | W1 XP |
| --- | ---: | ---: | ---: | ---: | ---: |
| 78 Reichweite, 75 % gegen normale Gegner | 2/9 | 0/9 | 0/9 | 35 | 33,5 |
| 110 Reichweite, 75 % | 9/9 | 0/9 | 0/9 | 31 | 33 |
| 110 Reichweite, 100 % | 9/9 | 2/9 | 0/9 | 43 | 44 |

W1-Einkommen nur unter überlebten Proben. Daher ist die alte Zweiergruppe keine
faire Einkommensreferenz für neun Überlebende. Die beiden neuen Varianten
überstehen dagegen dieselben neun ersten Wellen: Der bessere normale Schaden
verbessert dort Gold und XP gegenüber dem reinen Reichweiten-Buff deutlich.
Auch danach bleibt der reine Fräsen-Einstieg auf Hell schwierig.

**Normal-Kontrolle nach den Änderungen:** Beide Waffen erreichen und besiegen
den ersten Boss 9/9. Mediane Boss-TTK: Bohrer 19,35 s, Fräse 19,20 s; schnellster
Kill 18,68 s. Diese Einstiegsprobe prüft keine vollständigen 20-Wellen-Runs.

UV-Lampe und Turbine wurden in der Hell-Kandidatenmessung erneut als Kontrollen
mitgeführt. Ausgang, Kills, Level, Gold, XP und Kapseln stimmen für alle neun
jeweiligen Seeds mit dem Ausgangsstand überein.

## Mindestversorgung: derzeit nicht eingebaut

Eine nachträgliche Aufstockung auf **20 Gold und 20 XP pro vollständig überlebter
Welle** hätte in keiner der 135 ausgewerteten vollständigen W1–4-Basisproben
zusätzliche Belohnungen erzeugt. Das schließt eine stärkere oder anders gestaltete
Versorgung nicht aus. Diese kleine Untergrenze würde den hier gemessenen Weg
jedoch nicht verbessern und rechtfertigt deshalb kein weiteres Spielsystem.
Es wurden dafür keine zusätzlichen Folgekäufe oder Kämpfe simuliert.

## Speichern, Kontakte und Prüfungen

Abgeschlossen: **164/164 Kerntests**, **4/4 Zusatzprüfungen**
(`earned_progression`, `weapon_roster`, `weapon_roster_dps`, `run_telemetry`),
126 Einstiegsproben und native Bildprüfung. Die bestehenden vier Python-
Aggregationsprüfungen bestehen ebenfalls.

Das verbrauchte Kontaktbudget wird unabhängig von lebenden Zielreferenzen
gespeichert. Auch wenn das erste getroffene Ziel beim Speichern schon fehlt,
erhält der zweite Kontakt nach Fortsetzen nur halben Schaden; ein verbrauchter
Stoß kann keinen neuen Gegner treffen. Historische laufende Angriffe bekommen
keinen zusätzlichen zweiten Kontakt. Neue Werte sind optional und validiert.

`turbo_contact` prüft alle vier Richtungen, Windup, tote/lebende Ziele, sichtbare
Kollision, unveränderten Hauptziel-/Bossschaden, halbe Elementpakete, gemeinsame
Lebensraub-Uhr und JSON-Fortsetzen mit bereits entfernten Zielen. `run_storage`
weist fehlerhafte Kontaktbudgets und Vektoren zurück. Die Story-Prüfung löst
jetzt auch eine zusätzliche Waffenbelohnung vor Ankunft/Epilog vollständig auf,
statt deren zufälliges Auftreten zu übergehen.

Die native Prüfung rendert Bohrer und Fräse mit echten Waffen-/Gegnersprites.
Beim Bohrer blinken nur die beiden getroffenen Körper auf der Stoßbahn;
seitliches und drittes Ziel bleiben ungetroffen. Werkzeuggrafiken bleiben erhalten.

## Berichte und Reproduktion

- [Kompakte Kandidatenauswertung](balance_drill_candidates.md).
- [54 Ausgangsproben](balance_drill_baseline.json), [9 Ersatzkontakt-Proben](balance_drill_retarget.json),
  [27 Zweitkontakt-/Kontrollproben](balance_drill_pair.json).
- [9 Fräsen-Reichweitenproben](balance_grinder_reach.json),
  [9 Fräsen-Clearproben](balance_grinder_clear.json), [18 Normal-Proben](balance_drill_normal_after.json).
- Zusammen **126 verdiente Einstiegsproben** mit den Quellhashes der jeweiligen
  Zwischenstände. Historische Zwischenstände werden nicht überschrieben.

```powershell
python tools/run_earned_progression.py --builds turbo_drill,cavity_grinder --difficulties hell --movements hunt --seeds 13579,24680,112233,445566,778899,314159,271828,424242,8675309 --output .godot/drill_current.json
python tools/analyze_drill_candidates.py
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter turbo_contact --filter run_storage --filter weapon_motion --filter story_mode
```

`tools/preview_drill_contact.gd` erzeugt native Bewegungsphasen unter
`.godot/drill_contact_preview/`; ohne `--headless` und mit isoliertem APPDATA starten.
Vor einer weiteren Verstärkung bleiben menschliche Normal-/Hell-Runs mit den
geänderten Waffen und gezielte Mischbuilds nötig.
