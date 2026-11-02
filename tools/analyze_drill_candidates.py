"""Compare earned drill candidates with matched waves and bounded income floors."""
from collections import Counter
import json
from pathlib import Path
import statistics

ROOT = Path(__file__).resolve().parents[1]


def load(name):
    return json.loads((ROOT / "docs" / name).read_text(encoding="utf-8"))


def analyze():
    reports = [("Vorher", load("balance_drill_baseline.json")),
               ("Nur Ersatzkontakt", load("balance_drill_retarget.json")),
               ("Ersatzkontakt + zweites Ziel", load("balance_drill_pair.json"))]
    lines = ["# Bohrer: Kontrollierte Kandidaten", "",
             "Je neun identische Hell-Seeds, aktive Zielsuche, ein echter Starter, verdiente Ausrüstung. "
             "Kein Dash oder bewusstes Ausweichen. HP/Einkommen vor W5 nur unter den tatsächlich "
             "dort angekommenen Läufen; die Seedmenge kann sich unterscheiden.", "",
             "| Variante | W5 erreicht | Boss besiegt | Gold W1–4 | XP W1–4 | Start-HP % | Verlorenes Ziel, kein Kontakt / abgeschlossene Stöße |",
             "| --- | ---: | ---: | ---: | ---: | ---: | --- |"]
    first = [row for row in reports[0][1]["samples"] if row["build"] == "turbo_drill"]
    before = {(row["seed"], wave["wave"]): wave for row in first for wave in row["waves"] if wave["wave"] <= 4 and wave["outcome"] == "wave_complete"}
    for label, report in reports:
        rows = [row for row in report["samples"] if row["build"] == "turbo_drill"]
        starts = [row["waves"][4]["start"] for row in rows if row["wave"] == 5]
        counters = Counter()
        for row in rows:
            for wave in row["waves"]: counters.update(wave["strikes"])
        gold = f"{statistics.median(start['gold_earned'] for start in starts):.1f}" if starts else "—"
        xp = f"{statistics.median(start['xp_earned'] for start in starts):.1f}" if starts else "—"
        hp = f"{statistics.median(start['stats']['health'] / start['stats']['max_health'] * 100 for start in starts):.1f}" if starts else "—"
        lines.append(f"| {label} | {len(starts)}/{len(rows)} | {sum(row['outcome'] == 'boss_killed' for row in rows)}/{len(rows)} | "
                     f"{gold} | {xp} | {hp} | {counters['lost_without_contact']}/{counters['completed']} "
                     f"({100 * counters['lost_without_contact'] / max(counters['completed'], 1):.1f} %) |")
    lines += ["", "## Gleiche vollständig beendete Wellen", "",
              "Nur W1–4 mit demselben Seed und vollständigem Abschluss in beiden Varianten. "
              "Summierte Einnahmen dieser gleichen Zeitfenster; keine scheinbare Verbesserung "
              "allein durch längeres Überleben. Unterbrochene Wellen sind ausgeschlossen.", "",
              "| Kandidat | Wellenpaare | Gold vorher → Kandidat | XP vorher → Kandidat |",
              "| --- | ---: | ---: | ---: |"]
    for label, report in reports[1:]:
        after = {(row["seed"], wave["wave"]): wave for row in report["samples"] if row["build"] == "turbo_drill"
                 for wave in row["waves"] if wave["wave"] <= 4 and wave["outcome"] == "wave_complete"}
        keys = before.keys() & after.keys()
        values = [f"{sum(before[key]['all_loot'][metric] for key in keys)} → {sum(after[key]['all_loot'][metric] for key in keys)}"
                  for metric in ["coins_collected", "xp_collected"]]
        lines.append(f"| {label} | {len(keys)} | " + " | ".join(values) + " |")
    lines += ["", "## Mindestversorgung: reine Einnahmenkontrolle", "",
              "Eine hypothetische Aufstockung auf mindestens 20 Gold und 20 XP nach einer "
              "vollständig überlebten Welle. Nur nachträgliche Berechnung auf unveränderten "
              "Basisproben: Zusätzliche Käufe/Heilung und spätere Kämpfe werden nicht simuliert.", "",
              "| Waffe | Vollständige W1–4 | Gold-Aufstockung gesamt | XP-Aufstockung gesamt |",
              "| --- | ---: | ---: | ---: |"]
    for build in sorted({row["build"] for row in reports[0][1]["samples"]}):
        waves = [wave for row in reports[0][1]["samples"] if row["build"] == build for wave in row["waves"]
                 if wave["wave"] <= 4 and wave["outcome"] == "wave_complete"]
        gold = sum(max(20 - wave["all_loot"]["coins_collected"], 0) for wave in waves)
        xp = sum(max(20 - wave["all_loot"]["xp_collected"], 0) for wave in waves)
        lines.append(f"| {build} | {len(waves)} | {gold} | {xp} |")
    lines += ["", "## Fräse: Reichweite und normaler Gegnerschaden", "",
              "Dieselben neun Seeds und dieselbe verdiente Progression. Einkommen aus der ersten "
              "Welle nur unter überlebten W1-Proben; die Anzahl bleibt sichtbar.", "",
              "| Variante | W1 überlebt | W5 erreicht | Boss besiegt | W1 Gold | W1 XP |",
              "| --- | ---: | ---: | ---: | ---: | ---: |"]
    grinder_reports = [("78 Reichweite, 75 % Trash", reports[0][1]),
                       ("110 Reichweite, 75 % Trash", load("balance_grinder_reach.json")),
                       ("110 Reichweite, 100 % Trash", load("balance_grinder_clear.json"))]
    for label, report in grinder_reports:
        rows = [row for row in report["samples"] if row["build"] == "cavity_grinder"]
        first_waves = [row["waves"][0] for row in rows if row["waves"][0]["outcome"] == "wave_complete"]
        values = [f"{statistics.median(wave['all_loot'][key] for wave in first_waves):.1f}" if first_waves else "—"
                  for key in ["coins_collected", "xp_collected"]]
        lines.append(f"| {label} | {len(first_waves)}/{len(rows)} | {sum(row['wave'] == 5 for row in rows)}/{len(rows)} | "
                     f"{sum(row['outcome'] == 'boss_killed' for row in rows)}/{len(rows)} | " + " | ".join(values) + " |")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    output = ROOT / "docs/balance_drill_candidates.md"
    output.write_text(analyze(), encoding="utf-8")
    print(output)
