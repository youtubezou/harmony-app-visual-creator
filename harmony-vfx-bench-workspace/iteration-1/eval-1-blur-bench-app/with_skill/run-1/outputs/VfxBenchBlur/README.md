# VfxBenchBlur — 鸿蒙模糊效果原子 Benchmark App

全屏显示一张**本地生成**的图片（无任何网络内容），对其施加 ArkUI 实时内容模糊 `.blur(radius)`；
模糊半径经 Ability Want 启动参数从外部注入（`--pi blur_radius <int>`，0–100，默认 20），
app 启动后按参数渲染，供外部脚本批量扫描不同半径下的渲染负载（FPS/帧耗时/CPU/GPU/内存——
测量归外部工具，app 内**不含**任何测量逻辑）。

- 参数契约（给跑测脚本作者）：[docs/PARAM_CONTRACT.md](docs/PARAM_CONTRACT.md)
- 验证命令链与核实记录：[docs/VERIFICATION.md](docs/VERIFICATION.md)

## 快速开始

```bash
# 编译（签名配置见 docs/VERIFICATION.md「前置：签名」）
hvigorw assembleHap --mode module -p product=default --no-daemon
# 安装
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
# 带参启动（半径 40）
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 40
# 观测参数回显
hdc shell hilog | grep VFXBENCH
# 截图取证
hdc shell snapshot_display -f /data/local/tmp/blur_40.jpeg && hdc file recv /data/local/tmp/blur_40.jpeg .
```

## Benchmark 契约落实对照

| 契约 | 落实方式 |
|---|---|
| 1. 原子性 | 页面仅「全屏 Image + .blur()」+ 一处静态参数回显 Text；无动画/转场/网络内容/权限声明 |
| 2. 参数外部驱动 | 唯一正式接口 = Want 启动参数（`--pi blur_radius`），EntryAbility 解析+校验+钳制，经 AppStorage → 页面 @StorageLink 驱动渲染；onNewWant 支持热更新 |
| 3. 确定性 | 图片构建期确定性生成（`tools/generate_bench_image.py`，无随机数）；布局写死全屏；无时间驱动内容；同参数多次启动渲染逐帧一致 |
| 4. 可观测最小集 | 仅 `LAUNCH_PARAMS` / `FIRST_FRAME` / 参数异常 warn 三类日志（TAG=VFXBENCH, DOMAIN=0xE100）；零测量逻辑 |
| 5. 可验证 | 完整验证命令链见 docs/VERIFICATION.md（本交付机无 DevEco/hdc，真机步骤文档化待执行） |

## 工程结构

```
VfxBenchBlur/
├── AppScope/app.json5                      # bundleName=com.example.vfxbench.blur
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets   # Want 参数解析（类型校验+范围钳制+默认值）、LAUNCH_PARAMS 日志
│   │   ├── pages/BenchPage.ets             # @Entry 全屏场景，@StorageLink('blur_radius') 驱动
│   │   └── components/BlurBench.ets        # 被测视效：Image + .blur(radius)，FIRST_FRAME 日志
│   ├── resources/base/
│   │   ├── media/bench_image.png           # 被测图片（构建期生成，1080×1440）
│   │   ├── media/startIcon.png
│   │   ├── element/string.json, color.json
│   │   └── profile/main_pages.json         # pages/BenchPage
│   └── module.json5                        # 无权限声明，singleton
├── tools/generate_bench_image.py           # 确定性图片生成脚本（Pillow）
├── build-profile.json5 / hvigorfile.ts / hvigor/hvigor-config.json5 / oh-package.json5
└── docs/PARAM_CONTRACT.md, VERIFICATION.md
```

被测图片如需重新生成（例如换分辨率）：

```bash
python3 tools/generate_bench_image.py   # 依赖 Pillow；输出逐字节可复现
```
