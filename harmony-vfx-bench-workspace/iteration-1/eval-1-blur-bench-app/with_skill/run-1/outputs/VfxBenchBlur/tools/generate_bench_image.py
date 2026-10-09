#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 VfxBenchBlur 的本地基准图片（构建期素材，杜绝网络图片）。

确定性保证：全部图元由固定坐标/固定公式计算，不使用任何随机数，
同一代码在任何机器上重复执行输出逐字节一致（Pillow 版本一致时）。

输出：
  entry/src/main/resources/base/media/bench_image.png   1080x1440 被测图片
  entry/src/main/resources/base/media/startIcon.png      512x512  启动图标
  AppScope/resources/base/media/app_icon.png             512x512  应用图标
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

W, H = 1080, 1440

# 固定调色板（高饱和，模糊后颜色混合肉眼可辨）
PALETTE = [
    (230, 57, 70),    # red
    (255, 159, 28),   # orange
    (255, 209, 102),  # yellow
    (6, 214, 160),    # green
    (17, 138, 178),   # blue
    (115, 60, 190),   # purple
]


def gen_bench_image(path: str) -> None:
    """竖直渐变底 + 圆点网格 + 斜条纹 + 棋盘块：含足够高频细节，便于模糊半径对比。"""
    img = Image.new("RGB", (W, H))
    px = img.load()

    # 1) 竖直双色渐变底（纯公式）
    top, bottom = (16, 24, 48), (8, 60, 80)
    for y in range(H):
        t = y / (H - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        for x in range(W):
            px[x, y] = (r, g, b)

    d = ImageDraw.Draw(img)

    # 2) 斜向细条纹（高频成分，验证低半径模糊差异）
    for i in range(-H, W, 48):
        d.line([(i, 0), (i + H, H)], fill=(255, 255, 255, 255), width=3)

    # 3) 彩色圆点网格（中频成分，主视觉）
    cols, rows = 6, 8
    cw, ch = W // cols, H // rows
    radius = min(cw, ch) // 3
    for row in range(rows):
        for col in range(cols):
            cx = col * cw + cw // 2
            cy = row * ch + ch // 2
            color = PALETTE[(row * cols + col) % len(PALETTE)]
            d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color)

    # 4) 中央棋盘块（硬边缘，验证高半径下边缘扩散）
    cell = 45
    bx0, by0 = W // 2 - cell * 4, H // 2 - cell * 4
    for ry in range(8):
        for rx in range(8):
            if (rx + ry) % 2 == 0:
                x0, y0 = bx0 + rx * cell, by0 + ry * cell
                d.rectangle([x0, y0, x0 + cell - 1, y0 + cell - 1], fill=(245, 245, 245))

    img.save(path, "PNG", optimize=True)


def gen_icon(path: str, size: int = 512) -> None:
    """简单图标：圆角矩形底 + 同心圆（仅用于安装/启动标识）。"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=size // 6, fill=(17, 138, 178, 255))
    for i, color in enumerate([(255, 209, 102, 255), (230, 57, 70, 255), (255, 255, 255, 255)]):
        inset = size // 5 + i * size // 10
        d.ellipse([inset, inset, size - inset - 1, size - inset - 1], outline=color, width=size // 32)
    img.save(path, "PNG", optimize=True)


if __name__ == "__main__":
    bench = os.path.join(ROOT, "entry/src/main/resources/base/media/bench_image.png")
    start_icon = os.path.join(ROOT, "entry/src/main/resources/base/media/startIcon.png")
    app_icon = os.path.join(ROOT, "AppScope/resources/base/media/app_icon.png")
    gen_bench_image(bench)
    gen_icon(start_icon)
    gen_icon(app_icon)
    for p in (bench, start_icon, app_icon):
        print(f"generated: {os.path.relpath(p, ROOT)} ({os.path.getsize(p)} bytes)")
