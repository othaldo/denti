# Einheitliche Bodenwarnungen

Stand: 31.10.2026. Im Spiel aktiv.

Alle gegnerischen Bodenwarnungen verwenden jetzt dieselbe analytische Darstellung: klare, dauerhaft sichtbare Kontur, leichte transparente Grundfläche, beschleunigte Füllung, wandernde Lichtbänder und ein später Helligkeitsanstieg. Die Farbgebung bleibt pro Angriff frei. Die Quelle besitzt bei Bedarf einen Timerbogen mit leerer Mitte.

[Vorschau aller Formen](screenshots/neon_charge/unified_shapes.png) · [Animation](screenshots/neon_charge/unified_shapes.mp4) · [Überlagerungen im Spiel](screenshots/neon_charge/unified_ingame.png) · [Messdaten](unified_telegraph_measurements.json).

## Anbindung

| Form | Verwendung |
| --- | --- |
| Kreis | Impuls-/Explosionsradius, Prinzenbombe, aktive Karamellpfützen |
| Ring mit sicherer Mitte | Graf: Rundumschlag |
| Sektor, einschließlich beliebiger großer Winkel | Graf: Fächer/Stich; Kaiser: Edikte |
| Rechteckige Bahn | Dash/Charge, Geschosswände, Portal-Lanze |
| Kapsel mit runden Enden | König: Säurekanäle und Trittlinien; dieselbe Geometrie wie die Kollisionsprüfung |
| Rechteck | Kissenboss: Aufschlag und Faltkorridor, auch senkrecht |
| Dünne Bahn / Timerbogen | Zielstrahlen, Fächer- und Radialansagen, verbleibende Quelltimer |

WarningEffects ist die gemeinsame Schnittstelle. AttackEffects.lane, .danger und .warning_ring delegieren dorthin. Die vorher separaten Warnwege in den Boss-Zeichnern sind umgestellt. Gemalte Bossobjekte wie Bomben, Kissen und Säure bleiben als zusätzliche Motive erhalten. Spielerwaffen, Projektilgrafiken, Statussymbole und dekorative Auren sind eigene Effekte und werden nicht als Bodenwarnungen behandelt. Die Körperinszenierung der Charge-Studie bleibt eine separate Studie.

Warnbahnen erhalten keine zusätzlichen Endkreise oder runden Endblitze. Das gilt für Zucker- und Boss-Charges, Raumkugel-Warnungen einschließlich Bossmustern sowie die Endpunkte der Säurekanäle. Eigenständige Kreisangriffe und Quelltimer behalten ihre jeweilige Form.

## Zeit und Treffergrenzen

- Sämtliche flächigen Warnungen verwenden t^2.2 für die Lichtfront. Der Timerbogen zeigt die verbleibende Warnzeit direkt; er ist keine zusätzliche Trefferfläche.
- Die komplette Treffergrenze ist von Beginn an sichtbar. Die Lichtfront verändert keine Kollisionsform und verzögert keinen Angriff.
- Radien, Ringinnenradius, Winkel, Endpunkte und Ausrichtung stammen aus den vorhandenen Angriffsdaten. Sektoren und Ringe benötigen keine fest eingebrannten Profilmaße mehr.
- Zielbindung und Weltraumposition bleiben erhalten, auch wenn sich der Boss weiterbewegt. Rechteckfüllungen folgen bei senkrechten Kissenangriffen der Bewegungsrichtung.
- Kein Shader-TIME: Pausen und gespeicherter Angriffszustand bestimmen die Darstellung. Ein leerer Neuzeichnungsdurchlauf entfernt veraltete Warnungen.
- Bei dichten Bahnen wird die Füllung konservativ anhand des kleinsten vorhandenen Dichtewertes der ganzen Bahn reduziert. Kontur und Lichtfront bleiben sichtbar. Die bisherige abschnittsweise Atlas-Abschwächung wurde durch diese gleichmäßige, ruhigere Füllung ersetzt.

## Rendering

TelegraphBatch verwendet pro zeichnendem Besitzer zwei MultiMeshes: Füllungen hinter dem Besitzer, Konturen davor. Mesh und beide Materialien werden über alle Besitzer geteilt; Instanzpuffer werden wiederverwendet und bei Bedarf verdoppelt. Die internen Renderkinder erscheinen nicht in den normalen Gegnerlisten. Der normale Gegner-Warnpass sammelt seine Anzeigen gemeinsam.

Der Shader berechnet Konturen pro Ausgabepixel und glättet mit Bildschirmableitungen. Kleine Timerstufen und hochskalierte 64-Pixel-Masken sind in diesem Pfad entfallen. Es gibt keinen Vollbild-Bloom, Bildschirmkopien, Partikelschwärme oder neue Texturen pro Warnung. Sektoren verwenden einen auf ihren Winkel begrenzten Zeichenbereich.

Die Messung vergleicht dieselben gemischten Charge-/Ring-/Sektor-/Timer-/Bahn-Fälle mit dem erhaltenen vorherigen Atlasrenderer, inklusive der zuvor eingebauten Timer-/Charge-Glättung. VSync aus, 80 Aufwärmframes, 200 Messframes, Reihenfolge Atlas/Neu/Neu/Atlas. Alle Werte umfassen die isolierte Szene samt Boden. Es sind keine vollständigen Spiel-FPS und keine isolierten GPU-Zeiten. Browser und Mobilgeräte wurden nicht gemessen.

NVIDIA GeForce RTX 4070, Godot 4.7.2 Compatibility. Mittelwerte der beiden Wiederholungen:

| Ausgabe | Warnungen | Vorher | Einheitlich | Zeichenaufrufe vorher / neu |
| --- | ---: | ---: | ---: | ---: |
| (1280, 720) | 1 | 0.426 ms | 0.351 ms | 7 / 8 |
| (1280, 720) | 20 | 0.450 ms | 0.515 ms | 14 / 8 |
| (1280, 720) | 60 | 0.610 ms | 0.676 ms | 30 / 8 |
| (2560, 1440) | 1 | 0.331 ms | 0.343 ms | 7 / 8 |
| (2560, 1440) | 20 | 0.411 ms | 0.465 ms | 14 / 8 |
| (2560, 1440) | 60 | 0.548 ms | 0.919 ms | 30 / 8 |

Bei 60 gemischten Warnungen in 1440p steigt die isolierte Framezeit um rund 0,37 ms. Es gibt acht Szenen-Zeichenaufrufe statt dreißig; sechs davon gehören zum Boden. Die neue Darstellung ist somit nicht kostenlos, bleibt auf diesem Rechner im gemessenen Extremfall unter 1 ms mittlerer Framezeit. Das ersetzt keine Prüfung schwächerer Zielgeräte.

## Verifikation

- 15 gezielte automatisierte Tests einschließlich Warngeometrie, Batch-Wachstum, gemeinsam genutzter Ressourcen, Dichte, Zielbindung, Pause, Speicherstand und aller Bossabläufe; außerdem Shader-Warmup.
- Regressionstest für Zucker-/Boss-Charges, Raumkugel- und Geschossbahnen sowie Bossvoranzeigen, jeweils in lokaler und gemeinsamer Darstellung: keine zusätzlichen Endkreise. Auch mit nativem Renderer bestanden.
- Native Pixelprüfung: Kreisgrenze, beide Ringgrenzen und freie Mitte, schmale/breite Sektoren, Kapselenden/-seiten, senkrechte Rechtecke, Timerbeginn oben im Uhrzeigersinn.
- Native Prüfung: eingefrorene Anzeige bleibt pixelgleich, leeres Neuzeichnen löscht sie, lokale/gemeinsame Transformationen stimmen bei Rotation, Scherung und ungleichmäßiger Skalierung überein.
- Native Bossansichten und tatsächliches Spielfeld mit bis zu 20 Warnungen, 40 Gegnergeschossen und 24 Spielerprojektilen visuell geprüft.

## Reproduzieren

Mit isoliertem APPDATA unter .godot und dem Godot-Binary aus README:

~~~powershell
godot --path . --script tools/preview_unified_telegraphs.gd -- --video
godot --path . --script tools/verify_telegraphs.gd
godot --path . --script tools/benchmark_unified_telegraphs.gd
~~~

Die beiden nativen Prüfwerkzeuge benötigen einen echten Renderer. Der Headless-Test warning_effects prüft Daten, Ressourcenwiederverwendung und Batch-Verhalten. Der alte Qualitätsvergleich bleibt über tools/support/legacy_warning_effects.gd reproduzierbar.
