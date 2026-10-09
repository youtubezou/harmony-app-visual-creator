# VfxBlurBench — 鸿蒙全屏高斯模糊 Benchmark 应用

一个用于负载测试的最小化 HarmonyOS 应用：

- **全屏显示一张本地生成的测试图**（App 内代码生成 PixelMap：高频棋盘格 + RGB 渐变，不依赖任何网络图片或内置大图）。
- **高斯模糊半径可外部注入**：启动参数 `blurRadius`，取值范围 **0–100**，默认 **20**。
- **App 启动后即按参数渲染**，无需任何手动操作，适合脚本批量驱动。

## 1. 工程信息

| 项 | 值 |
|---|---|
| Bundle name | `com.example.vfxblurbench` |
| 入口 Ability | `EntryAbility`（stage 模型） |
| compileSdk / compatibleSdk | `5.0.0(12)`（API 12，DevEco Studio 5.x） |
| 页面 | `pages/Index` |

## 2. 在 DevEco 中构建

1. 用 **DevEco Studio**（含 API 12 SDK）打开本工程根目录。
2. 首次打开等待 hvigor 同步完成。
3. 配置签名：**File → Project Structure → Signing Configs**，勾选 *Automatically generate signature*（真机运行必需）。
4. 连接真机（`hdc list targets` 可见），点击 **Run 'entry'**，或 Build → Build Hap(s)。

## 3. 注入模糊半径启动

通过 `aa start` 的 `--ps`（字符串）或 `--pi`（整型）传入 `blurRadius`：

```bash
BUNDLE=com.example.vfxblurbench

# 半径 0（无模糊）
hdc shell aa force-stop $BUNDLE
hdc shell aa start -b $BUNDLE -a EntryAbility --ps blurRadius 0

# 半径 40
hdc shell aa force-stop $BUNDLE
hdc shell aa start -b $BUNDLE -a EntryAbility --ps blurRadius 40

# 不传参数 -> 默认 20
hdc shell aa force-stop $BUNDLE
hdc shell aa start -b $BUNDLE -a EntryAbility
```

参数解析逻辑在 `entry/src/main/ets/entryability/EntryAbility.ets`：

- 非法值（非数字）回退为默认 **20**；
- 超出范围的值被钳制到 **[0, 100]**；
- 解析结果写入 `AppStorage('blurRadius')`，页面据此应用 `.blur(radius)`；
- 页面左上角有半透明浮层显示当前生效的半径，方便截图核验。

## 4. 批量测试

`tools/run_blur_bench.sh` 已给出参考实现（macOS / Linux）：

```bash
chmod +x tools/run_blur_bench.sh
./tools/run_blur_bench.sh
# 自定义半径列表 / 采样时长 / 输出文件：
RADII="0 20 40 60 80 100" SAMPLE_SECONDS=8 OUT=my.csv ./tools/run_blur_bench.sh
```

脚本流程：逐半径 `force-stop` → `aa start --ps blurRadius <r>` → 等待采样 →
`hidumper -s RenderService -a fps` 抓 FPS 快照 → 追加写入 CSV。

> 提示：不同设备 hidumper 输出格式不同，脚本保留原始文本（逗号转分号）到
> CSV 的 `fps_raw` 列，后处理时再解析；也可以换成你们团队已有的
> FPS/GPU 采集手段（如 DevEco Profiler、`hidumper -s 10`、SmartPerf 等），
> 只要保持「按半径分批启动 App」这一驱动方式即可。

## 5. 工程结构

```
.
├── AppScope/
│   ├── app.json5                       # bundleName / 版本 / 应用图标与名称
│   └── resources/base/
│       ├── element/string.json
│       └── media/app_icon.png          # 本地生成的图标
├── entry/
│   ├── build-profile.json5             # stageMode / targets
│   ├── hvigorfile.ts
│   ├── oh-package.json5
│   ├── obfuscation-rules.txt
│   └── src/main/
│       ├── module.json5                # EntryAbility 声明
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets    # 解析 want.parameters.blurRadius (0-100, 默认20)
│       │   └── pages/
│       │       └── Index.ets           # 本地生成测试图 + 全屏 Image + .blur(radius)
│       └── resources/base/
│           ├── element/string.json
│           ├── element/color.json
│           ├── media/icon.png
│           ├── media/startIcon.png
│           └── profile/main_pages.json
├── build-profile.json5                 # 根构建配置（API 12 / HarmonyOS）
├── hvigorfile.ts
├── oh-package.json5
├── .gitignore
├── tools/
│   └── run_blur_bench.sh               # 批量半径扫描脚本（hdc）
└── README.md
```

## 6. 实现要点

- **本地生成图片**：`Index.ets` 中按 RGBA_8888 逐像素填充 1080×1920 缓冲
  （8px 棋盘格提供高频边缘，红绿蓝通道分别为棋盘 / 水平渐变 / 垂直渐变），
  经 `image.createPixelMap` 生成 PixelMap —— 全程无网络、无打包大图。
- **模糊实现**：ArkUI `Image` 组件的 `.blur(radius)`（系统高斯模糊，单位 px），
  全屏 `ImageFit.Cover` 铺满，`.expandSafeArea` 沉浸式全屏。
- **参数注入**：`aa start --ps blurRadius 40`（字符串）或 `--pi blurRadius 40`
  （整型）均可，`EntryAbility.onCreate` 中兼容解析。
