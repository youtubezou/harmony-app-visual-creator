#!/usr/bin/env python3
"""刷新归档：按 references/api-docs/manifest.txt 从 OpenHarmony docs master 重新拉取。
跨平台（Windows/macOS/Linux），仅依赖 Python 标准库。

用法：python scripts/refresh_api_docs.py
"""
import sys
import time
import urllib.request
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
DEST = SKILL_DIR / "references" / "api-docs"
BASE = "https://gitee.com/openharmony/docs/raw/master/zh-cn"


def route(path: str):
    """gitee 路径 → 归档子目录（与归档脚本规则一致）"""
    name = path.rsplit("/", 1)[-1]
    if path.startswith("application-dev/ui/") or path.startswith("application-dev/quick-start/"):
        return "guides", name
    if path.startswith("application-dev/tools/"):
        return "tools", name
    if "/reference/apis-arkui/" in path or "/reference/apis-arkgraphics2d/" in path:
        return "api", name
    return None, name


def fetch(url: str, dest: Path, retries: int = 3) -> bool:
    for attempt in range(1, retries + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = resp.read()
            if data and not data.startswith(b"<a href"):  # gitee 302 占位页检测
                dest.write_bytes(data)
                return True
        except Exception as ex:
            print(f"  attempt {attempt} failed: {ex}", file=sys.stderr)
        time.sleep(2)
    return False


def main():
    manifest = DEST / "manifest.txt"
    if not manifest.exists():
        print("manifest.txt 不存在", file=sys.stderr)
        return 1
    ok = fail = 0
    for line in manifest.read_text(encoding="utf-8").splitlines():
        p = line.strip()
        if not p:
            continue
        sub, name = route(p)
        if sub is None:
            print(f"SKIP: {p}")
            continue
        target = DEST / sub / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if fetch(f"{BASE}/{p}", target):
            ok += 1
        else:
            fail += 1
            print(f"FAIL: {p}")
    print(f"refresh done: ok={ok} fail={fail}")
    print("刷新后请同步更新 INDEX.md 顶部的归档日期")
    return 0 if fail == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
