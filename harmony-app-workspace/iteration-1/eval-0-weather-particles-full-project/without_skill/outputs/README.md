# 天气粒子（WeatherParticles）— HarmonyOS NEXT 演示工程

一个可直接用 **DevEco Studio 5.x** 打开运行的鸿蒙天气演示 App（HarmonyOS NEXT，ArkTS，Stage 模型，API 12）。

首页包含三类动画效果，全部使用 `Canvas` 2D 自绘实现，无任何第三方依赖：

| 效果 | 实现方式 |
| ---- | -------- |
| 🌧 雨滴下落 | 160 个倾斜线段粒子，随机长度/速度/透明度，落出屏幕后循环回顶部 |
| ❄️ 雪花飘落 | 130 个圆形粒子，带正弦水平摇摆，模拟随风飘动 |
| ☁️ 云朵缓慢移动 | 多个圆形拼成的卡通云朵，低速匀速漂移并循环回绕 |

底部按钮可在「下雨 / 下雪 / 多云」三种模式间切换，背景渐变与天气信息随之联动变化。

## 运行方式

1. 安装 DevEco Studio 5.0（API 12 SDK）或更高版本；
2. `File` → `Open`，选择本工程根目录（`outputs/`）；
3. 首次打开后等待工程同步（Sync）完成；如需真机运行，在 `File` → `Project Structure` → `Signing Configs` 中配置自动签名；
4. 选择模拟器或真机，点击 **Run** 即可。

## 工程结构

```
outputs/
├── AppScope/                        # 应用全局配置与图标资源
│   ├── app.json5                    #   bundleName / 版本 / 图标 / 名称
│   └── resources/base/
│       ├── element/string.json
│       └── media/                   #   layered_image（分层图标）
├── build-profile.json5              # 工程级构建配置（5.0.0(12), HarmonyOS）
├── hvigorfile.ts                    # 工程级构建脚本
├── oh-package.json5                 # 工程级包配置
├── hvigor/hvigor-config.json5
└── entry/                           # entry 模块（HAP）
    ├── build-profile.json5
    ├── hvigorfile.ts
    ├── oh-package.json5
    └── src/main/
        ├── module.json5             # 模块与 EntryAbility 声明
        ├── ets/
        │   ├── entryability/EntryAbility.ets   # 入口 Ability
        │   ├── pages/Index.ets                 # 首页（背景 + 信息 + 切换按钮）
        │   └── components/WeatherCanvas.ets    # ★ 粒子动画画布
        └── resources/base/
            ├── element/             # string / color / float
            ├── media/               # 图标 PNG + layered_image.json
            └── profile/main_pages.json
```

## 核心实现说明

- `WeatherCanvas.ets`：一张全屏 `Canvas`，用 `setInterval`（约 60fps）驱动逐帧渲染，
  按帧间隔 `dt` 做位移积分，保证不同帧率下速度一致；
- 粒子参数（数量、速度、透明度、摇摆幅度等）集中在 `initParticles()`，可直接调参；
- 组件 `aboutToDisappear` 中清理定时器，避免泄漏。
