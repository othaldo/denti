"""Compile approved paintings into runtime sprites and rigs, without repainting.

python tools/pack_weapon_skins.py
Requires Pillow. Originals under reference/element_forms remain byte-identical.
All seven forms share one source crop, scale and canvas per weapon. Animation
parts are mechanically extracted from each painting, not from the old atlases.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import re

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/weapons/reference/element_forms"
OUTPUT = ROOT / "assets/weapons/element_forms"
DATA = ROOT / "data/weapon_skins"
KINDS = ("normal", "fire", "ice", "poison", "electric", "bleed", "wet")
SIZE = 512
CONTENT = 472


def vector(point):
    return "Vector2(%.6f, %.6f)" % tuple(point)


def texture_import(path):
    sidecar = Path(str(path) + ".import")
    if sidecar.exists():
        text = sidecar.read_text(encoding="utf-8")
        text = text.replace("mipmaps/generate=false", "mipmaps/generate=true")
    else:
        relative = "res://" + path.relative_to(ROOT).as_posix()
        text = ('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                '[deps]\nsource_file="' + relative + '"\n\n[params]\n'
                'compress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=true\n')
    sidecar.write_text(text, encoding="utf-8")


def save(image, path):
    image.save(path, optimize=True)
    texture_import(path)


def ellipse_mask(size, center, radii, angle):
    # Exact matching sampling transforms keep the stationary axle and rotating
    # face registered. Supersampling is only edge antialiasing of this mask.
    scale = 3
    width, height = size
    mask = Image.new("L", (width * scale, height * scale))
    points = []
    for step in range(180):
        phase = step * math.tau / 180
        x, y = radii[0] * math.cos(phase), radii[1] * math.sin(phase)
        points.append(((center[0] + x * math.cos(angle) - y * math.sin(angle)) * scale,
                       (center[1] + x * math.sin(angle) + y * math.cos(angle)) * scale))
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask.resize(size, Image.Resampling.LANCZOS)


def rotor_layers(image, spec):
    center, radii = spec["center"], spec["radii"]
    angle = math.radians(spec["angle"])
    diameter = 256
    # Unproject the existing painted face into a circle. The runtime node then
    # spins that circle before applying the original elliptical perspective.
    a = 2 * radii[0] * math.cos(angle) / diameter
    b = -2 * radii[1] * math.sin(angle) / diameter
    d = 2 * radii[0] * math.sin(angle) / diameter
    e = 2 * radii[1] * math.cos(angle) / diameter
    face = image.transform((diameter, diameter), Image.Transform.AFFINE,
                           (a, b, center[0] - (a + b) * diameter / 2,
                            d, e, center[1] - (d + e) * diameter / 2), Image.Resampling.BICUBIC)
    disk = ellipse_mask(face.size, (diameter / 2, diameter / 2), (diameter / 2 - 1,) * 2, 0)
    face.putalpha(ImageChops.multiply(face.getchannel("A"), disk))
    body = image.copy()
    hole = ellipse_mask(image.size, center, (radii[0] - 2, radii[1] - 2), angle)
    body.putalpha(ImageChops.multiply(body.getchannel("A"), ImageChops.invert(hole)))
    return body, face


def sling_layers(image, spec):
    # Extract the painted pouch; the existing elastic component draws the two
    # live straps. The split follows the inside of the stationary ivory fork.
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).polygon(spec["pouch_polygon"], fill=255)
    pouch = image.copy()
    pouch.putalpha(ImageChops.multiply(image.getchannel("A"), mask))
    box = mask.getbbox()
    pouch = pouch.crop(box)
    body = image.copy()
    void = Image.new("L", image.size)
    ImageDraw.Draw(void).polygon(spec["interior_polygon"], fill=255)
    body.putalpha(ImageChops.multiply(body.getchannel("A"), ImageChops.invert(void)))
    return body, pouch, box


def build_pack(weapon_id, rig):
    source_folder = SOURCE / weapon_id
    folder = OUTPUT / weapon_id
    resource_folder = DATA / weapon_id
    folder.mkdir(parents=True, exist_ok=True)
    resource_folder.mkdir(parents=True, exist_ok=True)
    originals = {kind: Image.open(source_folder / (kind + ".png")).convert("RGBA") for kind in KINDS}
    bounds = [im.getchannel("A").point(lambda v: 255 if v >= 16 else 0).getbbox() for im in originals.values()]
    crop = (max(0, min(b[0] for b in bounds) - 6), max(0, min(b[1] for b in bounds) - 6),
            min(1024, max(b[2] for b in bounds) + 6), min(1536, max(b[3] for b in bounds) + 6))
    fit = CONTENT / max(crop[2] - crop[0], crop[3] - crop[1])
    fitted = (round((crop[2] - crop[0]) * fit), round((crop[3] - crop[1]) * fit))
    offset = ((SIZE - fitted[0]) // 2, (SIZE - fitted[1]) // 2)
    normal_bounds = originals["normal"].getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()

    def source_point(relative):
        return [normal_bounds[i] + relative[i] * (normal_bounds[i + 2] - normal_bounds[i]) for i in (0, 1)]

    def anchor(point):
        return [(offset[i] + (point[i] - crop[i]) * fit) / SIZE for i in (0, 1)]

    def frame(im):
        result = Image.new("RGBA", (SIZE, SIZE))
        resized = im.crop(crop).resize(fitted, Image.Resampling.LANCZOS)
        result.alpha_composite(resized, offset)
        return result

    base_fields = {}
    source_hashes = {}
    normal_span = 0
    for kind, original in originals.items():
        fields = {"grip_anchor": vector(anchor(source_point(rig["grip"]))),
                  "tip_anchor": vector(anchor(source_point(rig["tip"])))}
        image = frame(original)
        save(image, folder / (kind + ".png"))
        # Combat keeps the shared rig canvas. UI gets a per-form AtlasTexture
        # crop so additional flames/spikes cannot push the normal icon off center.
        visible = image.getchannel("A").point(lambda v: 255 if v >= 16 else 0).getbbox()
        icon_region = (max(0, visible[0] - 3), max(0, visible[1] - 3),
                       min(SIZE, visible[2] + 3), min(SIZE, visible[3] + 3))
        region_text = "Rect2(%d, %d, %d, %d)" % (icon_region[0], icon_region[1],
                       icon_region[2] - icon_region[0], icon_region[3] - icon_region[1])
        textures = {"sprite": kind + ".png", "held_sprite": kind + ".png"}
        if "floss_cut" in rig:
            spec = rig["floss_cut"]
            part_scale = SIZE / spec["canvas"]
            for side in ("left", "right"):
                if side + "_polygon" not in spec:
                    continue
                mask = Image.new("L", (SIZE, SIZE))
                ImageDraw.Draw(mask).polygon([tuple(round(v * part_scale) for v in p) for p in spec[side + "_polygon"]], fill=255)
                grip = image.copy()
                grip.putalpha(ImageChops.multiply(image.getchannel("A"), mask))
                filename = kind + "_" + side + "_grip.png"
                save(grip, folder / filename)
                textures["floss_" + side + "_texture"] = filename
                fields["floss_" + side + "_tip"] = vector([v / spec["canvas"] for v in spec[side + "_tip"]])
        if "rotor" in rig:
            spec = rig["rotor"] | rig.get("rotor_overrides", {}).get(kind, {})
            body, head = rotor_layers(original, spec)
            save(frame(body), folder / (kind + "_body.png"))
            save(head, folder / (kind + "_head.png"))
            textures |= {"held_sprite": kind + "_body.png", "working_head_texture": kind + "_head.png"}
            fields |= {"tip_anchor": vector(anchor(spec["center"])),
                       "working_head_radius": "%.6f" % (spec["radii"][1] * fit / SIZE),
                       "working_head_aspect": "%.6f" % (spec["radii"][0] / spec["radii"][1]),
                       "working_head_angle_degrees": str(spec["angle"])}
        if "sling" in rig:
            spec = rig["sling"]
            body, pouch, box = sling_layers(original, spec)
            save(frame(body), folder / (kind + "_body.png"))
            pouch = pouch.resize((round(pouch.width * fit), round(pouch.height * fit)), Image.Resampling.LANCZOS)
            save(pouch, folder / (kind + "_pouch.png"))
            textures |= {"held_sprite": kind + "_body.png", "pull_texture": kind + "_pouch.png"}
            # A fully drawn pouch rests at its position in the approved painting.
            center = anchor(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2))
            center[1] -= 0.09
            fields |= {"tip_anchor": vector(center), "pouch_anchor": vector(center),
                       "fork_left_anchor": vector(anchor(spec["left"])),
                       "fork_right_anchor": vector(anchor(spec["right"])),
                       "pouch_width": "%.6f" % (pouch.width / SIZE)}
        ext = ['[ext_resource type="Script" path="res://scripts/weapons/weapon_skin_data.gd" id="1"]']
        texture_ids = {}
        for field, filename in textures.items():
            if filename not in texture_ids:
                number = len(ext) + 1
                texture_ids[filename] = number
                path = "res://" + (folder / filename).relative_to(ROOT).as_posix()
                ext.append(f'[ext_resource type="Texture2D" path="{path}" id="{number}"]')
            number = texture_ids[filename]
            fields[field] = f'ExtResource("{number}")'
        icon_atlas = fields["sprite"]
        fields["sprite"] = 'SubResource("Icon_skin")'
        text = f'[gd_resource type="Resource" script_class="WeaponSkinData" load_steps={len(ext) + 2} format=3]\n\n'
        text += '\n'.join(ext) + '\n\n[sub_resource type="AtlasTexture" id="Icon_skin"]\n'
        text += 'atlas = ' + icon_atlas + '\nregion = ' + region_text + '\nfilter_clip = true\n'
        text += '\n[resource]\nscript = ExtResource("1")\n'
        text += '\n'.join(key + ' = ' + value for key, value in fields.items()) + '\n'
        (resource_folder / (kind + ".tres")).write_text(text, encoding="utf-8")
        if kind == "normal":
            base_fields = {key: ("texture:" + textures[key] if key in textures else value) for key, value in fields.items()}
            normal_region = region_text
            normal_span = max(visible[2] - visible[0], visible[3] - visible[1])
        source_hashes[kind] = hashlib.sha256((source_folder / (kind + ".png")).read_bytes()).hexdigest()
    # Keep the approved visible length, independent of pack padding or ornament
    # bounds across the seven forms. This scale belongs to the weapon, not a skin.
    weapon_text = (ROOT / "data/weapons" / (weapon_id + ".tres")).read_text(encoding="utf-8")
    visual_size = re.search(r'^visual_size = ([0-9.]+)', weapon_text, re.M)
    visual_size = float(visual_size[1]) if visual_size else 58.0
    mode = re.search(r'^attack_mode = &"([^"]+)"', weapon_text, re.M)[1]
    limit = 100.0 if mode in ("melee", "area", "thrust", "sweep") else 76.0
    scale = float(rig["combat_visible_size"]) / (min(visual_size, limit) * normal_span / SIZE)
    base_fields["held_scale"] = "%.6f" % scale
    update_weapon(weapon_id, base_fields.copy(), normal_region)
    return {"source_crop": crop, "runtime_canvas": [SIZE, SIZE], "content_size": list(fitted),
            "source_sha256": source_hashes, "normal_rig": base_fields}


def update_weapon(weapon_id, fields, icon_region):
    path = ROOT / "data/weapons" / (weapon_id + ".tres")
    text = path.read_text(encoding="utf-8")
    header, body = text.split("[resource]", 1)
    # Retain gameplay declarations verbatim. All replaced ext/sub resources were
    # artwork, so obsolete atlas dependencies no longer preload old textures.
    script = re.search(r'\[ext_resource type="Script"[^\n]+\]', header).group()
    ext = [script]
    texture_ids = {}
    for key in list(fields):
        value = fields[key]
        if value.startswith("texture:"):
            filename = value.removeprefix("texture:")
            if filename not in texture_ids:
                number = len(ext) + 1
                texture_ids[filename] = number
                ext.append(f'[ext_resource type="Texture2D" path="res://assets/weapons/element_forms/{weapon_id}/{filename}" id="{number}"]')
            number = texture_ids[filename]
            fields[key] = f'ExtResource("{number}")'
        body = re.sub(r'^' + re.escape(key) + r' = [^\n]*\n?', '', body, flags=re.M)
    body = re.sub(r'^element_skins = \{.*?^\}\n?', '', body, flags=re.M | re.S)
    icon_atlas = fields["sprite"]
    fields["sprite"] = 'SubResource("Icon_skin")'
    body = body.rstrip() + '\n\n' + '\n'.join(key + ' = ' + value for key, value in fields.items())
    body += '\nelement_skins = {\n' + ',\n'.join(f'"{kind}": "res://data/weapon_skins/{weapon_id}/{kind}.tres"' for kind in KINDS[1:]) + '\n}\n'
    header = f'[gd_resource type="Resource" script_class="WeaponData" load_steps={len(ext) + 2} format=3]\n\n'
    atlas = '\n\n[sub_resource type="AtlasTexture" id="Icon_skin"]\natlas = ' + icon_atlas
    atlas += '\nregion = ' + icon_region + '\nfilter_clip = true\n'
    path.write_text(header + '\n'.join(ext) + atlas + '\n[resource]' + body, encoding="utf-8")


def main():
    layout = json.loads((DATA / "rigs.json").read_text(encoding="utf-8"))
    expected = {p.parent.name for p in SOURCE.glob("*/manifest.json")}
    assert set(layout) == expected and len(layout) == 24, "Every approved weapon needs an explicit rig"
    result = {}
    for weapon_id, rig in layout.items():
        result[weapon_id] = build_pack(weapon_id, rig)
        print("Packed", weapon_id)
    (DATA / "build_manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
    print("PASS: 168 runtime forms plus matching animation parts; source paintings preserved.")


if __name__ == "__main__":
    main()
