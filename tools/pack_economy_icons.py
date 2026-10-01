"""Normalize the two generated economy motifs into padded 512px atlas cells."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sources = [
    Image.open(ROOT / "assets/items/reference/economy_icons_source.png").convert("RGBA"),
    Image.open(ROOT / "assets/items/reference/economy_icons_source_v3.png").convert("RGBA"),
]
atlas = Image.new("RGBA", (1024, 512))
for index, source in enumerate(sources):
    # Generated motifs may extend past the mathematical canvas midpoint.
    # Separate them in the actual transparent gutter so no handle is clipped.
    alpha = source.getchannel("A")
    separators = [x for x in range(source.width * 2 // 5, source.width * 3 // 5)
                  if alpha.crop((x, 0, x + 1, source.height)).getbbox() is None]
    if not separators:
        raise ValueError("Economy motifs need a fully transparent separating gutter")
    split = min(separators, key=lambda x: abs(x - source.width // 2))
    cell = source.crop((0, 0, split, source.height) if index == 0
                       else (split, 0, source.width, source.height))
    cell = cell.crop(cell.getchannel("A").getbbox())
    cell.thumbnail((400, 400), Image.Resampling.LANCZOS)
    atlas.alpha_composite(cell, (index * 512 + (512 - cell.width) // 2, (512 - cell.height) // 2))
atlas.save(ROOT / "assets/items/item_icons_economy.png")
