# Neon-Charge: isolierte Effektstudie

Aktueller Spielstand: [Einheitliche Bodenwarnungen für alle Formen](UNIFIED_TELEGRAPHS.md). Diese Datei beschreibt die separate Charge-Studie mit Körperanimation.

Stand: 30.10.2026. Die HTML-Testbank (Fassung 3) folgt der vom Nutzer bereitgestellten
`charge-telegraph.html`: dünne Kontur mit abgeschrägten Ecken, weicher Verlauf
zum Angreifer, transparente Füllung, helle Ladefront und laufende Chevrons.
Die Godot-Studie (Fassung 4) ergänzt nun Körperspannung, Streckung beim Start,
Kontakt-Schatten, gerichtete Lichtspur und Abfedern.

[Glättung der Ingame-Warnungen und Messwerte](WARNING_QUALITY.md).

[Interaktive HTML-Testbank](screenshots/neon_charge/charge-telegraph.html) ·
[Animierter Godot-Vergleich](screenshots/neon_charge/preview.gif) ·
[MP4](screenshots/neon_charge/preview.mp4) ·
[Späte Aufladung](screenshots/neon_charge/late.png).

## Mit dem Verlauf spielen

Die HTML-Datei ist eine eigenständige Kopie der Nutzerreferenz mit eingebettetem
Bodenbild. Sie lässt sich lokal im Browser öffnen; das Original in Downloads
bleibt unverändert. Alle vier Formen (Bahn, Kreis, Kegel, Ring), Farbauswahl,
Mischmodi und die bisherigen Look-Regler bleiben erhalten.

Neu sind drei Aufladekurven, ein Anzug-Regler und ein Zeitregler zum Pausieren
und Scrubben. Der Anzug gilt nur für „Beschleunigend“ und ist sonst deaktiviert.

| Verlauf | Füllung bei Zeitanteil t | Gefühl |
| --- | --- | --- |
| Linear | t | Gleichmäßiges Voranschreiten |
| Beschleunigend | t^k, k = 1–4 | Langsamer Aufbau, schneller Schluss |
| S-Kurve | t² × (3 − 2t) | Sanfter Anfang und Abschluss, schnelle Mitte |

Standard ist Beschleunigend mit k = 2,2: Nach 50 % der Warnzeit sind rund
22 % der Bahn gefüllt, nach 85 % rund 70 %. Die S-Kurve ist eine Alternative
mit gebremstem Ende, kein zusätzlicher Endspurt.

Die Freigabe erfolgt für jede Kurve bei 100 % **Zeit**. Das abschließende
Pulsieren folgt ebenfalls der Zeit und nicht der Füllung. Die Kurve ändert
weder Warnzeit noch Bewegungsdauer. Beide Werte für Zeit und Füllung sind
in der Testbank sichtbar. Eine geänderte Aufladedauer startet den Zyklus neu.

## Godot-Vergleich

In Godot `scenes/dev/neon_charge_preview.tscn` öffnen und die aktuelle Szene
starten. Oben läuft der bisherige HTML-inspirierte Look, unten die neue
Inszenierung. Beide verwenden dieselbe gewählte Kurve. Endpunkte, Breite,
Warnzeit und Losstürmen sind synchron; die zusätzliche Körperbewegung verändert
nur die Sprite-Darstellung, nicht die Position des Angriffs. Pause, Zeitlupe,
Neustart, Zeitregler, Kurvenwahl, Anzug und Dauer sind bedienbar.

Alternativ aus dem Checkout mit getrennten Benutzerdaten:

```powershell
$previousDentiAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path (Get-Location) '.godot/neon_charge_userdata'
    Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/dev/neon_charge_preview.tscn
} finally {
    $env:APPDATA = $previousDentiAppData
}
```

## Technische Grenze und Prüfung

Dies bleibt eine eigenständige visuelle Studie ohne Kampfkoordinator,
Treffer oder Wellen. Sie lädt und verändert keinen Spielstand. Die gemeinsam
verwendeten Bossabläufe werden durch diese Szene nicht umgestellt.
Vorschaumaße: 640 px Länge, 96 px Breite; voreingestellte Aufladedauer 2,2 s.
Diese Werte sind keine Änderung an Gegnerwerten. Die getrennte Verbesserung
der Kantenglättung ist dagegen bereits im gemeinsamen Ingame-Renderer aktiv;
siehe WARNING_QUALITY.md.

Der Godot-Shader zeichnet die Bahn in einem CanvasItem-Material im
Compatibility-Renderer, ohne globalen Bloom oder Bildschirmkopie.
Er nutzt Premultiplied Alpha; der Screen-Mischmodus der HTML-Referenz wird
visuell angenähert, nicht pixelgleich nachgerechnet. Die zusätzlichen Formen
bleiben vorerst in der HTML-Testbank. Die Godot-Studie zeigt die Charge-Bahn.

Zeit und Füllung sind separate Shader-Parameter. Die Animation verwendet kein
`TIME`; Pause und Scrubbing halten auch Chevrons und Pulsieren an. Der Boden
bleibt durchscheinend, Figuren liegen darüber.

Die native Aufnahme prüft Pause, Zeitlupe, Scrubbing, Kurvenwahl,
Anzug und Dauer sowie monotonen Fortschritt und den identischen
Freigabezeitpunkt aller Kurven. Browser-Prüfung: drei Kurven × vier Formen,
Bedienelemente, beide Look-Presets, Mischmodi und kein horizontaler Überlauf
bei 390 px Breite. Native Standbilder und die Browser-Darstellung wurden
visuell geprüft. Die neue Bodenanzeige wurde zusätzlich mit 1/20/60 Instanzen gemessen.
Die vollständige Inszenierung mit Figur ist noch keine Umstellung aller
Ingame-Charges. Automatische Capture-Prüfungen decken außerdem eingefrorene
Körperposen, das Ausblenden fertiger Spuren und den sauberen Neustart ab.

## Native Aufnahme erneuern

Mit dem isolierten Benutzerdatenverzeichnis:

```powershell
Godot_v4.7.2-stable_win64_console.exe --path . --fixed-fps 60 --script res://tools/capture_neon_charge.gd
```

Ein kompletter Zyklus liegt danach als 113 PNGs bei 30 fps unter
`.godot/neon_charge_preview/frames/`. `-- --stills-only` erzeugt frühe,
mittlere, späte Aufladung, Freigabe, Bewegung, Abfedern und eine S-Kurven-Ansicht. GIF und MP4
werden aus den nativen Frames erstellt.
