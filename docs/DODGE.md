# Zahnflutsch – Ausweichen

Denti startet mit **0 % Zahnflutsch**. Level-ups, Items und Mythic erhöhen dieselbe additive Ausweichchance. Angezeigt und gewürfelt wird eine Chance zwischen **0 und 60 %**. Der rohe Bonus bleibt gespeichert: 80 % Bonus minus 30 % ergibt 50 %, obwohl vorher effektiv nur 60 % galten.

Bei einem eingehenden Kontakt-, Projektil- oder Flächentreffer gilt: laufender Trefferschutz → Ausweichwurf → Schild → Härte → HP-Schaden. Ein erfolgreiches Ausweichen bewahrt Schildladungen, verhindert Schaden und löst keinen Verletzungs-/Vergeltungseffekt aus. Denti zwinkert, erscheint kurz türkis und zeigt „Zahnflutsch!“. Für 0,15 Sekunden sind weitere Treffer ausgeschlossen; dadurch erzeugt ein dichtes Projektilpaket nicht mehrfach im selben Frame Heilung oder Schilde. Diese Chance ist zufällig und ersetzt keine Bewegung.

`PlayerStats.take_damage(amount, false)` erlaubt ausdrücklich nicht ausweichbare direkte Treffer. Laufendes Gift und Blutung verwenden den eigenen Pfad `take_status_damage`: Er umgeht auch Schildladungen und Treffer-Unverwundbarkeit. Die Gesichter zeigen jetzt diese tatsächlichen Zustände an. [Effekte, Gegner und Schwierigkeit](PLAYER_STATUS_EFFECTS.md).

## Items

| Seltenheit | Item | Effekt | Basispreis |
| --- | --- | --- | ---: |
| Common | Gleitwachs | +4 % Zahnflutsch, −1 Härte | 5 |
| Uncommon | Seidenwurzel | +7 % Zahnflutsch, +3 % Bewegung, −8 Schmelz | 9 |
| Rare | Flutschspülung | +10 % Zahnflutsch, −1 Speichel; Ausweichen heilt 1 HP je Exemplar, max. 4, gemeinsam alle 1,5 s | 15 |
| Legendary | Lotusschmelz | +13 % Zahnflutsch, −2 Härte; jedes dritte Ausweichen gibt eine Schildladung, max. 5, gemeinsam alle 8 s | 24 |
| Mythic | Unfassbare Wurzel | Einmalig +15 % Zahnflutsch, ohne Nachteil oder Proc | 38 |

Die vier normalen Varianten teilen **Familienlimit 4**; Mythic ist davon unabhängig. Während der Schild-Abklingzeit sammeln weitere Ausweichereignisse keinen Fortschritt. Zusätzliche Lotusschmelz-Exemplare erhöhen die Chance, nicht Schildmenge oder Auslösefrequenz. Flutschspülung darf überheilen und verbindet sich mit Speichelkelch; Lotusschmelz bewahrt und erzeugt Ladungen für Schildsplitter und Schildrelikt. Härte-/HP-Nachteile machen fehlgeschlagene Ausweichwürfe gefährlicher. Bewegung harmoniert mit Lauf-Builds und hilft gegen Projektilmuster.

Zahnflutsch erscheint in Shop, Pause/Stats, Level-up und F4. Level-up-Stufen gewähren **+3 / +6 / +9 / +12 %**. F3 und JSON-Telemetrie zählen tatsächliche Ausweichereignisse pro Welle und Run. Spielstände bewahren Chance, verbleibenden Ausweichschutz, Item-Abklingzeiten und Schildfortschritt; ältere Spielstände erhalten 0 % ohne Änderung ihrer bisherigen Werte.

## Grafik und Prüfung

Fünf Itemicons und ein Attributicon wurden gemeinsam im Stil der bestehenden bemalten Atlanten erzeugt. `item_icons_dodge_packed.png` enthält sechs gepolsterte 512-Pixel-Zellen (3 × 2). Item-Indizes 86–90, Stat-Index 10. Original und Prompts bleiben erhalten.

`tests/dodge.gd` prüft reproduzierbare echte Trefferwürfe, die Obergrenze, negative Boni, Schildreihenfolge, Gesicht/Schutz, Heilung, Stackgrenzen, Proc-Cooldowns, Save/Resume, Shopkäufe und Level-up-Einheiten. Die Werte sind eine erste Balance für Playtests.

[Icons in 96 und 48 px](screenshots/dodge_icons.png), [Desktop-Shop](screenshots/dodge_shop_desktop.png), [Handy-Shop](screenshots/dodge_shop_mobile.png), [Handy-Stats im Shop](screenshots/dodge_shop_mobile_stats.png), [Handy-Level-up](screenshots/dodge_levelup_mobile.png). UI-Aufnahmen erstellt `tools/preview_dodge.gd` mit getrenntem Spielstand.
