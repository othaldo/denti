# Karies-Graf: Bettwanzen-Vampir

Stand: 20.10.2026. **Entwurf C wurde vom Spieler ausgewählt.** Visuelle
Historische Entwurfsrunde; C ist inzwischen im
[spielbaren Umhang-Encounter](../COUNT_CLOAK.md) integriert.

**Weiter ausgearbeitet:** Der [native Godot-Rig-Prototyp](count-rig.md) verwendet
zwölf Knochen und zwei gewichtete Stoffnetze statt eines Wechsels dieser
Ganzkörperposen. [Neue Aufnahme und Vorschau](count-bedbug/rig.html).

## Anlass

Der bisherige Graf bleibt trotz Kissenumhang ein weiterer gekrönter Karieszahn.
Der Spieler hat außerdem den Kissenablauf als viel zu langsam und leicht
umgehbar zurückgemeldet. Das ist eine offene Abnahme, kein fertiger Encounter.

Die neue Richtung wurde als Idee angenommen: ein verschlafener, beleidigter
Bettwanzen-Vampir unter dem Kissen. Drei Körperformen werden vor der weiteren
Ausarbeitung verglichen. Der Herrschertitel und das erste Storykapitel bleiben.

## Drei Entwürfe

- **A — Der flache Graf:** Breiter ovaler Bettwanzenkörper, kurze Beine, Monokel.
  Der eng anliegende Umhang öffnet sich zu einem großen gepolsterten Fächer.
  Favorit für den stärksten Wechsel zwischen Ruhe und Angriff.
- **B — Der Schlafrock-Adelige:** Birnenförmiger Körper, kleiner Kopf, Nachtmütze
  und winzige Pantoffeln. Der Schlafrock öffnet sich zur breiten Stoffwand.
  Schwerpunkt: komischer Charakter und erkennbare Schlafenszeit.
- **C — Der Umhang-Graf (ausgewählt):** Kantige, nach unten schmaler werdende Ruheform.
  Zwei große Innenflächen öffnen sich zu versetzten Schlagarmen.
  Schwerpunkt: gut unterscheidbare linke und rechte Schläge.

Die weitere Ausarbeitung folgt C. A und B bleiben als Vergleich erhalten,
bestimmen aber weder das Charakterbild noch die nächsten Spielposen.

Vier zusätzliche generierte Posen von C liegen in `count-bedbug/c-poses.png`:
Ruhe, Auffächern, linker Schlag und rechter Gegenschlag. Die Bewegungsstudie
`count-bedbug/motion.html` zeigt sie als kurze Folge mit gemeinsamem Maßstab
und Fußanker. Einzelschritte sowie eine 112-px-Vorschau sind ebenfalls verfügbar.
Es gibt keine Bildverzerrung oder Morphing-Interpolation. Die vier Posen sind
eine Animationsgrundlage, noch keine vollständige Spielanimation.

Alle Entwürfe: warm gemalter Cartoonstil, pflaumenfarbener Umhang, elfenbeinfarbenes
Polsterfutter, bernsteinfarbene Augen und ein langer einzelner Fangzahn. Keine
Zahnkörperform, keine Krone, keine zusätzlichen herumfliegenden Statussymbole.
Große Stoffflächen statt vieler kleiner Steppdetails. Originalreferenzen bleiben
unverändert. Das Monokel ist ein Bonus, kein nötiges Erkennungsmerkmal bei 64 px.

Je Variante stehen Ruhepose und geöffnete Angriffspose nebeneinander. Die
Vergleichsseite zeigt beide außerdem mit 64 und 112 px längster sichtbarer Kante
sowie als schwarze Silhouette. Bilder werden ausschließlich proportional
skaliert; die Vorschau liest Ausschnitte aus den unveränderten Quelldateien.

## Kampf: weniger Leerlauf, neue Entscheidungen innerhalb der Folge

Die alten Werte erklären das Feedback: 1,25 s Ankündigung, 0,55 s bis zur Falte,
1,3 s langsame Wanderung und anschließend 2,4 s Pause. Ein einmaliger früher
Seitenschritt erledigt zu viel von der ganzen Folge.

Der nächste Kampfentwurf verbindet die Bewegung des Bosses mit dem Schaden:

1. Der Graf nähert sich vor einer Folge sichtbar auf Schlagdistanz. Er bleibt
   kein ungefährlicher Werfer am anderen Ende der Arena.
2. Er richtet sich auf und öffnet den Umhang. Die Bodenwarnung zeigt die
   tatsächlich folgende Schlagfläche. Erster Startwert: etwa 0,85 s Vorwarnung.
3. Ein kurzer, kräftiger Umhangschlag trifft die fest angekündigte Fläche.
   Bildwechsel, ein Stoffknall und wenige Fasern betonen den Moment; keine
   gestreckte Grafik und keine bildfüllende Staubwolke.
4. Nach dem Schlag richtet er sich erneut auf Dentis aktuelle Position aus.
   Zweiter Startwert: etwa 0,75 s sichtbare Ankündigung, dann der Gegenschlag.
   Jede neue Fläche bleibt ab ihrem Warnbeginn fest. Kein unsichtbares Nachführen.
5. Erst danach öffnet eine kurze Erholung von zunächst etwa 1 s die Gelegenheit
   für Nahkampf. Später kann eine klar angekündigte Dreierfolge hinzukommen.

Diese Zeiten sind Entwurfswerte, noch keine implementierten oder vermessenen
Balancewerte. Form und Reichweite werden zusammen mit den Ausweichstrecken
festgelegt; schneller heißt nicht, bloß bestehende Warnzeiten zu kürzen.

Wiederholtes Kreisen darf nicht automatisch alle Folgen lösen. Gleichzeitig
bleibt jeder Einzelschlag bei Grundbewegung vermeidbar. Insbesondere Nähe zum
Boss, Ecken, langsame Builds, normale Wellengegner und zwei Endlosbosse müssen
geprüft werden. Die Folge darf keine schnelle Pflicht-Dash-Kette verlangen:
Dash kostet weiterhin 100 Wurzelkraft, hat 1,5 s Cooldown und gewährt keine
Unverwundbarkeit. Ein Dash durch die aktive Schlagfläche bleibt gefährlich.

Keine dauerhaften Bodenflächen, zusätzliche Milbenhorden oder pauschale
HP-Erhöhung in dieser Entwurfsrunde. Zuerst muss die eigene Schlagfolge tragen.

## Nächste Abnahme

Die Silhouette und der Wechsel von Ruhe zu Drohung müssen bereits klein
funktionieren. Danach folgt eine Bewegungsstudie für Auffächern, Schlag,
Gegenschlag und Erholung, bevor der aktive Encounter ersetzt wird. Zwei
gemalte Posen allein sind noch keine fertige Spielanimation.

Für die spielbare Fassung zählen anschließend: Schaden und Treffer je Angriff,
Bewegungswechsel je Folge, Angriffspausen sowie Nah-/Fernkampf-Erreichbarkeit.
Eine hohe Bestehensquote in automatischen Tests belegt nicht den gewünschten
Spielspaß oder Druck; dafür ist ein menschlicher Vergleich der kompletten
Bosswelle nötig.

## Generierung und Referenzen

Integriertes Imagegen-Werkzeug, echter transparenter Hintergrund. Referenzen:
`assets/denti/denti_unarmed.png` und `assets/enemies/bacteria.png`, ausschließlich
für Malstil, Konturen und Materialbehandlung, nicht für Körperform oder Krone.
Die vollständigen Generierungsprompts stehen in `count-bedbug-prompts.md`.

Die Vergleichsseite `count-bedbug/index.html` zeigt C zuerst sowie die generierten Originale,
proportional verkleinerte Ausschnitte und per Darstellungsfilter erzeugte
Silhouetten. Sie verändert weder Quelldateien noch die Laufzeitressourcen.
