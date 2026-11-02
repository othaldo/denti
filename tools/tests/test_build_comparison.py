"""Ensure failed encounters cannot make reported boss kill times look faster."""

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_build_comparison import summary


class ComparisonSummaryTests(unittest.TestCase):
    def sample(self, outcome, ttk=None):
        return {"wave": 20, "mode": "shop", "movement": "orbit", "build": "uv_floss",
                "outcome": outcome, "boss_ttk": ttk, "health_start": 100, "health_end": 0,
                "damage_taken": 100, "healing": 0, "near_enemy_fraction": 0.5, "kills": 20}

    def test_censored_encounters_do_not_enter_ttk_median(self):
        report = {"samples": [self.sample("death"), self.sample("timeout"),
                              self.sample("boss_killed", 45.0)]}
        table = summary(report)
        row = next(line for line in table.splitlines() if line.startswith("| 20 |"))
        self.assertIn("| 1/3 |", row)
        self.assertIn("45.0 (1/3)", row)

    def test_no_kill_does_not_report_a_zero_second_kill(self):
        table = summary({"samples": [self.sample("death"), self.sample("timeout")]})
        row = next(line for line in table.splitlines() if line.startswith("| 20 |"))
        self.assertIn("| 0/2 |", row)
        self.assertTrue(row.endswith("| — |"))


if __name__ == "__main__":
    unittest.main()
