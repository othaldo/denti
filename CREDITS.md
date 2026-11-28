# Credits

## Schrift

**Fredoka** — The Fredoka Project Authors. Bezogen aus dem [Google-Fonts-Repository](https://github.com/google/fonts/tree/main/ofl/fredoka). Veröffentlicht unter der **SIL Open Font License 1.1**; der vollständige Lizenztext liegt in [`assets/ui/Fredoka-OFL.txt`](assets/ui/Fredoka-OFL.txt).

**Arimo** — The Arimo Project Authors, Design Steve Matteson. Ergänzt fehlende Pfeile und mathematische Zeichen in Fredoka, auch ohne installierte Systemschriften. Bezogen aus dem [Google-Fonts-Repository](https://github.com/google/fonts/tree/main/ofl/arimo), unverändert unter der **SIL Open Font License 1.1**; Lizenztext: [`assets/ui/Arimo-OFL.txt`](assets/ui/Arimo-OFL.txt).

## Grafiken und UI

- Denti basiert auf den vorhandenen Referenzbildern unter `assets/denti/reference/`.
- Der transparente Denti-Spiel-Sprite, die waffenlose Variante und die fünf Gegner-Sprites wurden mit OpenAI ImageGen erstellt.
- Die acht einzelnen Waffensprites unter `assets/weapons/` wurden mit OpenAI ImageGen erstellt.
- Der transparente Waffen-Erweiterungsatlas `assets/weapons/weapon_icons_expansion.png` mit zehn Waffenideen wurde mit OpenAI ImageGen erstellt; Prompt und Zellzuordnung stehen in `docs/WEAPON_ATLAS_PROMPT.md`.
- Der Arena-Hintergrund unter `assets/environment/dental_arena_floor.png` wurde mit OpenAI ImageGen erstellt.
- Die Item- und HUD-Icon-Atlanten unter `assets/items/` und `assets/ui/`, einschließlich der acht neuen Item-Symbole, wurden mit OpenAI ImageGen erstellt.
- Die zehn eigenen Stat-Icons in `assets/ui/stat_icons_atlas.png` wurden mit dem eingebauten OpenAI ImageGen-Werkzeug erstellt. Prompt, Zuordnung und Schutz vor abgeschnittenen Motiven stehen in `docs/STAT_ICONS.md`.
- Die acht Animationsframes der Boss-Entzündungs-Aura in `assets/vfx/boss_inflammation_aura.png` wurden mit dem eingebauten OpenAI ImageGen-Werkzeug erstellt; Prompt und Farbstufen stehen in `docs/BOSS_INFLAMMATION.md`.
- Die gemalten Projektil-, Strahl- und Bodenwarnungs-Quellen unter `assets/vfx/` wurden mit dem eingebauten OpenAI ImageGen-Werkzeug erstellt. Prompts, Zuschnitt und Laufzeitatlanten sind in `docs/PROJECTILE_ART.md` und `docs/ATTACK_EFFECTS.md` dokumentiert; Partikelframes für Verzauberungen und präzise Bodenmasken werden offline erzeugt.
- Die XP-Schmelzkristalle und Goldmünzen unter `assets/loot/` wurden mit dem eingebauten OpenAI ImageGen-Werkzeug erstellt und für den gemeinsamen Beute-Atlas aufbereitet. Quelle, Prompt und Vorschau stehen in `docs/LOOT_ART.md`.
- HUD, Karten, Buttons und Fortschrittsbalken sind eigene Godot-UI-Elemente. Es werden keine externen UI-Packs verwendet.

## Musik

**othaldo** hat Dentis sieben Originalaufnahmen mit **Suno** erstellt. `python tools/prepare_original_score.py` rendert aus den MP3-Quellen unter `assets/audio/` die Loops in `assets/audio/classic/` und gibt die Godot-Loop-Offsets aus.

| Originalaufnahme | Einsatz in Denti |
| --- | --- |
| [The Little Hero's Quest](https://suno.com/s/epTxpblJhmHTmTO5) | Hauptmenü, Unter dem Kissen und Sieg |
| [Celesta Loop](https://suno.com/s/mjahlf7vcjGly4ky) | Frühe normale Wellen |
| [Buant Loop](https://suno.com/s/ZXRhf1K6KsSEUqg7) | Späte normale Wellen |
| [Celestial Marimba Motif](https://suno.com/s/XgNjwdRRkGlOBgnj) | Miniboss in Welle 5 und 15 |
| [The Boss's Theme](https://suno.com/song/4606c51b-551c-4ec2-b349-bba3d45dd5f6) | Miniboss in Welle 10 und Endlos-Arena |
| [Divine Tooth Battle](https://suno.com/song/f48d5833-dfda-4d10-ba77-7850b1118a19) | Imperator |
| [Divine Tooth Battle, zweite Fassung](https://suno.com/song/04f36c46-596f-4acd-a0e9-e3bb99b08dfb) | Palast, Imperator-Entzündung und Endlos-Doppelboss |

Vier zusätzliche Suno-Arrangements verwenden diese Originalaufnahmen als direkte Vorlagen. Die Spielfassungen liegen unter `assets/audio/themes/` und werden mit `tools/prepare_score_loop.py` geschnitten.

| Neues Stück | Einsatz | Vorlage | Schnittoptionen |
| --- | --- | --- | --- |
| [Rast zwischen den Wurzeln](https://suno.com/song/69ca0971-f638-4f5d-ad10-0f6844ee65cd) | Beutesammlung, Belohnungen und Shop | The Little Hero's Quest | `--start 12.43508 --end 51.56534 --wrap .32 --gain-db=-1.3` |
| [Karamellkurven](https://suno.com/song/29872e1f-9b9d-4992-aa08-3052f6fe14b4) | Das süße Verderben | Buant Loop | `--entry .15 --start 13.87575 --end 76.03812 --wrap .22` |
| [Strömung unter Schmelz](https://suno.com/song/aa580d87-d431-4e1e-b75a-478870e1be5a) | Tief im Säurestrom | Celesta Loop | `--start 14.18469 --end 65.74083 --wrap .26 --gain-db .6` |
| [Wurzelstrom](https://suno.com/song/34af6dd3-3664-410a-af9c-9640cadea1c4) | Abwechselnd mit dem Originalstück zwischen den Endlos-Bosswellen | Celestial Marimba Motif | `--start 17.29748 --end 84.57681 --wrap .22 --gain-db 1.2` |

Die kurzen Kampf-, Boss- und Sammelgeräusche unter `assets/audio/sfx/` wurden für dieses Projekt synthetisiert. Der Generator liegt unter `tools/generate_sfx.py`; es werden dafür keine externen Soundeffekte verwendet.
