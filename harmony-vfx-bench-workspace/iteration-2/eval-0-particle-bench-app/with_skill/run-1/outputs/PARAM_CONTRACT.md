# PARAM_CONTRACT — 下雨粒子 Benchmark App

- **Bundle**: `com.example.vfxbench.particle` / Ability: `EntryAbility` / Page: `pages/BenchPage`
- **原子视效**：ArkUI `Particle` 组件（POINT 点粒子）下雨效果，视口固定 360×640 vp，纯黑背景，无其他动画/转场/网络内容。
- **日志 tag**：`VFXBENCH`（domain `0xE100`）。仅两类日志：`LAUNCH_PARAMS {json}`（参数回显，冷/热启动各一次）、`FIRST_FRAME`（首帧，采样窗口起点）。
- **测量归外部工具**：app 内无任何 FPS/CPU/内存统计。

## 参数契约表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| `particle_count` | int | `--pi` | 100–2000 | 500 | 100,200,400,800,1200,1600,2000 | 同时存活粒子总数上限（emitter.particle.count） |
| `emitter_rate` | int | `--pi` | 10–1000 | 100 | 10,50,100,200,400,800,1000 | 发射器每秒发射粒子数（emitter.emitRate） |

- 类型不符 → 记 warn 并用默认值；越界 → clamp 到范围内并记 warn（脏参数不崩溃，保证采样点不缺失）。
- 固定项（不可注入，保证确定性）：视口 360×640 vp、粒子 radius=2vp、lifetime=1200ms（range=0）、速度 speed∈[550,600] vp/s、angle=90°（垂直向下）、无加速度、颜色固定 `#FF9EC5FF`。
- **确定性说明**：Particle 组件内部不暴露随机种子；确定性依赖「固定视口 + 固定速度/生命周期 + 窄随机区间」。运动为墙钟步长语义——负载升高表现为掉帧，适合以 FPS/掉帧为指标的跑测。

## 验证命令链（macOS/Linux；Windows 见 SKILL 文档，`grep`→`findstr`/`Select-String`）

```bash
# 1. 编译（首次需 ohpm install；产物 entry/build/default/outputs/default/entry-default-signed.hap）
ohpm install
hvigorw assembleHap --mode module -p product=default --no-daemon

# 2. 安装
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 3. 带参启动（默认组 / 轻载组）
hdc shell aa start -b com.example.vfxbench.particle -a EntryAbility --pi particle_count 500 --pi emitter_rate 100

# 4. 参数回显核对（通过标准：LAUNCH_PARAMS 值与注入一致，随后出现 FIRST_FRAME）
hdc shell hilog -r
hdc shell hilog | grep VFXBENCH

# 5. 渲染取证（通过标准：截图非纯黑，可见下落雨点）
hdc shell snapshot_display -f /data/local/tmp/bench_c500_r100.jpeg
hdc file recv /data/local/tmp/bench_c500_r100.jpeg .

# 6. 换参复验（重载组；通过标准：回显参数变化 + 两图雨密度肉眼可辨差异）
hdc shell aa start -b com.example.vfxbench.particle -a EntryAbility --pi particle_count 2000 --pi emitter_rate 1000
hdc shell hilog | grep VFXBENCH
hdc shell snapshot_display -f /data/local/tmp/bench_c2000_r1000.jpeg
hdc file recv /data/local/tmp/bench_c2000_r1000.jpeg .

# 清理
hdc shell aa force-stop com.example.vfxbench.particle
hdc uninstall com.example.vfxbench.particle
```

> 签名前置：未配置签名的环境需先在 DevEco Studio（File → Project Structure → Signing Configs → Automatically generate signature）开一次自动签名，再执行第 1 步。
