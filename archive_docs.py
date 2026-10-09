#!/usr/bin/env python3
"""把 research/raw 中已核实的官方文档归档到 harmony-vfx-bench/references/api-docs/，
并生成 INDEX.md（清单）与 manifest.txt（gitee 源路径，供 refresh 脚本使用）。"""
import shutil
from pathlib import Path

BASE = Path("/Volumes/Ext/Workspace/ai-ws/harmony-app-visual-creator")
RAW = BASE / "research/raw"
DEST = BASE / "harmony-vfx-bench/references/api-docs"
SRC_URL = "https://gitee.com/openharmony/docs/raw/master/zh-cn"

# (源文件名, 归档子目录, 归档文件名, 主题说明, gitee路径)
RULES = []
def add(src, sub, name, topic, gitee_path):
    RULES.append((src, sub, name, topic, gitee_path))

GUIDE_TOPICS = {
    "arkts-attribute-animation-overview.md": "属性动画概述（animateTo/animation/keyframe 三接口对比）",
    "arkts-attribute-animation-apis.md": "属性动画接口用法（UIContext.animateTo 正确姿势）",
    "arkts-animator.md": "帧动画 createAnimator（模块级 create 已废弃）",
    "arkts-particle-animation.md": "粒子动画 Particle 组件",
    "arkts-transition-overview.md": "转场动画概述",
    "arkts-enter-exit-transition.md": "组件出现/消失转场",
    "arkts-shared-element-transition.md": "共享元素转场 geometryTransition（一镜到底）",
    "arkts-navigation-animation.md": "Navigation 转场（页面转场当前推荐体系）",
    "arkts-page-transition-animation.md": "页面转场（官方标注不推荐）",
    "arkts-modal-transition.md": "模态转场 bindSheet/bindContentCover",
    "arkts-blur-effect.md": "模糊家族 blur/backdropBlur/*BlurStyle/motionBlur",
    "arkts-shadow-effect.md": "阴影",
    "arkts-color-effect.md": "颜色效果",
    "arkts-graphics-display.md": "图形显示",
    "arkts-component-animation.md": "组件动画",
    "arkts-custom-attribute-animation.md": "自定义属性动画",
    "arkts-animation-smoothing.md": "动画流畅度优化",
    "arkts-drawing-customization-on-canvas.md": "Canvas 自绘",
    "arkts-geometric-shape-drawing.md": "几何图形绘制（Shape/Path/Circle）",
    "napi-xcomponent-guidelines.md": "XComponent 自定义渲染（native/EGL）",
    "application-package-structure-stage.md": "Stage 模型工程结构",
    "application-configuration-file-overview-stage.md": "应用配置文件（app.json5/module.json5）",
    "start-with-ets-stage.md": "Stage 模型入门",
}
for name, topic in GUIDE_TOPICS.items():
    prefix = "application-dev_quick-start_" if name.startswith(("application-", "start-")) else "application-dev_ui_"
    add(prefix + name, "guides", name, topic, f"application-dev/{'quick-start' if prefix.endswith('quick-start_') else 'ui'}/{name}")

API_TOPICS = {
    "ts-explicit-animation.md": "AnimateParam 参数（全局 animateTo 已废弃标注）",
    "ts-animatorproperty.md": "animation 属性接口",
    "ts-keyframeAnimateTo.md": "关键帧动画",
    "js-apis-animator.md": "Animator 模块（模块级 create 废弃说明）",
    "arkts-apis-uicontext-uicontext.md": "UIContext（animateTo/createAnimator 当前入口）",
    "ts-particle-animation.md": "Particle 组件 API 全文",
    "ts-transition-animation-component.md": "transition（TransitionEffect，TransitionOptions 废弃）",
    "ts-transition-animation-geometrytransition.md": "geometryTransition API",
    "ts-transition-animation-shared-elements.md": "共享元素转场 API",
    "ts-page-transition-animation.md": "pageTransition API（不推荐）",
    "ts-motion-path-animation.md": "路径动画",
    "ts-basic-components-xcomponent.md": "XComponent 组件",
    "ts-components-canvas-canvas.md": "Canvas 组件",
    "ts-canvasrenderingcontext2d.md": "CanvasRenderingContext2D 全部绘制方法",
    "ts-offscreencanvasrenderingcontext2d.md": "离屏 Canvas 上下文",
    "ts-universal-attributes-click-effect.md": "点击效果属性",
    "ts-universal-attributes-filter-effect.md": "滤镜效果属性",
    "ts-universal-attributes-foreground-blur-style.md": "前景模糊样式 BlurStyle",
    "ts-universal-attributes-foreground-effect.md": "前景效果",
    "ts-universal-attributes-hover-effect.md": "悬停效果",
    "ts-universal-attributes-image-effect.md": "图像效果（blur/shadow/grayscale/brightness 等）",
    "ts-universal-attributes-modal-transition.md": "模态转场属性（bindContentCover）",
    "ts-universal-attributes-sheet-transition.md": "半模态转场属性（bindSheet）",
    "ts-universal-attributes-motionBlur.md": "运动模糊",
    "ts-universal-attributes-spatial-effect.md": "空间效果",
    "ts-universal-attributes-use-effect.md": "组件效果开关",
    "js-apis-effectKit.md": "effectKit 离线图像处理",
    "js-apis-uiEffect.md": "uiEffect 实时组件效果",
    "arkts-apis-graphics-drawing-ShaderEffect.md": "drawing ShaderEffect",
    "capi-effectkit.md": "effectKit C API",
    "capi-effectkit-oh-filter.md": "OH_Filter",
    "capi-effectkit-oh-filter-colormatrix.md": "OH_Filter_ColorMatrix",
    "capi-drawing-shader-effect-h.md": "drawing shader effect C 头文件",
    "capi-drawing-oh-drawing-shadereffect.md": "OH_Drawing_ShaderEffect",
}
for name, topic in API_TOPICS.items():
    if name.startswith("ts-") or name == "js-apis-animator.md" or name == "arkts-apis-uicontext-uicontext.md":
        if name == "js-apis-animator.md":
            src = "application-dev_reference_apis-arkui_js-apis-animator.md"
            gp = "application-dev/reference/apis-arkui/js-apis-animator.md"
        elif name == "arkts-apis-uicontext-uicontext.md":
            src = "application-dev_reference_apis-arkui_arkts-apis-uicontext-uicontext.md"
            gp = "application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md"
        else:
            src = f"application-dev_reference_apis-arkui_arkui-ts_{name}"
            gp = f"application-dev/reference/apis-arkui/arkui-ts/{name}"
    else:
        src = f"application-dev_reference_apis-arkgraphics2d_{name}"
        gp = f"application-dev/reference/apis-arkgraphics2d/{name}"
    add(src, "api", name, topic, gp)

add("application-dev_tools_aa-tool.md", "tools", "aa-tool.md",
    "aa 命令（aa start --pi/--ps/--pb/--psn/--wl..ww）", "application-dev/tools/aa-tool.md")
add("application-dev_dfx_hdc.md", "tools", "dfx-hdc.md",
    "hdc 命令（DFX 文档）", "application-dev/dfx/hdc.md")

for f in sorted(RAW.glob("perf_*.md")):
    add(f.name, "perf", f.name, f"性能优化专题（{f.name[5:-3]}）", None)
add("application-dev_application-test_smartperf-guidelines.md", "perf", "smartperf-guidelines.md",
    "SmartPerf 性能测试指南", None)

manifest, index_rows, copied, missing = [], [], 0, []
for src, sub, name, topic, gp in RULES:
    src_path = RAW / src
    dest_dir = DEST / sub
    dest_dir.mkdir(parents=True, exist_ok=True)
    if src_path.exists():
        shutil.copy2(src_path, dest_dir / name)
        copied += 1
        if gp:
            manifest.append(gp)
            url = f"{SRC_URL}/{gp}"
        else:
            url = "(由评估代理下载，源路径见 research/raw 文件名)"
        index_rows.append((sub, name, topic, url))
    else:
        missing.append(src)

lines = [
    "# 归档官方 API 文档（api-docs/）",
    "",
    "鸿蒙视效相关官方文档的离线归档，**编码时直接查阅，无需联网获取**。",
    "归档时间：2026-09-29/30，来源：OpenHarmony docs 仓库 master 分支（gitee.com/openharmony/docs）。",
    "",
    "## 版本与刷新",
    "",
    "- 这是 master 快照。版本对齐裁决：与本地 SDK 声明（ets/api/*.d.ts）冲突时**以 SDK 为准**。",
    "- 归档外的新接口/商业 Kit：按 ../search-sources.md 联网核实。",
    "- 刷新归档：运行 `scripts/refresh-api-docs.sh`（按 manifest.txt 重新拉取）。",
    "",
    "## 目录",
    "",
    "| 目录 | 内容 |",
    "|---|---|",
    "| guides/ | 开发指南（概念 + 完整示例代码） |",
    "| api/ | API 参考（签名、参数、@since/@deprecated 标注） |",
    "| tools/ | aa / hdc 等工具链命令 |",
    "| perf/ | 性能优化专题（渲染负载视角） |",
    "",
    "## 文件清单",
    "",
    "| 位置 | 文件 | 主题 | 源 |",
    "|---|---|---|---|",
]
for sub, name, topic, url in index_rows:
    lines.append(f"| {sub}/ | [{name}]({sub}/{name}) | {topic} | {url} |")
lines.append("")
if missing:
    lines.append("## 归档时缺失（未下载，可刷新补齐）")
    lines += [f"- {m}" for m in missing]

(DEST / "INDEX.md").write_text("\n".join(lines), encoding="utf-8")
(DEST / "manifest.txt").write_text("\n".join(manifest) + "\n", encoding="utf-8")
print(f"copied={copied} missing={len(missing)}")
for m in missing:
    print("MISS:", m)
