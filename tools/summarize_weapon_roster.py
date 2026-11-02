"""Join the current weapon DPS, full-combat and mixed-support measurements."""
from pathlib import Path
import json
import statistics

ROOT = Path(__file__).resolve().parents[1]


def completed(rows):
    return sum(row["outcome"] in {"wave_complete", "boss_killed"} for row in rows)


def encounter(rows, boss=False):
    result = f"{completed(rows)}/{len(rows)}"
    if boss:
        times = [row["boss_ttk"] for row in rows if row["boss_ttk"] is not None]
        return result + (f" · {statistics.median(times):.1f} s" if times else " · —")
    return result


def median(rows, key):
    return statistics.median(row[key] for row in rows)


def hp(rows):
    return statistics.median(row["health_end"] / row["health_start"] * 100 for row in rows)


def summarize(dps, combat, support):
    regular = [weapon for weapon in dps["weapons"] if not weapon["evolution"]]
    by_measure = {(row["weapon"], row["tier"], row["scenario"]): row for row in dps["measurements"]}
    lines = ["# Alle Waffen: aktuelle Vergleichszahlen", "",
             "Automatisch erzeugt. Einzelziel-/Gruppen-/Boss-DPS jeweils **pro Wurzel**; echte Angriffe, "
             "unbewegliche unsterbliche Ziele, keine Items/Verzauberungen, kein Gegnerschutz. "
             "Die Kampftabellen darunter verwenden endliche HP und echte Gegner. Keine Run-Winrates.", "",
             "## Grunddurchsatz", "",
             "| Waffe | Wurzeln | Einzel I | II | III | IV | Frontgruppe IV | Linie IV | Boss IV | Reichweite I–IV |",
             "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |"]
    for weapon in regular:
        values = [by_measure[(weapon["id"], tier, "single")]["dps_per_root"] for tier in [1, 2, 3, 4]]
        values += [by_measure[(weapon["id"], 4, scenario)]["dps_per_root"] for scenario in ["pack", "lane", "boss"]]
        lines.append(f"| {weapon['name']} | {weapon['roots']} | " + " | ".join(f"{value:.1f}" for value in values)
                     + f" | {weapon['range_i']:.0f}–{weapon['range_iv']:.0f} |")
    for mode in ["base", "shop"]:
        lines += ["", f"## Volle Kämpfe: {mode}", "",
                  "Drei Seeds; sechs Wurzeln mit derselben Waffe. Horden: feste Kreisroute. "
                  "Bosse: Nachsetzen im Abstand Bossradius + 75 % Waffenreichweite, ohne bewusstes Ausweichen. "
                  "TTK nur bei erfolgreichem Kill; hinter der Erfolgszahl steht deren Median. "
                  "Tote Builds haben ein kürzeres Fenster für Kills/Schaden.", "",
                  "| Waffe | W4 bestanden | W4 Kills | W4 Schaden erhalten | W5 Siege · TTK | W19 bestanden | W19 Kills | W19 Rest-HP % | W20 Siege · TTK |",
                  "| --- | --- | ---: | ---: | --- | --- | ---: | ---: | --- |"]
        for weapon in regular:
            groups = {wave: [row for row in combat["samples"] if row["wave"] == wave and row["mode"] == mode and row["build"] == weapon["id"]]
                      for wave in [4, 5, 19, 20]}
            a, b, c, d = (groups[wave] for wave in [4, 5, 19, 20])
            if any(len(rows) != 3 for rows in groups.values()):
                raise ValueError(f"Incomplete roster: {weapon['id']} {mode}")
            lines.append(f"| {weapon['name']} | {encounter(a)} | {median(a, 'kills'):.0f} | {median(a, 'damage_taken'):.1f} | "
                         f"{encounter(b, True)} | {encounter(c)} | {median(c, 'kills'):.0f} | {hp(c):.1f} | {encounter(d, True)} |")
    lines += ["", "## Zwei Wurzeln als Ergänzung", "",
              "Fester Kern: zwei Zauberbürsten (vier Wurzeln). Die verbleibenden zwei Wurzeln "
              "wechseln. Auf Mk IV bekommen alle sechs Wurzeln Elektrizität 6, Lebensraub 3 und Tempo 3 "
              "(W14/Mk III: Elektrizität 4, Lebensraub 2, Tempo 2); "
              "gleiche Grundstats, Qualität und allgemeine Shop-Items. "
              "Keine zusätzlichen Wasser-/Leitfähigkeitsitems. W14/19 Kreisroute; W20 gleiche "
              "Boss-Abstandsregel für alle Varianten (Bossradius + 75 % von 225 px).", "",
              "| Ergänzung | Welle | Bestanden | Kills | Rest-HP % | Schaden erhalten | Boss-TTK s |",
              "| --- | ---: | --- | ---: | ---: | ---: | ---: |"]
    names = {"support_turbine": "1× Turbine", "support_jets": "2× Wasserflosser", "support_push": "2× Amalgam-Schleuder",
             "support_uv": "1× UV-Lampe", "support_damage": "2× Schmelzspiegel", "support_fluoride": "1× Fluorid-Sprüher"}
    for build, name in names.items():
        for wave in [14, 19, 20]:
            rows = [row for row in support["samples"] if row["build"] == build and row["wave"] == wave]
            if len(rows) != 3:
                raise ValueError(f"Incomplete support: {build} {wave}")
            times = [row["boss_ttk"] for row in rows if row["boss_ttk"] is not None]
            ttk = f"{statistics.median(times):.1f}" if times else "—"
            lines.append(f"| {name} | {wave} | {encounter(rows)} | {median(rows, 'kills'):.0f} | {hp(rows):.1f} | {median(rows, 'damage_taken'):.1f} | {ttk} |")
    lines += ["", "## Evolutionen: isolierte Grundfunktion", "",
              "Mk IV ohne Rezeptitems/Verzauberungen. Bewegungsabhängige Fäden erhalten in diesem "
              "stationären Aufbau keinen fairen vollständigen Nutzen. Dies ist keine Einstufung kompletter Evolutionsbuilds.", "",
              "| Evolution | Einzelziel je Wurzel | Frontgruppe je Wurzel | Linie je Wurzel | Boss je Wurzel |",
              "| --- | ---: | ---: | ---: | ---: |"]
    for weapon in dps["weapons"]:
        if not weapon["evolution"]:
            continue
        values = [by_measure[(weapon["id"], 4, scenario)]["dps_per_root"] for scenario in ["single", "pack", "lane", "boss"]]
        lines.append(f"| {weapon['name']} | " + " | ".join(f"{value:.1f}" for value in values) + " |")
    return "\n".join(lines) + "\n"


def main():
    directory = ROOT / "docs"
    dps, combat, support = (json.loads((directory / f"balance_weapon_roster_{name}.json").read_text(encoding="utf-8"))
                            for name in ["dps", "combat", "support"])
    output = directory / "balance_weapon_roster_summary.md"
    output.write_text(summarize(dps, combat, support), encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
