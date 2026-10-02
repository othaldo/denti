"""Pad six painted cells without repainting or changing their generated alpha."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / "assets/items/item_icons_dodge.png").convert("RGBA")
atlas = Image.new("RGBA", (1536, 1024))
for index in range(6):
    col, row = index % 3, index // 3
    cell = source.crop((col * source.width // 3, row * source.height // 2,
                        (col + 1) * source.width // 3, (row + 1) * source.height // 2))
    cell.thumbnail((400, 400), Image.Resampling.LANCZOS)
    atlas.alpha_composite(cell, (col * 512 + (512 - cell.width) // 2,
                                 row * 512 + (512 - cell.height) // 2))
atlas.save(ROOT / "assets/items/item_icons_dodge_packed.png")
preview = Image.new("RGB", (720, 270), "#fff7e1")
draw = ImageDraw.Draw(preview)
font = ImageFont.truetype(str(ROOT / "assets/ui/Fredoka.ttf"), 19)
names = ["Gleitwachs", "Seidenwurzel", "Flutschspülung", "Lotusschmelz", "Unfassbare Wurzel", "Zahnflutsch"]
for index, name in enumerate(names):
    col, row = index % 3, index // 3
    cell = atlas.crop((col * 512, row * 512, (col + 1) * 512, (row + 1) * 512))
    large = cell.resize((96, 96), Image.Resampling.LANCZOS)
    small = cell.resize((48, 48), Image.Resampling.LANCZOS)
    preview.paste(large, (col * 240 + 20, row * 135 + 4), large)
    preview.paste(small, (col * 240 + 130, row * 135 + 28), small)
    draw.text((col * 240 + 20, row * 135 + 103), name, fill="#402131", font=font)
preview.save(ROOT / "docs/screenshots/dodge_icons.png")
print("Packed six dodge motifs with transparent padding; preview at 96 and 48 px.")
