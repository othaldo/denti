"""Run the Godot build comparison in isolated user data and summarize its JSON."""

from __future__ import annotations

import argparse
from collections import defaultdict
import concurrent.futures
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
import threading
import time
import uuid

from run_tests import ROOT, isolated_environment, stop_process

CONTROLLERS = {"default": "benchmark_build_comparison.gd", "pursuit": "benchmark_build_pursuit.gd",
               "max": "benchmark_build_max_enchantments.gd", "roster": "benchmark_weapon_roster.gd",
               "support": "benchmark_weapon_support.gd"}


def source_fingerprint(controller: str = "default") -> str:
    paths = [ROOT / "project.godot", ROOT / "tools" / "benchmark_build_comparison.gd"]
    if controller != "default":
        paths.append(ROOT / "tools" / CONTROLLERS[controller])
    if controller == "roster":
        paths.extend([ROOT / "tools" / "benchmark_weapon_dps.gd", ROOT / "tools" / "benchmark_weapon_roster_dps.gd"])
    if controller == "support":
        paths.append(ROOT / "tools" / "benchmark_weapon_roster.gd")
    for folder, pattern in [("scripts", "*.gd"), ("data", "*.tres"), ("scenes", "*.tscn"), ("tools/balance", "*.gd")]:
        paths.extend((ROOT / folder).rglob(pattern))
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(path.relative_to(ROOT).as_posix().encode() + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()


def run_wave(godot: str, wave: str, args, directory: Path, stop: threading.Event) -> dict:
    if stop.is_set():
        raise RuntimeError("Comparison cancelled")
    output = directory / f"wave_{wave}.json"
    log = directory / f"wave_{wave}.engine.log"
    environment = isolated_environment(directory / "userdata" / f"wave_{wave}")
    script = CONTROLLERS[args.controller]
    command = [godot, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60", "--path", str(ROOT),
               "--log-file", str(log), "--script", "res://tools/" + script, "--",
               "--output=" + output.as_posix(), "--waves=" + wave]
    for name in ["builds", "modes", "movements", "seeds", "elements"]:
        value = getattr(args, name)
        if value is not None:
            command.append("--" + name + "=" + value)
    if args.trace:
        command.append("--trace")
    started = time.perf_counter()
    with (directory / f"wave_{wave}.log").open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, cwd=ROOT, env=environment, stdout=stream,
                                   stderr=subprocess.STDOUT, start_new_session=sys.platform != "win32")
        try:
            while process.poll() is None:
                if stop.is_set() or time.perf_counter() - started >= args.timeout:
                    raise TimeoutError(f"Wave {wave} cancelled or timed out; inspect {log}")
                try:
                    process.wait(timeout=0.5)
                except subprocess.TimeoutExpired:
                    pass
            code = process.returncode
        except BaseException:
            stop_process(process)
            raise
    errors = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
    if code or any(marker in errors for marker in ["SCRIPT ERROR:", "ERROR:", "WARNING: ObjectDB"]):
        raise RuntimeError(f"Wave {wave} failed (exit {code}); inspect {log}")
    result = json.loads(output.read_text(encoding="utf-8"))
    if not result["samples"]:
        raise RuntimeError(f"Wave {wave} produced no samples")
    print(f"Wave {wave}: {len(result['samples'])} samples in {time.perf_counter() - started:.1f}s", flush=True)
    return result


def summary(report: dict, source_name: str = "balance_build_comparison.json") -> str:
    groups = defaultdict(list)
    for sample in report["samples"]:
        groups[(sample["wave"], sample["mode"], sample["movement"], sample["build"])].append(sample)
    lines = [
        "# " + {"boss_pursuit": "Buildvergleich mit gezieltem Nachsetzen", "max_enchantments": "Maximale Elemente und Lebensraub", "weapon_roster": "Alle Standardwaffen im Kampfvergleich"}.get(report.get("controller"), "Buildvergleich auf Normal"), "",
        f"Automatisch erzeugt aus `{source_name}`. Mediane je Gruppe; "
        "Abgeschlossen zählt nur beendete Wellen oder getötete Bosse. "
        "Abgebrochene Bosskämpfe haben keine TTK. Dies sind synthetische Checkpoints, keine Run-Winrates.", "",
        "| Welle | Ausbau | Bewegung | Build | Abgeschlossen | HP Ende % | Schaden erhalten | Heilung | Nähe % | Kills | Boss-TTK s |",
        "| ---: | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for (wave, mode, movement, build), rows in sorted(groups.items()):
        def median(key):
            return statistics.median(row[key] for row in rows)
        completed = sum(row["outcome"] in {"wave_complete", "boss_killed"} for row in rows)
        ttks = [row["boss_ttk"] for row in rows if row["boss_ttk"] is not None]
        ttk = f"{statistics.median(ttks):.1f} ({len(ttks)}/{len(rows)})" if ttks else "—"
        hp = statistics.median(row["health_end"] / row["health_start"] * 100 for row in rows)
        lines.append(f"| {wave} | {mode} | {movement} | {build} | {completed}/{len(rows)} | "
                     f"{hp:.1f} | {median('damage_taken'):.1f} | {median('healing'):.1f} | "
                     f"{median('near_enemy_fraction') * 100:.1f} | {median('kills'):.0f} | {ttk} |")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="Godot_v4.7.2-stable_win64_console.exe")
    parser.add_argument("--output", type=Path, default=ROOT / "docs" / "balance_build_comparison.json")
    parser.add_argument("--timeout", type=float, default=1800, help="maximum wall seconds per wave")
    parser.add_argument("--jobs", type=int, choices=range(1, 5), default=4, help="isolated Godot workers")
    for name in ["waves", "builds", "modes", "movements", "seeds", "elements"]:
        parser.add_argument("--" + name, help="comma-separated selection")
    parser.add_argument("--summarize", action="store_true", help="only regenerate the Markdown table")
    parser.add_argument("--trace", action="store_true", help="log health once per simulated second")
    parser.add_argument("--controller", choices=list(CONTROLLERS), default="default")
    args = parser.parse_args()
    output = args.output.resolve()
    if not args.summarize:
        godot = shutil.which(args.godot)
        if godot is None:
            parser.error("Godot executable not found; pass --godot")
        run_dir = ROOT / ".godot" / "build_comparison" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
        print("Isolated build comparison:", run_dir, flush=True)
        defaults = {"default": "4,5,9,10,14,15,19,20", "pursuit": "5,10,15,20", "max": "19,20", "roster": "4,5,19,20", "support": "14,19,20"}
        waves = (args.waves or defaults[args.controller]).split(",")
        if not waves or any(wave not in {"4", "5", "9", "10", "14", "15", "19", "20"} for wave in waves) or len(set(waves)) != len(waves):
            parser.error("Choose unique checkpoints from 4,5,9,10,14,15,19,20")
        fingerprint = source_fingerprint(args.controller)
        stop = threading.Event()
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as workers:
            pending = [workers.submit(run_wave, godot, wave, args, run_dir, stop) for wave in waves]
            try:
                reports = [task.result() for task in pending]
            except BaseException:
                stop.set()
                raise
        if fingerprint != source_fingerprint(args.controller):
            raise RuntimeError("Gameplay/benchmark sources changed during measurement; rerun with stable sources")
        report = {key: value for key, value in reports[0].items() if key not in {"samples", "setups"}}
        report["samples"] = [sample for part in reports for sample in part["samples"]]
        report["setups"] = {key: value for part in reports for key, value in part["setups"].items()}
        report["revision"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        report["source_sha256"] = fingerprint
        report["source_dirty"] = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).strip())
        if args.controller == "support":
            report["support_boss_reach"] = 225.0
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report = json.loads(output.read_text(encoding="utf-8"))
    table_path = output.with_suffix(".md")
    table_path.write_text(summary(report, output.name), encoding="utf-8")
    print(f"{len(report['samples'])} samples: {output}\nTable: {table_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
