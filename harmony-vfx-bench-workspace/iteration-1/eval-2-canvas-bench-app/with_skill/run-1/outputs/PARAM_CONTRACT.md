# CanvasBench 参数契约（给跑测脚本作者的接口文档）

- **App**：CanvasBench —— 鸿蒙 Canvas 自绘负载测试：固定视口内 N 个圆点持续做布朗运动
- **bundleName**：`com.example.vfxbench.canvas`
- **Ability**：`EntryAbility`
- **日志**：hilog，`TAG=VFXBENCH`，`DOMAIN=0xE100`
- **键名即接口**：以下键名一旦注入即被识别，改键名 = 破坏性变更；未识别键名一律忽略。

## 1. 参数契约表

| 键名 | 类型 | 注入方式 | 范围 | 默认值 | 建议步长 | 说明 |
|---|---|---|---|---|---|---|
| `dot_count` | int（无符号） | `--pi` | 100–5000 | 500 | 100, 250, 500, 1000, 2000, 3000, 5000 | 圆点总数（主扫描变量：每帧 arc 路径数） |
| `dot_radius` | int（无符号） | `--pi` | 1–32 | 4 | 2, 4, 8, 16, 32 | 圆点半径，单位 vp（次扫描变量：单 arc 填充面积） |
| `seed` | int（无符号） | `--pi` | 0–2147483647 | 20240521 | 固定默认 | 布朗运动随机种子。**复现对比时严禁改动** |
| `checksum_log` | bool | `--pb` | true/false | true | 固定 true | 周期性轨迹 CHECKSUM 日志开关（复现性探针，见 §4） |

解析规则（`EntryAbility.ets` 实现）：

- 类型不符（如给 `dot_count` 传 string）→ warn 日志 + 回退默认值，**不崩溃**；
- int 参数超范围 → warn 日志 + 钳制到边界值；
- 未传参 → 全部走默认值（等价于一次标准基线运行）。

## 2. 固定场景常量（非被测变量，改动即破坏跨版本数据可比性）

| 常量 | 值 | 说明 |
|---|---|---|
| 仿真域（视口） | 360 × 720 vp | Canvas 组件固定尺寸，居中于纯色页面；轨迹坐标与设备分辨率解耦 |
| 时间步长 `DT` | 1/60 虚拟秒/帧 | 每渲染一帧仿真恰好推进一个虚拟步；第 k 帧状态只依赖参数与 k |
| 初始速度幅值 `V0` | 60 vp/虚拟秒 | 各向均匀 |
| 随机加速度 `ACCEL` | 400 vp/虚拟秒² | 每帧对速度施加均匀随机冲量（布朗运动） |
| 速度钳制 `VMAX` | 120 vp/虚拟秒 | 双向钳制 |
| 边界 | 镜面反弹 | 圆心限制在 [r, W−r] × [r, H−r] |
| 渲染 | `#FF8C1A` 圆点 / `#101418` 背景 | 每帧：clearRect + N×arc + 单次 fill（一条路径） |
| PRNG | LCG（种子 ⊕ 0x9E3779B9，`Math.imul` 精确 32 位） | 每圆点初始化消费 4 个随机数（x,y,vx,vy），每帧消费 2 个 |

## 3. 确定性保证（契约 3）

同一组 `(dot_count, dot_radius, seed)` 多次启动，**轨迹逐帧位级一致**：

1. 全部随机数来自固定种子 LCG，无 `Math.random()`、无墙钟时间；
2. 运动推进用固定虚拟时间步长，与真实帧率解耦——设备快/慢只影响墙钟速度，不影响轨迹数据；
3. 仿真全程只用 IEEE 754 加减乘/比较 + `Math.imul`/`Math.round`，不用任何实现相关超越函数，跨引擎位级可复现；
4. 视口、背景、颜色全部固定，无网络内容、无装饰动画。

复现性验证：两次带相同参数启动后，比较 hilog 中相同 `frame=` 的 `CHECKSUM` 行 `hash` 值，必须完全一致（见 §4 与 VERIFICATION.md）。

## 4. 日志规范（可观测最小集）

| 时机 | 格式 | 用途 |
|---|---|---|
| 参数解析完成（onCreate / onNewWant） | `LAUNCH_PARAMS {"dot_count":500,"dot_radius":4,"seed":20240521,"checksum_log":true}` | 确认注入生效；标记采样窗口起点 |
| 当前参数集首帧渲染完成 | `FIRST_FRAME dots=500 radius=4 seed=20240521` | 对齐预热结束/采样开始 |
| 每 300 虚拟帧（`checksum_log=true` 时） | `CHECKSUM frame=300 hash=9e479d3e dots=500 radius=4 seed=20240521` | 复现性探针：同参数多次启动，同 frame 的 hash 必须一致 |
| 参数类型/范围异常 | `param <key> ...`（warn） | 脏参数诊断 |

> CHECKSUM 是对全部圆点量化（1/1024 vp）坐标的 FNV-1a 32 位哈希，属复现性验证数据，
> 不属于性能测量；app 内**无任何** FPS/帧耗时/CPU 统计逻辑（测量归外部工具）。
> 参考基线（离线逻辑验证实测，见 verification/determinism-check-output.txt）：
> 默认参数 `dots=500 radius=4 seed=20240521` → `frame=300 hash=9e479d3e`、`frame=900 hash=7b8514e4`。

## 5. 复现命令链（编译 → 带参启动）

```bash
# 0. 前置：DevEco Studio 打开工程，File → Project Structure → Signing Configs
#    勾选 Automatically generate signature（一次性，需登录华为账号）
cd CanvasBench
ohpm install
hvigorw assembleHap --mode module -p product=default --no-daemon
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap

# 1. 基线启动（默认参数）
hdc shell hilog -r                                    # 先清日志缓冲
hdc shell aa start -b com.example.vfxbench.canvas -a EntryAbility
hdc shell hilog | grep VFXBENCH                       # 核对 LAUNCH_PARAMS / FIRST_FRAME / CHECKSUM

# 2. 带参启动（扫描点示例）
hdc shell aa force-stop com.example.vfxbench.canvas
hdc shell aa start -b com.example.vfxbench.canvas -a EntryAbility --pi dot_count 2000 --pi dot_radius 8

# 3. 渲染取证
hdc shell snapshot_display -f /data/local/tmp/canvas_2000_8.jpeg
hdc file recv /data/local/tmp/canvas_2000_8.jpeg .

# 4. 复现性验证：同一参数组合启动两次，CHECKSUM 行逐条比对
hdc shell hilog | grep CHECKSUM > run_A.txt
hdc shell aa force-stop com.example.vfxbench.canvas
hdc shell aa start -b com.example.vfxbench.canvas -a EntryAbility --pi dot_count 2000 --pi dot_radius 8
hdc shell hilog | grep CHECKSUM > run_B.txt
diff run_A.txt run_B.txt   # 必须无差异（忽略时间戳）

# 5. 清理
hdc shell aa force-stop com.example.vfxbench.canvas
hdc uninstall com.example.vfxbench.canvas
```

> 注：`--pi` 仅接受无符号整型（官方 aa-tool.md 已核实）；`--wl/--wt/--wh/--ww` 固定窗口
> 仅在 2in1 开发者模式 + 调试签名下生效，手机端请依赖本 app 的固定尺寸 Canvas（360×720 vp）。
