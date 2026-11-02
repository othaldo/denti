"""Compare old/new movement on identical earned first-boss arrival builds."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import time
import uuid

from run_bot_comparison import fingerprint
from run_tests import ROOT, isolated_environment, positive_float, stop_process

def replay_fingerprint():
    digest = hashlib.sha256(bytes.fromhex(fingerprint()))
    for path in [Path(__file__), ROOT / "tools/benchmark_boss_pilot.gd"]:
        digest.update(path.read_bytes())
    return digest.hexdigest()


def replay_arrivals(report):
    rows = [row for row in report["samples"] if row.get("skill") == "expert" and
            any(wave["wave"] == 5 for wave in row["waves"])]
    if not rows: raise ValueError("Input must contain expert runs that reached W5")
    return rows


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--baseline-ref", default="b748f4d")
    parser.add_argument("--godot", default="Godot_v4.7.2-stable_win64_console.exe")
    parser.add_argument("--timeout", type=positive_float, default=600)
    args = parser.parse_args(argv)
    input_bytes = args.input.read_bytes()
    original = json.loads(input_bytes)
    try: arrivals = replay_arrivals(original)
    except ValueError as error: parser.error(str(error))
    godot = shutil.which(args.godot)
    if godot is None: parser.error("Godot executable not found")
    reference = subprocess.check_output(["git", "rev-parse", "--verify", "--end-of-options", args.baseline_ref + "^{commit}"], cwd=ROOT, text=True).strip()
    directory = ROOT / ".godot/boss_replays" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
    baseline = directory / "baseline"
    baseline.mkdir(parents=True)
    prefix = "res://" + baseline.relative_to(ROOT).as_posix() + "/"
    for name in ["pilot_brain.gd", "pilot_observation.gd", "pilot_profile.gd", "novice.tres", "regular.tres", "expert.tres"]:
        data = subprocess.check_output(["git", "show", reference + ":tools/balance/bots/" + name], cwd=ROOT).decode("utf-8")
        (baseline / name).write_text(data.replace("res://tools/balance/bots/", prefix), encoding="utf-8")
    output = directory / "report.json"
    command = [godot, "--headless", "--audio-driver", "Dummy", "--fixed-fps", "60", "--path", str(ROOT),
               "--script", "res://tools/benchmark_boss_pilot.gd", "--", "--input=" + args.input.resolve().as_posix(),
               "--reference-brain=" + prefix + "pilot_brain.gd", "--reference-sensor=" + prefix + "pilot_observation.gd",
               "--output=" + output.as_posix()]
    before = replay_fingerprint()
    with (directory / "output.log").open("w", encoding="utf-8") as stream:
        process = subprocess.Popen(command, cwd=ROOT, env=isolated_environment(directory / "userdata"), stdout=stream,
                                   stderr=subprocess.STDOUT, start_new_session=sys.platform != "win32")
        try: process.wait(timeout=args.timeout)
        except BaseException:
            stop_process(process)
            raise
    logs = (directory / "output.log").read_text(encoding="utf-8", errors="replace")
    if process.returncode or any(token in logs for token in ["SCRIPT ERROR:", "ERROR:", "WARNING: ObjectDB"]):
        raise RuntimeError(f"Boss replay failed; inspect {directory / 'output.log'}")
    if before != replay_fingerprint() or input_bytes != args.input.read_bytes():
        raise RuntimeError("Sources or input changed during the boss replay")
    report = json.loads(output.read_text(encoding="utf-8"))
    if len(report["samples"]) != len(arrivals) * 2 or report["hz"] != 60 or report["time_scale"] != 1:
        raise RuntimeError("Boss replay omitted cases or changed the simulation timestep")
    report.update(baseline_revision=reference, source_sha256=before,
                  input_sha256=hashlib.sha256(input_bytes).hexdigest())
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for revision in ["reference", "revised"]:
        rows = [row for row in report["samples"] if row["policy_revision"] == revision]
        print(f"{revision}: {sum(row['outcome'] == 'boss_killed' for row in rows)}/{len(rows)} boss kills")
    print(output)


if __name__ == "__main__":
    main()
