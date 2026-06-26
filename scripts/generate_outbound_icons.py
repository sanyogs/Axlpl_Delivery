#!/usr/bin/env python3
"""Generate outbound menu icons matching the Add Shipment (tracking.png) flat style."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT_SIZE = 120
RENDER_SCALE = 4
SIZE = OUT_SIZE * RENDER_SCALE
STROKE = 4 * RENDER_SCALE
# Small transparent edge on exported PNGs (final pixels).
EXPORT_MARGIN = 6

# Sampled from assets/tracking.png
CORAL = (248, 104, 104)
GREY = (216, 232, 232)
BLUE = (48, 184, 232)
NAVY = (48, 96, 136)
BROWN = (166, 124, 82)
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

TARGET_CONTENT_SIZE = OUT_SIZE - 2 * EXPORT_MARGIN
TARGET_MARGIN = EXPORT_MARGIN


def canvas() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)


def draw_rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    fill: tuple[int, int, int],
    radius: int = 6 * RENDER_SCALE,
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=BLACK, width=STROKE)


def draw_circle(
    draw: ImageDraw.ImageDraw,
    cx: int,
    cy: int,
    r: int,
    fill: tuple[int, int, int],
) -> None:
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill, outline=BLACK, width=STROKE)


def draw_wheel(draw: ImageDraw.ImageDraw, cx: int, cy: int) -> None:
    draw_circle(draw, cx, cy, 10 * RENDER_SCALE, NAVY)
    draw_circle(draw, cx, cy, 5 * RENDER_SCALE, GREY)


def draw_arrow_right(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int) -> None:
    body = (x, y + h // 3, x + w - h // 2, y + 2 * h // 3)
    draw.rounded_rectangle(body, radius=4 * RENDER_SCALE, fill=CORAL, outline=BLACK, width=STROKE)
    tip = [(x + w - h // 2, y), (x + w, y + h // 2), (x + w - h // 2, y + h)]
    draw.polygon(tip, fill=CORAL, outline=BLACK)


def icon_home() -> Image.Image:
    """Outbound hub — warehouse with outgoing arrow (not a delivery truck)."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    # building
    draw_rounded_rect(d, (16 * s, 40 * s, 72 * s, 92 * s), GREY, radius=5 * s)
    d.polygon(
        [(12 * s, 40 * s), (44 * s, 14 * s), (76 * s, 40 * s)],
        fill=CORAL,
        outline=BLACK,
        width=STROKE,
    )
    draw_rounded_rect(d, (30 * s, 56 * s, 58 * s, 92 * s), CORAL, radius=4 * s)
    draw_rounded_rect(d, (22 * s, 50 * s, 38 * s, 66 * s), BLUE, radius=3 * s)
    draw_arrow_right(d, 74 * s, 44 * s, 42 * s, 30 * s)
    return img


def icon_manifest() -> Image.Image:
    """Manifest — clipboard checklist."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (26 * s, 28 * s, 94 * s, 102 * s), GREY, radius=6 * s)
    draw_rounded_rect(d, (46 * s, 14 * s, 74 * s, 34 * s), CORAL, radius=8 * s)
    draw_rounded_rect(d, (52 * s, 18 * s, 68 * s, 28 * s), NAVY, radius=4 * s)
    y = 44 * s
    for _ in range(3):
        d.line([(36 * s, y), (56 * s, y)], fill=BLACK, width=3 * s)
        d.line(
            [(64 * s, y - 4 * s), (68 * s, y), (84 * s, y - 8 * s)],
            fill=CORAL,
            width=STROKE,
        )
        y += 16 * s
    return img


def icon_linehaul() -> Image.Image:
    """Linehaul — articulated truck, no location pin."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (8 * s, 44 * s, 70 * s, 78 * s), GREY, radius=4 * s)
    draw_rounded_rect(d, (70 * s, 48 * s, 106 * s, 78 * s), CORAL, radius=5 * s)
    draw_rounded_rect(d, (80 * s, 54 * s, 98 * s, 68 * s), BLUE, radius=3 * s)
    d.line([(16 * s, 78 * s), (102 * s, 78 * s)], fill=NAVY, width=STROKE)
    draw_wheel(d, 28 * s, 92 * s)
    draw_wheel(d, 56 * s, 92 * s)
    draw_wheel(d, 94 * s, 92 * s)
    d.rectangle((66 * s, 60 * s, 72 * s, 78 * s), fill=NAVY, outline=BLACK, width=2 * s)
    return img


def icon_sector_pickup() -> Image.Image:
    """Sector pickup — map pin over a package."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (30 * s, 78 * s, 90 * s, 104 * s), GREY, radius=4 * s)
    draw_rounded_rect(d, (42 * s, 68 * s, 78 * s, 82 * s), BROWN, radius=3 * s)
    d.ellipse((36 * s, 12 * s, 84 * s, 60 * s), fill=CORAL, outline=BLACK, width=STROKE)
    d.polygon(
        [(44 * s, 52 * s), (76 * s, 52 * s), (60 * s, 92 * s)],
        fill=CORAL,
        outline=BLACK,
        width=STROKE,
    )
    draw_circle(d, 60 * s, 34 * s, 10 * s, WHITE)
    return img


def icon_hub_scan() -> Image.Image:
    """Hub scan — barcode inside scanner frame."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (20 * s, 22 * s, 100 * s, 98 * s), GREY, radius=6 * s)
    for x0, y0, x1, y1 in (
        (26 * s, 28 * s, 44 * s, 46 * s),
        (76 * s, 28 * s, 94 * s, 46 * s),
        (26 * s, 74 * s, 44 * s, 92 * s),
        (76 * s, 74 * s, 94 * s, 92 * s),
    ):
        draw_rounded_rect(d, (x0, y0, x1, y1), CORAL, radius=3 * s)
    x = 38 * s
    for w in (3, 5, 3, 7, 4, 3, 6, 3):
        draw_rounded_rect(
            d,
            (x, 48 * s, x + w * s, 72 * s),
            NAVY if w % 2 == 0 else CORAL,
            radius=2 * s,
        )
        x += (w + 3) * s
    return img


def icon_bagging() -> Image.Image:
    """Bagging — sealed carton."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (26 * s, 46 * s, 94 * s, 104 * s), GREY, radius=5 * s)
    d.polygon(
        [(26 * s, 46 * s), (60 * s, 18 * s), (94 * s, 46 * s)],
        fill=CORAL,
        outline=BLACK,
        width=STROKE,
    )
    draw_rounded_rect(d, (42 * s, 58 * s, 78 * s, 74 * s), BLUE, radius=3 * s)
    d.line([(34 * s, 82 * s), (86 * s, 82 * s)], fill=NAVY, width=STROKE)
    d.line([(60 * s, 46 * s), (60 * s, 104 * s)], fill=NAVY, width=2 * s)
    return img


def icon_sector_pickup_report() -> Image.Image:
    """Pickup status report — bar chart on a board."""
    img = canvas()
    d = ImageDraw.Draw(img)
    s = RENDER_SCALE
    draw_rounded_rect(d, (24 * s, 22 * s, 96 * s, 104 * s), GREY, radius=6 * s)
    draw_rounded_rect(d, (44 * s, 10 * s, 76 * s, 26 * s), CORAL, radius=6 * s)
    base_y = 92 * s
    bars = [
        (38 * s, 52 * s, 50 * s, base_y, BLUE),
        (54 * s, 40 * s, 66 * s, base_y, CORAL),
        (70 * s, 60 * s, 82 * s, base_y, NAVY),
    ]
    for x1, y1, x2, y2, color in bars:
        draw_rounded_rect(d, (x1, y1, x2, y2), color, radius=3 * s)
    return img


OUTPUTS = {
    "outbound_home_icon.png": icon_home,
    "outbound_hub_scan_icon.png": icon_hub_scan,
    "outbound_bagging_icon.png": icon_bagging,
    "outbound_manifest_icon.png": icon_manifest,
    "outbound_linehaul_icon.png": icon_linehaul,
    "outbound_sector_pickup_icon.png": icon_sector_pickup,
    "outbound_sector_pickup_report_icon.png": icon_sector_pickup_report,
}


def _content_bbox(img: Image.Image) -> tuple[int, int, int, int] | None:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    w, h = rgba.size
    min_x, min_y, max_x, max_y = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 10:
                found = True
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if not found:
        return None
    return min_x, min_y, max_x + 1, max_y + 1


def export_icon_natural(img: Image.Image) -> Image.Image:
    """Export artwork at natural aspect ratio — rectangular PNG when content is wide/tall."""
    bbox = _content_bbox(img)
    if bbox is None:
        return Image.new("RGBA", (OUT_SIZE, OUT_SIZE), TRANSPARENT)

    cropped = img.crop(bbox)
    cw, ch = cropped.size
    inner_px = TARGET_CONTENT_SIZE * RENDER_SCALE
    scale = min(inner_px / cw, inner_px / ch)
    new_w = max(1, int(round(cw * scale)))
    new_h = max(1, int(round(ch * scale)))
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    margin_px = EXPORT_MARGIN * RENDER_SCALE
    out_w = new_w + 2 * margin_px
    out_h = new_h + 2 * margin_px
    stage = Image.new("RGBA", (out_w, out_h), TRANSPARENT)
    stage.paste(resized, (margin_px, margin_px), resized)

    final_w = max(1, int(round(out_w / RENDER_SCALE)))
    final_h = max(1, int(round(out_h / RENDER_SCALE)))
    return stage.resize((final_w, final_h), Image.Resampling.LANCZOS)


# Back-compat aliases.
scale_icon_to_square = export_icon_natural
scale_icon_to_match_home = export_icon_natural


def main() -> None:
    assets = Path(__file__).resolve().parents[1] / "assets"
    for name, builder in OUTPUTS.items():
        path = assets / name
        export_icon_natural(builder()).save(path, "PNG")
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
