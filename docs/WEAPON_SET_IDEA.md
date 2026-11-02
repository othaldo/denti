# Prüfidee: Waffenfamilien-Sets

02.11.2026 · optionale Build-Idee aus dem Spielerfeedback, noch keine Umsetzung.

**Auf Nutzerwunsch zurückgestellt.** Zuerst werden die anderen Balance-Ideen geprüft.

Mehrere Waffen einer Gattung könnten einen kleinen gemeinsamen Bonus geben.
Die erste Prüffrage ist, ob dadurch eine interessante Entscheidung entsteht,
die sich ohne zusätzliche Regeln und lange Erklärungen verstehen lässt.

## Kleinstmögliche Variante

- Zunächst nur **Nahkampf** und **Fernkampf**. Die Zuordnung existiert bereits
  in `WeaponData.damage_stat`; daraus folgt bisher kein automatischer Setbonus.
- Genau eine Schwelle, als Entwurf **vier belegte Wurzeln derselben Gattung**.
  Eine Zwei-Wurzel-Waffe zählt entsprechend doppelt.
- Ein kleiner additiver Effekt je Familie. Illustrative, ungetestete Beispiele:
  Nahkampf erhält etwas Härte, Fernkampf etwas Waffenreichweite.
- Bei vier Wurzeln ist der Bonus vollständig. Sechs gleiche Waffen erhalten
  keinen zusätzlichen sechsten Schwellenbonus. So bleibt eine Zwei-Wurzel-
  Ergänzung attraktiv.
- Keine Setstufen, Rangabhängigkeit, zufälligen Setwerte oder besonderen
  Aktivierungen im ersten Versuch. Eine kompakte Anzeige in den Ausrüstungsdetails
  muss zum Verstehen reichen.

| Ausrüstung | Nah-/Fernwurzeln | Entwurf mit Vierer-Schwelle |
| --- | --- | --- |
| 4 Bohrer + 1 UV-Lampe | 4 / 2 | Nahkampfbonus und freie Wahl einer Ergänzung |
| 2 Turbinen + 2 Bohrer | 2 / 4 | Fernkampfbonus und zwei Nahkampfwaffen |
| 3 Bohrer + 3 Spiegel | 3 / 3 | Kein Setbonus; Nutzen der Mischung muss trotzdem bestehen |
| 3 Zahnseiden-Schneiden | 6 / 0 | Derselbe Nahkampfbonus, nicht dreimal weniger als bei sechs Bohrern |

## Vor einer Umsetzung zu klären

**Fusion und Verlustgefühl:** Auch beim Zählen nach Wurzeln kann eine Fusion
die belegte Wurzelzahl senken. Vier Mk-I-Bohrer werden durch eine Fusion zu drei
Waffen und unterschreiten die Schwelle. Die zusätzliche Waffenstärke müsste
gegen den verlorenen Bonus abgewogen und in der Vorschau sichtbar werden.
Das kann gerade wegen Verlustaversion unnötig unangenehm wirken. Nach Mk oder
investierten Exemplaren zu zählen vermeidet manche Verluste, macht die Regeln
aber komplizierter und entfernt sie vom Gedanken „mehrere Waffen“.

**Einstieg:** Eine Schwelle von zwei Wurzeln würde einer einzelnen kostenlosen
Zwei-Wurzel-Startwaffe sofort einen Bonus geben, einer Ein-Wurzel-Startwaffe
jedoch nicht. Die Vierer-Skizze vermeidet diesen unmittelbaren Startbonus,
hilft dafür in den ersten Wellen noch nicht zuverlässig.

**Breite Gattungen lösen das Einzelzielproblem nicht:** Bohrer, Fräse, Bürste
und Schneide sind alle Nahkampf. Ein pauschaler Nahkampfbonus verstärkt damit
auch bereits starke Flächenwaffen. Fernkampf enthält ebenfalls Einzelziel- und
Flächenwaffen. Ein zusätzlicher Goldbonus pro Kill würde die bestehende
Einkommensrückkopplung weiter verstärken.

**Vorhandene Spezialisierung:** Gemeinsame Nah-/Fernschadenswerte begünstigen
bereits Builds, die viele Waffen mit demselben Stat verbessern. Ein weiteres
System muss mehr beitragen als zusätzliche Pflichtzahlen und sollte mit späteren
Klassen zusammengedacht werden.

## Empfehlung

Als optionale Build-Vertiefung festhalten. Zuerst den
[verdienten Weg schwächerer Starts zum Boss](EARNED_PROGRESSION.md) verbessern.
Danach höchstens die kleine Variante separat testen: Mischbuilds 4+2 und 3+3,
Fusion, Ein-/Zwei-Wurzel-Starts sowie starke und schwache Waffen derselben Gattung.
Die Beispiele sind Designhypothesen, keine gemessenen oder beschlossenen Boni.
