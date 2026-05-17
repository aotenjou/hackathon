#!/usr/bin/env python3
"""
将PNG转换为WebP格式（高压缩比，像素风友好）
- 缩小宽度超过1600的图片（最近邻插值）
- 使用WebP有损压缩，质量85%
"""
import os
from pathlib import Path
from PIL import Image

TARGET_WIDTH = 1600
WEBP_QUALITY = 85  # 85%质量，像素风图片几乎无视觉损失

def convert_to_webp(png_path: Path) -> tuple[int, int]:
    """Convert PNG to WebP. Returns (old_size, new_size)."""
    try:
        img = Image.open(png_path)
        old_size = png_path.stat().st_size

        # Calculate new dimensions
        width, height = img.size
        if width > TARGET_WIDTH:
            new_width = TARGET_WIDTH
            new_height = int(height * (TARGET_WIDTH / width))
            img = img.resize((new_width, new_height), Image.Resampling.NEAREST)
            print(f"  缩放: {width}x{height} -> {new_width}x{new_height}")

        # Save as WebP
        webp_path = png_path.with_suffix('.webp')
        img.save(webp_path, 'WEBP', quality=WEBP_QUALITY, method=6)
        img.close()

        new_size = webp_path.stat().st_size
        return old_size, new_size

    except Exception as e:
        print(f"  错误: {e}")
        return 0, 0

def main():
    base_path = Path(r"e:\dev\hackathon\assets\storyline")

    # Find all PNG files
    png_files = list(base_path.rglob("*.png"))
    png_files = [f for f in png_files if not f.name.endswith('.import')]

    print(f"找到 {len(png_files)} 个PNG文件\n")

    total_old = 0
    total_new = 0
    converted = []

    for i, png_file in enumerate(sorted(png_files)):
        rel_path = png_file.relative_to(base_path)
        print(f"[{i+1}/{len(png_files)}] {rel_path}")

        old_size, new_size = convert_to_webp(png_file)

        if new_size > 0:
            total_old += old_size
            total_new += new_size
            savings = (1 - new_size/old_size) * 100
            print(f"  {old_size/1024:.1f} KB -> {new_size/1024:.1f} KB (节省 {savings:.1f}%)")
            converted.append(png_file)

        print()

    print("=" * 50)
    print(f"转换完成: {len(converted)} 个文件")
    print(f"总大小: {total_old/1024/1024:.2f} MB -> {total_new/1024/1024:.2f} MB")
    print(f"节省: {(total_old-total_new)/1024/1024:.2f} MB ({(1-total_new/total_old)*100:.1f}%)")

if __name__ == "__main__":
    main()
