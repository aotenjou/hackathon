#!/usr/bin/env python3
"""
像素风图片压缩工具
- 缩小宽度超过1600的图片（使用最近邻插值保持锐利）
- 量化颜色到256色（像素艺术几乎无视觉损失）
"""
import os
from pathlib import Path
from PIL import Image

TARGET_WIDTH = 1600
MAX_COLORS = 256

def compress_image(input_path: Path, dry_run: bool = False) -> tuple[bool, int, int]:
    """Compress a single image. Returns (changed, old_size, new_size)."""
    try:
        img = Image.open(input_path)
        old_size = input_path.stat().st_size
        original_mode = img.mode

        # Calculate new dimensions
        width, height = img.size
        if width > TARGET_WIDTH:
            new_width = TARGET_WIDTH
            new_height = int(height * (TARGET_WIDTH / width))
            if not dry_run:
                # Use NEAREST for pixel art - keeps sharp edges
                img = img.resize((new_width, new_height), Image.Resampling.NEAREST)
            print(f"  缩放: {width}x{height} -> {new_width}x{new_height}")

        # Quantize colors (convert to P mode with palette)
        if img.mode in ('RGB', 'RGBA'):
            if not dry_run:
                # dither=Image.Dither.NONE keeps sharp pixel edges
                if img.mode == 'RGBA':
                    # Preserve alpha channel
                    img = img.convert('P', palette=Image.Palette.ADAPTIVE, colors=MAX_COLORS, dither=Image.Dither.NONE)
                    img = img.convert('RGBA')
                else:
                    img = img.convert('P', palette=Image.Palette.ADAPTIVE, colors=MAX_COLORS, dither=Image.Dither.NONE)
                    img = img.convert('RGB')

        if not dry_run:
            # Save with maximum compression
            img.save(input_path, 'PNG', optimize=True)
            new_size = input_path.stat().st_size
        else:
            new_size = old_size  # placeholder for dry run

        img.close()
        return True, old_size, new_size

    except Exception as e:
        print(f"  错误: {e}")
        return False, 0, 0

def main():
    base_path = Path(r"e:\dev\hackathon\assets\storyline")

    # Find all PNG files
    png_files = list(base_path.rglob("*.png"))
    # Exclude .import files
    png_files = [f for f in png_files if not f.name.endswith('.import')]

    print(f"找到 {len(png_files)} 个PNG文件\n")

    total_old = 0
    total_new = 0
    processed = 0
    errors = 0

    for i, png_file in enumerate(sorted(png_files)):
        rel_path = png_file.relative_to(base_path)
        old_size = png_file.stat().st_size
        total_old += old_size

        print(f"[{i+1}/{len(png_files)}] {rel_path}")
        print(f"  原始: {old_size/1024:.1f} KB")

        success, _, new_size = compress_image(png_file)

        if success:
            processed += 1
            if new_size > 0:
                total_new += new_size
                savings = (1 - new_size/old_size) * 100
                print(f"  压缩后: {new_size/1024:.1f} KB (节省 {savings:.1f}%)")
        else:
            errors += 1
            total_new += old_size

        print()

    print("=" * 50)
    print(f"处理完成: {processed} 个文件, {errors} 个错误")
    print(f"总大小: {total_old/1024/1024:.2f} MB -> {total_new/1024/1024:.2f} MB")
    print(f"节省: {(total_old-total_new)/1024/1024:.2f} MB ({(1-total_new/total_old)*100:.1f}%)")

if __name__ == "__main__":
    main()
