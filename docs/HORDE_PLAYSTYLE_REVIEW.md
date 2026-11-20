# Spieltest: Klassen müssen im Hordenkampf unterscheidbar sein

Nutzerfeedback vom 05.11.2026 nach einem Handy-Run auf Hard.

## Ergebnis der Abnahme

Der aktuelle Assassinen-/Talententwurf erfüllt das Spielstilziel nicht.
Der Spieler konnte die Gegner leicht beseitigen, empfand die Auswirkungen der
Talente als austauschbaren Mehrschaden und den Dashnutzen als kaum erkennbar.
Der zweite Abschluss war nach Ausbau des ersten Pfads unerwartet gesperrt.
Zwei lineare Knotenketten wurden nicht als echte Talentbäume wahrgenommen.
Die erreichte Welle ist nicht bekannt; daraus folgt keine gemessene W20-Winrate.

Wichtige Korrektur: **Denti bekämpft Horden. Ein Duell-/Einzelzielfokus ist
kein geeigneter Kern für den neuen Klassenentwurf.** Auch ein stärkerer einzelner
Dash-Treffer geht im hohen automatischen Angriffstempo unter.

Die bisherigen automatisierten Eröffnungsruns belegen Funktionsfähigkeit und
Erreichbarkeit. Sie belegen keine wahrnehmbaren Unterschiede und ersetzen diese
menschliche Abnahme nicht. P3 bleibt technisch umgesetzt, ist gestalterisch
jedoch nicht abgenommen.

## Konsequenzen

- Den Duell-/Fokuspfad nicht weiter ausbauen. Die bestehende Implementierung und
  ihre Messdaten bleiben bis zu einer bewusst umgesetzten Ablösung dokumentiert.
- Klassen über den Umgang mit ganzen Gruppen entwerfen: durchqueren, bündeln,
  fernhalten, umlenken, Räume vorbereiten oder in die Horde hineinspielen.
- Angriffsschaden allein ist keine Klassensignatur. Unterschiede müssen an
  Reichweiten, Angriffsgeometrie, Positionierung oder Gegnerverhalten sichtbar sein.
- Ein Dash braucht einen erkennbaren räumlichen Nutzen unter Hordendruck. Ein
  Bonus auf einen der vielen automatischen Treffer reicht nicht.
- Ein Baum benötigt echte Alternativen innerhalb seiner Verzweigungen. Keine
  versteckte Sperre zwischen den letzten Knoten zweier ansonsten kaufbarer Listen.
- Punktequelle klar darstellen: derzeit ein Punkt pro verdientem Level,
  gemeinsame Verteilung nach der Welle. Das ist keine Belohnung pro Welle.
- Die geringe wahrgenommene Gefahr auf Hard separat untersuchen. Mehr oder
  stärkere Talentboni erzeugen keinen Grund, anders zu spielen. Keine pauschale
  Gegner-HP-Erhöhung als Ersatz für nötigen Raum-/Bewegungsdruck.

## Nächster Entwurfsmaßstab

Für einen Prototyp zuerst einen vollständigen Hordenablauf festlegen:
Annäherung → Umgang mit der Gruppe → Positionswechsel → erneute Annäherung.
Eine Alternative muss diesen Ablauf verändern, statt dieselbe Bewegung mit
anderer Schadensfarbe oder höherem Durchsatz zu belohnen.

Abnahme: Der Unterschied ist mit ausgeblendeten Schadenszahlen, auf dem Handy
und ohne seltenes Pflichtitem in kurzer Spielzeit erkennbar. Zunächst die
tragende Mechanik prüfen; erst danach zusätzliche Knoten, Werte und Klassen.

Umsetzung des ersten Prototyps nach diesem Maßstab: [Klassen-Essenz](CLASS_ESSENCE.md).
