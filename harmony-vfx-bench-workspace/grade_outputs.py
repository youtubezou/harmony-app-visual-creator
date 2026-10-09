#!/usr/bin/env python3
"""harmony-vfx-bench eval grading helper: programmatic checks for the benchmark-app contract.

Usage: python3 grade_outputs.py <outputs_dir> <eval_name>
eval_name in {particle-bench-app, blur-bench-app, canvas-bench-app}
Prints JSON lines: {"assertion": "...", "passed": true/false/null, "evidence": "..."}
passed=null means "needs grader judgment".
"""
import json
import re
import sys
from pathlib import Path

DEPRECATED_PATTERNS = {
    "global animateTo()": re.compile(r"(?<![\w.)])animateTo\s*\("),
    "animator.create (module-level, deprecated API 18+)": re.compile(r"(?<![\w.])animator\.create\s*\("),
    "ParticleSystem/ParticleComponent (old name)": re.compile(r"\bParticleSystem\b|\bParticleComponent\b"),
    "pageTransition (not recommended)": re.compile(r"(?<![\w.])pageTransition\s*\("),
    "TransitionOptions (deprecated)": re.compile(r"\bTransitionOptions\b"),
}

MEASUREMENT_PATTERNS = {
    "fps calculation": re.compile(r"(frameCount|frame_count|frames)\s*[/+]+|1000\s*[/]\s*(delta|elapsed|dt)|fps\s*=\s*", re.I),
    "frame time stats": re.compile(r"(frameTime|frame_time|frameCost).*(avg|average|sum|total)", re.I),
    "cpu sampling": re.compile(r"(cpuUsage|getCpuUsage|cpu_usage)", re.I),
}


def read_all_code(root: Path):
    texts = []
    for ext in ("*.ets", "*.ts", "*.json5", "*.json", "*.md"):
        for f in root.rglob(ext):
            try:
                texts.append((f, f.read_text(encoding="utf-8", errors="replace")))
            except OSError:
                pass
    return texts


def strip_comments_and_md(code_files):
    """返回只含代码行（去掉 // 注释与 /* */ 块注释与 .md 文件）的连接文本，用于废弃 API 判定。"""
    out = []
    for f, text in code_files:
        if f.suffix == ".md":
            continue
        # 去块注释
        t = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
        # 去行注释
        t = "\n".join(line.split("//")[0] for line in t.splitlines())
        out.append(t)
    return "\n".join(out)


def check(name, ok, evidence):
    return {"assertion": name, "passed": ok, "evidence": evidence}


def grade(root: Path, eval_name: str):
    results = []
    code_files = read_all_code(root)
    all_text = "\n".join(t for _, t in code_files)
    code_only = strip_comments_and_md(code_files)
    md_text = "\n".join(t for f, t in code_files if f.suffix == ".md")

    # 1. 工程结构
    required = [
        "AppScope/app.json5",
        "entry/src/main/module.json5",
        "entry/src/main/ets/entryability/EntryAbility.ets",
        "entry/src/main/resources/base/profile/main_pages.json",
        "build-profile.json5",
        "hvigorfile.ts",
        "oh-package.json5",
    ]
    all_files = [f for f in root.rglob("*") if f.is_file()]
    missing = [p for p in required if not any(str(f).endswith(p) for f in all_files)]
    results.append(check(
        "project-structure-complete: 工程含 Stage 模型必备文件",
        not missing, "全部存在" if not missing else f"缺失: {missing}"))

    # 2. Want 参数注入（代码中，非注释）
    want_parse = bool(re.search(r"want\s*\?*\.parameters|Want\s*\)", code_only))
    storage = bool(re.search(r"AppStorage|LocalStorage", code_only))
    results.append(check(
        "params-via-want-injection: 参数经 Ability Want 注入并传递到页面",
        want_parse and storage,
        f"want.parameters 解析: {want_parse}; AppStorage/LocalStorage 传递: {storage}"))

    # 3. 参数契约文档
    contract = bool(re.search(r"(键名|参数名).{0,40}(类型|type)|--p[isb]|默认值", md_text)) and \
               bool(re.search(r"(范围|range|默认|default)", md_text, re.I))
    results.append(check(
        "param-contract-doc: 交付含参数契约表",
        contract, "文档中发现参数契约要素" if contract else "未发现参数契约表"))

    # 4. hilog 参数回显
    hilog_ok = bool(re.search(r"hilog\.(info|warn|error|debug)", code_only))
    echo_ok = bool(re.search(r"LAUNCH_PARAMS|PARAMS", all_text))
    results.append(check(
        "hilog-param-echo: 统一 tag 的 hilog 参数回显日志",
        hilog_ok and echo_ok,
        f"hilog 调用: {hilog_ok}; 参数回显标记: {echo_ok}"))

    # 5. 确定性
    unseeded_random = bool(re.search(r"Math\.random\s*\(", code_only))
    seed_or_ts = bool(re.search(r"seed|种子|timestep|时间戳|elapsed|deltaTime", all_text, re.I))
    results.append(check(
        "determinism-measures: 确定性措施（种子/时间步长，无未播种 Math.random）",
        (not unseeded_random) and seed_or_ts,
        f"Math.random: {unseeded_random}; 种子/时间步长证据: {seed_or_ts}"))

    # 6. 废弃 API（仅代码，排除注释与文档中的「勿用」说明）
    hits = []
    for label, pat in DEPRECATED_PATTERNS.items():
        for m in pat.finditer(code_only):
            line = code_only[: m.start()].count("\n") + 1
            hits.append(f"{label}@line{line}")
    results.append(check(
        "no-deprecated-apis: 不使用已废弃 API",
        not hits, "未发现" if not hits else "; ".join(hits[:6])))

    # 7. 不内置测量
    mhits = [label for label, pat in MEASUREMENT_PATTERNS.items() if pat.search(code_only)]
    results.append(check(
        "no-built-in-measurement: app 不内置测量统计逻辑",
        not mhits, "未发现" if not mhits else f"疑似内置测量: {mhits}"))

    # 8. 验证命令链
    chain = all(k in all_text for k in ("hvigorw", "hdc install", "aa start"))
    snap = "snapshot_display" in all_text or "截图" in md_text
    results.append(check(
        "verification-chain-doc: 交付含 hdc 验证命令链",
        chain and snap,
        f"编译/安装/启动命令: {chain}; 截图取证: {snap}"))

    # 9. 视效特定
    if eval_name == "particle-bench-app":
        p_new = bool(re.search(r"(?<![\w.])Particle\s*\(", code_only))
        results.append(check("uses-particle-component: 粒子用当前 Particle 组件", p_new,
                             "发现 Particle()" if p_new else "未发现 Particle 组件"))
    elif eval_name == "blur-bench-app":
        blur = bool(re.search(r"\.blur\s*\(|foregroundBlurStyle|backdropBlur|backgroundBlurStyle", code_only))
        net_img = bool(re.search(r"https?://\S+\.(png|jpg|jpeg|webp)", code_only, re.I))
        results.append(check("uses-blur-api: 模糊用 blur/*BlurStyle 实现", blur,
                             "发现模糊 API" if blur else "未发现"))
        results.append(check("local-image-only: 图片本地化", not net_img,
                             "无网络图片" if not net_img else "发现网络图片 URL"))
    elif eval_name == "canvas-bench-app":
        canvas = bool(re.search(r"CanvasRenderingContext2D", code_only))
        ts = bool(re.search(r"(now|timestamp|Date\.now|elapsed|delta).*(\*|步|speed|velocity)", code_only, re.I))
        seed = bool(re.search(r"seed\s*[:=]", code_only, re.I))
        results.append(check("uses-canvas-api: 用 CanvasRenderingContext2D 绘制", canvas,
                             "发现 CanvasRenderingContext2D" if canvas else "未发现"))
        results.append(check("fixed-timestep-or-seed: 固定时间步长且随机有种子", ts and seed,
                             f"时间步长: {ts}; 种子: {seed}"))

    return results


if __name__ == "__main__":
    root = Path(sys.argv[1])
    eval_name = sys.argv[2]
    if not root.exists():
        print(json.dumps({"error": f"{root} 不存在"}))
        sys.exit(1)
    for r in grade(root, eval_name):
        print(json.dumps(r, ensure_ascii=False))
