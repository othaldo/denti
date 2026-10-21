# Run-Vorbereitung und Startwaffenauswahl

Stand: 22.10.2026. Alle 18 Standardwaffen sind ohne Freischaltung auswählbar.
Die Run-Vorbereitung nutzt eine gemeinsame native Auswahlbühne mit vier gemalten
Schwierigkeitsmotiven, Iconraster und kompakter Waffenvorschau.
[Gestaltungsgrundlage und Prüfregeln](UI_UX_PLAN.md).
Der reguläre `WeaponCatalog.ALL` ist die Quelle; `STARTERS` ist nur noch ein
Kompatibilitätsalias. Geheime Evolutionen bleiben außerhalb dieses Katalogs.
Waffen müssen in die konfigurierte Wurzelkapazität des Spielers passen.

## Menüablauf

Die Vorbereitung findet vollständig im Hauptmenü statt:
**1. Schwierigkeit → Weiter → 2. Startwaffe → Run starten**.
Die Schwierigkeitsbuttons markieren zunächst nur eine Auswahl. Zurück und Weiter
behalten Schwierigkeit und Waffenvorschau; Escape geht zum vorherigen Schritt.
Arena, Denti im Spielfeld, Timer und Kampf-HUD sind währenddessen nicht geladen.
Bei Story-Runs folgt nach „Run starten“ erst das Intro, dann Welle 1 mit der bereits
gewählten Waffe, ohne eine zweite Waffenauswahl.

`RunSetup.STEPS` definiert die Reihenfolge. Eine spätere Klassenauswahl kann als
eigener Schritt mit eigener Ansicht zwischen Schwierigkeit und Waffe eingefügt
werden. Es gibt noch keine sichtbare oder spielbare Klassenauswahl.

## Auswahl

Ein Antippen markiert die Waffe im Iconraster und zeigt ihre gemalte Grafik,
ihren Namen, Wurzelkosten und drei Iconwerte: Mk-I-Grundschaden, Angriffspause und
Reichweite. Mechaniken und Skalierung sind über „Details“ abrufbar;
die drei Wertflächen öffnen ihre jeweilige Bedeutung auch per Antippen.
Vorschauen vergeben keine Waffen und starten keinen Kampf.
Ohne Auswahl ist die Bestätigung deaktiviert. Erst „Run starten“
vergibt eine normale Mk-I-Waffe ohne Zufallsrollen oder Verzauberung und beginnt
Welle 1. Mehrfachbestätigung kann keine zweite Waffe oder Welle erzeugen.

Die Vorbereitung wird getrennt vom Kampfspielstand unter
`<run_save_path>.setup.json` gespeichert. Fortsetzen ohne aktiven Run stellt
Schritt, Schwierigkeit und Vorschau wieder her. Ein bestehender Run bleibt
während der Vorbereitung eines neuen Runs unverändert; erst der endgültige
Start ersetzt ihn. Fortsetzen eines aktiven Runs lädt weiterhin diesen Run.

Alte Spielstände mit `starter_pending` werden beim Fortsetzen zuerst als offene
Waffenauswahl ins Menü übernommen. Ihre Vorschau und Wurzelgrenze bleiben erhalten;
der bestätigte Start setzt den gespeicherten Zustand fort und beginnt genau
Welle 1. `starter_preview` bleibt für diese Kompatibilität im Run-Snapshot.

## Darstellung

`RunSetupScreen` enthält die gemeinsame Bühne, Schrittanzeige und feste Navigation.
`DifficultySelection` und `WeaponSelection` liefern nur den jeweiligen Inhalt;
`RunSetup` verwaltet Wahl, besuchte Schritte und Entwurf. `StarterSelection` nutzt
für alte offene Spielstände und Testarenen dieselbe Waffenansicht.
Belohnungskarten bleiben für Aufstiege, Kapseln und Relikte zuständig.

Vier zusammengehörige Imagegen-Motive zeigen steigende Gefahr um denselben Denti.
[Originalatlas, Referenzen und vollständiger Prompt](concepts/run-setup-art/README.md).
Die Motive und vorhandenen Waffenbilder behalten Seitenverhältnis und Originalfarben.
Die 18 Waffen nutzen eigene, symmetrisch eingerückte Bildflächen statt der
linksbündigen Button-Icons. Gemessene sichtbare Bildgrenzen in
`RunSetupPresentation.ICON_BOUNDS` gleichen ungleiche transparente Ränder aus;
die Originale und die Ausrichtung im Kampf bleiben erhalten. Markierungen liegen
darüber und verändern weder Bildgröße noch Mitte. Kleine Karten verwenden kleinere
Häkchen. Dieselben Bildausschnitte gelten für die große Waffenvorschau.
Mipmaps glätten die Schwierigkeitsbilder; eine lokale MSDF-Schrift bleibt bei
kleinen Fenstern und mobiler Projektskalierung scharf.

Desktop: vier Schwierigkeitskarten beziehungsweise 18 Waffen im 6×3-Raster,
große Vorschau daneben. Hochformat: Schwierigkeiten in 2×2, Waffen über einer
kompakten Vorschauzeile. Nur die Galerie scrollt bei Platzmangel; die Standardansicht
hat keinen zweiten Text-Scrollbereich. Die gemeinsame Navigation bleibt stehen.
Ein lokaler Skalierungsausgleich erhält mindestens 48×48 große Ziele in kleinen
physischen Fenstern, ohne die globale Kampf- oder Kameraskalierung zu ändern.

Auswahl = Goldkontur und Häkchen, Tastaturfokus = zusätzliche cremefarbene Kontur.
Pointerfokus erhält diese Kontur nicht. Die Hauptaktion trägt die volle Goldfläche.
Hell bleibt vor dem Hard-Sieg abgedunkelt und inspizierbar; der kurze Sperrhinweis
steht direkt auf der Karte. Doppelklick/-tippen auf „Weiter“ bestätigt nicht zusätzlich
„Run starten“. Rückmeldungen blockieren die Eingabe nicht; reduzierte Bewegung
wird respektiert. Details schließen per Escape, ohne den Schritt dahinter zu ändern.

## Prüfung

**134/134 automatisierte Tests bestanden** (vollständiger Lauf am 22.10.2026).
Die Auswahl wird mit Ablauf-, Eingabe- und Layouttests geprüft.
Nach der Zentrierkorrektur wurden die vier betroffenen UI-/Ablauftests erneut
erfolgreich ausgeführt. Alle 18 Waffen wurden nativ in gewähltem und ungewähltem
Zustand auf Desktop und schmalem Handy geprüft; die sichtbare Bildmitte und
der unveränderte Bildbereich beim Auswählen sind zusätzlich automatisiert geprüft.
Native Aufnahmen zeigen alle sechs Größen sowie das unveränderte Desktop-Stretch
und die tatsächliche mobile Projektbasis. Mausauswahl, Weiter und Escape wurden
zusätzlich über die native GUI-Eingabe geprüft.

Automatisierte Prüfung aller 18 Starts, keine Evolutionen/Duplikate, Mk-I-Werte,
Vorschau ohne Vergabe, leere/mehrfache Bestätigung, gespeicherte Vorschau und alte
Saves. Der Menütest prüft Vor/Zurück, Entwürfe, Schutz eines bestehenden Runs,
Migration offener Auswahlen und Story-Intro mit vorbereiteter Waffe.
Bestehende Wurzelkapazitäts- und Fortschrittstests prüfen eingeschränkte
Starts und den weiteren Spielfluss. Layout und Scrollzugang werden in 320×568,
568×320, 720×1280, 1040×600, 1280×720 und 1920×1080 geprüft.
Der zusätzliche GUI-Test prüft echte Trefferflächen, Modal-Fokus, Escape,
besuchte Schritte, Doppelklickschutz, lange Namen und alle Touchflächen mit der
mobilen Projektbasis im physischen 320×568-Fenster.

Native Aufnahmen der tatsächlichen UI:

- [Schwierigkeit](screenshots/starter_selection/difficulty_1280x720.png)
- [Startwaffe auf Desktop](screenshots/starter_selection/1280x720.png)
- [Schmales Hochformat](screenshots/starter_selection/320x568.png)
- [Kleines Querformat](screenshots/starter_selection/568x320.png)
- [Echte Desktop-Projektskalierung](screenshots/starter_selection/desktop_project_stretch.png)
- [Echte mobile Projektskalierung](screenshots/starter_selection/mobile_project_weapon.png)
- [Abrufbare mobile Details](screenshots/starter_selection/mobile_project_details.png)
- [Gesperrtes Hell](screenshots/starter_selection/hell_requirement.png)

Aufnahmen erneut erzeugen:
`Godot_v4.7.2-stable_win64_console.exe --path . --script res://tools/preview_starter_selection.gd`

Die ersten drei vollständigen Wellen mit jeder Waffe, Überlebensrate und erste
Kaufmöglichkeiten benötigen noch Build-/Spielvergleiche. Die funktionierende
Startauswahl ist keine Balancefreigabe für alle Starts; Werte wurden hier nicht
pauschal angehoben.
