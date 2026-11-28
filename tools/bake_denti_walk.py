"""Pack the approved Denti turnarounds into uniformly aligned in-game atlases."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "art"
DESTINATION = ROOT / "assets" / "denti" / "locomotion"
CLASS_IDS = (
    "good_old_molar",
    "assassin",
    "tooth_fairy",
    "ember",
    "rinser",
    "frost_warden",
    "necrodent",
    "herb_druid",
)
EAST_ART = {"tooth_fairy", "rinser", "frost_warden"}
CELL_WIDTH, CELL_HEIGHT = 224, 192
BODY_HEIGHT = 150
ALPHA_MASK = [0] * 32 + [255] * 224


def cells(path: Path, columns: int, rows: int, count: int) -> list[Image.Image]:
    with Image.open(path) as source:
        atlas = source.convert("RGBA")
    if atlas.width % columns or atlas.height % rows:
        raise ValueError(f"Uneven cell sizes in {path}")
    width, height = atlas.width // columns, atlas.height // rows
    result = []
    for index in range(count):
        x, y = (index % columns) * width, (index // columns) * height
        result.append(atlas.crop((x, y, x + width, y + height)))
    return result


def align(pose: Image.Image) -> Image.Image:
    alpha = pose.getchannel("A").point(ALPHA_MASK)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("An expected turnaround pose is empty")
    left, top, right, bottom = bounds
    height = bottom - top
    soles = alpha.crop((left, bottom - max(1, round(height * 0.10)), right, bottom)).getbbox()
    foot_x = (soles[0] + soles[2]) * 0.5
    factor = BODY_HEIGHT / height
    scaled = pose.crop(bounds).resize((round((right - left) * factor), BODY_HEIGHT), Image.Resampling.LANCZOS)
    x = round(CELL_WIDTH * 0.5 - foot_x * factor)
    y = (CELL_HEIGHT - BODY_HEIGHT) // 2
    if x < 0 or x + scaled.width > CELL_WIDTH:
        raise ValueError(f"Pose extends beyond its {CELL_WIDTH}-pixel cell")
    cell = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT))
    cell.paste(scaled, (x, y))
    return cell


def bake(class_id: str) -> None:
    filename = "denti" if class_id == "good_old_molar" else class_id
    south, southwest, west, northwest, north = cells(SOURCE / f"{filename}_turnaround_prototype.png", 3, 2, 5)
    if class_id == "good_old_molar":
        south, southwest = cells(SOURCE / "denti_expression_walk_bodies.png", 2, 1, 2)
    northeast, east, southeast = (
        cells(SOURCE / f"{filename}_east_turnaround_prototype.png", 2, 2, 3)
        if class_id in EAST_ART
        else (pose.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for pose in (northwest, west, southwest))
    )
    atlas = Image.new("RGBA", (CELL_WIDTH * 4, CELL_HEIGHT * 2))
    for index, pose in enumerate((north, northeast, east, southeast, south, southwest, west, northwest)):
        atlas.paste(align(pose), ((index % 4) * CELL_WIDTH, (index // 4) * CELL_HEIGHT))
    atlas.save(DESTINATION / f"{class_id}.png", optimize=True)


if __name__ == "__main__":
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for class_id in CLASS_IDS:
        bake(class_id)
