#!/usr/bin/env python3
"""对 iteration-1 各 run 目录的产出做程序化断言检查，生成 grading.json。

用法: python3 grade_outputs.py harmony-uitest-writer-workspace/iteration-1
每个 run 目录（eval-*/{with_skill,without_skill}）下生成 grading.json，
格式: {"expectations": [{"text": ..., "passed": bool|null, "evidence": ...}]}
passed=null 表示该断言需人工复核（无法程序化判定）。
"""
import json
import os
import re
import sys

ROOT = sys.argv[1]

ALLOWED_IDS = {
    "eval-0-login-flow": {"account_input", "password_input", "btn_login", "song_list"},
    "eval-1-list-favorite": {"song_list", "tv_song_title", "btn_play_pause"},
    "eval-2-csv-input-gap": {"search_input"},
}
ALLOWED_TEXTS = {
    "eval-0-login-flow": {"登录", "推荐", "我的", "晴天", "夜曲"},
    "eval-1-list-favorite": {"夜曲", "暂停"},
    "eval-2-csv-input-gap": set(),
}


def read_all(outputs_dir):
    """读取 outputs 下全部文本内容，返回 {文件名: 内容}"""
    texts = {}
    for dirpath, _, files in os.walk(outputs_dir):
        for f in files:
            p = os.path.join(dirpath, f)
            try:
                texts[f] = open(p, encoding="utf-8").read()
            except (UnicodeDecodeError, OSError):
                pass
    return texts


def find_json(texts, name_part):
    for name, content in texts.items():
        if name_part in name:
            try:
                return json.loads(content)
            except json.JSONDecodeError:
                return None
    return None


def ets_content(texts, strip_comments=False):
    code = "\n".join(c for n, c in texts.items() if n.endswith(".ets"))
    if strip_comments:
        code = re.sub(r"/\*.*?\*/", "", code, flags=re.DOTALL)
        code = re.sub(r"//[^\n]*", "", code)
    return code


def timeline_events(timeline):
    """容忍数组或 {events|steps|timeline: [...]} 两种结构，返回操作列表。"""
    if isinstance(timeline, list):
        return timeline
    if isinstance(timeline, dict):
        for key in ("events", "steps", "timeline", "operations"):
            if isinstance(timeline.get(key), list):
                return timeline[key]
    return []


def readme_content(texts):
    return "\n".join(c for n, c in texts.items() if "readme" in n.lower())


def cases_content(texts):
    return "\n".join(c for n, c in texts.items() if "case" in n.lower())


def check(eval_name, texts):
    results = []
    blob = "\n".join(texts.values())
    ets = ets_content(texts)
    ets_exec = ets_content(texts, strip_comments=True)
    timeline = find_json(texts, "timeline")
    events = timeline_events(timeline)
    readme = readme_content(texts)
    cases = cases_content(texts)

    def add(text, passed, evidence):
        results.append({"text": text, "passed": passed, "evidence": evidence})

    def has(pattern, where):
        return bool(re.search(pattern, where, re.IGNORECASE))

    if not texts:
        add("产出非空", False, "outputs 目录没有任何可读文件")
        return results

    # ---- 通用检查 ----
    if events:
        add("timeline-parsed: 产出操作时间线", True, f"timeline 解析成功，{len(events)} 个操作")
    else:
        add("timeline-parsed: 产出操作时间线", False, "未找到可解析的 timeline.json")

    if eval_name == "eval-0-login-flow":
        add("timeline 3 步 click、id 选择器",
            bool(len(events) == 3
                 and all("click" in json.dumps(t, ensure_ascii=False) for t in events)),
            f"timeline 长度={len(events)}")
        add("input-values-from-user: 采用用户提供的账号密码",
            has(r"test@example\.com", blob) and has(r"Passw0rd", blob),
            "在产出中搜索 test@example.com / Passw0rd")
        add("has-derived-negative-case: 含推导的负向用例",
            bool(re.search(r"derived|负向|反向|推导|边界", cases)) and bool(re.search(r"TC-|case", cases)),
            "cases 中搜索 derived/负向/推导/边界 关键词")

    if eval_name == "eval-1-list-favorite":
        add("swipe-preserved-with-coords: 保留滑动及起止坐标",
            has(r"swipe", blob) and has(r"700", blob) and has(r"300", blob),
            "搜索 swipe 与坐标 700/300")
        add("weak-selector-flagged: 弱选择器标风险并给收窄方案",
            bool(re.search(r"风险|高风险|weak|人工确认|within|收窄|索引", blob)),
            "搜索 风险/人工确认/within/收窄 关键词")
        add("assertion-from-layout: 断言使用布局快照中的元素",
            has(r"btn_play_pause", blob) or has(r"夜曲", ets),
            "搜索 btn_play_pause / 夜曲")
        add("no-fake-device-verification: 不声称真机回放通过",
            not has(r"已在真机|回放通过|验证通过|hdc shell aa test.*通过", blob)
            or has(r"未真机|无法验证|待验证|未执行", blob),
            "搜索虚假验证声明；同时检查是否有未验证说明")

    if eval_name == "eval-2-csv-input-gap":
        add("csv-header-format-handled: 解析出 click+fling 两个操作",
            bool(len(events) == 2
                 and has(r"fling", json.dumps(events, ensure_ascii=False))),
            f"timeline 长度={len(events)}")
        add("input-gap-surfaced: 指出输入关键词缺失并标注待确认",
            bool(re.search(r"关键词|输入值|待确认|缺失|uiRecord 不|不记录.*输入|请.*提供|向用户", blob)),
            "搜索 关键词/待确认/缺失 等关键词")
        add("fling-mapped: fling 被映射为 fling/swipe 操作",
            has(r"fling", blob),
            "搜索 fling")
        add("no-layout-stated: 说明无布局快照导致断言依据受限",
            bool(re.search(r"布局快照|layout|dumpLayout|断言依据|补抓", blob)),
            "搜索 布局快照/dumpLayout/补抓 关键词")

    # ---- 所有 eval 的 .ets 骨架与选择器检查 ----
    if ets:
        add("ets-uses-official-skeleton: '@ohos/hypium' + '@kit.TestKit' 骨架",
            has(r"@ohos/hypium", ets) and has(r"@kit\.TestKit", ets)
            and has(r"Driver\.create", ets),
            "检查 import 与 Driver.create")
        add("waits-not-sleeps: 无裸 sleep/setTimeout 等待",
            not has(r"setTimeout|sleep\s*\(", ets) or has(r"waitFor", ets),
            "搜索 setTimeout/sleep；存在 waitFor 视为缓解")
        # 选择器检查：ON.id("...") 的值必须在允许集合内
        used_ids = set(re.findall(r'ON\.id\(["\']([^"\']+)["\']\)', ets_exec))
        unknown = used_ids - ALLOWED_IDS[eval_name]
        add("selectors-from-evidence: ON.id 选择器全部来自录制数据",
            not unknown,
            f"使用的 id={sorted(used_ids)}；未知 id={sorted(unknown)}")
    else:
        add("ets-uses-official-skeleton: '@ohos/hypium' + '@kit.TestKit' 骨架", False, "未产出 .ets 文件")
        add("waits-not-sleeps", None, "无 .ets 可检查")
        add("selectors-from-evidence", None, "无 .ets 可检查")

    add("case-json-structured: 用例 JSON 结构完整",
        bool(re.search(r'"steps"', cases) and re.search(r'"expected"', cases)),
        "cases 文件搜索 steps/expected 字段")

    return results


def main():
    for eval_dir in sorted(os.listdir(ROOT)):
        eval_path = os.path.join(ROOT, eval_dir)
        if not os.path.isdir(eval_path) or not eval_dir.startswith("eval-"):
            continue
        for cfg in ("with_skill", "without_skill"):
            out_dir = os.path.join(eval_path, cfg, "outputs")
            if not os.path.isdir(out_dir):
                continue
            texts = read_all(out_dir)
            expectations = check(eval_dir, texts)
            passed = sum(1 for e in expectations if e["passed"] is True)
            failed = sum(1 for e in expectations if e["passed"] is False)
            total = passed + failed
            grading = {"eval": eval_dir, "config": cfg,
                       "summary": {"pass_rate": (passed / total) if total else 0.0,
                                   "passed": passed, "failed": failed, "total": total},
                       "expectations": expectations}
            gp = os.path.join(eval_path, cfg, "grading.json")
            json.dump(grading, open(gp, "w"), ensure_ascii=False, indent=2)
            print(f"{eval_dir}/{cfg}: {passed}/{total} 通过（产物 {len(texts)} 个文件）")


if __name__ == "__main__":
    main()
