# ArkUI 声明式动画与视觉效果

> **归档提示**：本文涉及的接口全文（签名/参数/官方示例）已离线归档在 `api-docs/`（索引 `api-docs/INDEX.md`），编码时直接查阅，无需联网。本文是地图与陷阱速查。

本文事实摘录自 OpenHarmony 官方文档（2026-09 master 快照）。**使用前仍需按 SKILL.md Step 2 联网核实最新状态**——本文的作用是给你正确的概念地图和已知的废弃陷阱，不是免检通行证。

## 目录

1. 三大属性动画接口（选型表）
2. animateTo（全局版已废弃，用 UIContext）
3. animation 属性
4. keyframeAnimateTo 关键帧
5. Animator 帧动画（模块级 create 已废弃）
6. Particle 粒子动画
7. transition 组件转场（用 TransitionEffect）
8. geometryTransition 共享元素转场
9. 页面转场（pageTransition 不推荐 → Navigation 体系）
10. 模态转场
11. 模糊家族
12. 图像效果通用属性（shadow 等）
13. 路径动画与曲线

## 1. 三大属性动画接口

| 接口 | 形态 | 适用场景 |
|---|---|---|
| `animateTo` | `this.getUIContext().animateTo(param, event)`，闭包内状态变化驱动 | 多个可动画属性共用一组参数；需要嵌套 |
| `animation` | 组件链式属性，作用于其**之上**的属性调用 | 同一组件多个属性各配不同参数 |
| `keyframeAnimateTo` | 多关键帧闭包分段 | 同一属性连续多段动画 |

## 2. animateTo

**陷阱：全局 `animateTo(value, event)` 已废弃（deprecated）。** 官方原文："直接使用 animateTo 可能导致 UI 上下文不明确的问题，建议使用 getUIContext() 获取 UIContext 实例"。

```ts
import { curves } from '@kit.ArkUI';

@Entry
@Component
struct Demo {
  @State scaleVal: number = 1;

  build() {
    Column() {
      Text('点我')
        .scale({ x: this.scaleVal, y: this.scaleVal })
        .onClick(() => {
          // 正确：UIContext 实例上的 animateTo
          this.getUIContext()?.animateTo({ duration: 600, curve: curves.springMotion() }, () => {
            this.scaleVal = this.scaleVal === 1 ? 1.5 : 1;  // 闭包内改变状态变量
          });
        })
    }
  }
}
```

- 参数 `AnimateParam`：duration（ms）、curve、delay、iterations（-1 无限）、playMode、onFinish。
- API 23+ 新增 `animateToImmediately(param, processor)`（显式立即动画）。
- 循环多段动画：优先用 `playMode`/`iterations` 或 keyframeAnimateTo，而不是递归嵌套 animateTo。

## 3. animation 属性

```ts
Text('hello')
  .fontSize(this.size)                 // ← animation 作用于它之上的属性
  .animation({ duration: 300, curve: Curve.EaseOut })
  .fontColor(this.color)               // ← 这行不受上面的 animation 影响（在其之下）
```

- 组件接口从下往上执行，`animation` 只作用于调用顺序在它之上的属性。
- 可按调用顺序给不同属性配不同 `animation`。

## 4. keyframeAnimateTo 关键帧

同一属性的连续多段动画（如"先放大→再旋转→再归位"）用它，比嵌套 animateTo 清晰。参考 `ts-keyframeAnimateTo.md`。

## 5. Animator 帧动画

**陷阱：`@ohos.animator` 模块级 `animator.create()` 从 API 18 起废弃。** 当前方式：

```ts
import { AnimatorOptions, AnimatorResult } from '@kit.ArkUI';

@Component
struct Demo {
  private animator: AnimatorResult | undefined = undefined;
  @State angle: number = 0;

  aboutToAppear(): void {
    const options: AnimatorOptions = {
      duration: 2000, easing: 'linear', delay: 0,
      fill: 'forwards', direction: 'normal',
      iterations: -1,        // 无限循环
      begin: 0, end: 360
    };
    this.animator = this.getUIContext().createAnimator(options);
    this.animator.onFrame = (value: number) => { this.angle = value; };
  }

  // 关键：必须释放，否则循环引用导致内存泄漏（官方明确警告）
  aboutToDisappear(): void {
    this.animator?.cancel();
    this.animator = undefined;
  }

  build() {
    Image($r('app.media.album')).rotate({ angle: this.angle })  // 专辑封面旋转
      .onClick(() => this.animator?.play())
  }
}
```

- 逐帧回调、可暂停（`pause()`）、实时响应；性能略逊于属性动画，**属性动画能满足就别用帧动画**。
- `cancel()`/`finish()` 会额外触发一次 onFrame（终点值）；想中途停在当前帧：先把 `onFrame` 置为空函数再 `finish()`。
- 无限循环的 Animator 即使在开发者选项关闭动画也会继续执行。
- 适用：进度驱动动画、拖拽跟手、需要中途暂停/反向的场景（如音乐封面旋转的播放/暂停）。

## 6. Particle 粒子动画

**注意组件名是 `Particle`**（不是旧资料里的 ParticleSystem/ParticleComponent）：

```ts
@Entry
@Component
struct ParticleDemo {
  build() {
    Stack() {
      Particle({
        particles: [
          {
            emitter: {
              particle: {
                type: ParticleType.POINT,        // 圆点粒子；图片粒子用对应类型
                config: { radius: 5 },           // 圆点半径
                count: 100,                      // 粒子总数
              },
            },
            color: {
              range: ['rgb(39,135,217)', 'rgb(0,74,175)'],  // 初始颜色范围
            },
            // 官方支持动画维度：颜色、透明度、大小、速度、加速度、自旋角度
          },
        ],
      }).width(250).height(250)
    }
  }
}
```

- 适合：雨/雪/烟花/礼花/点赞爆发/氛围光点。
- 点赞爆发类「点击触发」场景：用状态变量控制 Particle 的创建/参数，配合点击事件触发；大量短生命周期粒子注意 count 与生命周期设置（参考 `ts-particle-animation.md` 的 emitter/生命周期字段）。

## 7. transition 组件转场

**陷阱：`TransitionOptions` 已废弃。** 当前用 `TransitionEffect`（API 10+）：

```ts
// 出现/消失转场，可 .combine() 组合
.transition(
  TransitionEffect.OPACITY
    .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
    .animation({ duration: 300 })
)
```

- 组件插入/删除（if 条件渲染、ForEach 增删）时触发。
- 非对称转场：`TransitionEffect.asymmetric(appear, disappear)`。

## 8. geometryTransition 共享元素转场（一镜到底）

**有效，未废弃**（API 7+，10 起生效）。两个组件绑定同一 id，切换逻辑放 animateTo 闭包内：

```ts
// 旧位置组件
Image($r('app.media.cover')).geometryTransition(this.expanded ? '' : 'sharedCover')
// 新位置组件
Image($r('app.media.cover')).geometryTransition(this.expanded ? 'sharedCover' : '')

// 切换时：
this.getUIContext()?.animateTo({ duration: 300 }, () => {
  this.expanded = !this.expanded;
});
```

- 系统自动对绑定同 id 的组件做位置/宽高匹配过渡。
- 三种一镜到底方式的官方选型：不新建容器直接变化（简单场景）、NodeController 跨容器迁移（重对象如视频全屏）、geometryTransition（新建节点开销小的场景）。
- 注意：绑定节点需有稳定宽高，避免跳变。

## 9. 页面转场

**陷阱：`pageTransition()`（PageTransitionEnter/PageTransitionExit）官方已标注"不推荐"。** 当前标准是 Navigation 体系：

```ts
@Entry
@Component
struct Index {
  pageStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.pageStack) {
      // 首页内容，点击跳转：
      Button('去详情').onClick(() => this.pageStack.pushPath({ name: 'Detail' }))
    }
  }
}
```

- **系统默认转场**：`NavDestination.systemTransition(...)`（API 14+）选系统转场类型；默认是弹簧曲线，时长不可控，不要和业务逻辑耦合。
- **自定义转场**（API 15+）：实现 `NavDestinationTransitionDelegate` 返回 `NavDestinationTransition`（`event` 必填——转场动画逻辑；`onTransitionEnd`/`duration`/`curve`/`delay` 可选），挂到 `NavDestination.customTransition(...)`。多个协议对象逐层叠加。
- `Navigation.customNavContentTransition`（API 11+）与 customTransition 同用时优先级更高。
- 关闭动画：全局 `pageStack.disableAnimation(true)`；单次 `pushPath({name}, false)`（animated 参数）。
- 路由注册：pageMap / `pages` 配置见 references/project-build.md。

## 10. 模态转场

新界面覆盖旧界面、旧界面不消失：

| 接口 | 场景 |
|---|---|
| `bindContentCover` | 全屏模态（缩略图点看大图，可结合 geometryTransition） |
| `bindSheet` | 半模态（分享框、底部面板） |
| `bindMenu` / `bindContextMenu` | 菜单 / 长按菜单 |
| `bindPopup` | 气泡弹框 |

## 11. 模糊家族

| 接口 | 效果 |
|---|---|
| `.blur(radius)` | 组件内容模糊 |
| `.backdropBlur(radius)` | 组件背景（背后内容）模糊 |
| `.backgroundBlurStyle(BlurStyle.XXX)` | 背景模糊样式（系统材质） |
| `.foregroundBlurStyle(BlurStyle.XXX, options)` | 前景模糊样式（毛玻璃卡片首选） |
| `.motionBlur(...)` | 运动模糊 |

`BlurStyle` 枚举：`Thin` / `Regular` / `Thick` / `BACKGROUND_THIN` / `BACKGROUND_REGULAR` / `BACKGROUND_THICK` / `BACKGROUND_ULTRA_THICK` 等。

```ts
// 歌词面板毛玻璃
Column() { /* 歌词列表 */ }
  .foregroundBlurStyle(BlurStyle.Regular, { colorMode: ThemeColorMode.DARK })
```

## 12. 图像效果通用属性

`.blur()` `.shadow()` `.grayscale()` `.brightness()` `.saturate()` `.contrast()` `.invert()`（参考 `ts-universal-attributes-image-effect.md`，多数在 API 18 有增强版本）。

```ts
Image($r('app.media.cover'))
  .shadow({ radius: 20, color: 'rgba(0,0,0,0.3)', offsetY: 8 })
```

**注意：shadow 的文档在 image-effect 文件里**，不是独立的 shadow 参考文件。

## 13. 路径动画与曲线

- **路径动画**：参考 `ts-motion-path-animation.md`（沿路径运动）。
- **曲线**：`import { curves } from '@kit.ArkUI'`，如 `curves.springMotion()`；内置 `Curve.EaseIn/Out/Linear/Spring` 等。
- 动画流畅度最佳实践：见 `ui/arkts-animation-smoothing.md`。

## 常见坑速查

| 症状 | 原因 | 解法 |
|---|---|---|
| `animateTo` 报 UI 上下文不明确/行为异常 | 用了已废弃的全局函数 | `this.getUIContext().animateTo(...)` |
| `animator.create` 不存在/废弃告警 | 模块级 API 18 废弃 | `this.getUIContext().createAnimator(...)` |
| 页面转场不生效 | pageTransition 已不推荐 | 迁移 Navigation 体系 |
| 转场代码报 TransitionOptions 废弃 | 旧写法 | TransitionEffect |
| 退出页面后内存上涨 | Animator 未释放 | aboutToDisappear 里 cancel |
| 粒子组件找不到 | 按旧名 ParticleSystem 搜 | 当前组件名是 `Particle` |
