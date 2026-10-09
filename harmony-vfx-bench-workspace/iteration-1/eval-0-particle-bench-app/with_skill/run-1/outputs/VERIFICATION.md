# 验证说明 — 粒子雨视效 Benchmark App

## 0. 本次交付的验证状态（如实声明）

| 验证项 | 状态 | 说明 |
|---|---|---|
| 工程结构 / 语法自检 | ✅ 已执行 | 结构与官方 Stage 模板逐字段核对；JSON/JSON5 通过解析检查 |
| 视效 API 联网核实 | ✅ 已执行 | 详见第 4 节「API 核实记录」 |
| `hvigorw assembleHap` 编译 | ⚠️ 未执行 | 本机无 DevEco/hvigorw/SDK（见第 1 节探测结果），需用户执行 |
| 真机安装 / 带参启动 / 日志回显 / 截图 | ⚠️ 未执行 | 本机无 hdc 与设备，已降级为文档化命令链（第 2 节） |

**结论：工程可交付，但「装得上、起得来、参数生效、渲染可见」四步需在用户真机环境按第 2 节命令链过一遍；没有截图证据前不得声称「渲染正常」。**

## 1. 开发环境探测结果（执行时实际情况）

```text
$ which hvigorw ohpm hdc        → 均无（未安装命令行工具链）
$ hdc list targets              → 无输出（无设备在线）
$ ls /Applications/DevEco-Studio.app → 不存在
$ ls ~/Library/OpenHarmony/Sdk ~/Library/Huawei/Sdk → 不存在
```

按 skill 的降级策略：产出完整工程，验证步骤文档化，由用户在真机环境执行。

## 2. 复现命令链（用户真机验证用）

前置：DevEco Studio（含 SDK）+ 已连接并授权调试的 HarmonyOS 真机。

```bash
# ---- 0. 签名（一次性，二选一）----
# 方式 A（推荐）：DevEco Studio 打开工程 → File → Project Structure → Signing Configs
#   → 勾选 "Automatically generate signature"（需登录华为账号）。
#   此后命令行编译自动产出带签名 hap。
# 方式 B：复用你既有签名工程，把本工程 entry/src/main 下的 ets/resources/module.json5 合入。

# ---- 1. 编译（通过标准：exit 0 且产物存在）----
cd ParticleRainBench
ohpm install
hvigorw assembleHap --mode module -p product=default --no-daemon
ls entry/build/default/outputs/default/entry-default-signed.hap
# 若无 hvigorw 命令行：用 DevEco Studio → Build → Build Hap(s)/APP(s) → Build Hap(s)

# ---- 2. 安装（通过标准：输出 successfully）----
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# ---- 3. 带参启动 + 日志回显（通过标准：hilog 出现 LAUNCH_PARAMS 且值与注入一致）----
hdc shell hilog -r            # 先清缓冲，避免捞到旧日志
hdc shell aa start -b com.example.vfxbench.particle -a EntryAbility \
  --pi particle_count 1000 --pi emitter_rate 200
sleep 3
hdc shell hilog | grep VFXBENCH
# 期望看到：
#   LAUNCH_PARAMS {"particle_count":1000,"emitter_rate":200}
#   FIRST_FRAME count=1000 rate=200

# ---- 4. 渲染取证（通过标准：截图非纯黑/纯白，可见雨丝）----
hdc shell snapshot_display -f /data/local/tmp/bench_1000.jpeg
hdc file recv /data/local/tmp/bench_1000.jpeg ./verify-1000.jpeg

# ---- 5. 换参复验（通过标准：日志参数变化 + 两张截图密度肉眼可辨）----
hdc shell aa force-stop com.example.vfxbench.particle
hdc shell aa start -b com.example.vfxbench.particle -a EntryAbility \
  --pi particle_count 200 --pi emitter_rate 50
sleep 3
hdc shell hilog | grep VFXBENCH
hdc shell snapshot_display -f /data/local/tmp/bench_200.jpeg
hdc file recv /data/local/tmp/bench_200.jpeg ./verify-200.jpeg

# ---- 6. 清理 ----
hdc shell aa force-stop com.example.vfxbench.particle
hdc uninstall com.example.vfxbench.particle
```

## 3. 故障排查表

| 故障 | 排查 |
|---|---|
| `hvigorw` 找不到 | 用 DevEco Studio 图形界面编译；或将其 `tools/hvigor` 加入 PATH |
| 编译报 SDK 版本不存在 | 把 `build-profile.json5` 的 `compileSdkVersion/compatibleSdkVersion`（当前 12）改为本机已装 API（12–20 均可，本工程 API 最低要求 12） |
| 安装报 signature 错误 | 未签名：按 2.0 节开自动签名后重新编译 |
| `aa start` 报 ability not found | 核对 `-b` 为 `com.example.vfxbench.particle`、`-a` 为 `EntryAbility` |
| hilog 无 LAUNCH_PARAMS | 先 `hdc shell hilog -r` 清缓冲再启动；确认 grep 时进程已拉起 |
| 截图纯黑 | 看 `hilog \| grep VFXBENCH` 是否有 `loadContent failed`；先在 DevEco Previewer 单参数调通 |
| 换参后画面不变 | 参数走 onNewWant 但页面没刷新——检查是否改动了 AppStorage 键名（必须与契约一致） |
| 截图雨丝比预期稀疏 | 非故障：屏幕外粒子计入负载但不可见，见 PARAM_CONTRACT.md 第 5 节 |

## 4. API 核实记录（Step 2 执行的动作）

按 skill「先搜索，后编码」原则，以下事实均经官方来源核实（核实时间见会话）：

| 事实 | 来源 | 结论 |
|---|---|---|
| `Particle` 组件存在且未废弃，构造为 `Particle({particles:[...]})` | OpenHarmony docs master：`reference/apis-arkui/arkui-ts/ts-particle-animation.md` + `ui/arkts-particle-animation.md` | ✅ 采用（API 11+） |
| `EmitterOptions`：particle(type/config/count/lifetime/lifetimeRange)、emitRate（默认 5，>5000 严重影响性能）、shape、position、size | 同上 | ✅ 按此实现 |
| `count` 语义 = 总发射预算，耗尽即停止（非并发上限、不回收） | graphic_graphic_2d 源码 `rosen/.../rs_render_particle_emitter.cpp`：`last > maxParticle → emitFinish_ = true`；`count=-1 → INT32_MAX`；`MAX_EMIT_RATE=5000` | ✅ 据此设计 count=-1 + 反解 lifetime 的稳态模型 |
| `velocity`：speed/angle 二元组，angle 0°=+X 轴、顺时针为正 → 下雨取 90° | ts-particle-animation.md VelocityOptions 节 | ✅ |
| `acceleration`：`{speed:{range:[...]},angle:{range:[...]}}` | 同上 AccelerationOptions 节 | ✅ |
| `aa start` 参数：`--pi`（**仅无符号整型**）/`--ps`/`--pb`/`--psn`；`--wl/--wt/--wh/--ww` 仅 2in1 开发者模式 + 调试签名有效 | OpenHarmony docs master：`application-dev/tools/aa-tool.md` | ✅ 契约仅用 --pi 正整数；文档注明窗口参数限制 |
| `emitter()` 属性方法（动态更新，API 12+） | ts-particle-animation.md emitter 节 | 未采用（重建即可，减少变量） |
| 工程模板（build-profile.json5 字段、hvigorfile、hvigor-config、app.json5、module.json5 skills 写法 `ohos.want.action.home`） | 官方样例仓 applications_app_samples master（ArkUISample/Animation）逐字段核对 | ✅ 按最新模板编写 |
| 动画类 API 陷阱（全局 animateTo 废弃 / animator.create 废弃 / pageTransition 不推荐） | skill references/arkui-animation.md | 本工程不使用这些 API（纯 Particle，无帧/属性动画代码） |
