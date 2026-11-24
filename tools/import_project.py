"""Import Godot assets for a fresh checkout without spurious autoload errors.

On a fresh checkout the editor compiles the autoloads before the first
filesystem scan has imported any textures or sounds, so every `preload()` of an
asset fails and hundreds of misleading parse errors are printed. The project
is therefore imported once with the autoload section removed, then started
normally; that second start must be free of script and engine errors.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
AUTOLOAD_SECTION = re.compile(r"^\[autoload\]\n(?:(?!\[).*\n)*", re.M)


def without_autoloads(source: str) -> str:
    """Return project.godot text whose [autoload] section has no entries."""
    normalized = source.replace("\r\n", "\n")
    if not AUTOLOAD_SECTION.search(normalized):
        return normalized
    return AUTOLOAD_SECTION.sub("[autoload]\n\n", normalized, count=1)


def error_lines(output: str) -> list[str]:
    return [line for line in output.splitlines() if line.startswith(("SCRIPT ERROR:", "ERROR:"))]


def run_import(godot: str, root: Path) -> str:
    result = subprocess.run([godot, "--headless", "--path", str(root), "--import"], cwd=root,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                            encoding="utf-8", errors="replace", check=False)
    if result.returncode != 0:
        print(result.stdout)
        raise SystemExit(f"Godot import exited with code {result.returncode}")
    return result.stdout


def import_project(godot: str, root: Path = ROOT) -> list[str]:
    project = root / "project.godot"
    original = project.read_bytes()
    try:
        project.write_text(without_autoloads(original.decode("utf-8")), encoding="utf-8", newline="\n")
        run_import(godot, root)
    finally:
        # Keep a stamped CI version or local edits exactly as they were.
        project.write_bytes(original)
    return error_lines(run_import(godot, root))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    args = parser.parse_args()
    godot = shutil.which(args.godot)
    if godot is None:
        parser.error("Godot executable not found; set --godot or GODOT_BIN.")
    errors = import_project(godot)
    for line in errors:
        print(line)
    if errors:
        print(f"{len(errors)} errors after the asset import.", file=sys.stderr)
        return 1
    print("Godot assets imported; project starts without script or engine errors.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
