# Builds und Releases auf GitHub

GitHub Actions baut die spielbaren Pakete. Lokal ist keine Exportumgebung nötig.
Die erste Stufe umfasst Builds, Downloads, Release-Entwürfe und die Trennung von
Test- und stabiler Webversion. `release.json` bildet die Grundlage für eine
spätere Updateprüfung. Ein Updatebutton oder automatischer Installer im Spiel
ist in dieser Stufe noch nicht enthalten.

## Ablauf

| Auslöser | Ergebnis |
| --- | --- |
| Pull Request nach `main` | Tests, Web- und Windows-Releaseexport, herunterladbares Actions-Artefakt; keine Veröffentlichung |
| Push auf `main` | Dieselben Prüfungen und Pakete; Testversion auf `/dev/` |
| Tag `vX.Y.Z` | Geprüfte Pakete und GitHub-Release-Entwurf; stabile Website bleibt unverändert |
| Tag `vX.Y.Z-beta.N` | Release-Entwurf als Vorabversion; stabile Website bleibt unverändert |
| Stabiles Release veröffentlichen | Veröffentlichte Webdateien werden am bisherigen Spiellink bereitgestellt; `/dev/` bleibt separat |

[Build-Workflow](../.github/workflows/build.yml) ·
[Veröffentlichungs-Workflow](../.github/workflows/publish-release.yml) ·
[Actions](https://github.com/othaldo/denti/actions) ·
[Releases](https://github.com/othaldo/denti/releases)

Der bisherige Spiellink ist `https://othaldo.github.io/denti/`.
Die Testversion liegt unter `https://othaldo.github.io/denti/dev/`.
**Solange noch kein stabiles GitHub Release veröffentlicht wurde, zeigen beide
Adressen den aktuellen Testbuild.** Danach bleibt der Hauptlink auf der neuesten
stabilen Veröffentlichung, auch wenn `main` weiterentwickelt wird.

## Downloadpakete

Jeder erfolgreiche Build erzeugt:

- `Denti-VERSION-windows-x86_64.zip`: `Denti.exe`, `Denti.pck` und Versionsdaten.
  ZIP vollständig entpacken und `Denti.exe` starten. Portable, ohne Installer.
- `Denti-VERSION-web.zip`: vollständiger Godot-Webexport, direkt mit `index.html`
  im Archivstamm. Für einen Webserver bestimmt.
- `release.json`: Version, Kanal, vollständiger Commit, Tag, Speicherformatversion,
  Plattformen, Downloadadressen, Dateigrößen und SHA-256-Prüfsummen.
- `SHA256SUMS.txt`: Prüfsummen der Archive und des Manifests.

Die Spielversion und der kurze Commit werden ins Hauptmenü übernommen. Die
Windows-Dateiversion bleibt numerisch, auch wenn die Spielversion etwa
`0.6.0-beta.1` oder `0.6.0-dev.42` heißt. Der normale Spielstand liegt weiterhin
in Godots `user://` außerhalb des entpackten Spielordners.

Testpakete sind in einem Actions-Lauf unter **Artifacts → denti-…** erhältlich
und werden 14 Tage aufbewahrt. Dafür ist eine GitHub-Anmeldung erforderlich.
Veröffentlichte Release-Dateien sind die dauerhaften Downloadadressen.
Testlogs bleiben sieben Tage erhalten.

Entwicklungsscreenshots, Dokumentation, Tests und Vorschauwerkzeuge bleiben aus
beiden Spielepaketen ausgeschlossen.

## Ein Release erstellen

1. Gewünschten Stand auf `main` prüfen. Basisversion in
   `project.godot` (`application/config/version`) setzen und Patchnotes pflegen.
2. Einen passenden Tag pushen, zum Beispiel `v0.6.0` zur Projektversion `0.6.0`
   oder `v0.6.0-beta.1` zur Basisversion `0.6.0`.
3. GitHub Actions führt zuerst Python- und Godot-Tests aus und exportiert danach
   Web und Windows. Erst bei Erfolg entsteht der Release-Entwurf mit beiden
   Paketen, Manifest, Prüfsummen und automatisch erzeugten Release Notes.
4. Den Entwurf auf GitHub prüfen, Notes fertigstellen und **Publish release**
   verwenden. Eine als Vorabversion markierte Veröffentlichung ersetzt die
   stabile Website nicht.

Tag und Basisversion müssen übereinstimmen; ein Tippfehler erstellt keinen
falsch bezeichneten Download. Bereits veröffentlichte Releases werden durch
erneutes Ausführen der Buildpipeline nicht überschrieben. Ein unveröffentlichter
Entwurf kann nach einem fehlgeschlagenen Lauf aktualisiert werden.

Die Veröffentlichung stößt den Pages-Workflow auf `main` an. Damit funktioniert
auch die bestehende GitHub-Pages-Umgebung mit einer auf `main` beschränkten
Deploymentregel; die Regeln müssen nicht für alle Versionstags geöffnet werden.
Ein manuelles **Run workflow** für „Publish stable Denti Web“ auf `main` stellt
die aktuelle stabile Veröffentlichung erneut bereit.

## Pages und Wiederherstellung

Jede Bereitstellung setzt eine neue komplette Website aus zwei geprüften
Archiven zusammen. Es werden keine alten Exportdateien über neue Dateien
kopiert. Das stabile Webpaket kommt aus dem neuesten veröffentlichten stabilen
Release, der Dev-Build aus dem aktuellen Lauf beziehungsweise dem letzten
erfolgreichen `main`-Build.

Version und Commit im Webarchiv müssen zum Manifest passen, ebenso Prüfsumme
und Dateigröße. Defekte Downloads, falsche Kanäle und ungültige Archivpfade
brechen die Bereitstellung ab. Die zuletzt bereitgestellte Website bleibt dann
aktiv. Abgelaufene Testartefakte verhindern kein stabiles Deployment; `/dev/`
zeigt in diesem Fall einen kurzen Link zur stabilen Version. Der nächste
erfolgreiche `main`-Build stellt dort wieder die Testversion bereit.

GitHub Pages wird wie bisher über Actions bereitgestellt. Die Workflows nutzen
den eingebauten `GITHUB_TOKEN`; zusätzliche Zugangsschlüssel oder ein eigener
Downloadserver sind nicht nötig. Das Paket ist derzeit nicht codesigniert.

## Prüfung und nächste Stufe

`python -m unittest discover -s tools/tests -v` prüft unter anderem Versions-Tags,
Windows-Versionsdaten, lauffähige Archivstruktur, fehlende Exporte, Prüfsummen,
beschädigte Pakete, erste Veröffentlichung, getrennte Webkanäle und abgelaufene
Testartefakte. Die vorhandene Godot-Suite bleibt Teil jedes Builds.

Die nächste Stufe liest das veröffentlichte `release.json` im Spiel: verfügbare
Version erkennen, stabile und Beta-Kanäle unterscheiden und einen passenden
Download anbieten. Anschließend kann ein separater Updater Downloads prüfen
und nach dem Beenden installieren. Spielstände, Migrationen und Wiederherstellung
gehören zu dieser Installationsstufe; während eines Runs wird kein Austausch
erzwungen.
