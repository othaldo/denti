"""Normalize the two generated economy motifs into padded 512px atlas cells."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sources = [
    Image.open(ROOT / "assets/items/reference/economy_icons_source.png").convert("RGBA"),
    Image.open(ROOT / "assets/items/reference/economy_icons_source_v2.png").convert("RGBA"),
]
atlas = Image.new("RGBA", (1024, 512))
for index, source in enumerate(sources):
    cell = source.crop((index * source.width // 2, 0, (index + 1) * source.width // 2, source.height))
    cell = cell.crop(cell.getchannel("A").getbbox())
    cell.thumbnail((400, 400), Image.Resampling.LANCZOS)
    atlas.alpha_composite(cell, (index * 512 + (512 - cell.width) // 2, (512 - cell.height) // 2))
atlas.save(ROOT / "assets/items/item_icons_economy.png")
