from pathlib import Path
import queue
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from bot_launcher import BotRun, Settings, weapons
from run_bot_comparison import parse_args


class LauncherTests(unittest.TestCase):
    def settings(self, **kwargs):
        return Settings(godot="C:/Program Files/Godot/godot.exe", **kwargs)

    @patch("bot_launcher.shutil.which", side_effect=lambda path: path)
    def test_visible_launch_uses_real_runner_validation_and_literal_paths(self, _which):
        arguments = self.settings(difficulties="hell", speed="1", capture=True).arguments()
        args = parse_args(arguments)
        self.assertTrue(args.visible and args.capture)
        self.assertEqual(args.weapons, ["turbo_drill"])
        self.assertEqual(args.skills, ["expert"])
        self.assertEqual(args.difficulties, ["hell"])
        self.assertEqual(args.speed, 1)
        self.assertEqual(args.godot, "C:/Program Files/Godot/godot.exe")

    @patch("bot_launcher.shutil.which", side_effect=lambda path: path)
    def test_all_weapon_comparison_has_every_regular_weapon_and_requested_seeds(self, _which):
        settings = self.settings(mode="comparison", weapons="*", skills="*", seeds="42,123", jobs="3")
        args = parse_args(settings.arguments())
        self.assertEqual(set(args.weapons), set(weapons()))
        self.assertEqual(len(args.weapons), 18)
        self.assertEqual(args.jobs, 3)
        self.assertEqual(args.seeds, [42, 123])
        self.assertEqual(settings.run_count(), 18 * 3 * 2)
        self.assertFalse(args.visible)

    @patch("bot_launcher.shutil.which", side_effect=lambda path: path)
    def test_invalid_requests_fail_before_starting_a_process(self, _which):
        for values in [dict(weapons="*"), dict(seeds="1,2"), dict(seeds="oops"),
                       dict(last_wave="6"), dict(mode="unknown"), dict(strategies="perfect")]:
            with self.subTest(values=values), self.assertRaises(ValueError):
                self.settings(**values).arguments()

    @patch("bot_launcher.shutil.which", return_value=None)
    def test_missing_godot_can_be_reported_in_the_launcher(self, _which):
        with self.assertRaisesRegex(ValueError, "Godot"):
            self.settings().arguments()

    def test_labels_follow_current_resources(self):
        self.assertEqual(weapons()["turbo_drill"], "Turbo-Bohrer")
        self.assertNotIn("laser_god", weapons())

    def test_worker_streams_logs_finishes_and_can_stop_its_own_process(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "tools").mkdir()
            script = root / "tools/run_bot_comparison.py"
            script.write_text("import sys, time\nprint('started', flush=True)\nif '--wait' in sys.argv: time.sleep(30)\nprint('finished', flush=True)\n", encoding="utf-8")
            with patch("bot_launcher.ROOT", root):
                completed = BotRun([])
                completed.start()
                events = self.collect(completed)
                self.assertIn(("log", "started\n"), events)
                self.assertIn(("log", "finished\n"), events)
                self.assertIn(("done", 0), events)
                stopped = BotRun(["--wait"])
                stopped.start()
                try:
                    self.assertEqual(stopped.events.get(timeout=10), ("log", "started\n"))
                    stopped.cancel()
                    events = self.collect(stopped)
                    self.assertTrue(stopped.cancelled.is_set())
                    self.assertFalse(any(kind == "log" and value == "finished\n" for kind, value in events))
                    self.assertIsNotNone(stopped.process.poll())
                finally:
                    stopped.cancel()

    def collect(self, run):
        events = []
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            try:
                event = run.events.get(timeout=0.1)
            except queue.Empty:
                continue
            events.append(event)
            if event[0] == "done": return events
        self.fail("Launcher worker did not finish")


if __name__ == "__main__":
    unittest.main()
