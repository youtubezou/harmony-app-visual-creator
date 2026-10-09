# 参数契约文档 — 粒子雨视效 Benchmark App

- **应用**：VfxBenchRain（bundleName: `com.example.vfxbench.particle`，Ability: `EntryAbility`）
- **被测原子视效**：下雨粒子（ArkUI `Particle` 组件，`ParticleType.POINT`，单发射器，全屏）
- **接口读者**：跑测脚本作者。键名即接口，一经确定不要改。

## 1. 参数契约表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| `particle_count` | int | `--pi` | 100–2000 | 500 | 100, 200, 400, 800, 1200, 1600, 2000 | 稳态并发粒子数（负载主旋钮） |
| `emitter_rate` | int | `--pi` | 10–1000 | 100 | 10, 25, 50, 100, 200, 400, 800, 1000 | 每秒发射（新生/消亡）粒子数 |

- 未传任何参数（如点桌面图标启动）→ 全部取默认值（500 / 100）。
- 类型不符 → 降级为默认值并打 warn 日志；数值越界 → 钳制到上表范围并打 warn 日志。
  App 不会因脏参数崩溃（崩溃 = 该采样点数据缺失）。
- `aa start` 的 `--pi` 仅支持**无符号整型**（官方 aa-tool.md 已核实），本契约两个参数均为正整数，不受影响。

## 2. 负载模型（跑测脚本作者必读）

已对 OpenHarmony 源码 `rs_render_particle_emitter.cpp`（graphic_graphic_2d 仓库 master）核实发射器语义：

- `count` 是**总发射预算**：发射速率按时间累计，达到 count 后发射器永久停止。
  因此 app 内部固定 `count = -1`（预算无限）——**雨在整个采样窗口内持续，不会断流**。
- 稳态并发粒子数 `N ≈ emitter_rate × lifetime / 1000`。
  app 反解生命周期：`lifetime_ms = particle_count × 1000 / emitter_rate`（下限 200ms），
  使**稳态并发数精确等于 `particle_count`**。
- 两个旋钮正交：
  - 固定 `emitter_rate` 扫 `particle_count` → 测并发渲染负载随粒子数的变化；
  - 固定 `particle_count` 扫 `emitter_rate` → 并发数不变，测粒子新生/消亡（churn）开销。
- 引擎内部发射速率上限为 5000/s（源码 `MAX_EMIT_RATE`），契约上限 1000 远在其下，无截断。
- 固定场景（非被测变量）：纯色背景 `#0A1428`、竖屏锁定、全屏发射带（顶部 1vp 高 × 100% 宽）、
  下落速度区间 [500, 900] vp/s、角度恒 90°（竖直向下）、无加速度、半径 2vp、
  颜色/透明度/缩放区间固定。除两个注入参数外无任何可变项。

## 3. 启动命令（跑测脚本直接参考）

```bash
BUNDLE=com.example.vfxbench.particle
ABILITY=EntryAbility

# 默认（500 / 100）
hdc shell aa start -b $BUNDLE -a $ABILITY

# 带参启动示例
hdc shell aa start -b $BUNDLE -a $ABILITY --pi particle_count 1000 --pi emitter_rate 200

# 批量扫描示例（bash）
for c in 100 200 400 800 1200 1600 2000; do
  hdc shell aa force-stop $BUNDLE
  hdc shell aa start -b $BUNDLE -a $ABILITY --pi particle_count $c --pi emitter_rate 100
  sleep 12   # 预热 + 采样窗口（按你的工具链口径调整）
  # ... 外部指标采集 ...
done
```

- 连续注入时若 app 已存活，参数经 `onNewWant` 生效（页面自动重建粒子系统），
  日志会再打一行 `LAUNCH_PARAMS` 标记新采样窗口。两次采样间建议 `aa force-stop` 消除残留态。
- **建议固定同一台设备、同一分辨率**做对比；app 为全屏竖屏，视口随设备分辨率而定。
  （`aa start --wl/--wt/--wh/--ww` 窗口参数经核实仅对 2in1 设备开发者模式 + 调试签名生效，手机端不要用。）

## 4. 可观测性（app 对外打出的全部日志）

统一 `tag=VFXBENCH`，domain `0xE100`，可用 `hdc shell hilog | grep VFXBENCH` 对齐采样窗口：

| 时机 | 日志 | 含义 |
|---|---|---|
| 参数解析完成（onCreate / onNewWant） | `LAUNCH_PARAMS {"particle_count":500,"emitter_rate":100}` | 注入回显 + 采样窗口起点 |
| 粒子组件首次挂载 | `FIRST_FRAME count=500 rate=100` | 预热参考点（建议再预热 1–2s 进稳态） |
| 窗口销毁 | `WINDOW_STAGE_DESTROY` | 采样窗口终点参考 |
| 参数异常 | `param xxx ...`（warn） | 注入参数被降级/钳制 |

**app 内不内置任何 FPS/CPU/内存测量逻辑**（测量归外部工具链，避免污染被测负载）。

## 5. 确定性与已知限制

- app 自身代码**不含任何随机数和时间相关逻辑**；所有区间参数为编译期固定值。
- **已知限制**：ArkUI `Particle` 组件内部随机数不可播种（官方未提供 seed API），
  因此同一参数组合多次运行是**统计一致**（并发数、速率、分布相同），
  不保证逐帧一致。对比实验请在相同参数下多次采样取统计量。
- 粒子速度区间 [500, 900] vp/s、生命周期随参数变化 → 个别粒子会落到屏幕外才消亡。
  屏幕外粒子仍计入 `particle_count` 负载（引擎照常更新），但**可见雨丝密度**会略低于
  `particle_count`（默认参数下约为 1/4–1/3）。截图验证以「明显可见下雨且密度随参数变化」为准。
