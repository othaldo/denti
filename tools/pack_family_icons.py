"""Crop complete generated motifs at transparent gutters into padded atlas cells.

No repainting or background removal: all source RGBA pixels are preserved.
Raw generated sheets remain available for future art changes.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/items"
SHEETS = [
    ("item_icons_families_1.png", "item_icons_families_1_packed.png", 4),
    ("item_icons_families_2.png", "item_icons_families_2_packed.png", 4),
    ("item_icons_families_3_v2.png", "item_icons_families_3_packed.png", 4),
    ("item_icons_mythic.png", "item_icons_mythic_packed.png", 2),
]


def gutter(alpha, axis, target, radius, start, end):
    width, height = alpha.size
    positions = []
    for pos in range(max(1, target - radius), min((width if axis == "x" else height) - 1, target + radius)):
        box = (pos, start, pos + 1, end) if axis == "x" else (start, pos, end, pos + 1)
        if alpha.crop(box).getbbox() is None:
            positions.append(pos)
    if not positions:
        raise ValueError(f"No transparent {axis} gutter near {target}; repair generated layout first")
    return min(positions, key=lambda value: abs(value - target))


motifs = []
for source_name, output_name, rows in SHEETS:
    source = Image.open(ASSETS / source_name).convert("RGBA")
    alpha = source.getchannel("A")
    xcuts = [0] + [gutter(alpha, "x", round(source.width * i / 4), round(source.width / 20), 0, source.height)
                   for i in range(1, 4)] + [source.width]
    atlas = Image.new("RGBA", (2048, rows * 512))
    cells = {}
    for col in range(4):
        x0, x1 = xcuts[col:col + 2]
        ycuts = [0] + [gutter(alpha, "y", round(source.height * i / rows), round(source.height / (rows * 5)), x0, x1)
                      for i in range(1, rows)] + [source.height]
        for row in range(rows):
            cell = source.crop((x0, ycuts[row], x1, ycuts[row + 1]))
            bounds = cell.getchannel("A").getbbox()
            if bounds is None:
                raise ValueError("Empty icon cell")
            cell = cell.crop(bounds)
            scale = 400 / max(cell.size)
            cell = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.LANCZOS)
            atlas.alpha_composite(cell, (col * 512 + (512 - cell.width) // 2, row * 512 + (512 - cell.height) // 2))
            cells[row * 4 + col] = atlas.crop((col * 512, row * 512, (col + 1) * 512, (row + 1) * 512))
    atlas.save(ASSETS / output_name)
    motifs.extend(cells[i] for i in range(rows * 4))
    print(output_name, atlas.size)

# One labeled contact sheet shows every new cell at actual 48px shop-card size.
manifest = json.loads((ROOT / "docs/item_icon_manifest.json").read_text(encoding="utf-8"))
preview = Image.new("RGB", (1120, 14 * 88 + 60), "#fff7e1")
draw = ImageDraw.Draw(preview)
font = ImageFont.truetype(str(ROOT / "assets/ui/Fredoka.ttf"), 15)
title_font = ImageFont.truetype(str(ROOT / "assets/ui/Fredoka.ttf"), 25)
draw.text((20, 12), "Denti · 56 neue Icons in Shopgröße (48 px)", fill="#402131", font=title_font)
names = ["Common", "Uncommon", "Rare", "Legendary", "Mythic"]
colors = ["#8f777a", "#4289b6", "#8753b8", "#bc7424", "#c33e76"]
for index, (item, motif) in enumerate(zip(manifest, motifs)):
    x, y = (index % 4) * 280 + 12, (index // 4) * 88 + 60
    icon = motif.copy()
    icon.thumbnail((48, 48), Image.Resampling.LANCZOS)
    preview.paste(icon, (x + (48 - icon.width) // 2, y + (48 - icon.height) // 2), icon)
    draw.text((x + 58, y + 2), item["name"], fill="#402131", font=font)
    draw.text((x + 58, y + 24), names[item["tier"] - 1], fill=colors[item["tier"] - 1], font=font)
preview.save(ROOT / "docs/screenshots/item_families_icons_48px.png")
