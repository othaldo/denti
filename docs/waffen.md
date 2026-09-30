# Dentis Waffen

Denti beginnt ohne fest ins Charakterbild eingebaute Waffe. Vor Welle 1 wählt man Zauberbürste, Turbo-Bohrer oder Wasserflosser. Die übrigen Waffen sowie weitere Exemplare gibt es im Shop.

| Waffe | Hände | Angriff | Rolle |
| --- | ---: | --- | --- |
| Zauberbürste | 2 | Schmelz-Projektil | Verlässliche Reichweite; ab Stufe III zwei, ab IV drei Pastegeschosse mit leichtem Streuwinkel. |
| Turbo-Bohrer | 1 | Bohrung im Nahkampf | Kräftiger Einzelstich; Bossbonus wächst von 25 % auf 40 %. |
| Zahnseidenpeitsche | 1 | Rundumschnitt | Trifft alle nahen Gegner und verursacht Blutung; der Radius wächst mit der Stufe. |
| Wasserflosser | 1 | Schnelles Wasserprojektil | Macht Ziele nass, hat niedrigen Rohschaden und wachsenden Rückstoß. |
| Kronenwerfer | 2 | Schweres Metallprojektil | Durchdringt auf Stufe I einen weiteren Gegner, auf Stufe IV drei. |
| Schmelzspiegel | 1 | Sofortiger Lichtstrahl | Präziser Treffer ohne Flugzeit. |
| Zahnsteinkratzer | 1 | Schneller Nahkampfschnitt | Sehr kurze Reichweite und hoher Angriffstakt bauen kleine Blutungen schnell auf. |
| Mundspülungs-Mörser | 2 | Minzprojektil | Flächenschaden beim Einschlag; Explosionsradius wächst mit der Stufe. |

Die Waffen haben eigene Sprites unter `assets/weapons/` und werden getrennt von Dentis Körper geschwenkt beziehungsweise beim Schuss zurückgestoßen. Projektilfarbe, Tempo, Reichweite und Trefferform liegen in den jeweiligen `WeaponData`-Ressourcen unter `data/weapons/`.

Die Ausrüstung fasst sechs Hand-Plätze. Einhandwaffen belegen einen, Zweihandwaffen zwei. Solange genug Plätze frei sind, fügt ein Kauf die Waffe einzeln hinzu. Ist die Ausrüstung voll, verschmilzt eine gekaufte Waffe mit einem gleichen Exemplar derselben Stufe (bis IV). Zwei bereits ausgerüstete gleiche Waffen derselben Stufe lassen sich per Rechtsklick auf eine der Waffen verschmelzen. Verkauf benötigt zwei Linksklicks und erstattet die Hälfte des Kaufwerts aller in dieser Waffe aufgegangenen Exemplare. Jede Stufe erhöht Schaden und Angriffstempo. Der Spielstand speichert Waffentypen, Stufen und investierte Münzen.

Bohrung verursacht je nach Stufe 25–40 % mehr Schaden gegen Bosse. Schnitt verursacht 15 % mehr Schaden gegen nahezu unverletzte Gegner und baut Blutung auf. Wasserflosser-Treffer machen Gegner nass. Die anderen Schadensarten unterscheiden sich über Reichweite, Projektiltempo, Durchschlag, Rückstoß, Strahl oder Flächentreffer. Gegner haben derzeit keine elementaren Resistenzen. Die Waffen haben individuelle Schadensmultiplikatoren und ausgewählte Eigenschaften, die mit ihrer Stufe wachsen.
