from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[2]
ART_ROOT = PROJECT_ROOT / "art"
OUTPUT_ROOT = ART_ROOT / "generated" / "character_one_robot"


@dataclass(frozen=True)
class SheetSpec:
    source_name: str
    animation_name: str
    columns: int
    rows: int
    active_cells: tuple[int, ...] | None = None
    inset_x: float = 0.03
    inset_y: float = 0.03
    background_profile: str = "plain"


SPECS: tuple[SheetSpec, ...] = (
    SheetSpec("Mc Idle.png", "idle", 2, 3),
    SheetSpec("Walking W.png", "move_up", 5, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("Walking S.png", "move_down", 6, 2, active_cells=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), inset_x=0.02, inset_y=0.04),
    SheetSpec("Walking A.png", "move_left", 4, 2, inset_x=0.02, inset_y=0.04, background_profile="complex"),
    SheetSpec("Walking D.png", "move_right", 4, 2, inset_x=0.02, inset_y=0.04, background_profile="complex"),
    SheetSpec("Walking WyA.png", "move_up_left", 4, 2, inset_x=0.02, inset_y=0.04, background_profile="complex"),
    SheetSpec("Walking WyD.png", "move_up_right", 5, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("Walking AyS.png", "move_down_left", 6, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("Walking SyD.png", "move_down_right", 8, 1, inset_x=0.02, inset_y=0.05),
)

MIN_COMPONENT_PIXELS = 160
BOTTOM_PADDING = 12
SIDE_PADDING = 10
TARGET_SUBJECT_HEIGHT = 620


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    all_frames: dict[str, list[Image.Image]] = {}
    max_width = 0
    max_height = 0

    for spec in SPECS:
        frames = extract_sheet_frames(spec)
        if not frames:
            raise RuntimeError(f"No frames extracted from {spec.source_name}")

        frames = normalize_animation_height(frames)
        all_frames[spec.animation_name] = frames
        for frame in frames:
            max_width = max(max_width, frame.width)
            max_height = max(max_height, frame.height)

    canvas_width = max_width + SIDE_PADDING * 2
    canvas_height = max_height + BOTTOM_PADDING * 2

    for animation_name, frames in all_frames.items():
        animation_dir = OUTPUT_ROOT / animation_name
        animation_dir.mkdir(parents=True, exist_ok=True)
        clear_png_files(animation_dir)

        for frame_index, frame in enumerate(frames):
            aligned_frame = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
            paste_x = (canvas_width - frame.width) // 2
            paste_y = canvas_height - frame.height - BOTTOM_PADDING
            aligned_frame.alpha_composite(frame, (paste_x, paste_y))
            aligned_frame.save(animation_dir / f"frame_{frame_index:02d}.png")

    write_preview_sheet(all_frames, canvas_width, canvas_height)


def extract_sheet_frames(spec: SheetSpec) -> list[Image.Image]:
    source_path = ART_ROOT / spec.source_name
    sheet_image = Image.open(source_path).convert("RGBA")

    column_edges = split_edges(sheet_image.width, spec.columns)
    row_edges = split_edges(sheet_image.height, spec.rows)

    frames: list[Image.Image] = []
    active_cells = set(spec.active_cells) if spec.active_cells is not None else None

    for row_index in range(spec.rows):
        for column_index in range(spec.columns):
            cell_index = row_index * spec.columns + column_index
            if active_cells is not None and cell_index not in active_cells:
                continue

            left = column_edges[column_index]
            top = row_edges[row_index]
            right = column_edges[column_index + 1]
            bottom = row_edges[row_index + 1]

            inset_x = int((right - left) * spec.inset_x)
            inset_y = int((bottom - top) * spec.inset_y)
            cell_image = sheet_image.crop((left + inset_x, top + inset_y, right - inset_x, bottom - inset_y))

            frame = crop_largest_subject(cell_image, spec.background_profile)
            if frame is None:
                continue

            frames.append(frame)

    return frames


def normalize_animation_height(frames: list[Image.Image]) -> list[Image.Image]:
    average_height = sum(frame.height for frame in frames) / len(frames)
    scale = TARGET_SUBJECT_HEIGHT / average_height

    if abs(scale - 1.0) < 0.05:
        return frames

    normalized_frames: list[Image.Image] = []
    for frame in frames:
        target_width = max(1, round(frame.width * scale))
        target_height = max(1, round(frame.height * scale))
        normalized_frames.append(frame.resize((target_width, target_height), Image.Resampling.NEAREST))

    return normalized_frames


def split_edges(total_size: int, slices: int) -> list[int]:
    return [round(total_size * index / slices) for index in range(slices + 1)]


def crop_largest_subject(cell_image: Image.Image, background_profile: str) -> Image.Image | None:
    width, height = cell_image.size
    pixels = cell_image.load()

    border_samples = sample_border_pixels(pixels, width, height)
    if not border_samples:
        return None

    brightest_samples = select_brightest_samples(border_samples)
    avg_r = sum(sample[0] for sample in brightest_samples) / len(brightest_samples)
    avg_g = sum(sample[1] for sample in brightest_samples) / len(brightest_samples)
    avg_b = sum(sample[2] for sample in brightest_samples) / len(brightest_samples)
    avg_luma = (avg_r + avg_g + avg_b) / 3.0

    background_mask = flood_fill_background(pixels, width, height, avg_r, avg_g, avg_b, avg_luma, background_profile)
    mask = [[False for _ in range(width)] for _ in range(height)]
    has_foreground = False

    for y in range(height):
        for x in range(width):
            if background_mask[y][x]:
                continue
            if pixels[x, y][3] == 0:
                continue
            mask[y][x] = True
            has_foreground = True

    if not has_foreground:
        return None

    component = select_subject_component(mask)
    if component is None:
        return None

    pixel_count, left, top, right, bottom = component
    cropped_image = Image.new("RGBA", (right - left + 1, bottom - top + 1), (0, 0, 0, 0))
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            if mask[y][x]:
                cropped_image.putpixel((x - left, y - top), pixels[x, y])

    return cropped_image


def sample_border_pixels(pixels, width: int, height: int) -> list[tuple[int, int, int]]:
    samples: list[tuple[int, int, int]] = []
    inset = max(2, min(width, height) // 24)

    for x in range(width):
        samples.append(pixels[x, inset][:3])
        samples.append(pixels[x, height - inset - 1][:3])

    for y in range(height):
        samples.append(pixels[inset, y][:3])
        samples.append(pixels[width - inset - 1, y][:3])

    return samples


def select_brightest_samples(samples: Iterable[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    ordered_samples = sorted(samples, key=lambda sample: sample[0] + sample[1] + sample[2], reverse=True)
    cutoff = max(8, len(ordered_samples) // 3)
    return ordered_samples[:cutoff]


def flood_fill_background(
    pixels,
    width: int,
    height: int,
    avg_r: float,
    avg_g: float,
    avg_b: float,
    avg_luma: float,
    background_profile: str,
) -> list[list[bool]]:
    background_mask = [[False for _ in range(width)] for _ in range(height)]
    queue = deque()

    def enqueue_if_background_like(x: int, y: int) -> None:
        if background_mask[y][x]:
            return
        red, green, blue, alpha = pixels[x, y]
        if alpha == 0:
            background_mask[y][x] = True
            return
        if is_background_like(red, green, blue, avg_r, avg_g, avg_b, avg_luma, background_profile):
            background_mask[y][x] = True
            queue.append((x, y))

    for x in range(width):
        enqueue_if_background_like(x, 0)
        enqueue_if_background_like(x, height - 1)

    for y in range(height):
        enqueue_if_background_like(0, y)
        enqueue_if_background_like(width - 1, y)

    while queue:
        current_x, current_y = queue.popleft()
        for next_x, next_y in (
            (current_x - 1, current_y),
            (current_x + 1, current_y),
            (current_x, current_y - 1),
            (current_x, current_y + 1),
        ):
            if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                continue
            if background_mask[next_y][next_x]:
                continue

            red, green, blue, alpha = pixels[next_x, next_y]
            if alpha == 0 or is_background_like(red, green, blue, avg_r, avg_g, avg_b, avg_luma, background_profile):
                background_mask[next_y][next_x] = True
                queue.append((next_x, next_y))

    return background_mask


def is_background_like(
    red: int,
    green: int,
    blue: int,
    avg_r: float,
    avg_g: float,
    avg_b: float,
    avg_luma: float,
    background_profile: str,
) -> bool:
    brightness = (red + green + blue) / 3.0
    colorfulness = max(red, green, blue) - min(red, green, blue)
    distance = abs(red - avg_r) + abs(green - avg_g) + abs(blue - avg_b)

    if background_profile == "complex":
        if distance <= 58 and colorfulness <= 34:
            return True
        if brightness >= avg_luma - 26 and colorfulness <= 18:
            return True
        if brightness >= avg_luma - 12 and colorfulness <= 32:
            return True
        return False

    if distance <= 58 and colorfulness <= 34:
        return True
    if brightness >= avg_luma - 26 and colorfulness <= 18:
        return True
    if brightness >= avg_luma - 12 and colorfulness <= 32:
        return True

    return False


def select_subject_component(mask: list[list[bool]]) -> tuple[int, int, int, int, int] | None:
    height = len(mask)
    width = len(mask[0]) if height > 0 else 0
    visited = [[False for _ in range(width)] for _ in range(height)]
    best_component: tuple[int, int, int, int, int] | None = None
    best_score = -1.0

    for y in range(height):
        for x in range(width):
            if mask[y][x] is False or visited[y][x]:
                continue

            queue = deque([(x, y)])
            visited[y][x] = True
            pixel_count = 0
            left = x
            top = y
            right = x
            bottom = y

            while queue:
                current_x, current_y = queue.popleft()
                pixel_count += 1
                left = min(left, current_x)
                top = min(top, current_y)
                right = max(right, current_x)
                bottom = max(bottom, current_y)

                for next_x, next_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                        continue
                    if mask[next_y][next_x] is False or visited[next_y][next_x]:
                        continue

                    visited[next_y][next_x] = True
                    queue.append((next_x, next_y))

            component = (pixel_count, left, top, right, bottom)
            score = score_component(component, width, height)
            if score <= 0.0:
                continue

            if best_component is None or score > best_score:
                best_component = component
                best_score = score

    return best_component


def score_component(component: tuple[int, int, int, int, int], cell_width: int, cell_height: int) -> float:
    pixel_count, left, top, right, bottom = component
    if pixel_count < MIN_COMPONENT_PIXELS:
        return 0.0

    bbox_width = right - left + 1
    bbox_height = bottom - top + 1
    if bbox_width < cell_width * 0.12 or bbox_height < cell_height * 0.35:
        return 0.0

    bbox_area = bbox_width * bbox_height
    density = pixel_count / float(bbox_area)
    if density < 0.12:
        return 0.0

    touches_edge = int(left <= 1) + int(top <= 1) + int(right >= cell_width - 2) + int(bottom >= cell_height - 2)
    score = pixel_count * density

    if touches_edge >= 2:
        score *= 0.55
    elif touches_edge == 1:
        score *= 0.8

    if bbox_width > cell_width * 0.9 and density < 0.25:
        score *= 0.25

    return score


def write_preview_sheet(all_frames: dict[str, list[Image.Image]], canvas_width: int, canvas_height: int) -> None:
    ordered_animation_names = [spec.animation_name for spec in SPECS]
    max_frames = max(len(frames) for frames in all_frames.values())
    preview = Image.new(
        "RGBA",
        (canvas_width * max_frames, canvas_height * len(ordered_animation_names)),
        (9, 14, 28, 255),
    )

    for row_index, animation_name in enumerate(ordered_animation_names):
        for column_index, frame in enumerate(all_frames[animation_name]):
            aligned_frame = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
            paste_x = (canvas_width - frame.width) // 2
            paste_y = canvas_height - frame.height - BOTTOM_PADDING
            aligned_frame.alpha_composite(frame, (paste_x, paste_y))
            preview.alpha_composite(aligned_frame, (column_index * canvas_width, row_index * canvas_height))

    preview.save(OUTPUT_ROOT / "preview.png")


def clear_png_files(directory: Path) -> None:
    for png_file in directory.glob("*.png"):
        png_file.unlink()


if __name__ == "__main__":
    main()
