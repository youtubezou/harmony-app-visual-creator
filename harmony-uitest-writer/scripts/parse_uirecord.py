#!/usr/bin/env python3
"""parse_uirecord.py — 把 HarmonyOS uitest uiRecord 产物解析为规范化操作时间线 JSON。

用法:
    python3 parse_uirecord.py --record record.csv [--layouts <目录>] [--out timeline.json]

输入容忍三种格式（不同系统版本产物不一）:
    1. 每行一条 JSON 对象（JSON Lines）
    2. 单个 JSON 数组
    3. 带表头的 CSV（fingerList 单元格内嵌 JSON 字符串）

输出: 操作时间线 JSON（数组），每项含 action/坐标/时长/命中控件/选择器建议/warnings。
选择器策略（与 SKILL.md 一致）: W1_ID → W1_Text → type(+bounds 说明) → 裸坐标兜底。
"""

import argparse
import csv
import io
import json
import os
import re
import sys

# uiRecord 官方支持的事件类型 → 用例 action 名
OP_MAP = {
    "click": "click",
    "doubleClick": "doubleClick",
    "longClick": "longClick",
    "drag": "drag",
    "swipe": "swipe",
    "fling": "fling",
}

# 可能承载文本输入的控件类型（点击它们后若没有后续输入信息，要发 warning）
INPUT_WIDGET_TYPES = {"TextInput", "TextArea", "SearchBar", "RichEditor"}


def load_records(path: str) -> list:
    """按 3 种候选格式依次尝试解析录制文件，返回原始记录 dict 列表。"""
    raw = open(path, "r", encoding="utf-8-sig").read().strip()
    if not raw:
        sys.exit(f"录制文件为空: {path}")

    # 尝试 1：整体是 JSON（数组或单个对象）
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            data = [data]
        return data
    except json.JSONDecodeError:
        pass

    # 尝试 2：JSON Lines
    lines = [ln for ln in raw.splitlines() if ln.strip()]
    try:
        return [json.loads(ln) for ln in lines]
    except json.JSONDecodeError:
        pass

    # 尝试 3：CSV（fingerList 单元格可能是 JSON）
    reader = csv.DictReader(io.StringIO(raw))
    records = []
    for row in reader:
        rec = dict(row)
        fl = rec.get("fingerList")
        if isinstance(fl, str) and fl.strip():
            try:
                rec["fingerList"] = json.loads(fl)
            except json.JSONDecodeError:
                # 有些实现用单引号，尝试宽松转换
                try:
                    rec["fingerList"] = json.loads(fl.replace("'", '"'))
                except json.JSONDecodeError:
                    rec["fingerList"] = []
        records.append(rec)
    if records:
        return records
    sys.exit(f"无法识别录制文件格式: {path}")


def to_int(value, default=0):
    try:
        return int(float(str(value).strip()))
    except (TypeError, ValueError):
        return default


def parse_widget(finger: dict, prefix: str) -> dict:
    """从 fingerList 条目提取 W1_*/W2_* 控件信息。"""
    widget = {
        "id": str(finger.get(f"{prefix}_ID", "") or "").strip(),
        "text": str(finger.get(f"{prefix}_Text", "") or "").strip(),
        "type": str(finger.get(f"{prefix}_Type", "") or "").strip(),
        "bounds": str(finger.get(f"{prefix}_BOUNDS", "") or "").strip(),
        "hier": str(finger.get(f"{prefix}_HIER", "") or "").strip(),
    }
    return widget


def suggest_selector(widget: dict, start: dict) -> tuple:
    """按 SKILL.md 决策规则给出 ON 选择器建议与风险级别。

    返回 (selector_dict, risk, note)
    """
    if widget["id"]:
        return (
            {"strategy": "id", "on": f'ON.id("{widget["id"]}")'},
            "low",
            "",
        )
    if widget["text"]:
        return (
            {"strategy": "text", "on": f'ON.text("{widget["text"]}")'},
            "medium",
            "text 选择器受文案/多语言影响，注意回归失效风险",
        )
    if widget["type"]:
        return (
            {
                "strategy": "type",
                "on": f'ON.type("{widget["type"]}")',
                "hint": f"bounds={widget['bounds']}",
            },
            "high",
            "type 选择器可能命中多个控件，生成代码时需加 .within(...) 或索引收窄，并人工确认",
        )
    return (
        {"strategy": "coordinate", "on": f"driver.click({start['x']}, {start['y']})"},
        "high",
        "未能命中任何控件信息，只能坐标兜底；分辨率相关，强烈建议人工确认",
    )


def find_layout_snapshot(layouts_dir: str, seq: int) -> str:
    """按文件名 layout_<ts>_<seq>.json 匹配该操作序号对应的布局快照。"""
    if not layouts_dir or not os.path.isdir(layouts_dir):
        return ""
    pat = re.compile(rf"^layout_\d+_{seq}\.json$")
    for name in sorted(os.listdir(layouts_dir)):
        if pat.match(name):
            return name
    return ""


def normalize(records: list, layouts_dir: str) -> list:
    timeline = []
    for seq, rec in enumerate(records, start=1):
        op = str(rec.get("OP_TYPE", "") or "").strip()
        fingers = rec.get("fingerList") or [{}]
        finger = fingers[0] if isinstance(fingers, list) and fingers else {}

        start = {"x": to_int(finger.get("X_POSI")), "y": to_int(finger.get("Y_POSI"))}
        end = {"x": to_int(finger.get("X2_POSI", start["x"])), "y": to_int(finger.get("Y2_POSI", start["y"]))}
        widget = parse_widget(finger, "W1")
        selector, risk, note = suggest_selector(widget, start)

        warnings = []
        if note:
            warnings.append(note)
        if widget["type"] in INPUT_WIDGET_TYPES:
            warnings.append(
                "命中输入类控件但 uiRecord 不记录文本输入——请从同步录屏或用户处确认输入值，不要臆造"
            )
        if op and op not in OP_MAP:
            warnings.append(f"未知 OP_TYPE={op}，请人工确认语义")

        timeline.append({
            "seq": seq,
            "action": OP_MAP.get(op, op or "unknown"),
            "bundle": str(rec.get("BUNDLE", "") or ""),
            "ability": str(rec.get("ABILITY", "") or ""),
            "start": start,
            "end": end,
            "duration_ms": round(to_int(rec.get("duration")) / 1_000_000, 1),
            "widget": widget,
            "selector": selector,
            "selector_risk": risk,
            "layout_snapshot": find_layout_snapshot(layouts_dir, seq),
            "warnings": warnings,
        })
    return timeline


def main():
    ap = argparse.ArgumentParser(description="解析 uitest uiRecord 产物为操作时间线 JSON")
    ap.add_argument("--record", required=True, help="record.csv 路径")
    ap.add_argument("--layouts", default="", help="layout_*.json 所在目录（可选）")
    ap.add_argument("--out", default="", help="输出文件（缺省打印到 stdout）")
    args = ap.parse_args()

    records = load_records(args.record)
    timeline = normalize(records, args.layouts)

    out = json.dumps(timeline, ensure_ascii=False, indent=2)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(out + "\n")
        n_warn = sum(len(t["warnings"]) for t in timeline)
        print(f"已解析 {len(timeline)} 个操作 → {args.out}（{n_warn} 条 warning 待确认）")
        for t in timeline:
            for w in t["warnings"]:
                print(f"  [seq {t['seq']}] {w}", file=sys.stderr)
    else:
        print(out)


if __name__ == "__main__":
    main()
