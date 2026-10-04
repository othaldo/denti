"""Exercise the runner's failure handling and per-process data isolation."""

import concurrent.futures
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("run_tests", Path(__file__).resolve().parents[1] / "run_tests.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.run_dir = self.root / "run"
        self.run_dir.mkdir()
        self.stub = self.root / "fake_godot.py"
        self.stub.write_text('''import json, os, pathlib, sys, time
name = sys.argv[1]
if name == "timeout":
    time.sleep(10)
if name == "script_error":
    print("SCRIPT ERROR: deliberately simulated", flush=True)
elif name == "exit_failure":
    sys.exit(1)
else:
    directory = os.environ.get("APPDATA") if sys.platform == "win32" else os.environ["XDG_DATA_HOME"]
    pathlib.Path(directory, "same_save.json").write_text(name)
    print(json.dumps({"directory": directory, "name": name}), flush=True)
''', encoding="utf-8")
        self.root_patch = patch.object(runner, "ROOT", self.root)
        self.command_patch = patch.object(runner, "godot_command",
                                          side_effect=lambda executable, test, log: [sys.executable, str(self.stub), test.stem])
        self.root_patch.start()
        self.command_patch.start()

    def tearDown(self):
        self.command_patch.stop()
        self.root_patch.stop()
        self.temporary.cleanup()

    def run_test(self, name, timeout=5):
        return runner.run_one("fake", Path(name + ".gd"), self.run_dir, timeout)

    def test_parallel_processes_have_separate_data_without_changing_parent_environment(self):
        before = os.environ.copy()
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(self.run_test, ["first", "second"]))
        self.assertEqual(before, dict(os.environ))
        directories = []
        for result in results:
            self.assertTrue(result["passed"])
            output = json.loads(Path(result["log"]).read_text(encoding="utf-8"))
            directories.append(output["directory"])
            self.assertEqual(Path(output["directory"], "same_save.json").read_text(), result["test"])
        self.assertNotEqual(*directories)

    def test_exit_code_and_zero_exit_script_errors_both_fail(self):
        error = self.run_test("script_error")
        self.assertEqual(error["exit_code"], 0)
        self.assertTrue(error["script_error"])
        self.assertFalse(error["passed"])
        self.assertFalse(self.run_test("exit_failure")["passed"])

    def test_timeout_fails_and_stops_the_process(self):
        result = self.run_test("timeout", timeout=0.2)
        self.assertTrue(result["timed_out"])
        self.assertFalse(result["passed"])
        self.assertLess(result["seconds"], 5)

    def test_filter_keeps_all_matches_and_rejects_empty_suite(self):
        tests = self.root / "tests"
        tests.mkdir()
        for name in ["weapon_motion", "weapon_layout", "smoke"]:
            (tests / (name + ".gd")).touch()
        selected = runner.select_tests(self.root, ["weapon_*"])
        self.assertEqual([test.stem for test in selected], ["weapon_layout", "weapon_motion"])
        self.assertEqual(len(runner.select_tests(self.root, [])), 3)
        with self.assertRaises(ValueError):
            runner.select_tests(self.root, ["missing_test"])


if __name__ == "__main__":
    unittest.main()
