# HarmonyOS 动效与视效开发技术调研

调研时间：2026-09-29。调研方式：直接获取 OpenHarmony 官方文档仓库（gitee.com/openharmony/docs，master 分支）60+ 份 Markdown 原文并提取事实。原始文档存于 `research/raw/`（文件名规则：仓库路径中 `/` 替换为 `_`）。

> 本文档是编写 harmony-app skill 的事实依据。其中 API 版本与接口状态均摘录自官方文档原文；HarmonyOS 迭代极快，skill 的运行时行为仍以「开发前联网核实」为准。

## 目录

1. 版本现状
2. 命名空间迁移（@ohos.* → @kit.*）
3. ArkUI 动画 API 现状（含废弃项）
4. 转场体系
5. 视觉效果（模糊/阴影/图像效果）
6. 绘制与渲染（Canvas / XComponent / 着色器）
7. 图像处理（effectKit / uiEffect）
8. 3D 与 Lottie
9. 工程结构与构建
10. 权威信息源与检索方法

## 1. 版本现状

- OpenHarmony docs 仓库分支列表显示发布分支已到 **OpenHarmony-6.1-Release**（master 跟踪最新开发版）。
- master 文档中的 API 版本标注：API version 18 出现最频繁（178 处），最高标注到 **API version 24**（少量新接口）。
- HarmonyOS 商业版（HarmonyOS NEXT / 5.x / 6.x）与 OpenHarmony API 版本的映射关系以华为官方文档为准，开发前需联网核实。

## 2. 命名空间迁移（@ohos.* → @kit.*）

官方文档示例已全面使用 `@kit.*` 导入（从应用层 ArkTS 代码角度）。动效/视效相关高频导入：

```ts
import { curves, AnimatorOptions, AnimatorResult, LengthMetrics, window, display, componentUtils, UIContext, FrameNode } from '@kit.ArkUI';
import { drawing, effectKit, common2D, uiEffect, text } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';
```

要点：动画/图形类集中在 `@kit.ArkUI` 与 `@kit.ArkGraphics2D`。旧的 `@ohos.animator`、`@ohos.effectKit`、`@ohos.graphics.uiEffect` 等写法对应迁移到 Kit 命名空间；部分模块级接口已废弃（见下）。

## 3. ArkUI 动画 API 现状

### 3.1 属性动画三接口（均有效）

| 接口 | 用法 | 适用场景 |
|---|---|---|
| `animateTo` | **全局函数已废弃**。必须用 `this.getUIContext().animateTo(param, event)`（闭包内状态变化驱动）。API 23+ 另有 `animateToImmediately(param, processor)` 显式立即动画 | 多个可动画属性共用一组动画参数；需要嵌套 |
| `animation` | 组件链式属性 `.animation(value)`，作用于其**之上**的属性调用 | 同一组件多个属性分别配不同动画参数 |
| `keyframeAnimateTo` | 多个关键帧闭包分段动画 | 同一属性连续多段动画 |

官方原文（arkts-attribute-animation-apis.md）："直接使用 animateTo 可能导致 UI 上下文不明确的问题，建议使用 getUIContext() 获取 UIContext 实例"。

### 3.2 Animator 帧动画（接口迁移，注意！）

- 旧的 `@ohos.animator` 模块级 `animator.create()` **从 API version 18 起废弃**。
- 当前方式：`this.getUIContext().createAnimator(options)`（API 10+），返回 `AnimatorResult`；`AnimatorOptions`/`AnimatorResult` 从 `@kit.ArkUI` 导入。
- 特性：onFrame 逐帧回调、可暂停、实时响应；性能略逊于属性动画，属性动画能满足时优先用属性动画。
- **内存陷阱**：自定义组件须持有 AnimatorResult 并在 `aboutToDisappear` 中释放，否则循环引用内存泄漏（官方原文明确警告）。
- `cancel()`/`finish()` 会触发一次额外 onFrame（值为终点）；中途暂停需先将 onFrame 置空函数再 finish。

### 3.3 粒子动画

- 组件名：**`Particle`**（文档原文："通过 Particle 组件来实现"），用法 `Particle({ particles: [...] })`。
- 粒子类型 `ParticleType.POINT`（圆点，config.radius）；另有图片粒子。
- 可动画维度：颜色、透明度、大小、速度、加速度、自旋角度；发射器 `emitter` 配置数量 count 等。
- 官方示例（雪花场景）：大量粒子在限定区域内随机运动组合成动画。

### 3.4 组件转场 transition

- **`TransitionOptions` 已废弃**（标记 deprecated）。
- 当前方式：**`TransitionEffect`**（API 10+）：`.transition(TransitionEffect.OPACITY.animation({...}))`，可组合 `.combine(...)`。

### 3.5 共享元素转场 geometryTransition（一镜到底）

- **有效**（API 7+，API 10 起生效），未废弃。
- 用法：转场前后两个组件 `.geometryTransition('同一id')` 绑定，转场逻辑放在 animateTo 闭包内，系统自动添加一镜到底过渡。
- 三种一镜到底实现方式官方对比：不新建容器直接变化（简单场景）、NodeController 跨容器迁移（重对象如视频全屏）、geometryTransition（新建节点开销小的场景）。

### 3.6 其他动画能力

- **Motion path 动画**：`ts-motion-path-animation.md`（沿路径运动）。
- 动画曲线：`curves`（@kit.ArkUI），如 `curves.springMotion()`；弹簧曲线见 arkts-spring-curve.md。
- 自定义属性动画：arkts-custom-attribute-animation.md。

## 4. 转场体系

### 4.1 页面转场：pageTransition 已不推荐

官方原文标题即「页面转场动画 (不推荐)」："为了实现更好的转场效果，推荐使用 **Navigation 转场动画** 和 **模态转场**"。

**Navigation 体系（当前标准）**：

- `Navigation` + `NavPathStack`（`pageStack.pushPath(...)` / `pop()` / `replacePath()`，均可传 `animated: false` 单次关闭动画）
- `NavDestination.systemTransition`（API 14+）设置系统默认转场类型
- `NavDestination.customTransition`（API 15+）：实现 `NavDestinationTransitionDelegate` 返回 `NavDestinationTransition`（event 必填，实现转场动画逻辑；onTransitionEnd/duration/curve/delay 可选）
- `Navigation.customNavContentTransition`（API 11+，与 customTransition 同用时优先级更高）
- `pageStack.disableAnimation(true)` 全局关闭
- 默认转场用弹簧曲线，时长不可控，不建议与业务耦合

### 4.2 模态转场

| 接口 | 场景 |
|---|---|
| `bindContentCover` | 全屏模态（如缩略图点看大图） |
| `bindSheet` | 半模态（分享框） |
| `bindMenu` / `bindContextMenu` | 菜单 |
| `bindPopup` | Popup 弹框 |

## 5. 视觉效果

### 5.1 模糊家族（均有效）

`blur`（内容模糊）、`backdropBlur`（背景模糊）、`backgroundBlurStyle`（背景模糊样式）、`foregroundBlurStyle`（前景模糊样式，枚举 BlurStyle.Thin/Regular/Thick/BACKGROUND_* 等）、`motionBlur`（运动模糊）。

### 5.2 图像效果通用属性（ts-universal-attributes-image-effect.md）

`blur`、`shadow`、`grayscale`、`brightness`、`saturate`、`contrast`、`invert`（多数从 API 18 起有增强版本标注）。**注意：shadow 通用属性文档在 image-effect 文件中**，不是独立文件。

### 5.3 其他效果属性

`clickEffect`、`hoverEffect`、`useEffect`（组件内容整体效果开关）、`filter-effect`、`foreground-effect`、`spatial-effect`、`use-union-effect`（sys）等，见 ts-universal-attributes-*.md。

## 6. 绘制与渲染

### 6.1 Canvas

```ts
private settings: RenderingContextSettings = new RenderingContextSettings(true); // 抗锯齿
private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
// build 中：
Canvas(this.context).width('100%').height('100%')
```

- 组件：`Canvas`；上下文：`CanvasRenderingContext2D` / `OffscreenCanvasRenderingContext2D`（离屏）。
- 绘制对象：基础形状、文本、图片；几何绘制组件另有 Shape/Path/Circle 等（arkts-geometric-shape-drawing.md）。

### 6.2 XComponent + Native 渲染

- 组件自 API 8 起支持；**API 19+ 新接口** `XComponent(params: NativeXComponentParameters)`（Native 侧获取节点实例、注册 Surface 生命周期回调与触摸/鼠标/按键事件回调）。
- 开发指南：`application-dev/ui/napi-xcomponent-guidelines.md`（自定义渲染 XComponent）。
- 链路：ArkTS 侧 XComponent 组件 → NAPI → C++ 侧 EGL/OpenGL ES 渲染循环。NDK 动画另见 `ndk-use-animation.md`。

## 7. 图像处理（区分两个模块！）

| 模块 | 定位 | 关键能力 | 导入 |
|---|---|---|---|
| **effectKit** | **离线**图像处理（pixelmap/png/jpeg），API 9+ | `createEffect(pixelmap): Filter`（亮度/模糊/灰度等）、ColorPicker 智能取色、Color | `import { effectKit } from '@kit.ArkGraphics2D'` |
| **uiEffect** | **实时**组件效果，接入渲染管线处理屏幕帧缓存，API 12+ | `createFilter(): Filter`（模糊、边缘像素扩展、提亮等，同类效果可级联）、VisualEffect | `import { uiEffect } from '@kit.ArkGraphics2D'` |

官方原文（effectKit）："effectKit 用于离线处理图像以获得视觉效果，而 uiEffect 则实时接入渲染服务，针对屏幕帧缓存进行处理以获得动态视觉效果。"

另：`uiMaterial`（@kit.ArkUI）出现在 image-effect 文档中（材质效果，较新能力，使用时需核实版本）。

## 8. 3D 与 Lottie

- **SceneKit（3D）**：HarmonyOS 商业版能力，不在 OpenHarmony 开源文档范围。使用时必须联网查华为官方文档（developer.huawei.com）核实当前 API 形态。
- **Lottie**：三方库，经 ohpm 安装（`ohpm install @ohos/lottie`），发布于 ohpm.openharmony.cn。版本与 API 形态需联网核实。

## 9. 工程结构与构建（Stage 模型）

开发态结构（官方 application-package-structure-stage.md）：

```
Project/
├── AppScope/
│   ├── app.json5              # 全局配置：bundleName、应用名、图标、版本
│   └── resources/             # 应用级资源
├── entry/ (ModuleName)/
│   ├── src/main/
│   │   ├── ets/               # ArkTS 源码（.ets）
│   │   │   ├── entryability/EntryAbility.ets
│   │   │   └── pages/Index.ets
│   │   ├── resources/         # 模块级资源
│   │   └── module.json5       # 模块配置：设备类型、abilities、权限、pages(main_pages.json)
│   ├── build-profile.json5    # 模块级构建配置
│   ├── hvigorfile.ts          # 模块构建脚本
│   ├── oh-package.json5       # 依赖（三方库/共享包）
│   └── obfuscation-rules.txt  # 混淆（Release）
├── build-profile.json5        # 工程级：products、签名 signingConfigs、compileSdk
├── hvigorfile.ts              # 工程级构建脚本
└── oh-package.json5           # 工程级依赖
```

编译：ets → .abc；产物 .hap / .hsp / .har（HAR 会被直接编译进 HAP/HSP）。构建配置详见 developer.huawei.com 的 ide-hvigor-build-profile-app / ide-hvigor-build-profile。

## 10. 权威信息源与检索方法

### 一手信息源（按采信优先级）

1. **OpenHarmony 官方文档仓库**（纯 Markdown，agent 可直接 curl，最友好）：
   - 仓库：`https://gitee.com/openharmony/docs`（master）
   - raw 模式：`https://gitee.com/openharmony/docs/raw/master/zh-cn/<路径>`（**必须 `curl -L` 跟随重定向**，否则拿到的是 HTML 跳转页）
   - 指南：`zh-cn/application-dev/ui/arkts-*.md`
   - API 参考：`zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-*.md`、`apis-arkgraphics2d/*.md`
   - Gitee API 列目录：`https://gitee.com/api/v5/repos/openharmony/docs/contents/<路径>`（注意返回 JSON 中目录类型字段是 `dir`/`file`，不是 GitHub 的 `tree`/`blob`；匿名调用有频率限制，失败时重试）
2. **华为官方文档**（商业版 HarmonyOS，含 SceneKit 等闭源能力）：
   - `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/<guide-name>`（指南）
   - `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/<api-name>`（API 参考）
   - 页面为 JS 渲染，web_fetch 可能拿不到正文；可用其搜索页或改用 gitee 仓库对应文件
3. **官方示例代码仓库**：`https://gitcode.com/openharmony/applications_app_samples`（文档中的示例代码链接 `@[xxx](https://gitcode.com/openharmony/applications_app_samples/blob/master/code/DocsSample/...)` 均指向此）
4. **ohpm 三方库中心**：`https://ohpm.openharmony.cn`（Lottie 等）
5. 博客/论坛（华为开发者论坛、掘金、CSDN）：仅作线索，必须与官方文档交叉验证

### 检索关键词对照

| 需求 | 中文关键词 | 英文/标识符关键词 |
|---|---|---|
| 属性动画 | 鸿蒙 属性动画 animateTo | UIContext animateTo AnimateParam |
| 帧动画 | 鸿蒙 帧动画 Animator | createAnimator AnimatorResult |
| 粒子 | 鸿蒙 粒子动画 | Particle ParticleType emitter |
| 共享元素 | 鸿蒙 一镜到底 共享元素转场 | geometryTransition |
| 页面转场 | 鸿蒙 Navigation 转场动画 | NavDestination customTransition NavPathStack |
| 模态 | 鸿蒙 半模态 全屏模态 | bindSheet bindContentCover |
| 模糊 | 鸿蒙 毛玻璃 模糊 | foregroundBlurStyle backdropBlur motionBlur |
| 自绘 | 鸿蒙 Canvas 绘制 | CanvasRenderingContext2D OffscreenCanvas |
| native 渲染 | 鸿蒙 XComponent OpenGL | NativeXComponentParameters EGL |
| 图像处理 | 鸿蒙 图像效果 | effectKit uiEffect Filter |
| 3D | 鸿蒙 3D 场景 SceneKit | SceneView（需查华为文档） |
| Lottie | 鸿蒙 Lottie | @ohos/lottie ohpm |

### 工具降级策略

agent 环境可能无 web_search 配额。优先级：`web_search` → `web_fetch`（直接抓文档 URL）→ `curl -L`（gitee raw，最稳定）。本调研全程用 curl 直连 gitee 完成，证实可行。
