# 鸿蒙音乐播放器 —— 三种组合动效（ArkTS / ArkUI）

最小可运行页面上下文：一个 `@Entry` 页面 + 两个自定义组件 + 数据模型，
不依赖任何图片/媒体资源（封面用渐变圆代替，接入真实工程时替换为 `Image($r(...))` 即可）。

## 文件清单

| 文件 | 作用 |
|---|---|
| `ets/pages/MusicPlayerPage.ets` | `@Entry` 主页面：布局、播放/切歌交互、**动效三（切歌共享元素转场）** |
| `ets/components/RotatingCover.ets` | 黑胶唱片样式封面，**动效一（播放旋转 / 暂停停止）** |
| `ets/components/LyricsPanel.ets` | 底部歌词列表，**动效二（毛玻璃背景）** |
| `ets/model/Song.ets` | 歌曲数据模型与演示数据（3 首歌、含歌词） |

## 动效实现与触发时机

1. **封面旋转（播放转、暂停停）** —— `RotatingCover.ets`
   - `this.getUIContext().createAnimator({ duration: 20000, easing: 'linear', iterations: -1, begin: 0, end: 360 })` 创建帧动画，`onFrame` 回调逐帧驱动 `@State angle` → `.rotate()`。
   - `@Prop @Watch('onPlayingChanged') isPlaying`：播放 → `animator.play()`，暂停 → `animator.pause()`（停在当前角度）。
   - `aboutToDisappear` 中 `cancel()` 并置空（官方明确警告：不释放会循环引用内存泄漏）。

2. **底部歌词列表毛玻璃背景** —— `LyricsPanel.ets`
   - 面板容器 `.backgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR)` + `.borderRadius(24)`。
   - 要模糊的是「面板背后的内容」（背景光斑/渐变），故用 `backgroundBlurStyle`；
     `foregroundBlurStyle` 是模糊组件自身内容，不适用于本场景。
   - 附加：`@Watch` 监听当前行，`scroller.scrollToIndex(..., true, ScrollAlign.CENTER)` 平滑滚动，高亮行字号/颜色经 `.animation()` 过渡。

3. **切歌封面共享元素转场（一镜到底）** —— `MusicPlayerPage.ets`
   - 双槽位 `if/else` 渲染两个封面节点，绑定同一 `geometryTransition('sharedAlbumCover')` id，
     各自带 `TransitionEffect.OPACITY` 和 `.id('coverSlotFront/Back')`（官方防重影规则）。
   - 点击上一首/下一首：`this.getUIContext()?.animateTo({ duration: 450, curve: curves.springMotion() }, ...)` 闭包内把新歌曲放入另一槽位并翻转 `showFront`，系统自动完成旧封面（out）→ 新封面（in）的位置/大小匹配过渡。

## 如何运行

本机未安装 DevEco Studio / hvigorw，未做编译验证，请在本地：
1. 用 DevEco Studio 新建 Empty Ability（Stage 模型，API 12+）工程；
2. 将 `ets/` 下四个文件拷入 `entry/src/main/ets/` 对应目录；
3. 在 `main_pages.json` 注册 `pages/MusicPlayerPage`（或把 `MusicPlayerPage.ets` 改名为 `Index.ets` 直接替换首页）；
4. Previewer / 模拟器 / 真机运行。

## 调参指南

| 参数 | 位置 | 效果 |
|---|---|---|
| `ROTATION_DURATION` | RotatingCover.ets 顶部 | 封面转一圈时长（默认 20000ms），调小转更快 |
| `PANEL_HEIGHT` | LyricsPanel.ets 顶部 | 毛玻璃面板高度 |
| `BlurStyle.BACKGROUND_REGULAR` | LyricsPanel.ets `.backgroundBlurStyle(...)` | 毛玻璃浓淡：BACKGROUND_THIN / REGULAR / THICK / ULTRA_THICK |
| `COVER_SWITCH_DURATION` | MusicPlayerPage.ets 顶部 | 切歌转场时长（默认 450ms） |
| `curves.springMotion()` | MusicPlayerPage.ets `switchSong` | 转场曲线，可换 `Curve.EaseInOut` 等 |
| `LYRIC_LINE_INTERVAL` | MusicPlayerPage.ets 顶部 | 演示用歌词推进间隔 |

## API 版本声明与核实来源

本机无 HarmonyOS 工具链，未做编译验证；以下 API 均已在开发前通过联网
（curl 直读 OpenHarmony 官方文档仓库 gitee.com/openharmony/docs master 分支 Markdown）核实为当前有效接口：

| API | 状态 | 核实来源 |
|---|---|---|
| `UIContext.createAnimator` / `AnimatorResult`（play/pause/cancel/onFrame） | 有效；模块级 `animator.create()` 自 **API 18 起废弃**，已避开 | [js-apis-animator.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md) |
| `getUIContext().animateTo` | 有效；全局 `animateTo` 已废弃，已避开 | [ts-explicit-animation.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-explicit-animation.md) |
| `backgroundBlurStyle(value: BlurStyle, options?)` | 有效，API 9+ | [ts-universal-attributes-background.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-background.md) |
| `BlurStyle` 枚举（Thin/Regular/Thick/BACKGROUND_*） | 有效 | 同上文件 |
| `foregroundBlurStyle` | 有效，API 10+（本场景未采用，仅核实对比） | [ts-universal-attributes-foreground-blur-style.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-foreground-blur-style.md) |
| `geometryTransition(id)`（须配合 animateTo） | 有效，API 7 支持 / 10 起生效 | [ts-transition-animation-geometrytransition.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-geometrytransition.md) |
| 共享元素官方写法（if/else 双节点 + `.id()`） | 有效 | [arkts-shared-element-transition.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-shared-element-transition.md) |
| `TransitionEffect.OPACITY` | 有效，API 10+（`TransitionOptions` 已废弃，已避开） | [ts-transition-animation-component.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-transition-animation-component.md) |

最低建议目标版本：API 12（使用的全部接口均 ≤ API 10 起始，仅 `createAnimator` 建议 API 10+ 入口）。
