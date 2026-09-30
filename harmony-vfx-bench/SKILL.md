---
name: harmony-vfx-bench
description: Use when developing HarmonyOS (鸿蒙/HarmonyOS NEXT/OpenHarmony) benchmark apps for atomic visual effects (原子视效) — a single parameterized effect such as particles, blur, transitions, Canvas drawing, XComponent/OpenGL rendering, shaders, 3D, or Lottie — built so external tooling can drive parameter sweeps and measure load (FPS/frame time/CPU/GPU/memory). Also use whenever the user mentions 鸿蒙视效/动效 benchmark、负载测试 app、参数扫描、帧耗时测量、vfx bench、性能验证 demo, hdc 批量跑测, or wants a demo app whose rendering parameters are injected externally. This skill covers ONLY the benchmark app itself plus on-device usability verification; measurement orchestration, metrics collection, and modeling belong to the user's external toolchain. Consult it before writing ANY HarmonyOS benchmark/perf-demo app, because benchmark apps have a strict contract (external parameter injection, determinism) that ordinary demo code violates, and HarmonyOS APIs evolve rapidly (verify latest API via web search first).
---

# HarmonyOS 原子视效 Benchmark App 开发

## Overview

开发鸿蒙**原子视效 benchmark app**：单视效、demo 级、参数可外部注入的最小应用，
并用真机（hdc）验证其可用性。

**职责边界（重要）**：

- ✅ 本 skill 只做：benchmark **app 本体** + **可用性验证**（编译/安装/启动/参数生效/渲染可见）
- ❌ 本 skill 不做：跑测编排、参数扫描驱动、指标采集（FPS/CPU/GPU/内存）、数据建模——这些在你的外部工具链

为什么严格分离：app 是**被测对象**。测量逻辑放进 app 会污染被测负载；
参数硬编码会让外部脚本无法驱动。负载数据是否可信，首先取决于被测 app 本身是否干净、确定、可驱动。

**核心原则仍然成立：先搜索，后编码。** HarmonyOS API 迭代极快，每次开发前必须联网核实
（全局 `animateTo` 已废弃、模块级 `animator.create()` API 18 废弃、`pageTransition` 不推荐……
这些已核实的陷阱见 references/arkui-animation.md，新 API 仍需按 references/search-sources.md 核实）。

## Benchmark App 契约（五条）

每条都在 references/benchmark-app.md 有详细实现模板。**违反任何一条，产出的负载数据就不可信**：

1. **原子性**：一个 app 只测一种视效。场景固定，无无关动画、无装饰性转场、无网络内容。
2. **参数外部驱动**：所有关键参数经 Ability Want 启动参数注入
   （`hdc shell aa start -b <bundle> -a <ability> --pi <key> <int> --ps <key> <string>`），
   app 内解析、类型校验、给默认值；UI 调参只能是手动调试辅助，不能是唯一入口。
3. **确定性**：固定视口、固定随机种子、固定时间步长——同一参数组合多次启动，渲染行为逐帧一致。
4. **可观测最小集**：仅打生命周期与参数回显日志（hilog，统一 tag），供外部工具对齐采样窗口；
   **不内置任何测量/统计逻辑**（测量归外部工具）。
5. **可验证**：交付前真机过一遍——装得上、起得来、参数生效（日志回显核对）、渲染可见（截图）。

## Workflow

```dot
digraph bench_workflow {
  "澄清视效与参数契约" -> "环境探测(hdc/签名)";
  "环境探测(hdc/签名)" -> "联网核实 API";
  "联网核实 API" -> "实现 benchmark app";
  "实现 benchmark app" -> "真机可用性验证";
  "真机可用性验证" -> "交付(契约表+证据)";
}
```

### Step 0 — 澄清视效与参数契约

确认四件事（缺失时问用户，不要猜）：

1. **原子视效**：哪一种？（粒子/模糊/转场/Canvas 对象/着色器……一次一种）
2. **参数契约**：关键参数的键名、类型、范围、默认值、建议步长
   （如 `particle_count: int, 100–2000, 默认 500, 步长建议 ×2 几何级数`）。
   这份契约最终要交付给跑测脚本作者——键名一旦确定就不要改。
3. **固定场景**：视口尺寸、背景、静态元素——所有非被测变量。
4. **设备与签名**：目标设备型号？是否已在 DevEco Studio 配置过签名？

### Step 1 — 环境探测

```bash
which hvigorw ohpm hdc 2>/dev/null
hdc list targets 2>/dev/null          # 真机是否在线
ls /Applications/DevEco-Studio.app 2>/dev/null
```

- 无 hdc/设备 → 仍产出完整工程，但验证步骤降级为「文档化命令链 + 请用户在真机执行」，
  并在交付中明确标注哪些验证未实际执行。
- 有设备但编译产物未签名 → 提示用户在 DevEco Studio 开一次自动签名
  （File → Project Structure → Signing Configs），或复用其既有签名工程配置。

### Step 2 — 联网核实（不可跳过）

对两类事实核实（方法见 **references/search-sources.md**）：

1. **视效 API**：按视效类型读对应 reference（下方选型表）了解已核实的陷阱，
   再对本次要用的具体接口做联网核实（版本、废弃状态、当前写法）。
2. **工具链命令**：hdc / aa 命令的确切参数形式（如 `aa start` 的 `--pi/--ps/--pb/--psn`、
   `--wl/--wt/--wh/--ww` 固定窗口、截图命令）。已核实基础：
   `hdc shell aa start -b <bundle> -a <ability> [--pi k v] [--ps k v]`
   （官方文档 `application-dev/tools/aa-tool.md`）。

### Step 3 — 实现 benchmark app

按 **references/benchmark-app.md** 的模板实现契约五条；视效本身的实现参考选型表：

| 原子视效 | 技术 | 参考文件 |
|---|---|---|
| 粒子（数量/区域/速度扫描） | `Particle` 组件 | references/arkui-animation.md |
| 属性动画负载（N 个组件同时动画） | `animation` / `getUIContext().animateTo` | references/arkui-animation.md |
| 帧动画/自驱渲染 | `getUIContext().createAnimator` | references/arkui-animation.md |
| 模糊（半径/样式扫描） | `blur` / `foregroundBlurStyle` / `backdropBlur` / `motionBlur` | references/arkui-animation.md |
| 转场/共享元素 | `transition`+`TransitionEffect` / `geometryTransition` | references/arkui-animation.md |
| Canvas 自绘（对象数/路径复杂度扫描） | `CanvasRenderingContext2D` | references/canvas-xcomponent.md |
| 着色器/重渲染 | `XComponent` + OpenGL ES（成本高，先确认 Canvas 不够） | references/canvas-xcomponent.md |
| 3D / Lottie | SceneKit / `@ohos/lottie`（先联网核实版本） | references/3d-lottie.md |

工程结构与构建配置见 references/project-build.md。

### Step 4 — 真机可用性验证（交付前必做）

```bash
hvigorw assembleHap --mode module -p product=default --no-daemon   # 编译
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc shell aa start -b <bundle> -a EntryAbility --pi particle_count 500
hdc shell hilog | grep VFXBENCH        # 核对参数回显日志
hdc shell snapshot_display -f /data/local/tmp/bench.jpeg
hdc file recv /data/local/tmp/bench.jpeg ./verify-default.jpeg
# 换一组参数重复启动+截图，确认参数驱动生效
```

每步的通过标准与故障排查见 references/benchmark-app.md 的验证清单。
**没有截图证据不得声称「渲染正常」**——装得上不等于渲得出。

### Step 5 — 交付

1. 工程（可直接 DevEco Studio 打开）
2. **参数契约表**：键名 / 类型 / 范围 / 默认值 / 建议步长（给跑测脚本作者的接口文档）
3. **验证证据**：编译结果、安装输出、参数回显日志摘录、不同参数下的截图
4. **复现命令链**：从编译到带参启动的完整命令（用户的外部脚本直接参考）

## Common Mistakes

| 错误 | 后果 | 正确做法 |
|---|---|---|
| 参数硬编码在 build() / 常量里 | 外部脚本无法驱动，benchmark 报废 | Want 启动参数注入（契约 2） |
| 只做 UI 滑块调参 | 批量跑测无法无人值守 | UI 仅辅助，Want 为主入口 |
| 随机粒子/随机颜色无种子 | 同参数多次运行数据不可比 | 固定种子或确定性伪随机 |
| 动画用帧率相关步长（每帧 +1px） | 不同帧率下运动速度不同，污染负载-参数关系 | 固定 timestep（按时间戳推进） |
| app 内置 FPS/CPU 测量 | 测量逻辑污染被测负载 | 测量归外部工具（契约 4） |
| 场景混入装饰性动画/转场 | 测到的不只是目标视效 | 原子性（契约 1），无关元素全部静态 |
| 凭记忆写视效 API | 全局 animateTo / animator.create / pageTransition 等已废弃 | Step 2 联网核实 + arkui-animation.md 陷阱表 |
| 验证只到「安装成功」 | 白屏/崩溃/参数没生效都不知道 | 走完验证清单，截图+日志为证 |

## Quick Reference

```bash
# 环境与设备
which hvigorw ohpm hdc && hdc list targets

# 编译与安装
hvigorw assembleHap --mode module -p product=default --no-daemon
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 带参启动（int/string/bool/null 四类参数）
hdc shell aa start -b com.example.vfxbench -a EntryAbility \
  --pi particle_count 1000 --ps scene storm --pb fixed_seed true

# 观测与取证
hdc shell hilog | grep VFXBENCH
hdc shell snapshot_display -f /data/local/tmp/shot.jpeg
hdc file recv /data/local/tmp/shot.jpeg .

# 清理
hdc shell aa force-stop com.example.vfxbench
hdc uninstall com.example.vfxbench
```

## References 导读

| 文件 | 何时读 |
|---|---|
| references/benchmark-app.md | **每次必读**：契约五条实现模板、参数解析代码、hilog 规范、验证清单 |
| references/search-sources.md | Step 2 搜索前必读：官方文档 URL 模式、信息源、关键词 |
| references/arkui-animation.md | 视效涉及 ArkUI 动画/粒子/转场/模糊时 |
| references/canvas-xcomponent.md | 视效涉及 Canvas / XComponent / 着色器时 |
| references/3d-lottie.md | 视效涉及 3D / Lottie 时 |
| references/project-build.md | 新建工程、构建配置、签名、编译排错时 |
