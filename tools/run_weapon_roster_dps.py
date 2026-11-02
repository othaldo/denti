"""Measure all normal weapons and evolutions without replacing historical reports."""
import argparse
import json
import shutil
import time
from pathlib import Path

from run_build_comparison import source_fingerprint
from run_tests import ROOT, run_one


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="Godot_v4.7.2-stable_win64_console.exe")
    args = parser.parse_args()
    godot = shutil.which(args.godot)
    if godot is None:
        parser.error("Godot executable not found")
    fingerprint = source_fingerprint("roster")
    directory = ROOT / ".godot" / "weapon_roster_dps" / time.strftime("%Y%m%d-%H%M%S")
    directory.mkdir(parents=True)
    result = run_one(godot, ROOT / "tools" / "benchmark_weapon_roster_dps.gd", directory, 300)
    if not result["passed"]:
        print(Path(result["log"]).read_text(encoding="utf-8"))
        raise RuntimeError(f"DPS measurement failed: {result}")
    if fingerprint != source_fingerprint("roster"):
        raise RuntimeError("Sources changed during measurement")
    output = ROOT / "docs" / "balance_weapon_roster_dps.json"
    report = json.loads(output.read_text(encoding="utf-8"))
    report["source_sha256"] = fingerprint
    report["wall_seconds"] = result["seconds"]
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(report['measurements'])} DPS samples: {output} ({result['seconds']:.1f}s)")


if __name__ == "__main__":
    main()
