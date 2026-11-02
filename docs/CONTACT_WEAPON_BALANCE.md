# Kontaktwaffen: nutzbare Stärke statt höherer Dummy-DPS

02.11.2026 · anschließender Spieltest-Pass nach
[Bohrer/Fräse](DRILL_CONTACT_BALANCE.md) und der sichtbaren Waffenskalierung.

## Entscheidung

Die UV-Lampe verbindet große Reichweite, sofortige Treffer und viele Ziele auf
einer Linie. Kurze Kontaktwaffen brauchen deshalb auch Möglichkeiten, ihre
Stärke sicher einzusetzen und den Ausbau zu verdienen. Mehr rechnerischer
Einzelzielschaden allein bezahlt dieses Risiko nicht. Die Änderungen unten
erhalten unterschiedliche Rollen; Setboni bleiben zurückgestellt.

| Waffe | Änderung dieses Passes | Zweck im Spiel |
| --- | --- | --- |
| Turbo-Bohrer | 8 Rückstoß pro Treffer | Der bereits begrenzte Durchbohr-Stoß schafft etwas Abstand. Erfolgreich angreifen soll beim anschließenden Ausweichen helfen. |
| Karies-Fräse | 6 Rückstoß pro Treffer | Die schnelle Einzelzielwaffe gewinnt etwas Raum, ohne noch mehr theoretischen Boss-DPS zu benötigen. Reichweite ist weiterhin 110 aus dem vorherigen Pass. |
| Zahnsteinkratzer | 6 Rückstoß; Ersatzkontakt bei totem Ziel; höchstens ein weiteres Ziel vorwärts auf der sichtbaren Hiebspur für 50 % Trefferschaden | Weniger leere Schnitte und ein begrenzter Gruppenbeitrag helfen beim Verdienen von Gold/XP. Blutung und schneller Angriff bleiben seine Identität. |
| Prophylaxe-Polierer | 110 statt 85 Reichweite; 4 Rückstoß; Ersatzkontakt bei totem Ziel; jeder dritte Angriff pro Waffenexemplar kritisch | Der Crit-Vorteil wird auch beim Wechsel zwischen kleinen Gegnern nutzbar. Der Polierer bleibt eine einzelne Kontaktwaffe und bietet einen Grund für Crit-/Polierpaste-Builds. |

Rückstoß wird von der vorhandenen Gegnerresistenz reduziert und wirkt nur auf
überlebende getroffene Ziele. Die Waffen teilen keine gemeinsame Rückstoß- oder
Crit-Aufladung. Kurze Angriffe benötigen weiterhin die tatsächliche sichtbare
Waffenberührung und ihr Ausholen; sie bekommen keine unsichtbare Rundumfläche.

Der zweite Kratzerkontakt verwendet dieselbe begrenzte Komponente wie der
Bohrer. Sein Grund- und zusätzlicher Elementtrefferschaden wird halbiert; die
kleine intrinsische Blutung wird weiterhin als normaler Status angewendet.
Lebensraub bleibt innerhalb der bestehenden Waffen-Uhr. Ein noch lebendes
ursprüngliches Ziel wird beim Ersatzkontakt nicht ausgetauscht.

## Polierer: Angriffszähler und Fortsetzen

Der neue Crit-Zyklus zählt **Angriffe**, nicht nur erfolgreiche Kontakte.
Zielwechsel und Pausen löschen den Fortschritt nicht. Ohne erreichbares Ziel
beginnt kein Angriff; eine Waffe lädt sich beim Herumstehen also nicht selbst
auf. Ein begonnener verfehlter Angriff zählt wie in der Dentipedia beschrieben.
Das macht den Ablauf eindeutig und vermeidet einen neuen Treffer-Sonderfall.

`crit_cycle_progress` gehört zur Waffeninstanz und wird unabhängig von noch
lebenden Gegnerreferenzen gespeichert. Zwei Angriffe, Speichern bei bereits
entfernten Zielen und Fortsetzen ergeben einen kritischen dritten Angriff auf
ein neues Ziel. Der vierte Angriff beginnt eine neue Serie. Alte Spielstände
ohne das optionale Feld beginnen bei null; laufende Angriffe behalten weiterhin
ihren gespeicherten Schadens-/Crit-Zustand. Die getrennte Fokusmechanik der Fräse
behält ihre bisherigen Regeln für dasselbe Ziel.

## Was die Messungen zeigen

**78 neue verdiente Einstiegsproben**: sechs Normal-Ausgangsproben,
45 Hell-Proben des Rückstoß-/Kontaktkandidaten, 18 Normal-/Hell-Proben des
überarbeiteten Polierers und neun weitere Normal-Kontrollen. Die Ausgangswerte
der übrigen Waffen kommen aus den bereits vorhandenen identischen Seeds des
vorherigen Passes. Es gibt keine kostenlose Heilung oder gleichgesetzte
Stat-/Geldbudgets. Alle Unterschiede in späteren Käufen gehören zur verdienten
Progression.

Neun identische Hell-Seeds, aktive Zielsuche, ohne Dash oder bewusste Reaktion
auf Warnungen:

| Waffe | Ersten Boss erreicht, vorher → jetzt | Boss besiegt, vorher → jetzt |
| --- | ---: | ---: |
| Turbo-Bohrer | 8/9 → 9/9 | 1/9 → 0/9 |
| Karies-Fräse | 2/9 → 5/9 | 0/9 → 0/9 |
| Zahnsteinkratzer | 0/9 → 3/9 | 0/9 → 0/9 |
| Prophylaxe-Polierer | 0/9 → 1/9 | 0/9 → 0/9 |

Das verbessert die Erreichbarkeit teilweise, **belegt aber keine geschlossene
Lücke zur UV-Lampe**. Insbesondere die Hell-Bosskämpfe bleiben schwach. Beim
Bohrer verschwindet sogar der eine bisherige Boss-Sieg; nur die Ankunft wurde
verlässlicher. Beim Polierer reichten Reichweite und Rückstoß allein für keine
Bossankunft; erst der zusätzliche unabhängige Crit-Zyklus erreicht eine Probe.
Das Ergebnis rechtfertigt weder eine allgemeine Siegchance noch weitere
pauschale Schadenssteigerungen.

Nur über beidseitig vollständig überstandene, identische W1–4-Fenster:

- Kratzer: 13 Wellenpaare, Gold 528 → 582 (+10,2 %), erlittener Schaden
  477,9 → 245,0. XP 534 → 550.
- Polierer: 17 Wellenpaare, Gold 811 → 838; erlittener Schaden
  677,2 → 342,5. XP 794 → 787: kein allgemeiner XP-Gewinn.
- Bohrer: 35 Wellenpaare, Gold 2.441 → 2.450; erlittener Schaden
  704,5 → 620,7. Der Einkommensvorsprung gegenüber dem vorherigen Pass ist klein.
- Fräse: 29 Wellenpaare, Gold 1.817 → 1.756 und erlittener Schaden
  492,8 → 545,0. Mehr Bossankünfte bedeuten hier nicht automatisch besseren
  Clear oder weniger Schaden. Der Rückstoß hat eine mögliche Wechselwirkung
  mit Kontaktzeit/Fokus und braucht besonders kritische menschliche Prüfung.

**Normal:** 18/18 aktuelle Einstiegsproben besiegen den ersten Boss: je drei
Bohrer/Fräse/Kratzer und neun Polierer. Alle Bosszeiten liegen zwischen
18,55 und 22,27 Sekunden. In den drei paarweise verglichenen Seeds jeder Waffe
liegen die Mediane bei 18,67 / 20,88 / 21,42 / 19,85 Sekunden. Es entstehen hier
keine Bosskills im Bereich 2–5 Sekunden. Das prüft keine vollständigen Runs.

Die unveränderte UV-Kontrolle hat über alle neun Hell-Seeds exakt dieselben
Endpunkte für Ausgang, Welle, Kills, Gold, XP, Level und Kapseln wie vorher.

## Spielerfahrung und nächste Abnahme

Dieser Pass ist eine begrenzte Verbesserung zum Anspielen, kein abgeschlossenes
Balancing aller 18 Waffen. Wichtig für menschliche Normal-/Hell-Runs sind:

- Bleibt ein kurzer Kontakt-Build beim Sammeln und Ausweichen spielbar?
- Fühlt sich Rückstoß hilfreich an oder schiebt er Ziele ärgerlich aus dem
  eigenen Folgeangriff, besonders bei der Fräse?
- Wird der Polierer mit Crit-/Polierpaste-Items sinnvoller, ohne dass häufige
  Folgeeffekte das Spiel trivialisieren? Die feste Feuer-Ausbaupolitik der
  automatisierten Proben deckt diesen Build nur teilweise ab.
- Können sichere Linienwaffen weiter mächtig wirken, während Gegnerdruck und
  Bossmechaniken auch auf Normal noch Bewegung verlangen?

Weitere Änderungen danach gezielt aus diesen Befunden ableiten. Die starken
Linien- und Rundumwaffen brauchen keinen pauschalen Nahkampf-Buff. Zusätzlicher
Gegnerdruck ist ein eigener nächster Schritt und muss mit den nun veränderten
Waffen geprüft werden.

## Reproduktion

Abgeschlossen: **164/164 Kerntests**, die beiden bestehenden Python-Prüfungen
zur Einkommensauswertung, 78 neue Einstiegsproben und native Sichtprüfung der
vier Kontaktwaffen. `git diff --check` meldet keine fehlerhaften Änderungen.

[Automatische Gegenüberstellung mit allen Zahlen](balance_contact_pressure_comparison.md).
Rohdaten: [Normal vorher](balance_contact_normal_before.json),
[Hell-Druckpass](balance_contact_pressure_after.json),
[Polierer-Zyklus](balance_polisher_cycle_after.json),
[Normal danach](balance_contact_normal_after.json).
Die Rohberichte enthalten die jeweiligen Quellhashes; historische Messstände
werden nicht überschrieben.

```powershell
python tools/analyze_contact_pressure.py
python tools/run_tests.py --godot Godot_v4.7.2-stable_win64_console.exe --filter turbo_contact --filter weapon_expansion --filter run_storage
```

`turbo_contact` deckt jetzt auch den Kratzer in vier Richtungen, die begrenzte
sichtbare Kollision, Rückstoßresistenz und den zielunabhängigen Polierer-Zyklus
über einen JSON-Spielstand ab. Der stationäre Fokus-Dummy in `weapon_expansion`
wird zwischen Angriffen zurückgestellt, damit der neu hinzugefügte Rückstoß
nicht versehentlich den Save-/Fokustest in einen Reichweitentest verwandelt.
Native Phasenaufnahmen mit echten Sprites entstehen über
`tools/preview_drill_contact.gd` unter `.godot/contact_pressure_preview/`.
