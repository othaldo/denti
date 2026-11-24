import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("import_project", Path(__file__).resolve().parents[1] / "import_project.py")
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)

PROJECT = """config_version=5\r
\r
[application]\r
\r
config/name="Denti"\r
\r
[autoload]\r
\r
GameSession="*res://scripts/systems/game_session.gd"\r
GameInput="*res://scripts/input/controller_input.gd"\r
\r
[display]\r
\r
window/size/viewport_width=1280\r
"""


class ImportProjectTests(unittest.TestCase):
    def test_autoload_entries_are_removed_and_other_sections_kept(self):
        stripped = importer.without_autoloads(PROJECT)
        self.assertNotIn("GameSession", stripped)
        self.assertNotIn("GameInput", stripped)
        self.assertIn("[autoload]\n\n[display]", stripped)
        self.assertIn('config/name="Denti"', stripped)
        self.assertIn("window/size/viewport_width=1280", stripped)

    def test_projects_without_autoloads_are_unchanged(self):
        source = "config_version=5\n\n[display]\n\nwindow/size/viewport_width=1280\n"
        self.assertEqual(importer.without_autoloads(source), source)

    def test_only_script_and_engine_errors_count(self):
        output = "Godot Engine v4.7.2\nWARNING: atlas rounding\nSCRIPT ERROR: Parse Error\nERROR: Failed loading\n   at: x"
        self.assertEqual(importer.error_lines(output), ["SCRIPT ERROR: Parse Error", "ERROR: Failed loading"])

    def test_first_import_runs_without_autoloads_and_restores_the_exact_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            project = root / "project.godot"
            project.write_bytes(PROJECT.encode("utf-8"))
            seen = []

            def fake_import(_godot, path):
                seen.append(project.read_text(encoding="utf-8"))
                return "" if len(seen) == 1 else "SCRIPT ERROR: real problem"

            with patch.object(importer, "run_import", side_effect=fake_import):
                errors = importer.import_project("godot", root)
            self.assertNotIn("GameSession", seen[0])
            self.assertIn("GameSession", seen[1])
            self.assertEqual(errors, ["SCRIPT ERROR: real problem"])
            self.assertEqual(project.read_bytes(), PROJECT.encode("utf-8"))


if __name__ == "__main__":
    unittest.main()
