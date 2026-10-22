# Builds und Releases auf GitHub

GitHub Actions baut die spielbaren Pakete. Lokal ist keine Exportumgebung nötig.
Die Pipeline umfasst Builds, Downloads, Release-Entwürfe und die Trennung von
Test- und stabiler Webversion. Portable Windows-Builds können veröffentlichte
Updates direkt im Hauptmenü laden und nach einem bewussten Neustart installieren.

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

## Updater im Windows-Spiel

Im Hauptmenü führt **Updates** zur installierten Version, Kanalwahl und einer
einzigen Aktion. Eine verfügbare Version hebt den Menüeintrag dezent hervor.
Der automatische Check läuft beim ersten Menübesuch, danach höchstens alle sechs
Stunden innerhalb derselben Sitzung. **Erneut prüfen** übergeht dieses Intervall.
Ohne Netzwerk oder bei GitHub-Limits bleibt das Spiel vollständig nutzbar.

- **Stable** berücksichtigt nur veröffentlichte stabile Releases.
- **Beta** berücksichtigt auch Vorabversionen; die höchste semantische Version
  gewinnt, unabhängig von Veröffentlichungsreihenfolge oder alphabetischer Sortierung.
- Es gibt keine automatischen Downgrades. Ein Entwicklungsbuild kann zur stabilen
  Veröffentlichung derselben Basisversion wechseln. GitHub-Actions-Artefakte sind
  keine Updatequelle; bis zur ersten Veröffentlichung gibt es keine Updates.
- Editor, Browser, Linux und umbenannte Windows-EXEs aktivieren den Windows-Updater
  nicht. Im Browser aktualisiert weiterhin das Webdeployment die Spielversion.

**Herunterladen** zeigt Fortschritt und lässt sich abbrechen. Verlassen der
Updateseite bricht einen laufenden Download ebenfalls ab. Das geprüfte Paket kann
vor der Installation liegenbleiben, während man weiterspielt. **Installieren & neu
starten** ist ausschließlich aus dem Hauptmenü erreichbar. Kämpfe und Pausenmenüs
werden nie für Updates unterbrochen.

### Prüfung, Austausch und Rückfall

Die Prüfung verbindet GitHub-Release, Versions-Tag, Repository, Kanal,
Speicherformat, Paketname, Downloadadresse, Dateigröße und SHA-256. Downloads
kommen ausschließlich aus `othaldo/denti` auf GitHub. Der Dateihash wird in
kleinen Abschnitten geprüft, damit das Menü weiter reagieren kann. Das ZIP darf
genau `Denti.exe`, `Denti.pck` und `build-info.json` enthalten; die Buildkennung
im Archiv muss zum Manifest passen.

Der eingebaute Helfer nutzt Windows PowerShell 5.1 und .NET Framework; Python,
ein zusätzlicher Installer und Administratorrechte sind nicht erforderlich.
Der Spielordner muss beschreibbar sein. Verknüpfte Installations-/Cacheordner
werden nicht automatisch verändert. Der Helfer prüft das Paket erneut, entpackt
in einen eigenen Ordner auf demselben Laufwerk und meldet erst dann Bereitschaft.
Er wartet auf das Ende des zugehörigen Denti-Prozesses und ersetzt die drei
Dateien einzeln atomar, mit vollständigen Rückfallkopien.

Die neue Version muss den erfolgreichen Aufbau ihres Hauptmenüs bestätigen.
Schlägt ein Austausch fehl oder kommt keine Startbestätigung, werden die alten
Dateien wiederhergestellt. Nach einem fehlgeschlagenen Neustart wird die alte
Version erneut gestartet. Ein Sperrgriff verhindert parallele Installationen.
Die wiederhergestellte Version zeigt den fehlgeschlagenen Versuch im Updatebereich;
ein Hintergrundcheck überschreibt diese Rückmeldung nicht.
Andere Dateien im Spielordner und sämtliche `user://`-Spielstände, Einstellungen
und Freischaltungen werden vom Helfer nicht verändert.

Nach Erfolg wird das Download-ZIP entfernt und genau eine vorherige Spielversion
als Rückfallkopie behalten. `.denti-updater.json` verweist auf deren Ordner
`.denti-update-…/backup`. Bei einem Stromausfall während des Austauschs bleiben
bereits gesicherte Dateien dort erhalten; man kann sie bei beendetem Spiel
zurückkopieren oder das komplette veröffentlichte ZIP erneut entpacken.
Ein fehlgeschlagener Rückfall löscht seine Sicherungen nicht.

Ändert eine zukünftige Version `RunStore.VERSION`, wird die automatische
Installation vorerst mit einem Hinweis auf das andere Speicherformat gesperrt.
Explizite Migrationen müssen implementiert und geprüft werden, bevor diese
Sperre für ein neues Speicherformat geöffnet wird.

Die erste Version mit diesem Updater muss einmal als vollständiges Windows-ZIP
installiert werden. Ältere Pakete erhalten die neue Funktion nicht nachträglich.

## Prüfung

`python -m unittest discover -s tools/tests -v` prüft unter anderem Versions-Tags,
Windows-Versionsdaten, lauffähige Archivstruktur, fehlende Exporte, Prüfsummen,
beschädigte Pakete, erste Veröffentlichung, getrennte Webkanäle und abgelaufene
Testartefakte. Ein separater Windows-CI-Job führt den tatsächlichen PowerShell-
Helfer gegen Wegwerf-Installationen aus: Austausch, gesperrte Datei, Rückfall,
Prüfsummenfehler, Pfadmanipulation und vollständige Prozessübergabe mit und ohne
Startbestätigung. Die vorhandene Godot-Suite prüft zusätzlich Kanalwahl,
Versionsordnung, Manifestprüfung, Archive und responsive Updateansichten.
Beide Testjobs müssen vor einem Release-Entwurf oder Webdeployment bestehen.

Native Ansichten: [Installation am Desktop](screenshots/updater/ready_1280x720.png)
und [Download in schmaler Ansicht](screenshots/updater/downloading_360x640.png).
