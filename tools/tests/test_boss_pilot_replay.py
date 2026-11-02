from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_boss_pilot_replay import replay_arrivals


class BossReplayTests(unittest.TestCase):
    def test_control_includes_boss_arrivals_even_when_the_full_run_died(self):
        arrived = dict(skill="expert", outcome="death", waves=[{"wave": 1}, {"wave": 5}])
        report = {"samples": [arrived, dict(skill="expert", waves=[{"wave": 1}]),
                              dict(skill="novice", waves=[{"wave": 5}])]}
        self.assertEqual(replay_arrivals(report), [arrived])

    def test_empty_control_cannot_claim_a_successful_comparison(self):
        for samples in [[], [dict(skill="expert", waves=[{"wave": 4}])],
                        [dict(skill="novice", waves=[{"wave": 5}])]]:
            with self.subTest(samples=samples), self.assertRaises(ValueError):
                replay_arrivals({"samples": samples})


if __name__ == "__main__":
    unittest.main()
