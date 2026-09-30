# 3D（SceneKit）与 Lottie

这两条技术路线有一个共同点：**它们不在 OpenHarmony 开源文档的覆盖范围内，版本和 API 形态变化快，本文件无法提供免检事实——使用前必须联网核实。** 本文件给你正确的入口、集成模式和避坑意识。

## 1. SceneKit（3D 场景）

- 定位：HarmonyOS 商业版的 3D 场景渲染能力（模型加载、相机、灯光、动画播放），适合商品 3D 展示、AR 预览、3D 形象等。
- **核实入口（必做）**：
  - 华为官方文档：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scenekit-*`（指南）、`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scenekit-*`（API）
  - 搜索关键词：`鸿蒙 SceneKit 3D 场景`、`HarmonyOS SceneKit SceneView`
- 核实要点：当前 Kit 名与导入路径（`@kit.SceneKit`？）、支持的模型格式（glTF？）、最低 API 版本、是否需要额外签名/权限、是否收费或有配额。
- 降级方案：如果 SceneKit 不满足（或目标版本不支持），考虑 XComponent + 自研/三方渲染（见 canvas-xcomponent.md），成本更高但可控。

## 2. Lottie

设计师用 After Effects 产出动画（Bodymovin 导出 JSON），开发直接播放——还原度高、免去手写复杂时序。

- 三方库：`@ohos/lottie`，发布在 ohpm 中心 `https://ohpm.openharmony.cn`。
- 安装（工程根目录，需要 ohpm 可用）：

```bash
ohpm install @ohos/lottie --save
# 或在 entry/oh-package.json5 的 dependencies 中声明后 ohpm install
```

- **核实入口（必做）**：ohpm 页面确认①最新版本号 ②当前主版本支持的渲染模式（Canvas 渲染还是组件渲染）③最低兼容 API 版本 ④导入方式。Lottie 鸿蒙库历史上经历过破坏性升级，直接抄老博客的 `lottie.loadAnimation` 参数很可能跑不起来。
- 典型用法模式（**示意骨架，具体参数以 ohpm 当前 README 为准**）：

```ts
import lottie from '@ohos/lottie';  // 核实：当前版本的导出名

@Component
struct LottieDemo {
  // 1. 把动画 JSON 放到 resources/rawfile/xxx.json
  // 2. 在合适的时机（如 Canvas/组件 ready）加载并播放
  // 3. 提供播放控制：play/pause/stop/进度跳转/速度

  aboutToDisappear(): void {
    // 关键：销毁动画实例，释放资源
  }
}
```

- 资源放置：JSON 放 `entry/src/main/resources/rawfile/`；含图片资源的动画需确认图片打包方式（随 JSON 内嵌 base64 或 images 目录）。
- 性能注意：大 JSON（几百 KB+）解析有耗时，考虑预加载；多个 Lottie 同屏注意内存。

## 3. 什么时候选它们

| 需求 | 选型 |
|---|---|
| 设计师交付的复杂品牌/IP 动画（loading、空状态插画动效、礼物特效） | Lottie（还原度最高，成本最低） |
| 3D 模型展示与交互 | SceneKit（先核实版本）→ 降级 XComponent+GL |
| 粒子/光效等程序化特效 | 不用这两个，用 Particle / Canvas（见 arkui-animation.md） |
| 简单图标动效 | 也不用，animation/animateTo 足够 |

## 4. 交付时的注意

- Lottie/SceneKit 都依赖运行时核实结果：交付说明里必须写清「本次核实的库版本 + ohpm/文档链接」，方便用户日后升级时对照。
- 如果用户的工程是离线/内网环境无法 ohpm，提示手动下载 har 包放入工程的替代方式。
