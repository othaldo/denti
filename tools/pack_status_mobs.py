"""Split the generated two-character sheet, preserving all generated RGBA pixels."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / "assets/enemies/status_specialists.png").convert("RGBA")
for index, name in enumerate(["poison_germ", "gum_biter"]):
    cell = source.crop((index * source.width // 2, 0, (index + 1) * source.width // 2, source.height))
    cell.save(ROOT / f"assets/enemies/{name}.png")
    print(name, cell.size, cell.getchannel("A").getextrema())
