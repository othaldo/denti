"""Merge disjoint boss-pressure batches and summarize without hiding raw samples."""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import statistics
import subprocess

ROOT = Path(__file__).resolve().parents[1]
KEYS = ("wave", "difficulty", "build", "policy", "seed")
METRICS = ("seconds", "damage", "damage_per_second", "hp_bars_lost",
           "task_seconds", "immune_seconds", "minion_seconds", "minion_task_seconds",
           "moving_fraction", "threatened_fraction", "warning_count")


def summarize(samples: list[dict]) -> list[dict]:
    groups = defaultdict(list)
    for row in samples:
        groups[tuple(row[key] for key in KEYS[:-1])].append(row)
    result = []
    for key, rows in sorted(groups.items()):
        summary = dict(zip(KEYS[:-1], key))
        summary["n"] = len(rows)
        summary["boss"] = rows[0]["boss"]
        for metric in METRICS:
            values = [row[metric] for row in rows]
            summary[metric] = {"median": statistics.median(values),
                               "min": min(values), "max": max(values)}
        summary["boss_killed"] = sum(row["outcome"] == "boss_killed" for row in rows)
        summary["trial_failures"] = sum(row["trial_failures"] for row in rows)
        summary["trial_counts"] = sorted({len(row["trials"]) for row in rows})
        gaps = []
        for row in rows:
            trials = sorted(row["trials"].values(), key=lambda trial: trial["start"])
            gaps.extend(max(second["start"] - first["start"] - first["seconds"], 0)
                        for first, second in zip(trials, trials[1:]))
        summary["normal_windows_between_trials"] = (
            {"median": statistics.median(gaps), "min": min(gaps), "max": max(gaps)} if gaps else None)
        sources = set().union(*(row["damage_by_source"] for row in rows))
        summary["damage_by_source_mean"] = {
            source: statistics.mean(row["damage_by_source"].get(source, 0) for row in rows)
            for source in sorted(sources)}
        result.append(summary)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", nargs="+", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--date", required=True)
    args = parser.parse_args()
    batches = [json.loads(path.read_text(encoding="utf-8")) for path in args.inputs]
    for key in ("schema", "engine", "hz", "time_scale", "method"):
        if any(batch[key] != batches[0][key] for batch in batches):
            raise ValueError(f"Incompatible batches: {key}")
    samples = [row for batch in batches for row in batch["samples"]]
    identifiers = [tuple(row[key] for key in KEYS) for row in samples]
    if len(identifiers) != len(set(identifiers)):
        raise ValueError("Duplicate samples; repeated seeds belong in separate replay reports")
    digest = hashlib.sha256()
    paths = sorted({path for directory in ("scripts", "data", "tools/balance")
                    for path in (ROOT / directory).rglob("*")
                    if path.suffix in {".gd", ".tres"}})
    paths.append(ROOT / "tools/measure_boss_pressure.gd")
    for path in paths:
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(b"\0" + path.read_bytes())
    report = {key: batches[0][key] for key in ("schema", "engine", "hz", "time_scale", "method")}
    report.update({"date": args.date,
                   "git_parent": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                   "worktree_dirty": bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT)),
                   "source_fingerprint_sha256": digest.hexdigest(),
                   "source_fingerprint_scope": "All .gd/.tres under scripts, data and tools/balance, plus tools/measure_boss_pressure.gd",
                   "batches": [{"arguments": batch["arguments"], "samples": len(batch["samples"])} for batch in batches],
                   "summary": summarize(samples), "samples": samples})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(samples)} samples -> {args.output}")
    for row in report["summary"]:
        if row["policy"] == "reactive":
            print(f"W{row['wave']:2} {row['difficulty']:6} {row['build']:14}: "
                  f"{row['seconds']['median']:5.1f}s, {row['hp_bars_lost']['median']:.2f} HP bars")


if __name__ == "__main__":
    main()
