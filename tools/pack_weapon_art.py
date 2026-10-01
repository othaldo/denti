"""Pack generated sprites and animation layers; never paint replacement art.

Run from the repository root: python tools/pack_weapon_art.py
The generated sources remain intact under assets/weapons/reference/.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/weapons"
SIZE = 512


def cell(image, col, row, cols=3, rows=3):
    return image.crop(tuple(round(v) for v in (
        col * image.width / cols, row * image.height / rows,
        (col + 1) * image.width / cols, (row + 1) * image.height / rows,
    )))


def trimmed(image):
    # Use the alpha bounding box only to trim transparent atlas padding.
    return image.crop(image.getchannel("A").getbbox())


def frame_body(image, crop, longest, at):
    body = trimmed(image.crop(crop))
    factor = longest / max(body.size)
    body = body.resize(tuple(round(v * factor) for v in body.size), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (SIZE, SIZE))
    frame.alpha_composite(body, at)
    return frame


def main():
    weapons = Image.open(ASSETS / "reference/weapon_refinement_generated.png").convert("RGBA")
    parts = Image.open(ASSETS / "reference/weapon_parts_generated.png").convert("RGBA")
    icons = Image.new("RGBA", (SIZE * 3, SIZE * 3))
    layers = Image.new("RGBA", (SIZE * 3, SIZE * 2))
    # Generated rows are approximate; explicit object bounds keep entire grips
    # and muzzles inside each cell rather than slicing at an assumed grid line.
    layout = {}
    specs = [
        ("crown_launcher", (57, 79, 420, 421), (157, 363), (373, 164)),
        ("mouthwash_mortar", (460, 65, 840, 420), (530, 365), (797, 172)),
        ("water_jet", (873, 68, 1230, 435), (1028, 372), (1219, 82)),
        ("fluoride_sprayer", (115, 461, 410, 820), (196, 749), (381, 548)),
        ("water_turbine", (451, 472, 840, 815), (517, 755), (795, 535)),
        ("amalgam_slingshot", (877, 470, 1205, 823), None, None),
    ]
    for index, (name, box, grip, tip) in enumerate(specs):
        source = weapons.crop(box)
        fit = 448 / max(source.size)
        sprite = source.resize(tuple(round(v * fit) for v in source.size), Image.Resampling.LANCZOS)
        offset = ((SIZE - sprite.width) // 2, (SIZE - sprite.height) // 2)
        icons.alpha_composite(sprite, (index % 3 * SIZE + offset[0], index // 3 * SIZE + offset[1]))
        if grip is not None:
            def anchor(point):
                return [round((offset[axis] + (point[axis] - box[axis]) * fit) / SIZE, 5) for axis in range(2)]
            layout[name] = {"grip": anchor(grip), "tip": anchor(tip)}
    grinder = frame_body(parts, (35, 80, 680, 675), 380, (20, 80))
    polisher = frame_body(parts, (710, 65, 1240, 675), 390, (50, 85))
    fork = cell(weapons, 0, 2).resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    rotors = [trimmed(parts.crop(box)) for box in [(60, 680, 610, 1220), (675, 680, 1210, 1220)]]
    pouch = trimmed(cell(weapons, 1, 2))
    for index, body in enumerate([grinder, polisher, fork]):
        layers.alpha_composite(body, (index * SIZE, 0))
    for index, part in enumerate(rotors + [pouch]):
        # Keep circular faces circular with identical transparent cell padding.
        fit = 448 / max(part.size)
        part = part.resize(tuple(round(v * fit) for v in part.size), Image.Resampling.LANCZOS)
        layers.alpha_composite(part, (index * SIZE + (SIZE - part.width) // 2, SIZE + (SIZE - part.height) // 2))
    # Assemble shop icons from exactly the body/head layers used in combat.
    # This is asset compositing, not a repaint of the generated artwork.
    for index, (body, center, radius, angle) in enumerate([
        (grinder, (0.73, 0.205), 0.15, 25),
        (polisher, (0.73, 0.201), 0.105, 15),
    ]):
        icon = body.copy()
        head = cell(layers, index, 1, 3, 2)
        diameter = round(SIZE * radius * 2)
        head = head.resize((round(diameter * 0.65), diameter), Image.Resampling.LANCZOS)
        head = head.rotate(angle, Image.Resampling.BICUBIC, expand=True)
        icon.alpha_composite(head, (round(center[0] * SIZE - head.width / 2), round(center[1] * SIZE - head.height / 2)))
        icons.alpha_composite(icon, (index * SIZE, SIZE * 2))
    icons.save(ASSETS / "weapon_icons_refined.png")
    layers.save(ASSETS / "weapon_animation_parts.png")
    (ASSETS / "reference/weapon_art_layout.json").write_text(json.dumps(layout, indent=2) + "\n")
    print("Packed eight weapon icons and six animation layers; source images preserved.")


if __name__ == "__main__":
    main()
