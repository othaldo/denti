"""Compare independent bot skills, strategies and build policies, or watch one run."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import itertools
import json
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import sys
import threading
import time
import uuid

from run_build_comparison import source_fingerprint
from run_tests import ROOT, isolated_environment, stop_process

SKILLS = ("novice", "regular", "expert")
STRATEGIES = ("aggressive", "kite", "collector", "boss")
POLICIES = ("simple", "synergy")
AXES = ("weapons", "skills", "strategies", "build_policies", "difficulties")


def csv_values(value, allowed=None):
    parts = value.split(",")
    if not parts or any(not part for part in parts) or len(set(parts)) != len(parts):
        raise ValueError("Lists must contain unique, nonempty values")
    if allowed is not None and any(part not in allowed for part in parts):
        raise ValueError(f"Choose from {', '.join(allowed)}")
    return parts


def weapon_ids():
    return re.findall(r'data/weapons/([a-z0-9_]+)\.tres',
                      (ROOT / "scripts/weapons/weapon_catalog.gd").read_text(encoding="utf-8"))


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="Godot_v4.7.2-stable_win64_console.exe")
    for flag in ["weapons", "skills", "strategies", "build-policies", "difficulties", "seeds"]:
        parser.add_argument("--" + flag)
    parser.add_argument("--last-wave", type=int, choices=range(1, 6), default=5)
    parser.add_argument("--jobs", type=int, choices=range(1, 5))
    parser.add_argument("--timeout", type=float, default=600)
    parser.add_argument("--visible", action="store_true")
    parser.add_argument("--speed", type=int, choices=[1, 4, 8, 16])
    parser.add_argument("--capture", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--summarize", type=Path, metavar="REPORT_JSON")
    args = parser.parse_args(argv)
    if args.summarize:
        return args
    defaults = {"weapons": "turbo_drill" if args.visible else "turbo_drill,uv_lamp",
                "skills": "regular" if args.visible else ",".join(SKILLS),
                "strategies": "kite", "build_policies": "simple", "difficulties": "normal",
                "seeds": "13579" if args.visible else "13579,24680,112233"}
    allowed = {"weapons": weapon_ids(), "skills": SKILLS, "strategies": STRATEGIES,
               "build_policies": POLICIES, "difficulties": ("easy", "normal", "hard", "hell")}
    try:
        for axis in AXES:
            setattr(args, axis, csv_values(getattr(args, axis) or defaults[axis], allowed[axis]))
        seeds = csv_values(args.seeds or defaults["seeds"])
        args.seeds = [int(value) for value in seeds]
        if len(set(args.seeds)) != len(args.seeds) or any(not 0 <= value <= 2147483647 for value in args.seeds):
            raise ValueError("Seeds must be unique integers from 0 to 2147483647")
        if not 0 < args.timeout < float("inf"):
            raise ValueError("Timeout must be finite and positive")
        count = len(args.seeds)
        for axis in AXES:
            count *= len(getattr(args, axis))
        if args.visible and (count != 1 or args.jobs not in (None, 1)):
            raise ValueError("Visible mode watches one weapon/skill/strategy/policy/difficulty/seed with one worker")
        if not args.visible and (args.speed is not None or args.capture):
            raise ValueError("--speed and --capture require --visible; headless already runs without realtime synchronization")
    except ValueError as error:
        parser.error(str(error))
    args.jobs = args.jobs or (1 if args.visible else 4)
    args.speed = args.speed or 4
    return args


def jobs_for(args):
    return [dict(zip(AXES, values)) for values in itertools.product(*(getattr(args, axis) for axis in AXES))]


def workloads_for(args):
    cases = jobs_for(args)
    batches = min(len(args.seeds), max(1, (args.jobs + len(cases) - 1) // len(cases)))
    return [(case, args.seeds[offset::batches]) for case in cases for offset in range(batches)]


class RunningProcesses:
    def __init__(self):
        self.lock = threading.Lock()
        self.active = set()
        self.cancelled = threading.Event()

    def cancel(self):
        self.cancelled.set()
        with self.lock:
            processes = list(self.active)
        for process in processes:
            stop_process(process)


def fingerprint():
    digest = hashlib.sha256(bytes.fromhex(source_fingerprint()))
    paths = [Path(__file__), ROOT / "tools/benchmark_bot_comparison.gd",
             ROOT / "tools/benchmark_earned_progression.gd"]
    paths.extend((ROOT / "tools/balance/bots").glob("*.tres"))
    for path in sorted(paths):
        digest.update(path.relative_to(ROOT).as_posix().encode() + b"\0" + path.read_bytes())
    return digest.hexdigest()


def run_job(index, case, seeds, args, directory, running):
    if running.cancelled.is_set():
        raise concurrent.futures.CancelledError()
    folder = directory / f"case_{index:04d}"
    folder.mkdir()
    output = folder / "report.json"
    command = [args.godot]
    command += ["--disable-render-loop"] if args.visible else ["--headless"]
    command += ["--audio-driver", "Dummy", "--fixed-fps", "60", "--path", str(ROOT),
                "--log-file", str(folder / "engine.log"), "--script", "res://tools/benchmark_bot_comparison.gd", "--"]
    command += [f"--{key.replace('_', '-')}={value}" for key, value in case.items()]
    command += ["--seeds=" + ",".join(map(str, seeds)), f"--last-wave={args.last_wave}", "--output=" + output.as_posix()]
    if args.visible:
        command += ["--visible", f"--speed={args.speed}"]
        if args.capture:
            command += ["--capture=" + (folder / "viewer.png").as_posix()]
    with (folder / "output.log").open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, cwd=ROOT, env=isolated_environment(folder / "userdata"),
                                   stdout=stream, stderr=subprocess.STDOUT, start_new_session=sys.platform != "win32")
        with running.lock:
            running.active.add(process)
        try:
            if running.cancelled.is_set():
                stop_process(process)
                raise concurrent.futures.CancelledError()
            process.wait(timeout=args.timeout)
        except BaseException:
            stop_process(process)
            raise
        finally:
            with running.lock:
                running.active.discard(process)
    logs = (folder / "output.log").read_text(encoding="utf-8", errors="replace")
    if process.returncode or any(token in logs for token in ["SCRIPT ERROR:", "ERROR:", "WARNING: ObjectDB"]):
        raise RuntimeError(f"Bot case failed; inspect {folder / 'output.log'}")
    report = json.loads(output.read_text(encoding="utf-8"))
    if len(report["samples"]) != len(seeds) or {row["seed"] for row in report["samples"]} != set(seeds):
        raise RuntimeError("Bot worker omitted or duplicated a requested seed")
    for row in report["samples"]:
        expected = dict(build=case["weapons"], skill=case["skills"], strategy=case["strategies"],
                        build_policy=case["build_policies"], difficulty=case["difficulties"])
        if any(row[key] != value for key, value in expected.items()) or row["physics_hz"] != 60 or row["time_scale"] != 1:
            raise RuntimeError("Bot case metadata or physics timestep differs from the request")
    print(f"{index + 1}: {' / '.join(case.values())}: {len(report['samples'])} runs", flush=True)
    return report


def summary(report):
    groups = {}
    for row in report["samples"]:
        key = tuple(row[name] for name in ["difficulty", "build", "skill", "strategy", "build_policy"])
        groups.setdefault(key, []).append(row)
    lines = ["# Botvergleich", "", report["method"], "",
             "Spielstärke, Strategie und Buildregel sind getrennte Achsen. Profile sind noch nicht an menschlichen "
             "Spielstärken kalibriert. Keine menschlichen Winrates. Abgebrochene Läufe bleiben sichtbar und gehen "
             "nicht in Erfolgs-/Einkommensmediane ein. Gold/XP/HP vor W5 nur unter tatsächlichen Bossankünften; "
             "TTK nur unter erfolgreichen Bosskills. Unterschiedliche Überlebensgruppen sind kein gleicher Nenner.", "",
             "| Grad | Startwaffe | Pilot | Strategie | Buildregel | Läufe / Abbrüche | W5 erreicht | Boss besiegt | Gold / XP vor W5 | HP vor W5 % | Boss-TTK |",
             "| --- | --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for key, samples in sorted(groups.items()):
        valid = [row for row in samples if row["outcome"] != "aborted"]
        starts = [row["waves"][4]["start"] for row in valid if row["wave"] == 5]
        times = [row["waves"][-1]["combat"]["boss_ttk"] for row in valid if row["outcome"] == "boss_killed"]
        income = f"{statistics.median(s['gold_earned'] for s in starts):.0f} / {statistics.median(s['xp_earned'] for s in starts):.0f}" if starts else "—"
        hp = f"{statistics.median(s['stats']['health'] / s['stats']['max_health'] * 100 for s in starts):.1f}" if starts else "—"
        time_text = f"{statistics.median(times):.2f} s" if times else "—"
        planned_boss = report.get("last_wave", 5) == 5
        arrived = f"{len(starts)}/{len(valid)}" if planned_boss and valid else "—"
        killed = f"{len(times)}/{len(valid)}" if planned_boss and valid else "—"
        lines.append("| " + " | ".join(key) + f" | {len(valid)} / {len(samples) - len(valid)} | {arrived} | {killed} | {income} | {hp} | {time_text} |")
    lines += ["", "## Erste vollständig beendete Welle", "",
              "Gleiche volle W1-Dauer; gescheiterte oder abgebrochene Wellen werden nicht mit einer vollen "
              "Einnahmenphase verglichen. Anzahl sowie tatsächlich ausgeführte Dashs bleiben sichtbar.", "",
              "| Grad / Start / Pilot / Strategie / Buildregel | W1 vollständig | Kills | Gold | XP | Schaden erhalten | Dashs |",
              "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for key, samples in sorted(groups.items()):
        waves = [row["waves"][0] for row in samples if row["waves"][0]["outcome"] == "wave_complete"]
        values = [f"{statistics.median(w['all_loot'][field] for w in waves):.1f}" if waves else "—"
                  for field in ["kills", "coins_collected", "xp_collected", "damage_taken", "dashes"]]
        lines.append("| " + " / ".join(key) + f" | {len(waves)}/{len(samples)} | " + " | ".join(values) + " |")
    return "\n".join(lines) + "\n"


def main(argv=None):
    args = parse_args(argv)
    if args.summarize:
        output = args.summarize
        report = json.loads(output.read_text(encoding="utf-8"))
    else:
        args.godot = shutil.which(args.godot)
        if args.godot is None:
            raise SystemExit("Godot executable not found")
        directory = ROOT / ".godot/bot_runs" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
        directory.mkdir(parents=True)
        output = args.output.resolve() if args.output else directory / "report.json"
        output.parent.mkdir(parents=True, exist_ok=True)
        cases = workloads_for(args)
        before = fingerprint()
        started = time.perf_counter()
        print(f"{sum(len(seeds) for _, seeds in cases)} bot runs, {args.jobs} workers: {directory}", flush=True)
        running = RunningProcesses()
        workers = concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs)
        try:
            futures = [workers.submit(run_job, index, case, seeds, args, directory, running)
                       for index, (case, seeds) in enumerate(cases)]
            reports = [future.result() for future in concurrent.futures.as_completed(futures)]
        except BaseException:
            running.cancel()
            raise
        finally:
            workers.shutdown(wait=True, cancel_futures=True)
        if before != fingerprint():
            raise RuntimeError("Sources changed during measurement")
        report = {key: value for key, value in reports[0].items() if key != "samples"}
        report.update(samples=[row for part in reports for row in part["samples"]], last_wave=args.last_wave,
                      source_sha256=before, wall_seconds=time.perf_counter() - started,
                      working_tree_dirty=bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).strip()),
                      revision=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip())
        report["samples"].sort(key=lambda row: tuple(str(row[key]) for key in ["difficulty", "build", "skill", "strategy", "build_policy", "seed"]))
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    output.with_suffix(".md").write_text(summary(report), encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
