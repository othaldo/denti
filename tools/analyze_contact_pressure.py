"""Compare contact buffs on identical completed wave windows and matched seeds."""
import json
from pathlib import Path
import statistics

ROOT = Path(__file__).resolve().parents[1]
BUILDS = ["turbo_drill", "cavity_grinder", "plaque_scaler", "prophylaxis_polisher"]


def rows(name, build, difficulty):
    report = json.loads((ROOT / "docs" / name).read_text(encoding="utf-8"))
    return {row["seed"]: row for row in report["samples"]
            if row["build"] == build and row["difficulty"] == difficulty and row["movement"] == "hunt"}


def matched(before, after):
    keys = sorted(before.keys() & after.keys())
    return [before[key] for key in keys], [after[key] for key in keys]


def completed_pairs(before, after):
    first = {(row["seed"], wave["wave"]): wave for row in before for wave in row["waves"]
             if wave["wave"] < 5 and wave["outcome"] == "wave_complete"}
    second = {(row["seed"], wave["wave"]): wave for row in after for wave in row["waves"]
              if wave["wave"] < 5 and wave["outcome"] == "wave_complete"}
    pairs = [(first[key], second[key]) for key in sorted(first.keys() & second.keys())]
    if any(a["spawn_plan"] != b["spawn_plan"] or a["seconds"] != b["seconds"] for a, b in pairs):
        raise ValueError("Matched waves must have the same spawn plan and observation duration")
    return pairs


def arrivals(samples):
    return sum(row["wave"] == 5 for row in samples)


def wins(samples):
    return sum(row["outcome"] == "boss_killed" for row in samples)


def ttk(samples):
    times = [row["waves"][-1]["combat"]["boss_ttk"] for row in samples if row["outcome"] == "boss_killed"]
    return f"{statistics.median(times):.2f} s" if times else "—"


def main():
    lines = ["# Kontaktwaffen: Platz schaffen und verlässliche Stärken", "",
             "Neun identische Hell-Seeds; ein kostenloser Starter, echte Drops, endliche mitgenommene HP, "
             "bezahlte Shops und verdiente Feuer-Upgrades. Dieselbe Suchbewegung ohne Dash/Warnungsreaktion. "
             "Diagnoseproben, keine menschlichen Winrates. Vorher: letzter Stand nach dem Bohrer-/Fräsenpass, "
             "vor den kleinen Kontakt-Rückstößen und dem unabhängigen Polierer-Crit-Zyklus.", "",
             "| Waffe | W5 vorher → jetzt | Boss vorher → jetzt |", "| --- | ---: | ---: |"]
    comparisons = {}
    for build in BUILDS:
        source = {"turbo_drill": "balance_drill_pair.json", "cavity_grinder": "balance_grinder_clear.json"}.get(build, "balance_drill_baseline.json")
        candidate = "balance_polisher_cycle_after.json" if build == "prophylaxis_polisher" else "balance_contact_pressure_after.json"
        before, after = matched(rows(source, build, "hell"), rows(candidate, build, "hell"))
        if len(before) != 9:
            raise ValueError("Expected all nine paired Hell seeds")
        comparisons[build] = (before, after)
        lines.append(f"| {build} | {arrivals(before)}/9 → {arrivals(after)}/9 | {wins(before)}/9 → {wins(after)}/9 |")
    lines += ["", "## Identische vollständig überstandene W1–4", "",
              "Nur gleiche Seeds/Wellen mit vollständigem Abschluss in beiden Varianten. Einkommen und "
              "erlittener Schaden sind über dieselbe Beobachtungszeit summiert. Verschiedene "
              "Shop-/Levelentscheidungen danach gehören zum tatsächlichen Progressionspfad.", "",
              "| Waffe | Wellenpaare | Gold vorher → jetzt | XP vorher → jetzt | Schaden erlitten vorher → jetzt |",
              "| --- | ---: | ---: | ---: | ---: |"]
    for build, (before, after) in comparisons.items():
        pairs = completed_pairs(before, after)
        values = []
        for bucket, key in [("all_loot", "coins_collected"), ("all_loot", "xp_collected"), ("combat", "damage_taken")]:
            first = sum(a[bucket][key] for a, _ in pairs)
            second = sum(b[bucket][key] for _, b in pairs)
            values.append(f"{first:.1f} → {second:.1f}")
        lines.append(f"| {build} | {len(pairs)} | " + " | ".join(values) + " |")
    lines += ["", "## Normal: drei gleiche Vergleichsseeds", "",
              "Boss-TTK ist der Median erfolgreicher Kämpfe, ohne ihn für gescheiterte Läufe einzusetzen.", "",
              "| Waffe | Boss vorher → jetzt | TTK vorher → jetzt |", "| --- | ---: | --- |"]
    for build in BUILDS:
        source = "balance_contact_normal_before.json" if build in {"plaque_scaler", "prophylaxis_polisher"} else "balance_drill_normal_after.json"
        candidate = "balance_polisher_cycle_after.json" if build == "prophylaxis_polisher" else "balance_contact_normal_after.json"
        before, after = matched(rows(source, build, "normal"), rows(candidate, build, "normal"))
        # The polisher candidate also has six additional Normal seeds.
        keys = {13579, 24680, 112233}
        before = [row for row in before if row["seed"] in keys]
        after = [row for row in after if row["seed"] in keys]
        if len(before) != 3 or len(after) != 3:
            raise ValueError("Expected three paired Normal seeds")
        lines.append(f"| {build} | {wins(before)}/3 → {wins(after)}/3 | {ttk(before)} → {ttk(after)} |")
    first, second = matched(rows("balance_drill_pair.json", "uv_lamp", "hell"), rows("balance_contact_pressure_after.json", "uv_lamp", "hell"))
    metrics = ["outcome", "wave", "kills", "gold_earned", "xp_earned", "level", "chests"]
    if len(first) != 9 or any(a[key] != b[key] for a, b in zip(first, second) for key in metrics):
        raise ValueError("Unchanged UV endpoint control drifted")
    lines += ["", "Unveränderte UV-Kontrolle: Ausgang, erreichte Welle, Kills, Gold, XP, Level und Kapseln "
              "stimmen in allen neun Seeds exakt mit dem vorherigen Stand überein. Laufzeitabhängige "
              "Waffen-UIDs sind keine Vergleichsgröße.", ""]
    output = ROOT / "docs/balance_contact_pressure_comparison.md"
    output.write_text("\n".join(lines), encoding="utf-8")
    print(output)


if __name__ == "__main__":
    main()
