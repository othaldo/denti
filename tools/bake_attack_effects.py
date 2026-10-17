"""Offline, deterministic masks for textured combat effects. No runtime raster work."""
from math import sin, cos, exp, pi, hypot, atan2
from pathlib import Path
from PIL import Image

CELL_W, CELL_H, FRAMES = 256, 128, 4


def bell(value, width):
    return exp(-((value / width) ** 2))


def bake():
    atlas = Image.new("RGBA", (CELL_W * FRAMES, 1680))
    for kind in (4, 7):  # Aiming wisps and active movement afterimages.
        for frame in range(FRAMES):
            phase = frame * 2 * pi / FRAMES
            tile = Image.new("RGBA", (CELL_W, CELL_H))
            pixels = tile.load()
            for y in range(2, CELL_H - 2):
                v = (y + .5 - CELL_H / 2) / 56
                for x in range(2, CELL_W - 2):
                    u = (x + .5 - 8) / 240
                    if u <= 0 or u >= 1:
                        continue
                    ends = min(1, u * 32, (1 - u) * 32)
                    if kind == 4:
                        dash = max(0, sin(u * 39 - phase)) ** 6
                        alpha = (bell(v, .085) * dash * .95 + bell(v, .24) * .24) * ends
                        shine = dash * bell(v, .06)
                    else:
                        alpha = (bell(v, .1 + u * .17) * .75 + bell(v, .65) * .17) * u * ends
                        alpha += bell(v - sin(u * 24 - phase) * .35, .025) * u * .3 * ends
                        shine = bell(v, .09) * u
                    alpha = max(0, min(1, alpha))
                    pixels[x, y] = (int(220 + 35 * shine), int(231 + 24 * shine), 255, round(alpha * 255))
            atlas.paste(tile, (frame * CELL_W, kind * CELL_H))
    pack_painted(atlas)
    pack_ground(atlas)
    pack_warnings(atlas)
    target = Path(__file__).resolve().parents[1] / "assets/vfx/attack_effects.png"
    atlas.save(target)
    print(f"Attack atlas: {atlas.size}, {target.stat().st_size} bytes")


def pack_painted(atlas):
    """Crop/pack generated art; never load the large reference sheet in combat."""
    source = Image.open(Path(__file__).resolve().parents[1] / "assets/vfx/attack_art_source.png").convert("RGBA")
    # Atlas row, source cell, horizontal flow origin. Preserve the source art.
    for row, column, source_row, center_y in [(0, 0, 0, 316), (8, 1, 0, 318), (1, 0, 1, 255), (2, 1, 1, 255), (5, 2, 1, 255), (6, 2, 0, 318)]:
        original = source.crop((column * 512, source_row * 512, (column + 1) * 512, (source_row + 1) * 512))
        # Align flow emission with the quad center line, retaining all margins.
        crop = Image.new("RGBA", (512, 640))
        crop.paste(original, (0, 320 - center_y))
        small = crop.resize((240, 112), Image.Resampling.LANCZOS)
        # An impact is a neutral flash tinted by its caller.
        if row == 5:
            from PIL import ImageOps
            alpha = small.getchannel("A")
            small = ImageOps.grayscale(small).convert("RGBA")
            small.putalpha(alpha)
        for frame in range(FRAMES):
            tile = Image.new("RGBA", (CELL_W, CELL_H))
            # Small column offsets animate flow without an emitter or live shader.
            for x in range(240):
                offset = 0 if row == 5 else round(sin(x / 240 * pi * 4 - frame * pi / 2) * 1.5)
                tile.paste(small.crop((x, 0, x + 1, 112)), (8 + x, 8 + offset))
            # Transparent gutters and soft endpoints eliminate cell seams.
            data = tile.load()
            for y in range(CELL_H):
                for x in range(CELL_W):
                    red, green, blue, alpha = data[x, y]
                    fade = max(0, min(1, (x - 8) / 5, (248 - x) / 5, (y - 2) / 5, (125 - y) / 5))
                    data[x, y] = (red, green, blue, round(alpha * fade))
            atlas.paste(tile, (frame * CELL_W, row * CELL_H))


def pack_warnings(atlas):
    # Timer rings share the SAME texture as lanes, preserving enemy batching.
    for step in range(65):
        tile = Image.new("RGBA", (80, 80))
        pixels = tile.load()
        for y in range(80):
            for x in range(80):
                dx, dy = x + .5 - 40, y + .5 - 40
                angle = (atan2(dy, dx) + pi / 2) % (2 * pi)
                if step == 0 or angle > step / 64 * 2 * pi:
                    continue
                distance = hypot(dx, dy) - 32
                core = bell(distance, .8)
                alpha = min(1, core * .9 + bell(distance, 1.7) * .45)
                light = .25 + .75 * core
                pixels[x, y] = (round(255 * light), round(255 * light), round(255 * light), round(alpha * 255))
        atlas.paste(tile, ((step % 12) * 80, 1152 + (step // 12) * 80))
    root = Path(__file__).resolve().parents[1]
    danger = Image.open(root / "assets/vfx/ground_effects.png").crop((768, 0, 1152, 384))
    atlas.paste(danger.resize((128, 128), Image.Resampling.LANCZOS), (480, 1552))


def pack_ground(atlas):
    from PIL import ImageOps
    source = Image.open(Path(__file__).resolve().parents[1] / "assets/vfx/charge_ground_source.png").convert("RGBA")
    # Prepare a neutral, tintable decal, preserving the painted branching cracks.
    patch = source.crop((0, 200, 1536, 840)).resize((240, 112), Image.Resampling.LANCZOS)
    luminance = ImageOps.grayscale(patch)
    for frame in range(FRAMES):
        tile = Image.new("RGBA", (256, 128))
        pixels = tile.load()
        for y in range(112):
            v = (y + .5 - 56) / 56
            # No continuous rails. The decal fades at the nominal threat width.
            edge = max(0, min(1, (.86 - abs(v)) / .12))
            for x in range(240):
                u = (x + .5) / 240
                ends = min(1, u * 24, (1 - u) * 24)
                red, green, blue, alpha = patch.getpixel((x, y))
                value = luminance.getpixel((x, y)) / 255
                pressure = .5 + .5 * cos(u * pi * 8 - frame * pi / 2)
                light = min(1, .13 + value * (1.35 + pressure * .2))
                opacity = min(.62, alpha / 255 * .65) * edge * ends
                # An even faint underlay keeps the full width readable.
                opacity = max(opacity, .07 * edge * ends)
                pixels[x + 8, y + 8] = (round(light * 255), round(light * 255), round(light * 255), round(opacity * 255))
        atlas.paste(tile, (frame * 256, 3 * 128))


if __name__ == "__main__":
    bake()
