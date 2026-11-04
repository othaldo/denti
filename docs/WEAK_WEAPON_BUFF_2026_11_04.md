# Kleine Buffs nach dem Waffen-Audit

04.11.2026 · Umsetzung für die schwächeren Einstiegswaffen aus dem
[verdienten Vergleich aller 18 Startwaffen](WEAPON_AUDIT_2026_11_04.md).
Vorher-Stand: `e636465`. Der ursprüngliche Audit bleibt unverändert erhalten.

## Änderungen

| Waffe | Vorher | Jetzt | Zweck |
| --- | --- | --- | --- |
| Prophylaxe-Polierer | 110 Reichweite, ein Ziel | 120 Reichweite; ein weiteres Ziel vorwärts auf der sichtbaren Hiebspur für 40 % Schaden | Mehr nutzbare Kontaktzeit und ein begrenzter Gruppenbeitrag beim Verdienen des Builds |
| Zauberbürste | 20 Grundschaden | 22 Grundschaden | +10 % auf den Basisanteil jedes Mk-Treffers, um Gruppen früher abzubauen |
| Schmelzspiegel | 0,95 s Grundpause, 390 Reichweite | 0,90 s Grundpause, 420 Reichweite | Rund 5,6 % mehr Angriffe und 7,7 % mehr Zielreichweite für etwas sicherere Angriffszeit |

Preise, Wurzelkosten und Skalierungsfaktoren bleiben erhalten. Der Polierer
behält seinen Einzelzielschaden, 4 Rückstoß und den kritischen dritten Angriff.
Die Zauberbürste behält 0,65 Sekunden Basispause und ihre Salven von einem,
einem, zwei und drei Geschossen auf Mk I–IV. Die Evolution bleibt damit auch
bei Grundschaden und Angriffstakt eine Aufwertung. Beim Spiegel bleibt der
Grundschaden unverändert; er wird nicht zur Linien-/Flächenwaffe.

Der Kronenwerfer erhält nach seinen 9/9 Bossankünften und 7/9 Siegen im Audit
zunächst keinen zusätzlichen Buff. Andere Waffen und Gegnerwerte ändern sich
durch diesen Pass nicht.

## Polierer: genau ein begrenzter Folgekontakt

Der zweite Kontakt verwendet die vorhandene `WeaponSingleContact`-Komponente.
Er muss auf der tatsächlichen sichtbaren Waffenbewegung liegen und vorwärts
vom ersten Einschlagspunkt aus erreichbar sein. Kein drittes Ziel, kein
Treffer hinter Denti und keine unsichtbare Kreisfläche. Ein einzelner Boss
wird nicht zweimal vom selben Angriff getroffen.

Grund- und zusätzlicher Elementtrefferschaden erhalten denselben Faktor 0,4.
Der bestehende Lebensraub-Timer gilt gemeinsam für beide Kontakte. Der dritte
kritische Angriff zählt weiterhin einmal pro Angriff und Waffenexemplar,
auch bei Zielwechsel und Pausen. Er füllt sich nicht pro getroffenem Gegner.

Save/Resume erhält das bereits verbrauchte Kontaktbudget. Ein gespeicherter
Angriff aus der alten Fassung behält seine Grenze von einem Kontakt; erst der
nächste neu begonnene Angriff erhält das neue Zweierbudget. Ein während des
ersten Kontakts getötetes und später entferntes Ziel setzt das Budget nicht
zurück.

## Gleiche Hell-Seeds, tatsächlich verdiente Ausrüstung

72 Abschlussläufe: vier Waffen einschließlich UV-Kontrolle, Normal und Hell,
je neun Seeds. `regular`-Pilot, `kite`-Strategie und unveränderte `synergy`-
Kauf-/Upgradepolitik. Ein echter Starter, 100 HP, Level 1 und null Gold;
weitere Waffen, Items und Rerolls werden bezahlt, Verluste und Ausbau werden
zwischen den Wellen mitgenommen. Sichtbare Warnreaktionen und echte Dash-Kosten
bleiben aktiv. Es gibt keine geschenkten Stat-/Itempakete.

| Hell, je neun Läufe | Boss erreicht vorher → jetzt | Boss besiegt vorher → jetzt | Erfolgreiche Boss-TTK vorher → jetzt |
| --- | ---: | ---: | ---: |
| Polierer | 5/9 → 9/9 | 5/9 → 9/9 | 19,95 → 19,85 s |
| Zauberbürste | 7/9 → 8/9 | 6/9 → 8/9 | 18,76 → 18,51 s |
| Schmelzspiegel | 7/9 → 7/9 | 6/9 → 7/9 | 18,33 → 18,28 s |
| UV-Kontrolle | 9/9 → 9/9 | 8/9 → 8/9 | 19,06 → 19,06 s |

Auf Normal bestehen nach dem Patch alle 36 Proben den ersten Boss. Die
Normal-Ausgangsprüfung hatte drei statt neun Seeds je Waffe; deren identische
Seeds bleiben im Messbericht vergleichbar. Alle zwölf gemeinsamen UV-Fälle
(neun Hell, drei Normal) behalten exakt dieselben Endpunkte für Ausgang,
Welle, Level, Kills, Gold, XP und Kapseln.

Die Bosszeiten bleiben im Bereich von ungefähr zwanzig Sekunden, statt auf
2–5 Sekunden zu fallen. Der Hauptgewinn ist der bessere Weg zum Boss. Beim
Spiegel ist die Verbesserung klein; die neun Seeds begründen keinen weiteren
großen Schadensaufschlag. Die Zauberbürste verliert einen zuvor erfolgreichen
Seed in W4, während andere Seeds besser werden. Es ist kein monotoner
Vorteil auf jeder Route.

### Nur gleich vollständig überstandene W1–4-Fenster

Tote Läufe haben weniger Zeit für Kills und Einkommen. Deshalb summiert die
folgende Kontrolle ausschließlich vollständig überstandene Wellen gleicher
Nummer und gleichen Seeds auf beiden Seiten.

| Waffe | Wellenpaare | Schaden erhalten vorher → jetzt | Gold vorher → jetzt | XP vorher → jetzt |
| --- | ---: | ---: | ---: | ---: |
| Polierer | 28 | 574,4 → 471,8 | 1.629 → 1.694 | 1.586 → 1.628 |
| Zauberbürste | 33 | 596,1 → 246,6 | 2.120 → 2.224 | 2.024 → 2.039 |
| Schmelzspiegel | 31 | 456,6 → 393,1 | 1.869 → 1.947 | 1.724 → 1.843 |

Der Effekt ist keine allgemeine Heilungserhöhung. Über die fünf gleichen
Polierer-Seeds mit Bossankunft vor und nach dem Patch sinkt das mediane
Startleben leicht von 78,2 auf 75,3 %. Die vorher verlorenen vier Läufe
erreichen jetzt zusätzlich den Boss. Bei den sechs gemeinsamen
Zauberbürsten-Ankünften steigt das Startleben von 70,7 auf 84,7 %, beim
Spiegel über sechs gemeinsame Ankünfte von 82,2 auf 84,7 %.

## Prüfung und Darstellung

`turbo_contact` ergänzt vier Richtungen, Windup, volle Haupttreffer, den
40-%-Folgetreffer, dritte/off-axis/nähere Ziele, den kritischen dritten
Angriff, Einzelboss-Treffer, skalierte Elementpakete, gemeinsamen Lebensraub
und JSON-Fortsetzen nach entferntem Hauptziel einschließlich des alten
Einkontaktbudgets. `weapon_rework` prüft den neuen Mk-IV-Basiswert der
Zauberbürste. Die bestehenden Prüfungen für Risikoprämie, Evolutionen und
Waffenbewegung bleiben aktiv.

Abschluss: **178/178 Kernprüfungen** bestanden in 566,31 Sekunden mit zwei
Workern, zusätzlich **3/3 erweiterte Waffen-/Botprüfungen** in 25,74 Sekunden.
Die Berichte liegen unter
`.godot/test_runs/20261104-083203-7b87cc0b/results.json` und
`.godot/test_runs/20261104-083735-8d971606/results.json`.
Der abschließende `turbo_contact`-Nachlauf mit der zusätzlich ergänzten
Altspielstand-Assertion besteht ebenfalls: **1/1** unter
`.godot/test_runs/20261104-084233-aca2d69b/results.json`.

Die native Vorschau `tools/preview_drill_contact.gd` zeigt den Polierer jetzt
mit mehreren Zielen auf der Hiebspur sowie einem seitlichen Kontrollziel.
Die vorhandene gemalte Waffe, Arbeitskopf und physische Kontaktspur bleiben
deckungsgleich. Aufnahmen liegen unter `.godot/contact_pressure_preview/`;
normale Spielstände werden nicht verwendet.

## Messdaten und Reproduktion

Der [Messbericht](weak_weapon_buff_2026_11_04.json) enthält die 72 finalen
Einzelresultate, Wellenwerte, Startausrüstung, gemeinsame Wellenpaare und
Quellen-/Rohbericht-Hashes. Die Ausgangsdaten sind im
[vorherigen Audit](weapon_audit_2026_11_04.json) archiviert.

```powershell
python tools/run_bot_comparison.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --weapons prophylaxis_polisher,magic_toothbrush,enamel_mirror,uv_lamp --skills regular --strategies kite --build-policies synergy --difficulties normal,hell --seeds 13579,24680,112233,31415,27182,42424,77777,88888,99999 --jobs 4 --output .godot/weak_weapon_buff_repeat.json
python tools/run_tests.py --godot 'C:\Program Files\godot\Godot_v4.7.2-stable_win64_console.exe' --filter turbo_contact --filter weapon_rework --filter weapon_dps_balance --filter weapon_motion
```

Godot 4.7.2, feste 60 Hz, Zeitskalierung 1 und getrennte Benutzerdaten. Die
Zahlen sind Diagnoseproben bis zum ersten Boss, keine menschlichen Siegchancen
und kein Nachweis für vollständige Hell-Runs. Der nächste menschliche Test
soll besonders frühen Polierer-Clear, den Nutzen eines einzelnen Polierers
im Mischbuild und die Zauberbürste in W4 unter bewegtem Hordendruck prüfen.
