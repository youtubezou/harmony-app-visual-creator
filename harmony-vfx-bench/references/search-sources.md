# 联网搜索信息源与检索策略

开发任何 HarmonyOS 动效/视效代码前，按本文件核实 API 现状。HarmonyOS API 迭代极快（调研时官方文档已标注到 API 24，且存在全局 `animateTo` 废弃、`pageTransition` 不推荐、`animator.create()` 废弃这类破坏性变化），**凭记忆写鸿蒙动画代码几乎必然踩坑**。

## 信息源（按采信优先级）

### 0. 本地 SDK 声明文件（有 SDK 时是最高优先级源）

HarmonyOS SDK 自带的 API 声明文件是与**实际编译版本精确匹配**的一手事实：
JSDoc/Hdoc 注释里的 `@since`、`@deprecated`、`@useinstead`、`@syscap` 标注就是编译器看到的世界。
离线、零延迟、版本绝对对齐——**装了 SDK 就先查它，联网源用于补充示例与更新版本前瞻**。

**探测 SDK 位置**（版本间布局有差异，动态探测，不要背路径）：

```bash
# 常见根目录（macOS）
ls ~/Library/OpenHarmony/Sdk 2>/dev/null
ls ~/Library/Huawei/Sdk 2>/dev/null
ls "/Applications/DevEco-Studio.app/Contents/sdk" 2>/dev/null
# 兜底：全盘找声明文件（macOS Spotlight 最快）
mdfind -name "animator" 2>/dev/null | grep -i "ets/api" | head -3
# 或
find ~ -maxdepth 8 -type d -name "api" -path "*ets*" 2>/dev/null | head -3
```

**典型结构**（探测到 SDK 根目录后确认）：

```
<SDK>/<api版本>/ets/api/                        ArkTS 声明（@ohos.animator.d.ts 等，含 Kit 导出）
<SDK>/<api版本>/native/sysroot/usr/include/    NDK 头文件（XComponent/EGL/GLES 等 .h）
```

**用法**：

```bash
# 找 API 声明位置
grep -rln "animateTo" <SDK根>/<版本>/ets/api/ | head -5
# 读 JSDoc：@deprecated 会写明替代接口，@since 是起始版本
grep -B5 -A10 "createAnimator" <找到的.d.ts> | head -40
# NDK 侧（XComponent 等）直接读头文件注释
grep -B3 -A15 "OH_NativeXComponent" <SDK根>/<版本>/native/sysroot/usr/include/**/*.h | head -40
```

**采信规则**：SDK 声明与网上文档冲突时，**以 SDK 为准**（它决定编译成败）；
SDK 里没有的新接口（更高版本），才去 gitee master / 华为文档核实后决定是否在工程中声明更高的 compileSdk。

### 1. OpenHarmony 官方文档仓库（首选联网源，机器可读）

纯 Markdown 文档，agent 可直接获取全文，是核实 API 的最佳来源。

```
仓库：https://gitee.com/openharmony/docs （master 分支）
raw URL 模式：https://gitee.com/openharmony/docs/raw/master/zh-cn/<路径>
```

**注意：必须 `curl -L` 跟随重定向**，否则拿到的是 302 跳转占位页（约 500 字节的 HTML），不是正文。

关键路径模式：

| 内容 | 路径模式 |
|---|---|
| 开发指南（含完整示例代码） | `application-dev/ui/arkts-<主题>.md` |
| ArkUI 组件/属性 API 参考 | `application-dev/reference/apis-arkui/arkui-ts/ts-*.md` |
| UIContext / 模块级 API | `application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md`、`js-apis-animator.md` |
| 图形/效果（effectKit、uiEffect、drawing） | `application-dev/reference/apis-arkgraphics2d/*.md` |
| 工程结构 | `application-dev/quick-start/application-package-structure-stage.md` |

不知道确切文件名时，用 Gitee API 列目录后过滤：

```bash
# 列出目录（注意：返回 JSON 中类型字段是 dir/file，不是 GitHub 的 tree/blob）
curl -sSL "https://gitee.com/api/v5/repos/openharmony/docs/contents/zh-cn/application-dev/ui" \
  | python3 -c "import json,sys; print('\n'.join(e['name'] for e in json.load(sys.stdin)))"
# 匿名调用有频率限制（约 60 次/小时），失败时等几秒重试
```

常用文档清单（调研快照，2026-09 核实存在于 master）：

```
ui/arkts-attribute-animation-overview.md      属性动画概述（三接口对比）
ui/arkts-attribute-animation-apis.md          animateTo/animation/keyframeAnimateTo 用法
ui/arkts-animator.md                          帧动画 Animator
ui/arkts-particle-animation.md                粒子动画 Particle 组件
ui/arkts-transition-overview.md               转场概述
ui/arkts-enter-exit-transition.md             组件出现/消失转场
ui/arkts-shared-element-transition.md         共享元素转场（一镜到底）geometryTransition
ui/arkts-navigation-animation.md              Navigation 转场动画（当前推荐）
ui/arkts-page-transition-animation.md         页面转场（官方标注"不推荐"）
ui/arkts-modal-transition.md                  模态转场 bindSheet/bindContentCover 等
ui/arkts-blur-effect.md                       模糊（blur/backdropBlur/*BlurStyle/motionBlur）
ui/arkts-shadow-effect.md                     阴影
ui/arkts-color-effect.md                      颜色效果
ui/arkts-graphics-display.md                  图形显示
ui/arkts-component-animation.md               组件动画
ui/arkts-custom-attribute-animation.md        自定义属性动画
ui/arkts-animation-smoothing.md               动画流畅度
ui/arkts-drawing-customization-on-canvas.md   Canvas 自绘
ui/arkts-geometric-shape-drawing.md           几何图形绘制（Shape/Path/Circle）
ui/napi-xcomponent-guidelines.md              XComponent 自定义渲染（native）
tools/aa-tool.md                              aa 命令（aa start --pi/--ps/--pb/--psn/--wl/--wt/--wh/--ww，已核实）
reference/apis-arkui/arkui-ts/ts-explicit-animation.md            animateTo 参数（全局版已废弃）
reference/apis-arkui/arkui-ts/ts-animatorproperty.md              animation 属性
reference/apis-arkui/arkui-ts/ts-keyframeAnimateTo.md             关键帧动画
reference/apis-arkui/arkts-apis-uicontext-uicontext.md            UIContext（animateTo/createAnimator 当前入口）
reference/apis-arkui/js-apis-animator.md                          Animator（模块级 create 已废弃）
reference/apis-arkui/arkui-ts/ts-particle-animation.md            粒子 API
reference/apis-arkui/arkui-ts/ts-transition-animation-component.md        transition（用 TransitionEffect）
reference/apis-arkui/arkui-ts/ts-transition-animation-geometrytransition.md  geometryTransition
reference/apis-arkui/arkui-ts/ts-page-transition-animation.md             pageTransition（不推荐）
reference/apis-arkui/arkui-ts/ts-basic-components-xcomponent.md           XComponent
reference/apis-arkui/arkui-ts/ts-components-canvas-canvas.md              Canvas 组件
reference/apis-arkui/arkui-ts/ts-canvasrenderingcontext2d.md              Canvas 上下文
reference/apis-arkui/arkui-ts/ts-motion-path-animation.md                 路径动画
reference/apis-arkgraphics2d/js-apis-effectKit.md                effectKit（离线图像处理）
reference/apis-arkgraphics2d/js-apis-uiEffect.md                 uiEffect（实时组件效果）
reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md    blur/shadow/grayscale 等图像效果属性
reference/apis-arkui/arkui-ts/ts-universal-attributes-foreground-blur-style.md  前景模糊样式
```

### 2. 华为官方文档（商业版 HarmonyOS）

覆盖 OpenHarmony 开源文档没有的商业能力（如 SceneKit 3D）：

```
指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/<guide-name>
API 参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/<api-name>
构建配置：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile-app
```

页面是 JS 渲染，web_fetch 可能取不到正文——优先用 gitee 仓库同名文件交叉核实；华为侧独有能力（3D、商业 Kit）才直接查它。

### 3. 官方示例代码

`https://gitcode.com/openharmony/applications_app_samples` —— 官方文档中的示例代码链接都指向这里（`code/DocsSample/ArkUISample/...`），可直接浏览/克隆，学最标准的写法。

### 4. ohpm 三方库中心

`https://ohpm.openharmony.cn` —— Lottie（`@ohos/lottie`）等三方库的版本与用法以这里为准。

### 4.5 hdc 工具

`https://gitee.com/openharmony/developtools_hdc`（README_zh.md，已核实 `hdc install` / `hdc file recv`）。
`hdc shell` 内的系统命令（aa、snapshot_display、hilog 等）文档在 OpenHarmony docs 仓库
`application-dev/tools/` 与 `application-dev/dfx/` 目录下，用 Gitee API 列目录找确切文件名。

### 5. 博客/论坛（仅作线索）

华为开发者论坛、掘金、CSDN。**鸿蒙领域过时博客是最大的坑**（大量基于已废弃的 FA 模型、`@ohos.*` 旧命名空间、pageTransition 的文章仍在传播）——任何博客代码必须经官方文档交叉验证后才可使用。

## 核实清单（每个关键 API 过一遍）

1. **接口当前形态**：是否废弃？（文档标题/正文有 `<sup>(deprecated)</sup>`、"不推荐"、"建议使用 XXX 替代" 标注）
2. **导入路径**：`@kit.ArkUI` 还是 `@kit.ArkGraphics2D`？还是全局接口/组件属性？
3. **起始版本**：与工程 `compileSdkVersion`/`compatibleSdkVersion` 对齐（文档标注"从 API version N 开始支持"）
4. **官方示例写法**：优先模仿官方示例的结构（状态变量怎么声明、闭包怎么写、生命周期怎么处理）

## 检索关键词速查

| 需求 | 关键词（中英文混用效果更好） |
|---|---|
| 属性动画 | `鸿蒙 属性动画`、`UIContext animateTo AnimateParam` |
| 帧动画 | `鸿蒙 帧动画`、`createAnimator AnimatorResult onFrame` |
| 粒子 | `鸿蒙 粒子动画`、`Particle ParticleType emitter` |
| 共享元素 | `鸿蒙 一镜到底`、`geometryTransition` |
| 页面转场 | `鸿蒙 Navigation 转场`、`NavDestination customTransition NavPathStack` |
| 模态 | `鸿蒙 半模态`、`bindSheet bindContentCover` |
| 模糊 | `鸿蒙 毛玻璃`、`foregroundBlurStyle backdropBlur` |
| 自绘 | `鸿蒙 Canvas`、`CanvasRenderingContext2D` |
| native 渲染 | `鸿蒙 XComponent`、`NativeXComponentParameters EGL OpenGL` |
| 图像处理 | `鸿蒙 图像效果`、`effectKit uiEffect createFilter` |
| 3D | `鸿蒙 SceneKit 3D`（查华为文档） |
| Lottie | `鸿蒙 lottie`、`@ohos/lottie ohpm` |

## 工具降级策略

环境中 `web_search` 未必可用。降级顺序：

1. `web_search`（有关键词覆盖优势）
2. `web_fetch` 直接抓文档 URL
3. `curl -L` 抓 gitee raw Markdown（本 skill 调研已证实全程可行，最稳定）

**交叉验证规则**：同一 API 至少在官方文档（gitee 或 developer.huawei.com）核实一次；博客内容必须二次验证。搜索不到当前版本资料时，明确告知用户「该 API 可能已废弃或改名」并给替代方案，不要硬写。
