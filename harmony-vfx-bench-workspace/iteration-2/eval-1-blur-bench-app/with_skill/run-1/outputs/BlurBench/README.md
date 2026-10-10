# BlurBench — 鸿蒙高斯模糊原子视效 Benchmark App

全屏显示一张本地生成的基准图片，通过 `.blur(radius)` 施加实时内容高斯模糊。
模糊半径由外部启动参数注入，供脚本批量扫描 0–100 的渲染负载。

- **bundleName**：`com.example.vfxbench.blur` ｜ **入口**：`EntryAbility`
- **参数契约 / 注入命令**：见 `../docs/PARAM_CONTRACT.md`
- **验证说明与命令链**：见 `../docs/VERIFICATION.md`

## 快速开始

```bash
# 1. DevEco Studio 打开本目录，配置自动签名（一次性）
#    File -> Project Structure -> Signing Configs -> Automatically generate signature
# 2. 编译安装
ohpm install
hvigorw assembleHap --mode module -p product=default --no-daemon
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
# 3. 带参启动（半径 0–100，默认 20）
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 50
# 4. 观测
hdc shell hilog | grep VFXBENCH     # LAUNCH_PARAMS / FIRST_FRAME
hdc shell snapshot_display -f /data/local/tmp/shot.jpeg && hdc file recv /data/local/tmp/shot.jpeg .
```

## 设计要点（benchmark 契约）

1. **原子性**：只测 `.blur()` 内容模糊。无动画、无转场、无网络内容；
   顶部调试条（参数回显 + Slider）静态且跨参数恒定。
2. **参数外部驱动**：唯一正式入口是 `aa start --pi blur_radius <n>`
   （Want → AppStorage → `@StorageLink`）；`onNewWant` 支持热更新；
   越界 clamp、类型不符降级默认值并 warn。
3. **确定性**：基准图由 `scripts/generate_assets.py` 以固定种子（42）生成，
   1080×1920 PNG 随包分发；运行时零随机；全屏固定视口（`expandSafeArea`）。
4. **可观测最小集**：仅 `LAUNCH_PARAMS` / `FIRST_FRAME`（tag=`VFXBENCH`,
   domain=`0xE100`），无任何内置 FPS/耗时测量——测量归外部工具链。
5. **可验证**：验证命令链与通过标准见 `../docs/VERIFICATION.md`。

## 目录

```
BlurBench/
├── AppScope/                       # 应用级配置与资源（bundleName 等）
├── entry/                          # 唯一模块
│   └── src/main/
│       ├── ets/entryability/EntryAbility.ets   # Want 参数解析 + hilog 回显
│       ├── ets/pages/BenchPage.ets             # 全屏 Image + .blur(radius)
│       ├── resources/base/media/bench_image.png# 基准图（本地生成，勿替换为网络图）
│       └── module.json5
├── scripts/generate_assets.py      # 基准图/图标生成脚本（固定种子，可复现）
├── build-profile.json5             # 签名配置由 DevEco 自动写入
└── hvigor/ · hvigorfile.ts · oh-package.json5
```

目标工具链：DevEco Studio 5.x / HarmonyOS SDK API 12+（`compatibleSdkVersion: 5.0.0(12)`）。
