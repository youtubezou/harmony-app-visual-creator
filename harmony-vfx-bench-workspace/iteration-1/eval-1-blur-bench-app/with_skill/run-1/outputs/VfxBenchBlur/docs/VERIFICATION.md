# 验证说明 — VfxBenchBlur

## 本次交付的验证状态（如实声明）

| 验证项 | 状态 | 说明 |
|---|---|---|
| 工程结构完整性 | ✅ 已验证 | Stage 模型必备文件齐全（见下方清单核对） |
| 图片素材确定性生成 | ✅ 已执行 | `tools/generate_bench_image.py` 在本机运行成功，输出 `bench_image.png`（1080×1440，49553 bytes）并经视觉检查：渐变底 + 斜条纹 + 彩色圆点 + 棋盘块，高/中频细节充足 |
| 使用的 API 联网核实 | ✅ 已执行 | 见「API 核实记录」 |
| hvigorw 编译 | ⚠️ **未实际执行** | 交付机上未发现 DevEco Studio / hvigorw / ohpm / hdc（已探测 /Applications、ExtApps、~/Library、PATH）。请在装有 DevEco Studio 的机器上按下方命令链执行 |
| hdc 安装 / 带参启动 / 日志回显 / 截图取证 | ⚠️ **未实际执行** | 同上，命令链已文档化，需在真机环境执行 |

> 本机执行过的命令：`python3 tools/generate_bench_image.py`（成功）、文件树完整性检查（成功）。
> 其余步骤为**文档化验证命令链**，执行前请先完成签名配置。

## 前置：签名（一次性）

hdc 安装要求 hap 已签名：

1. DevEco Studio 打开本工程；
2. File → Project Structure → Signing Configs → 勾选 **Automatically generate signature**（需登录华为账号）；
3. 配置自动写回工程级 `build-profile.json5` 的 `signingConfigs`，之后命令行编译自动带签名。

## 完整验证命令链

```bash
cd VfxBenchBlur

# 0. 环境与设备
which hvigorw ohpm hdc && hdc list targets        # 设备在线才有输出

# 1. 编译（通过标准：exit 0，产物 hap 存在）
ohpm install                                       # 首次/依赖变更后
hvigorw assembleHap --mode module -p product=default --no-daemon
ls entry/build/default/outputs/default/*.hap

# 2. 安装（通过标准：successfully）
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 3. 带参启动（通过标准：无 error，hilog 出现 LAUNCH_PARAMS 且值正确）
hdc shell hilog -r                                 # 清缓冲便于对齐
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 20
hdc shell hilog | grep VFXBENCH
# 期望： LAUNCH_PARAMS {"blur_radius":20}  →  FIRST_FRAME blur_radius=20

# 4. 渲染取证（通过标准：截图非纯黑/纯白，可见模糊后的图片，左上角显示 blur_radius=20）
hdc shell snapshot_display -f /data/local/tmp/bench_20.jpeg
hdc file recv /data/local/tmp/bench_20.jpeg ./verify-20.jpeg

# 5. 换参复验（通过标准：日志参数变化 + 两张截图肉眼可辨差异——半径越大圆点/条纹越糊）
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 80
hdc shell hilog | grep VFXBENCH
# 期望： LAUNCH_PARAMS {"blur_radius":80}（走 onNewWant 热更新）
hdc shell snapshot_display -f /data/local/tmp/bench_80.jpeg
hdc file recv /data/local/tmp/bench_80.jpeg ./verify-80.jpeg

# 6. 基线点（radius=0 应完全不模糊）
hdc shell aa start -b com.example.vfxbench.blur -a EntryAbility --pi blur_radius 0
hdc shell snapshot_display -f /data/local/tmp/bench_0.jpeg
hdc file recv /data/local/tmp/bench_0.jpeg ./verify-0.jpeg

# 清理
hdc shell aa force-stop com.example.vfxbench.blur
hdc uninstall com.example.vfxbench.blur
```

没有 hvigorw 命令行时：DevEco Studio → Build → Build Hap(s)/APP(s) → Build Hap(s)，
产物同样在 `entry/build/default/outputs/default/` 下。

## 故障排查表

| 故障 | 排查 |
|---|---|
| `hvigorw` 找不到 | 用 DevEco Studio 编译（Build Hap(s)），或把 DevEco 自带的 hvigor 加入 PATH |
| 安装报 `signature verification failed` | 未完成签名配置，回到「前置：签名」 |
| `aa start` 报 ability not found | 核对 bundleName `com.example.vfxbench.blur` 与 ability `EntryAbility`（见 module.json5） |
| hilog 无 LAUNCH_PARAMS | 先 `hdc shell hilog -r` 清缓冲再启动；确认 grep 的是 `VFXBENCH` |
| 截图纯黑 | `hilog | grep VFXBENCH` 看是否有 `loadContent failed`；确认 `main_pages.json` 注册了 `pages/BenchPage` |
| 换参后画面不变 | 检查是否走了 onNewWant（日志应再次出现 LAUNCH_PARAMS）；@StorageLink 键名 `blur_radius` 一致性 |
| hdc 无设备 | `hdc kill -r` 重启服务；设备端确认「允许 USB 调试」 |

## API 核实记录（开发前联网核实，OpenHarmony docs master 快照）

| 事实 | 结论 | 来源 |
|---|---|---|
| `.blur(value: number)` 现状 | 未废弃，API 7+，通用组件属性，内容为实时模糊；半径越大越模糊，0 不模糊 | gitee.com/openharmony/docs `reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md` |
| 实时 vs 静态模糊 | blur/backdropBlur/*BlurStyle/motionBlur 均为**实时**接口、每帧渲染负载大；静态模糊走 effectKit（本 bench 故意不用，否则测不到每帧负载） | `ui/arkts-blur-effect.md` |
| `aa start` 参数形式 | `aa start -b <bundle> -a <ability> [--pi k <无符号int>] [--pb k bool] [--ps k str] [--psn k] [--wl/--wt/--wh/--ww 窗口几何]` 现行有效 | `tools/aa-tool.md` |
| Want 解析 + AppStorage/StorageLink 注入模式 | Stage 模型标准做法，onNewWant 处理热启动带新参 | skill references/benchmark-app.md 模板 |
| 废弃陷阱规避 | 本工程未使用任何动画 API，天然规避全局 animateTo / animator.create / pageTransition / TransitionOptions 等已废弃接口 | skill references/arkui-animation.md 陷阱表 |
