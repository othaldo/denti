# Kräuterzahn – Druidenklasse (Konzept)

Entwurf vom **23.11.2026**, **umgesetzt am selben Tag**. Werte sind Schätzungen,
Spieltests stehen aus. Gemalte Grafik ist bei Codex beauftragt
([Auftrag](../assets/classes/herb_druid.prompt.md)); bis dahin zeigt das Spiel
Platzhalter (Denti-Porträt, Extraktionsstab-Bild, gezeichnete Pflanzen,
Platzhalter-Talentsymbole). Grundlage sind
[Klassen-Essenz](CLASS_ESSENCE.md) (Verb + Linse + Verzicht) und der
[Talentbaum v3](TALENT_TREE_V3_PLAN.md) mit drei Ästen, je einem Skill in Reihe 3.

**Idee:** Denti trägt keine Kampfwaffe, sondern einen Pflanzstab. Jeder „Angriff“
setzt eine Heilpflanze in Dentis Umgebung. Pflanzen wachsen, kämpfen und
verwelken nach einer Weile. Je schneller Denti pflanzt, desto mehr Pflanzen stehen
gleichzeitig auf dem Feld. Alle Pflanzen sind echte Zahnheilkräuter: Salbei,
Kamille, Gewürznelke.

Abgrenzung zum Nekrodent: Seine Zähne folgen Denti und beißen. Die Pflanzen des
Kräuterzahns stehen fest. Er baut einen **Garten** und lockt die Horde hinein.

## Verb, Linse, Verzicht

| Teil | Inhalt |
| --- | --- |
| **Verb** | Pflanzen statt schießen. Der Pflanzstab setzt im Angriffstakt einen Salbeitrieb in Dentis Umgebung. Salbeitriebe schießen selbstständig auf Gegner in ihrer Reichweite. Wie viele Pflanzen gleichzeitig stehen, ergibt sich aus Lebenszeit ÷ Pflanztakt. |
| **Linse** | **Putzeifer** (schneller pflanzen = größerer Garten), **Fernschaden** (Salbeischuss), **Glanz** (Salbei-Krits). Element-Verzauberungen des Pflanzstabs gehen auf die Salbeischüsse über, wie beim Nekrodent auf die Bisse. Flächen- und Pfützen-Items wirken im Garten doppelt gut, weil die Horde dort steht. |
| **Verzicht** | Denti selbst macht keinen Schaden. Wer flieht, lässt seinen Garten zurück und kämpft mit leeren Händen. Der Garten braucht Anlaufzeit: Zu Wellenbeginn und nach einem Rückzug ist der Kräuterzahn schwach. |

**Hordenablauf:** Stehenbleiben und pflanzen → die Horde läuft in den Garten → am
Rand kreisen, damit neue Triebe die Lücken füllen → bei Druck in einen zweiten
Garten ausweichen.

## Pflanzstäbe (Exklusivwaffe, bis zu drei)

- Start mit einem Stab und 1 Wurzel. Andere Waffen kann der Kräuterzahn nicht tragen.
- Die Talente **Zweiter Stab** (Salbeibeet, Reihe 2) und **Dritter Stab** (Reihe 4)
  öffnen je eine Wurzel (`extra_roots` → `PlayerStats.talent_roots`). Ist eine Wurzel
  frei, bietet der Shop einen weiteren Pflanzstab an, sonst die Fusion des
  schwächsten Stabs.
- **Jeder Stab pflegt seinen eigenen Garten:** eigener Pflanztakt, eigenes Element,
  eigene Mk-Stufe und Verzauberungen. Der Bodenschein zeigt das Element pro Pflanze.
- **Keine feste Obergrenze:** Wie viele Pflanzen stehen, ergibt sich aus Lebensdauer ÷
  Pflanztakt (Mk I: etwa 5). Putzeifer, „Dichtes Beet“ und Mk-Stufen lassen den Garten
  wachsen. Nur eine Sicherheitsgrenze von 30 Pflanzen pro Stab schützt die Leistung.
- Angriffstakt = Pflanztakt (Putzeifer verkürzt ihn). Stäbe pflanzen während der ganzen
  Welle, auch ohne Gegner in der Nähe, mit Versatz untereinander und leichter Streuung.
- Neue Pflanzen landen zufällig im Umkreis um Denti, bevorzugt an freien Stellen.
- **Fokusfeuer:** Jeder Trieb bevorzugt unter den Gegnern in seiner Reichweite die,
  die Denti am nächsten sind.
- **Don Karamello:** Eine ausgewachsene Pflanze hält ein Karamellherz in ihrer Nähe
  offen, auch wenn Denti weiter weg ist.
- **Ernte:** Beute neben einer ausgewachsenen Pflanze fliegt zu Denti, damit Kills auf
  Entfernung XP und Münzen bringen.
- Shop-Fusion Mk II–IV: Pflanzen leben länger, Salbei schießt weiter und stärker.
- Fällt ein Stab weg (Fusion, Klassenwechsel), übernimmt der erste Stab seine Pflanzen.

| Wert (Mk I, Startschätzung) | |
| --- | --- |
| Pflanztakt | 1,6 s |
| Lebenszeit einer Pflanze | 8 s (+1,5 s je Mk-Stufe) → etwa 5 Pflanzen auf Mk I |
| Dichtes Beet | +10 % Pflanztakt je Rang |
| Wachstum bis zum ersten Schuss | 0,6 s |
| Salbeischuss | 10 + 1,5 × Fernschaden, alle 0,8 s, mittlere Reichweite. Viele kleine Schüsse: Fernschaden ist das Hauptattribut, Bisskraft der spätere Multiplikator. |
| Startwerte | +20 Schmelz, +2 Härte (Denti kämpft nicht selbst) |
| Bosse | zertrampeln Pflanzen mit dreifachem Kontaktschaden |

Bot-Proben (`tools/benchmark_herb_druid.gd`, Normal) gaben den Ausschlag für
Fokusfeuer, Ernte, höheren Salbeischaden und die Startwerte: Ohne Ernte sammelte der
Kräuterzahn nur ein Viertel der XP und Münzen von Good Old Molar.

Die Werte sind Schätzungen und werden über die bestehenden Wellenproben eingestellt.

## Talentbaum: drei Äste

Jeder Ast folgt dem bekannten Schema: Reihen 0–1 Attribute und eine freie Wurzel,
Reihe 2 eine Gabel, Reihe 3 der Skill, Reihe 4 Modifikatoren, Reihe 5 ein
Schlüsselstein. Die Skills fügen dem Pflanztakt neue Pflanzen hinzu. Mit mehreren
Skills wechselt der Stab reihum: zum Beispiel Salbei, Kamille, Salbei, Nelke.

### Ast 1: Salbeibeet (Angriff) → Skill **Salbeistrauch**

- Talente: **Dornen** (Salbeischüsse durchbohren einen Gegner), **Dichtes Beet**
  (+10 % Pflanztakt je Rang), **Zweiter Stab** (Reihe 2) und **Dritter Stab**
  (Reihe 4) öffnen je eine Wurzel für einen weiteren Pflanzstab.
- **Skill Salbeistrauch:** Jeder fünfte Trieb wächst zu einem großen Strauch, der
  statt Einzelschüssen eine kurze Salve auf mehrere Gegner feuert.
- Modifikatoren: **Wildwuchs** (jeder vierte statt jeder fünfte), **Samenschuss**
  (Strauch-Salve platzt in kleine Samen).
- Schlüsselstein **Monokultur:** Nur noch Salbei, keine Kamille und Nelke mehr; dafür
  leben Pflanzen 50 % länger.

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
- Texte: Verzauberungen, Schadenseinheit („Schaden/Salbeischuss“), „Pflanztakt“ statt
  „Angriffspause“ und die Startauswahl beschreiben die Wirkung auf die Pflanzen.
- Elemente: Bis die gemalten Varianten da sind
  ([Auftrag](../assets/weapons/planting_staff_elements.prompt.md)), tönt
  `WeaponSkins.TINTED_STAFFS` den Samen im Stabkopf in der Elementfarbe. Die Pflanzen
  tragen einen Bodenschein in derselben Farbe.
- Test: `tests/herb_druid.gd`. Vorschau: `tools/preview_herb_garden.gd`
  (`HERB_ELEMENT=fire` für einen verzauberten Garten).
