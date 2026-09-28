# Dentis Waffen

Denti beginnt ohne fest ins Charakterbild eingebaute Waffe. Vor Welle 1 wählt man Zauberbürste, Turbo-Bohrer oder Wasserflosser. Die übrigen Waffen sowie weitere Exemplare gibt es im Shop.

| Waffe | Hände | Angriff | Rolle |
| --- | ---: | --- | --- |
| Zauberbürste | 2 | Schmelz-Projektil | Verlässliche Reichweite; Dentis klassische Startwaffe. |
| Turbo-Bohrer | 1 | Bohrung im Nahkampf | Langsamer, kräftiger Einzelstich; 25 % mehr Schaden gegen Bosse. |
| Zahnseidenpeitsche | 1 | Rundumschnitt | Trifft alle nahen Gegner gleichzeitig; erster Schnitt gegen einen Gegner ist stärker. |
| Wasserflosser | 1 | Schnelles Wasserprojektil | Kurzer Takt und Rückstoß. |
| Kronenwerfer | 2 | Schweres Metallprojektil | Durchdringt bis zu zwei weitere Gegner. |
| Schmelzspiegel | 1 | Sofortiger Lichtstrahl | Präziser Treffer ohne Flugzeit. |
| Zahnsteinkratzer | 1 | Schneller Nahkampfschnitt | Hohe Angriffszahl auf kurze Distanz; erster Schnitt gegen einen Gegner ist stärker. |
| Mundspülungs-Mörser | 2 | Minzprojektil | Flächenschaden beim Einschlag. |

Die Waffen haben eigene Sprites unter `assets/weapons/` und werden getrennt von Dentis Körper geschwenkt beziehungsweise beim Schuss zurückgestoßen. Projektilfarbe, Tempo, Reichweite und Trefferform liegen in den jeweiligen `WeaponData`-Ressourcen unter `data/weapons/`.

Die Ausrüstung fasst sechs Hand-Plätze. Einhandwaffen belegen einen, Zweihandwaffen zwei. Der Shop zeigt die aktuelle Ausrüstung; Verkauf benötigt zwei Klicks und schafft Platz für einen Wechsel. Ein Kauf einer identischen Waffe auf Stufe I verschmilzt mit einem vorhandenen Exemplar derselben Stufe. Zwei gleiche Waffen derselben Stufe werden jeweils zur nächsthöheren Stufe, bis IV. Jede Stufe erhöht Schaden und Angriffstempo. Der Spielstand speichert Waffentypen und Stufen.

Bohrung verursacht 25 % mehr Schaden gegen Bosse. Schnitt verursacht 15 % mehr Schaden gegen nahezu unverletzte Gegner. Die anderen Schadensarten unterscheiden sich über Reichweite, Projektiltempo, Durchschlag, Rückstoß, Strahl oder Flächentreffer. Gegner haben derzeit keine elementaren Resistenzen.
