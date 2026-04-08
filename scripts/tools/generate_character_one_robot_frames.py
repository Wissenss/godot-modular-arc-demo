from __future__ import annotations

from collections import deque
from dataclasses import dataclass
import math
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
    extract_mode: str = "grid"


@dataclass(frozen=True)
class PreparedFrame:
    image: Image.Image
    head_center_x: float
    head_top: int
    head_width: int
    head_height: int
    body_bottom: int


@dataclass(frozen=True)
class CanvasLayout:
    width: int
    height: int
    anchor_x: float
    anchor_y: int


SPECS: tuple[SheetSpec, ...] = (
    SheetSpec("Mc Idle.png", "idle", 2, 3, inset_y=0.08),
    SheetSpec("Walking W.png", "move_up", 5, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("Walking S.png", "move_down", 6, 2, active_cells=(0, 1, 2, 3, 4, 5, 6, 7, 8, 9), inset_x=0.02, inset_y=0.04),
    SheetSpec("Walking A.png", "move_left", 4, 2, inset_x=0.02, inset_y=0.04, background_profile="complex"),
    SheetSpec("Walking D.png", "move_right", 4, 2, inset_x=0.02, inset_y=0.04, background_profile="complex"),
    SheetSpec("Walking WyA.png", "move_up_left", 4, 2, inset_x=0.16, inset_y=0.22, background_profile="complex"),
    SheetSpec("Walking WyD.png", "move_up_right", 5, 1, inset_x=0.08, inset_y=0.05, background_profile="complex"),
    SheetSpec("Walking AyS.png", "move_down_left", 6, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("Walking SyD.png", "move_down_right", 8, 1, inset_x=0.02, inset_y=0.05),
    SheetSpec("MC damage recieve animation.png", "hit", 2, 3, inset_x=0.03, inset_y=0.06, background_profile="robot_sheet"),
    SheetSpec("Mc Attack animation front.png", "attack_front", 2, 2, inset_x=0.04, inset_y=0.08, background_profile="robot_sheet"),
    SheetSpec("Mc animation atack different directions.png", "attack_down", 6, 4, active_cells=(0, 1, 2, 3, 4, 5), background_profile="robot_sheet", extract_mode="components"),
    SheetSpec("Mc animation atack different directions.png", "attack_side", 6, 4, active_cells=(5, 6, 7, 8, 9, 10), background_profile="robot_sheet", extract_mode="components"),
    SheetSpec("Mc animation atack different directions.png", "attack_up", 6, 4, active_cells=(11, 12, 13, 14, 15, 16), background_profile="robot_sheet", extract_mode="components"),
    SheetSpec("Dashes Direcciones AWSD.png", "dash_up", 2, 4, active_cells=(0,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes Direcciones AWSD.png", "dash_down", 2, 4, active_cells=(1,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes Direcciones AWSD.png", "dash_left", 2, 4, active_cells=(2,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes Direcciones AWSD.png", "dash_right", 2, 4, active_cells=(3,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes direccion AyW, DyW.png", "dash_up_right", 3, 2, active_cells=(1,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes direccion AyW, DyW.png", "dash_up_left", 3, 2, active_cells=(2,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes direccion AyW, DyW.png", "dash_down_right", 3, 2, active_cells=(3,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
    SheetSpec("Dashes direccion AyW, DyW.png", "dash_down_left", 3, 2, active_cells=(4,), inset_x=0.04, inset_y=0.04, background_profile="robot_sheet"),
)

MIN_COMPONENT_PIXELS = 160
SIDE_PADDING = 8
TOP_PADDING = 6
BOTTOM_PADDING = 8
TARGET_HEAD_HEIGHT = 72
TARGET_HEAD_WIDTH = 92
TARGET_BODY_HEIGHT = 176
RESIDUE_BRIGHTNESS_THRESHOLD = 150
RESIDUE_COLORFULNESS_THRESHOLD = 65
SECONDARY_COMPONENT_MIN_PIXELS = 70
SECONDARY_COMPONENT_DISTANCE_RATIO = 0.22


def main() -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)

    prepared_frames_by_animation: dict[str, list[PreparedFrame]] = {}
    for spec in SPECS:
        prepared_frames: list[PreparedFrame] = []
        for frame in extract_sheet_frames(spec):
            prepared_frames.append(prepare_frame(frame, spec.animation_name))

        if not prepared_frames:
            raise RuntimeError(f"No frames extracted from {spec.source_name}")

        prepared_frames_by_animation[spec.animation_name] = prepared_frames

    scaled_frames_by_animation = {
        animation_name: [scale_prepared_frame(frame, animation_name) for frame in frames]
        for animation_name, frames in prepared_frames_by_animation.items()
    }
    for animation_name, frames in scaled_frames_by_animation.items():
        if animation_name == "idle" or animation_name.startswith("move_") or animation_name == "hit":
            scaled_frames_by_animation[animation_name] = normalize_animation_top_margin(frames)

    layout = build_canvas_layout(scaled_frames_by_animation)

    for animation_name, frames in scaled_frames_by_animation.items():
        animation_dir = OUTPUT_ROOT / animation_name
        animation_dir.mkdir(parents=True, exist_ok=True)
        clear_png_files(animation_dir)

        for frame_index, frame in enumerate(frames):
            aligned_frame = build_aligned_frame(frame, layout)
            aligned_frame.save(animation_dir / f"frame_{frame_index:02d}.png")

    write_preview_sheet(scaled_frames_by_animation, layout)


def extract_sheet_frames(spec: SheetSpec) -> list[Image.Image]:
    source_path = ART_ROOT / spec.source_name
    sheet_image = Image.open(source_path).convert("RGBA")
    if spec.extract_mode == "components":
        return extract_component_frames(sheet_image, spec)

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


def extract_component_frames(sheet_image: Image.Image, spec: SheetSpec) -> list[Image.Image]:
    width, height = sheet_image.size
    pixels = sheet_image.load()
    border_samples = sample_border_pixels(pixels, width, height)
    if not border_samples:
        return []

    brightest_samples = select_brightest_samples(border_samples)
    avg_r = sum(sample[0] for sample in brightest_samples) / len(brightest_samples)
    avg_g = sum(sample[1] for sample in brightest_samples) / len(brightest_samples)
    avg_b = sum(sample[2] for sample in brightest_samples) / len(brightest_samples)
    avg_luma = (avg_r + avg_g + avg_b) / 3.0

    background_mask = flood_fill_background(pixels, width, height, avg_r, avg_g, avg_b, avg_luma, spec.background_profile)
    mask = [[False for _ in range(width)] for _ in range(height)]
    for y in range(height):
        for x in range(width):
            if background_mask[y][x]:
                continue
            if pixels[x, y][3] == 0:
                continue
            mask[y][x] = True

    labels, components = find_components(mask)
    valid_component_ids = []
    for component_id, component in enumerate(components):
        pixel_count, left, top, right, bottom = component
        bbox_width = right - left + 1
        bbox_height = bottom - top + 1
        if pixel_count < 1200:
            continue
        if bbox_width < 35 or bbox_height < 90:
            continue
        valid_component_ids.append(component_id)

    valid_component_ids.sort(
        key=lambda component_id: (
            (components[component_id][2] + components[component_id][4]) / 2.0,
            components[component_id][1],
        )
    )

    if spec.active_cells is None:
        selected_component_ids = valid_component_ids
    else:
        average_component_height = sum(components[component_id][4] - components[component_id][2] + 1 for component_id in valid_component_ids) / float(len(valid_component_ids))
        row_bucket = max(120.0, average_component_height * 1.15)
        valid_component_ids.sort(
            key=lambda component_id: (
                round(((components[component_id][2] + components[component_id][4]) / 2.0) / row_bucket),
                components[component_id][1],
            )
        )
        selected_component_ids = [valid_component_ids[index] for index in spec.active_cells if index < len(valid_component_ids)]

    frames: list[Image.Image] = []
    for component_id in selected_component_ids:
        _, left, top, right, bottom = components[component_id]
        cropped_image = Image.new("RGBA", (right - left + 1, bottom - top + 1), (0, 0, 0, 0))
        for y in range(top, bottom + 1):
            for x in range(left, right + 1):
                if labels[y][x] != component_id:
                    continue
                cropped_image.putpixel((x - left, y - top), pixels[x, y])
        frames.append(cropped_image)

    return frames


def prepare_frame(frame: Image.Image, animation_name: str) -> PreparedFrame:
    working_frame = frame.copy()
    remove_edge_connected_background_residue(working_frame)
    remove_disconnected_artifacts(working_frame)
    if animation_name == "move_up_right":
        repair_glass_head_gaps(working_frame)
    working_frame = trim_transparent_border(working_frame)
    if animation_name == "idle" or animation_name.startswith("move_"):
        working_frame = trim_sparse_top_rows(working_frame)
        working_frame = trim_transparent_border(working_frame)

    head_center_x, head_top, head_width, head_height, body_bottom = measure_head_anchor(working_frame)
    return PreparedFrame(working_frame, head_center_x, head_top, head_width, head_height, body_bottom)


def scale_prepared_frame(frame: PreparedFrame, animation_name: str) -> PreparedFrame:
    scale = 1.0
    if frame.head_height > 0 and frame.head_width > 0:
        body_height = max(1, frame.body_bottom - frame.head_top + 1)
        body_scale = TARGET_BODY_HEIGHT / float(body_height)
        height_scale = TARGET_HEAD_HEIGHT / float(frame.head_height)
        width_scale = TARGET_HEAD_WIDTH / float(frame.head_width)
        head_scale = math.sqrt(height_scale * width_scale)
        scale = math.sqrt(body_scale * head_scale)
        if animation_name.startswith("dash"):
            effect_margin = frame.head_top + max(0, frame.image.height - frame.body_bottom - 1)
            effect_ratio = effect_margin / float(body_height)
            scale *= max(0.82, 1.0 - effect_ratio * 0.30)
            if animation_name in {"dash_down_left", "dash_down_right"}:
                scale *= 0.92

    target_width = max(1, round(frame.image.width * scale))
    target_height = max(1, round(frame.image.height * scale))
    scaled_image = frame.image.resize((target_width, target_height), Image.Resampling.NEAREST)

    remove_edge_connected_background_residue(scaled_image)
    remove_disconnected_artifacts(scaled_image)
    if animation_name == "move_up_right":
        repair_glass_head_gaps(scaled_image)
    scaled_image = trim_transparent_border(scaled_image)
    if animation_name == "idle" or animation_name.startswith("move_"):
        scaled_image = trim_sparse_top_rows(scaled_image)
        scaled_image = trim_transparent_border(scaled_image)

    head_center_x, head_top, head_width, head_height, body_bottom = measure_head_anchor(scaled_image)
    return PreparedFrame(scaled_image, head_center_x, head_top, head_width, head_height, body_bottom)


def build_canvas_layout(frames_by_animation: dict[str, list[PreparedFrame]]) -> CanvasLayout:
    all_frames = [frame for frames in frames_by_animation.values() for frame in frames]
    max_left_extent = max(frame.head_center_x for frame in all_frames)
    max_right_extent = max(frame.image.width - frame.head_center_x for frame in all_frames)
    max_top_extent = max(frame.body_bottom for frame in all_frames)
    max_bottom_extent = max(frame.image.height - frame.body_bottom for frame in all_frames)

    anchor_x = SIDE_PADDING + max_left_extent
    anchor_y = TOP_PADDING + max_top_extent
    width = round(anchor_x + max_right_extent + SIDE_PADDING)
    height = round(anchor_y + max_bottom_extent + BOTTOM_PADDING)
    return CanvasLayout(width, height, anchor_x, anchor_y)


def build_aligned_frame(frame: PreparedFrame, layout: CanvasLayout) -> Image.Image:
    aligned_frame = Image.new("RGBA", (layout.width, layout.height), (0, 0, 0, 0))
    paste_x = round(layout.anchor_x - frame.head_center_x)
    paste_y = round(layout.anchor_y - frame.body_bottom)
    aligned_frame.alpha_composite(frame.image, (paste_x, paste_y))
    return aligned_frame


def write_preview_sheet(frames_by_animation: dict[str, list[PreparedFrame]], layout: CanvasLayout) -> None:
    ordered_animation_names = [spec.animation_name for spec in SPECS]
    max_frames = max(len(frames) for frames in frames_by_animation.values())
    preview = Image.new(
        "RGBA",
        (layout.width * max_frames, layout.height * len(ordered_animation_names)),
        (9, 14, 28, 255),
    )

    for row_index, animation_name in enumerate(ordered_animation_names):
        for column_index, frame in enumerate(frames_by_animation[animation_name]):
            aligned_frame = build_aligned_frame(frame, layout)
            preview.alpha_composite(aligned_frame, (column_index * layout.width, row_index * layout.height))

    preview.save(OUTPUT_ROOT / "preview.png")


def normalize_animation_top_margin(frames: list[PreparedFrame]) -> list[PreparedFrame]:
    if not frames:
        return frames

    ordered_top_margins = sorted(frame.head_top for frame in frames)
    target_top_margin = ordered_top_margins[len(ordered_top_margins) // 2]
    normalized_frames: list[PreparedFrame] = []

    for frame in frames:
        if frame.head_top <= target_top_margin:
            normalized_frames.append(frame)
            continue

        crop_top = frame.head_top - target_top_margin
        cropped_image = frame.image.crop((0, crop_top, frame.image.width, frame.image.height))
        head_center_x, head_top, head_width, head_height, body_bottom = measure_head_anchor(cropped_image)
        normalized_frames.append(PreparedFrame(cropped_image, head_center_x, head_top, head_width, head_height, body_bottom))

    return normalized_frames


def trim_transparent_border(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def trim_sparse_top_rows(image: Image.Image) -> Image.Image:
    bbox = image.getbbox()
    if bbox is None:
        return image

    left, top, right, bottom = bbox
    pixels = image.load()
    row_coverages: list[tuple[int, int]] = []
    for y in range(top, bottom):
        opaque_count = 0
        for x in range(left, right):
            if pixels[x, y][3] > 0:
                opaque_count += 1
        if opaque_count > 0:
            row_coverages.append((y, opaque_count))

    if not row_coverages:
        return image

    strongest_row = max(row[1] for row in row_coverages)
    coverage_threshold = max(6, round(strongest_row * 0.18))
    trim_top = top
    for row_y, opaque_count in row_coverages:
        if opaque_count >= coverage_threshold:
            trim_top = row_y
            break

    if trim_top <= top:
        return image

    return image.crop((0, trim_top, image.width, image.height))


def measure_head_anchor(image: Image.Image) -> tuple[float, int, int, int, int]:
    bbox = image.getbbox()
    if bbox is None:
        return 0.0, 0, 0, 0, 0

    left, top, right, bottom = bbox
    used_height = bottom - top
    search_bottom = top + max(1, round(used_height * 0.45))

    pixels = image.load()
    row_slices: list[tuple[int, int, int, int]] = []
    for y in range(top, min(search_bottom, image.height)):
        row_min_x = image.width
        row_max_x = -1
        opaque_count = 0
        for x in range(left, right):
            if pixels[x, y][3] == 0:
                continue
            opaque_count += 1
            row_min_x = min(row_min_x, x)
            row_max_x = max(row_max_x, x)

        if opaque_count > 0:
            row_slices.append((y, opaque_count, row_min_x, row_max_x))

    if not row_slices:
        return (left + right) / 2.0, top, right - left, bottom - top, bottom - 1

    strongest_row = max(row[1] for row in row_slices)
    dominant_threshold = max(10, round(strongest_row * 0.45))
    supporting_threshold = max(6, round(strongest_row * 0.28))

    dominant_bands: list[list[tuple[int, int, int, int]]] = []
    current_band: list[tuple[int, int, int, int]] = []
    previous_y = -10
    for row in row_slices:
        row_y, opaque_count, _, _ = row
        if opaque_count >= dominant_threshold:
            if current_band and row_y - previous_y > 2:
                dominant_bands.append(current_band)
                current_band = []
            current_band.append(row)
            previous_y = row_y
        elif current_band:
            dominant_bands.append(current_band)
            current_band = []
            previous_y = -10
    if current_band:
        dominant_bands.append(current_band)

    if not dominant_bands:
        candidate_rows = row_slices
    else:
        candidate_rows = max(dominant_bands, key=lambda band: sum(row[1] for row in band))
        candidate_top = candidate_rows[0][0]
        candidate_bottom = candidate_rows[-1][0]
        expanded_rows: list[tuple[int, int, int, int]] = []
        for row in row_slices:
            row_y, opaque_count, _, _ = row
            if row_y < candidate_top - 2 or row_y > candidate_bottom + 2:
                continue
            if opaque_count >= supporting_threshold:
                expanded_rows.append(row)
        if expanded_rows:
            candidate_rows = expanded_rows

    min_x = min(row[2] for row in candidate_rows)
    max_x = max(row[3] for row in candidate_rows)
    min_y = min(row[0] for row in candidate_rows)
    max_y = max(row[0] for row in candidate_rows)
    body_band_half_width = max(14, round((max_x - min_x + 1) * 0.32))
    body_band_left = max(left, round((min_x + max_x) / 2.0) - body_band_half_width)
    body_band_right = min(right - 1, round((min_x + max_x) / 2.0) + body_band_half_width)
    body_band_threshold = max(5, round((body_band_right - body_band_left + 1) * 0.18))

    body_bottom = bottom - 1
    for y in range(bottom - 1, min_y - 1, -1):
        opaque_in_band = 0
        for x in range(body_band_left, body_band_right + 1):
            if pixels[x, y][3] > 0:
                opaque_in_band += 1
        if opaque_in_band >= body_band_threshold:
            body_bottom = y
            break

    return (min_x + max_x) / 2.0, min_y, max_x - min_x + 1, max_y - min_y + 1, body_bottom


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

    labels, components = find_components(mask)
    primary_id = select_primary_component_id(components, width, height)
    if primary_id is None:
        return None

    kept_ids = collect_kept_component_ids(components, primary_id, width, height)
    left = min(components[index][1] for index in kept_ids)
    top = min(components[index][2] for index in kept_ids)
    right = max(components[index][3] for index in kept_ids)
    bottom = max(components[index][4] for index in kept_ids)
    cropped_image = Image.new("RGBA", (right - left + 1, bottom - top + 1), (0, 0, 0, 0))
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            if mask[y][x] and labels[y][x] in kept_ids:
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
        if brightness >= 170 and colorfulness <= 42:
            return True
        if distance <= 82 and colorfulness <= 45:
            return True
        if brightness >= avg_luma - 28 and colorfulness <= 30:
            return True
        if brightness >= avg_luma - 12 and colorfulness <= 34:
            return True
        return False

    if background_profile == "robot_sheet":
        if distance <= 24 and colorfulness <= 16:
            return True
        if brightness >= avg_luma - 4 and distance <= 42 and colorfulness <= 22:
            return True
        return False

    if distance <= 58 and colorfulness <= 34:
        return True
    if brightness >= avg_luma - 26 and colorfulness <= 18:
        return True
    if brightness >= avg_luma - 12 and colorfulness <= 32:
        return True

    return False


def select_primary_component_id(components: list[tuple[int, int, int, int, int]], cell_width: int, cell_height: int) -> int | None:
    best_component_id: int | None = None
    best_score = -1.0

    for component_id, component in enumerate(components):
        score = score_component(component, cell_width, cell_height)
        if score <= 0.0:
            continue
        if best_component_id is None or score > best_score:
            best_component_id = component_id
            best_score = score

    return best_component_id


def collect_kept_component_ids(
    components: list[tuple[int, int, int, int, int]],
    primary_id: int,
    cell_width: int,
    cell_height: int,
) -> set[int]:
    kept_ids = {primary_id}
    primary_component = components[primary_id]

    for component_id, component in enumerate(components):
        if component_id == primary_id:
            continue
        if should_keep_secondary_component(primary_component, component, cell_width, cell_height):
            kept_ids.add(component_id)

    return kept_ids


def should_keep_secondary_component(
    primary_component: tuple[int, int, int, int, int],
    secondary_component: tuple[int, int, int, int, int],
    cell_width: int,
    cell_height: int,
) -> bool:
    secondary_pixels, left, top, right, bottom = secondary_component
    if secondary_pixels < SECONDARY_COMPONENT_MIN_PIXELS:
        return False

    bbox_width = right - left + 1
    bbox_height = bottom - top + 1
    if bbox_width < 3 or bbox_height < 3:
        return False

    touches_edge = int(left <= 1) + int(top <= 1) + int(right >= cell_width - 2) + int(bottom >= cell_height - 2)
    if touches_edge >= 2 and secondary_pixels < primary_component[0] * 0.20:
        return False

    max_gap = max(cell_width, cell_height) * SECONDARY_COMPONENT_DISTANCE_RATIO + 8.0
    return component_bbox_distance(primary_component, secondary_component) <= max_gap


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


def clear_png_files(directory: Path) -> None:
    for png_file in directory.glob("*.png"):
        png_file.unlink()


def remove_disconnected_artifacts(image: Image.Image) -> None:
    width, height = image.size
    pixels = image.load()
    alpha_mask = [[pixels[x, y][3] > 0 for x in range(width)] for y in range(height)]
    labels, components = find_components(alpha_mask)
    if not components:
        return

    primary_id = select_primary_component_id(components, width, height)
    if primary_id is None:
        return

    kept_ids = collect_kept_component_ids(components, primary_id, width, height)
    for y in range(height):
        for x in range(width):
            component_id = labels[y][x]
            if component_id is None or component_id in kept_ids:
                continue
            pixels[x, y] = (0, 0, 0, 0)


def remove_edge_connected_background_residue(image: Image.Image) -> None:
    width, height = image.size
    pixels = image.load()
    visited = [[False for _ in range(width)] for _ in range(height)]
    queue = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))

    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        current_x, current_y = queue.popleft()
        if current_x < 0 or current_x >= width or current_y < 0 or current_y >= height:
            continue
        if visited[current_y][current_x]:
            continue

        visited[current_y][current_x] = True
        red, green, blue, alpha = pixels[current_x, current_y]
        if alpha == 0:
            push_neighbor_coordinates(queue, current_x, current_y)
            continue

        brightness = (red + green + blue) / 3.0
        colorfulness = max(red, green, blue) - min(red, green, blue)
        if brightness >= RESIDUE_BRIGHTNESS_THRESHOLD and colorfulness <= RESIDUE_COLORFULNESS_THRESHOLD:
            pixels[current_x, current_y] = (0, 0, 0, 0)
            push_neighbor_coordinates(queue, current_x, current_y)


def repair_glass_head_gaps(image: Image.Image) -> None:
    bbox = image.getbbox()
    if bbox is None:
        return

    left, top, right, bottom = bbox
    head_limit = top + int((bottom - top) * 0.30)
    pixels = image.load()
    source = image.copy().load()
    width, height = image.size

    for y in range(top, min(head_limit, height)):
        for x in range(left, right):
            if source[x, y][3] > 0:
                continue

            bright_neighbors: list[tuple[int, int, int, int]] = []
            opaque_neighbors = 0
            for neighbor_y in range(max(0, y - 2), min(height, y + 3)):
                for neighbor_x in range(max(0, x - 2), min(width, x + 3)):
                    if neighbor_x == x and neighbor_y == y:
                        continue

                    neighbor = source[neighbor_x, neighbor_y]
                    if neighbor[3] == 0:
                        continue

                    opaque_neighbors += 1
                    neighbor_brightness = (neighbor[0] + neighbor[1] + neighbor[2]) / 3.0
                    if neighbor_brightness >= 90.0:
                        bright_neighbors.append(neighbor)

            if opaque_neighbors < 6 or len(bright_neighbors) < 4:
                continue

            avg_r = round(sum(color[0] for color in bright_neighbors) / len(bright_neighbors))
            avg_g = round(sum(color[1] for color in bright_neighbors) / len(bright_neighbors))
            avg_b = round(sum(color[2] for color in bright_neighbors) / len(bright_neighbors))
            pixels[x, y] = (avg_r, avg_g, avg_b, 255)


def push_neighbor_coordinates(queue: deque[tuple[int, int]], current_x: int, current_y: int) -> None:
    queue.append((current_x - 1, current_y))
    queue.append((current_x + 1, current_y))
    queue.append((current_x, current_y - 1))
    queue.append((current_x, current_y + 1))


def component_bbox_distance(
    component_a: tuple[int, int, int, int, int],
    component_b: tuple[int, int, int, int, int],
) -> float:
    _, left_a, top_a, right_a, bottom_a = component_a
    _, left_b, top_b, right_b, bottom_b = component_b

    horizontal_gap = max(0, max(left_a - right_b - 1, left_b - right_a - 1))
    vertical_gap = max(0, max(top_a - bottom_b - 1, top_b - bottom_a - 1))
    if horizontal_gap == 0 or vertical_gap == 0:
        return float(horizontal_gap + vertical_gap)

    return math.sqrt(horizontal_gap * horizontal_gap + vertical_gap * vertical_gap)


def find_components(mask: list[list[bool]]) -> tuple[list[list[int | None]], list[tuple[int, int, int, int, int]]]:
    height = len(mask)
    width = len(mask[0]) if height > 0 else 0
    labels: list[list[int | None]] = [[None for _ in range(width)] for _ in range(height)]
    components: list[tuple[int, int, int, int, int]] = []
    component_id = 0

    for y in range(height):
        for x in range(width):
            if mask[y][x] is False or labels[y][x] is not None:
                continue

            queue = deque([(x, y)])
            labels[y][x] = component_id
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
                    if mask[next_y][next_x] is False or labels[next_y][next_x] is not None:
                        continue

                    labels[next_y][next_x] = component_id
                    queue.append((next_x, next_y))

            components.append((pixel_count, left, top, right, bottom))
            component_id += 1

    return labels, components


if __name__ == "__main__":
    main()
