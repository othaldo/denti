from pathlib import Path
from contextlib import redirect_stderr
import io
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from unittest.mock import patch
from run_bot_comparison import parse_args, jobs_for, workloads_for, summary, RunningProcesses


class BotComparisonTests(unittest.TestCase):
    def test_axes_are_independent_and_visible_defaults_to_one_case(self):
        args = parse_args(["--weapons", "turbo_drill", "--skills", "novice,expert", "--strategies", "aggressive,kite", "--build-policies", "simple,synergy", "--seeds", "42"])
        self.assertEqual(len(jobs_for(args)), 8)
        self.assertEqual(len({tuple(case.values()) for case in jobs_for(args)}), 8)
        visible = parse_args(["--visible"])
        self.assertEqual(len(jobs_for(visible)), 1)
        self.assertEqual(visible.jobs, 1)
        self.assertEqual(visible.seeds, [13579])

    def test_many_seeds_share_workers_even_for_a_single_pilot_configuration(self):
        args = parse_args(["--weapons", "turbo_drill", "--skills", "regular", "--seeds", "1,2,3,4,5", "--jobs", "4"])
        jobs = workloads_for(args)
        self.assertEqual(len(jobs), 4)
        self.assertEqual(sorted(seed for _, seeds in jobs for seed in seeds), [1, 2, 3, 4, 5])

    def test_cancel_stops_only_registered_child_processes(self):
        running = RunningProcesses()
        first, second = object(), object()
        running.active.update([first, second])
        with patch("run_bot_comparison.stop_process") as stop:
            running.cancel()
        self.assertEqual({call.args[0] for call in stop.call_args_list}, {first, second})
        self.assertTrue(running.cancelled.is_set())

    def test_invalid_inputs_cannot_silently_change_the_comparison(self):
        for argv in [["--skills", "perfect"], ["--seeds", "1,01"], ["--seeds", "-1"],
                     ["--seeds", "1,"], ["--speed", "8"], ["--capture"], ["--timeout", "nan"],
                     ["--visible", "--jobs", "2"], ["--visible", "--skills", "novice,expert"],
                     ["--weapons", "revelation"]]:
            with self.subTest(argv=argv), redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                parse_args(argv)

    def row(self, skill="regular", outcome="death", wave=1, gold=999):
        entry = {"outcome": "death", "all_loot": {"kills": 2, "coins_collected": 2, "xp_collected": 2, "damage_taken": 100, "dashes": 0},
                 "start": {"gold_earned": gold, "xp_earned": 200, "stats": {"health": 50, "max_health": 100}}, "combat": {"boss_ttk": 0}}
        return dict(difficulty="hell", build="turbo_drill", skill=skill, strategy="kite", build_policy="simple",
                    seed=42, outcome=outcome, wave=wave, waves=[entry] * wave)

    def test_summary_separates_pilots_and_censors_missing_boss_arrivals(self):
        text = summary({"method": "fixture", "last_wave": 5, "samples": [self.row(), self.row(skill="expert")]})
        self.assertIn("| regular | kite | simple |", text)
        self.assertIn("| expert | kite | simple |", text)
        self.assertNotIn("999", text)
        self.assertNotIn("0.00 s", text)

    def test_abort_is_visible_and_not_a_failed_full_run(self):
        text = summary({"method": "fixture", "last_wave": 1, "samples": [self.row(outcome="aborted")]})
        self.assertIn("| 0 / 1 | — | — |", text)
        self.assertNotIn("999", text)
        only_aborted = summary({"method": "fixture", "last_wave": 5, "samples": [self.row(outcome="aborted")]})
        self.assertNotIn("0/0", only_aborted)


if __name__ == "__main__":
    unittest.main()
