"""Compare earned opening runs, with isolated saves and actual paid shops."""
import argparse
import concurrent.futures
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import sys
import time
import uuid

from run_build_comparison import source_fingerprint
from run_tests import ROOT, isolated_environment, stop_process


def fingerprint():
    return hashlib.sha256(bytes.fromhex(source_fingerprint()) +
                          (ROOT / "tools/benchmark_earned_progression.gd").read_bytes()).hexdigest()


def run_build(build, args, directory):
    output = directory / f"{build}.json"
    log = directory / f"{build}.engine.log"
    command = [args.godot, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(log), "--script", "res://tools/benchmark_earned_progression.gd", "--",
               f"--builds={build}", f"--difficulties={args.difficulties}", f"--movements={args.movements}",
               f"--seeds={args.seeds}", "--output=" + output.as_posix()]
    started = time.perf_counter()
    with (directory / f"{build}.log").open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, cwd=ROOT, env=isolated_environment(directory / "userdata" / build),
                                   stdout=stream, stderr=subprocess.STDOUT, start_new_session=sys.platform != "win32")
        try:
            process.wait(timeout=args.timeout)
        except BaseException:
            stop_process(process)
            raise
    errors = (directory / f"{build}.log").read_text(encoding="utf-8", errors="replace")
    if process.returncode or any(token in errors for token in ["SCRIPT ERROR:", "ERROR:", "WARNING: ObjectDB"]):
        raise RuntimeError(f"{build} failed ({process.returncode}); inspect {directory / (build + '.log')}")
    report = json.loads(output.read_text(encoding="utf-8"))
    print(f"{build}: {len(report['samples'])} runs in {time.perf_counter() - started:.1f}s", flush=True)
    return report


def summary(report):
    groups = {}
    for row in report["samples"]:
        groups.setdefault((row["difficulty"], row["movement"], row["build"]), []).append(row)
    lines = ["# Verdienter Ausbau bis zum ersten Boss", "",
             "Ein echter Starter, endliche HP, tatsächliche Drops und Beutesammlung, verdiente Level, "
             "gekaufte Angebote und bezahlte Rerolls. Keine vorgegebenen Stat-/Goldbudgets. "
             "Skriptierte Entscheidungen und Bewegung, keine menschlichen Winrates. "
             "Einkommen/Ausbau vor W5 nur für Läufe, die W5 tatsächlich erreicht haben; sonst —. "
             "Gold verdient ist das Gesamteinkommen in W1–4, Gold übrig der Geldbeutel nach Käufen. "
             "HP beziehen sich auf den tatsächlichen Start von W5. Gruppenmediane.", "",
             "| Grad | Bewegung | Waffe | W5 erreicht | Boss besiegt | Gold verdient W1–4 | Gold übrig | XP W1–4 | Level vor W5 | Start-HP % |",
             "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for (difficulty, movement, build), rows in sorted(groups.items()):
        starts = [row["waves"][4]["start"] for row in rows if row["wave"] >= 5]
        values = [f"{statistics.median(start[key] for start in starts):.0f}" if starts else "—"
                  for key in ["gold_earned", "coins", "xp_earned", "level"]]
        values.append(f"{statistics.median(start['stats']['health'] / start['stats']['max_health'] * 100 for start in starts):.1f}" if starts else "—")
        wins = sum(row["outcome"] == "boss_killed" for row in rows)
        lines.append(f"| {difficulty} | {movement} | {build} | {len(starts)}/{len(rows)} | {wins}/{len(rows)} | " + " | ".join(values) + " |")
    lines += ["", "## Erste vollständige Welle", "",
              "W1 bietet für alle dieselbe Messdauer, sofern überlebt. Angegeben sind nur vollständig "
              "beendete W1-Proben nach der Beutesammlung; die Anzahl bleibt sichtbar.", "",
              "| Grad | Bewegung | Waffe | W1 bestanden | Kills | Gold | XP | Level danach |",
              "| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |"]
    for (difficulty, movement, build), rows in sorted(groups.items()):
        waves = [row["waves"][0] for row in rows if row["waves"][0]["outcome"] == "wave_complete"]
        values = [f"{statistics.median(wave['all_loot'][key] for wave in waves):.0f}" if waves else "—"
                  for key in ["kills", "coins_collected", "xp_collected"]]
        values += [f"{statistics.median(wave['after_rewards']['level'] for wave in waves):.0f}" if waves else "—"]
        lines.append(f"| {difficulty} | {movement} | {build} | {len(waves)}/{len(rows)} | " + " | ".join(values) + " |")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="Godot_v4.7.2-stable_win64_console.exe")
    parser.add_argument("--builds", default="turbo_drill,floss_garrote,uv_lamp,water_turbine,interdental_brush")
    parser.add_argument("--difficulties", default="hell")
    parser.add_argument("--movements", default="orbit,hunt")
    parser.add_argument("--seeds", default="13579,24680,112233")
    parser.add_argument("--jobs", type=int, choices=range(1, 5), default=4)
    parser.add_argument("--timeout", type=float, default=600)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/balance_earned_progression.json")
    parser.add_argument("--summarize", action="store_true")
    args = parser.parse_args()
    builds = args.builds.split(",")
    if not builds or len(builds) != len(set(builds)) or any(not re.fullmatch(r"[a-z0-9_]+", build) for build in builds):
        parser.error("Choose unique weapon IDs")
    if any(value not in {"easy", "normal", "hard", "hell"} for value in args.difficulties.split(",")):
        parser.error("Unknown difficulty")
    if any(value not in {"orbit", "hunt"} for value in args.movements.split(",")):
        parser.error("Choose orbit/hunt movements")
    try:
        seeds = [int(value) for value in args.seeds.split(",")]
    except ValueError:
        parser.error("Seeds must be comma-separated integers")
    if len(seeds) != len(set(seeds)) or not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("Use unique seeds and a finite positive timeout")
    if not args.summarize:
        args.godot = shutil.which(args.godot)
        if args.godot is None:
            parser.error("Godot executable not found")
        directory = ROOT / ".godot/earned_progression" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
        directory.mkdir(parents=True)
        print("Isolated earned progression:", directory, flush=True)
        before = fingerprint()
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as workers:
            reports = list(workers.map(lambda build: run_build(build, args, directory), builds))
        if before != fingerprint():
            raise RuntimeError("Sources changed during measurement")
        report = {key: value for key, value in reports[0].items() if key != "samples"}
        report["samples"] = [row for part in reports for row in part["samples"]]
        report["source_sha256"] = before
        report["revision"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report = json.loads(args.output.read_text(encoding="utf-8"))
    args.output.with_suffix(".md").write_text(summary(report), encoding="utf-8")
    print(f"{len(report['samples'])} earned runs: {args.output}")


if __name__ == "__main__":
    main()
