# Dentis Gesichtsausdrücke

Der Spielcharakter besteht nun aus einer Körperebene und einer transparenten Gesichtsebene. Die Gesichtsebene hängt unter dem bestehenden Körpersprite und übernimmt dessen Wippen, Rotation, Dehnung und Trefferfarbe. Das ursprüngliche `assets/denti/denti_unarmed.png` und die Referenzbilder bleiben unverändert. Die neue Körperebene erhält die Ausstattung des bisherigen Spielsprites.

## Reaktionen im Spiel

| Anlass | Ausdruck | Dauer / Regel |
| --- | --- | --- |
| Normalzustand | Freundliches Gesicht | Grundzustand |
| Blinzeln | Geschlossene Augen | 0,12 s, alle 2,8–6,2 s im normalen Grundzustand |
| Tatsächlich erlittener Schaden | Autsch-Gesicht | 0,45 s |
| Tatsächliche Heilung | Erleichtertes Lächeln | 0,65 s; höchstens alle 2,5 s |
| Wenig HP | Besorgtes Gesicht | Bei höchstens 25 % HP, solange kein anderer Ausdruck Vorrang hat |
| Schildblock | Selbstbewusstes Grinsen | 0,55 s; kein Schadensgesicht bei geblocktem Treffer |
| Erfolgreiches Ausweichen | Zwinkern | 0,45 s; ausgelöst durch Zahnflutsch |
| Erfolgreicher Wellenabschluss | Jubel | 1,2 s, zu Beginn der Beutesammlung |
| Tod | Geschlossene Augen und trauriger Mund | Sofort, auch wenn der Tod im selben Moment das Spiel pausiert |

Kleine Heilungen werden bis insgesamt 0,5 HP gesammelt, bevor der Ausdruck ausgelöst wird. Weitere Heilungen während der Abklingzeit verlängern ihn nicht. Überheilung ohne tatsächlich gewonnene HP spielt keine Heilungsreaktion. Das automatische Angreifen verwendet weiterhin den bestehenden Körperimpuls; es wechselt nicht bei jedem Schuss das Gesicht.

## Statusanzeige und Anschluss

Gift und Blutung sind **Anzeigen für zukünftige Spielzustände**. Diese Änderung fügt weder neue Schadensregeln noch solche Angriffe bei Gegnern hinzu. Die Anzeige kann bereits einzeln oder kombiniert aktiviert werden:

```gdscript
player.expressions.set_status(DentiExpressions.Status.POISON, true)
player.expressions.set_status(DentiExpressions.Status.BLEED, true, 5.0)
player.expressions.set_status(DentiExpressions.Status.POISON, false)
```

Eine Dauer von null bedeutet „bis zum expliziten Entfernen“. Positive Dauern laufen während unpausierter Spielzeit ab. Ein künftiges Statuseffektsystem kann die Anzeige mit seinen eigenen Zustandswechseln aktivieren und entfernen. Die Anzeige selbst verändert niemals HP, Rüstung, Schilde oder Unverwundbarkeit.

Vergiftet: müde Augen, welliger Mund, grüne Wangen und drei kleine grüne Bläschen neben dem Körper. Blutend: zusammengekniffene Augen, angespannter Mund, kleiner Wangenfleck und zwei kleine rote Tropfen. Beide Hinweise bleiben auch während eines kurzfristigen Treffer- oder Heilungsgesichts sichtbar. Für beide Zustände zusammen gibt es ein eigenes Gesicht. `show_dodge()` reagiert auf das tatsächliche Ausweichsignal von `PlayerStats`; die Mechanik ist unter [Zahnflutsch](DODGE.md) dokumentiert.

Tod hat Vorrang vor allen Reaktionen. Bei vorübergehenden Reaktionen gilt Treffer > Schildblock > Ausweichen > Heilung > Jubel. Danach erscheint wieder der anhaltende Zustand: Gift + Blutung, Gift, Blutung, wenig HP oder normal. Nur das normale Grundgesicht blinzelt zusätzlich. Anhaltende Anzeigen und deren Restdauer werden im Spielstand gespeichert; kurze Reaktionen starten beim Fortsetzen neu. Ältere Spielstände benötigen das neue Feld nicht.

## Dateien und Vorschau

- [Körperebene](../assets/denti/expressions/denti_body.png)
- [Gesichtsatlas mit zwölf Ausdrücken](../assets/denti/expressions/denti_faces.png)
- [Vorschau in Spielgröße und doppelt so groß](screenshots/denti_expressions.png)
- [Bewegte Vorschau mit echten Treffer-/Heilungsereignissen](screenshots/denti_reactions.gif)
- Verhalten: `scripts/player/denti_expressions.gd`
- Abstimmung: `data/player/denti_expressions.tres` / `DentiExpressionSettings`
- Prüfung: `tests/denti_expressions.gd`
- Vorschau erzeugen: `godot --path . --script res://tools/preview_denti_expressions.gd`
- Reaktionsdemo: `godot --path . --fixed-fps 30 --script res://tools/preview_denti_reactions.gd` (separater Vorschau-Spielstand)

Die Bilder wurden mit dem integrierten Imagegen-Werkzeug aus dem bestehenden Denti-Sprite abgeleitet. Die vollständigen Prompts liegen unter `docs/art/denti_body_prompt.txt`, `docs/art/denti_faces_prompt.txt` und `docs/art/denti_faces_cleanup_prompt.txt`. Gesichtspositionen werden je Atlasframe über einen gemeinsamen Mundanker registriert, damit unterschiedlich viel Leerraum um geschlossene Augen keinen Sprung im Gesicht verursacht.
