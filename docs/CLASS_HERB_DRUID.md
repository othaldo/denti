# Kräuterzahn – Druidenklasse (Konzept)

Entwurf vom **23.11.2026**, **umgesetzt am selben Tag**. Werte sind Schätzungen,
Spieltests stehen aus. Gemalte Grafik ist bei Codex beauftragt
([Auftrag](../assets/classes/herb_druid.prompt.md)); bis dahin zeigt das Spiel
Platzhalter (Denti-Porträt, Extraktionsstab-Bild, gezeichnete Pflanzen,
Platzhalter-Talentsymbole). Grundlage sind
[Klassen-Essenz](CLASS_ESSENCE.md) (Verb + Linse + Verzicht) und der
[Talentbaum v3](TALENT_TREE_V3_PLAN.md) mit drei Ästen, je einem Skill in Reihe 3.

**Idee:** Denti trägt keine Kampfwaffe, sondern einen Pflanzstab. Jeder „Angriff“
setzt eine Heilpflanze dorthin, wo Denti steht. Pflanzen wachsen, kämpfen und
verwelken nach einer Weile. Je schneller Denti pflanzt, desto mehr Pflanzen stehen
gleichzeitig auf dem Feld. Alle Pflanzen sind echte Zahnheilkräuter: Salbei,
Kamille, Gewürznelke.

Abgrenzung zum Nekrodent: Seine Zähne folgen Denti und beißen. Die Pflanzen des
Kräuterzahns stehen fest. Er baut einen **Garten** und lockt die Horde hinein.

## Verb, Linse, Verzicht

| Teil | Inhalt |
| --- | --- |
| **Verb** | Pflanzen statt schießen. Der Pflanzstab setzt im Angriffstakt einen Salbeitrieb an Dentis Standort. Salbeitriebe schießen selbstständig auf Gegner in Reichweite. Pflanzen verwelken nach einer festen Lebenszeit; so viele stehen gleichzeitig, wie in diese Zeit hineinpassen (Lebenszeit ÷ Pflanztakt), höchstens bis zu einer Obergrenze. |
| **Linse** | **Putzeifer** (schneller pflanzen = größerer Garten), **Fernschaden** (Salbeischuss), **Glanz** (Salbei-Krits). Element-Verzauberungen des Pflanzstabs gehen auf die Salbeischüsse über, wie beim Nekrodent auf die Bisse. Flächen- und Pfützen-Items wirken im Garten doppelt gut, weil die Horde dort steht. |
| **Verzicht** | Denti selbst macht keinen Schaden. Wer flieht, lässt seinen Garten zurück und kämpft mit leeren Händen. Der Garten braucht Anlaufzeit: Zu Wellenbeginn und nach einem Rückzug ist der Kräuterzahn schwach. |

**Hordenablauf:** Stehenbleiben und pflanzen → die Horde läuft in den Garten → am
Rand kreisen, damit neue Triebe die Lücken füllen → bei Druck in einen zweiten
Garten ausweichen.

## Pflanzstab (Exklusivwaffe)

- 1 Wurzel, wie der Extraktionsstab des Nekrodenten. Andere Waffen kann der
  Kräuterzahn nicht tragen.
- Angriffstakt = Pflanztakt (Putzeifer verkürzt ihn).
- Shop-Fusion Mk II–IV: Pflanzen leben länger, Obergrenze steigt, Salbei schießt weiter.
- Verzauberungen: ein Element pro Stab, wirkt auf alle Salbeischüsse.

| Wert (Mk I, Startschätzung) | |
| --- | --- |
| Pflanztakt | 1,6 s |
| Lebenszeit einer Pflanze | 12 s → etwa 7 Pflanzen gleichzeitig |
| Obergrenze | 10 (Mk IV: 16) |
| Wachstum bis zum ersten Schuss | 0,6 s |
| Salbeischuss | 6 + 0,6 × Fernschaden, alle 0,9 s, mittlere Reichweite |

Die Werte sind Schätzungen und werden über die bestehenden Wellenproben eingestellt.

## Talentbaum: drei Äste

Jeder Ast folgt dem bekannten Schema: Reihen 0–1 Attribute und eine freie Wurzel,
Reihe 2 eine Gabel, Reihe 3 der Skill, Reihe 4 Modifikatoren, Reihe 5 ein
Schlüsselstein. Die Skills fügen dem Pflanztakt neue Pflanzen hinzu. Mit mehreren
Skills wechselt der Stab reihum: zum Beispiel Salbei, Kamille, Salbei, Nelke.

### Ast 1: Salbeibeet (Angriff) → Skill **Salbeistrauch**

- Talente: **Dornen** (Salbeischüsse durchbohren einen Gegner), **Dichtes Beet**
  (+1 Obergrenze je Rang), **Bitterkraut** (+Salbeischaden je Rang).
- **Skill Salbeistrauch:** Jeder fünfte Trieb wächst zu einem großen Strauch, der
  statt Einzelschüssen eine kurze Salve auf mehrere Gegner feuert.
- Modifikatoren: **Wildwuchs** (jeder vierte statt jeder fünfte), **Samenschuss**
  (Strauch-Salve platzt in kleine Samen), **Tiefe Wurzeln** (Sträucher leben doppelt so lang).
- Schlüsselstein **Monokultur:** Nur noch Salbei, keine Kamille und Nelke mehr; dafür
  +50 % Obergrenze.

### Ast 2: Kamillenhain (Unterstützung) → Skill **Kamillentotem**

- Talente: **Beruhigend** (Speichel-Regeneration in Gartennähe), **Gießkanne**
  (Pflanzen in Dentis Nähe leben länger), **Blütenstaub** (+Putzeifer je Rang).
- **Skill Kamillentotem:** Jede vierte Pflanzung ist ein Kamillentotem. Seine Aura
  gibt Denti und Salbeitrieben im Umkreis mehr Angriffstempo und heilt Denti langsam.
- Modifikatoren: **Großer Kranz** (größere Aura), **Kamillentee** (Aura gibt alle paar
  Sekunden einen Schild), **Ableger** (ein verwelkendes Totem setzt einen neuen Trieb).
- Schlüsselstein **Teezeremonie:** Totems wirken doppelt so stark, aber Denti bewegt
  sich in der Aura langsamer.

### Ast 3: Nelkenhecke (Kontrolle) → Skill **Nelkenknospe**

- Talente: **Betäubung** (Salbeischüsse verlangsamen kurz), **Ranken** (Dash setzt
  am Startpunkt einen Trieb), **Hecke** (Pflanzen halten mehr Gegnerkontakt aus).
- **Skill Nelkenknospe:** Jede vierte Pflanzung ist eine Nelkenknospe. Nelkenöl
  betäubt: Gegner im Umkreis sind verlangsamt und nehmen mehr Schaden aus allen
  Quellen, auch von Bossen.
- Modifikatoren: **Nelkenöl** (stärkere Betäubung), **Platzende Knospe** (explodiert
  beim Verwelken), **Würgeranke** (Gegner bleiben am Rand kurz hängen, nicht Bosse).
- Schlüsselstein **Giftgarten:** Nelken geben Gift statt Verlangsamung; Gift-Items
  werden zur zweiten Linse.

### Dash

Der Dash bleibt ein normaler Ausweich-Dash. Über **Ranken** wird er zum Werkzeug:
Er setzt einen Trieb am Startpunkt und lässt beim Rückzug einen Wachposten stehen.

## Pflanzen im Kampf

- Gegner können Pflanzen angreifen. Pflanzen haben eigenen Schmelz und verwelken
  früher, wenn sie zu viel abbekommen. Bosse zertrampeln Pflanzen, die ihnen im Weg
  stehen, ähnlich wie bei den Eiswänden des Frostwächters.
- Gegnerische Geschosse treffen nur Denti, nicht die Pflanzen. Die Arena bleibt
  lesbar.
- Bosse: Salbeischaden zählt als Fernschaden; Nelkenknospen öffnen Verwundbarkeits-
  fenster. Ein reiner Salbeigarten soll gegen Bosse bewusst etwas länger brauchen.
- Optik: drei klar unterscheidbare Silhouetten (schmaler grüner Trieb, runder
  gelb-weißer Kamillenkranz, braun-rote Nelkenknospe), Wachstumsanimation,
  Verwelken über die letzte Sekunde. Salbeischüsse grün und klar von
  Gegnergeschossen unterscheidbar.

## Freischaltung

Passend zum „Garten“: **einen Run ab Welle 15 mit drei oder mehr Fernkampfwaffen
beenden.** Wer viele Fernwaffen trägt, lernt den Kampf aus der Distanz. Dafür bekommt
`ClassUnlockData` eine zweite Art von Bedingung (Anzahl Waffen einer Rolle). Die
Alternative ohne neue Bedingungsart wäre ein Zähler wie „50 Elites“.

## Shop, Items und Relikte

Bestehende Items reichen für den Start (Linse). Später, zusammen mit der
Heilerklasse, sind diese Synergie-Items denkbar:

- **Blumentopf:** Platzierte Objekte (Pflanzen, Eiswände, Pfützen, Giftfelder) halten
  länger.
- **Dünger:** Pflanzen und Gefolgschaft (Nekrodent) teilen sich einen Schadensbonus
  je Element-Verzauberung.
- Relikt **Mundgarten:** Getötete Gegner hinterlassen manchmal einen kurzlebigen
  wilden Trieb, auch bei anderen Klassen.

## Grafik (Auftrag für Codex)

- Porträt Kräuterzahn: Denti mit Blätterkranz, Gartenschürze, kleinem Pflanzstab.
- Pflanzstab (Waffe, Mk-Stufen werden vom bestehenden System getönt).
- Kampf-Sprites: Salbeitrieb, Salbeistrauch, Kamillentotem, Nelkenknospe,
  jeweils mit klarer Silhouette bei kleiner Größe.
- Talent-Icon-Atlas für den Baum (wie bei den anderen Klassen).

## Technik

- `HerbSkills` als `ClassSkillModule` (wie `NecrodentSkills`), registriert in
  `ClassSkillRegistry`. Hält die Pflanzen, ihr Wachstum, die Auren und Schüsse.
- Pflanzstab mit `attack_mode = &"plant"`; der Angriffstakt ruft das Modul auf
  statt selbst anzugreifen.
- Klassendaten und Baum über `tools/generate_class_roster.py`.
- Spielstand: Pflanzen (Ort, Art, Restzeit, Schmelz) und Rotation werden gespeichert.
- Performance: harte Obergrenze, Schüsse über den vorhandenen Projektilpfad,
  Zielwahl über `EnemySpatialIndex`.
- Tests: Pflanztakt bestimmt die Gartengröße, Obergrenze, Rotation der Skills,
  Totem-Aura, Nelken-Debuff auch an Bossen, Bosse zertrampeln Pflanzen,
  Speichern/Fortsetzen, Freischaltbedingung.

## Entscheidungen

1. Der Kräuterzahn trägt ausschließlich den Pflanzstab (1 Wurzel).
2. Gegner nutzen Pflanzen bei Kontakt ab (eigener Schmelz); gegnerische Geschosse
   treffen Pflanzen nicht. Bosse zertrampeln Pflanzen sofort. Gegner suchen Pflanzen
   nicht gezielt auf.
3. Freischaltung: Run ab Welle 15 mit drei Fernkampfwaffen beenden
   (`ClassUnlockData.role`/`role_count`).

## Umsetzung

- `scripts/player/herb_skills.gd` (`HerbSkills`): Pflanzen, Rotation, Schüsse über
  `PlayerProjectilePool` mit Stabdaten (Verzauberungen, Krits, Items wirken), Auren,
  Nelken-Betäubung (Nervenverlangsamung + Waffenschadensbonus über `damage_bonus`),
  Würgeranke, Speichern.
- Pflanzstab: `data/weapons/planting_staff.tres`, `attack_mode = &"plant"`; der
  Angriffstakt ruft `HerbSkills.plant()` auf, sobald Gegner in Reichweite sind.
  Schaden, Angriffspause und Reichweite in Shop und Verzauberung gelten für die
  Salbeischüsse beziehungsweise den Pflanztakt.
- Klasse und Baum: `python tools/generate_class_roster.py herb_druid`.
- Test: `tests/herb_druid.gd`.
