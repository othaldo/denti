# Klassen-Essenz: Eine Klasse ist eine Regel, kein Bonus

Stand **20.11.2026**. Antwort auf den [Horden-Spieltest](HORDE_PLAYSTYLE_REVIEW.md):
Der erste Assassine unterschied sich nur durch Zahlen (Wurzeln, Nahschaden,
+20 % Antritt, Fokusstufen). Bei automatischen Hordenangriffen sind solche Boni
unsichtbar; die Klasse veränderte weder Bewegung noch Itembewertung.

## Verb + Linse + Verzicht

Jede Spezialklasse besteht aus genau drei Teilen:

| Teil | Bedeutung | Prüffrage |
| --- | --- | --- |
| **Verb** | Eine sichtbare räumliche Kernmechanik, die ohne Items funktioniert und die Bewegung gegen die Horde verändert. Meist eine Umdeutung von Dash oder Bewegung. | Erkennt ein Zuschauer mit ausgeblendeten Schadenszahlen nach 60 s, welche Klasse läuft? |
| **Linse** | 2–3 **bestehende** Item-/Effektfamilien erhalten unter dieser Klasse eine zusätzliche Bedeutung, weil sie das Verb speisen. Kein neues Item nötig. | Kauft man im Shop andere Dinge als mit Good Old Molar, aus Lust statt aus Zwang? |
| **Verzicht** | Ein echter Nachteil, der das Verb erzwingt. | Gibt es Situationen, in denen die Klasse klar schlechter ist und anders spielen muss? |

Regeln:

- Das Verb nutzt vorhandene Bausteine: Dashpfad, Nass, Blutung, Schilde,
  Rückstoß, Pfützen, Linienschaden. Kein neues Element nötig.
- Prozentuale Schadensboni sind nie das Verb, höchstens Feinschliff.
- Good Old Molar bleibt der regelfreie Generalist mit sechs Wurzeln.
- Alle Items bleiben für alle Klassen kaufbar; die Linse macht einige besonders gut.
- Talente verändern das Verb räumlich (Dauer, Form, Kreuzung, Anzahl) und zeigen
  jeweils auf eine Linsenfamilie. Keine versteckte Sperre zwischen Ästen.

## Hordenverben der geplanten Klassen

| Klasse | Verb | Linse | Verzicht |
| --- | --- | --- | --- |
| **Assassine** – Giftschneise | Der Dash geht ohne Kontaktschaden durch Gegner und zieht eine Giftspur. Kurz danach schnappt sie zu (Treffer + Gift auf der ganzen Linie) und bleibt 3 s als sichtbares Giftfeld liegen, das alles vergiftet, was hineinläuft. Spur-Kills geben begrenzt Wurzelkraft zurück. | Gift (Depotfüllung verstärkt das Spurgift, Nervensonde lässt das Feld verlangsamen, Giftaufbau-Stapel), Zucker („während du dich bewegst“ zählt doppelt), Nahschaden und Wurzelkraft | 4 Wurzeln, 85 Schmelz, nur kurze Kontaktwaffen |
| **Hüter** – Standhalten | Statt Bewegungsdash ein Zahnstampfer: radialer Rückstoß, ein Schild, löscht Projektile im Radius. Stillstand baut einen Schmelzring auf, der Gegner abprallen lässt. | Härte, Schilde/Schildblock, Keramiksplitter, Speichel | Langsamer, kein Bewegungsdash, Zucker nahezu wertlos |
| **Spültechniker** – Raum vorbereiten | Laufen hinterlässt eine begrenzte Spülspur. Gegner darauf sind nass; Elektro/Licht und Ketten springen entlang der Spur. Dash spült die ganze Spur einmal. | Wasser/Ketten, Leitlack, Spülventil, Bewegung | Weniger direkter Waffenschaden |

Später, erst nach Abnahme dieser drei: **Kariesteufel** (Gegnerdichte in der Nähe
gibt Tempo, Abstand lässt es zerfallen) und **Zahnfee** (Aufsammeln löst Effekte aus).

## Hordenablauf des Assassinen

Annäherung: Gegner ziehen zusammen → **Durchqueren:** Dash mitten durch die Gruppe,
ohne Kontaktschaden → **Zuschnappen:** 0,25 s danach trifft und vergiftet die ganze
Linie hinter Denti → **Schneise:** das Giftfeld bleibt liegen; die Horde muss hindurch,
um Denti zu folgen → nächster Durchgang. Projektile, Flächenangriffe und Kontakt außerhalb
des Dashs bleiben gefährlich.

**Korrektur 20.11.2026:** Der erste Prototyp setzte auf Blutung, kurz sichtbare Linie und
reduzierten statt aufgehobenen Kontaktschaden. Spieltest-Feedback: Gift war das Ziel,
die Spur kaum wahrnehmbar und der Dash in Gegner nicht anders als der normale.
Antritt/Fokus des ersten Assassinen entfallen ebenfalls; Good Old Molar behält sein
optionales Antrittstalent.

### Werte des Prototyps

Daten: `data/classes/assassin.tres` (`ClassCombatData`), Talente:
`data/talents/assassin.tres`, Logik: `scripts/player/class_dash_cut.gd`.

| Wert | Start |
| --- | --- |
| Kontaktschaden im Dash | keiner (kein Schild- oder Ausweichverbrauch); außerhalb des Dashs normal |
| Spurschaden je Gegner | 16 + 150 % Nahschaden, skaliert mit Bisskraft und Item-Waffenboni |
| Spurgift je Treffer | 30 + 200 % Nahschaden Giftbudget, über die normale Giftdauer, mit Aufbau-Stapeln |
| Giftfeld | 3 s, alle 0,5 s 20 % des Spurgifts für jeden Gegner im Feld |
| Depotfüllung | +50 % Spurgift je Item-Stärke |
| Nervensonde | Gegner im Feld werden verlangsamt (wie Talent Lähmende Schneise) |
| Zucker-Bewegungsbonus | zählt ×2 für den Spur-Direktschaden |
| Breite / Verzögerung | 44 px / 0,25 s |
| Wurzelkraft je Spur-Kill | 10, höchstens 40 je Spur |
| Gleichzeitige Spuren | 2 |

Spurtreffer sind Sekundärschaden ohne Waffe: keine rekursiven Waffen-Procs,
Bossschutz und Phasensperren bleiben wirksam. Telemetrie: Proc-Schaden
`class_trail`, Zähler `class_trail_hits`, `class_trail_kills`,
`class_trail_refund`, `class_trail_crosses`, `class_trail_field_ticks`.

### Talentbaum: Reihen, Pfeile und Attribut-Wegknoten

Seit 20.11.2026 gibt es keinen getrennten Attribut-Tab mehr. Jede Klasse hat einen
Baum aus drei Ästen nebeneinander (WoW-Classic-Prinzip):

- **Reihen:** Reihe *n* eines Astes öffnet sich mit *n* × 3 investierten Punkten
  in diesem Ast. Die Linie mit der Zahl markiert die erste noch geschlossene Reihe.
- **Attribut-Wegknoten (Kreise):** Jeder Rang gibt das Attribut mit der beim Level
  gewürfelten Seltenheit, wie die früheren Statkarten. Sie zählen für die Reihen und
  sind damit der Weg zu tieferen Talenten.
- **Freie Wurzeln (Kreis mit +):** nach PoE2-Vorbild (dort „Travel Nodes“ mit
  frei wählbarem Attribut). Das Attribut wird beim Skillen in der Detailbox gewählt;
  für die Klasse nutzlose Werte (Fernschaden beim Assassinen) fehlen. Jeder Ast hat
  spätestens in Reihe 2 eine freie Wurzel. So kann keine Talentroute Schmelz, Härte
  oder Schaden aushungern; das ist die Absicherung für Hell und automatisch geprüft.
- **Talente (Kacheln):** verändern das Klassenverb. Pfeile markieren echte
  Abhängigkeiten. Keine exklusiven Abschlüsse, keine versteckten Sperren.
- **Schlüsselsteine** tauschen eine Stärke gegen eine andere statt flacher Boni.
- Der dritte Ast ist eine allgemeine Grundlage mit hohen Attributrängen, damit lange
  Endlos-Runs ihre Punkte immer verteilen können (Kapazität ≥ 100).

| Assassine | Inhalt |
| --- | --- |
| **Giftspur** | Nahschaden, Bisskraft, Glanz, Putzeifer · Giftfaden (+10 Spurgift, 3) → Lähmende Schneise (Feld verlangsamt) → Breite Schwaden (+14 px, 2) → **Zuschnüren** (Überlebende 45 px auf die Spur ziehen) · Lange Schwaden (+1 s Feld, 2) · Scharfe Seide (+8 Spurschaden, 2) · Schlüsselstein **Giftschneise** (Spur-Direktschaden 35 %, Spurgift ×2,5) · 4 freie Wurzeln |
| **Zuckerrausch** | Bewegung, Wurzelkraft, Zahnflutsch, Putzeifer · Naschkatze (Rückgabe, 3) · Weiter Sprung (+30 px Dashweite, 2) → Kreuzschnitt → Doppelspule / Nachbrenner (Spur-Kill setzt Dash-Abklingzeit zurück) → Schlüsselstein **Sprintfaden** (Dash −25 Wurzelkraft, mindestens halbe Kosten; Spur-Direktschaden −25 %) · 3 freie Wurzeln |
| **Zahnpflege** | Schmelz, Härte, Speichel, Zahnglück · Versiegelung · 4 freie Wurzeln |

Good Old Molar: **Werkzeug**, **Standfest**, **Beweglichkeit** mit seinen bisherigen
Talenten und je drei bis vier freien Wurzeln. Talent-IDs bleiben kompatibel.

Damit entstehen beim Assassinen unterscheidbare Wege: Giftteppich (Giftspur +
Lange Schwaden + Giftschneise, Depotfüllung/Nervensonde), Dauerdash (Zuckerrausch + Sprintfaden, Zucker- und
Bewegungsitems), Kreuzungsjäger (Kreuzschnitt + Doppelspule + Zuschnüren) oder ein
zäher Mischbuild über Zahnpflege und freie Wurzeln. Offen: Hell-Earned-Runs je Weg
als Diagnose und ein menschlicher Spieltest.

Bedienung: Tippen wählt, erneutes Tippen auf den gewählten Knoten skillt. Die Ansicht
passt den Baum ohne Scrollen ein: breit alle drei Äste plus Details rechts, schmal ein
Ast mit Tabs, im Querformat wächst der Baum nach rechts.
[Desktop](screenshots/class_talents/tree_v2_desktop.png),
[Handy hoch](screenshots/class_talents/tree_v2_mobile.png),
[Handy quer](screenshots/class_talents/tree_v2_landscape.png),
[Good Old Molar](screenshots/class_talents/tree_v2_molar_mobile.png).
Code: `scripts/ui/talent_tree_view.gd`, `scripts/ui/talent_node_button.gd`,
Daten `data/talents/*.tres` (`row`, `column`, `stat`, `points_per_row`).

## Abnahme

Automatische Tests prüfen Regeln, Grenzen, Save/Resume und Bossschutz. Entscheidend
ist der menschliche Spieltest auf Handy und Desktop mit ausgeblendeten
Schadenszahlen: Fühlt sich der Assassine nach ein bis zwei Wellen anders an als
Good Old Molar, und werden Blutungs-/Zuckeritems anders bewertet? Erst danach
folgen Hüter und Spültechniker.
