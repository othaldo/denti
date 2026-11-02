"""Opening failures must not be mistaken for low-income full opening runs."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_earned_progression import summary


class EarnedProgressionSummaryTests(unittest.TestCase):
    def row(self, reached, gold, outcome="death"):
        wave = {"outcome": "wave_complete", "all_loot": {"kills": 10, "coins_collected": 8, "xp_collected": 5},
                "after_rewards": {"level": 2},
                "start": {"gold_earned": gold, "coins": 20, "xp_earned": 100, "level": 6,
                          "stats": {"health": 50, "max_health": 100}}}
        return {"difficulty": "hell", "movement": "hunt", "build": "turbo_drill", "wave": 5 if reached else 2,
                "outcome": outcome, "waves": [wave] * (5 if reached else 2)}

    def test_income_is_conditioned_on_reaching_the_boss(self):
        table = summary({"samples": [self.row(True, 200, "boss_killed"), self.row(False, 999)]})
        row = next(line for line in table.splitlines() if line.startswith("| hell | hunt | turbo_drill |"))
        self.assertIn("| 1/2 | 1/2 | 200 | 20 | 100 | 6 | 50.0 |", row)
        self.assertNotIn("999", row)

    def test_no_boss_arrivals_show_missing_income(self):
        table = summary({"samples": [self.row(False, 999)]})
        row = next(line for line in table.splitlines() if line.startswith("| hell | hunt | turbo_drill |"))
        self.assertIn("| 0/1 | 0/1 | — | — | — | — | — |", row)


if __name__ == "__main__":
    unittest.main()
