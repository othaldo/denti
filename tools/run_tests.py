"""Run Godot tests with isolated user data, bounded parallelism and timing reports."""

from __future__ import annotations

import argparse
import concurrent.futures
import fnmatch
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]


def select_tests(root: Path, patterns: list[str]) -> list[Path]:
    tests = sorted((root / "tests").glob("*.gd"))
    if patterns:
        tests = [test for test in tests if any(
            fnmatch.fnmatchcase(test.stem, pattern) or fnmatch.fnmatchcase(test.name, pattern)
            for pattern in patterns
        )]
    if not tests:
        raise ValueError("No tests matched; refusing to report an empty suite as passing.")
    return tests


def isolated_environment(directory: Path) -> dict[str, str]:
    environment = os.environ.copy()
    directory.mkdir(parents=True, exist_ok=True)
    if sys.platform == "win32":
        environment["APPDATA"] = str(directory)
    elif sys.platform.startswith("linux"):
        environment["XDG_DATA_HOME"] = str(directory)
    else:
        raise ValueError("User-data isolation currently supports Windows and Linux only.")
    return environment


def godot_command(godot: str, test: Path, engine_log: Path) -> list[str]:
    return [godot, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
            "--log-file", str(engine_log), "--script", "res://tests/" + test.name]


def stop_process(process: subprocess.Popen) -> None:
    if process.poll() is not None:
        return
    if sys.platform == "win32":
        # The console executable can launch a child Godot process.
        subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        if process.poll() is None:
            process.kill()
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    process.wait()


def run_one(godot: str, test: Path, run_dir: Path, timeout: float) -> dict:
    log_path = run_dir / (test.stem + ".log")
    engine_log = run_dir / (test.stem + ".engine.log")
    environment = isolated_environment(run_dir / "userdata" / test.stem)
    started = time.perf_counter()
    timed_out = False
    process = None
    with log_path.open("w", encoding="utf-8") as output:
        try:
            process = subprocess.Popen(godot_command(godot, test, engine_log), cwd=ROOT,
                                       env=environment, stdout=output, stderr=subprocess.STDOUT,
                                       start_new_session=sys.platform != "win32")
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            stop_process(process)
        except BaseException:
            if process is not None:
                stop_process(process)
            raise
    text = log_path.read_text(encoding="utf-8", errors="replace")
    # Godot can emit script errors and still return exit code zero.
    script_error = "SCRIPT ERROR:" in text
    return {"test": test.stem, "seconds": round(time.perf_counter() - started, 3),
            "passed": process.returncode == 0 and not timed_out and not script_error,
            "exit_code": process.returncode, "timed_out": timed_out,
            "script_error": script_error, "log": str(log_path)}


def positive_int(value: str) -> int:
    number = int(value)
    if number < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return number


def positive_float(value: str) -> float:
    number = float(value)
    if not 0 < number < float("inf"):
        raise argparse.ArgumentTypeError("must be a finite positive number")
    return number


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--jobs", type=positive_int, default=min(4, os.cpu_count() or 1))
    parser.add_argument("--timeout", type=positive_float, default=180.0, help="seconds per test")
    parser.add_argument("--filter", action="append", default=[], help="test name/glob, repeatable")
    args = parser.parse_args()
    godot = shutil.which(args.godot)
    if godot is None:
        parser.error("Godot executable not found; set --godot or GODOT_BIN.")
    try:
        tests = select_tests(ROOT, args.filter)
        isolated_environment(ROOT / ".godot" / "test_runs")
    except ValueError as error:
        parser.error(str(error))
    if not (ROOT / ".godot" / "global_script_class_cache.cfg").exists():
        parser.error("Import assets first: godot --headless --path . --editor --quit")
    report_path = ROOT / ".godot" / "test_results.json"
    durations = {}
    # Fresh CI jobs use the recorded baseline; local timings override it.
    for timing_path in [ROOT / "docs" / "test_runtime_serial.json", report_path]:
        try:
            previous = json.loads(timing_path.read_text(encoding="utf-8"))
            durations.update({result["test"]: result["seconds"] for result in previous["results"]})
        except (OSError, ValueError, KeyError, TypeError):
            pass
    # Start previously slow tests first to avoid a long tail with idle workers.
    tests.sort(key=lambda test: -durations.get(test.stem, 0))
    run_dir = ROOT / ".godot" / "test_runs" / (time.strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:8])
    run_dir.mkdir(parents=True)
    started = time.perf_counter()
    results = []
    print(f"Running {len(tests)} tests with {args.jobs} workers (fixed delta 1/60 s).", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(run_one, godot, test, run_dir, args.timeout): test for test in tests}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            status = "PASS" if result["passed"] else "FAIL"
            print(f"{status} {result['test']} ({result['seconds']:.2f}s)", flush=True)
            if not result["passed"]:
                print(Path(result["log"]).read_text(encoding="utf-8", errors="replace"), flush=True)
                if result["timed_out"]:
                    print(f"Timed out after {args.timeout:g}s.", flush=True)
    elapsed = round(time.perf_counter() - started, 3)
    results.sort(key=lambda result: result["test"])
    failed = sum(not result["passed"] for result in results)
    report = {"seconds": elapsed, "jobs": args.jobs, "count": len(results), "failed": failed,
              "godot": godot, "results": results}
    encoded = json.dumps(report, indent=2) + "\n"
    (run_dir / "results.json").write_text(encoded, encoding="utf-8")
    report_path.write_text(encoded, encoding="utf-8")
    print(f"\n{len(results) - failed}/{len(results)} passed in {elapsed:.2f}s. Logs: {run_dir}")
    print("Slowest tests:")
    for result in sorted(results, key=lambda result: result["seconds"], reverse=True)[:10]:
        print(f"  {result['seconds']:6.2f}s  {result['test']}")
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as summary:
            summary.write(f"### Godot tests\n\n{len(results) - failed}/{len(results)} passed "
                          f"in {elapsed:.2f}s with {args.jobs} workers.\n\n"
                          "| Test | Seconds |\n| --- | ---: |\n")
            for result in sorted(results, key=lambda result: result["seconds"], reverse=True)[:10]:
                summary.write(f"| {result['test']} | {result['seconds']:.2f} |\n")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
