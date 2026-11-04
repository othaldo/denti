# Dead Code und Duplikate

Stand: 4. November 2026. Ausgangspunkt: `b3c0b2d`.

## Bereinigung

Die Referenzprüfung umfasst die 290 GDScript-Dateien unter `scripts/` sowie
Szenen, Ressourcen, Projektkonfiguration, Tests und Werkzeuge. Statische
Nichtverwendung wurde vor dem Entfernen am jeweiligen Aufrufpfad geprüft.
Das ist kein vollständiger Beweis für die Erreichbarkeit jedes Codezweigs.

- 18 unaufgerufene Methoden entfernt: fünf alte Layout-Schnittstellen in
  `UpgradeCard` und `RewardCard`, außerdem `blend_sample`, `in_rect`,
  `hud_text`, `breadcrumb`, `next_wave_preview`, `quick_text`, `unmanaged`
  und der Rasterhelfer `CombatSpriteTextures._line`.
- Unbenutzte `hover_tween`-Felder und `DentiUIStyle.VIOLET` entfernt.
- Die ausschließlich durch die entfernten Layout-Methoden aktivierbaren
  Wiederherstellungszweige und `chest_row`/`chest_layout` entfernt.
  `affix_header` gehört jetzt unmittelbar zu `RewardCard`.
  Die Chest-Tests prüfen weiter sichtbare Inhalte, Fokus und Geometrie,
  statt zusätzlich einen dauerhaft falschen internen Schalter abzufragen.

## Zusammengefasste Implementierungen

`DentiUIComponents.wrap_text` ersetzt vier Implementierungen des expliziten
Textumbruchs für Rewards, Waffenwahl, Achievements und deren Hinweiskarte.
Auch das Waffenkapsel-Panel verwendet den öffentlichen Helfer, statt die
private Methode der ersten Belohnungskarte aufzurufen. Font, Umbruchregeln
und die besondere Leerzeilenbehandlung der Waffenwahl bleiben erhalten.
Der bestehende Achievement-UI-Test prüft zusätzlich lange deutsche Wörter,
Breitenwechsel, Leerzeilen, leere Texte und unterschiedliche Schriftgrößen.

`SnapshotValues.is_number` und `is_vector` ersetzen identische Prüfungen in
den König-/Imperator-Snapshots. Sie werden auch von sieben abhängigen
Gegner-/Boss-Systemen verwendet. Dadurch entfallen deren Zugriffe auf private
Methoden anderer Encounter-Snapshots. Akzeptiert werden weiterhin ausschließlich
endliche Zahlen beziehungsweise Arrays aus genau zwei endlichen Zahlen.
Save-Format, Migration und tolerantes `read_vector` bleiben unverändert.
`run_storage` prüft gültige Werte und ungültige Typen einschließlich Bool,
Strings, falscher Arraylängen, NaN und Unendlichkeit.

## Weitere Refactoring-Kandidaten

| Bereich | Wiederholung | Sinnvoller nächster Schritt |
| --- | --- | --- |
| Boss-Rigs | `KingAcidRig`, `EmperorCourtRig` und `PrinceCaramelRig` bauen ähnliche Bones und Sprite-Teile auf. | Kleine gemeinsame Fabrik für Bones und Sprite-Teile; jeweilige Hierarchie, Shader und Animationen bei den Rigs belassen. |
| Boss-Art | `KingAcidArt`, `PrinceCaramelArt` und `EmperorCourtArt` erzeugen und cachen Atlaszellen nahezu identisch. | Gemeinsamer Atlas-Helfer mit explizitem Besitz des Caches; Zuschnitt und Texturidentität durch vorhandene Rig-Tests prüfen. |
| UI-Layout | `DentiDentikon` und `RunSetupDetails` formen ebenfalls Textabsätze, verwenden aber andere Umbruch- beziehungsweise Messregeln. | Bei einer gezielten Layoutänderung an den gemeinsamen Helfer anbinden; Unterschiede vorher durch Beispiele absichern. |

Die Suche nach identischen Blöcken von zehn nichtleeren, nicht kommentierten
Zeilen zeigt vor allem kleine Helfer, Diagnose-Wrapper und generierten Code.
Sie misst keine semantischen Duplikate und liefert keine allgemeine
Duplikationsquote. Es gibt keinen Anlass für einen flächendeckenden Umbau.

`profiled_*` wird dynamisch von `CombatDiagnostics.instrument` geladen.
Generierte Atlasdaten dienen auch Bake- und Pixeltests. Beides ist weiterhin
in Verwendung. Die getrennten normalen/zentralen Gegner-Bewegungspfade bleiben
wegen ihrer gemessenen Performance und des bestehenden Referenztests erhalten.

## Prüfung

- Godot-4.7.2-Import ohne Skriptfehler; `git diff --check` ohne Befund.
- 33/33 gezielte Tests bestanden, einschließlich der erweiterten Rig-Prüfung:
  zwei Läufe mit 14 Tests in 35,87 s und 19 Tests in 54,17 s.
  Berichte: `.godot/test_runs/20261104-140138-15fb04e3/results.json` und
  `.godot/test_runs/20261104-140249-956ba81f/results.json`.
- Native Reward-Vorschau in 1280×720 und 360×640 erzeugt; ausgewählte
  Level-up-, Item- und Kapselaufnahmen visuell geprüft. Text und Karten bleiben
  lesbar, größere Inhalte scrollen innerhalb ihres vorgesehenen Bereichs.
  Bilder liegen unter `.godot/cleanup_reward_preview/`; der Vorschau-Log
  enthält keine Skript-/Engine-Fehler oder Leak-Meldungen.

Anschließende vollständige Regression vor dem Push:

- **199/199 Godot-Tests bestanden**, Kern- und erweiterte Suite mit vier
  Workern und 300 Sekunden Timeout pro Test, insgesamt 519,84 Sekunden.
  Bericht: `.godot/test_runs/20261104-140548-f4b1f072/results.json`.
- **50/50 Python-Tests bestanden** (`python -m unittest discover -s tools/tests -v`),
  insgesamt 11,53 Sekunden. Log: `.godot/cleanup-python-tests.log`.
