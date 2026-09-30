#!/usr/bin/env python3
"""harmony-app eval grading helper: programmatic checks for scriptable assertions.

Usage: python3 grade_outputs.py <outputs_dir> <eval_name>
Prints JSON lines: {"assertion": "...", "passed": true/false, "evidence": "..."}
Grader agent should combine these with qualitative checks for the remaining assertions.
"""
import json
import re
import sys
from pathlib import Path

DEPRECATED_PATTERNS = {
    "global animateTo()": re.compile(r"(?<![\w.)])animateTo\s*\("),
    "animator.create (module-level, deprecated API 18+)": re.compile(r"\banimator\.create\s*\("),
    "ParticleSystem/ParticleComponent (old name)": re.compile(r"\bParticleSystem\b|\bParticleComponent\b"),
    "pageTransition (not recommended)": re.compile(r"\bpageTransition\s*\("),
    "TransitionOptions (deprecated)": re.compile(r"\bTransitionOptions\b"),
}


def find_files(root: Path, pattern: str):
    return sorted(root.rglob(pattern))


def read_all_code(root: Path):
    texts = []
    for ext in ("*.ets", "*.ts", "*.json5", "*.json", "*.md"):
        for f in root.rglob(ext):
            try:
                texts.append((f, f.read_text(encoding="utf-8", errors="replace")))
            except OSError:
                pass
    return texts


def check(name, ok, evidence):
    return {"assertion": name, "passed": bool(ok), "evidence": evidence}


def grade(root: Path, eval_name: str):
    results = []
    code_files = read_all_code(root)
    all_code = "\n".join(t for _, t in code_files)

    # --- deprecated API scan (shared negative assertions) ---
    deprecated_hits = []
    for label, pat in DEPRECATED_PATTERNS.items():
        hits = []
        for f, text in code_files:
            for m in pat.finditer(text):
                line = text[: m.start()].count("\n") + 1
                hits.append(f"{f.relative_to(root)}:{line}")
        if hits:
            deprecated_hits.append(f"{label} -> {', '.join(hits[:5])}")
    no_deprecated = not deprecated_hits
    dep_evidence = "未发现废弃 API" if no_deprecated else "; ".join(deprecated_hits)

    kit_ok = "@kit." in all_code
    ohos_animator = re.search(r"from ['\"]@ohos\.animator['\"]", all_code)

    if eval_name == "weather-particles-full-project":
        required = [
            "AppScope/app.json5",
            "entry/src/main/module.json5",
            "entry/src/main/ets/entryability/EntryAbility.ets",
            "entry/src/main/resources/base/profile/main_pages.json",
            "build-profile.json5",
            "hvigorfile.ts",
            "oh-package.json5",
        ]
        missing = [p for p in required if not list(root.rglob(Path(p).name)) and not (root / p).exists()]
        # more precise: match by suffix path
        missing = [p for p in required if not any(str(f).endswith(p) for f in root.rglob("*") if f.is_file())]
        results.append(check(
            "project-structure-complete: 工程包含 Stage 模型必备文件",
            not missing,
            "全部存在" if not missing else f"缺失: {missing}"))

        particle_new = re.search(r"\bParticle\s*\(", all_code)
        particle_old = re.search(r"\bParticleSystem\b|\bParticleComponent\b", all_code)
        results.append(check(
            "uses-current-particle-component: 粒子动画使用当前组件名 Particle",
            bool(particle_new) and not particle_old,
            f"Particle 组件出现: {bool(particle_new)}; 旧名出现: {bool(particle_old)}"))

        results.append(check(
            "no-deprecated-global-animateto: 不使用已废弃的全局 animateTo()",
            no_deprecated, dep_evidence))

        mp = list(root.rglob("main_pages.json"))
        routes_ok = False
        route_evi = "未找到 main_pages.json"
        if mp:
            try:
                src = json.loads(mp[0].read_text(encoding="utf-8")).get("src", [])
                pages = {p.stem for p in (root / "entry/src/main/ets/pages").rglob("*.ets")} if (root / "entry/src/main/ets/pages").exists() else set()
                routes_ok = bool(src) and (not pages or {s.split("/")[-1] for s in src} >= pages)
                route_evi = f"main_pages.json src={src}, pages 目录文件={sorted(pages)}"
            except Exception as ex:
                route_evi = f"解析失败: {ex}"
        results.append(check("routes-registered: main_pages.json 注册了全部页面", routes_ok, route_evi))

        results.append(check(
            "uses-kit-namespace: 使用 @kit.* 命名空间且未用废弃 @ohos.animator",
            kit_ok and not ohos_animator,
            f"@kit 导入: {kit_ok}; @ohos.animator 导入: {bool(ohos_animator)}"))

        results.append(check(
            "delivery-includes-run-and-version-notes: 交付说明含运行方式与 API 版本声明（定性，供 grader 复核）",
            None,
            "需人工/grader 查看 outputs 中的说明文档"))

    elif eval_name == "like-burst-component":
        ets = find_files(root, "*.ets")
        comp = [f for f, t in code_files if f.suffix == ".ets" and "@Component" in t and "struct" in t]
        results.append(check(
            "produces-reusable-component: 产出独立可复用 .ets 组件",
            bool(comp),
            f"组件文件: {[str(f.relative_to(root)) for f, _ in code_files if f.suffix=='.ets']}" if ets else "无 .ets 文件"))

        results.append(check(
            "uses-current-api-no-deprecated: 不使用已废弃 API",
            no_deprecated, dep_evidence))

        has_guide = any(f.suffix == ".md" for f, _ in code_files) or "集成" in all_code or "使用说明" in all_code
        results.append(check(
            "has-integration-guide: 附集成说明",
            has_guide, "存在说明文档/集成说明" if has_guide else "未发现集成说明"))

        evi = re.findall(r"(gitee\.com/openharmony|developer\.huawei\.com|ohpm\.openharmony\.cn|gitcode\.com)", all_code)
        results.append(check(
            "evidence-of-api-verification: 有联网核实 API 的证据",
            bool(evi),
            f"引用来源: {sorted(set(evi))[:6]}" if evi else "outputs 中未见官方来源引用（grader 可复核 agent 报告）"))

        params_ok = bool(re.search(r"(const|readonly|@Prop).*(duration|count|color|radius|speed)", all_code, re.I))
        results.append(check(
            "params-extracted-as-constants: 动画参数提取为可配置常量",
            params_ok, "发现参数常量/Props" if params_ok else "未发现参数提取"))

    elif eval_name == "music-player-combo-effects":
        pausable = bool(re.search(r"createAnimator|\.pause\s*\(|\.play\s*\(|isPlaying", all_code))
        results.append(check(
            "rotation-is-pausable: 封面旋转动画可暂停/恢复",
            pausable, "发现暂停/播放控制" if pausable else "未发现可暂停机制"))

        blur_ok = bool(re.search(r"foregroundBlurStyle|backgroundBlurStyle|backdropBlur", all_code))
        results.append(check(
            "frosted-glass-uses-blurstyle: 毛玻璃使用 *BlurStyle/backdropBlur",
            blur_ok, "发现模糊样式 API" if blur_ok else "未发现 BlurStyle 系列 API"))

        geo_ok = bool(re.search(r"\bgeometryTransition\b", all_code))
        results.append(check(
            "shared-element-uses-geometrytransition: 共享元素转场使用 geometryTransition",
            geo_ok, "发现 geometryTransition" if geo_ok else "未发现 geometryTransition"))

        results.append(check("no-deprecated-apis: 不使用已废弃 API", no_deprecated, dep_evidence))

        any_hits = re.findall(r":\s*any\b|as\s+any\b", all_code)
        results.append(check(
            "arkts-strict-no-any: ArkTS 严格语法无 any",
            not any_hits,
            "未发现 any" if not any_hits else f"发现 {len(any_hits)} 处 any"))

    return results


if __name__ == "__main__":
    root = Path(sys.argv[1])
    eval_name = sys.argv[2]
    if not root.exists():
        print(json.dumps({"error": f"{root} 不存在"}))
        sys.exit(1)
    for r in grade(root, eval_name):
        print(json.dumps(r, ensure_ascii=False))
