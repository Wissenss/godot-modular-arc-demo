from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
DATA_PATH = ROOT / "art" / "generated" / "brunich" / "mc_face_expressions.json"
OUT_DIR = ROOT / "Narrativa" / "preview" / "faces"

BG = "#07101c"
PANEL = "#0d1629"
GRID = "#13203a"
PIXEL = "#f6fbff"
TITLE = "#e6ecfb"
MUTED = "#95a4c7"
ACCENT = "#7fe7ff"

CELL = 128
PX = 6
MARGIN = 28
COLUMNS = 5


def load_faces() -> dict[str, list[list[int]]]:
    with DATA_PATH.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    return data["expressions"]


def draw_face(canvas: ImageDraw.ImageDraw, origin_x: int, origin_y: int, pixels: list[list[int]]) -> None:
    canvas.rounded_rectangle(
        (origin_x + 16, origin_y + 16, origin_x + 112, origin_y + 112),
        radius=10,
        fill=PANEL,
        outline="#27466d",
        width=2,
    )
    canvas.rounded_rectangle(
        (origin_x + 24, origin_y + 24, origin_x + 104, origin_y + 104),
        radius=8,
        fill="#081120",
    )

    for px_x, px_y in pixels:
        x = origin_x + 64 + px_x * PX
        y = origin_y + 62 + px_y * PX
        canvas.rectangle((x - PX // 2, y - PX // 2, x + PX // 2, y + PX // 2), fill=PIXEL)


def build_sheet(faces: dict[str, list[list[int]]]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    rows = (len(faces) + COLUMNS - 1) // COLUMNS
    width = MARGIN * 2 + COLUMNS * CELL
    height = MARGIN * 2 + rows * CELL + 80
    sheet = Image.new("RGBA", (width, height), BG)
    draw = ImageDraw.Draw(sheet)

    try:
        font_title = ImageFont.truetype("arial.ttf", 24)
        font_label = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font_title = ImageFont.load_default()
        font_label = ImageFont.load_default()

    draw.text((MARGIN, 18), "MC Face Expressions", fill=TITLE, font=font_title)
    draw.text((MARGIN, 48), "Preview sheet generado desde mc_face_expressions.json", fill=MUTED, font=font_label)

    for index, (name, pixels) in enumerate(faces.items()):
        col = index % COLUMNS
        row = index // COLUMNS
        ox = MARGIN + col * CELL
        oy = 80 + row * CELL

        draw.rounded_rectangle(
            (ox + 4, oy + 4, ox + CELL - 8, oy + CELL - 8),
            radius=16,
            fill=GRID,
            outline="#20304d",
            width=1,
        )
        draw_face(draw, ox, oy, pixels)
        draw.text((ox + 12, oy + CELL - 24), name, fill=ACCENT, font=font_label)

        single = Image.new("RGBA", (128, 128), BG)
        single_draw = ImageDraw.Draw(single)
        draw_face(single_draw, 0, 0, pixels)
        single_draw.text((8, 104), name, fill=ACCENT, font=font_label)
        single.save(OUT_DIR / f"{name}.png")

    sheet.save(OUT_DIR / "_sheet.png")


if __name__ == "__main__":
    build_sheet(load_faces())
