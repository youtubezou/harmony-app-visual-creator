# BlurBench 验证说明

## 验证状态总览

| 项目 | 状态 | 证据 |
|---|---|---|
| 工程结构完整性 | ✅ 已验证（离线） | 目录树与配置文件见 §1；逐文件静态检查通过 |
| 被测图片生成与内容 | ✅ 已验证（离线） | `scripts/generate_assets.py` 实际运行产出 1080×1920 PNG（4,375,077 B），图像内容人工检查（见 §4 图 1） |
| 参数契约实现（解析/回显/clamp） | ✅ 已验证（代码审查） | `EntryAbility.ets` 与 `BenchPage.ets` 键名、日志、边界行为一致 |
| 预期渲染效果（离线模拟） | ⚠️ 仅模拟示意 | §4 图 2–4，PIL 高斯模糊模拟，**非真机截图**，仅供肉眼预期参考 |
| 编译（`hvigorw assembleHap`） | ❌ 未执行 | **交付机器无 DevEco Studio / hvigorw / HarmonyOS SDK**，见 §5 |
| 真机安装 / 带参启动 / 日志回显 / 截图 | ❌ 未执行 | **交付机器无 hdc 与设备**，见 §5 |

**结论**：编译与真机可用性验证需在你的环境（DevEco + hdc 真机）执行。
请按 §2 的命令链逐步执行，通过标准见各步；全部通过后本 app 即达到交付标准。
§3 附故障排查表。

## 1. 已完成的离线验证

- 工程骨架按 Stage 模型标准结构（AppScope + entry 单模块），与
  `harmony-vfx-bench/references/project-build.md` 的 benchmark 骨架一致；
  `app.json5` / `module.json5` / `build-profile.json5` / `hvigor-config.json5` /
  `oh-package.json5` / `hvigorfile.ts` / `main_pages.json` 齐全。
- `main_pages.json` 注册 `pages/BenchPage` 与 `@Entry` 页面路径一致。
- `module.json5` 的 `abilities[0].srcEntry` 指向存在的
  `ets/entryability/EntryAbility.ets`；`exported: true`（`aa start` 前提）。
- 资源引用闭环：`$media:app_icon`（AppScope 与 entry 均存在）、
  `$media:bench_image`（4.3 MB PNG 存在）、`$string:*`、`$color:*`、
  `$profile:main_pages` 全部有对应文件。
- 代码审查核对：
  - `Want -> parseParams -> AppStorage -> @StorageLink` 链路键名一致（`blur_radius`）；
  - 默认值 20、范围 0–100、clamp + warn、类型降级与契约文档一致；
  - `onNewWant` 已实现（热启动参数生效）；
  - hilog 仅 `LAUNCH_PARAMS` / `FIRST_FRAME` / warn / error，统一
    `TAG='VFXBENCH'`、`DOMAIN=0xE100`，无内置测量逻辑；
  - 页面无动画、无网络、无随机；图片为本地资源（契约 1/3）。
- API 依据见 §6。

## 2. 待执行：真机验证命令链（含通过标准）

前置：用 DevEco Studio 打开 `BlurBench/` 一次，
**File → Project Structure → Signing Configs → Automatically generate signature**
（需登录华为账号），把自动签名写入 `build-profile.json5`；此后命令行编译自动带签名。

```bash
cd BlurBench

# 0) 环境
which hvigorw ohpm hdc && hdc list targets          # 有设备序列号输出

# 1) 编译 —— 通过标准：exit 0，产物存在
ohpm install
hvigorw assembleHap --mode module -p product=default --no-daemon
ls entry/build/default/outputs/default/entry-default-signed.hap

# 2) 安装 —— 通过标准：输出 successfully
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 3) 带参启动（默认参数验证） —— 通过标准：返回 start ability successfully，
#    且 hilog 出现 LAUNCH_PARAMS {"blur_radius":20} 与 FIRST_FRAME
hdc shell hilog -r                                  # 清缓冲，便于观察
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 20
hdc shell hilog | grep VFXBENCH

# 4) 渲染取证 —— 通过标准：截图非纯黑/纯白，可见模糊后的渐变图与顶部调试条
hdc shell snapshot_display -f /data/local/tmp/blur_020.jpeg
hdc file recv /data/local/tmp/blur_020.jpeg .

# 5) 换参复验 —— 通过标准：日志参数变化 + 三张截图肉眼可辨差异
#    （r=0 细节锐利；r=20 细节柔化；r=100 仅剩大色块渐变）
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 0
hdc shell snapshot_display -f /data/local/tmp/blur_000.jpeg && hdc file recv /data/local/tmp/blur_000.jpeg .
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 100
hdc shell snapshot_display -f /data/local/tmp/blur_100.jpeg && hdc file recv /data/local/tmp/blur_100.jpeg .

# 6) 边界行为（可选） —— 通过标准：hilog 出现 clamp warn，界面按 r=100 渲染
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 150
hdc shell hilog | grep VFXBENCH

# 7) 清理
hdc shell aa force-stop com.example.vfxbench.blur
hdc uninstall com.example.vfxbench.blur
```

若更喜欢 IDE：DevEco Studio 直接 Run ▶ 也能安装启动（默认参数 r=20），
随后用 §2 第 5 步的 `aa start` 换参复验即可。

## 3. 故障排查表

| 故障 | 排查 |
|---|---|
| `hvigorw` 找不到 | 用 DevEco Studio 编译（Build → Build Hap(s)），产物同在 `entry/build/...` |
| 安装报签名错误 | 未配置自动签名；见 §2 前置步骤 |
| `aa start` 报 ability 不存在 | 核对包名/ability 名：`com.example.vfxbench.blur` / `EntryAbility` |
| hilog 无 `LAUNCH_PARAMS` | 先 `hdc shell hilog -r` 再启动；确认抓日志时进程已拉起 |
| 截图纯黑 | `hdc shell hilog \| grep VFXBENCH` 看 `loadContent failed`；DevEco Previewer 先单参数调通 |
| 换参后画面不变 | 核对 `@StorageLink` 键名（本工程为 `blur_radius`）；确认新命令返回 successfully |
| 编译报 SDK 版本相关错误 | 本工程 `compatibleSdkVersion` 为 `5.0.0(12)`；若本地 SDK 不同，改为本地已装版本（DevEco 会在 Sync 提示中给出可选项） |

## 4. 预期效果（离线模拟，非真机截图）

以下由 Pillow `GaussianBlur` 对同一张 `bench_image.png` 模拟生成
（脚本见 `docs/expected/` 生成命令记录于 git 历史/交付说明），
**仅用于给你肉眼预期，数值口径以真机为准**：

| 半径 | 预期视觉 |
|---|---|
| r=0（图 2） | 原图：网格、圆点、同心圆环边缘锐利，噪点可见 |
| r=20（图 3） | 细节明显柔化，圆环仍可辨，色块轮廓发虚 |
| r=100（图 4） | 仅剩大面积渐变与角部色块轮廓，全部细节消失 |

- 图 1（基准原图）：`BlurBench/entry/src/main/resources/base/media/bench_image.png`
- 图 2：`docs/expected/sim_blur_000.png`
- 图 3：`docs/expected/sim_blur_020.png`
- 图 4：`docs/expected/sim_blur_100.png`

真机截图应额外包含顶部半透明调试条（显示 `blur_radius = N` 与 Slider）。

## 5. 本机环境探测记录（为什么真机验证未执行）

在交付机器上执行 `which hvigorw ohpm hdc`、`hdc list targets`、
`ls /Applications/DevEco-Studio.app`、`ls ~/Library/OpenHarmony/Sdk` 等探测，
**均无结果**（该机器无 DevEco Studio、无命令行工具链、无 HarmonyOS SDK、无在线设备）。
按 skill 工作流降级策略：产出完整工程 + 文档化验证命令链，未执行项已在 §0 表中明确标注。

## 6. API 核实依据（编码前已核对）

| 事实 | 来源 |
|---|---|
| `.blur(value: number)` 为内容模糊，半径 0 不模糊、越大越模糊；实时渲染、负载较大 | 归档 `harmony-vfx-bench/references/api-docs/guides/arkts-blur-effect.md` + `api/ts-universal-attributes-image-effect.md`（`blur` 条目） |
| `aa start --pi <key> <unsigned int>` 仅支持无符号整型；`--ps` 字符串不得以 `-` 开头；`--wl/--wh` 系列仅 2in1 生效 | 归档 `api-docs/tools/aa-tool.md` |
| Stage 工程结构 / app.json5 / module.json5 组成 | 归档 `api-docs/guides/application-package-structure-stage.md`、`application-configuration-file-overview-stage.md`、`start-with-ets-stage.md` |
| benchmark 契约实现模板（Want 解析、hilog 规范、验证清单） | `harmony-vfx-bench/references/benchmark-app.md`、`project-build.md` |

**是否使用归档 api-docs：是（主要依据）。** 联网核实层不可达
（搜索服务未配置、raw 文档站重定向受限），而本次用到的 `.blur()` 与
`aa start` 均为归档覆盖的成熟接口；`blur` 条目在归档中标注 API 7 起可用、
API 18/19 仅为参数可选性增强，基础用法无变化，故未强行联网。
`module.json5` 的 `srcEntry` 字段按 DevEco Studio 5.x（API 12+）模板编写，
若你的 IDE 版本更老/更新，打开工程时按 Sync 提示自动适配即可。
