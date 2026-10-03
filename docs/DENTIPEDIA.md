# Dentipedia

Im Esc-Menü öffnet **Dentipedia** das Nachschlagewerk. Der Kampf bleibt pausiert. Die Suche filtert innerhalb des gewählten Bereichs.

- **Waffen:** alle 18 normalen Waffen mit Spielweise, Skalierung, Effekten und Basiswerten I–IV. Danach folgen die sechs Spezialwaffen.
- **Items:** vollständige Effekte und Stapel-/Familienlimits aus den aktuellen Ressourcen.
- **Relikte:** alle fünf Relikte und ihre Effekte.
- **Werte:** Attribute mit denselben Namen und Icons wie HUD und Shop.
- **Mechaniken:** Strom/Nass, Blutung, Krit/Fokus, Schmelzbruch, Geschosse/Flächen, Heilung/Schild/Ausweichen, Wurzeln/Fusion, Shop, Seltenheiten, Wellen/Belohnungen und Gegnerdruck.

Unentdeckte Spezialwaffen zeigen ihre schwarze Alpha-Silhouette, aber weder Namen noch Zutaten, Effekte oder Werte. Erst die erfolgreiche Fusion schaltet den vollständigen Eintrag mit Zutaten-Icons frei. Der Fortschritt bleibt über Runs, Verkäufe und Neustarts erhalten. Familienzutaten akzeptieren jede Seltenheit; der Eintrag nennt die passende Familie. Es gibt kein Fusionslimit pro Run.

`DentipediaData` baut die Einträge aus den Waffen-, Item-, Relikt- und Attributkatalogen. `Dentipedia` zeigt eine Liste mit Detailansicht; auf schmalen Hochformatbildschirmen stehen beide untereinander. Kleine Querformate behalten die Spalten, damit das Menü nicht aus dem Bild ragt.

`tests/dentipedia.gd` prüft Menü-Zugang, Vollständigkeit, Spoilerschutz auch in der Suche, Freischaltung durch echte Shop-Fusion, dauerhaften Fortschritt, Koexistenz mit Hell-Freischaltung, Silhouetten und drei Bildschirmgrößen. `-- --capture` erstellt Vorschauen unter `.godot/`.
