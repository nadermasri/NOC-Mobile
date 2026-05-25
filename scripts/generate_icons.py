#!/usr/bin/env python3
"""
Generate iOS and Android app icons from logo.png.
Crops the source logo to just the circular emblem (no bottom text),
then exports all required sizes for both platforms.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "branding" / "logo.png"
OUT_ICON_SQUARE = ROOT / "assets" / "branding" / "icon_1024.png"

# iOS icon set — paths and pixel sizes
IOS_ICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

# Android icon set
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def crop_to_circle(img: Image.Image) -> Image.Image:
    """Use the logo as-is (no cropping)."""
    return img


def fill_background(img: Image.Image, color=(43, 26, 71)) -> Image.Image:
    """Composite RGBA onto a solid color background (for icons that need opaque)."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    bg = Image.new("RGB", img.size, color)
    bg.paste(img, mask=img.split()[3])
    return bg


def main():
    if not SOURCE.exists():
        raise SystemExit(f"Source logo not found: {SOURCE}")

    print(f"Loading: {SOURCE}")
    src = Image.open(SOURCE).convert("RGBA")
    print(f"Source size: {src.size}")

    # 1. Crop to circle emblem
    cropped = crop_to_circle(src)
    print(f"Cropped to: {cropped.size}")

    # 2. Resize to 1024×1024 master
    master = cropped.resize((1024, 1024), Image.LANCZOS)

    # iOS icons need opaque RGB (no alpha allowed by App Store)
    master_rgb = fill_background(master)
    master_rgb.save(OUT_ICON_SQUARE, "PNG", optimize=True)
    print(f"Master icon: {OUT_ICON_SQUARE}")

    # 3. Generate iOS icons
    IOS_ICON_DIR.mkdir(parents=True, exist_ok=True)
    for filename, size in IOS_SIZES.items():
        out = IOS_ICON_DIR / filename
        resized = master_rgb.resize((size, size), Image.LANCZOS)
        resized.save(out, "PNG", optimize=True)
    print(f"Generated {len(IOS_SIZES)} iOS icons in {IOS_ICON_DIR}")

    # 4. Generate Android icons (these can keep alpha)
    for folder, size in ANDROID_SIZES.items():
        target_dir = ANDROID_RES / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        resized = master.resize((size, size), Image.LANCZOS)
        # Standard launcher
        resized.save(target_dir / "ic_launcher.png", "PNG", optimize=True)
    print(f"Generated {len(ANDROID_SIZES)} Android icon densities in {ANDROID_RES}")

    print("\nDone. Run the build to see your new app icon.")


if __name__ == "__main__":
    main()
