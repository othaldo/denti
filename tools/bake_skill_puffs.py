"""Offline, deterministic smoke puffs for animated skill clouds.

Writes assets/vfx/skill_puffs.png: four soft, top-lit puffs and two small
particles in neutral white/grey. SkillPuffs tints them at draw time, so one
atlas serves poison, frost, ember smoke, foam and other skill clouds.
No raster work happens in the game.

    python tools/bake_skill_puffs.py
    python tools/bake_skill_puffs.py --painted path/to/four_puffs.png

--painted takes a transparent image with four puffs side by side in equal
square cells (any size), fits each into its 256 px cell and keeps the baked
bubble and sparkle. Painted puffs should be neutral white/grey so tinting
works; a dark contour stays dark.
"""
import sys
from math import exp, floor, hypot, sin, cos, pi
from pathlib import Path
import random

from PIL import Image

PUFF = 256          # puff cell size; four cells in the first row
SMALL = 64          # particle cells in the second row
OUTPUT = Path(__file__).resolve().parent.parent / "assets/vfx/skill_puffs.png"
LIGHT = (-0.45, -0.62, 0.64)  # top-left and in front, matching the painted combat art


def smoothstep(edge0, edge1, value):
    t = min(max((value - edge0) / (edge1 - edge0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def hash2(ix, iy, seed):
    n = (ix * 374761393 + iy * 668265263 + seed * 982451653) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def value_noise(x, y, seed):
    ix, iy = floor(x), floor(y)
    fx, fy = x - ix, y - iy
    ux, uy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, seed), hash2(ix + 1, iy, seed)
    c, d = hash2(ix, iy + 1, seed), hash2(ix + 1, iy + 1, seed)
    return (a + (b - a) * ux) + ((c + (d - c) * ux) - (a + (b - a) * ux)) * uy


def fbm(x, y, seed):
    total, amplitude, frequency = 0.0, 0.5, 1.0
    for octave in range(4):
        total += amplitude * value_noise(x * frequency, y * frequency, seed + octave * 31)
        amplitude *= 0.5
        frequency *= 2.0
    return total * 2.0 - 0.9375  # roughly centered on zero


def puff(seed):
    """Cartoon cloud: union of sphere caps, each lobe lit on its own."""
    rng = random.Random(seed)
    lobes = [(0.0, 0.05, 0.42)]
    count = rng.randint(7, 9)
    for index in range(count):
        angle = (index + rng.uniform(-0.2, 0.2)) / count * 2 * pi
        top = max(0.0, -sin(angle))  # billows on top, flatter base
        distance = rng.uniform(0.28, 0.36) + 0.06 * top
        lobes.append((cos(angle) * distance, sin(angle) * distance * 0.72 + 0.05, rng.uniform(0.19, 0.24) + 0.04 * top))
    # Upper lobes sit in front, like a billow rolling toward the viewer.
    lobes.sort(key=lambda lobe: lobe[1], reverse=True)

    tile = Image.new("RGBA", (PUFF, PUFF))
    pixels = tile.load()
    edge = 2.5 / PUFF * 2  # anti-aliased outline width in uv units
    for y in range(PUFF):
        v = (y + 0.5) / PUFF * 2 - 1
        for x in range(PUFF):
            u = (x + 0.5) / PUFF * 2 - 1
            wobble = 0.025 * fbm(u * 6 + 2, v * 6 + 8, seed)
            best = None
            coverage = 0.0
            for lx, ly, radius in lobes:
                dx, dy = u - lx, v - ly
                r = radius * (1 + wobble)
                distance = hypot(dx, dy)
                coverage = max(coverage, smoothstep(r + edge, r - edge, distance))
                if distance < r:
                    # Flattened caps read as soft gas instead of hard balls.
                    height = (1 - (distance / r) ** 2) ** 0.5 * 0.7 + 0.3
                    # Front-most (last sorted) covering lobe wins.
                    best = (dx / r, dy / r, height, distance / r)
            if coverage <= 0.004:
                continue
            if best is None:
                # Outline fringe: use the nearest lobe edge as a rim.
                best = (0.0, 0.0, 0.05, 1.0)
            nx, ny, nz, rel = best
            length = (nx * nx * 0.45 + ny * ny * 0.45 + nz * nz) ** 0.5
            lambert = max(0.0, (nx * 0.67 * LIGHT[0] + ny * 0.67 * LIGHT[1] + nz * LIGHT[2]) / length)
            crevice = smoothstep(0.82, 1.0, rel)  # gentle shade where lobes meet
            # Whole-cloud gradient: lighter top-left, denser bottom.
            body = 0.1 * (-(u * 0.5 + v * 0.8))
            lum = 0.6 + 0.3 * lambert + body - 0.07 * crevice + 0.035 * fbm(u * 10, v * 10, seed + 7)
            # Soft translucency toward the outer silhouette.
            alpha = coverage * (0.8 + 0.2 * (1 - smoothstep(0.55, 0.98, hypot(u, v * 1.1))))
            # Painted-art contour: a slightly darker rim on the silhouette.
            lum -= 0.22 * (1 - coverage) ** 0.5 * (1 if coverage < 0.98 else 0)
            value = int(min(max(lum, 0.0), 1.0) * 255)
            pixels[x, y] = (value, value, value, int(alpha * 255))
    return tile


def bubble():
    tile = Image.new("RGBA", (SMALL, SMALL))
    pixels = tile.load()
    radius = SMALL * 0.38
    for y in range(SMALL):
        for x in range(SMALL):
            dx, dy = x + 0.5 - SMALL / 2, y + 0.5 - SMALL / 2
            r = hypot(dx, dy) / radius
            if r > 1.08:
                continue
            rim = exp(-((r - 0.9) / 0.11) ** 2)
            body = 0.22 * smoothstep(1.02, 0.6, r)
            shine = exp(-(((dx + radius * 0.38) ** 2 + (dy + radius * 0.4) ** 2) / (radius * 0.2) ** 2))
            alpha = min(1.0, rim * 0.95 + body + shine)
            value = int(255 * min(1.0, 0.82 + 0.18 * shine + 0.1 * rim))
            pixels[x, y] = (value, value, value, int(alpha * 255))
    return tile


def sparkle():
    tile = Image.new("RGBA", (SMALL, SMALL))
    pixels = tile.load()
    for y in range(SMALL):
        for x in range(SMALL):
            dx, dy = (x + 0.5 - SMALL / 2) / (SMALL / 2), (y + 0.5 - SMALL / 2) / (SMALL / 2)
            core = exp(-(dx * dx + dy * dy) / 0.02)
            rays = exp(-(dx * dx) / 0.0016) * exp(-(dy * dy) / 0.35) + exp(-(dy * dy) / 0.0016) * exp(-(dx * dx) / 0.35)
            glow = exp(-(dx * dx + dy * dy) / 0.12) * 0.35
            alpha = min(1.0, core + rays * 0.8 + glow)
            pixels[x, y] = (255, 255, 255, int(alpha * 255))
    return tile


def painted_puffs(path):
    source = Image.open(path).convert("RGBA")
    cell = source.width // 4
    result = []
    for index in range(4):
        tile = source.crop((index * cell, 0, (index + 1) * cell, source.height))
        bounds = tile.getbbox()
        if bounds is None:
            raise SystemExit(f"Painted cell {index} is empty")
        tile = tile.crop(bounds)
        # Fit into 92 % of the cell so filtering never bleeds into neighbours.
        scale = PUFF * 0.92 / max(tile.size)
        tile = tile.resize((max(1, round(tile.width * scale)), max(1, round(tile.height * scale))), Image.LANCZOS)
        framed = Image.new("RGBA", (PUFF, PUFF))
        framed.alpha_composite(tile, ((PUFF - tile.width) // 2, (PUFF - tile.height) // 2))
        result.append(framed)
    return result


def bake(painted=None):
    atlas = Image.new("RGBA", (PUFF * 4, PUFF + SMALL))
    puffs = painted_puffs(painted) if painted else [puff(seed) for seed in (11, 23, 37, 53)]
    for index, tile in enumerate(puffs):
        atlas.alpha_composite(tile, (index * PUFF, 0))
    atlas.alpha_composite(bubble(), (0, PUFF))
    atlas.alpha_composite(sparkle(), (SMALL, PUFF))
    atlas.save(OUTPUT)
    print("Saved", OUTPUT, atlas.size)


if __name__ == "__main__":
    arguments = sys.argv[1:]
    bake(arguments[1] if len(arguments) == 2 and arguments[0] == "--painted" else None)
