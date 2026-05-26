#!/usr/bin/env python3
"""
Generate the Google Play Store feature graphic (1024x500).
Combines the brand logo with the app name and tagline on a gradient background.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets" / "branding" / "logo.png"
OUT = ROOT / "store" / "feature_graphic_1024x500.png"

W, H = 1024, 500
PURPLE_DARK = (43, 26, 71)
PURPLE_MID = (74, 66, 224)
PURPLE_LIGHT = (139, 133, 255)
WHITE = (255, 255, 255)
PURPLE_TEXT = (200, 192, 255)


def gradient_bg() -> Image.Image:
    """Diagonal purple gradient."""
    img = Image.new("RGB", (W, H), PURPLE_DARK)
    pixels = img.load()
    for y in range(H):
        for x in range(W):
            t = (x + y) / (W + H)
            r = int(PURPLE_DARK[0] * (1 - t) + PURPLE_MID[0] * t)
            g = int(PURPLE_DARK[1] * (1 - t) + PURPLE_MID[1] * t)
            b = int(PURPLE_DARK[2] * (1 - t) + PURPLE_MID[2] * t)
            pixels[x, y] = (r, g, b)
    return img


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Try to load a system font; fall back to default."""
    candidates = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def main():
    if not LOGO.exists():
        raise SystemExit(f"Logo not found: {LOGO}")

    # Background
    img = gradient_bg()

    # Logo on the left (300x300, padded inside the 500-tall canvas)
    logo = Image.open(LOGO).convert("RGBA")
    logo.thumbnail((360, 360), Image.LANCZOS)
    logo_x = 90
    logo_y = (H - logo.height) // 2
    img.paste(logo, (logo_x, logo_y), logo)

    # Text on the right
    draw = ImageDraw.Draw(img)
    text_x = logo_x + logo.width + 70

    title_font = font(82, bold=True)
    sub_font = font(36)
    tagline_font = font(26)

    draw.text((text_x, 140), "Pocket NOC", font=title_font, fill=WHITE)
    draw.text((text_x, 240), "Network Toolkit", font=sub_font, fill=PURPLE_LIGHT)
    draw.text((text_x, 310), "Diagnose · Monitor · Optimize", font=tagline_font, fill=PURPLE_TEXT)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG", optimize=True)
    print(f"Feature graphic: {OUT}")
    print(f"Size: {W}x{H}")


if __name__ == "__main__":
    main()
