# Waffenanimationen und Verankerung

Geprüft: alle 18 normalen Waffen und alle sechs Spezialwaffen. Der gemeinsame Test läuft pro Waffe in fünf Zielrichtungen und zwei Darstellungsgrößen. Die bestehenden Kontakt-Tests prüfen außerdem volle Reichweite, Nahdistanz, alle Stufen, übersprungene Physikframes und getrennte Arbeitsteile.

## Korrekturen

- Ausgerichtete Waffen richten ihre tatsächliche Griff-Spitzen-Achse zum Ziel. Übernommene Illustrationswinkel verzerren neue Sprites nicht mehr. Dreifaltigkeitsbürste und Zahn der Offenbarung erhalten passend gesetzte Emissionsanker.
- Projektile starten an der transformierten Waffenspitze und bleiben nach dem Abschuss unabhängig von Dentis Bewegung.
- Schmelzspiegel speichert einen Welt-Trefferpunkt und ein Ziel. Der sichtbare Strahl folgt Mündung und bewegtem Ziel; verschwindet das Ziel, bleibt der letzte Kontaktpunkt erhalten.
- UV-Lampe verwendet für Treffertest und Darstellung denselben Strahl ab der Mündung. Die Trefferlinie ist nicht mehr eine separate Linie durch Dentis Körper.
- Zahn der Offenbarung hält seine aktive Pose bis nach der Aufladung. Aufladeführung, Hauptstrahl und kritische Seitenstrahlen beginnen an der aktuellen Mündung. Aktive Laser folgen Denti und werden beim Fortsetzen wiederhergestellt.
- Der Durchbruch des Wurzelkanalbrechers beginnt an der Bohrspitze. Gegnerverbindungen, Pfützen und Markierungen bleiben dagegen an ihren Welt-/Gegnerpositionen.
- Heiligenschein startet seinen Orbit am tatsächlichen ersten Einschlag statt am Ende des gesamten Physikschritts.

Das Nachführen sichtbarer Strahlen erzeugt keine zusätzlichen Treffer. Normale Laser verursachen beim Abschuss einmal Schaden; der aufgeladene Spezialstrahl beim Freisetzen. Kontaktwaffen behalten ihre Aushol- und Trefferfenster. Karies-Fräse und Prophylaxe-Polierer behalten ihre getrennten rotierenden Köpfe; die Amalgam-Schleuder ihre elastische Sehne.

## Waffenabdeckung

| Waffen | Geprüfte Darstellung |
| --- | --- |
| Zauberbürste, Wasserflosser, Kronenwerfer, Mundspülungs-Mörser, Fluorid-Rakete | Salve, Mündungsanker, Rückstoß und freie Projektilbewegung |
| Gewitterdusche, Heiligenschein, Dreifaltigkeitsbürste | dieselben Emissionsprüfungen; zusätzliche Spezialeffekte/Orbit |
| Turbo-Bohrer, Zahnstein-Kratzer, Zahnstocher-Speer | Ausholen, Kontaktsegment, Stich/Bohrung/Schnitt |
| Zahnseidenpeitsche, Interdental-Bürste, Zahnseiden-Garotte, Schicksalsfaden | Drehung/Frontbogen und physischer Kontakt |
| Karies-Fräse, Prophylaxe-Polierer | Kontakt und separate rotierende Arbeitsteile |
| Mundduschen-Turbine, Fluorid-Sprüher | Sprühbewegung, Mündung und Trefferkegel |
| Amalgam-Schleuder | aufrechter Griff, gespannte Sehne und Projektil aus der Tasche |
| Schmelzspiegel, UV-Lampe, Zahn der Offenbarung | Mündung, Zielbewegung, Bewegung Dentis, Zielverlust und Fortsetzen |
| Wurzelkanalbrecher | Kontaktbohrung plus Durchbruch ab der Spitze |

`tests/weapon_visual_contract.gd` deckt diese gemeinsamen Verträge ab. `-- --capture` rendert zusätzlich alle Waffen in Godot nach `.godot/weapon-audit/`, einschließlich einer gemeinsamen Übersicht. Die Vorschauen sind lokale Prüfartefakte. Die bestehenden Tests `weapon_motion`, `weapon_evolutions`, `weapon_expansion`, `weapons`, `weapon_art_layers`, `weapon_layout` und `damage_defense_balance` bleiben Teil der Prüfung.
