#!/usr/bin/env python3
"""Generate Android launcher icons from the xxxhdpi source icon."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

# Android launcher icon sizes by density bucket.
TARGETS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def center_crop_square(image: Image.Image) -> Image.Image:
    width, height = image.size
    if width == height:
        return image

    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side))


def generate_icons(res_root: Path, source_file: Path, output_name: str) -> None:
    if not source_file.exists():
        raise FileNotFoundError(f"Source icon not found: {source_file}")

    with Image.open(source_file) as original:
        image = center_crop_square(original.convert("RGBA"))

        for folder, size in TARGETS.items():
            out_dir = res_root / folder
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / output_name

            resized = image.resize((size, size), Image.Resampling.LANCZOS)
            resized.save(out_path, format="PNG", optimize=True)
            print(f"Generated {out_path} ({size}x{size})")


def verify_icons(res_root: Path, output_name: str) -> None:
    print("\nVerifying generated files:")
    for folder, expected_size in TARGETS.items():
        icon_path = res_root / folder / output_name
        if not icon_path.exists():
            print(f"[MISSING] {icon_path}")
            continue

        with Image.open(icon_path) as img:
            actual_size = img.size
        status = "OK" if actual_size == (expected_size, expected_size) else "WRONG"
        print(f"[{status}] {icon_path} -> {actual_size}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate Android mipmap launcher icons from a source PNG."
    )
    parser.add_argument(
        "--res-root",
        type=Path,
        default=Path("frontend/android/app/src/main/res"),
        help="Android res directory containing mipmap-* folders.",
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("frontend/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"),
        help="Source icon file.",
    )
    parser.add_argument(
        "--name",
        default="ic_launcher.png",
        help="Output file name in each mipmap folder.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    res_root = args.res_root.resolve()
    source_file = args.source.resolve()

    generate_icons(res_root=res_root, source_file=source_file, output_name=args.name)
    verify_icons(res_root=res_root, output_name=args.name)


if __name__ == "__main__":
    main()
