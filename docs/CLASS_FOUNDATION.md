# Klassenfundament und Good Old Molar

Stand: **05.11.2026**, erster Umsetzungsschnitt des
[Klassen-/Synergieplans](CLASSES_AND_SYNERGIES_IMPLEMENTATION_PLAN.md).

**Good Old Molar** ist als Standardprofil eingebunden. Vorbereitung und
Build-Menü nennen die Klasse. Freie reguläre Waffenwahl, sechs Standardwurzeln,
Grundstats und normale Dashwerte bleiben erhalten. Explizite Wurzelparameter
für Challenges und alte Saves bleiben nutzbar.

Weitere sichtbare Klassen, neue Synergie-Items und der Skilltree folgen in den
nächsten Schnitten. Die bestehenden Level-up-Karten bleiben hier erhalten.

## Gemeinsame Datenbasis

- `data/classes/good_old_molar.tres`: ausgeliefertes Standardprofil.
- `PlayerClassData`: ID/Regelversion, additive Startbeiträge, Wurzeln,
  Attributregeln, gerichtete Statumrechnungen, Waffenrollen, bevorzugte Item-Tags
  und optional eigene Dashkonfiguration.
- `ClassStatRuleData`: getrennte Faktoren für positive/negative Beiträge und
  wirksame Minima/Maxima in den normalen Attributeinheiten.
- `ClassStatConversionData`: Beitrag eines wirksamen Quellattributs zu einem
  Zielattribut. Zirkuläre Umrechnungen sind ungültig.
- `ClassCatalog`: gemeinsame Profilauflösung für Vorbereitung und Spielstand.
  Diagnoseprofile des Tests werden nicht als spielbare Klassen ausgeliefert.

Das Profil wird einmal vor Runstart angewandt. Laden vergibt keine erneuten
Startbeiträge. Die Klasse bleibt während des Runs fest. Der Vorbereitungsentwurf
speichert ihre ID; `RunSetup.select_class()` aktualisiert Wurzeln und verwirft
eine nicht mehr zulässige Startwaffe.

## Rohbeiträge und wirksame Werte

`PlayerStats` bleibt die gemeinsame Statquelle. Bestehende Leser erhalten über
dieselben Attribute den durch die Klasse begrenzten Wert. `raw_stat()` stellt
den gespeicherten Beitrag bereit. Verbesserungen addieren zum Rohwert, nicht zum
bereits begrenzten Ergebnis.

Beispiel der Diagnoseklasse: Ein Rüstungsgewinn von 5 mit Faktor 2 ergibt 10 rohe
Härte. Bei Klassenmaximum 5 sind 5 wirksam. Ein anschließender Nachteil von 7 mit
Faktor 1 lässt 3 rohe und wirksame Härte übrig. Eine daraus abgeleitete
Nahschadenswirkung verwendet die wirksamen 3 Punkte.

Vorschau, Käufe und Kampf verwenden dieselbe Berechnung. Temporäre Tempo- und
Schadensboni beachten ebenfalls die Klassenregel, ohne permanente Werte zu
verändern. Normale Treffer ohne Sonderprofil erzeugen keine Vorschaukopie pro
Angriff. Die neutrale Erwerbsbegrenzung von Glück und Grund-Glanz bleibt erhalten,
solange keine entsprechende explizite Klassenregel gesetzt ist.

Attributgrenzen beziehen sich auf den jeweiligen Spielerstat. Ein Glanzlimit
verändert beispielsweise nicht automatisch garantierte Krits einer Waffe.
Die Ausweichgrenze ist direkt die wirksame Ausweichchance und kann vom Profil
gegenüber den normalen 60 % verändert werden, innerhalb 0–100 %.

Ein begrenzter HP-Kauf heilt nur den tatsächlich hinzugewonnenen Lebensraum.
Vorschauen ändern weder HP noch Dashladung. Verbesserungen ohne wirksamen Nutzen
werden nicht angeboten. Bei weniger als vier sinnvollen Angeboten zeigt die
Belohnungsansicht die verfügbaren; ein vollständig begrenztes Profil blockiert
die Queue nicht. Das Level bleibt verdient, ohne zusätzliche Ersatzbelohnung.

## Waffenfreigabe unabhängig von Kapazität

Alle 18 Standardwaffen und sechs Evolutionen besitzen geprüfte Rollen:

- `contact`: kurze Kontaktwaffen und Wurzelkanalbrecher.
- `reach`: Peitsche, lange Fadenwaffen, Speer und Schicksalsfaden.
- `ranged`: Fernangriffe einschließlich Strahlen und Kegel.

Die Rollen sind unabhängig vom Schadensstat. Die lange Zahnseiden-Schneide wird
deshalb nicht zur kurzen Kontaktwaffe, nur weil sie mit Nahschaden skaliert.

`WeaponEligibility` und `WeaponLoadout.weapon_allowed()` prüfen die
Klassenzulassung. `can_acquire()` prüft zusätzlich Wurzeln oder Fusionskauf.
Startwahl, Shop einschließlich Kapazitäts-Fallback, Kauf, Fusion und Evolution
verwenden diese Regeln. Eine direkte Wiederherstellung mit verbotenen Waffen
wird vor dem Entfernen vorhandener Ausrüstung abgewiesen.

## Speicherung und Kompatibilität

Die bisherige numerische Statsektion bleibt erhalten. Daneben speichert
`player.class_state` ID, Regelversion und vollständige Rohwerte. `RunSnapshot`
stellt das Profil vor Ausrüstung und Dashzustand wieder her. Items werden nicht
nochmals auf gespeicherte Stats aufaddiert.

Alte Saves ohne Klassenmetadaten werden als Good Old Molar mit bisherigen
Gesamtstats und Wurzeln geladen. Unbekannte Klassen, nicht unterstützte
Regelversionen, ungültige Rohwerte und verbotene gespeicherte Waffen werden vor
einer Veränderung des laufenden Spiels abgewiesen. Keine stille Klassenumwandlung
oder Löschung ihrer Ausrüstung.

Die Combat-Telemetrie erfasst Klassen-ID und Regelversion im Startbuild der
Welle. Der vorhandene post-wave Ablauf bleibt erhalten.

## Prüfung

`tests/player_classes.gd` prüft Limits, Zugewinn/Nachteil, Umrechnung, temporäre
Boni, HP-Heilung, Dashkonfiguration, Waffenrollen, Fusionskauf bei vollen Wurzeln,
Shop-Fallback, verbotene Evolution, Vorschau, begrenzte Belohnungspools und einen
echten Szenen-Neustart mit gespeichertem Klassenprofil.

- Vollständiger Kernlauf: **179/179**, 299,83 s;
  `.godot/test_runs/20261105-115549-7ac71d7e`.
- Nach Lifecycle-/Vorschaukorrekturen: **4/4** gezielte Prüfungen;
  `.godot/test_runs/20261105-120214-2535220f`.
- Erweiterte Telemetrie, Debug-Menü und Stat-Icons: **3/3**;
  `.godot/test_runs/20261105-120306-f2ad44b5`.
- Nach Ergänzung ausdrücklich höherer Klassengrenzen für Ausweichen:
  **6/6** für Klasse, Ausweichen, Upgradevorschau, Statbalance, Attributanzeige und
  native Menüeingaben; `.godot/test_runs/20261105-120450-1ba776fb`.

Native Aufnahmen im tatsächlichen Godot-Renderer:
[Vorbereitung Desktop](screenshots/class_foundation/class_setup_1280x720.png),
[Vorbereitung Mobil](screenshots/class_foundation/class_setup_320x568.png),
[Build-Menü Mobil](screenshots/class_foundation/class_build_mobile.png).

Nächster Inhaltsschnitt: das unabhängig von Spezialklassen spielbare Giftpaket.
