#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
VFXBENCH blur benchmark 资产生成脚本（确定性：固定随机种子）。

生成：
  1. entry/src/main/resources/base/media/bench_image.png
     —— 1080x1920 基准测试图：彩虹渐变底 + 网格 + 高频几何细节 + 固定种子噪点。
     设计目标：包含足够的高频细节与大面积色块，使 0~100 模糊半径下
     肉眼可辨差异（截图取证用），且跨设备内容完全固定（负载确定）。
  2. AppScope/resources/base/media/app_icon.png 与
     entry/src/main/resources/base/media/app_icon.png
     —— 512x512 应用图标（无字体依赖，纯几何图形）。

复现：python3 scripts/generate_assets.py
依赖：Pillow + numpy（脚本顶部注明版本无关，仅用基础 API）。
"""

import os
import numpy as np
from PIL import Image, ImageDraw

SEED = 42  # 契约 3：确定性。改种子 = 改被测内容，勿动。

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BENCH_OUT = os.path.join(
    ROOT, "entry", "src", "main", "resources", "base", "media", "bench_image.png")
ICON_ENTRY_OUT = os.path.join(
    ROOT, "entry", "src", "main", "resources", "base", "media", "app_icon.png")
ICON_APPSCOPE_OUT = os.path.join(
    ROOT, "AppScope", "resources", "base", "media", "app_icon.png")

W, H = 1080, 1920


def make_base_gradient() -> np.ndarray:
    """对角彩虹渐变底（完全解析式，无随机）。"""
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    u = (x / W + y / H) / 2.0  # 0..1 对角参数
    # 多段色相：红 -> 黄 -> 绿 -> 青 -> 蓝 -> 品红
    hue = (u * 300.0) % 360.0
    # HSV->RGB（饱和度 0.85，明度 0.9），纯 numpy 实现
    h = hue / 60.0
    c = 0.9 * 0.85
    xx = c * (1 - np.abs(h % 2 - 1))
    m = 0.9 - c
    r = np.select([h < 1, h < 2, h < 3, h < 4, h < 5, h >= 5],
                  [c, xx, 0, 0, xx, c]) + m
    g = np.select([h < 1, h < 2, h < 3, h < 4, h < 5, h >= 5],
                  [xx, c, c, xx, 0, 0]) + m
    b = np.select([h < 1, h < 2, h < 3, h < 4, h < 5, h >= 5],
                  [0, 0, xx, c, c, xx]) + m
    return np.stack([r, g, b], axis=-1) * 255.0


def add_noise(img: np.ndarray) -> np.ndarray:
    """固定种子低幅噪点（高频细节源）。"""
    rng = np.random.default_rng(SEED)
    noise = rng.integers(-32, 33, size=img.shape[:2], dtype=np.int16)
    out = img + noise[..., None]
    return np.clip(out, 0, 255)


def draw_details(im: Image.Image) -> None:
    """规则网格 + 固定种子几何形状 + 大色块（Pillow 绘制层）。"""
    d = ImageDraw.Draw(im, "RGBA")

    # 1) 规则网格（48px 间距，半透明白线）——模糊后可辨的重要高频参照
    for gx in range(0, W, 48):
        d.line([(gx, 0), (gx, H)], fill=(255, 255, 255, 60), width=1)
    for gy in range(0, H, 48):
        d.line([(0, gy), (W, gy)], fill=(255, 255, 255, 60), width=1)

    # 2) 四角大色块（大面积纯色，验证大半径模糊下的颜色扩散）
    d.rectangle([0, 0, 200, 200], fill=(255, 255, 255, 255))
    d.rectangle([W - 200, 0, W, 200], fill=(0, 0, 0, 255))
    d.rectangle([0, H - 200, 200, H], fill=(255, 0, 0, 255))
    d.rectangle([W - 200, H - 200, W, H], fill=(0, 0, 255, 255))

    # 3) 中央同心圆环（锐利边缘，模糊半径的直接视觉标尺）
    cx, cy = W // 2, H // 2
    for i, r in enumerate(range(300, 40, -40)):
        col = (255, 255, 255, 220) if i % 2 == 0 else (0, 0, 0, 220)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=14)

    # 4) 固定种子随机圆点与方块（中高频细节）
    rng = np.random.default_rng(SEED + 1)
    palette = [(255, 80, 80), (80, 255, 80), (80, 80, 255),
               (255, 255, 80), (80, 255, 255), (255, 80, 255)]
    for _ in range(300):
        px, py = int(rng.integers(0, W)), int(rng.integers(0, H))
        pr = int(rng.integers(4, 20))
        c = palette[int(rng.integers(0, len(palette)))]
        d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=c + (200,))
    for _ in range(150):
        px, py = int(rng.integers(0, W)), int(rng.integers(0, H))
        s = int(rng.integers(6, 26))
        c = palette[int(rng.integers(0, len(palette)))]
        d.rectangle([px, py, px + s, py + s], outline=c + (220,), width=2)


def gen_bench_image() -> None:
    base = make_base_gradient()
    base = add_noise(base)
    im = Image.fromarray(base.astype(np.uint8), "RGB")
    draw_details(im)
    im.save(BENCH_OUT, "PNG", optimize=True)
    print(f"[gen] {BENCH_OUT} {im.size} {os.path.getsize(BENCH_OUT)} bytes")


def gen_icon() -> None:
    """512x512 图标：深色底 + 叠层光斑（示意'模糊'主题），无字体依赖。"""
    S = 512
    im = Image.new("RGB", (S, S), (18, 18, 24))
    d = ImageDraw.Draw(im, "RGBA")
    rng = np.random.default_rng(SEED)
    for i in range(7):
        r = 200 - i * 24
        c = palette_c = (60 + i * 28, 120 + i * 12, 255 - i * 20, 40)
        d.ellipse([S // 2 - r, S // 2 - r, S // 2 + r, S // 2 + r], fill=c)
    for _ in range(24):
        px, py = int(rng.integers(40, S - 40)), int(rng.integers(40, S - 40))
        pr = int(rng.integers(8, 42))
        d.ellipse([px - pr, py - pr, px + pr, py + pr],
                  fill=(255, 255, 255, int(rng.integers(20, 90))))
    im.save(ICON_ENTRY_OUT, "PNG", optimize=True)
    im.save(ICON_APPSCOPE_OUT, "PNG", optimize=True)
    print(f"[gen] {ICON_ENTRY_OUT}")
    print(f"[gen] {ICON_APPSCOPE_OUT}")


if __name__ == "__main__":
    gen_bench_image()
    gen_icon()
