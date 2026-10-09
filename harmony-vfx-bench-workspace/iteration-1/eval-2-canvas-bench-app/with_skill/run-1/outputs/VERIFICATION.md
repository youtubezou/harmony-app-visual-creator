# CanvasBench 验证说明

## 0. 环境探测结果（决定验证策略）

| 探测项 | 结果 |
|---|---|
| `hvigorw` / `ohpm` / `hdc`（PATH 与常见安装位置） | ❌ 均未找到 |
| DevEco Studio（`/Applications/DevEco-Studio.app`） | ❌ 未安装 |
| HarmonyOS SDK（`~/Library/OpenHarmony/Sdk`、`~/Library/Huawei/Sdk`） | ❌ 未安装 |
| hdc 真机 | ❌ 无（无 hdc 工具，无从谈设备） |
| Node.js | ✅ v26.5.0（仅用于离线逻辑验证） |

**结论（按 skill 降级策略）**：本机无工具链与真机，**真机验证未实际执行**。
交付内容为：完整可打开的 DevEco 工程 + 已联网核实的 API 用法 + 离线确定性逻辑验证证据 +
文档化命令链（PARAM_CONTRACT.md §5），请用户在有 DevEco Studio + 签名 + 真机的环境按命令链执行。

## 1. 已执行的验证

### 1.1 API 联网核实（Step 2，全部来自 OpenHarmony 官方文档仓库 master）

| 核实项 | 结论 | 来源 |
|---|---|---|
| `Canvas(context: CanvasRenderingContext2D)` 组件接口 | ✅ 当前有效（API 8+；API 23 另有 `Canvas(CanvasParams)` 新接口，旧接口未废弃） | [ts-components-canvas-canvas.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-components-canvas-canvas.md) |
| `Canvas.onReady(VoidCallback)` | ✅ 当前有效（API 9+） | 同上 |
| `CanvasRenderingContext2D`：`clearRect`/`beginPath`/`moveTo`/`arc`/`fill`/`fillStyle` | ✅ 当前有效，无废弃标注 | [ts-canvasrenderingcontext2d.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-canvasrenderingcontext2d.md) |
| 帧驱动：`getUIContext().createAnimator(options)` | ✅ 当前入口；模块级 `animator.create()` 自 API 18 废弃（已避开） | [js-apis-animator.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/js-apis-animator.md)、[arkts-apis-uicontext-uicontext.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uicontext-uicontext.md) |
| `AnimatorResult.onFrame` / 无限循环 `iterations: -1` / 销毁时须 `cancel()` | ✅ 按官方要求实现（aboutToDisappear 释放） | 同上 |
| `aa start --pi/--pb/--ps/--psn` | ✅ 已核实；**`--pi` 仅接受无符号整型**（契约表已按此设计） | [aa-tool.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/tools/aa-tool.md) |
| `aa start --wl/--wt/--wh/--ww` | ✅ 已核实；仅 2in1 开发者模式 + 调试签名生效（手机端不适用，故视口在 app 内固定） | 同上 |

### 1.2 确定性核心逻辑离线验证（Node.js，证据见 `verification/determinism-check-output.txt`）

`verification/determinism-check.mjs` 是 `BrownianSim.ets` 的逐行等值移植
（ArkTS 与 JS 同为 IEEE 754 双精度，`Math.imul`/`Math.round` 位级一致），实测：

- ✅ 同参数两次"启动"（dots=500/r=4、dots=100/r=4、dots=5000/r=2，seed=20240521），
  推进 900 帧，`CHECKSUM` 逐条**完全一致**；
- ✅ 反向对照：seed/count/radius 任一变化 → hash 不同（排除校验恒真）；
- ✅ 参考基线：默认参数 `frame=300 hash=9e479d3e`、`frame=900 hash=7b8514e4`
  （真机同参数运行应复现此值——等值移植的坐标运算与 ArkTS 位级一致）。

> 该验证覆盖契约 3 的算法层（随机流、步进、反弹、哈希）；不覆盖设备渲染管线
> （Canvas 光栅化属于确定性绘制，同一几何输入输出一致，但仍需真机截图确认）。

### 1.3 工程静态自查

- ✅ 契约五条逐条落实（见 README.md 对照表）；
- ✅ 全部资源本地化（图标为构建期生成的本地 PNG），无任何网络依赖；
- ✅ `module.json5` 零权限声明；bundleName 独立；
- ✅ 页面注册 `pages/BenchPage`；ability 名 / bundleName 与文档命令链一致。

## 2. 未执行的验证（降级标注，需在真机环境补做）

| 步骤 | 通过标准 | 状态 |
|---|---|---|
| `hvigorw assembleHap` 编译 | exit 0，产出 `entry-default-signed.hap` | ⚠️ 未执行（无工具链）；需先在 DevEco 配置自动签名 |
| `hdc install -r` 安装 | 输出 successfully | ⚠️ 未执行（无 hdc/设备） |
| 带参启动 + 日志回显 | hilog 出现 `LAUNCH_PARAMS`/`FIRST_FRAME`，值与注入一致 | ⚠️ 未执行 |
| 截图取证 | 截图非纯黑/纯白，可见橙色圆点散布 | ⚠️ 未执行 |
| 换参复验 | 新参数日志 + 两张截图肉眼可辨密度/尺寸差异 | ⚠️ 未执行 |
| 复现性验证 | 同参数两次启动 `CHECKSUM` 行 diff 无差异 | ⚠️ 真机部分未执行（算法层已离线验证通过） |

补做命令链与每步标准：见 [PARAM_CONTRACT.md §5](PARAM_CONTRACT.md)。
故障排查（签名错误 / ability not found / hilog 无输出 / 截图纯黑）：
见 skill 库 `references/benchmark-app.md` 验证清单故障表。

## 3. 真机验证注意事项

1. **签名**：工程 `build-profile.json5` 的 `signingConfigs` 留空，必须先在
   DevEco Studio → File → Project Structure → Signing Configs 勾选自动签名后再编译。
2. **SDK 版本**：工程按 `compileSdkVersion 5.0.0(12)` 配置；若本机 SDK 不同，
   在 DevEco 中同步调整（所用 API 均为 API 9–11 起支持的老接口，向下兼容空间充足）。
3. **首次打开**：DevEco 打开工程会自动补齐 `hvigorw`/本地配置（本交付未包含 IDE 生成物）。
