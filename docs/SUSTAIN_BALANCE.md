# Lebensraub und Feenverträge

Stand: 27.10.2026, nach v0.6.0.

Lebensraub verwendet jetzt **0,6 Sekunden je Waffenexemplar**. Zwei gleiche
Waffentypen besitzen getrennte Heilintervalle. Weitere Waffen mit Lebensraub
werden deshalb nicht mehr von einer zuerst treffenden Waffe blockiert.

Der Heilanteil bleibt bei höchstens **5 % des tatsächlich verursachten
Trefferschadens**, begrenzt durch den ausgebauten Effektwert und maximal 2 HP pro belegter Wurzel
je Impuls. Der jeweilige Waffeneintrag zeigt den Ausbauwert. Salven, Durchschlag,
Rückflug und Explosionen derselben Waffe teilen sich ihren Takt. DoTs und
Folgeeffekte erzeugen weiterhin keine Lebensraub-Heilung.

## Weniger Heilung durch XP

| Item | Leben je XP vorher | Jetzt | Änderung |
| --- | ---: | ---: | ---: |
| Feenquittung | 0,15 | 0,10 | −33 % |
| Zahnfee-Pakt | 0,35 | 0,25 | −29 % |
| Feenvertrag | 0,45 | 0,35 | −22 % |
| Feenbund | 0,60 | 0,45 | −25 % |

Preise, Nachteile und das gemeinsame Familienlimit von zwölf bleiben erhalten.
Die Heilung skaliert weiterhin mit der gesammelten XP-Menge und den Exemplaren.
Eine größere einzelne XP-Aufnahme und mehrere kleine Aufnahmen bleiben gleichwertig.
Beim Fortsetzen werden die Itemeffekte aus den aktuellen Ressourcen aufgebaut.

## Messung

30 Sekunden echte Angriffe von Mk-IV-Schmelzspiegeln mit Lebensraub 10/10,
60 Physikschritte/s, keine Items oder eingehender Schaden, ausreichend fehlendes
Leben. Ein stationäres Ziel besitzt weder Rüstung noch Schutzphasen. Der alte
gemeinsame Takt wird für den Vergleich durch dieselbe Proc-Herkunft aller Waffen
nachgebildet. Die zweite Variante verwendet ihre echten Waffen-IDs.

| Waffen mit Lebensraub | Geteilter Takt, HP/s | Je Waffenexemplar, HP/s |
| ---: | ---: | ---: |
| 1 | 2,09 | 2,09 |
| 3 | 2,09 | 6,22 |
| 6 | 2,09 | 12,43 |

Das ist Heilungsdurchsatz bei ununterbrochenen Treffern, keine Messung von
Überlebensrate oder Heilung unter realem Gegnerdruck. Andere Waffen, Ränge,
Rüstung und Schusslücken verändern die Werte.

[Rohdaten](balance_sustain.json). Reproduzierbar mit
`tools/benchmark_sustain.gd` in einem isolierten Godot-Testlauf.

## Herkunft und Fortsetzen

Der Trefferweg überträgt die bereits vorhandene persistente Waffen-ID an
Nahkampf, Strahlen und Projektile. Alle Geschosse einer Salve behalten dieselbe
ID. Auch Einschläge, Explosionen, Pool-Wiederverwendung und gespeicherte
Projektile verwenden diese Herkunft.

Die Uhren liegen weiterhin im gespeicherten Item-Effektkontext, nun unter
getrennten Schlüsseln. Abgelaufene Waffenuhren werden entfernt. Die verbleibende
globale Sperre eines alten Spielstands wird zunächst respektiert; historische
Geschosse ohne Waffen-ID verwenden bis zu ihrem Ablauf den konservativen
gemeinsamen Takt. Neue Angriffe nutzen stets die Waffen-ID. Eine normale Fusion
oder Evolution behält die ID ihrer primären Waffe.

Shoptexte, Verzauberungsdetails und Dentipedia erklären den Takt je Waffe.
`tests/sustain_balance.gd` prüft echte Salven identischer Waffen, Splash-Grenzen,
Nahkampf und Strahlen, JSON-Fortsetzen, Pooling, alte Sperren, volle Gesundheit
und einzelne sowie gemischte Feen-Items. Die bestehenden Verzauberungsprüfungen
decken Schutzphasen, DoTs, Folgeeffekte und tatsächliche Heil-Telemetrie ab.
