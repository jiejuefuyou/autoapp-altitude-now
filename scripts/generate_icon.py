"""
AltitudeNow icon generator — v1.0.4

Design:
  - Emerald gradient background: #0E4A2C (top) → #33A673 (mid) → #7DD3A1 (bottom)
  - Mountain silhouette + snow cap in lower half
  - "A↑" lettermark in upper half (white A + golden arrow)

Run:
  python scripts/generate_icon.py

Requires: pip install Pillow
Output:  AltitudeNow/Resources/Assets.xcassets/AppIcon.appiconset/icon.png
"""
from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFont


def make_gradient_bg(size: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        t = y / size
        if t < 0.5:
            ratio = t * 2
            r_c = int(0x0E + (0x33 - 0x0E) * ratio)
            g_c = int(0x4A + (0xA6 - 0x4A) * ratio)
            b_c = int(0x2C + (0x73 - 0x2C) * ratio)
        else:
            ratio = (t - 0.5) * 2
            r_c = int(0x33 + (0x7D - 0x33) * ratio)
            g_c = int(0xA6 + (0xD3 - 0xA6) * ratio)
            b_c = int(0x73 + (0xA1 - 0x73) * ratio)
        for x in range(size):
            draw.point((x, y), fill=(r_c, g_c, b_c))
    return img, draw


def draw_mountain(draw: ImageDraw.ImageDraw, size: int) -> None:
    mountain_pts = [
        (0, size),
        (0, int(size * 0.78)),
        (int(size * 0.15), int(size * 0.68)),
        (int(size * 0.28), int(size * 0.74)),
        (int(size * 0.44), int(size * 0.50)),   # main peak
        (int(size * 0.58), int(size * 0.68)),
        (int(size * 0.72), int(size * 0.62)),
        (int(size * 0.88), int(size * 0.74)),
        (size, int(size * 0.80)),
        (size, size),
    ]
    draw.polygon(mountain_pts, fill=(0x07, 0x2E, 0x1C))
    # Snow cap on main peak
    snow = [
        (int(size * 0.40), int(size * 0.54)),
        (int(size * 0.44), int(size * 0.50)),
        (int(size * 0.48), int(size * 0.54)),
        (int(size * 0.46), int(size * 0.57)),
        (int(size * 0.42), int(size * 0.57)),
    ]
    draw.polygon(snow, fill=(255, 255, 255))


def draw_text_elements(draw: ImageDraw.ImageDraw, size: int) -> None:
    font_bold: str | None = None
    font_sym: str | None = None
    for p in ["C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/arial.ttf",
              "/System/Library/Fonts/SFNSDisplay-Bold.otf"]:
        if os.path.exists(p):
            font_bold = p
            break
    for p in ["C:/Windows/Fonts/seguisym.ttf", "C:/Windows/Fonts/segoeui.ttf",
              "/System/Library/Fonts/Apple Symbols.ttf"]:
        if os.path.exists(p):
            font_sym = p
            break

    letter_size = int(size * 0.26)
    arrow_size = int(size * 0.18)

    try:
        font_letter = ImageFont.truetype(font_bold or "arial.ttf", letter_size)
    except Exception:
        font_letter = ImageFont.load_default()
    try:
        font_arrow = ImageFont.truetype(font_sym or font_bold or "arial.ttf", arrow_size)
    except Exception:
        font_arrow = ImageFont.load_default()

    text_a = "A"
    text_arrow = "↑"   # ↑

    bbox_a = draw.textbbox((0, 0), text_a, font=font_letter)
    aw = bbox_a[2] - bbox_a[0]
    bbox_arr = draw.textbbox((0, 0), text_arrow, font=font_arrow)
    arw = bbox_arr[2] - bbox_arr[0]

    gap = int(size * 0.02)
    total_w = aw + gap + arw
    start_x = (size - total_w) // 2
    a_y = int(size * 0.14)

    # Drop shadow
    shadow_off = max(2, int(size * 0.003))
    draw.text((start_x + shadow_off, a_y + shadow_off), text_a,
              fill=(0, 0, 0, 80), font=font_letter)
    draw.text((start_x + aw + gap + shadow_off, a_y + shadow_off), text_arrow,
              fill=(0, 0, 0, 80), font=font_arrow)

    draw.text((start_x, a_y), text_a, fill=(255, 255, 255), font=font_letter)
    draw.text((start_x + aw + gap, a_y), text_arrow, fill=(0xFF, 0xE5, 0x70), font=font_arrow)


def main() -> None:
    size = 1024
    img, draw = make_gradient_bg(size)
    draw_mountain(draw, size)
    draw_text_elements(draw, size)

    out_dir = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "AltitudeNow", "Resources", "Assets.xcassets",
        "AppIcon.appiconset",
    )
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "icon.png")
    img.save(out_path, "PNG")
    print(f"Saved {out_path} ({size}x{size})")


if __name__ == "__main__":
    main()
